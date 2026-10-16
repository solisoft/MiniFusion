# The landing page's images, shot from the real editor in headless Chrome.
#   bin/landing-images        (runs this spec with MF_CAPTURE=1, then WebP)
# Without MF_CAPTURE the test is pending: it rewrites public/images/landing/.

def _cad_wait(expression, seconds)
  waited = 0
  while waited < seconds
    ready = evaluate("(()=>{try{return !!(#{expression});}catch(e){return false;}})()")
    return true if ready

    sleep(1)
    waited = waited + 1
  end
  false
end

def _cad_open(key)
  visit("/editor/" + key)
  ok = _cad_wait("typeof occtReady!=='undefined'&&occtReady&&bodies.length>0&&faoSolidSettled()&&!bootVeilOn", 180)
  sleep(3)
  ok
end

def _capture_user
  user = User.find_by("email", "atelier@minifusion.test")
  user = User.register("Camille Martin", "atelier@minifusion.test", "atelier-minifusion") if user.nil?
  user
end

def _capture_plan(user, name, path)
  plan = Plan.start(user._key, name)
  plan.content = File.read(path)
  plan.save
  plan
end

def _shot(name)
  screenshot("public/images/landing/" + name + ".png")
end

# The 3D view alone: every panel hidden, the canvas over the whole page, the
# part framed by the editor's own "Tout afficher".
def _shot_view(name)
  evaluate("""(()=>{
    const st=document.createElement('style');st.id='mfShotCss';
    st.textContent='#vpwrap{position:fixed!important;inset:0!important;z-index:9999}'
      +'#treeWrap,#viewbar,#faoWrap,#faoTreeWrap,#faoViewerBar,#faoAddBar,#labels,#bootVeil{display:none!important}';
    document.head.appendChild(st);dispatchEvent(new Event('resize'));showAll();return true;})()""")
  sleep(2)
  _shot(name)
  evaluate("document.getElementById('mfShotCss').remove();dispatchEvent(new Event('resize'));true")
  sleep(1)
end

describe("landing captures") do
  viewport(1600, 1000, {"scale": 2})

  test("shoots the editor and the plan list") do
    return pending("MF_CAPTURE=1 pour régénérer public/images/landing/") if getenv("MF_CAPTURE").nil?

    user = _capture_user()
    Plan.where({"user_key": user._key}).all.each do |old|
      old.delete()
    end
    pince = _capture_plan(user, "Pince", "Exemples/Pince.minifusion.json")
    piece = _capture_plan(user, "Pièce", "Exemples/Pièce.minifusion.json")
    cavite = _capture_plan(user, "Cavité usinage", "Exemples/Cavité Usinage.minifusion.json")

    login("atelier@minifusion.test", "atelier-minifusion")
    visit("/plans")
    expect(evaluate("location.pathname")).to_equal("/plans")
    wait_for_text("Mes plans")

    # Modelling: the most detailed part, framed by the editor itself.
    expect(_cad_open(piece._key)).to_equal(true)
    expect(_cad_wait("MF.plan.has_thumbnail", 60)).to_equal(true)
    _shot_view("modele")

    # A sketch with its constraints and dimensions.
    expect(_cad_open(pince._key)).to_equal(true)
    expect(_cad_wait("MF.plan.has_thumbnail", 60)).to_equal(true)
    evaluate("openSketch(doc.sketches[0].id)")
    sleep(3)
    _shot("esquisse")

    # Machining: toolpaths of the 3D roughing, then the G-code they give.
    expect(_cad_open(cavite._key)).to_equal(true)
    expect(_cad_wait("MF.plan.has_thumbnail", 60)).to_equal(true)
    evaluate("setTimeout(()=>{window.__gen=faoPreviewGenerate();},50);true")
    expect(_cad_wait("window.__gen>0&&!faoMovesPending()", 120)).to_equal(true)
    sleep(3)
    _shot("usinage")
    _shot_view("parcours")
    gcode = evaluate("faoPost(faoDoc()).code.split('\\n').slice(0,40).join('\\n')")
    File.write("public/images/landing/gcode.txt", gcode)

    visit("/plans")
    _shot("plans")
  end
end
