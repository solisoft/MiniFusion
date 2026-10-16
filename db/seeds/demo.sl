# The demo account and its plans, from the pieces in Exemples/.
#   soli db:seed                       (runs db/seeds.sl, then this file)
# Idempotent: an existing account is kept, a missing plan is re-created — a
# visitor who deletes or breaks a demo plan gets it back on the next run.
# The login page offers this account in one click (User.DEMO).

demo = User.DEMO
user = User.find_by("email", demo["email"])
if user.nil?
  user = User.register(demo["name"], demo["email"], demo["password"])
  print("demo account created: #{demo["email"]}")
end

examples = [
  ["Cavité usinage", "Exemples/Cavité Usinage.minifusion.json"],
  ["Pièce", "Exemples/Pièce.minifusion.json"],
  ["Barquette", "Exemples/Barquette.minifusion.json"],
  ["Pince", "Exemples/Pince.minifusion.json"],
  ["Crochet", "Exemples/Crochet.minifusion.json"],
  ["Coque et dépouilles", "Exemples/Coque et Dépouilles.json"],
  ["Révolution", "Exemples/Révolution 1.minifusion.json"]
]
existing = Plan.of_user(user._key).map { |plan| plan.name }
examples.reverse.each do |example|
  next if existing.includes?(example[0])

  plan = Plan.start(user._key, example[0])
  plan.content = File.read(example[1])
  plan.save
  print("demo plan: #{example[0]}")
end
