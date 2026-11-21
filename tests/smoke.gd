extends SceneTree

func _initialize() -> void:
 var s := GameState.new(12345)
 s.discover(Vector2i.ZERO)
 assert(s.cities.size() >= 4)
 var a := Vector2i(2,4)
 var b := Vector2i(10,5)
 var proposal: Dictionary = RoadPlanner.plan(s.world,a,b)
 assert(proposal.has("path"))
 var price: float = s.price(proposal,0)
 assert(price < s.money)
 s.build(proposal,0)
 assert(is_equal_approx(s.money, Balance.INITIAL_MONEY-price))
 var before: float = s.money
 for i: int in range(800): s.step(0.25)
 assert(s.completed > 0)
 assert(s.money > before)
 var copy: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(s.data())))
 assert(copy.completed == s.completed)
 assert(copy.vehicles.size() == s.vehicles.size())
 var saved_income: float = copy.income
 for i: int in range(400): copy.step(0.25)
 assert(copy.income >= saved_income)
 var w1 := WorldGenerator.new(12345)
 var w2 := WorldGenerator.new(12345)
 for y: int in range(-40,40,7):
  for x: int in range(-40,40,7): assert(w1.terrain(Vector2i(x,y)) == w2.terrain(Vector2i(x,y)))
 print("SMOKE OK: coste=",price," viajes=",s.completed," vehículos=",s.vehicles.size())
 quit()
