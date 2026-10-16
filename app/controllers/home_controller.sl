# The public landing page and the health check the proxy polls.
class HomeController < ApplicationController
  # GET /
  def index
    @title = "MiniFusion"
    @description = "CAO paramétrique et FAO dans le navigateur."
  end

  # GET /health
  def health
    render_json({"status": "ok"})
  end
end
