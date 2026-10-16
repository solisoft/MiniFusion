# The CAD editor: the page fusion_mvp.html used to be, with its script
# assembled from src/ (CadBundle) and the server context — the plan, its
# content and the viewer — handed over in window.MF_SERVER.
class EditorController < ApplicationController
  # GET /editor/:id
  def show
    path = "/editor/" + req["params"]["id"].to_s
    return @_to_login(path) unless @_signed_in?

    plan = Plan.owned(@_viewer_key, req["params"]["id"])
    return halt(404, "Plan introuvable") if plan.nil?

    viewer = @_session_viewer
    boot = {
      "assetVer": CadBundle.app_ver,
      "plan": plan.summary.merge({"content": plan.content.to_s, "has_thumbnail": !plan.thumbnail.blank?}),
      "user": {"name": viewer["name"], "initials": viewer["initials"]}
    }
    @asset_ver = boot["assetVer"]
    @csrf_token = csrf_token()
    @cad_js = CadBundle.source
    # Inside <script>: a "</script>" in a sketch name must not close the tag.
    @boot_json = json_stringify(boot).replace("</", "<\\/")
    render("editor/show", {}, {"layout": false})
  end
end
