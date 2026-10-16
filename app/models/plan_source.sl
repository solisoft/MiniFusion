# The original bytes of a STEP/STL file an import feature was built from. The
# editor names them by content (`impsrc:<fnv hash>_<length>`, src/90), so one
# source serves every plan of its owner that imports the same file — a copy of
# a plan needs no copy of its sources. The bytes are on disk (storage/), the
# record keeps the blob id.
class PlanSource < Model
  static MAX_SIZE: Int = 48000000
  static STORE: Hash = {"service": "disk", "collection": "plan_sources"}

  validates("user_key", {"presence": true})
  validates("src_key", {"presence": true, "format": "^impsrc:[A-Za-z0-9_]{1,80}$"})

  static def owned(user_key, src_key)
    PlanSource.where({"user_key": user_key, "src_key": src_key.to_s}).first
  end

  # The keys among `src_keys` this user has already stored.
  static def known(user_key, src_keys)
    return [] if src_keys.length == 0

    PlanSource.where({"user_key": user_key, "src_key": src_keys}).all.map { |source| source.src_key }
  end

  # Stores (or replaces) the bytes for this key. `data` is base64, as the
  # editor already carries imports in its .miniFusion bundles.
  static def put(user_key, src_key, filename, data)
    source = PlanSource.new()
    source.user_key = user_key
    source.src_key = src_key.to_s
    source.filename = filename.to_s.chars().take(200).join("")
    source.size = data.to_s.length
    unless Regex.matches("^impsrc:[A-Za-z0-9_]{1,80}$", source.src_key)
      source._errors = [{"field": "src_key", "message": "is invalid"}]
      return source
    end

    if source.size > PlanSource.MAX_SIZE
      source._errors = [{"field": "data", "message": "fichier trop volumineux"}]
      return source
    end

    blob = {"filename": source.filename, "content_type": "application/octet-stream", "data": data.to_s}
    source.blob_id = store_attachment(PlanSource.STORE, blob)
    previous = PlanSource.owned(user_key, src_key)
    unless previous.nil?
      delete_attachment(PlanSource.STORE, previous.blob_id)
      previous.delete()
    end

    source.save
    source
  end

  # {filename, data (base64)}.
  def read
    blob = read_attachment(PlanSource.STORE, @blob_id)
    {"filename": @filename, "data": blob["data"]}
  end
end
