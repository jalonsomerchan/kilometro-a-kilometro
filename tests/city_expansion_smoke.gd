extends SceneTree

func _initialize() -> void:
 var world := WorldGenerator.new(42)
 for y: int in range(-4,5):
  for x: int in range(-4,5):
   var chunk := Vector2i(x,y)
   var cities := world.cities_for_chunk(chunk)
   assert(not cities.is_empty())
   assert(cities == world.cities_for_chunk(chunk))
 var state := GameState.new(42)
 state.discover_rect(Vector2i(-80,-80), Vector2i(80,80))
 var count := state.cities.size()
 assert(count > 24)
 state.discover_rect(Vector2i(-80,-80), Vector2i(80,80))
 assert(state.cities.size() == count)
 state._generate_demand(0.1)
 state._generate_demand(0.1)
 var later_city_has_demand := false
 for key: String in state.demand_credit:
  if int(key.get_slice(":",0)) >= 24: later_city_has_demand = true
 assert(later_city_has_demand)
 var loaded := GameState.from_data(state.data())
 var saved_count: int = loaded.cities.size()
 loaded.discover_rect(Vector2i(-80,-80), Vector2i(80,80))
 assert(loaded.cities.size() == saved_count)
 print("CITY EXPANSION OK")
 quit()
