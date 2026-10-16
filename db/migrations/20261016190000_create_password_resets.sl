# One-time password reset links, found by the SHA-256 of their token.

def up(db)
  db.create_collection("password_resets") rescue nil
  db.create_index("password_resets", "idx_token_digest", ["token_digest"], {"unique": true})
end

def down(db)
  db.drop_collection("password_resets")
end
