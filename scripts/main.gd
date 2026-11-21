extends Node2D

var state: GameState
var cursor := Vector2i(2,4)
var camera_cell := Vector2(6,6)
var zoom: float = 1.0
var selected_type: int = 0
var start := Vector2i.ZERO
var drawing: bool = false
var waypoint: Vector2i = Vector2i.ZERO
var has_waypoint: bool = false
var proposal: Dictionary = {}
var simulation_speed: int = 1
var accumulator: float = 0.0
var autosave_clock: float = 0.0
var notice: String = ""
var notice_time: float = 0.0
var notice_road_id: int = -1
var notice_point: Array = []
var screen: String = "title"
var overlay: CanvasLayer
var panel: PanelContainer
var menu_scroll: ScrollContainer
var column: VBoxContainer
var title_label: Label
var footer: Label
var input_name: LineEdit
var input_seed: LineEdit
var guided: bool = true
var last_device: String = "teclado"
var grid_visible: bool = true
var view_mode: String = "normal"
var selected_road: int = 0
var tool: String = "Construir"
var elevated_crossings: bool = false
var previous_focus: String = ""
var background_world := WorldGenerator.new(17)
var zoom_in: bool = false
var zoom_out: bool = false
var shown_event_notice: String = ""
var geometry_anchors: Dictionary = {}
var settings: Dictionary = {}
var waiting_binding: String = ""
var settings_error: String = ""
var shoulder_left: bool = false
var shoulder_right: bool = false
var shoulder_combo_used: bool = false
var focus_memory: Dictionary = {}
var menu_direction_time: int = -1000
var cursor_motion := CursorMotion.new()
var menu_motion := CursorMotion.new()
const TOOLS: Array[String] = ["Construir","Construir puente","Construir rotonda","Señalar","Reparar","Mejorar","Demoler","Información","Cerrar/Abrir"]
const MENU_DIRECTION_INTERVAL_MS: int = 200
const CONTROL_LABELS: Dictionary = {"move_up":"Mover arriba","move_down":"Mover abajo","move_left":"Mover izquierda","move_right":"Mover derecha","accept_action":"Aceptar","back_action":"Cancelar","inspect_action":"Inspector","menu_action":"Menú","road_prev":"Vía anterior","road_next":"Vía siguiente","pause_action":"Pausa","tool_action":"Herramienta siguiente","tool_previous":"Herramienta anterior","zoom_in":"Acercar","zoom_out":"Alejar","notice_go":"Ir al aviso","notice_dismiss":"Descartar aviso"}
const DEFAULT_KEYS: Dictionary = {"move_up":[KEY_UP,KEY_W],"move_down":[KEY_DOWN,KEY_S],"move_left":[KEY_LEFT,KEY_A],"move_right":[KEY_RIGHT,KEY_D],"accept_action":[KEY_ENTER,KEY_SPACE],"back_action":[KEY_ESCAPE,KEY_DELETE],"inspect_action":[KEY_I],"menu_action":[KEY_M],"road_prev":[KEY_Q],"road_next":[KEY_E],"pause_action":[KEY_P],"tool_action":[KEY_TAB],"tool_previous":[KEY_F8],"zoom_in":[KEY_EQUAL,KEY_KP_ADD],"zoom_out":[KEY_MINUS,KEY_KP_SUBTRACT],"notice_go":[KEY_F6],"notice_dismiss":[KEY_F7]}

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
  cursor_motion.reset()
  menu_motion.reset()
  shoulder_left = false
  shoulder_right = false
  shoulder_combo_used = false

func _ready() -> void:
 settings = SettingsStore.read_settings()
 grid_visible = bool(settings.grid)
 cursor_motion.set_speed(str(settings.get("cursor_speed","normal")))
 if bool(settings.fullscreen): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
 _configure_input()
 Input.joy_connection_changed.connect(_on_joy_connection_changed)
 overlay = CanvasLayer.new()
 add_child(overlay)
 _show_title()

func _on_joy_connection_changed(_device: int, connected: bool) -> void:
 if not connected:
  cursor_motion.reset()
  menu_motion.reset()
  shoulder_left = false
  shoulder_right = false
  shoulder_combo_used = false

func _configure_input() -> void:
 cursor_motion.reset()
 menu_motion.reset()
 var bindings: Dictionary = DEFAULT_KEYS.duplicate(true)
 for action: String in settings.get("keys",{}):
  if bindings.has(action): bindings[action] = [int(settings.keys[action])]
 for action: String in bindings:
  if not InputMap.has_action(action): InputMap.add_action(action)
  else: InputMap.action_erase_events(action)
  for key: int in bindings[action]:
   var event := InputEventKey.new()
   event.physical_keycode = key
   InputMap.action_add_event(action,event)
 # Keep the active keyboard layout's + and − when zoom has default bindings.
 for binding: Array in [["zoom_in", KEY_PLUS], ["zoom_in", KEY_EQUAL], ["zoom_out", KEY_MINUS]]:
  if settings.keys.has(binding[0]): continue
  var logical := InputEventKey.new()
  logical.keycode = binding[1]
  InputMap.action_add_event(binding[0], logical)
 # Menu navigation includes the configured movement keys plus safe fallbacks.
 for pair: Array in [["ui_up","move_up",KEY_UP],["ui_down","move_down",KEY_DOWN],["ui_left","move_left",KEY_LEFT],["ui_right","move_right",KEY_RIGHT],["ui_accept","accept_action",KEY_ENTER],["ui_cancel","back_action",KEY_ESCAPE]]:
  for old: InputEvent in InputMap.action_get_events(pair[0]):
   if old is InputEventKey: InputMap.action_erase_event(pair[0],old)
  var values: Array = bindings[pair[1]].duplicate()
  if not values.has(pair[2]): values.append(pair[2])
  if pair[0] == "ui_accept" and not values.has(KEY_SPACE): values.append(KEY_SPACE)
  for key: int in values:
   var event := InputEventKey.new()
   event.physical_keycode = key
   InputMap.action_add_event(pair[0],event)
 var joy: Dictionary = {"move_up":JOY_BUTTON_DPAD_UP,"move_down":JOY_BUTTON_DPAD_DOWN,"move_left":JOY_BUTTON_DPAD_LEFT,"move_right":JOY_BUTTON_DPAD_RIGHT,"accept_action":JOY_BUTTON_A,"back_action":JOY_BUTTON_B,"inspect_action":JOY_BUTTON_Y,"menu_action":JOY_BUTTON_X,"road_prev":JOY_BUTTON_LEFT_SHOULDER,"road_next":JOY_BUTTON_RIGHT_SHOULDER,"pause_action":JOY_BUTTON_START,"notice_go":JOY_BUTTON_PADDLE1,"notice_dismiss":JOY_BUTTON_PADDLE2,"tool_action":JOY_BUTTON_PADDLE3,"tool_previous":JOY_BUTTON_PADDLE4}
 for action: String in joy:
  var event := InputEventJoypadButton.new()
  event.button_index = joy[action]
  InputMap.action_add_event(action,event)
 for axis_data: Array in [["move_left",JOY_AXIS_LEFT_X,-1.0],["move_right",JOY_AXIS_LEFT_X,1.0],["move_up",JOY_AXIS_LEFT_Y,-1.0],["move_down",JOY_AXIS_LEFT_Y,1.0],["zoom_out",JOY_AXIS_TRIGGER_LEFT,1.0],["zoom_in",JOY_AXIS_TRIGGER_RIGHT,1.0]]:
  var event := InputEventJoypadMotion.new()
  event.axis = axis_data[1]
  event.axis_value = axis_data[2]
  InputMap.action_add_event(axis_data[0],event)
  InputMap.action_set_deadzone(axis_data[0],0.65 if axis_data[0].begins_with("move_") else 0.4)

func _input(event: InputEvent) -> void:
 # Synthetic menu actions go straight to Godot's GUI, not back into the repeater.
 if event is InputEventAction and event.action in ["ui_up","ui_down","ui_left","ui_right"]: return
 if event is InputEventJoypadButton or event is InputEventJoypadMotion: last_device = "mando"
 elif event is InputEventKey: last_device = "teclado"
 if screen != "game" and waiting_binding.is_empty() and not _native_popup_open():
  var stick_axis: bool = event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]
  var dpad: bool = event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]
  if stick_axis or dpad:
   menu_motion.handle_event(event)
   get_viewport().set_input_as_handled()
   return
 if screen != "game" and waiting_binding.is_empty() and _limit_menu_navigation(event,Time.get_ticks_msec()):
  get_viewport().set_input_as_handled()
  return
 if screen == "game" and event is InputEventJoypadButton and event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:
  if event.pressed: _cycle_tool(-1 if event.button_index == JOY_BUTTON_LEFT_SHOULDER else 1)
  get_viewport().set_input_as_handled()
  return
 if waiting_binding.is_empty() or not event is InputEventKey or not event.pressed or event.echo: return
 var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
 if key in [KEY_SHIFT,KEY_CTRL,KEY_ALT,KEY_META]: return
 if key == KEY_ESCAPE:
  waiting_binding = ""
  get_viewport().set_input_as_handled()
  _controls_menu()
  return
 # Avoid silently stealing another action's key.
 for action: String in DEFAULT_KEYS:
  if action == waiting_binding: continue
  var values: Array = [int(settings.keys[action])] if settings.keys.has(action) else DEFAULT_KEYS[action]
  if values.has(key):
   _notify("Esa tecla ya está asignada a " + str(CONTROL_LABELS[action]))
   _controls_menu()
   get_viewport().set_input_as_handled()
   return
 settings.keys[waiting_binding] = key
 waiting_binding = ""
 _configure_input()
 _save_settings()
 get_viewport().set_input_as_handled()
 _controls_menu()

func _native_popup_open() -> bool:
 var focus: Control = get_viewport().gui_get_focus_owner()
 return focus is OptionButton and focus.get_popup().visible

func _advance_menu_navigation(delta: float) -> void:
 if not waiting_binding.is_empty(): return
 if _native_popup_open():
  menu_motion.reset()
  return
 var direction: Vector2i = menu_motion.advance(delta)
 if direction == Vector2i.ZERO: return
 var action: StringName = &"ui_up"
 if direction == Vector2i.DOWN: action = &"ui_down"
 elif direction == Vector2i.LEFT: action = &"ui_left"
 elif direction == Vector2i.RIGHT: action = &"ui_right"
 var press := InputEventAction.new()
 press.action = action
 press.pressed = true
 get_viewport().push_input(press)
 var release := InputEventAction.new()
 release.action = action
 release.pressed = false
 get_viewport().push_input(release)

func _limit_menu_navigation(event: InputEvent, now: int) -> bool:
 if not (event.is_action_pressed("ui_up",true) or event.is_action_pressed("ui_down",true)):
  return false
 if now - menu_direction_time < MENU_DIRECTION_INTERVAL_MS:
  return true
 menu_direction_time = now
 return false

func _save_settings() -> void:
 settings_error = "" if SettingsStore.write_settings(settings) == OK else "No se pudieron guardar los ajustes."
 if not settings_error.is_empty(): _notify(settings_error)

func _process(delta: float) -> void:
 if screen != "game": _advance_menu_navigation(delta)
 if notice_time > 0.0: notice_time -= delta
 if screen == "game" and state != null:
  var movement: Vector2i = cursor_motion.advance(delta)
  if movement != Vector2i.ZERO: _move(movement)
  var zi: float = Input.get_action_strength("zoom_in")
  var zo: float = Input.get_action_strength("zoom_out")
  zoom = clampf(zoom * exp((zi-zo)*delta),0.55,2.2)
  _update_camera(delta)
  state.discover(cursor)
  state.cursor_x = cursor.x
  state.cursor_y = cursor.y
  accumulator += minf(delta,0.25) * simulation_speed
  while accumulator >= Balance.FIXED_STEP:
   state.step(Balance.FIXED_STEP)
   accumulator -= Balance.FIXED_STEP
   autosave_clock += Balance.FIXED_STEP
  if not state.latest_notice.is_empty() and state.latest_notice != shown_event_notice:
   shown_event_notice = state.latest_notice
   _notify(state.latest_notice,state.notice_road,state.notice_point)
  if autosave_clock >= 120.0:
   autosave_clock = 0.0
   var error: String = SaveManager.save_game(state,true)
   if not error.is_empty(): _notify(error)
 queue_redraw()

func _update_camera(delta: float) -> void:
 # Keep the map still for precise cell selection; follow only near screen edges.
 var size: Vector2 = get_viewport_rect().size
 var cell: float = 24.0*zoom
 var position: Vector2 = size*0.5+(Vector2(cursor)+Vector2(0.5,0.5)-camera_cell)*cell
 var scale: float = float(settings.get("ui_scale",1.0))
 var top: float = maxf(size.y*0.18,68.0*scale+40.0)
 var bottom: float = minf(size.y*0.82,size.y-108.0*scale-40.0)
 if bottom < top: top = size.y*0.25; bottom = size.y*0.75
 var clamped := Vector2(clampf(position.x,size.x*0.18,size.x*0.82),clampf(position.y,top,bottom))
 var target: Vector2 = camera_cell+(position-clamped)/cell
 camera_cell = camera_cell.lerp(target,minf(1.0,maxf(0.0,delta)*10.0))

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventJoypadButton or event is InputEventJoypadMotion: last_device = "mando"
 if event is InputEventKey: last_device = "teclado"
 if screen != "game":
  if event.is_action_pressed("back_action"):
   get_viewport().set_input_as_handled()
   _back()
  return
 if cursor_motion.handle_event(event):
  get_viewport().set_input_as_handled()
  return
 if event.is_action_pressed("notice_go") and notice_time > 0.0:
  _go_to_notice()
 elif event.is_action_pressed("notice_dismiss") and notice_time > 0.0:
  _dismiss_notice()
 elif event.is_action_pressed("accept_action"): _accept_map()
 elif event.is_action_pressed("back_action"):
  if drawing:
   drawing = false
   proposal = {}
   _notify("Trazado cancelado")
  else: _notify("Selecciona Demoler para eliminar una carretera.")
 elif event.is_action_pressed("inspect_action"): _tool_options()
 elif event.is_action_pressed("menu_action"): _game_menu()
 elif event.is_action_pressed("road_prev"): selected_type = posmod(selected_type - 1, 7); _refresh_proposal(); _road_type_notice()
 elif event.is_action_pressed("road_next"): selected_type = (selected_type + 1) % 7; _refresh_proposal(); _road_type_notice()
 elif event.is_action_pressed("pause_action"): simulation_speed = 1 if simulation_speed == 0 else 0
 elif event.is_action_pressed("tool_action"): _cycle_tool()
 elif event.is_action_pressed("tool_previous"): _cycle_tool(-1)
 else: return
 get_viewport().set_input_as_handled()

func _move(dir: Vector2i) -> void:
 cursor += dir
 selected_road = 0
 _refresh_proposal()

func _road_type_notice() -> void:
 var requirement: String = state.unlock_reason(selected_type)
 if not requirement.is_empty(): _notify("%s bloqueada. %s" % [Balance.ROADS[selected_type].name,requirement])
 else: _notify("Vía disponible: %s. %s" % [Balance.ROADS[selected_type].name,Balance.terrain_hint(selected_type)])

func _refresh_proposal() -> void:
 if drawing:
  proposal = RoadPlanner.plan_via(state.world,start,waypoint,cursor,selected_type) if has_waypoint else RoadPlanner.plan(state.world,start,cursor,selected_type)
  if not proposal.has("error"):
   proposal = RoadPlanner.validate_terrain(state.world,proposal,selected_type)
  if not proposal.has("error"):
   proposal = RoadPlanner.add_crossings(state.world,proposal,state.roads,tool == "Construir puente",selected_type)

func _accept_map() -> void:
 if tool == "Construir rotonda":
  _roundabout_review()
  return
 if tool == "Información":
  _inspector()
  return
 if tool == "Demoler":
  _delete_prompt()
  return
 if tool not in ["Construir", "Construir puente"]:
  _road_action()
  return
 if not drawing:
  start = cursor
  has_waypoint = false
  drawing = true
  _refresh_proposal()
  _notify("Origen marcado. Elige el destino.")
 else:
  if proposal.has("error"):
   _notify(str(proposal.error)); return
  if cursor == start:
   _notify("Elige un destino distinto."); return
  _review()

func _review() -> void:
 var cost: float = state.price(proposal,selected_type)
 var spans: Array = proposal.get("overpasses",[])
 var text: String = "%s · %.1f casillas\nBase: %.0f €  ·  Terreno: %.0f €\nPuente de agua: %d casillas · %.0f €\nPasos sobre carreteras: %d · %.0f €\nTotal: %.0f € · obra: %.0f s\nSaldo disponible: %.0f €" % [Balance.ROADS[selected_type].name,proposal.length,float(proposal.length)*Balance.CELL_COST*float(Balance.ROADS[selected_type].cost),proposal.terrain_cost,proposal.water,float(proposal.water)*Balance.BRIDGE_COST,spans.size(),proposal.get("overpass_cost",0.0),cost,state.construction_time(proposal),state.money]
 for span: Dictionary in spans:
  text += "\nRampas (%d,%d) → (%d,%d) · %.1f casillas" % [span.start[0],span.start[1],span.end[0],span.end[1],span.length]
 if not spans.is_empty(): text += "\nLas vías inferiores siguen abiertas; el paso elevado no crea enlaces."
 _make_panel("Revisar presupuesto",text,"review")
 var locked: String = state.unlock_reason(selected_type)
 if not locked.is_empty(): _label("Vía bloqueada. " + locked)
 if cost <= state.money and locked.is_empty(): _button("Confirmar obra",func() -> void: state.build(proposal,selected_type); drawing = false; proposal = {}; _close_panel(); _notify("Obra iniciada. Se abrirá al terminar."))
 elif cost > state.money: _label("Fondos insuficientes. Vuelve y ajusta el trazado.")
 _button("Volver al trazado",func() -> void: _close_panel())
 _focus_first()

func _road_at(p: Vector2i) -> Array:
 var found: Array = []
 for road: Dictionary in state.roads:
  if road.path.has([p.x,p.y]): found.append(road)
 return found

func _delete_prompt() -> void:
 var roads: Array = _road_at(cursor)
 if roads.is_empty(): _notify("No hay una carretera que demoler aquí."); return
 var road: Dictionary = roads[mini(selected_road,roads.size()-1)]
 _make_panel("Demoler carretera", "Se eliminará el tramo completo. Los vehículos en él se retirarán sin ingreso. No hay devolución.\n" + state.closure_impact(int(road.id)),"delete")
 _button("Demoler",func() -> void: state.remove_road(road); _close_panel(); _notify("Carretera demolida."))
 _button("Cancelar",func() -> void: _close_panel())
 _focus_first()

func _road_action() -> void:
 var roads: Array = _road_at(cursor)
 if roads.is_empty(): _notify("Selecciona una carretera."); return
 var road: Dictionary = roads[mini(selected_road,roads.size()-1)]
 if tool in ["Reparar","Mejorar"]:
  _work_menu(road, "repair" if tool == "Reparar" else "upgrade")
 elif tool == "Cerrar/Abrir":
  _manual_closure_menu(road)
 else:
  _signal_menu(road)

func _manual_closure_menu(road: Dictionary) -> void:
 var id: int = int(road.id)
 var label: String = str(road.get("road_name","Tramo %d" % id))
 if bool(road.get("manual_closed",false)):
  var remaining: Array[String] = RoadNetwork.closure_reasons(road,false)
  var text: String = "El cierre manual de %s se retirará sin coste." % label
  if not remaining.is_empty(): text += "\nSeguirá cerrada por: " + ", ".join(remaining) + "."
  else: text += "\nLa carretera volverá a admitir tráfico."
  _make_panel("Abrir carretera",text,"action")
  _button("Quitar cierre manual" if not remaining.is_empty() else "Confirmar apertura",func() -> void: _apply_manual_closure(id,false))
  _button("Cancelar",func() -> void: _close_panel())
  _focus_first()
  return
 var lost: Array[String] = state.closure_lost(id)
 var description: String = "%s · cierre manual indefinido · sin coste\nLos vehículos que ya circulan pueden salir.\n%s" % [label,state.closure_impact(id)]
 var existing: Array[String] = RoadNetwork.closure_reasons(road,false)
 if not existing.is_empty(): description += "\nYa está cerrada por: " + ", ".join(existing) + "."
 _make_panel("Cerrar carretera",description,"action")
 if not lost.is_empty(): _button("Preparar desvío",func() -> void: _close_panel(); _notify("Prepara una alternativa antes de cerrar."))
 _button("Cerrar y asumir aislamiento" if not lost.is_empty() else "Confirmar cierre",func() -> void: _apply_manual_closure(id,true))
 _button("Cancelar",func() -> void: _close_panel())
 _focus_first()

func _apply_manual_closure(road_id: int, closed: bool) -> void:
 if not state.set_manual_closed(road_id,closed):
  _close_panel()
  _notify("La carretera ya no existe.")
  return
 var road: Dictionary = state._road_by_id(road_id)
 var name: String = str(road.get("road_name","Tramo %d" % road_id))
 var message: String = "%s cerrada manualmente." % name if closed else "%s abierta al tráfico." % name
 if not closed and RoadNetwork.road_closed(road):
  message = "Cierre manual retirado. %s sigue cerrada: %s." % [name,", ".join(RoadNetwork.closure_reasons(road,false))]
 _close_panel()
 _notify(message,road_id,[cursor.x,cursor.y])

func _work_menu(road: Dictionary, kind: String) -> void:
 var repair: bool = kind == "repair"
 var target: int = selected_type
 var cost: float = ceil((100.0-float(road.condition))*float(road.length)*4.0+100.0) if repair else ceil(float(road.length)*Balance.CELL_COST*float(Balance.ROADS[target].cost)*0.7)
 var duration: float = 15.0 if repair else 20.0
 var bridge_cost: float = 0.0
 if not repair:
  for bridge: Dictionary in road.get("bridges",[]):
   if target > int(bridge.category): bridge_cost += float(int(bridge.end)-int(bridge.start)+1)*200.0
  cost += bridge_cost
 var lost: Array[String] = state.closure_lost(int(road.id))
 var unsafe_upgrade: bool = false
 if not repair and target >= 4 and int(road.type) < 4:
  for point: Array in road.path:
   for other: Dictionary in state.roads:
    if int(other.id) != int(road.id) and int(other.type) <= 3 and other.path.has(point): unsafe_upgrade = true
 var description: String = "%s · %.0f € · cierre %.0f s\n%s\n%s" % ["Reparar a 100%" if repair else "Mejorar a " + str(Balance.ROADS[target].name),cost,duration,state.closure_impact(int(road.id)),"Mantenimiento preventivo: " + ("activo" if road.get("maintenance",false) else "inactivo")]
 if bridge_cost > 0.0: description += "\nReemplazo de puentes: %.0f € (incluido); cierre durante la obra." % bridge_cost
 var unlock: String = state.unlock_reason(target) if not repair else ""
 if not unlock.is_empty(): description += "\nVía bloqueada: " + unlock
 if unsafe_upgrade: description += "\nMejora no disponible: eliminaría conexiones a nivel y aún no se pueden construir enlaces."
 if road.has("scheduled_work"): description += "\nObra pendiente: " + str(road.scheduled_work.status)
 _make_panel("Reparar y mantener" if repair else "Mejorar",description,"action")
 if float(road.work) <= 0.0 and state.money >= cost and not unsafe_upgrade and unlock.is_empty():
  var label: String = "Asumir aislamiento e iniciar" if not lost.is_empty() else "Iniciar ahora"
  _button(label,func() -> void:
   if not lost.is_empty(): _confirm_work(road,kind,target,cost,duration,false)
   else: _apply_work(road,kind,target,cost,duration,false))
  _button("Programar en periodo de baja demanda",func() -> void:
   if not lost.is_empty(): _confirm_work(road,kind,target,cost,duration,true)
   else: _apply_work(road,kind,target,cost,duration,true))
 if repair:
  var road_index: int = road.path.find([cursor.x,cursor.y])
  for bridge_index: int in range(road.get("bridges",[]).size()):
   var bridge: Dictionary = road.bridges[bridge_index]
   if road_index >= int(bridge.start) and road_index <= int(bridge.end):
    _button("Reparar puente seleccionado",func() -> void: _bridge_menu(road,bridge_index))
  _button("Desactivar mantenimiento" if road.get("maintenance",false) else "Activar mantenimiento preventivo",func() -> void: road.maintenance = not bool(road.get("maintenance",false)); _close_panel(); _notify("Mantenimiento actualizado."))
 if road.has("scheduled_work"): _button("Cancelar obra pendiente",func() -> void: road.erase("scheduled_work"); _close_panel(); _notify("Obra pendiente cancelada."))
 _button("Volver y preparar desvío",func() -> void: _close_panel())
 _focus_first()

func _bridge_menu(road: Dictionary, bridge_index: int) -> void:
 var bridge: Dictionary = road.bridges[bridge_index]
 var cost: float = ceil(100.0+(100.0-float(bridge.condition))*5.0)
 var duration: float = 12.0
 var lost: Array[String] = state.closure_lost(int(road.id))
 _make_panel("Reparar puente", "Conservación %.1f%% → 100%% · %.0f €\nCierre del tramo %.0f s.\n%s" % [bridge.condition,cost,duration,state.closure_impact(int(road.id))],"action")
 if state.money >= cost and float(road.work) <= 0.0:
  _button("Asumir aislamiento e iniciar" if not lost.is_empty() else "Iniciar reparación",func() -> void:
   if lost.is_empty(): _apply_work(road,"bridge",bridge_index,cost,duration,false)
   else: _confirm_work(road,"bridge",bridge_index,cost,duration,false))
  _button("Programar reparación",func() -> void:
   if lost.is_empty(): _apply_work(road,"bridge",bridge_index,cost,duration,true)
   else: _confirm_work(road,"bridge",bridge_index,cost,duration,true))
 _button("Volver y preparar desvío",func() -> void: _close_panel())
 _focus_first()

func _confirm_work(road: Dictionary, kind: String, target: int, cost: float, duration: float, scheduled: bool) -> void:
 _make_panel("Confirmar aislamiento",state.closure_impact(int(road.id))+"\nCierre previsto: %.0f s. ¿Asumes esta pérdida de acceso?" % duration,"action")
 _button("Asumir aislamiento",func() -> void: _apply_work(road,kind,target,cost,duration,scheduled))
 _button("Preparar desvío",func() -> void:
  state.schedule_work(road,kind,target,cost,duration,state.elapsed)
  road.scheduled_work.status = "draft"
  _close_panel()
  _notify("Obra pendiente conservada mientras preparas el desvío."))
 _focus_first()

func _apply_work(road: Dictionary, kind: String, target: int, cost: float, duration: float, scheduled: bool) -> void:
 if scheduled:
  # One day lasts 120 seconds; the last quarter is the quieter period.
  var day_start: float = floor(state.elapsed / Balance.DAY_SECONDS)*Balance.DAY_SECONDS
  var start_at: float = day_start + Balance.DAY_SECONDS*0.75
  if start_at <= state.elapsed: start_at += Balance.DAY_SECONDS
  state.schedule_work(road,kind,target,cost,duration,start_at)
  _close_panel(); _notify("Obra programada. Se volverá a comprobar el aislamiento.")
 else:
  var job: Dictionary = {"kind":kind,"target":target,"cost":cost,"duration":duration}
  if state.start_work(road,job): _close_panel(); _notify("Obra iniciada.")
  else: _notify("No se puede iniciar la obra.")

func _signal_menu(road: Dictionary) -> void:
 var index: int = road.path.find([cursor.x,cursor.y])
 _make_panel("Señalizar tramo", "Elige un límite de velocidad o una señal para el sentido de llegada al punto seleccionado.","action")
 var maximum: float = float(Balance.ROADS[int(road.type)].speed)
 for limit: int in [25,40,60,80,100,120]:
  if float(limit) <= maximum:
   _button("Límite %d km/h" % limit,func() -> void: road.speed_limit = float(limit); state.route_cache.clear(); _close_panel(); _notify("Límite aplicado: %d km/h" % limit))
 var connects: bool = false
 for other: Dictionary in _road_at(cursor):
  if int(other.id) != int(road.id) and int(other.type) <= 3 and int(road.type) <= 3:
   var other_index: int = other.path.find([cursor.x,cursor.y])
   if RoadNetwork._level(other,other_index) == RoadNetwork._level(road,index): connects = true
 if connects:
  var junction_key: String = state._junction_key(cursor)
  if state.roundabouts.has(junction_key):
   _button("Retirar rotonda",func() -> void: _confirm_remove_roundabout(junction_key))
  else:
   var reason: String = state.can_build_roundabout(cursor)
   if reason.is_empty(): _button("Construir rotonda",func() -> void: _roundabout_review())
   else: _label("Rotonda: " + reason)
  for direction: int in [-1,1]:
   var from_index: int = index-direction
   if from_index < 0 or from_index >= road.path.size(): continue
   var from: Array = road.path[from_index]
   _button("Entrada desde (%d,%d): STOP" % [from[0],from[1]],func() -> void: _set_signal(road,index,direction,"stop"))
   _button("Entrada desde (%d,%d): ceda" % [from[0],from[1]],func() -> void: _set_signal(road,index,direction,"yield"))
   _button("Entrada desde (%d,%d): sin señal" % [from[0],from[1]],func() -> void: _set_signal(road,index,direction,"none"))
 _button("Cancelar",func() -> void: _close_panel())
 _focus_first()

func _roundabout_review() -> void:
 var point: Vector2i = cursor
 _make_panel("Construir rotonda", "Coste: %.0f € · obra: %.0f s\nLa circulación continúa durante la obra. Una vez terminada, aumenta la capacidad del cruce; las señales existentes quedan en reserva hasta retirar la rotonda." % [Balance.ROUNDABOUT_COST,Balance.ROUNDABOUT_WORK_SECONDS],"action")
 var reason: String = state.can_build_roundabout(point)
 if reason.is_empty(): _button("Confirmar construcción",func() -> void:
  if state.build_roundabout(point): _close_panel(); _notify("Construcción de la rotonda iniciada.")
  else: _close_panel(); _notify("No se pudo construir la rotonda."))
 else: _label(reason)
 _button("Cancelar",func() -> void: _close_panel())
 _focus_first()

func _confirm_remove_roundabout(key: String) -> void:
 _make_panel("Retirar rotonda", "El cruce recuperará las señales anteriores. No se devuelve el coste.","action")
 _button("Retirar",func() -> void: state.roundabouts.erase(key); state.route_cache.clear(); _close_panel(); _notify("Rotonda retirada."))
 _button("Cancelar",func() -> void: _close_panel())
 _focus_first()

func _set_signal(road: Dictionary, index: int, direction: int, kind: String) -> void:
 if not road.has("signals"): road.signals = []
 var existing: Array = road.signals.duplicate()
 for signal_data: Dictionary in existing:
  if int(signal_data.index) == index and int(signal_data.direction) == direction: road.signals.erase(signal_data)
 if kind != "none": road.signals.append({"index":index,"direction":direction,"type":kind})
 state.route_cache.clear()
 _close_panel()
 _notify("Señal actualizada para la entrada seleccionada.")

func _cycle_tool(direction: int = 1) -> void:
 tool = TOOLS[posmod(TOOLS.find(tool)+direction,TOOLS.size())]
 drawing = false
 proposal = {}

func _tool_options() -> void:
 if tool in ["Construir", "Construir puente"]:
  _make_panel("Tipo de carretera", "Elige la vía que quieres construir.", "action")
  for index: int in range(Balance.ROADS.size()):
   var road_type: int = index
   var reason: String = state.unlock_reason(index)
   _button(str(Balance.ROADS[index].name) + (" · bloqueada" if not reason.is_empty() else "") + (" ✓" if index == selected_type else ""),func() -> void: selected_type = road_type; _close_panel(); _refresh_proposal(); _road_type_notice())
  _button("Cancelar",func() -> void: _close_panel())
  _focus_first()
 elif tool == "Construir rotonda":
  _roundabout_review()
 elif tool == "Señalar":
  _road_action()
 elif tool == "Información":
  _inspector()
 else:
  _notify("Usa A sobre una carretera para " + tool.to_lower() + ".")

func _key_hint(action: String, default_label: String) -> String:
 if settings.get("keys",{}).has(action): return OS.get_keycode_string(int(settings.keys[action]))
 return default_label

func _make_panel(heading: String, description: String, next_screen: String) -> void:
 cursor_motion.reset()
 menu_motion.reset()
 screen = next_screen
 shoulder_left = false
 shoulder_right = false
 shoulder_combo_used = false
 for child: Node in overlay.get_children(): child.queue_free()
 panel = PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 var ui_scale: float = float(settings.get("ui_scale",1.0))
 var viewport: Vector2 = get_viewport_rect().size
 var half_width: float = minf(350.0*ui_scale,viewport.x*0.48)
 var half_height: float = minf(330.0*ui_scale,viewport.y*0.46)
 panel.offset_left = -half_width
 panel.offset_right = half_width
 panel.offset_top = -half_height
 panel.offset_bottom = half_height
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.035,0.075,0.075,0.985)
 style.border_color = Color("c9d9bf")
 style.set_border_width_all(2*ui_scale)
 style.set_corner_radius_all(10)
 style.set_content_margin_all(26*ui_scale)
 panel.add_theme_stylebox_override("panel",style)
 panel.add_theme_color_override("font_color",Color("f4f1e8"))
 overlay.add_child(panel)
 menu_scroll = ScrollContainer.new()
 menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 menu_scroll.follow_focus = true
 menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 panel.add_child(menu_scroll)
 column = VBoxContainer.new()
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation",8)
 menu_scroll.add_child(column)
 title_label = Label.new()
 title_label.text = heading
 title_label.add_theme_font_size_override("font_size",roundi(30*ui_scale))
 title_label.add_theme_color_override("font_color",Color("f5f3eb"))
 column.add_child(title_label)
 if not description.is_empty(): _label(description)
 var help := Label.new()
 help.text = "A aceptar · B volver" if last_device == "mando" else "%s aceptar · %s volver" % [_key_hint("accept_action","Intro"),_key_hint("back_action","Esc")]
 help.add_theme_font_size_override("font_size",roundi(14*ui_scale))
 help.add_theme_color_override("font_color",Color("edcf78"))
 column.add_child(help)
 call_deferred("_fit_panel",panel)

func _fit_panel(expected_panel: PanelContainer) -> void:
 if not is_instance_valid(expected_panel) or expected_panel != panel or not is_instance_valid(column): return
 var ui_scale: float = float(settings.get("ui_scale",1.0))
 var viewport: Vector2 = get_viewport_rect().size
 var max_half_height: float = minf(330.0*ui_scale,viewport.y*0.46)
 var content_height: float = column.get_combined_minimum_size().y
 var half_height: float = clampf(content_height*0.5+30.0*ui_scale,150.0*ui_scale,max_half_height)
 expected_panel.offset_top = -half_height
 expected_panel.offset_bottom = half_height

func _label(value: String) -> void:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",roundi(17*float(settings.get("ui_scale",1.0))))
 label.add_theme_color_override("font_color",Color("c6d1c7"))
 column.add_child(label)

func _style_field(control: Control) -> void:
 var ui_scale: float = float(settings.get("ui_scale",1.0))
 var normal := StyleBoxFlat.new()
 normal.bg_color = Color(0.015,0.04,0.045,0.75)
 normal.border_color = Color(0.72,0.82,0.75,0.4)
 normal.set_border_width_all(1)
 normal.set_corner_radius_all(4)
 normal.set_content_margin(SIDE_LEFT,10*ui_scale)
 normal.set_content_margin(SIDE_RIGHT,10*ui_scale)
 var focus_style := StyleBoxFlat.new()
 focus_style.bg_color = normal.bg_color
 focus_style.border_color = Color("f7db82")
 focus_style.set_border_width_all(2)
 focus_style.set_corner_radius_all(4)
 control.add_theme_stylebox_override("normal",normal)
 control.add_theme_stylebox_override("focus",focus_style)
 control.add_theme_color_override("font_color",Color("f0f0e9"))
 control.add_theme_color_override("font_placeholder_color",Color("9eada3"))

func _button(label: String, action: Callable) -> Button:
 var button := Button.new()
 button.text = label
 var ui_scale: float = float(settings.get("ui_scale",1.0))
 button.custom_minimum_size.y = 44*ui_scale
 button.add_theme_font_size_override("font_size",roundi(18*ui_scale))
 button.add_theme_color_override("font_color",Color("f0f0e9"))
 button.add_theme_color_override("font_hover_color",Color.WHITE)
 button.add_theme_color_override("font_pressed_color",Color("f7db82"))
 button.add_theme_color_override("font_disabled_color",Color("82918a"))
 var normal := StyleBoxFlat.new()
 normal.bg_color = Color(0.015,0.04,0.045,0.62)
 normal.set_corner_radius_all(5)
 normal.set_content_margin(SIDE_LEFT,12*ui_scale)
 normal.set_content_margin(SIDE_RIGHT,12*ui_scale)
 var hover := StyleBoxFlat.new()
 hover.bg_color = Color("203432")
 hover.border_color = Color(0.72,0.82,0.75,0.36)
 hover.set_border_width_all(1)
 hover.set_corner_radius_all(5)
 var pressed := StyleBoxFlat.new()
 pressed.bg_color = Color("343a2f")
 pressed.border_color = Color("edcf78")
 pressed.set_border_width_all(2)
 pressed.set_corner_radius_all(5)
 var focus_style := StyleBoxFlat.new()
 focus_style.bg_color = Color(0.09,0.12,0.10,0.42)
 focus_style.border_color = Color("f7db82")
 focus_style.set_border_width_all(3)
 focus_style.set_corner_radius_all(5)
 button.add_theme_stylebox_override("normal",normal)
 button.add_theme_stylebox_override("hover",hover)
 button.add_theme_stylebox_override("pressed",pressed)
 button.add_theme_stylebox_override("focus",focus_style)
 button.pressed.connect(action)
 var focus_screen: String = screen
 button.focus_entered.connect(func() -> void:
  focus_memory[focus_screen] = button.text
 )
 column.add_child(button)
 return button

func _focus_if_current(control: Control, expected_panel: Control) -> void:
 if not is_instance_valid(control) or not is_instance_valid(expected_panel): return
 if panel != expected_panel or expected_panel.is_queued_for_deletion() or control.is_queued_for_deletion(): return
 if not expected_panel.is_ancestor_of(control): return
 control.grab_focus()

func _focus_first() -> void:
 var remembered: String = str(focus_memory.get(screen,""))
 for child: Node in column.get_children():
  if child is Button and child.text == remembered:
   call_deferred("_focus_if_current",child,panel)
   return
 for child: Node in column.get_children():
  if child is Button or child is LineEdit:
   call_deferred("_focus_if_current",child,panel)
   return

func _show_title() -> void:
 var saves: Array = SaveManager.list_saves()
 _make_panel("Kilómetro a Kilómetro", "Traza caminos, conecta ciudades y cuida tu red.", "title")
 for entry: Dictionary in saves:
  if entry.valid:
   var d: Dictionary = entry.data
   _button("Continuar · %s · %s" % [d.name,d.saved_at],func() -> void: _load(entry.path))
   break
 _button("Nueva partida",func() -> void: _new_menu())
 _button("Cargar partida",func() -> void: _load_menu())
 _button("Opciones y controles",func() -> void: _options())
 _button("Acerca de",func() -> void: _about())
 _button("Salir",func() -> void: _quit_prompt())
 _focus_first()

func _new_menu() -> void:
 _make_panel("Nueva partida", "El nombre y la semilla ya están preparados. Puedes cambiarlos con el teclado en pantalla de tu dispositivo.","new")
 _label("Nombre de la partida")
 input_name = LineEdit.new()
 input_name.text = "Partida " + Time.get_datetime_string_from_system().replace(":","-")
 input_name.virtual_keyboard_enabled = true
 input_name.focus_mode = Control.FOCUS_CLICK
 input_name.custom_minimum_size.y = 40*float(settings.get("ui_scale",1.0))
 _style_field(input_name)
 column.add_child(input_name)
 _label("Semilla (número)")
 input_seed = LineEdit.new()
 input_seed.text = str(randi_range(1,999999))
 input_seed.virtual_keyboard_enabled = true
 input_seed.focus_mode = Control.FOCUS_CLICK
 input_seed.custom_minimum_size.y = 40*float(settings.get("ui_scale",1.0))
 _style_field(input_seed)
 column.add_child(input_seed)
 var mode := OptionButton.new()
 mode.add_item("Partida guiada")
 mode.add_item("Modo libre")
 mode.custom_minimum_size.y = 40*float(settings.get("ui_scale",1.0))
 mode.add_theme_font_size_override("font_size",roundi(17*float(settings.get("ui_scale",1.0))))
 mode.add_theme_color_override("font_color",Color("f0f0e9"))
 _style_field(mode)
 column.add_child(mode)
 _button("Comenzar",func() -> void:
  var seed_number: int = int(input_seed.text) if input_seed.text.is_valid_int() else 1
  state = GameState.new(seed_number)
  state.game_name = input_name.text.strip_edges() if not input_name.text.strip_edges().is_empty() else "Mi partida"
  state.guided = mode.selected == 0
  state.discover(Vector2i.ZERO)
  cursor = Vector2i(2,4); camera_cell = Vector2(cursor); simulation_speed = 1; drawing = false; tool = "Construir"
  _close_panel()
  _notify("Conecta Valdeprado con Los Olmos: A / Intro en cada ciudad.")
 )
 _button("Volver",func() -> void: _show_title())
 # Default to the button so a controller can start without entering text.
 for child: Node in column.get_children():
  if child is Button: call_deferred("_focus_if_current",child,panel); break

func _load_menu() -> void:
 _make_panel("Cargar partida", "Selecciona un guardado.","load")
 var saves: Array = SaveManager.list_saves()
 if saves.is_empty(): _label("Todavía no hay partidas guardadas")
 for entry: Dictionary in saves:
  if entry.valid:
   var d: Dictionary = entry.data
   _button("%s%s · %s · día %d · %.0f €" % [d.name," (auto)" if d.get("automatic",false) else "",d.saved_at,1+int(float(d.elapsed)/120.0),float(d.money)],func() -> void: _load(entry.path))
  else: _label("Guardado dañado: " + str(entry.file))
 _button("Volver",func() -> void: _show_title())
 _focus_first()

func _load(path: String) -> void:
 var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
 if not d is Dictionary: _notify("No se pudo leer el guardado."); _load_menu(); return
 state = GameState.from_data(d)
 cursor = Vector2i(int(d.get("cursor_x",2)),int(d.get("cursor_y",4)))
 camera_cell = Vector2(cursor)
 drawing = false
 _close_panel()
 _notify("Partida cargada.")

func _options() -> void:
 _make_panel("Opciones", "Los ajustes se comparten entre partidas." + ("\n" + settings_error if not settings_error.is_empty() else ""),"options")
 _button("Cuadrícula: " + ("visible" if grid_visible else "oculta"),func() -> void: grid_visible = not grid_visible; settings.grid = grid_visible; _save_settings(); _options())
 _button("Pantalla: " + ("completa" if settings.fullscreen else "ventana"),func() -> void:
  settings.fullscreen = not bool(settings.fullscreen)
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
  _save_settings(); _options())
 _button("Escala de interfaz: %.0f%%" % (float(settings.ui_scale)*100.0),func() -> void:
  settings.ui_scale = 1.0 if float(settings.ui_scale) >= 1.4 else snappedf(float(settings.ui_scale)+0.2,0.1)
  _save_settings(); _options())
 _button("Velocidad del cursor: " + {"lento":"precisa","normal":"normal","rapido":"rápida"}.get(str(settings.cursor_speed),"normal"),func() -> void:
  settings.cursor_speed = {"lento":"normal","normal":"rapido","rapido":"lento"}.get(str(settings.cursor_speed),"normal")
  cursor_motion.set_speed(str(settings.cursor_speed)); _save_settings(); _options())
 _button("Controles de teclado",func() -> void: _controls_menu())
 _button("Volver",func() -> void: _options_back())
 _focus_first()

func _options_back() -> void:
 if state != null: _game_menu()
 else: _show_title()

func _controls_menu() -> void:
 var desc: String = "Elige una acción y pulsa la nueva tecla. Esc cancela. Flechas e Intro siguen disponibles para navegar."
 if not waiting_binding.is_empty(): desc = "Pulsa una tecla para «%s». Esc cancela." % CONTROL_LABELS[waiting_binding]
 if notice_time > 0.0 and not waiting_binding.is_empty(): desc += "\n" + notice
 if not settings_error.is_empty(): desc += "\n" + settings_error
 _make_panel("Controles de teclado",desc,"controls")
 for action: String in CONTROL_LABELS:
  var values: Array = [int(settings.keys[action])] if settings.keys.has(action) else DEFAULT_KEYS[action]
  var names: Array[String] = []
  for key: int in values: names.append(OS.get_keycode_string(key))
  _button("%s: %s" % [CONTROL_LABELS[action]," / ".join(names)],func() -> void: waiting_binding = action; _controls_menu())
 _button("Restaurar controles predeterminados",func() -> void: settings.keys = {}; waiting_binding = ""; _configure_input(); _save_settings(); _controls_menu())
 _button("Volver",func() -> void: waiting_binding = ""; _options())
 _focus_first()

func _about() -> void:
 _make_panel("Acerca de", "Kilómetro a Kilómetro · prototipo 0.1\nUn juego de gestión de carreteras y ciudades.\nGráficos originales dibujados con Godot.","about")
 _button("Volver",func() -> void: _show_title())
 _focus_first()

func _quit_prompt() -> void:
 _make_panel("Salir", "¿Cerrar el juego?", "quit")
 _button("Salir",func() -> void: get_tree().quit())
 _button("Cancelar",func() -> void: _show_title())
 _focus_first()

func _game_menu() -> void:
 _make_panel("Menú", "Selecciona una herramienta o una opción de simulación.","menu")
 for t: String in TOOLS:
  _button(t,func() -> void: tool = t; drawing = false; _close_panel())
 if drawing:
  _button("Fijar punto intermedio aquí",func() -> void: waypoint = cursor; has_waypoint = true; _close_panel(); _refresh_proposal(); _notify("Punto intermedio fijado. Elige el destino."))
  if has_waypoint: _button("Quitar punto intermedio",func() -> void: has_waypoint = false; _close_panel(); _refresh_proposal())
 _button("Velocidad: %s" % ("pausa" if simulation_speed == 0 else str(simulation_speed)+"×"),func() -> void: simulation_speed = {0:1,1:2,2:4,4:0}[simulation_speed]; _game_menu())
 _button("Vista: " + view_mode,func() -> void: view_mode = {"normal":"tráfico","tráfico":"conservación","conservación":"demanda","demanda":"normal"}[view_mode]; _game_menu())
 _button("Opciones",func() -> void: _options())
 _button("Economía y contratos",func() -> void: _economy_menu())
 _button("Balance y tráfico",func() -> void: _traffic_summary())
 _button("Avisos y eventos",func() -> void: _events_menu())
 _button("Guardar partida",func() -> void: _save())
 _button("Volver al menú principal",func() -> void: _return_prompt())
 _button("Continuar jugando",func() -> void: _close_panel())
 _focus_first()

func _economy_menu() -> void:
 var today_income: float = state.income-state.income_day_start
 var today_expenses: float = state.expenses-state.expenses_day_start
 var desc: String = "Hoy: ingresos %.0f € · gastos %.0f € · saldo %+.0f €\nAyer: ingresos %.0f € · gastos %.0f € · saldo %+.0f €\nAcumulado: ingresos %.0f € · gastos %.0f €\nDe ellos: peajes %.0f € · contratos %.0f €\nCiudades conectadas: %d · fiabilidad %.0f%%\nPréstamo pendiente: %.0f € · cuotas fallidas %d" % [today_income,today_expenses,today_income-today_expenses,state.yesterday_income,state.yesterday_expenses,state.yesterday_income-state.yesterday_expenses,state.income,state.expenses,state.toll_income,state.contract_income,state.connected_cities(),state.reliability()*100.0,state.loan_remaining,state.loan_overdue]
 if not state.contract.is_empty():
  var c: Dictionary = state.contract
  desc += "\nContrato %s: %s ↔ %s · %.0f €" % [c.status,state.cities[int(c.origin)].name,state.cities[int(c.destination)].name,c.reward]
  if c.status == "active": desc += " · quedan %.0f s" % maxf(0.0,float(c.deadline)-state.elapsed)
 _make_panel("Economía y contratos",desc,"economy")
 if not state.loan_taken and state.money < Balance.LOAN_PRINCIPAL:
  _button("Préstamo: +%.0f €; devolver %.0f € en cuotas de %.0f €/día" % [Balance.LOAN_PRINCIPAL,Balance.LOAN_TOTAL,Balance.LOAN_DAILY_PAYMENT],func() -> void: state.take_loan(); _economy_menu())
 if state.contract.get("status","") == "offered":
  _button("Aceptar contrato",func() -> void: state.accept_contract(); _economy_menu())
 elif state.contract.get("status","") != "active":
  _button("Buscar contrato de conexión",func() -> void: _offer_contract())
 _button("Volver",func() -> void: _game_menu())
 _focus_first()

func _offer_contract() -> void:
 var count: int = mini(state.cities.size(),12)
 for a: int in range(count):
  for b: int in range(a+1,count):
   if state.contract_history.has("%d:%d" % [a,b]): continue
   if RoadNetwork.route(state.roads,state._city_position(a),state._city_position(b)).is_empty():
    state.offer_contract(a,b)
    _economy_menu()
    return
 _economy_menu()
 _label("No hay conexiones nuevas disponibles entre las primeras ciudades conocidas.")

func _traffic_summary() -> void:
 var text: String = "Demanda potencial: %.1f viajes\nIniciados: %d · completados: %d\nSin atender: %d · interrumpidos: %d\nViajes con retraso: %d\n\nPenalización acumulada por atasco: %.0f €\n  Incluidas colas en cruces: %.0f €\nPenalización acumulada por retrasos: %.0f €\nPenalizaciones de hoy: %.0f € · ayer: %.0f €\n\nAtasco: 2,5 €/s por cada 100%% de ocupación sobre la capacidad; las colas cobran 0,6 €/s por cada vehículo a partir del tercero. Retraso: 4 €/s por encima de 1,6 segundos por casilla en línea recta (mínimo 3 s; máximo 80%% del ingreso)." % [state.potential_demand,state.started_trips,state.completed,state.unmet_demand,state.interrupted,state.late_trips,state.congestion_fines,state.junction_fines,state.delay_fines,state.today_penalties,state.yesterday_penalties]
 _make_panel("Balance y tráfico",text,"traffic_summary")
 _button("Volver",func() -> void: _game_menu())
 _focus_first()

func _events_menu() -> void:
 var description: String = state.latest_notice if not state.latest_notice.is_empty() else "No hay avisos."
 for prediction: Dictionary in state.forecasts:
  description += "\nPrevisión: %s · zona (%d,%d) · comienza en %.0f s" % [GameEvents.TITLES.get(prediction.kind,prediction.kind),prediction.x,prediction.y,maxf(0.0,float(prediction.start_at)-state.elapsed)]
 for event: Dictionary in state.events:
  GameEvents._legacy_entries(event)
  description += "\n%s · inicio %.0f s · quedan %.0f s · %d tramos" % [event.title,event.started,event.remaining,event.affected.size()]
  if event.has("center"): description += " · zona (%d,%d)" % [event.center[0],event.center[1]]
  var effects: Dictionary = {"snow":"velocidad y capacidad reducidas; posibles cierres", "fire":"cierre, propagación y daños", "flood":"puentes cerrados y daños", "landslide":"carretera bloqueada", "fair":"mayor demanda hacia la ciudad"}
  description += "\nEfectos: " + str(effects.get(event.kind,""))
  if event.kind == "fair" and int(event.get("target_city",-1)) >= 0: description += " " + str(state.cities[int(event.target_city)].name)
 _make_panel("Avisos y eventos",description,"events")
 for event: Dictionary in state.events:
  if event.kind in ["snow","landslide"]:
   for entry: Dictionary in event.affected:
    if bool(entry.cleared): continue
    var cost: float = 350.0
    var road_id: int = int(entry.road_id)
    if state.money >= cost:
     _button("Despejar tramo %d · %.0f €" % [road_id,cost],func() -> void:
      if GameEvents.clear_road(state,event,road_id): state.money -= cost; state.expenses += cost
      _events_menu())
 if state.notice_road >= 0:
  _button("Ir al tramo afectado",func() -> void:
   var road: Dictionary = state._road_by_id(state.notice_road)
   if not road.is_empty():
    var point: Array = road.path[int(road.path.size()/2)]
    cursor = Vector2i(int(point[0]),int(point[1]))
   _close_panel())
 _button("Volver",func() -> void: _game_menu())
 _focus_first()

func _save() -> void:
 var error: String = SaveManager.save_game(state)
 _close_panel()
 _notify("Partida guardada." if error.is_empty() else error)

func _return_prompt() -> void:
 _make_panel("Volver al menú principal", "¿Quieres guardar el progreso antes de salir?", "return")
 _button("Guardar y volver",func() -> void:
  var error: String = SaveManager.save_game(state)
  if error.is_empty(): state = null; _show_title()
  else: _close_panel(); _notify(error)
 )
 _button("Volver sin guardar",func() -> void: state = null; _show_title())
 _button("Cancelar",func() -> void: _game_menu())
 _focus_first()

func _inspector() -> void:
 var desc: String = "Casilla (%d, %d) · %s" % [cursor.x,cursor.y,WorldGenerator.terrain_name(state.world.terrain(cursor))]
 for city: Dictionary in state.cities:
  if int(city.x) == cursor.x and int(city.y) == cursor.y:
   desc += "\n%s · %s · %d habitantes\n" % [city.name,WorldGenerator.city_size(int(city.population)),city.population]
   var count: int = 0
   for destination: Dictionary in state.cities:
    if destination == city: continue
    var distance: float = Vector2(float(city.x-destination.x),float(city.y-destination.y)).length()
    var rate: float = minf(Balance.DEMAND_MAX_PER_PAIR,Balance.DEMAND_FACTOR*sqrt(float(city.population)*float(destination.population))/1500.0/(1.0+distance/30.0))
    desc += "%s: demanda %.1f / día · completados %d\n" % [destination.name,rate*Balance.DAY_SECONDS,int(city.completed.get(destination.name,0))]
    count += 1
    if count >= 5: break
 var roads: Array = _road_at(cursor)
 if not roads.is_empty():
  var road: Dictionary = roads[mini(selected_road,roads.size()-1)]
  desc += "\nTramo %d/%d · %s · %s\nLongitud %.1f · conservación %.1f%%\nLímite %.0f km/h · viajes %d\n%s" % [selected_road+1,roads.size(),str(road.get("road_name","Sin nombre")),Balance.ROADS[int(road.type)].name,road.length,road.condition,road.speed_limit,road.trips,"Obras: %.1f s" % road.work if float(road.work)>0 else ("Cerrado" if RoadNetwork.road_closed(road) else "Abierto")]
  var closure_reasons: Array[String] = RoadNetwork.closure_reasons(road)
  if not closure_reasons.is_empty(): desc += "\nMotivos del cierre: " + ", ".join(closure_reasons)
  desc += "\nMantenimiento: %s · %.2f €/s" % ["activo" if road.get("maintenance",false) else "inactivo",maxf(0.1,float(road.length)*0.015)]
  if road.has("scheduled_work"):
   var job: Dictionary = road.scheduled_work
   desc += "\nObra %s · inicio en %.0f s" % [job.status,maxf(0.0,float(job.start_at)-state.elapsed)]
  var current_index: int = road.path.find([cursor.x,cursor.y])
  for span: Dictionary in road.get("overpasses",[]):
   if current_index >= int(span.first)-1 and current_index <= int(span.last)+1:
    desc += "\nPaso elevado · %.1f casillas · sin enlace con la vía inferior" % float(span.length)
  if road.get("overpasses",[]).is_empty() and road.get("raised_indices",[]).has(current_index):
   desc += "\nPaso elevado · sin enlace con la vía inferior"
  for bridge: Dictionary in road.get("bridges",[]):
   if current_index >= int(bridge.start) and current_index <= int(bridge.end):
    desc += "\nPuente: %.1f%% de conservación · categoría %s" % [bridge.condition,Balance.ROADS[int(bridge.category)].name]
  for signal_data: Dictionary in road.get("signals",[]):
   if int(signal_data.index) == road.path.find([cursor.x,cursor.y]):
    desc += "\n%s · llegada en sentido %s" % ["STOP" if signal_data.type == "stop" else "Ceda", "+" if int(signal_data.direction)>0 else "−"]
  var load: float = float(state.traffic_load.get(int(road.id),0.0))
  desc += "\nOcupación: %d / %.1f (%.0f%%)\nVelocidad estimada: %.0f km/h\n%s" % [int(state.traffic_counts.get(int(road.id),0)),state.road_capacity(road),load*100.0,state.effective_speed(road),"Saturada: genera penalización" if load > Balance.CONGESTION_FINE_THRESHOLD else ("Cargada" if load >= Balance.CONGESTION_WARNING else "Fluida")]
 for event: Dictionary in state.events:
  GameEvents._legacy_entries(event)
  for road: Dictionary in roads:
   for entry: Dictionary in event.affected:
    if int(entry.road_id) == int(road.id) and not bool(entry.cleared): desc += "\n%s: quedan %.0f s%s" % [event.title,event.remaining," · CERRADA" if entry.closed else ""]
 var junction_key: String = state._junction_key(cursor)
 var junction_roads: Array = _road_at(cursor)
 if junction_roads.size() > 1:
  var queue: int = int(state.junction_queue_counts.get(junction_key,0))
  var mode: String = "sin regular"
  if state.roundabouts.has(junction_key):
   mode = "rotonda" if float(state.roundabouts[junction_key].work) <= 0.0 else "rotonda en obras (%.0f s)" % state.roundabouts[junction_key].work
  elif state._junction_headway(junction_key) < Balance.JUNCTION_UNCONTROLLED_HEADWAY: mode = "con señales"
  desc += "\nCruce %s · %d vehículos esperando · paso cada %.2f s" % [mode,queue,state._junction_headway(junction_key)]
 _make_panel("Inspector",desc,"inspector")
 if not roads.is_empty():
  var selected: Dictionary = roads[mini(selected_road,roads.size()-1)]
  _button("Abrir carretera" if bool(selected.get("manual_closed",false)) else "Cerrar carretera",func() -> void: _manual_closure_menu(selected))
 if not roads.is_empty() and int(roads[mini(selected_road,roads.size()-1)].type) == 6:
  var toll_road: Dictionary = roads[mini(selected_road,roads.size()-1)]
  _button("Peaje: %.0f €" % float(toll_road.get("toll",0.0)),func() -> void: _toll_menu(toll_road))
 if roads.size() > 1: _button("Siguiente elemento",func() -> void: selected_road = (selected_road+1)%roads.size(); _inspector())
 _button("Volver",func() -> void: _close_panel())
 _focus_first()

func _toll_menu(road: Dictionary) -> void:
 _make_panel("Peaje de autopista", "El peaje se paga solo al completar el viaje. Los coches siguen priorizando el menor tiempo estimado.","action")
 for toll: int in [0,10,25,50,100]:
  _button("%d € por paso" % toll,func() -> void: road.toll = float(toll); _close_panel(); _notify("Peaje actualizado."))
 _button("Volver",func() -> void: _inspector())
 _focus_first()

func _back() -> void:
 match screen:
  "title": _quit_prompt()
  "new", "load", "about", "quit": _show_title()
  "options": _options_back()
  "controls": waiting_binding = ""; _options()
  "return", "events", "traffic_summary", "economy": _game_menu()
  _: _close_panel()

func _close_panel() -> void:
 cursor_motion.reset()
 menu_motion.reset()
 for child: Node in overlay.get_children(): child.queue_free()
 screen = "game"

func _notify(message: String, road_id: int = -1, point: Array = []) -> void:
 notice = message
 notice_road_id = road_id
 notice_point = point.duplicate()
 notice_time = 12.0

func _dismiss_notice() -> void:
 # Hide only the banner; active events and their consequences continue.
 notice_time = 0.0
 notice_road_id = -1
 notice_point = []

func _go_to_notice() -> void:
 if state == null or notice_road_id < 0: return
 var road: Dictionary = state._road_by_id(notice_road_id)
 if road.is_empty() or road.path.is_empty():
  _notify("El tramo del aviso ya no existe.")
  return
 var point: Array = notice_point if notice_point.size() == 2 else road.path[int(road.path.size()/2)]
 cursor = Vector2i(int(point[0]),int(point[1]))
 camera_cell = Vector2(cursor)
 selected_road = 0
 _refresh_proposal()
 _dismiss_notice()

func _draw() -> void:
 var size: Vector2 = get_viewport_rect().size
 draw_rect(Rect2(Vector2.ZERO,size),Color("1d3332"))
 var world: WorldGenerator = state.world if state != null else background_world
 var center: Vector2 = camera_cell if state != null else Vector2(13,8)
 var cell: float = 24.0 * zoom if state != null else 24.0
 var offset: Vector2 = size * 0.5 - center * cell
 var minp := Vector2i(floori(-offset.x/cell)-1,floori(-offset.y/cell)-1)
 var maxp := Vector2i(ceili((size.x-offset.x)/cell)+1,ceili((size.y-offset.y)/cell)+1)
 var colors: Dictionary = {"pradera":Color("a8bf91"),"llanura":Color("bdc99d"),"bosque":Color("708f70"),"colina":Color("b8aa82"),"montaña":Color("888b80"),"marisma":Color("667e6e"),"desierto":Color("c9ad79"),"agua":Color("6b9da8")}
 for y: int in range(minp.y,maxp.y):
  for x: int in range(minp.x,maxp.x):
   var p := Vector2i(x,y)
   var rect := Rect2(offset + Vector2(p)*cell,Vector2.ONE*cell)
   draw_rect(rect,colors[world.terrain(p)])
   if grid_visible and cell > 12.0: draw_rect(rect,Color(0.1,0.2,0.15,0.10),false,1.0)
 var cities: Array = state.cities if state != null else background_world.cities_for_chunk(Vector2i.ZERO)
 if state != null:
  for event: Dictionary in state.events:
   if event.has("center"):
    var center_pos: Vector2 = offset+(Vector2(float(event.center[0]),float(event.center[1]))+Vector2(0.5,0.5))*cell
    var event_color: Color = Color(0.85,0.35,0.22,0.30) if event.kind == "fire" else Color(0.65,0.78,0.92,0.34)
    draw_arc(center_pos,float(event.radius)*cell,0.0,TAU,64,event_color,maxf(2.0,cell*0.08),true)
  geometry_anchors = _geometry_anchors()
  if drawing:
   for span: Dictionary in proposal.get("overpasses",[]): _anchor_underpass(span,geometry_anchors)
  var junctions: Dictionary = _junctions()
  # Draw every shoulder before every surface so connected roads blend together.
  for road: Dictionary in state.roads: _draw_road_layer(road,offset,cell,true)
  for road: Dictionary in state.roads: _draw_road_layer(road,offset,cell,false)
  for road: Dictionary in state.roads: _draw_road_details(road,offset,cell,junctions)
  _draw_roundabouts(offset,cell)
  for road: Dictionary in state.roads: _draw_overpasses(road,offset,cell)
  for road: Dictionary in state.roads: _draw_road_name(road,offset,cell)
  _draw_junction_queues(offset,cell)
  if drawing and has_waypoint:
   draw_circle(offset+(Vector2(waypoint)+Vector2(0.5,0.5))*cell,maxf(5.0,cell*0.23),Color("f5df81"),false,2.0)
  if drawing and proposal.has("path"):
   var preview_anchors: Dictionary = _preview_anchors()
   var points: PackedVector2Array = RoadGeometry.polyline(proposal.path,offset,cell,8,preview_anchors)
   var preview_color: Color = Color("e84c43") if proposal.has("error") else Color("f5df81")
   if points.size() > 1: draw_polyline(points,preview_color,maxf(3.0,cell*0.22),true)
   for span: Dictionary in proposal.get("overpasses",[]):
    var deck := PackedVector2Array()
    for segment: int in range(int(span.first)-1,int(span.last)+1):
     for j: int in range(8): deck.append(offset+(RoadGeometry.point(proposal.path,segment,float(j)/8.0,preview_anchors)+Vector2(0.5,0.5))*cell)
    deck.append(offset+(Vector2(proposal.path[int(span.last)+1])+Vector2(0.5,0.5))*cell)
    draw_polyline(deck,Color("35657a"),maxf(5.0,cell*0.38),true)
    draw_polyline(deck,Color("b9e7f0"),maxf(2.0,cell*0.18),true)
    for ramp: Array in [span.start,span.end]:
     draw_circle(offset+(Vector2(float(ramp[0]),float(ramp[1]))+Vector2(0.5,0.5))*cell,maxf(5.0,cell*0.2),Color("f9f1b4"),false,2.0)
   if proposal.has("conflict_index"):
    var conflict: Vector2i = proposal.path[int(proposal.conflict_index)]
    var conflict_center: Vector2 = offset+(Vector2(conflict)+Vector2(0.5,0.5))*cell
    draw_rect(Rect2(offset+Vector2(conflict)*cell,Vector2.ONE*cell),Color(0.91,0.22,0.17,0.28),true)
    draw_circle(conflict_center,maxf(6.0,cell*0.35),Color("e84c43"),false,3.0)
 else:
  draw_line(offset+Vector2(2.5,4.5)*cell,offset+Vector2(10.5,5.5)*cell,Color("8a6241"),8.0,true)
  draw_line(offset+Vector2(10.5,5.5)*cell,offset+Vector2(27.5,7.5)*cell,Color("697478"),9.0,true)
 for city: Dictionary in cities:
  var pos: Vector2 = offset + Vector2(float(city.x)+0.5,float(city.y)+0.5)*cell
  if not Rect2(Vector2(-100,-100),size+Vector2(200,200)).has_point(pos): continue
  var radius: float = clampf(5.0+sqrt(float(city.population))/22.0,7.0,13.0)*zoom
  if state != null and view_mode == "demanda":
   var demand: float = _city_demand(city)
   draw_arc(pos,radius+5.0+minf(12.0,demand/80.0),0.0,TAU,32,Color("edc76c"),2.5,true)
   draw_string(ThemeDB.fallback_font,pos+Vector2(12,radius+15),"%.0f viajes/día" % demand,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("243c38"))
  draw_circle(pos,radius,Color("30494a"))
  draw_rect(Rect2(pos-Vector2(radius*0.6,radius*0.65),Vector2(radius*1.2,radius*1.3)),Color("efe4c9"))
  var font := ThemeDB.fallback_font
  var city_name: String = city.name
  var city_details := "%s (%d hab.)" % [WorldGenerator.city_size(int(city.population)),city.population]
  var label_scale: float = float(settings.get("ui_scale",1.0))
  var name_size: int = roundi(16.0*label_scale)
  var detail_size: int = roundi(12.0*label_scale)
  var details_y: float = pos.y-radius-5.0
  draw_string(font,Vector2(pos.x-font.get_string_size(city_name,HORIZONTAL_ALIGNMENT_LEFT,-1,name_size).x/2.0,details_y-15.0*label_scale),city_name,HORIZONTAL_ALIGNMENT_LEFT,-1,name_size,Color("1a2c2c"))
  draw_string(font,Vector2(pos.x-font.get_string_size(city_details,HORIZONTAL_ALIGNMENT_LEFT,-1,detail_size).x/2.0,details_y),city_details,HORIZONTAL_ALIGNMENT_LEFT,-1,detail_size,Color("1a2c2c"))
 if state != null:
  for vehicle: Dictionary in state.vehicles: _draw_vehicle(vehicle,offset,cell)
  var cpos: Vector2 = offset+Vector2(cursor)*cell
  draw_rect(Rect2(cpos,Vector2.ONE*cell),Color("fff1a5"),false,3.0)
  _draw_hud(size)

func _city_demand(city: Dictionary) -> float:
 var demand: float = 0.0
 var count: int = 0
 var nearby: Array = state.cities.duplicate()
 nearby.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
  return Vector2(float(city.x-a.x),float(city.y-a.y)).length() < Vector2(float(city.x-b.x),float(city.y-b.y)).length())
 for other: Dictionary in nearby:
  if is_same(other,city): continue
  var distance: float = Vector2(float(city.x-other.x),float(city.y-other.y)).length()
  demand += minf(Balance.DEMAND_MAX_PER_PAIR,Balance.DEMAND_FACTOR*sqrt(float(city.population)*float(other.population))/1500.0/(1.0+distance/30.0))*Balance.DAY_SECONDS
  count += 1
  if count >= Balance.DEMAND_DESTINATIONS: break
 return demand

func _road_width(road: Dictionary, cell: float) -> float:
 return maxf(3.0,cell*0.29*float(Balance.ROADS[int(road.type)].width))

func _road_color(road: Dictionary) -> Color:
 var color: Color = Balance.ROADS[int(road.type)].color
 if view_mode == "tráfico":
  var load: float = float(state.traffic_load.get(int(road.id),0.0))
  color = Color("c44e44") if load > 1.0 else (Color("e0af4f") if load >= Balance.CONGESTION_WARNING else Color("69b78e"))
 if view_mode == "conservación": color = Color("e8b46b") if float(road.condition) < 60.0 else Color("73c89b")
 if RoadNetwork.road_closed(road): color = Color("bd8a50")
 return color

func _draw_road_name(road: Dictionary, offset: Vector2, cell: float) -> void:
 var label: String = str(road.get("road_name",""))
 var path: Array = road.path
 if label.is_empty() or path.size() < 2: return
 # Find the midpoint by distance, so diagonal cells do not shift the label.
 var total: float = 0.0
 for i: int in range(path.size()-1):
  total += RoadGeometry._vector(path[i]).distance_to(RoadGeometry._vector(path[i+1]))
 var half: float = total*0.5
 var segment: int = 0
 var t: float = 0.5
 for i: int in range(path.size()-1):
  var length: float = RoadGeometry._vector(path[i]).distance_to(RoadGeometry._vector(path[i+1]))
  if half <= length:
   segment = i
   t = clampf(half/maxf(length,0.001),0.0,1.0)
   break
  half -= length
 var center: Vector2 = offset+(RoadGeometry.point(path,segment,t,geometry_anchors)+Vector2(0.5,0.5))*cell
 if not Rect2(Vector2(-40,-40),get_viewport_rect().size+Vector2(80,80)).has_point(center): return
 var before: Vector2 = RoadGeometry.point(path,segment,maxf(0.0,t-0.1),geometry_anchors)
 var after: Vector2 = RoadGeometry.point(path,segment,minf(1.0,t+0.1),geometry_anchors)
 var tangent: Vector2 = after-before
 if tangent.length_squared() < 0.0001: tangent = RoadGeometry._vector(path[segment+1])-RoadGeometry._vector(path[segment])
 var angle: float = tangent.angle()
 if angle > PI*0.5 or angle < -PI*0.5: angle = wrapf(angle+PI,-PI,PI)
 var normal := Vector2(-sin(angle),cos(angle))
 var position: Vector2 = center-normal*(_road_width(road,cell)*0.5+5.0)
 var font: Font = ThemeDB.fallback_font
 var font_size: int = 9
 var width: float = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
 draw_set_transform(position,angle,Vector2.ONE)
 var baseline := Vector2(-width*0.5,0.0)
 draw_string_outline(font,baseline,label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,2,Color("e7efdd"))
 draw_string(font,baseline,label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("24362f"))
 draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)

func _draw_road_layer(road: Dictionary, offset: Vector2, cell: float, shoulder: bool) -> void:
 var points: PackedVector2Array = RoadGeometry.polyline(road.path,offset,cell,8,geometry_anchors)
 if points.size() < 2: return
 var width: float = _road_width(road,cell)
 var color: Color = Color("62685a") if shoulder else _road_color(road)
 var actual_width: float = width + maxf(1.5,cell*0.07) if shoulder else width
 draw_polyline(points,color,actual_width,true)
 # Rounded caps avoid square joins at city accesses and at the ends of roads.
 draw_circle(points[0],actual_width*0.5,color)
 draw_circle(points[-1],actual_width*0.5,color)

func _junctions() -> Dictionary:
 var locations: Dictionary = {}
 for road: Dictionary in state.roads:
  if int(road.type) > 3: continue
  for i: int in range(road.path.size()):
   if RoadNetwork._level(road,i) != 0: continue
   var p: Array = road.path[i]
   var key := Vector2i(int(p[0]),int(p[1]))
   if not locations.has(key): locations[key] = []
   locations[key].append(road)
 var result: Dictionary = {}
 for key: Vector2i in locations:
  var roads: Array = locations[key]
  var unique: Dictionary = {}
  for road: Dictionary in roads: unique[int(road.id)] = road
  if unique.size() > 1: result[key] = unique.values()
 return result

# Fix shared coordinates while rounding every other bend. This includes grade
# separations: although they do not connect, both decks must cross in place.
func _geometry_anchors() -> Dictionary:
 var owner: Dictionary = {}
 var anchors: Dictionary = {}
 for city: Dictionary in state.cities: anchors[Vector2i(int(city.x),int(city.y))] = true
 for road: Dictionary in state.roads:
  for item: Array in road.path:
   var point := Vector2i(int(item[0]),int(item[1]))
   if owner.has(point) and int(owner[point]) != int(road.id): anchors[point] = true
   else: owner[point] = int(road.id)
  for index_value: Variant in road.get("raised_indices",[]):
   var index: int = int(index_value)
   if index >= 0 and index < road.path.size():
    var point: Array = road.path[index]
    anchors[Vector2i(int(point[0]),int(point[1]))] = true
  for span: Dictionary in road.get("overpasses",[]): _anchor_underpass(span,anchors)
 return anchors

func _anchor_underpass(span: Dictionary, anchors: Dictionary) -> void:
 if not span.has("lower_road_id"): return
 var road: Dictionary = state._road_by_id(int(span.lower_road_id))
 if road.is_empty(): return
 for index: int in [int(span.lower_first),int(span.lower_last)]:
  if index < 0 or index >= road.path.size(): continue
  var point: Array = road.path[index]
  anchors[Vector2i(int(point[0]),int(point[1]))] = true

func _preview_anchors() -> Dictionary:
 var anchors: Dictionary = geometry_anchors.duplicate()
 for road: Dictionary in state.roads:
  for item: Array in road.path: anchors[Vector2i(int(item[0]),int(item[1]))] = true
 for index_value: Variant in proposal.get("raised_indices",[]):
  var index: int = int(index_value)
  if index >= 0 and index < proposal.path.size(): anchors[Vector2i(proposal.path[index])] = true
 for span: Dictionary in proposal.get("overpasses",[]): _anchor_underpass(span,anchors)
 return anchors

func _draw_road_details(road: Dictionary, offset: Vector2, cell: float, junctions: Dictionary) -> void:
 var path: Array = road.path
 var width: float = _road_width(road,cell)
 var road_type: int = int(road.type)
 # Short centre dashes and thin edge lines give paved roads scale without
 # drawing misleading markings through an intersection.
 if cell >= 14.0 and road_type >= 2:
  for i: int in range(path.size()-1):
   var a: Vector2i = Vector2i(int(path[i][0]),int(path[i][1]))
   var b: Vector2i = Vector2i(int(path[i+1][0]),int(path[i+1][1]))
   if junctions.has(a) or junctions.has(b): continue
   for part: int in range(4):
    var t0: float = float(part)/4.0
    var t1: float = minf(1.0,t0+0.13)
    var p: Vector2 = offset+(RoadGeometry.point(path,i,t0,geometry_anchors)+Vector2(0.5,0.5))*cell
    var q: Vector2 = offset+(RoadGeometry.point(path,i,t1,geometry_anchors)+Vector2(0.5,0.5))*cell
    if road_type >= 5:
     draw_line(p,q,Color("e5e0cc"),maxf(1.0,cell*0.035),true)
    elif part % 2 == 0:
     draw_line(p,q,Color(0.95,0.94,0.81,0.8),maxf(1.0,cell*0.035),true)
 # Subtle wheel-worn tracks distinguish dirt and rural lanes from asphalt.
 if cell >= 18.0 and road_type <= 1:
  for i: int in range(path.size()-1):
   var a := Vector2i(int(path[i][0]),int(path[i][1]))
   var b := Vector2i(int(path[i+1][0]),int(path[i+1][1]))
   if junctions.has(a) or junctions.has(b): continue
   for part: int in range(8):
    var p: Vector2 = offset+(RoadGeometry.point(path,i,float(part)/8.0,geometry_anchors)+Vector2(0.5,0.5))*cell
    var q: Vector2 = offset+(RoadGeometry.point(path,i,float(part+1)/8.0,geometry_anchors)+Vector2(0.5,0.5))*cell
    var normal: Vector2 = (q-p).normalized().orthogonal()*width*0.22
    var track := Color(0.31,0.24,0.17,0.16)
    draw_line(p+normal,q+normal,track,maxf(1.0,width*0.12),true)
    draw_line(p-normal,q-normal,track,maxf(1.0,width*0.12),true)
 for signal_data: Dictionary in road.get("signals",[]):
  var index: int = int(signal_data.index)
  var previous_index: int = index-int(signal_data.direction)
  if index < 0 or index >= path.size() or previous_index < 0 or previous_index >= path.size(): continue
  var point: Vector2 = RoadGeometry._vector(path[index])
  var sign_key: String = state._junction_key(Vector2i(point))
  if state.roundabouts.has(sign_key) and float(state.roundabouts[sign_key].work) <= 0.0: continue
  var previous: Vector2 = RoadGeometry._vector(path[previous_index])
  var toward: Vector2 = (previous-point).normalized()
  var position: Vector2 = offset+(point+Vector2(0.5,0.5)+toward*0.28)*cell
  draw_circle(position,maxf(5.0,cell*0.19),Color("bc3b32") if signal_data.type == "stop" else Color("f2efe1"))
  draw_string(ThemeDB.fallback_font,position+Vector2(-3,4),"S" if signal_data.type == "stop" else "C",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color.WHITE if signal_data.type == "stop" else Color("992e29"))
 # Bridge deck and rails follow the same curve as the road, instead of dots.
 for i: int in range(path.size()-1):
  var a := Vector2i(int(path[i][0]),int(path[i][1]))
  var b := Vector2i(int(path[i+1][0]),int(path[i+1][1]))
  if state.world.terrain(a) != "agua" and state.world.terrain(b) != "agua": continue
  var section := PackedVector2Array()
  for j: int in range(7): section.append(offset+(RoadGeometry.point(path,i,float(j)/6.0,geometry_anchors)+Vector2(0.5,0.5))*cell)
  draw_polyline(section,Color("d5c9b2"),width+maxf(2.0,cell*0.09),true)
  draw_polyline(section,_road_color(road),width,true)
 if RoadNetwork.road_closed(road):
  var middle: Vector2 = offset+(RoadGeometry._vector(path[int(path.size()/2)])+Vector2(0.5,0.5))*cell
  draw_circle(middle,maxf(6.0,cell*0.3),Color("b6342e"))
  draw_line(middle-Vector2(5,0),middle+Vector2(5,0),Color.WHITE,2.0)

func _draw_junction_queues(offset: Vector2, cell: float) -> void:
 for key: String in state.junction_queue_counts:
  var count: int = int(state.junction_queue_counts[key])
  if count < 2: continue
  var parts: PackedStringArray = key.split(",")
  if parts.size() != 2: continue
  var center: Vector2 = offset+(Vector2(float(parts[0]),float(parts[1]))+Vector2(0.5,0.5))*cell
  if not Rect2(Vector2(-100,-100),get_viewport_rect().size+Vector2(200,200)).has_point(center): continue
  var label: String = "Cola: %d" % count
  var box := Rect2(center+Vector2(cell*0.45,-cell*0.8),Vector2(64,21))
  draw_rect(box,Color(0.32,0.12,0.09,0.92) if count >= 5 else Color(0.38,0.29,0.12,0.94))
  draw_string(ThemeDB.fallback_font,box.position+Vector2(5,15),label,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)

func _draw_roundabouts(offset: Vector2, cell: float) -> void:
 for key: String in state.roundabouts:
  var item: Dictionary = state.roundabouts[key]
  var center: Vector2 = offset+(Vector2(float(item.x),float(item.y))+Vector2(0.5,0.5))*cell
  if not Rect2(Vector2(-cell,-cell),get_viewport_rect().size+Vector2(2*cell,2*cell)).has_point(center): continue
  var radius: float = maxf(5.0,cell*0.48)
  draw_circle(center,radius+1.5,Color("49534e"))
  draw_circle(center,radius,Color("808886") if float(item.work)<=0.0 else Color("bd8a50"))
  draw_arc(center,radius*0.72,0.0,TAU,24,Color("ede8d6"),maxf(1.0,cell*0.035),true)
  draw_circle(center,radius*0.47,Color("96a883"))
  if float(item.work)>0.0:
   draw_string(ThemeDB.fallback_font,center+Vector2(-4,4),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)

func _draw_overpasses(road: Dictionary, offset: Vector2, cell: float) -> void:
 var path: Array = road.path
 var indices: Array = road.get("raised_indices",[]).duplicate()
 indices.sort()
 var groups: Array = []
 for value: Variant in indices:
  var index: int = int(value)
  if groups.is_empty() or index > int(groups[-1].last)+1: groups.append({"first":index,"last":index})
  else: groups[-1].last = index
 for group: Dictionary in groups:
  var first: int = int(group.first)
  var last: int = int(group.last)
  if first < 1 or last >= path.size()-1: continue
  var points := PackedVector2Array()
  for i: int in range(first-1,last+1):
   for j: int in range(8): points.append(offset+(RoadGeometry.point(path,i,float(j)/8.0,geometry_anchors)+Vector2(0.5,0.5))*cell)
  points.append(offset+(RoadGeometry._vector(path[last+1])+Vector2(0.5,0.5))*cell)
  var width: float = _road_width(road,cell)
  draw_polyline(points,Color(0.12,0.17,0.16,0.4),width+maxf(5.0,cell*0.22),true)
  draw_polyline(points,Color("ded4c0"),width+maxf(3.0,cell*0.12),true)
  draw_polyline(points,_road_color(road),width,true)

func _draw_vehicle(vehicle: Dictionary, offset: Vector2, cell: float) -> void:
 if vehicle.has("signal_pending"):
  var pending: Dictionary = vehicle.signal_pending
  var incoming: Dictionary = state._road_by_id(int(pending.get("previous_road",-1)))
  var at: int = int(pending.get("previous_index",-1))
  var from: int = int(pending.get("approach_index",-1))
  if not incoming.is_empty() and at >= 0 and from >= 0 and at < incoming.path.size() and from < incoming.path.size():
   var junction: Vector2 = RoadGeometry._vector(incoming.path[at])
   var approach: Vector2 = RoadGeometry._vector(incoming.path[from])
   var position: Vector2 = junction.lerp(approach,0.32)
   draw_circle(offset+(position+Vector2(0.5,0.5))*cell,maxf(2.5,cell*0.1),Color("fff9df"))
   return
 if vehicle.has("route"):
  var route: Array = vehicle.route
  var route_index: int = int(vehicle.route_index)
  if route_index >= route.size(): return
  var segment: Dictionary = route[route_index]
  var current_road: Dictionary = state._road_by_id(int(segment.road))
  if current_road.is_empty(): return
  var from_index: int = int(segment.from_index)
  var to_index: int = int(segment.to_index)
  var t: float = clampf(float(vehicle.segment_progress),0.0,1.0)
  var point: Vector2 = RoadGeometry.point(current_road.path,mini(from_index,to_index),t if from_index < to_index else 1.0-t,geometry_anchors)
  draw_circle(offset+(point+Vector2(0.5,0.5))*cell,maxf(2.5,cell*0.1),Color("fff9df"))
  return
 var road: Dictionary = state._road_by_id(int(vehicle.road))
 if road.is_empty(): return
 var path: Array = road.path
 var progress: float = 1.0-float(vehicle.progress) if bool(vehicle.reverse) else float(vehicle.progress)
 var index: float = clampf(progress,0.0,0.99999)*float(path.size()-1)
 var pos: Vector2 = RoadGeometry.point(path,int(index),fposmod(index,1.0),geometry_anchors)
 draw_circle(offset+(pos+Vector2(0.5,0.5))*cell,maxf(2.5,cell*0.1),Color("fff9df"))

func _draw_fit(font: Font, position: Vector2, value: String, desired_size: int, available: float, color: Color) -> void:
 var measured: float = font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,desired_size).x
 var actual: int = maxi(11,roundi(float(desired_size)*minf(1.0,available/maxf(1.0,measured))))
 draw_string(font,position,value,HORIZONTAL_ALIGNMENT_LEFT,available,actual,color)

func _draw_hud(size: Vector2) -> void:
 var font: Font = ThemeDB.fallback_font
 var scale: float = float(settings.get("ui_scale",1.0))
 var heading_size: int = roundi(16*scale)
 var value_size: int = roundi(21*scale)
 var label_size: int = roundi(11*scale)
 var help_size: int = roundi(12*scale)
 var top_height: float = 68.0*scale
 var bottom_height: float = 108.0*scale
 var inset: float = 18.0*scale
 var content_width: float = size.x-inset*2.0
 var status_width: float = minf(220.0*scale,content_width*0.22)
 var metrics_width: float = content_width-status_width
 var column_width: float = metrics_width/4.0
 var surface := Color(0.035,0.075,0.075,0.98)
 var muted := Color("b8c9bd")
 draw_rect(Rect2(0,0,size.x,top_height),surface)
 draw_rect(Rect2(0,top_height-2.0*scale,size.x,2.0*scale),Color("b18a52"))
 draw_rect(Rect2(inset*0.5,4.0*scale,size.x-inset,top_height-9.0*scale),Color(0.72,0.85,0.75,0.72),false,1.0*scale)
 var metrics: Array = [
  ["TESORERÍA", "%.0f €" % state.money, Color("f2e4b3")],
  ["INGRESOS", "+%.0f €" % state.income, Color("a9d3a3")],
  ["GASTOS", "−%.0f €" % state.expenses, Color("e5b6a1")],
  ["PENALIZACIÓN HOY", "%.0f €" % state.today_penalties, Color("edc879")]
 ]
 for index: int in range(metrics.size()):
  var x: float = inset+column_width*index
  var entry: Array = metrics[index]
  _draw_fit(font,Vector2(x,22.0*scale),str(entry[0]),label_size,column_width-14.0*scale,muted)
  _draw_fit(font,Vector2(x,49.0*scale),str(entry[1]),value_size,column_width-14.0*scale,entry[2])
  if index > 0: draw_line(Vector2(x-10.0*scale,13.0*scale),Vector2(x-10.0*scale,56.0*scale),Color(0.72,0.82,0.75,0.22),1.0*scale)
 var sim_status: String = "%d viajes  ·  Día %d  ·  %s" % [state.completed,1+int(state.elapsed/120.0),"PAUSADO" if simulation_speed == 0 else "%d×" % simulation_speed]
 var status_x: float = inset+metrics_width
 draw_line(Vector2(status_x-12.0*scale,13.0*scale),Vector2(status_x-12.0*scale,56.0*scale),Color(0.72,0.82,0.75,0.22),1.0*scale)
 _draw_fit(font,Vector2(status_x,top_height*0.57),sim_status,label_size,status_width-10.0*scale,muted)
 var details: String = "%s  /  %s  /  (%d, %d)  /  %s" % [tool,Balance.ROADS[selected_type].name,cursor.x,cursor.y,WorldGenerator.terrain_name(state.world.terrain(cursor))]
 if drawing:
  if not proposal.has("error") and proposal.has("length"): details += "  /  %.0f €  /  puente %d" % [state.price(proposal,selected_type),proposal.water]
 var footer_y: float = size.y-bottom_height
 draw_rect(Rect2(0,footer_y,size.x,bottom_height),surface)
 draw_rect(Rect2(0,footer_y,size.x,2.0*scale),Color("b18a52"))
 var visible_count: int = mini(5, TOOLS.size())
 var item_width: float = content_width / float(visible_count)
 var selected_index: int = TOOLS.find(tool)
 for slot: int in range(visible_count):
  var index: int = posmod(selected_index + slot - visible_count / 2, TOOLS.size())
  var item_x: float = inset + item_width * slot
  var active: bool = TOOLS[index] == tool
  if active:
   draw_rect(Rect2(item_x,footer_y+8.0*scale,item_width-4.0*scale,34.0*scale),Color("b18a52"))
  _draw_fit(font,Vector2(item_x+5.0*scale,footer_y+30.0*scale),TOOLS[index],roundi(14*scale),item_width-14.0*scale,Color("142a29") if active else Color.WHITE)
 _draw_fit(font,Vector2(inset,footer_y+65.0*scale),details,help_size,content_width*0.48,Color("f2e4b3"))
 var controls: String = "L1 / R1  Herramienta    Y  Opciones    A  Usar    B  Cancelar    X  Menú" if last_device == "mando" else "%s / %s  Herramienta    %s  Opciones    %s  Usar    %s  Cancelar    %s  Menú" % [_key_hint("tool_previous","F8"),_key_hint("tool_action","Tab"),_key_hint("inspect_action","I"),_key_hint("accept_action","Intro"),_key_hint("back_action","Esc"),_key_hint("menu_action","M")]
 _draw_fit(font,Vector2(inset,footer_y+91.0*scale),controls,help_size,content_width,Color.WHITE)
 var legend: String = ""
 if view_mode == "tráfico": legend = "Tráfico: verde fluido · ámbar cargado · rojo saturado"
 elif view_mode == "conservación": legend = "Conservación: verde ≥ 60% · ámbar < 60% · barrera = cierre"
 elif view_mode == "demanda": legend = "Demanda potencial estimada por día hacia ciudades cercanas"
 if not legend.is_empty():
  draw_rect(Rect2(inset,size.y-bottom_height-30*scale,minf(content_width,650*scale),26*scale),surface)
  _draw_fit(font,Vector2(inset+10.0*scale,size.y-bottom_height-12*scale),legend,help_size,minf(content_width-20.0*scale,630*scale),Color.WHITE)
 if drawing and proposal.has("error"):
  var warning_width: float = minf(content_width,900.0*scale)
  var warning_height: float = 38.0*scale
  var warning_y: float = footer_y-warning_height-8.0*scale
  draw_rect(Rect2(inset,warning_y,warning_width,warning_height),Color(0.20,0.055,0.055,0.97))
  draw_rect(Rect2(inset,warning_y,4.0*scale,warning_height),Color("e84c43"))
  _draw_fit(font,Vector2(inset+12.0*scale,warning_y+25.0*scale),str(proposal.error),roundi(14*scale),warning_width-24.0*scale,Color("ffe7df"))
 if notice_time > 0.0:
  var banner_width: float = minf(size.x-inset*2.0,1000.0*scale)
  var banner_y: float = top_height+10.0*scale
  var banner_height: float = 42.0*scale
  draw_rect(Rect2(inset,banner_y,banner_width,banner_height),Color(0.035,0.09,0.09,0.97))
  draw_rect(Rect2(inset,banner_y,3.0*scale,banner_height),Color("edc879"))
  var can_go: bool = notice_road_id >= 0 and not state._road_by_id(notice_road_id).is_empty()
  var go_key: String = "R4" if last_device == "mando" else _key_hint("notice_go","F6")
  var dismiss_key: String = "L4" if last_device == "mando" else _key_hint("notice_dismiss","F7")
  var hint: String = "%s ir al aviso   ·   %s descartar" % [go_key,dismiss_key] if can_go else "%s descartar" % dismiss_key
  var banner_text_width: float = banner_width-24.0*scale
  var hint_width: float = minf(font.get_string_size(hint,HORIZONTAL_ALIGNMENT_LEFT,-1,help_size).x+4.0*scale,250.0*scale)
  _draw_fit(font,Vector2(inset+12.0*scale,banner_y+26.0*scale),notice,roundi(14*scale),banner_text_width-hint_width-14.0*scale,Color.WHITE)
  _draw_fit(font,Vector2(inset+banner_width-hint_width-8.0*scale,banner_y+26.0*scale),hint,help_size,hint_width,Color("f2e4b3"))
