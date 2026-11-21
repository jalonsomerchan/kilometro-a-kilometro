class_name Balance
extends RefCounted

const ROADS: Array[Dictionary] = [
 {"name":"Camino", "color":Color("8a6241"), "width":1.0, "speed":25.0, "capacity":1.0, "cost":1.0},
 {"name":"Carril rural", "color":Color("b79a5c"), "width":1.2, "speed":40.0, "capacity":1.5, "cost":1.5},
 {"name":"Secundaria", "color":Color("cbd1c8"), "width":1.5, "speed":60.0, "capacity":2.0, "cost":2.2},
 {"name":"Principal", "color":Color("697478"), "width":1.8, "speed":80.0, "capacity":3.0, "cost":3.3},
 {"name":"Vía rápida", "color":Color("728c9b"), "width":2.1, "speed":100.0, "capacity":4.0, "cost":4.8},
 {"name":"Autovía", "color":Color("547eb3"), "width":2.5, "speed":120.0, "capacity":6.0, "cost":6.8},
 {"name":"Autopista", "color":Color("8469a6"), "width":2.8, "speed":120.0, "capacity":8.0, "cost":9.0}
]

static func terrain_restriction(road_type: int, terrain: String) -> String:
 if terrain == "agua" or road_type <= 1: return ""
 if road_type >= 4 and terrain not in ["pradera","llanura"]:
  return "%s: solo se construye en terreno llano; no admite %s." % [ROADS[road_type].name,WorldGenerator.terrain_name(terrain)]
 if terrain == "marisma":
  return "%s: el terreno de marisma no admite esta categoría de vía." % ROADS[road_type].name
 return ""

static func terrain_hint(road_type: int) -> String:
 if road_type <= 1: return "Apta para todos los terrenos; el agua requiere puente."
 if road_type <= 3: return "Apta para montañas, bosques y colinas; no para marismas. El agua requiere puente."
 return "Solo en terreno llano (pradera o llanura); el agua requiere puente."
# Short route identifiers, indexed identically to ROADS.
const ROAD_PREFIXES: Array[String] = ["C","CR","S","P","VR","A","AP"]
const INITIAL_MONEY: float = 12000.0
const CELL_COST: float = 90.0
const BRIDGE_COST: float = 180.0
const MAX_BRIDGE: int = 5
const FIXED_STEP: float = 0.25

# Traffic and penalties, expressed in simulation seconds and euros.
const DEMAND_FACTOR: float = 0.12
const DEMAND_MAX_PER_PAIR: float = 1.5
const DEMAND_MAX_CITIES: int = 24
const DEMAND_DESTINATIONS: int = 6
const TRAFFIC_MAX_VEHICLES: int = 300
const ROUTE_REFRESH_SECONDS: float = 5.0
const CAPACITY_PER_CELL: float = 0.7
const CONGESTION_WARNING: float = 0.75
const CONGESTION_FINE_THRESHOLD: float = 1.0
const CONGESTION_FINE_PER_SECOND: float = 2.5
const LATE_GRACE_MULTIPLIER: float = 1.6
const LATE_FINE_PER_SECOND: float = 4.0
const LATE_FINE_MAX_FARE: float = 0.8
const DAY_SECONDS: float = 120.0

# Progression and optional finance.
const ROAD_UNLOCK_TRIPS: Array[int] = [0,0,10,30,60,100,160]
const ROAD_UNLOCK_CITIES: Array[int] = [0,0,2,3,3,4,4]
const ROAD_UNLOCK_RELIABILITY: Array[float] = [0.0,0.0,0.0,0.65,0.70,0.75,0.80]
const LOAN_PRINCIPAL: float = 3000.0
const LOAN_TOTAL: float = 3300.0
const LOAN_DAILY_PAYMENT: float = 550.0

# Junction capacity: seconds per vehicle, before and after improvements.
const JUNCTION_UNCONTROLLED_HEADWAY: float = 1.75
const JUNCTION_CONTROLLED_HEADWAY: float = 0.75
const JUNCTION_ROUNDABOUT_HEADWAY: float = 0.45
const JUNCTION_QUEUE_FINE: float = 0.6
const ROUNDABOUT_COST: float = 1400.0
const ROUNDABOUT_WORK_SECONDS: float = 12.0

const OVERPASS_COST: float = 650.0
const OVERPASS_WORK_SECONDS: float = 3.0
