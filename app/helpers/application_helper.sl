# View helpers.

# Who is signed in ({key, name, first_name, initials, email}), or nil.
def current_viewer
  session_get("viewer")
end

# The one-shot message set by the last action ({kind, message}), removed as
# it is read.
def take_flash
  message = session_get("flash")
  session_delete("flash") unless message.nil?
  message
end

# "16 oct. 2026, 18:05" for an ISO timestamp (UTC → Europe/Paris is left to
# the browser: the list shows the server's date, which is close enough).
def plan_date(iso) -> String
  return "" if iso.blank?

  months = ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."]
  text = iso.to_s
  day = text.substring(8, 10).to_i
  month = months[text.substring(5, 7).to_i - 1]
  "#{day} #{month} #{text.substring(0, 4)}, #{text.substring(11, 16)}"
end

# "12 Ko", "1,4 Mo" for a byte count.
def plan_size(bytes) -> String
  count = (bytes ?? 0).to_i
  return "#{count} o" if count < 1024
  return "#{(count / 1024.0).round(0).to_i} Ko" if count < 1048576

  str((count / 1048576.0).round(1)).replace(".", ",") + " Mo"
end

# A landing capture in both themes (bin/landing-images): the CSS shows the one
# matching <html data-theme>, and the hidden one is never fetched (lazy). A
# theme without its capture yet falls back to the dark one.
def landing_img(name: String, alt: String, sizes: String) -> String
  has_light = File.exists("public/images/landing/#{name}-light-1200.webp")
  themes = has_light ? ["dark", "light"] : ["dark"]
  themes.map do |theme|
    base = "/images/landing/#{name}-#{theme}"
    css = has_light ? "only-#{theme}" : ""
    "<img class=\"#{css}\" src=\"#{base}-1200.webp\" " +
      "srcset=\"#{base}-1200.webp 1200w, #{base}-2400.webp 2400w\" sizes=\"#{sizes}\" " +
      "width=\"2400\" height=\"1500\" loading=\"lazy\" alt=\"#{html_escape(alt)}\">"
  end.join("")
end
