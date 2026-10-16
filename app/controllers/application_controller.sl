# The base every page controller extends: the layout, who is viewing (a small
# hash kept in the session at sign-in, never the password digest) and the
# one-shot flash message. No actions here.
class ApplicationController < Controller
  static {
    this.layout = "application"
  }

  private

  def _session_viewer
    session_get("viewer")
  end

  def _viewer_key
    @_session_viewer&.dig("key")
  end

  def _signed_in? -> Bool
    !@_session_viewer.nil?
  end

  # Sends a visitor to the sign-in page, back here afterwards.
  def _to_login(return_to: String)
    session_set("return_to", return_to)
    @_notice("info", "Connectez-vous pour continuer.")
    redirect("/login")
  end

  def _notice(kind: String, message: String)
    session_set("flash", {"kind": kind, "message": message})
  end

  # A path on this site, never a full URL: `redirect` takes local paths only.
  def _local_path(path) -> String
    candidate = path.to_s
    return candidate if candidate.starts_with("/") && !candidate.starts_with("//")

    "/plans"
  end

  # {field => French message} for a record's `_errors`.
  def _errors_by_field(errors)
    by_field = {}
    (errors ?? []).each do |error|
      by_field[error["field"]] = ApplicationController.in_french(error["message"].to_s)
    end
    by_field
  end

  static def in_french(message: String) -> String
    return "est obligatoire" if message == "can't be blank"
    return "n'est pas valide" if message == "is invalid"
    return "est déjà utilisé" if message == "has already been taken"
    return "est trop long" if message.starts_with("is too long")

    message
  end
end
