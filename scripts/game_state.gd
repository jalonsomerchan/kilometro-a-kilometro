class_name GameState
extends RefCounted

var seed_value: int = 1
var game_name: String = "Mi partida"
var guided: bool = true
var money: float = Balance.INITIAL_MONEY
var elapsed: float = 0.0
var completed: int = 0
var income: float = 0.0
var expenses: float = 0.0
var cities: Array = []
var chunks: Array = []
var roads: Array = []
var vehicles: Array = []
var world: WorldGenerator
var next_id: int = 1
var spawn_clock: float = 0.0
var cursor_x: int = 2
var cursor_y: int = 4
var interrupted: int = 0
var route_cache: Dictionary = {}
var events: Array = []
var forecasts: Array = []
var next_event: float = 240.0
var latest_notice: String = ""
var notice_road: int = -1
var notice_point: Array = []
var demand_credit: Dictionary = {}
var potential_demand: float = 0.0
var started_trips: int = 0
var unmet_demand: int = 0
var traffic_load: Dictionary = {}
var traffic_counts: Dictionary = {}
var route_refresh_clock: float = 0.0
var congestion_fines: float = 0.0
var delay_fines: float = 0.0
var today_penalties: float = 0.0
var yesterday_penalties: float = 0.0
var late_trips: int = 0
var junction_busy_until: Dictionary = {}
var roundabouts: Dictionary = {}
var junction_queue_counts: Dictionary = {}
var junction_delays: Dictionary = {}
var junction_queue_serial: int = 0
var junction_fines: float = 0.0
var junction_warned: Dictionary = {}
var reroute_budget: int = 0
var income_day_start: float = 0.0
var expenses_day_start: float = 0.0
var yesterday_income: float = 0.0
var yesterday_expenses: float = 0.0
var loan_taken: bool = false
var loan_remaining: float = 0.0
var loan_overdue: int = 0
var contract: Dictionary = {}
var contracts_completed: int = 0
var toll_income: float = 0.0
var contract_income: float = 0.0
var contract_history: Array = []
var next_contract_check: float = 0.0

func _init(seed_number: int = 1) -> void:
 seed_value = seed_number
 world = WorldGenerator.new(seed_value)

func discover(p: Vector2i) -> void:
 var chunk := Vector2i(floori(float(p.x) / 32.0), floori(float(p.y) / 32.0))
 for y: int in range(chunk.y - 1, chunk.y + 2):
  for x: int in range(chunk.x - 1, chunk.x + 2):
   var key: String = "%d,%d" % [x,y]
   if chunks.has(key): continue
   chunks.append(key)
   for city: Dictionary in world.cities_for_chunk(Vector2i(x,y)): cities.append(city)

func price(proposal: Dictionary, road_type: int) -> float:
 return ceil(float(proposal.length) * Balance.CELL_COST * float(Balance.ROADS[road_type].cost) + float(proposal.terrain_cost) + float(proposal.water) * Balance.BRIDGE_COST + float(proposal.get("overpass_cost",0.0)))

func build(proposal: Dictionary, road_type: int) -> void:
 var amount: float = price(proposal, road_type)
 money -= amount
 expenses += amount
 var points: Array = []
 for p: Vector2i in proposal.path: points.append([p.x,p.y])
 roads.append({"id":next_id, "path":points, "type":road_type, "length":proposal.length, "water":proposal.water, "condition":100.0, "work":maxf(4.0, float(proposal.length) * 0.7), "speed_limit":Balance.ROADS[road_type].speed, "trips":0, "raised_indices":proposal.get("raised_indices",[]).duplicate(), "crossings":proposal.get("crossings",[]).duplicate(true)})
 roads[-1]["bridges"] = _create_bridges(roads[-1])
 next_id += 1
 route_cache.clear()

func _create_bridges(road: Dictionary) -> Array:
 var bridges: Array = []
 var path: Array = road.path
 var first: int = -1
 for i: int in range(path.size()+1):
  var water: bool = false
  if i < path.size(): water = world.terrain(Vector2i(int(path[i][0]),int(path[i][1]))) == "agua"
  if water and first < 0: first = i
  if not water and first >= 0:
   bridges.append({"start":first,"end":i-1,"condition":100.0,"category":int(road.type)})
   first = -1
 return bridges

func step(dt: float) -> void:
 var previous_day: int = int(elapsed / Balance.DAY_SECONDS)
 elapsed += dt
 if int(elapsed / Balance.DAY_SECONDS) != previous_day:
  yesterday_income = income - income_day_start
  yesterday_expenses = expenses - expenses_day_start
  income_day_start = income
  expenses_day_start = expenses
  _pay_loan_installment()
  yesterday_penalties = today_penalties
  today_penalties = 0.0
 _update_traffic()
 reroute_budget = 2
 route_refresh_clock += dt
 if route_refresh_clock >= Balance.ROUTE_REFRESH_SECONDS:
  route_refresh_clock = 0.0
  route_cache.clear()
 _charge_congestion(dt)
 for junction_key: String in roundabouts:
  var roundabout: Dictionary = roundabouts[junction_key]
  if float(roundabout.get("work",0.0)) > 0.0:
   roundabout.work = maxf(0.0,float(roundabout.work)-dt)
   if float(roundabout.work) == 0.0:
    route_cache.clear()
    notice_point = []
    latest_notice = "Rotonda terminada en (%d,%d)." % [roundabout.x,roundabout.y]
    notice_road = int(roundabout.get("road_id",-1))
 _update_contract()
 GameEvents.advance(self,dt)
 if completed > 0 and elapsed >= next_event and not roads.is_empty():
  next_event = elapsed + 240.0
  var road: Dictionary = roads[posmod(seed_value + int(elapsed / 240.0), roads.size())]
  var kinds: Array[String] = ["snow","fair"]
  if GameEvents.road_has_terrain(self,road,["bosque"]): kinds.append("fire")
  if GameEvents.road_has_terrain(self,road,["colina","roca"]): kinds.append("landslide")
  if int(road.get("water",0)) > 0: kinds.append("flood")
  var kind: String = kinds[posmod(seed_value + int(elapsed / 240.0),kinds.size())]
  if kind in ["snow","flood","fair"]: GameEvents.forecast(self,kind,int(road.id))
  else: GameEvents.start(self,kind,int(road.id))
 for road: Dictionary in roads:
  _process_scheduled_work(road)
  if float(road.work) > 0.0:
   road.work = maxf(0.0, float(road.work) - dt)
   if float(road.work) == 0.0:
    if road.has("pending_condition"): road.condition = road.pending_condition; road.erase("pending_condition")
    if road.has("pending_bridge"):
     var bridge_index: int = int(road.pending_bridge)
     if bridge_index >= 0 and bridge_index < road.get("bridges",[]).size(): road.bridges[bridge_index].condition = 100.0
     road.erase("pending_bridge")
    if road.has("pending_type"):
     road.type = road.pending_type
     road.speed_limit = Balance.ROADS[int(road.type)].speed
     for bridge: Dictionary in road.get("bridges",[]):
      if int(road.type) > int(bridge.category):
       bridge.category = int(road.type)
       bridge.condition = 100.0
     road.erase("pending_type")
    route_cache.clear()
  else:
   var wear_factor: float = 1.0 + maxf(0.0,float(traffic_load.get(int(road.id),0.0)))*0.5
   if bool(road.get("maintenance",false)):
    var maintenance_cost: float = maxf(0.1,float(road.length)*0.015)*dt
    if money >= maintenance_cost:
     money -= maintenance_cost
     expenses += maintenance_cost
     wear_factor *= 0.35
    else:
     road.maintenance = false
     notice_point = []
     latest_notice = "Mantenimiento suspendido en el tramo %d: fondos insuficientes." % int(road.id)
     notice_road = int(road.id)
   road.condition = maxf(0.0, float(road.condition) - dt * 0.0007 * wear_factor)
   for bridge: Dictionary in road.get("bridges",[]):
    var old_condition: float = float(bridge.condition)
    bridge.condition = maxf(0.0,old_condition-dt*0.001*wear_factor)
    if old_condition >= 10.0 and float(bridge.condition) < 10.0:
     notice_point = []
     latest_notice = "Puente del tramo %d cerrado por deterioro." % int(road.id)
     notice_road = int(road.id)
     route_cache.clear()
 spawn_clock += dt
 if spawn_clock >= 1.0:
  var demand_dt: float = spawn_clock
  spawn_clock = 0.0
  _generate_demand(demand_dt)
 var remove: Array = []
 for vehicle: Dictionary in vehicles:
  if vehicle.has("route"):
   vehicle.travel_time = float(vehicle.get("travel_time",0.0)) + dt
   if _advance_route_vehicle(vehicle, dt): remove.append(vehicle)
   continue
  var road: Dictionary = _road_by_id(int(vehicle.road))
  if road.is_empty():
   remove.append(vehicle)
   continue
  var capacity: float = float(Balance.ROADS[int(road.type)].capacity) * 5.0
  var occupancy: int = 0
  for other: Dictionary in vehicles:
   if other.has("road") and other.road == vehicle.road: occupancy += 1
  var congestion: float = maxf(0.22, 1.0 - maxf(0.0, float(occupancy) - capacity) / (capacity * 2.0))
  var speed: float = float(road.speed_limit) / 25.0 * congestion * maxf(0.3, float(road.condition) / 100.0)
  vehicle.progress = float(vehicle.progress) + dt * speed / maxf(1.0, float(road.length))
  if float(vehicle.progress) >= 1.0:
   var fare: float = 110.0 + float(vehicle.direct_distance) * 8.0
   money += fare
   income += fare
   completed += 1
   road.trips = int(road.trips) + 1
   var city: Dictionary = cities[int(vehicle.origin)]
   var destination: String = str(cities[int(vehicle.destination)].name)
   city.completed[destination] = int(city.completed.get(destination, 0)) + 1
   remove.append(vehicle)
 for vehicle: Dictionary in remove: vehicles.erase(vehicle)

func _update_traffic() -> void:
 traffic_counts.clear()
 traffic_load.clear()
 junction_queue_counts.clear()
 junction_delays.clear()
 for vehicle: Dictionary in vehicles:
  var road_id: int = -1
  if vehicle.has("signal_pending"):
   var pending: Dictionary = vehicle.signal_pending
   var junction_key: String = str(pending.key)
   junction_queue_counts[junction_key] = int(junction_queue_counts.get(junction_key,0)) + 1
   road_id = int(pending.get("previous_road",-1))
  elif vehicle.has("route") and int(vehicle.route_index) < vehicle.route.size():
   road_id = int(vehicle.route[int(vehicle.route_index)].road)
  elif vehicle.has("road"): road_id = int(vehicle.road)
  if road_id >= 0: traffic_counts[road_id] = int(traffic_counts.get(road_id,0)) + 1
 for road: Dictionary in roads:
  var capacity: float = road_capacity(road)
  traffic_load[int(road.id)] = float(traffic_counts.get(int(road.id),0)) / capacity
 for key: String in junction_queue_counts:
  junction_delays[key] = float(junction_queue_counts[key])*_junction_headway(key)
 for key: Variant in junction_warned.keys():
  if int(junction_queue_counts.get(key,0)) < 2: junction_warned.erase(key)

func road_capacity(road: Dictionary) -> float:
 var length: float = maxf(1.0,float(road.get("length",float(road.path.size()-1))))
 var condition: float = maxf(0.3,float(road.condition)/100.0)
 var weather: float = 0.65 if int(road.get("snow_count",0)) > 0 else 1.0
 return maxf(1.0,(2.0+length*Balance.CAPACITY_PER_CELL)*float(Balance.ROADS[int(road.type)].capacity)*condition*weather)

func effective_speed(road: Dictionary) -> float:
 var load: float = float(traffic_load.get(int(road.id),0.0))
 var congestion: float = maxf(0.16,1.0/(1.0+2.0*pow(maxf(0.0,load-0.65),2.0)))
 return float(road.speed_limit) * congestion * maxf(0.3,float(road.condition)/100.0) * (0.55 if int(road.get("snow_count",0))>0 else 1.0)

func _charge_congestion(dt: float) -> void:
 var charge: float = 0.0
 for road: Dictionary in roads:
  var load: float = float(traffic_load.get(int(road.id),0.0))
  if float(road.work) <= 0.0 and int(road.get("event_closures",0)) == 0:
   charge += maxf(0.0,load-Balance.CONGESTION_FINE_THRESHOLD)*Balance.CONGESTION_FINE_PER_SECOND*dt
   if load > Balance.CONGESTION_FINE_THRESHOLD and not bool(road.get("jam_warning",false)):
    road.jam_warning = true
    notice_point = []
    latest_notice = "Atasco en el tramo %d: %.0f%% de ocupación. Genera penalizaciones." % [int(road.id),load*100.0]
    notice_road = int(road.id)
   elif load < Balance.CONGESTION_WARNING:
    road.jam_warning = false
 var queue_charge: float = 0.0
 for key: String in junction_queue_counts:
  var count: int = int(junction_queue_counts[key])
  queue_charge += maxf(0.0,float(count)-2.0)*Balance.JUNCTION_QUEUE_FINE*dt
  if count >= 4 and not junction_warned.has(key):
   junction_warned[key] = true
   notice_point = []
   latest_notice = "Cola en el cruce (%s): %d vehículos esperando." % [key,count]
   var pieces: PackedStringArray = key.split(",")
   notice_road = -1
   if pieces.size() == 2:
    notice_point = [int(pieces[0]),int(pieces[1])]
    for road: Dictionary in roads:
     if road.path.has([int(pieces[0]),int(pieces[1])]): notice_road = int(road.id); break
 junction_fines += queue_charge
 charge += queue_charge
 if charge > 0.0:
  money -= charge
  expenses += charge
  congestion_fines += charge
  today_penalties += charge

func _generate_demand(dt: float) -> void:
 var count: int = mini(cities.size(),Balance.DEMAND_MAX_CITIES)
 if count < 2: return
 var budget: int = 12
 var phase: float = fposmod(elapsed,Balance.DAY_SECONDS)/Balance.DAY_SECONDS
 var multiplier: float = 0.55 if phase >= 0.75 else 1.0
 for origin: int in range(count):
  var candidates: Array = []
  for target: int in range(count):
   if target != origin: candidates.append(target)
  candidates.sort_custom(func(a: int,b: int) -> bool:
   return _city_position(origin).distance_to(_city_position(a)) < _city_position(origin).distance_to(_city_position(b)))
  for destination: int in candidates.slice(0,Balance.DEMAND_DESTINATIONS):
   var distance: float = _city_position(origin).distance_to(_city_position(destination))
   var population: float = sqrt(float(cities[origin].population)*float(cities[destination].population))
   var rate: float = minf(Balance.DEMAND_MAX_PER_PAIR,Balance.DEMAND_FACTOR*population/1500.0/(1.0+distance/30.0))*multiplier
   var event_multiplier: float = 1.0
   for event: Dictionary in events:
    if event.kind == "fair" and int(event.get("target_city",-1)) == destination: event_multiplier *= 2.0
   var demand: float = rate*dt*event_multiplier
   potential_demand += demand
   var key: String = "%d:%d" % [origin,destination]
   var credit: float = float(demand_credit.get(key,0.0))+demand
   while credit >= 1.0:
    credit -= 1.0
    if budget <= 0 or vehicles.size() >= Balance.TRAFFIC_MAX_VEHICLES:
     unmet_demand += 1
     continue
    budget -= 1
    if not _start_trip(origin,destination): unmet_demand += 1
   demand_credit[key] = credit

func _start_trip(origin: int, destination: int) -> bool:
 var key: String = "%d:%d" % [origin,destination]
 if not route_cache.has(key): route_cache[key] = RoadNetwork.route(roads,_city_position(origin),_city_position(destination),-1,traffic_load,-1,-1,junction_delays,roundabouts)
 var route: Array = route_cache[key]
 if route.is_empty(): return false
 vehicles.append({"route":route.duplicate(true),"route_index":0,"segment_progress":0.0,"origin":origin,"destination":destination,"direct_distance":_city_position(origin).distance_to(_city_position(destination)),"travel_time":0.0,"last_reroute":elapsed,"toll_due":0.0,"toll_road":-1})
 _enter_toll_road(vehicles[-1],int(route[0].road))
 started_trips += 1
 return true

# Used by existing tests and saves; normal play uses population-based demand.
func _spawn() -> void:
 if cities.size() < 2: return
 var origin: int = int(elapsed / 3.0) % cities.size()
 var candidates: Array = []
 for i: int in range(cities.size()):
  if i != origin: candidates.append(i)
 candidates.sort_custom(func(a: int,b: int) -> bool:
  return _city_position(origin).distance_to(_city_position(a)) < _city_position(origin).distance_to(_city_position(b)))
 for destination: int in candidates.slice(0,Balance.DEMAND_DESTINATIONS):
  if _start_trip(origin,destination): return

func _city_position(index: int) -> Vector2i:
 return Vector2i(int(cities[index].x),int(cities[index].y))

func _enter_toll_road(vehicle: Dictionary, road_id: int) -> void:
 if int(vehicle.get("toll_road",-1)) == road_id: return
 var road: Dictionary = _road_by_id(road_id)
 if road.is_empty(): return
 vehicle.toll_road = road_id
 if int(road.type) == 6: vehicle.toll_due = float(vehicle.get("toll_due",0.0))+maxf(0.0,float(road.get("toll",0.0)))

func connected_cities() -> int:
 var connected: Dictionary = {}
 var n: int = mini(cities.size(),12)
 for a: int in range(n):
  for b: int in range(a+1,n):
   if not RoadNetwork.route(roads,_city_position(a),_city_position(b)).is_empty():
    connected[a] = true
    connected[b] = true
 return connected.size()

func reliability() -> float:
 if completed + interrupted == 0: return 1.0
 return float(completed)/float(completed+interrupted)

func unlock_reason(road_type: int) -> String:
 var required: int = Balance.ROAD_UNLOCK_TRIPS[road_type]
 var cities_required: int = Balance.ROAD_UNLOCK_CITIES[road_type]
 var reliability_required: float = Balance.ROAD_UNLOCK_RELIABILITY[road_type]
 if required == 0 and cities_required == 0: return ""
 var cities_connected: int = connected_cities()
 if completed >= required and cities_connected >= cities_required and reliability() >= reliability_required: return ""
 return "Requiere %d viajes (%d), %d ciudades conectadas (%d) y %.0f%% de fiabilidad (%.0f%%)." % [required,completed,cities_required,cities_connected,reliability_required*100.0,reliability()*100.0]

func take_loan() -> bool:
 if loan_taken or money >= Balance.LOAN_PRINCIPAL: return false
 loan_taken = true
 loan_remaining = Balance.LOAN_TOTAL
 money += Balance.LOAN_PRINCIPAL
 return true

func _pay_loan_installment() -> void:
 if loan_remaining <= 0.0: return
 var installment: float = minf(loan_remaining,Balance.LOAN_DAILY_PAYMENT)
 if money < installment:
  loan_overdue += 1
  notice_point = []
  latest_notice = "Cuota del préstamo pendiente: %.0f €." % installment
  notice_road = -1
  return
 money -= installment
 expenses += installment
 loan_remaining -= installment
 notice_point = []
 latest_notice = "Cuota del préstamo pagada: %.0f €. Deuda restante: %.0f €." % [installment,loan_remaining]
 notice_road = -1

func offer_contract(origin: int, destination: int) -> void:
 contract = {"origin":origin,"destination":destination,"status":"offered","reward":ceil(1600.0+_city_position(origin).distance_to(_city_position(destination))*100.0),"duration":Balance.DAY_SECONDS*4.0}

func accept_contract() -> void:
 if contract.get("status","") != "offered": return
 contract.status = "active"
 contract.deadline = elapsed+float(contract.duration)

func _update_contract() -> void:
 if contract.get("status","") != "active": return
 if elapsed < next_contract_check and elapsed < float(contract.deadline): return
 next_contract_check = elapsed + 2.0
 var origin: int = int(contract.origin)
 var destination: int = int(contract.destination)
 if origin >= cities.size() or destination >= cities.size(): return
 if not RoadNetwork.route(roads,_city_position(origin),_city_position(destination)).is_empty():
  money += float(contract.reward)
  income += float(contract.reward)
  contract_income += float(contract.reward)
  contract.status = "completed"
  contract_history.append("%d:%d" % [mini(origin,destination),maxi(origin,destination)])
  contracts_completed += 1
  notice_point = []
  latest_notice = "Contrato completado: +%.0f €." % float(contract.reward)
  notice_road = -1
 elif elapsed >= float(contract.deadline):
  contract.status = "expired"
  notice_point = []
  latest_notice = "El plazo del contrato de conexión ha terminado."
  notice_road = -1

func _junction_key(point: Vector2i) -> String:
 return "%d,%d" % [point.x,point.y]

func _junction_headway(key: String) -> float:
 if roundabouts.has(key) and float(roundabouts[key].get("work",0.0)) <= 0.0:
  return Balance.JUNCTION_ROUNDABOUT_HEADWAY
 var pieces: PackedStringArray = key.split(",")
 if pieces.size() != 2: return Balance.JUNCTION_UNCONTROLLED_HEADWAY
 var point: Array = [int(pieces[0]),int(pieces[1])]
 for road: Dictionary in roads:
  var index: int = road.path.find(point)
  if index < 0 or RoadNetwork._level(road,index) != 0: continue
  for signal_data: Dictionary in road.get("signals",[]):
   if int(signal_data.index) == index: return Balance.JUNCTION_CONTROLLED_HEADWAY
 return Balance.JUNCTION_UNCONTROLLED_HEADWAY

func _junction_turn(vehicle: Dictionary) -> bool:
 var pending: Dictionary = vehicle.signal_pending
 var key: String = str(pending.key)
 if elapsed < float(pending.ready_at) or elapsed < float(junction_busy_until.get(key,0.0)): return false
 # Give unsignalled priority traffic time to enter, but cap the wait to prevent starvation.
 if pending.get("signal_type","none") in ["yield","stop"] and elapsed-float(pending.get("queued_at",elapsed)) < 3.0:
  if _priority_approaching(key,vehicle): return false
 var my_time: float = float(pending.get("queued_at",pending.ready_at))
 var my_order: int = int(pending.get("order",0))
 for other: Dictionary in vehicles:
  if is_same(other,vehicle) or not other.has("signal_pending"): continue
  var waiting: Dictionary = other.signal_pending
  if str(waiting.key) != key or int(waiting.get("level",0)) != int(pending.get("level",0)): continue
  if elapsed < float(waiting.ready_at): continue
  var other_time: float = float(waiting.get("queued_at",waiting.ready_at))
  var other_order: int = int(waiting.get("order",0))
  if other_time < my_time or (is_equal_approx(other_time,my_time) and other_order < my_order): return false
 return true

func can_build_roundabout(point: Vector2i) -> String:
 var p: Array = [point.x,point.y]
 if roundabouts.has(_junction_key(point)): return "Ya existe una rotonda aquí."
 if world.terrain(point) in ["agua","roca"]: return "La rotonda necesita terreno firme."
 for city: Dictionary in cities:
  if int(city.x)==point.x and int(city.y)==point.y: return "No se puede construir sobre una ciudad."
 var compatible: int = 0
 var arms: Dictionary = {}
 for road: Dictionary in roads:
  var index: int = road.path.find(p)
  if index < 0: continue
  if RoadNetwork._level(road,index) != 0 or int(road.type) > 3: return "Hay una vía elevada o incompatible en este punto."
  if RoadNetwork.road_closed(road): return "Espera a que las carreteras del cruce estén abiertas."
  compatible += 1
  for next_index: int in [index-1,index+1]:
   if next_index < 0 or next_index >= road.path.size(): continue
   var other: Array = road.path[next_index]
   var direction := Vector2i(signi(int(other[0])-point.x),signi(int(other[1])-point.y))
   if direction != Vector2i.ZERO: arms[direction] = true
 if compatible < 2 or arms.size() < 3: return "Selecciona un cruce a nivel con al menos tres accesos."
 if money < Balance.ROUNDABOUT_COST: return "Fondos insuficientes."
 return ""

func build_roundabout(point: Vector2i) -> bool:
 if not can_build_roundabout(point).is_empty(): return false
 var road_id: int = -1
 for road: Dictionary in roads:
  if road.path.has([point.x,point.y]): road_id = int(road.id); break
 money -= Balance.ROUNDABOUT_COST
 expenses += Balance.ROUNDABOUT_COST
 roundabouts[_junction_key(point)] = {"x":point.x,"y":point.y,"work":Balance.ROUNDABOUT_WORK_SECONDS,"road_id":road_id}
 route_cache.clear()
 return true

func remove_road(road: Dictionary) -> void:
 roads.erase(road)
 route_cache.clear()
 var obsolete: Array = []
 for key: String in roundabouts:
  var point: Array = [int(roundabouts[key].x),int(roundabouts[key].y)]
  var roads_at_level: int = 0
  for other: Dictionary in roads:
   var index: int = other.path.find(point)
   if index >= 0 and int(other.type) <= 3 and RoadNetwork._level(other,index) == 0: roads_at_level += 1
  if roads_at_level < 2: obsolete.append(key)
 for key: String in obsolete: roundabouts.erase(key)

func _priority_approaching(key: String, waiting_vehicle: Dictionary) -> bool:
 var parts: PackedStringArray = key.split(",")
 var point := Vector2i(int(parts[0]),int(parts[1]))
 for other: Dictionary in vehicles:
  if is_same(other,waiting_vehicle) or other.has("signal_pending") or not other.has("route"): continue
  var idx: int = int(other.route_index)
  if idx >= other.route.size() or float(other.segment_progress) < 0.65: continue
  var segment: Dictionary = other.route[idx]
  var road: Dictionary = _road_by_id(int(segment.road))
  if road.is_empty(): continue
  var end_index: int = int(segment.to_index)
  var end: Array = road.path[end_index]
  if Vector2i(int(end[0]),int(end[1])) != point: continue
  if RoadNetwork._level(road,end_index) != int(waiting_vehicle.signal_pending.get("level",0)): continue
  # A signed approach joins the deterministic waiting queue instead of being priority.
  var direction: int = 1 if end_index > int(segment.from_index) else -1
  var signed: bool = false
  for signal_data: Dictionary in road.get("signals",[]):
   if int(signal_data.index) == end_index and int(signal_data.direction) == direction: signed = true; break
  if not signed: return true
 return false

func _has_junction(road: Dictionary, index: int) -> bool:
 if int(road.type) > 3: return false
 var point: Array = road.path[index]
 var arms: Dictionary = {}
 var matches: int = 0
 for other: Dictionary in roads:
  if int(other.type) > 3 or RoadNetwork.road_closed(other): continue
  var other_index: int = other.path.find(point)
  if other_index < 0 or RoadNetwork._level(road,index) != RoadNetwork._level(other,other_index): continue
  matches += 1
  for neighbor: int in [other_index-1,other_index+1]:
   if neighbor < 0 or neighbor >= other.path.size(): continue
   var endpoint: Array = other.path[neighbor]
   var direction := Vector2i(signi(int(endpoint[0])-int(point[0])),signi(int(endpoint[1])-int(point[1])))
   if direction != Vector2i.ZERO: arms[direction] = true
 return matches >= 2 and arms.size() >= 3

func _advance_route_vehicle(vehicle: Dictionary, dt: float) -> bool:
 if vehicle.has("signal_pending"):
  var waiting: Dictionary = vehicle.signal_pending
  var key: String = str(waiting.key)
  if not _junction_turn(vehicle): return false
  var next_segment: Dictionary = vehicle.route[int(vehicle.route_index)]
  var approaching_road: Dictionary = _road_by_id(int(next_segment.road))
  if approaching_road.is_empty() or (int(next_segment.road) != int(waiting.get("previous_road",-1)) and (float(approaching_road.work)>0.0 or int(approaching_road.get("event_closures",0))>0 or RoadNetwork.road_closed(approaching_road))):
   var pieces: PackedStringArray = key.split(",")
   var replacement: Array = RoadNetwork.route(roads,Vector2i(int(pieces[0]),int(pieces[1])),_city_position(int(vehicle.destination)),-1,traffic_load,int(waiting.get("previous_road",-1)),int(waiting.get("previous_index",-1)),junction_delays,roundabouts)
   if replacement.is_empty(): interrupted += 1; return true
   vehicle.route = replacement
   vehicle.route_index = 0
   vehicle.segment_progress = 0.0
  _enter_toll_road(vehicle,int(vehicle.route[int(vehicle.route_index)].road))
  junction_busy_until[key] = elapsed + _junction_headway(key)
  vehicle.erase("signal_pending")
 var route: Array = vehicle.route
 var index: int = int(vehicle.route_index)
 if index >= route.size(): return true
 var segment: Dictionary = route[index]
 if int(vehicle.get("toll_road",-1)) != int(segment.road): _enter_toll_road(vehicle,int(segment.road))
 var road: Dictionary = _road_by_id(int(segment.road))
 if road.is_empty():
  interrupted += 1
  return true
 var speed: float = effective_speed(road)/25.0
 var a: Array = road.path[int(segment.from_index)]
 var b: Array = road.path[int(segment.to_index)]
 var length: float = Vector2(float(a[0]-b[0]),float(a[1]-b[1])).length()
 vehicle.segment_progress = float(vehicle.segment_progress)+dt*speed/maxf(length,0.1)
 while float(vehicle.segment_progress) >= 1.0:
  vehicle.segment_progress = float(vehicle.segment_progress)-1.0
  index += 1
  vehicle.route_index = index
  if index >= route.size():
   var fare: float = 110.0 + float(vehicle.direct_distance)*8.0
   var toll: float = float(vehicle.get("toll_due",0.0))
   money += fare+toll
   income += fare+toll
   toll_income += toll
   var target_time: float = maxf(3.0,float(vehicle.direct_distance)*Balance.LATE_GRACE_MULTIPLIER)
   var delay: float = maxf(0.0,float(vehicle.get("travel_time",0.0))-target_time)
   if delay > 0.0:
    var fine: float = minf(fare*Balance.LATE_FINE_MAX_FARE,delay*Balance.LATE_FINE_PER_SECOND)
    money -= fine
    expenses += fine
    delay_fines += fine
    today_penalties += fine
    late_trips += 1
   completed += 1
   road.trips = int(road.trips)+1
   var city: Dictionary = cities[int(vehicle.origin)]
   var destination: String = str(cities[int(vehicle.destination)].name)
   city.completed[destination] = int(city.completed.get(destination,0))+1
   return true
  # Re-evaluate at real same-level junctions, at most twice per simulation step.
  # Vehicles already on a road keep moving until they reach such a junction.
  if reroute_budget > 0 and elapsed-float(vehicle.get("last_reroute",0.0)) >= 10.0 and _has_junction(road,int(segment.to_index)):
   reroute_budget -= 1
   vehicle.last_reroute = elapsed
   var at := Vector2i(int(b[0]),int(b[1]))
   var updated: Array = RoadNetwork.route(roads,at,_city_position(int(vehicle.destination)),-1,traffic_load,int(road.id),int(segment.to_index),junction_delays,roundabouts)
   if not updated.is_empty():
    route = updated
    vehicle.route = updated
    index = 0
    vehicle.route_index = 0
    vehicle.segment_progress = 0.0
  var next: Dictionary = route[index]
  var next_road: Dictionary = _road_by_id(int(next.road))
  if next_road.is_empty() or (int(next.road) != int(road.id) and (RoadNetwork.road_closed(next_road))):
   var position := Vector2i(int(b[0]),int(b[1]))
   var replacement: Array = RoadNetwork.route(roads,position,_city_position(int(vehicle.destination)),-1,traffic_load,int(road.id),int(segment.to_index),junction_delays,roundabouts)
   if replacement.is_empty(): interrupted += 1; return true
   vehicle.route = replacement
   vehicle.route_index = 0
   vehicle.segment_progress = 0.0
   return false
  var arrival_index: int = int(segment.to_index)
  var direction: int = 1 if int(segment.to_index) > int(segment.from_index) else -1
  var signal_type: String = "none"
  for signal_data: Dictionary in road.get("signals",[]):
   if int(signal_data.index) == arrival_index and int(signal_data.direction) == direction:
    signal_type = str(signal_data.type)
    break
  var at_junction: bool = _has_junction(road,arrival_index)
  var coordinate: String = "%d,%d" % [int(b[0]),int(b[1])]
  if roundabouts.has(coordinate) and float(roundabouts[coordinate].get("work",0.0)) <= 0.0: signal_type = "none"
  if at_junction or signal_type != "none":
   var wait: float = 1.5 if signal_type == "stop" else 0.0
   if at_junction and _junction_headway(coordinate) == Balance.JUNCTION_UNCONTROLLED_HEADWAY: wait = maxf(wait,0.5)
   junction_queue_serial += 1
   vehicle.signal_pending = {"key":coordinate,"ready_at":elapsed+wait,"queued_at":elapsed,"order":junction_queue_serial,"level":RoadNetwork._level(road,arrival_index),"previous_road":int(road.id),"previous_index":arrival_index,"approach_index":int(segment.from_index),"signal_type":signal_type}
   vehicle.segment_progress = 0.0
   return false
  if int(next.road) != int(road.id): _enter_toll_road(vehicle,int(next.road))
  road = next_road
  segment = next
  a = road.path[int(segment.from_index)]
  b = road.path[int(segment.to_index)]
 return false

func closure_lost(road_id: int) -> Array[String]:
 var lost: Array[String] = []
 var checked: int = mini(cities.size(), 12)
 for a: int in range(checked):
  for b: int in range(a+1,checked):
   var from: Vector2i = _city_position(a)
   var to: Vector2i = _city_position(b)
   if not RoadNetwork.route(roads,from,to).is_empty() and RoadNetwork.route(roads,from,to,road_id).is_empty():
    lost.append("%s ↔ %s" % [cities[a].name,cities[b].name])
 return lost

func closure_impact(road_id: int) -> String:
 var lost: Array[String] = closure_lost(road_id)
 if lost.is_empty(): return "No se pierde ninguna conexión entre las primeras %d ciudades conocidas." % mini(cities.size(),12)
 return "Conexiones que se perderían: " + ", ".join(lost.slice(0,5)) + (" y otras %d." % (lost.size()-5) if lost.size()>5 else ".")

func schedule_work(road: Dictionary, kind: String, target: int, cost: float, duration: float, when: float) -> void:
 road.scheduled_work = {"kind":kind,"target":target,"cost":cost,"duration":duration,"start_at":when,"lost":closure_lost(int(road.id)),"status":"scheduled"}

func start_work(road: Dictionary, job: Dictionary) -> bool:
 var cost: float = float(job.cost)
 if money < cost or float(road.work) > 0.0: return false
 money -= cost
 expenses += cost
 if job.kind == "repair": road.pending_condition = 100.0
 elif job.kind == "bridge": road.pending_bridge = int(job.target)
 else: road.pending_type = int(job.target)
 road.work = float(job.duration)
 road.erase("scheduled_work")
 route_cache.clear()
 return true

func _process_scheduled_work(road: Dictionary) -> void:
 if not road.has("scheduled_work"): return
 var job: Dictionary = road.scheduled_work
 if job.status != "scheduled" or elapsed < float(job.start_at): return
 var previous: Array = job.lost
 var current: Array[String] = closure_lost(int(road.id))
 for pair: String in current:
  if not previous.has(pair):
   job.status = "blocked"
   notice_point = []
   latest_notice = "Obra del tramo %d aplazada: el aislamiento ha empeorado. Revisa el inspector." % int(road.id)
   notice_road = int(road.id)
   return
 if not start_work(road,job):
  job.status = "blocked"
  notice_point = []
  latest_notice = "Obra del tramo %d aplazada por falta de fondos o por otra obra." % int(road.id)
 else:
  notice_point = []
  latest_notice = "Ha comenzado la obra programada del tramo %d." % int(road.id)
 notice_road = int(road.id)

func _city_at(point: Array) -> int:
 for i: int in range(cities.size()):
  if int(cities[i].x) == int(point[0]) and int(cities[i].y) == int(point[1]): return i
 return -1

func _road_by_id(id: int) -> Dictionary:
 for road: Dictionary in roads:
  if int(road.id) == id: return road
 return {}

func data() -> Dictionary:
 return {"version":1,"generator_version":1,"name":game_name,"seed":seed_value,"guided":guided,"money":money,"elapsed":elapsed,"completed":completed,"income":income,"expenses":expenses,"cities":cities,"chunks":chunks,"roads":roads,"vehicles":vehicles,"next_id":next_id,"spawn_clock":spawn_clock,"cursor_x":cursor_x,"cursor_y":cursor_y,"interrupted":interrupted,"events":events,"forecasts":forecasts,"next_event":next_event,"latest_notice":latest_notice,"notice_road":notice_road,"notice_point":notice_point,"demand_credit":demand_credit,"potential_demand":potential_demand,"started_trips":started_trips,"unmet_demand":unmet_demand,"congestion_fines":congestion_fines,"delay_fines":delay_fines,"today_penalties":today_penalties,"yesterday_penalties":yesterday_penalties,"late_trips":late_trips,"route_refresh_clock":route_refresh_clock,"junction_busy_until":junction_busy_until,"roundabouts":roundabouts,"junction_queue_serial":junction_queue_serial,"junction_fines":junction_fines,"income_day_start":income_day_start,"expenses_day_start":expenses_day_start,"yesterday_income":yesterday_income,"yesterday_expenses":yesterday_expenses,"loan_taken":loan_taken,"loan_remaining":loan_remaining,"loan_overdue":loan_overdue,"contract":contract,"contracts_completed":contracts_completed,"toll_income":toll_income,"contract_income":contract_income,"contract_history":contract_history,"next_contract_check":next_contract_check,"saved_at":Time.get_datetime_string_from_system()}

static func from_data(d: Dictionary) -> GameState:
 var s := GameState.new(int(d.seed))
 s.game_name = str(d.name)
 s.guided = bool(d.guided)
 s.money = float(d.money)
 s.elapsed = float(d.elapsed)
 s.completed = int(d.completed)
 s.income = float(d.income)
 s.expenses = float(d.expenses)
 s.cities = d.cities
 s.chunks = d.chunks
 s.roads = d.roads
 for road: Dictionary in s.roads:
  if not road.has("bridges"): road.bridges = s._create_bridges(road)
 s.vehicles = d.vehicles
 s.next_id = int(d.next_id)
 s.spawn_clock = float(d.get("spawn_clock",0.0))
 s.cursor_x = int(d.get("cursor_x",2))
 s.cursor_y = int(d.get("cursor_y",4))
 s.interrupted = int(d.get("interrupted",0))
 s.events = d.get("events",[])
 s.forecasts = d.get("forecasts",[])
 s.next_event = float(d.get("next_event",240.0))
 s.latest_notice = str(d.get("latest_notice",""))
 s.notice_road = int(d.get("notice_road",-1))
 s.notice_point = d.get("notice_point",[])
 s.demand_credit = d.get("demand_credit",{})
 s.potential_demand = float(d.get("potential_demand",0.0))
 s.started_trips = int(d.get("started_trips",0))
 s.unmet_demand = int(d.get("unmet_demand",0))
 s.congestion_fines = float(d.get("congestion_fines",0.0))
 s.delay_fines = float(d.get("delay_fines",0.0))
 s.today_penalties = float(d.get("today_penalties",0.0))
 s.yesterday_penalties = float(d.get("yesterday_penalties",0.0))
 s.late_trips = int(d.get("late_trips",0))
 s.route_refresh_clock = float(d.get("route_refresh_clock",0.0))
 s.junction_busy_until = d.get("junction_busy_until",{})
 s.roundabouts = d.get("roundabouts",{})
 s.junction_queue_serial = int(d.get("junction_queue_serial",0))
 s.junction_fines = float(d.get("junction_fines",0.0))
 s.income_day_start = float(d.get("income_day_start",s.income))
 s.expenses_day_start = float(d.get("expenses_day_start",s.expenses))
 s.yesterday_income = float(d.get("yesterday_income",0.0))
 s.yesterday_expenses = float(d.get("yesterday_expenses",0.0))
 s.loan_taken = bool(d.get("loan_taken",false))
 s.loan_remaining = float(d.get("loan_remaining",0.0))
 s.loan_overdue = int(d.get("loan_overdue",0))
 s.contract = d.get("contract",{})
 s.contracts_completed = int(d.get("contracts_completed",0))
 s.toll_income = float(d.get("toll_income",0.0))
 s.contract_income = float(d.get("contract_income",0.0))
 s.contract_history = d.get("contract_history",[])
 s.next_contract_check = float(d.get("next_contract_check",0.0))
 s._update_traffic()
 return s
