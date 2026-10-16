# The public landing page and the health check the proxy polls.
class HomeController < ApplicationController
  # GET /
  def index
    @title = "Conception et usinage dans le navigateur"
    @description = "CAO paramétrique et FAO dans le navigateur : esquisses contraintes, solides exacts, " +
      "parcours d'usinage, G-code Sinumerik et Fagor. Plans enregistrés en ligne."
    @signed_in = @_signed_in?
    # The real program the "Cavité usinage" example gives (bin/landing-images).
    gcode = File.read("public/images/landing/gcode.txt") rescue ""
    @gcode_lines = gcode.split("\n").take(22)
  end

  # GET /health
  def health
    render_json({"status": "ok"})
  end
end
