# A user's CAD document, saved online. `content` is the editor's own JSON
# (serialise(false) in src/90): sketches, features, parameters, CAM setups.
# Toolpaths are not kept (they are recomputed); the original bytes of imported
# STEP/STL files live in PlanSource, shared by every plan of the same user.
class Plan < Model
  static MAX_CONTENT: Int = 16777216
  static MAX_THUMBNAIL: Int = 400000
  static BLANK_NAME: String = "Sans titre"

  optimistic_lock
  validates("user_key", {"presence": true})
  validates("name", {"presence": true, "max_length": 120})
  before_save("normalize")

  # A fresh, empty plan for this user.
  static def start(user_key, name)
    plan = Plan.new()
    plan.user_key = user_key
    plan.name = Plan.clean_name(name)
    plan.content = ""
    plan.size = 0
    plan.save
    plan
  end

  # The plan with this key if it belongs to this user, else nil — the same nil
  # for someone else's plan and for a plan that does not exist.
  static def owned(user_key, key)
    plan = Plan.find_by("_key", key.to_s)
    return nil if plan.nil?
    return nil if plan.user_key != user_key

    plan
  end

  static def of_user(user_key)
    Plan.where({"user_key": user_key}).order("_updated_at", "desc").all
  end

  static def clean_name(name) -> String
    cleaned = name.to_s.trim
    return Plan.BLANK_NAME if cleaned.blank?

    cleaned.chars().take(120).join("")
  end

  # A copy for the same user, under "<name> (copie)".
  def duplicate
    copy = Plan.new()
    copy.user_key = @user_key
    copy.name = Plan.clean_name(@name + " (copie)")
    copy.content = @content
    copy.app_ver = @app_ver
    copy.size = @size
    copy.thumbnail = @thumbnail
    copy.save
    copy
  end

  # What the editor and the plan list need — never the whole record blindly.
  def summary
    {
      "key": @_key,
      "name": @name,
      "size": @size ?? 0,
      "app_ver": @app_ver,
      "lock_version": @lock_version,
      "updated_at": @_updated_at
    }
  end

  def normalize
    @name = Plan.clean_name(@name)
    @content = "" if @content.nil?
    @size = @content.length
    true
  end
end
