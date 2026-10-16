# Who uses MiniFusion. The password is hashed (argon2) and never stored; the
# session keeps `to_viewer`, never the digest.
class User < Model
  static MIN_PASSWORD: Int = 8
  # The shared demo account (db/seeds/demo.sl). Public on purpose: the login
  # page signs anyone in with it in one click; the seed restores its plans.
  static DEMO: Hash = {"name": "Compte démo", "email": "demo@minifusion.test", "password": "demo-minifusion"}

  attr_accessible("name", "email")
  validates("name", {"presence": true, "max_length": 80})
  validates(
    "email",
    {
      "presence": true,
      "format": "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$",
      "uniqueness": true
    }
  )
  validates("password_digest", {"presence": true})
  before_save("normalize")

  # A new account from the sign-up form. A short password is refused on the
  # `password` field, before anything is written.
  static def register(name, email, password)
    user = User.new({"name": name.to_s.trim, "email": email.to_s})
    if password.to_s.length < User.MIN_PASSWORD
      user._errors = [{"field": "password", "message": "doit contenir au moins #{User.MIN_PASSWORD} caractères"}]
      return user
    end

    user.password_digest = password_hash(password.to_s)
    user.save
    user
  end

  # The user for these credentials, or nil — the same nil for an unknown
  # email and a wrong password.
  static def authenticate(email, password)
    user = User.find_by("email", email.to_s.trim.downcase)
    return nil if user.nil?
    return nil unless password_verify(password.to_s, user.password_digest)

    user
  end

  # "AM" for "Ada Martin", "?" for nobody.
  def initials -> String
    return "?" if @name.blank?

    @name.to_s.split(" ").take(2).map { |part| part.substring(0, 1).upcase }.join("")
  end

  # What the session keeps, so a page knows its viewer without a query.
  def to_viewer
    {
      "key": @_key,
      "name": @name,
      "first_name": @name.to_s.split(" ").first,
      "initials": @initials,
      "email": @email
    }
  end

  def normalize
    @email = @email.trim.downcase unless @email.blank?
    true
  end
end
