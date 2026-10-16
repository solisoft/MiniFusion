# The editor's JSON API on plans (same-origin fetch, session cookie). Every
# action answers only for the signed-in owner: someone else's plan is a 404,
# like a plan that does not exist.
class PlanApiController < ApplicationController
  # POST /api/plans
  def create
    return @_unauthorized unless @_signed_in?

    plan = Plan.start(@_viewer_key, @_body["name"])
    render_json(plan.summary, 201)
  end

  # GET /api/plans/:id
  def show
    return @_unauthorized unless @_signed_in?

    plan = Plan.owned(@_viewer_key, req["params"]["id"])
    return @_not_found if plan.nil?

    render_json(plan.summary.merge({"content": plan.content.to_s}))
  end

  # PUT /api/plans/:id — {name, content, lock_version, thumbnail?, app_ver?}
  def update
    return @_unauthorized unless @_signed_in?

    plan = Plan.owned(@_viewer_key, req["params"]["id"])
    return @_not_found if plan.nil?

    body = @_body
    content = body["content"]
    unless content.is_a?("string") && content.length <= Plan.MAX_CONTENT
      return render_json({"error": "contenu invalide ou trop volumineux"}, 422)
    end

    unless body["lock_version"].is_a?("int")
      return render_json({"error": "lock_version manquant"}, 422)
    end

    plan.lock_version = body["lock_version"]
    plan.content = content
    plan.name = body["name"] unless body["name"].nil?
    plan.app_ver = body["app_ver"].to_s unless body["app_ver"].nil?
    thumbnail = body["thumbnail"]
    if thumbnail.is_a?("string") && PlanApiController.thumbnail_ok?(thumbnail)
      plan.thumbnail = thumbnail
    end

    unless plan.save
      current = Plan.owned(@_viewer_key, plan._key)
      return render_json({"error": "stale", "plan": current.summary}, 409) if plan.stale?

      return render_json({"error": "invalide", "errors": plan._errors}, 422)
    end

    render_json(plan.summary)
  end

  # POST /api/plans/:id/duplicate
  def duplicate
    return @_unauthorized unless @_signed_in?

    plan = Plan.owned(@_viewer_key, req["params"]["id"])
    return @_not_found if plan.nil?

    render_json(plan.duplicate.summary, 201)
  end

  # A JPEG or PNG data URL of reasonable size — it is shown in <img src> on
  # the plan list, so nothing else gets in.
  static def thumbnail_ok?(value: String) -> Bool
    return false if value.length > Plan.MAX_THUMBNAIL

    value.starts_with("data:image/jpeg;base64,") || value.starts_with("data:image/png;base64,")
  end

  private

  def _body
    req["json"] ?? {}
  end

  def _unauthorized
    render_json({"error": "non connecté"}, 401)
  end

  def _not_found
    render_json({"error": "plan introuvable"}, 404)
  end
end
