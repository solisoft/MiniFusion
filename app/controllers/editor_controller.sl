# The CAD editor: the page fusion_mvp.html used to be, with its script
# assembled from src/ (CadBundle) and the server context handed over in
# window.MF_SERVER.
class EditorController < ApplicationController
  # GET /editor
  def show
    @asset_ver = CadBundle.app_ver
    @csrf_token = csrf_token()
    @cad_js = CadBundle.source
    @boot_json = json_stringify({"assetVer": @asset_ver})
    render("editor/show", {}, {"layout": false})
  end
end
