# MiniFusion — routes.

get("/", "home#index", name: "root")
get("/health", "home#health")

# Accounts
get("/signup", "registrations#new", name: "signup")
post("/signup", "registrations#create")
get("/login", "sessions#new", name: "login")
post("/login", "sessions#create")
post("/login/demo", "sessions#demo", name: "demo_login")
post("/logout", "sessions#destroy", name: "logout")
get("/password/forgot", "passwords#new", name: "forgot_password")
post("/password/forgot", "passwords#create")
get("/password/reset/:token", "passwords#edit")
post("/password/reset/:token", "passwords#update")

# "Mes plans" and the CAD editor
get("/plans", "plans#index", name: "plans")
post("/plans", "plans#create")
post("/plans/:id/duplicate", "plans#duplicate")
post("/plans/:id/delete", "plans#delete")
get("/editor/:id", "editor#show", name: "editor")

# The editor's JSON API (same-origin fetch, session cookie)
post("/api/plans", "plan_api#create")
get("/api/plans/:id", "plan_api#show")
put("/api/plans/:id", "plan_api#update")
post("/api/plans/:id/duplicate", "plan_api#duplicate")
post("/api/sources/known", "source_api#known")
get("/api/sources/:id", "source_api#show")
put("/api/sources/:id", "source_api#update")
