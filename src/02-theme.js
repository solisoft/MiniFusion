/* ---------- 2026-10-16-020 : thème clair / sombre ----------
   Le thème est posé AVANT le premier rendu par le script de tête de la page
   (app/views/editor/show.html.slv) : <html data-theme="light|dark">, d'après le choix
   mémorisé (localStorage 'minifusion_theme', partagé avec les pages publiques) ou, sans
   choix, le réglage du système. Le CSS suit par variables (--bg, --ovl-bg…) ; ce qui ne
   lit pas le CSS — l'esquisse SVG (attributs stroke/fill) et la scène THREE — passe par
   th('clé') ci-dessous, et themeApply() les repeint à la bascule.
   Bouton ◐ du bandeau : bascule clair ↔ sombre. Revenir au réglage du système = choisir
   le même thème que lui (la préférence mémorisée est alors effacée). */
const THEME_PAL={
  dark:{
    scene:0x1c1c1e, floor:0x141519,
    skGrid:'#2a2a2e', skBlue:'#0a84ff', skRef:'#e6e6ee', skSel:'#ff9f0a', skSel2:'#ffb340',
    skFull:'#e8e8ea', skUnder:'#64d2ff', skOk:'#30d158', skOkBg:'#16261b', skMuted:'#8e8e93',
    skMuted2:'#8a8f99', skHalo:'#101012', skInk:'#fff', skInkFill:'rgba(255,255,255,.06)',
    skBoxFill:'rgba(10,132,255,.08)', skCircleFill:'rgba(100,210,255,.07)', skLabelBg:'#1e1e1e',
    skPurple:'#bf5af2', skYellow:'#ffd60a', skRed:'#ff453a'
  },
  light:{
    scene:0xe9edf1, floor:0xdde2e8,
    skGrid:'#dde2e8', skBlue:'#0a6fdb', skRef:'#5e6875', skSel:'#d96a00', skSel2:'#e08a2c',
    skFull:'#1d232b', skUnder:'#0a7fc2', skOk:'#1f8a3b', skOkBg:'#e3f4e8', skMuted:'#7b8592',
    skMuted2:'#6b7480', skHalo:'#ffffff', skInk:'#1d232b', skInkFill:'rgba(20,30,45,.05)',
    skBoxFill:'rgba(10,111,219,.08)', skCircleFill:'rgba(10,127,194,.06)', skLabelBg:'#ffffff',
    skPurple:'#8e3bd1', skYellow:'#a77700', skRed:'#d70015'
  }
};
function themeSystem(){
  try{return (window.matchMedia&&window.matchMedia('(prefers-color-scheme: light)').matches)?'light':'dark';}catch(e){return 'dark';}
}
function themeRead(){
  try{const d=document.documentElement&&document.documentElement.dataset;if(d&&(d.theme==='light'||d.theme==='dark'))return d.theme;}catch(e){}
  return 'dark';
}
let mfTheme=themeRead();
function th(k){const p=THEME_PAL[mfTheme]||THEME_PAL.dark;return (k in p)?p[k]:THEME_PAL.dark[k];}
function themeApply(){
  try{if(typeof scene!=='undefined'&&scene&&scene.background&&scene.background.set)scene.background.set(th('scene'));}catch(e){}
  try{if(typeof mirrorU!=='undefined'&&mirrorU&&mirrorU.color)mirrorU.color.value.set(th('floor'));mirrorDirty=true;}catch(e){}
  try{if(typeof skEdit!=='undefined'&&skEdit){skDimTxtCol=th('skOk');drawSketch2D();}}catch(e){}
  try{const b=document.getElementById('mfTheme');if(b){b.textContent=mfTheme==='light'?'☾':'☀';
    b.title=mfTheme==='light'?'Passer en thème sombre':'Passer en thème clair';}}catch(e){}
}
function themeSet(t){
  mfTheme=(t==='light')?'light':'dark';
  try{document.documentElement.dataset.theme=mfTheme;}catch(e){}
  // Même thème que le système : on cesse de forcer, la page suit à nouveau l'OS.
  try{if(mfTheme===themeSystem())localStorage.removeItem('minifusion_theme');else localStorage.setItem('minifusion_theme',mfTheme);}catch(e){}
  themeApply();
}
try{
  const b=document.getElementById('mfTheme');
  if(b)b.onclick=()=>themeSet(mfTheme==='light'?'dark':'light');
  // Réglage du système modifié pendant la session : suivi, sauf choix explicite.
  const mq=window.matchMedia&&window.matchMedia('(prefers-color-scheme: light)');
  if(mq&&mq.addEventListener)mq.addEventListener('change',()=>{
    let forced=null;try{forced=localStorage.getItem('minifusion_theme');}catch(e){}
    if(!forced){mfTheme=themeSystem();try{document.documentElement.dataset.theme=mfTheme;}catch(e){}themeApply();}
  });
  // Autre onglet (page publique ou éditeur) qui bascule : on suit.
  addEventListener('storage',ev=>{
    if(ev.key!=='minifusion_theme')return;
    mfTheme=ev.newValue==='light'||ev.newValue==='dark'?ev.newValue:themeSystem();
    try{document.documentElement.dataset.theme=mfTheme;}catch(e){}themeApply();
  });
  themeApply();
}catch(e){}
