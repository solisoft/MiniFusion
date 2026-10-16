# Account e-mails, sent over SMTP by Soli's mailer (SOLI_SMTP_* in .env).
# Under --dev with no SMTP host they land in the dev inbox, /__soli/inbox.
class AccountMailer < Mailer
  def welcome(user, link)
    @name = user.to_viewer["first_name"]
    @link = link
    this.mail(to: user.email, subject: "Bienvenue sur MiniFusion")
  end

  def reset_password(user, link)
    @name = user.to_viewer["first_name"]
    @link = link
    this.mail(to: user.email, subject: "Choisir un nouveau mot de passe MiniFusion")
  end
end
