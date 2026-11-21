class_name WorldGenerator
extends RefCounted

var seed_value: int = 1
var noise: FastNoiseLite

func _init(value: int = 1) -> void:
 seed_value = value
 noise = FastNoiseLite.new()
 noise.seed = value
 noise.frequency = 0.025
 noise.fractal_octaves = 3

func terrain(p: Vector2i) -> String:
 if p in [Vector2i(2,4), Vector2i(10,5), Vector2i(27,7), Vector2i(11,24)]: return "pradera"
 # The initial river is continuous and the same global noise is sampled across chunks.
 var river_x: float = 19.0 + sin(float(p.y) * 0.055 + float(seed_value % 13)) * 2.0
 if absf(float(p.x) - river_x) < 1.5:
  return "agua"
 var n: float = noise.get_noise_2d(float(p.x), float(p.y))
 if n < -0.48: return "agua"
 if n < -0.20: return "bosque"
 if n > 0.53: return "roca"
 if n > 0.27: return "colina"
 return "pradera"

func cities_for_chunk(chunk: Vector2i) -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 if chunk == Vector2i.ZERO:
  result.append(_city("Valdeprado", Vector2i(2, 4), 1200))
  result.append(_city("Los Olmos", Vector2i(10, 5), 1800))
  result.append(_city("Ribera", Vector2i(27, 7), 6200))
  result.append(_city("Villalta", Vector2i(11, 24), 15000))
  return result
 var h: int = absi(hash(Vector3i(chunk.x, chunk.y, seed_value)))
 if h % 3 != 0: return result
 # Candidate constrained to the interior ensures at least 8 cells between chunks.
 var p := chunk * 32 + Vector2i(5 + h % 22, 5 + (h / 31) % 22)
 if p.distance_to(Vector2i(2, 4)) < 15.0 or terrain(p) == "agua" or terrain(p) == "roca": return result
 var names: Array[String] = ["Alameda", "Castañar", "Mirador", "Pinar", "Fuente", "Ladera", "Arroyo", "Vega"]
 var population: int = 800 + (h / 97) % 13000
 result.append(_city(names[h % names.size()] + " " + str(h % 1000), p, population))
 return result

func _city(city_name: String, p: Vector2i, population: int) -> Dictionary:
 return {"name":city_name, "x":p.x, "y":p.y, "population":population, "completed":{}}
