class_name WorldGenerator
extends RefCounted

var seed_value: int = 1
var noise: FastNoiseLite
var moisture_noise: FastNoiseLite

func _init(value: int = 1) -> void:
 seed_value = value
 noise = FastNoiseLite.new()
 noise.seed = value
 noise.frequency = 0.025
 noise.fractal_octaves = 3
 moisture_noise = FastNoiseLite.new()
 moisture_noise.seed = value + 104729
 moisture_noise.frequency = 0.047
 moisture_noise.fractal_octaves = 2

func terrain(p: Vector2i) -> String:
 if p in [Vector2i(2,4), Vector2i(10,5), Vector2i(27,7), Vector2i(11,24)]: return "pradera"
 # The initial river is continuous and the same global noise is sampled across chunks.
 var river_x: float = 19.0 + sin(float(p.y) * 0.055 + float(seed_value % 13)) * 2.0
 if absf(float(p.x) - river_x) < 1.5:
  return "agua"
 var n: float = noise.get_noise_2d(float(p.x), float(p.y))
 var moisture: float = moisture_noise.get_noise_2d(float(p.x), float(p.y))
 if n < -0.48: return "agua"
 if n > 0.53: return "montaña"
 if n > 0.27: return "colina"
 if n < -0.20: return "bosque"
 if n > -0.10 and n < 0.12 and moisture < -0.30: return "marisma"
 if n > -0.10 and n < 0.22 and moisture > 0.42: return "desierto"
 if n > 0.10 and moisture > 0.0: return "llanura"
 return "pradera"

static func terrain_name(kind: String) -> String:
 return {"pradera":"pradera","llanura":"llanura","bosque":"bosque","colina":"colina","montaña":"montaña","roca":"montaña","marisma":"marisma","desierto":"desierto","agua":"agua"}.get(kind,kind)

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
 if p.distance_to(Vector2i(2, 4)) < 15.0 or terrain(p) in ["agua","montaña","marisma"]: return result
 var names: Array[String] = ["Alameda", "Castañar", "Mirador", "Pinar", "Fuente", "Ladera", "Arroyo", "Vega"]
 var population: int = 800 + (h / 97) % 13000
 result.append(_city(names[h % names.size()] + " " + str(h % 1000), p, population))
 return result

func _city(city_name: String, p: Vector2i, population: int) -> Dictionary:
 return {"name":city_name, "x":p.x, "y":p.y, "population":population, "completed":{}}

static func city_size(population: int) -> String:
 if population < 3000: return "Pequeña"
 if population < 10000: return "Mediana"
 return "Grande"
