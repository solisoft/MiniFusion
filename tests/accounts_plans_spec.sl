# Accounts, plans and the editor's JSON API: what is accepted, and above all
# what is refused (wrong password, someone else's plan, a stale save…).

def _signup(name, email, password)
  post("/signup", {"name": name, "email": email, "password": password})
end

def _new_plan
  response = post("/plans", {"name": "Bride"})
  res_location(response).split("/").last
end

def _source_put(id, data)
  put("/api/sources/" + id, {"filename": "piece.step", "data": data})
end

describe("Accounts") do
  before_each() do
    as_guest()
    PasswordReset.delete_all()
    Plan.delete_all()
    User.delete_all()
  end

  test("a sign-up opens the account and lands on the plans") do
    response = _signup("Ada Martin", "ada@example.com", "motdepasse1")
    expect(res_status(response)).to_equal(302)
    expect(res_location(response).ends_with("/plans")).to_equal(true)
    expect(User.count).to_equal(1)
    expect(res_status(get("/plans"))).to_equal(200)
  end

  test("a short password is refused and nothing is written") do
    response = _signup("Ada Martin", "ada@example.com", "court")
    expect(res_status(response)).to_equal(422)
    expect(res_body(response)).to_match("8 caractères")
    expect(User.count).to_equal(0)
  end

  test("an e-mail already taken is refused") do
    _signup("Ada Martin", "ada@example.com", "motdepasse1")
    as_guest()
    response = _signup("Autre", "ADA@example.com", "motdepasse2")
    expect(res_status(response)).to_equal(422)
    expect(User.count).to_equal(1)
  end

  test("a wrong password and an unknown e-mail get the same refusal") do
    _signup("Ada Martin", "ada@example.com", "motdepasse1")
    as_guest()
    wrong = post("/login", {"email": "ada@example.com", "password": "mauvais-mdp"})
    unknown = post("/login", {"email": "nobody@example.com", "password": "motdepasse1"})
    expect(res_status(wrong)).to_equal(422)
    expect(res_status(unknown)).to_equal(422)
    expect(res_body(wrong)).to_match("E-mail ou mot de passe incorrect")
    expect(res_status(get("/plans"))).to_equal(302)
  end

  test("a guest is sent to the sign-in page, and the API answers 401") do
    expect(res_location(get("/plans")).ends_with("/login")).to_equal(true)
    expect(res_location(get("/editor/abc")).ends_with("/login")).to_equal(true)
    expect(res_status(get("/api/plans/abc"))).to_equal(401)
    expect(res_status(put("/api/plans/abc", {"content": "{}", "lock_version": 0}))).to_equal(401)
  end

  test("the demo button refuses cleanly when the demo is not seeded") do
    expect(res_status(post("/login/demo", {}))).to_equal(503)
  end
end

describe("Password reset") do
  before_each() do
    as_guest()
    PasswordReset.delete_all()
    User.delete_all()
  end

  test("an unknown address gets the same answer and no reset") do
    response = post("/password/forgot", {"email": "nobody@example.com"})
    expect(res_status(response)).to_equal(200)
    expect(res_body(response)).to_match("Si un compte existe")
    expect(PasswordReset.count).to_equal(0)
  end

  test("a reset link changes the password once, then is dead") do
    user = User.register("Ada Martin", "ada@example.com", "motdepasse1")
    token = PasswordReset.issue(user)
    expect(res_status(post("/password/reset/" + token, {"password": "court"}))).to_equal(422)
    response = post("/password/reset/" + token, {"password": "nouveau-mdp1"})
    expect(res_status(response)).to_equal(302)
    as_guest()
    expect(res_status(post("/password/reset/" + token, {"password": "encore-un-mdp"}))).to_equal(410)
    expect(User.authenticate("ada@example.com", "nouveau-mdp1").nil?).to_equal(false)
    expect(User.authenticate("ada@example.com", "motdepasse1").nil?).to_equal(true)
  end

  test("a made-up token is refused") do
    response = get("/password/reset/ceci-n-est-pas-un-jeton-valide-du-tout")
    expect(res_status(response)).to_equal(200)
    expect(res_body(response)).to_match("plus valable")
  end
end

describe("Plans and the editor API") do
  before_each() do
    as_guest()
    PlanSource.where({}).all.each do |source|
      delete_attachment(PlanSource.STORE, source.blob_id) rescue nil
    end
    PlanSource.delete_all()
    Plan.delete_all()
    User.delete_all()
    _signup("Ada Martin", "ada@example.com", "motdepasse1")
  end

  test("a new plan opens in the editor with its content handed over") do
    key = _new_plan()
    response = get("/editor/" + key)
    expect(res_status(response)).to_equal(200)
    expect(res_body(response)).to_match("window.MF_SERVER=")
    expect(res_body(response)).to_match(key)
  end

  test("a save bumps the lock; a stale one is refused with 409") do
    key = _new_plan()
    saved = put("/api/plans/" + key, {"name": "Bride 2", "content": "{\"v\":1}", "lock_version": 0})
    expect(res_status(saved)).to_equal(200)
    expect(res_json(saved)["lock_version"]).to_equal(1)
    stale = put("/api/plans/" + key, {"content": "{\"v\":2}", "lock_version": 0})
    expect(res_status(stale)).to_equal(409)
    expect(res_json(stale)["plan"]["lock_version"]).to_equal(1)
    expect(Plan.find(key).content).to_equal("{\"v\":1}")
  end

  test("bad input is refused: no lock, content not a string, foreign thumbnail") do
    key = _new_plan()
    expect(res_status(put("/api/plans/" + key, {"content": "{}"}))).to_equal(422)
    expect(res_status(put("/api/plans/" + key, {"content": 12, "lock_version": 0}))).to_equal(422)
    body = {"content": "{}", "lock_version": 0, "thumbnail": "javascript:alert(1)"}
    expect(res_status(put("/api/plans/" + key, body))).to_equal(200)
    expect(Plan.find(key).thumbnail.nil?).to_equal(true)
  end

  test("someone else's plan does not exist for you") do
    key = _new_plan()
    as_guest()
    _signup("Bruno", "bruno@example.com", "motdepasse2")
    expect(res_status(get("/editor/" + key))).to_equal(404)
    expect(res_status(get("/api/plans/" + key))).to_equal(404)
    expect(res_status(put("/api/plans/" + key, {"content": "{}", "lock_version": 0}))).to_equal(404)
    expect(res_status(post("/plans/" + key + "/delete", {}))).to_equal(404)
    expect(Plan.count).to_equal(1)
  end

  test("duplicate and delete act on one's own plans") do
    key = _new_plan()
    expect(res_status(post("/plans/" + key + "/duplicate", {}))).to_equal(302)
    expect(Plan.count).to_equal(2)
    expect(res_status(post("/plans/" + key + "/delete", {}))).to_equal(302)
    expect(Plan.count).to_equal(1)
  end

  test("an import source goes up once, comes back, and stays its owner's") do
    expect(res_status(_source_put("abc_13", "SVNPLTEwMzAzLTIxOw=="))).to_equal(200)
    known = post("/api/sources/known", {"keys": ["impsrc:abc_13", "impsrc:zz_1"]})
    expect(res_json(known)["known"]).to_equal(["impsrc:abc_13"])
    expect(res_json(get("/api/sources/abc_13"))["data"]).to_equal("SVNPLTEwMzAzLTIxOw==")
    expect(res_status(_source_put("a.b", "AAAA"))).to_equal(422)
    as_guest()
    _signup("Bruno", "bruno@example.com", "motdepasse2")
    expect(res_status(get("/api/sources/abc_13"))).to_equal(404)
  end
end
