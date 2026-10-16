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
