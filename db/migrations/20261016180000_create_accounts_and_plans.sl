# Accounts and online plans: one collection per model, with the indexes the
# pages and the API query by.

def _collections
  {
    "users": [["idx_email", ["email"], {"unique": true}]],
    "plans": [["idx_user_updated", ["user_key", "_updated_at"], {}]],
    "plan_sources": [["idx_user_src", ["user_key", "src_key"], {"unique": true}]]
  }
end

def up(db)
  collections = _collections()
  collections.keys.each do |collection|
    db.create_collection(collection) rescue nil
    collections[collection].each do |index|
      db.create_index(collection, index[0], index[1], index[2])
    end
  end
end

def down(db)
  _collections().keys.each do |collection|
    db.drop_collection(collection)
  end
end
