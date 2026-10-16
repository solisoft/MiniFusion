# "Mot de passe oublié": an e-mailed one-time link, then a new password. The
# request page answers the same whether the address has an account or not.
class PasswordsController < ApplicationController
  # GET /password/forgot
  def new
    @title = "Mot de passe oublié"
    @sent = false
    @email = ""
  end

  # POST /password/forgot
  def create
    email = params["email"].to_s.trim.downcase
    user = User.find_by("email", email)
    if !user.nil? && email != User.DEMO["email"]
      token = PasswordReset.issue(user)
      link = ApplicationController.app_url() + "/password/reset/" + token
      AccountMailer.reset_password(user, link).deliver_now rescue nil
    end

    @title = "Mot de passe oublié"
    @sent = true
    @email = email
    render("passwords/new")
  end

  # GET /password/reset/:token
  def edit
    @token = req["params"]["token"].to_s
    @valid = !PasswordReset.pending(@token).nil?
    @error = nil
    @title = "Nouveau mot de passe"
  end

  # POST /password/reset/:token
  def update
    @token = req["params"]["token"].to_s
    reset = PasswordReset.pending(@token)
    @title = "Nouveau mot de passe"
    if reset.nil?
      @valid = false
      @error = nil
      return render("passwords/edit", {}, {"status": 410})
    end

    password = params["password"].to_s
    if password.length < User.MIN_PASSWORD
      @valid = true
      @error = "Le mot de passe doit contenir au moins #{User.MIN_PASSWORD} caractères."
      return render("passwords/edit", {}, {"status": 422})
    end

    user = User.find(reset.user_key)
    user.password_digest = password_hash(password)
    user.save
    reset.used = true
    reset.save
    session_regenerate()
    session_set("viewer", user.to_viewer)
    @_notice("success", "Mot de passe changé.")
    redirect("/plans")
  end
end
