extends SceneTree

func _initialize() -> void:
 var world := WorldGenerator.new(1)
 var blocked := Vector2i(19, 0)
 var road_type := -1
 for i: int in range(Balance.ROADS.size()):
  if not Balance.terrain_restriction(i, world.terrain(blocked)).is_empty():
   road_type = i
   break
 assert(road_type >= 0)
 var started := Time.get_ticks_msec()
 var destination: Dictionary = RoadPlanner.plan(world, Vector2i(2, 4), blocked, road_type)
 var origin: Dictionary = RoadPlanner.plan(world, blocked, Vector2i(2, 4), road_type)
 assert(destination.has("error") and origin.has("error"))
 assert(destination.conflict_terrain == world.terrain(blocked))
 assert(Time.get_ticks_msec() - started < 1000)
 print("TERRAIN ENDPOINT OK")
 quit()
