# The original bytes of imported STEP/STL files, per user (see PlanSource).
# The URL carries the key without its "impsrc:" prefix.
class SourceApiController < ApplicationController
  # POST /api/sources/known — {keys: ["impsrc:…"]} → {known: [...]}
  def known
    return @_unauthorized unless @_signed_in?

    keys = (req["json"] ?? {})["keys"]
    return render_json({"error": "keys attendu"}, 422) unless keys.is_a?("array") && keys.length <= 500

    render_json({"known": PlanSource.known(@_viewer_key, keys.map { |key| key.to_s })})
  end

  # GET /api/sources/:id → {filename, data (base64)}
  def show
    return @_unauthorized unless @_signed_in?

    source = PlanSource.owned(@_viewer_key, "impsrc:" + req["params"]["id"].to_s)
    return render_json({"error": "source introuvable"}, 404) if source.nil?

    render_json(source.read)
  end

  # PUT /api/sources/:id — {filename, data (base64)}
  def update
    return @_unauthorized unless @_signed_in?

    body = req["json"] ?? {}
    return render_json({"error": "data attendu"}, 422) unless body["data"].is_a?("string")

    key = "impsrc:" + req["params"]["id"].to_s
    source = PlanSource.put(@_viewer_key, key, body["filename"], body["data"])
    return render_json({"error": "invalide", "errors": source._errors}, 422) if (source._errors ?? []).length > 0

    render_json({"key": source.src_key, "size": source.size})
  end

  private

  def _unauthorized
    render_json({"error": "non connecté"}, 401)
  end
end
