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
const INITIAL_MONEY: float = 12000.0
const CELL_COST: float = 90.0
const BRIDGE_COST: float = 180.0
const MAX_BRIDGE: int = 5
const FIXED_STEP: float = 0.25

# Traffic and penalties, expressed in simulation seconds and euros.
const DEMAND_FACTOR: float = 0.12
const DEMAND_MAX_PER_PAIR: float = 0.55
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
