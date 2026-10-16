# A one-time link to choose a new password. Only the SHA-256 of the token is
# stored: the link in the e-mail is the only copy of the token itself.
class PasswordReset < Model
  static TTL: Int = 7200

  validates("user_key", {"presence": true})
  validates("token_digest", {"presence": true})

  # A fresh token for this user (returned once, never stored in clear).
  static def issue(user) -> String
    token = Crypto.random_token(32)
    reset = PasswordReset.new()
    reset.user_key = user._key
    reset.token_digest = Crypto.sha256(token)
    reset.expires_at = DateTime.utc.to_unix + PasswordReset.TTL
    reset.used = false
    reset.save
    token
  end

  # The pending reset for this token, or nil when it is unknown, used or expired.
  static def pending(token)
    return nil if token.to_s.length < 20

    reset = PasswordReset.find_by("token_digest", Crypto.sha256(token.to_s))
    return nil if reset.nil?
    return nil if reset.used
    return nil if reset.expires_at < DateTime.utc.to_unix

    reset
  end
end
