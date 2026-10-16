# MiniFusion — routes.

get("/", "home#index", name: "root")
get("/health", "home#health")

# CAD editor
get("/editor", "editor#show", name: "editor")
