# "Mes plans": the signed-in user's documents. Opening one leads to the
# editor; the editor itself saves through PlanApiController.
class PlansController < ApplicationController
  # GET /plans
  def index
    return @_to_login("/plans") unless @_signed_in?

    @viewer = @_session_viewer
    @plans = Plan.of_user(@_viewer_key).map do |plan|
      plan.summary.merge({"thumbnail": plan.thumbnail})
    end
    @flash = session_delete("flash")
    @title = "Mes plans"
  end

  # POST /plans
  def create
    return @_to_login("/plans") unless @_signed_in?

    plan = Plan.start(@_viewer_key, params["name"])
    redirect("/editor/" + plan._key)
  end

  # POST /plans/:id/duplicate
  def duplicate
    return @_to_login("/plans") unless @_signed_in?

    plan = Plan.owned(@_viewer_key, req["params"]["id"])
    return halt(404, "Plan introuvable") if plan.nil?

    copy = plan.duplicate
    @_notice("success", "« #{copy.name} » créé.")
    redirect("/plans")
  end

  # POST /plans/:id/delete
  def delete
    return @_to_login("/plans") unless @_signed_in?

    plan = Plan.owned(@_viewer_key, req["params"]["id"])
    return halt(404, "Plan introuvable") if plan.nil?

    name = plan.name
    plan.delete()
    @_notice("success", "« #{name} » supprimé.")
    redirect("/plans")
  end
end
