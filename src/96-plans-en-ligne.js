/* ---------- 2026-10-16-018 : plans enregistrés en ligne (app Soli) ----------
   L'éditeur est servi par l'app Soli sur /editor/:id, compte obligatoire. Le serveur
   remet le plan dans window.MF_SERVER ({assetVer, plan:{key,name,lock_version,content},
   user}) ; ce module l'ouvre au démarrage (planBoot, appelé par 99-init) et
   l'enregistre par l'API JSON :
     PUT  /api/plans/:id   {name, content, lock_version, thumbnail?, app_ver}
          → 409 si le plan a changé ailleurs (autre onglet) : on demande quoi faire.
     POST /api/sources/known, PUT|GET /api/sources/:id — octets d'origine des imports
          STEP/STL (clé impsrc:…), propres à l'utilisateur, partagés entre ses plans.
   Les parcours FAO ne partent pas en ligne : recalculables, ils restent en cache local.
   Filet de sécurité : brouillon local par plan (minifusion_draft_<clé>) à chaque
   modification ; repris à la réouverture s'il est plus récent que la version serveur.
   Sans MF_SERVER (harnais de tests Node) : rien ne change, l'ancien comportement reste. */
const MF=(typeof window!=='undefined'&&window.MF_SERVER&&window.MF_SERVER.plan)?window.MF_SERVER:null;
let planLock=MF?MF.plan.lock_version:0;
let planLastContent=null;   // dernier contenu accepté par le serveur
let planSaving=null, planAgain=false, planSaveT=null, planConflict=false, planFromDraft=false;
const planKnownSrc=new Set();

function planDraftKey(){return 'minifusion_draft_'+MF.plan.key;}
function planCsrf(){const m=document.querySelector('meta[name="csrf-token"]');return m?m.content:'';}
async function planApi(method,url,body){
  const r=await fetch(url,{method,credentials:'same-origin',
    headers:{'Content-Type':'application/json','Accept':'application/json','X-CSRF-Token':planCsrf()},
    body:body===undefined?undefined:JSON.stringify(body)});
  let j=null;try{j=await r.json();}catch(e){}
  if(r.status===401){location.href='/login';}
  if(!r.ok){const e=new Error((j&&j.error)||('HTTP '+r.status));e.status=r.status;e.body=j;throw e;}
  return j;
}
function planState(state,text){
  const el=$('mfSaveState');if(!el)return;
  el.textContent=text;el.dataset.state=state;
}

/* Vignette pour « Mes plans » : la vue 3D telle qu'elle est, en JPEG 480×300. Lue
   juste après un rendu (le tampon WebGL n'est pas conservé entre deux images). */
function planThumb(){
  try{
    if(!renderer||!scene||!camera)return null;
    renderer.render(scene,camera);
    const src=renderer.domElement, W=480, H=300;
    const c=document.createElement('canvas');c.width=W;c.height=H;
    const g=c.getContext('2d');
    const k=Math.max(W/src.width,H/src.height), w=src.width*k, h=src.height*k;
    g.fillStyle='#1c1c1e';g.fillRect(0,0,W,H);
    g.drawImage(src,(W-w)/2,(H-h)/2,w,h);
    // Tampon déjà vidé (capture trop tôt, vue en fondu) : une image unie n'est pas un aperçu.
    const px=g.getImageData(0,0,W,H).data;let lo=765,hi=0;
    for(let i=0;i<px.length;i+=4*97){const l=px[i]+px[i+1]+px[i+2];if(l<lo)lo=l;if(l>hi)hi=l;}
    if(hi-lo<30)return null;
    const url=c.toDataURL('image/jpeg',0.82);
    return url.length<400000?url:null;
  }catch(e){return null;}
}

function planImportKeys(d){
  const out=[];
  ((d&&d.features)||[]).forEach(f=>{if(f&&f.type==='import'&&f.src&&f.src.key&&out.indexOf(f.src.key)<0)out.push(f.src.key);});
  return out;
}
function planSrcId(key){return encodeURIComponent(String(key).replace(/^impsrc:/,''));}

// Ouverture : rapatrier les sources des imports AVANT deserialise, qui les rejoue aussitôt.
async function planFetchSources(content){
  let d=null;try{d=JSON.parse(content);}catch(e){return;}
  for(const k of planImportKeys(d)){
    try{
      if(await importSrcGet(k))continue;
      const s=await planApi('GET','/api/sources/'+planSrcId(k));
      if(s&&typeof s.data==='string'){await importSrcPut(k,importB64ToU8(s.data));planKnownSrc.add(k);}
    }catch(e){try{console.warn('[plans] source '+k+' : '+e.message);}catch(_){}}
  }
}
// Enregistrement : envoyer les sources que le serveur n'a pas encore.
async function planUploadSources(){
  const keys=planImportKeys(doc).filter(k=>!planKnownSrc.has(k));
  if(!keys.length)return;
  const r=await planApi('POST','/api/sources/known',{keys});
  ((r&&r.known)||[]).forEach(k=>planKnownSrc.add(k));
  for(const k of keys){
    if(planKnownSrc.has(k))continue;
    const u8=await importSrcGet(k);if(!u8)continue;
    const f=(doc.features||[]).find(x=>x&&x.src&&x.src.key===k);
    await planApi('PUT','/api/sources/'+planSrcId(k),{filename:(f&&f.src&&f.src.file)||'',data:importU8ToB64(u8)});
    planKnownSrc.add(k);
  }
}

function planDraftWrite(){
  try{localStorage.setItem(planDraftKey(),JSON.stringify({lock:planLock,at:Date.now(),content:serialise(false)}));}catch(e){}
}
function planDraftClear(){try{localStorage.removeItem(planDraftKey());}catch(e){}}

async function planSave(opts){
  if(!MF||planConflict)return;
  if(planSaving){planAgain=true;return planSaving;}
  const force=!!(opts&&opts.force), thumb=!!(opts&&opts.thumb);
  planSaving=(async()=>{
    const v0=_docVersion, content=serialise(false);
    if(!force&&!thumb&&content===planLastContent){dirty=false;refreshParts();planState('saved','Enregistré');return;}
    planState('saving','Enregistrement…');
    await planUploadSources();
    const body={name:doc.name||'Sans titre',content,lock_version:planLock,app_ver:APP_VER};
    const t=planThumb();if(t)body.thumbnail=t;
    const r=await planApi('PUT','/api/plans/'+MF.plan.key,body);
    planLock=r.lock_version;planLastContent=content;MF.plan.name=r.name;
    if(_docVersion===v0){dirty=false;planDraftClear();}
    refreshParts();
    planState('saved','Enregistré');
  })().catch(e=>{
    if(e.status===409){planOnConflict(e.body&&e.body.plan);return;}
    planDraftWrite();
    planState('offline','Hors ligne — modifications gardées dans ce navigateur');
    try{console.warn('[plans] enregistrement : '+e.message);}catch(_){}
  }).finally(()=>{
    planSaving=null;
    if(planAgain){planAgain=false;planSaveSoon(800);}
  });
  return planSaving;
}
function planSaveSoon(ms){
  if(!MF)return;
  if(planSaveT)clearTimeout(planSaveT);
  planSaveT=setTimeout(()=>{planSaveT=null;planSave();},ms||2500);
}
function planOnConflict(current){
  planConflict=true;planDraftWrite();
  planState('conflict','Modifié ailleurs — non enregistré');
  const keep=confirm('Ce plan a été enregistré depuis un autre onglet ou un autre poste.\n\n'
    +'OK : remplacer cette version par la vôtre.\nAnnuler : recharger la version enregistrée (vos modifications d\'ici restent dans ce navigateur).');
  if(keep){
    planConflict=false;
    if(current&&typeof current.lock_version==='number')planLock=current.lock_version;
    planSave({force:true});
  }else{
    planDraftClear();location.reload();
  }
}

// Démarrage (99-init) : le plan du serveur, ou le brouillon local s'il est plus récent.
async function planBoot(){
  if(!MF)return false;
  let content=MF.plan.content||'';
  planLastContent=content;
  try{
    const d=JSON.parse(localStorage.getItem(planDraftKey())||'null');
    if(d&&d.lock===planLock&&typeof d.content==='string'&&d.content!==content){
      content=d.content;planFromDraft=true;faceEl.textContent='Modifications non enregistrées reprises de ce navigateur — enregistrement en cours.';
    }else if(d){planDraftClear();}
  }catch(e){}
  if(content){
    await planFetchSources(content);
    await deserialise(content,{rebuild:false});
  }
  doc.name=MF.plan.name||doc.name;
  try{$('docName').textContent=doc.name;}catch(e){}
  renderProps();
  planState('saved','Enregistré');
  if(content!==planLastContent)planSaveSoon(1500);
  return true;
}

// Après le premier rejeu : la sérialisation d'un plan qu'on vient d'ouvrir diffère
// souvent du texte stocké (champs normalisés, vue) — ce n'est pas une modification.
function planSettle(){
  if(planFromDraft)return;
  planLastContent=serialise(false);
  if(planSaveT){clearTimeout(planSaveT);planSaveT=null;}
  dirty=false;refreshParts();
}
// Plan jamais vignetté (créé vide, importé, compte de démo) : une vignette dès que la
// pièce est rejouée en exact et affichée.
function planThumbWhenReady(){
  const t0=Date.now();
  const tick=()=>{
    const cv=$('viewport');
    const ready=typeof occtReady!=='undefined'&&occtReady&&!planSaving&&(!doc.features||!doc.features.length||bodies.length>0)
      &&!(typeof bootVeilOn!=='undefined'&&bootVeilOn)&&!(cv&&cv.style&&cv.style.opacity==='0');
    if(ready){setTimeout(()=>{if(!planConflict&&planThumb())planSave({thumb:true}).then(()=>{MF.plan.has_thumbnail=true;});else if(Date.now()-t0<180000)setTimeout(tick,1000);},2500);return;}
    if(Date.now()-t0<180000)setTimeout(tick,1000);
  };
  tick();
}

if(MF){
  // Toute modification du document part au serveur (différé) ; le brouillon local
  // couvre la fermeture d'onglet et les coupures réseau.
  const _markDirty=markDirty;
  markDirty=function(){_markDirty.apply(this,arguments);if(!planConflict&&!planSaving)planState('pending','Modifié');planSaveSoon();};
  autosave=function(){refreshParts();planSaveSoon();};
  autosaveFlush=function(){if(dirty||planSaveT||planSaving)planDraftWrite();};

  $('btnSave').onclick=()=>{if(planSaveT){clearTimeout(planSaveT);planSaveT=null;}planSave({force:true});};
  $('btnSaveAs').onclick=async()=>{
    await planSave();
    try{const c=await planApi('POST','/api/plans/'+MF.plan.key+'/duplicate');location.href='/editor/'+c.key;}
    catch(e){alert('Copie impossible : '+e.message);}
  };
  $('btnNew').onclick=async()=>{
    await planSave();
    try{const p=await planApi('POST','/api/plans',{name:'Sans titre'});location.href='/editor/'+p.key;}
    catch(e){alert('Création impossible : '+e.message);}
  };
  // « Exporter .miniFusion » : le fichier autonome d'avant (document + trajectoires + sources).
  if($('btnExportBundle'))$('btnExportBundle').onclick=async()=>{
    const fname=(doc.name||'piece').replace(/[\\/:*?"<>|]/g,'_')+'.miniFusion';
    let data;try{data=await bundleSerialise();}catch(err){data=serialise();}
    const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([data],{type:'application/json'}));a.download=fname;a.click();
    setTimeout(()=>URL.revokeObjectURL(a.href),2000);
  };
  // « Importer un fichier » (ex-Ouvrir) : le fichier remplace le contenu de CE plan,
  // puis part en ligne — c'est le chemin des anciens .miniFusion vers le compte.
  $('fileProj').addEventListener('change',()=>setTimeout(()=>planSaveSoon(1200),0));
  try{
    $('btnSave').title='Enregistrer maintenant (l\'enregistrement en ligne est automatique)';
    $('btnSaveAs').title='Enregistrer une copie dans Mes plans et l\'ouvrir';
    $('btnLoad').title='Importer un fichier .miniFusion ou .minifusion.json dans ce plan';
    $('btnNew').title='Nouveau plan (celui-ci reste dans Mes plans)';
  }catch(e){}
  addEventListener('online',()=>{if(!planConflict&&dirty)planSaveSoon(500);});
}
