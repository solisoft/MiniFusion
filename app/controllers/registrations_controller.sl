# Creating an account.
class RegistrationsController < ApplicationController
  # GET /signup
  def new
    return redirect("/plans") if @_signed_in?

    @form = {"name": "", "email": ""}
    @errors = {}
    @title = "Créer un compte"
  end

  # POST /signup
  def create
    attrs = permit(params, {"name": true, "email": true, "password": true})
    user = User.register(attrs["name"], attrs["email"], attrs["password"])
    if user._key.nil?
      @form = {"name": attrs["name"].to_s, "email": attrs["email"].to_s}
      @errors = @_errors_by_field(user._errors)
      @title = "Créer un compte"
      return render("registrations/new", {}, {"status": 422})
    end

    session_regenerate()
    session_set("viewer", user.to_viewer)
    @_notice("success", "Bienvenue sur MiniFusion, #{user.to_viewer["first_name"]} !")
    redirect("/plans")
  end
end
