extends SceneTree

func _initialize() -> void:
 var state := GameState.new(123)
 state.money = 1000000.0
 var path: Array[Vector2i] = [Vector2i(2,4),Vector2i(3,4)]
 var proposal: Dictionary = RoadPlanner._describe(state.world,path)
 var expected: Array[String] = ["C1","CR1","S1","P1","VR1","A1","AP1"]
 for type: int in range(7):
  state.build(proposal,type)
  assert(str(state.roads[-1].road_name)==expected[type])
 state.build(proposal,2)
 assert(state.roads[-1].road_name=="S2")
 for i: int in range(20): state.step(0.25)
 var old_id: int = int(state.roads[2].id)
 assert(state.start_work(state.roads[2],{"kind":"upgrade","target":3,"cost":0.0,"duration":0.25}))
 assert(state.roads[2].road_name=="S1")
 state.step(0.25)
 assert(state.roads[2].road_name=="P2" and int(state.roads[2].id)==old_id)
 state.remove_road(state.roads[-1])
 var loaded: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(state.data())))
 assert(loaded.roads[2].road_name=="P2")
 loaded.build(proposal,2)
 assert(loaded.roads[-1].road_name=="S3")
 var legacy: Dictionary = loaded.data().duplicate(true)
 legacy.erase("road_number_counters")
 for road: Dictionary in legacy.roads: road.erase("road_name")
 var migrated: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(legacy)))
 assert(migrated.roads[0].road_name=="C1" and migrated.roads[1].road_name=="CR1")
 assert(migrated.roads[2].road_name=="P1" and migrated.roads[3].road_name=="P2")
 assert(migrated.roads[-1].road_name=="S1")
 print("ROAD NAMES OK: categorías, mejora, guardado y partidas anteriores")
 quit()
