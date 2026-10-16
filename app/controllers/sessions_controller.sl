# Signing in and out. The session keeps a small "viewer" hash, never the
# password digest.
class SessionsController < ApplicationController
  # GET /login
  def new
    return redirect("/plans") if @_signed_in?

    @email = ""
    @title = "Connexion"
  end

  # POST /login
  def create
    user = User.authenticate(params["email"], params["password"])
    if user.nil?
      @email = params["email"].to_s
      @error = "E-mail ou mot de passe incorrect."
      @title = "Connexion"
      return render("sessions/new", {}, {"status": 422})
    end

    return_to = session_get("return_to")
    session_regenerate()
    session_set("viewer", user.to_viewer)
    redirect(@_local_path(return_to ?? "/plans"))
  end

  # POST /login/demo — the "Essayer avec le compte de démo" button
  def demo
    user = User.authenticate(User.DEMO["email"], User.DEMO["password"])
    if user.nil?
      @email = ""
      @error = "Le compte de démo n'est pas installé sur ce serveur (soli db:seed)."
      @title = "Connexion"
      return render("sessions/new", {}, {"status": 503})
    end

    session_regenerate()
    session_set("viewer", user.to_viewer)
    redirect("/plans")
  end

  # POST /logout
  def destroy
    session_destroy()
    redirect("/")
  end
end
