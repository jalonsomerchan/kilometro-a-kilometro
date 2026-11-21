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
var screen: String = "title"
var overlay: CanvasLayer
var panel: PanelContainer
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

func _ready() -> void:
 _configure_input()
 overlay = CanvasLayer.new()
 add_child(overlay)
 _show_title()

func _configure_input() -> void:
 var bindings: Dictionary = {"move_up":[KEY_UP,KEY_W],"move_down":[KEY_DOWN,KEY_S],"move_left":[KEY_LEFT,KEY_A],"move_right":[KEY_RIGHT,KEY_D],"accept_action":[KEY_ENTER,KEY_SPACE],"back_action":[KEY_ESCAPE,KEY_DELETE],"inspect_action":[KEY_I],"menu_action":[KEY_M],"road_prev":[KEY_Q],"road_next":[KEY_E],"pause_action":[KEY_P],"tool_action":[KEY_TAB],"zoom_in":[KEY_EQUAL,KEY_KP_ADD],"zoom_out":[KEY_MINUS,KEY_KP_SUBTRACT]}
 for action: String in bindings:
  if not InputMap.has_action(action): InputMap.add_action(action)
  for key: int in bindings[action]:
   var event := InputEventKey.new()
   event.physical_keycode = key
   InputMap.action_add_event(action,event)
 # Logical symbols follow the active keyboard layout (on Spanish keyboards + is
 # not on the physical key used by US =). Keypad and physical bindings remain.
 for binding: Array in [["zoom_in", KEY_PLUS], ["zoom_in", KEY_EQUAL], ["zoom_out", KEY_MINUS]]:
  var logical := InputEventKey.new()
  logical.keycode = binding[1]
  InputMap.action_add_event(binding[0], logical)
 var joy: Dictionary = {"move_up":JOY_BUTTON_DPAD_UP,"move_down":JOY_BUTTON_DPAD_DOWN,"move_left":JOY_BUTTON_DPAD_LEFT,"move_right":JOY_BUTTON_DPAD_RIGHT,"accept_action":JOY_BUTTON_A,"back_action":JOY_BUTTON_B,"inspect_action":JOY_BUTTON_Y,"menu_action":JOY_BUTTON_X,"road_prev":JOY_BUTTON_LEFT_SHOULDER,"road_next":JOY_BUTTON_RIGHT_SHOULDER,"pause_action":JOY_BUTTON_START}
 for action: String in joy:
  var event := InputEventJoypadButton.new()
  event.button_index = joy[action]
  InputMap.action_add_event(action,event)
 for axis_data: Array in [["move_left",JOY_AXIS_LEFT_X,-1.0],["move_right",JOY_AXIS_LEFT_X,1.0],["move_up",JOY_AXIS_LEFT_Y,-1.0],["move_down",JOY_AXIS_LEFT_Y,1.0],["zoom_out",JOY_AXIS_TRIGGER_LEFT,1.0],["zoom_in",JOY_AXIS_TRIGGER_RIGHT,1.0]]:
  var event := InputEventJoypadMotion.new()
  event.axis = axis_data[1]
  event.axis_value = axis_data[2]
  InputMap.action_add_event(axis_data[0],event)
  InputMap.action_set_deadzone(axis_data[0],0.4)

func _process(delta: float) -> void:
 if notice_time > 0.0: notice_time -= delta
 if screen == "game" and state != null:
  var zi: float = Input.get_action_strength("zoom_in")
  var zo: float = Input.get_action_strength("zoom_out")
  zoom = clampf(zoom * exp((zi-zo)*delta),0.55,2.2)
  camera_cell = camera_cell.lerp(Vector2(cursor),minf(1.0,delta*5.0))
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
   _notify(state.latest_notice)
  if autosave_clock >= 120.0:
   autosave_clock = 0.0
   var error: String = SaveManager.save_game(state,true)
   if not error.is_empty(): _notify(error)
 queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventJoypadButton or event is InputEventJoypadMotion: last_device = "mando"
 if event is InputEventKey: last_device = "teclado"
 if screen != "game":
  if event.is_action_pressed("back_action"):
   get_viewport().set_input_as_handled()
   _back()
  return
 if event.is_action_pressed("move_up"): _move(Vector2i.UP)
 elif event.is_action_pressed("move_down"): _move(Vector2i.DOWN)
 elif event.is_action_pressed("move_left"): _move(Vector2i.LEFT)
 elif event.is_action_pressed("move_right"): _move(Vector2i.RIGHT)
 elif event.is_action_pressed("accept_action"): _accept_map()
 elif event.is_action_pressed("back_action"):
  if drawing:
   drawing = false
   proposal = {}
   _notify("Trazado cancelado")
  else: _delete_prompt()
 elif event.is_action_pressed("inspect_action"): _inspector()
 elif event.is_action_pressed("menu_action"): _game_menu()
 elif event.is_action_pressed("road_prev"): selected_type = posmod(selected_type - 1, 7); _refresh_proposal(); _road_type_notice()
 elif event.is_action_pressed("road_next"): selected_type = (selected_type + 1) % 7; _refresh_proposal(); _road_type_notice()
 elif event.is_action_pressed("pause_action"): simulation_speed = 1 if simulation_speed == 0 else 0
 elif event.is_action_pressed("tool_action"): _cycle_tool()
 else: return
 get_viewport().set_input_as_handled()

func _move(dir: Vector2i) -> void:
 cursor += dir
 selected_road = 0
 _refresh_proposal()

func _road_type_notice() -> void:
 var requirement: String = state.unlock_reason(selected_type)
 if not requirement.is_empty(): _notify("%s bloqueada. %s" % [Balance.ROADS[selected_type].name,requirement])
 else: _notify("Vía disponible: " + str(Balance.ROADS[selected_type].name))

func _refresh_proposal() -> void:
 if drawing:
  proposal = RoadPlanner.plan_via(state.world,start,waypoint,cursor) if has_waypoint else RoadPlanner.plan(state.world,start,cursor)
  if not proposal.has("error"):
   proposal = RoadPlanner.add_crossings(state.world,proposal,state.roads,elevated_crossings,selected_type)

func _accept_map() -> void:
 if tool != "Construir":
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
 var text: String = "%s · %.1f casillas\nBase: %.0f €  ·  Terreno: %.0f €\nPuente: %d casillas · %.0f €\nPasos elevados: %d · %.0f €\nTotal: %.0f €  ·  Obra: %.0f s\nSaldo disponible: %.0f €" % [Balance.ROADS[selected_type].name,proposal.length,float(proposal.length)*Balance.CELL_COST*float(Balance.ROADS[selected_type].cost),proposal.terrain_cost,proposal.water,float(proposal.water)*Balance.BRIDGE_COST,proposal.get("raised_indices",[]).size(),proposal.get("overpass_cost",0.0),cost,maxf(4.0,float(proposal.length)*0.7),state.money]
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
 _button("Demoler",func() -> void: state.roads.erase(road); state.route_cache.clear(); _close_panel(); _notify("Carretera demolida."))
 _button("Cancelar",func() -> void: _close_panel())
 _focus_first()

func _road_action() -> void:
 var roads: Array = _road_at(cursor)
 if roads.is_empty(): _notify("Selecciona una carretera."); return
 var road: Dictionary = roads[mini(selected_road,roads.size()-1)]
 if tool in ["Reparar","Mejorar"]:
  _work_menu(road, "repair" if tool == "Reparar" else "upgrade")
 else:
  _signal_menu(road)

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
  for direction: int in [-1,1]:
   var from_index: int = index-direction
   if from_index < 0 or from_index >= road.path.size(): continue
   var from: Array = road.path[from_index]
   _button("Entrada desde (%d,%d): STOP" % [from[0],from[1]],func() -> void: _set_signal(road,index,direction,"stop"))
   _button("Entrada desde (%d,%d): ceda" % [from[0],from[1]],func() -> void: _set_signal(road,index,direction,"yield"))
   _button("Entrada desde (%d,%d): sin señal" % [from[0],from[1]],func() -> void: _set_signal(road,index,direction,"none"))
 _button("Cancelar",func() -> void: _close_panel())
 _focus_first()

func _set_signal(road: Dictionary, index: int, direction: int, kind: String) -> void:
 if not road.has("signals"): road.signals = []
 var existing: Array = road.signals.duplicate()
 for signal_data: Dictionary in existing:
  if int(signal_data.index) == index and int(signal_data.direction) == direction: road.signals.erase(signal_data)
 if kind != "none": road.signals.append({"index":index,"direction":direction,"type":kind})
 _close_panel()
 _notify("Señal actualizada para la entrada seleccionada.")

func _cycle_tool() -> void:
 var tools: Array[String] = ["Construir","Señalar","Reparar","Mejorar"]
 tool = tools[(tools.find(tool)+1)%tools.size()]
 drawing = false
 _notify("Herramienta: " + tool)

func _make_panel(heading: String, description: String, next_screen: String) -> void:
 screen = next_screen
 for child: Node in overlay.get_children(): child.queue_free()
 panel = PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 panel.offset_left = -350
 panel.offset_right = 350
 panel.offset_top = -330
 panel.offset_bottom = 330
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.055,0.10,0.12,0.97)
 style.border_color = Color("c9d9bf")
 style.set_border_width_all(2)
 style.set_corner_radius_all(10)
 style.set_content_margin_all(24)
 panel.add_theme_stylebox_override("panel",style)
 overlay.add_child(panel)
 var scroll := ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 panel.add_child(scroll)
 column = VBoxContainer.new()
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation",8)
 scroll.add_child(column)
 title_label = Label.new()
 title_label.text = heading
 title_label.add_theme_font_size_override("font_size",30)
 column.add_child(title_label)
 if not description.is_empty(): _label(description)

func _label(value: String) -> void:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",18)
 column.add_child(label)

func _button(label: String, action: Callable) -> Button:
 var button := Button.new()
 button.text = label
 button.custom_minimum_size.y = 40
 button.add_theme_font_size_override("font_size",19)
 button.pressed.connect(action)
 column.add_child(button)
 return button

func _focus_first() -> void:
 for child: Node in column.get_children():
  if child is Button or child is LineEdit:
   child.call_deferred("grab_focus")
   return

func _show_title() -> void:
 var saves: Array = SaveManager.list_saves()
 _make_panel("Kilómetro a Kilómetro", "Traza caminos, conecta ciudades y cuida tu red.\nA / Intro: elegir     B / Esc: volver", "title")
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
 column.add_child(input_name)
 _label("Semilla (número)")
 input_seed = LineEdit.new()
 input_seed.text = str(randi_range(1,999999))
 input_seed.virtual_keyboard_enabled = true
 column.add_child(input_seed)
 var mode := OptionButton.new()
 mode.add_item("Partida guiada")
 mode.add_item("Modo libre")
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
  if child is Button: child.call_deferred("grab_focus"); break

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
 _make_panel("Opciones y controles", "Flechas / WASD: mover · Intro / Espacio: aceptar\nEsc / Supr: volver o demoler · I: inspector · M: menú\nQ / E: tipo de vía · Tab: herramienta · P: pausa\n− / +: zoom · Mando: cruceta, A/B/X/Y, LB/RB y gatillos", "options")
 _button("Cuadrícula: " + ("visible" if grid_visible else "oculta"),func() -> void: grid_visible = not grid_visible; _options())
 _button("Ventana / pantalla completa",func() -> void: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN))
 _button("Volver",func() -> void: _show_title())
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
 for t: String in ["Construir","Señalar","Reparar","Mejorar"]:
  _button(t,func() -> void: tool = t; drawing = false; _close_panel())
 if drawing:
  _button("Fijar punto intermedio aquí",func() -> void: waypoint = cursor; has_waypoint = true; _close_panel(); _refresh_proposal(); _notify("Punto intermedio fijado. Elige el destino."))
  if has_waypoint: _button("Quitar punto intermedio",func() -> void: has_waypoint = false; _close_panel(); _refresh_proposal())
 _button("Cruces: " + ("paso elevado" if elevated_crossings else "a nivel"),func() -> void: elevated_crossings = not elevated_crossings; _refresh_proposal(); _game_menu())
 _button("Velocidad: %s" % ("pausa" if simulation_speed == 0 else str(simulation_speed)+"×"),func() -> void: simulation_speed = {0:1,1:2,2:4,4:0}[simulation_speed]; _game_menu())
 _button("Vista: " + view_mode,func() -> void: view_mode = {"normal":"tráfico","tráfico":"conservación","conservación":"demanda","demanda":"normal"}[view_mode]; _game_menu())
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
 var text: String = "Demanda potencial: %.1f viajes\nIniciados: %d · completados: %d\nSin atender: %d · interrumpidos: %d\nViajes con retraso: %d\n\nPenalización acumulada por atasco: %.0f €\nPenalización acumulada por retrasos: %.0f €\nPenalizaciones de hoy: %.0f € · ayer: %.0f €\n\nAtasco: 2,5 €/s por cada 100%% de ocupación sobre la capacidad. Retraso: 4 €/s por encima de 1,6 segundos por casilla en línea recta (mínimo 3 s; máximo 80%% del ingreso)." % [state.potential_demand,state.started_trips,state.completed,state.unmet_demand,state.interrupted,state.late_trips,state.congestion_fines,state.delay_fines,state.today_penalties,state.yesterday_penalties]
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
 var desc: String = "Casilla (%d, %d) · %s" % [cursor.x,cursor.y,state.world.terrain(cursor)]
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
  desc += "\nTramo %d/%d · %s\nLongitud %.1f · conservación %.1f%%\nLímite %.0f km/h · viajes %d\n%s" % [selected_road+1,roads.size(),Balance.ROADS[int(road.type)].name,road.length,road.condition,road.speed_limit,road.trips,"Obras: %.1f s" % road.work if float(road.work)>0 else ("Cerrado" if RoadNetwork.road_closed(road) else "Abierto")]
  desc += "\nMantenimiento: %s · %.2f €/s" % ["activo" if road.get("maintenance",false) else "inactivo",maxf(0.1,float(road.length)*0.015)]
  if road.has("scheduled_work"):
   var job: Dictionary = road.scheduled_work
   desc += "\nObra %s · inicio en %.0f s" % [job.status,maxf(0.0,float(job.start_at)-state.elapsed)]
  var current_index: int = road.path.find([cursor.x,cursor.y])
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
 _make_panel("Inspector",desc,"inspector")
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
  "new", "load", "options", "about", "quit": _show_title()
  "return", "events", "traffic_summary", "economy": _game_menu()
  _: _close_panel()

func _close_panel() -> void:
 for child: Node in overlay.get_children(): child.queue_free()
 screen = "game"

func _notify(message: String) -> void:
 notice = message
 notice_time = 5.0

func _draw() -> void:
 var size: Vector2 = get_viewport_rect().size
 draw_rect(Rect2(Vector2.ZERO,size),Color("1d3332"))
 var world: WorldGenerator = state.world if state != null else background_world
 var center: Vector2 = camera_cell if state != null else Vector2(13,8)
 var cell: float = 24.0 * zoom if state != null else 24.0
 var offset: Vector2 = size * 0.5 - center * cell
 var minp := Vector2i(floori(-offset.x/cell)-1,floori(-offset.y/cell)-1)
 var maxp := Vector2i(ceili((size.x-offset.x)/cell)+1,ceili((size.y-offset.y)/cell)+1)
 var colors: Dictionary = {"pradera":Color("a8bf91"),"bosque":Color("708f70"),"colina":Color("b8aa82"),"roca":Color("888b80"),"agua":Color("6b9da8")}
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
  var junctions: Dictionary = _junctions()
  # Draw every shoulder before every surface so connected roads blend together.
  for road: Dictionary in state.roads: _draw_road_layer(road,offset,cell,true)
  for road: Dictionary in state.roads: _draw_road_layer(road,offset,cell,false)
  for road: Dictionary in state.roads: _draw_road_details(road,offset,cell,junctions)
  for road: Dictionary in state.roads: _draw_overpasses(road,offset,cell)
  if drawing and has_waypoint:
   draw_circle(offset+(Vector2(waypoint)+Vector2(0.5,0.5))*cell,maxf(5.0,cell*0.23),Color("f5df81"),false,2.0)
  if drawing and proposal.has("path"):
   var points: PackedVector2Array = RoadGeometry.polyline(proposal.path,offset,cell,8,_preview_anchors())
   if points.size() > 1: draw_polyline(points,Color("f5df81"),maxf(3.0,cell*0.22),true)
   for index: int in proposal.get("raised_indices",[]): draw_circle(offset+(Vector2(proposal.path[index])+Vector2(0.5,0.5))*cell,maxf(6.0,cell*0.35),Color("f9f1b4"),false,2.0)
 else:
  draw_line(offset+Vector2(2.5,4.5)*cell,offset+Vector2(10.5,5.5)*cell,Color("8a6241"),8.0,true)
  draw_line(offset+Vector2(10.5,5.5)*cell,offset+Vector2(27.5,7.5)*cell,Color("697478"),9.0,true)
 for city: Dictionary in cities:
  var pos: Vector2 = offset + Vector2(float(city.x)+0.5,float(city.y)+0.5)*cell
  if not Rect2(Vector2(-100,-100),size+Vector2(200,200)).has_point(pos): continue
  var radius: float = clampf(5.0+sqrt(float(city.population))/22.0,7.0,13.0)*zoom
  draw_circle(pos,radius,Color("30494a"))
  draw_rect(Rect2(pos-Vector2(radius*0.6,radius*0.65),Vector2(radius*1.2,radius*1.3)),Color("efe4c9"))
  draw_string(ThemeDB.fallback_font,pos+Vector2(0,-radius-5),"%s · %s · %d hab." % [city.name,WorldGenerator.city_size(int(city.population)),city.population],HORIZONTAL_ALIGNMENT_CENTER,-1,16,Color("1a2c2c"))
 if state != null:
  for vehicle: Dictionary in state.vehicles: _draw_vehicle(vehicle,offset,cell)
  var cpos: Vector2 = offset+Vector2(cursor)*cell
  draw_rect(Rect2(cpos,Vector2.ONE*cell),Color("fff1a5"),false,3.0)
  _draw_hud(size)

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
 return anchors

func _preview_anchors() -> Dictionary:
 var anchors: Dictionary = geometry_anchors.duplicate()
 for road: Dictionary in state.roads:
  for item: Array in road.path: anchors[Vector2i(int(item[0]),int(item[1]))] = true
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

func _draw_overpasses(road: Dictionary, offset: Vector2, cell: float) -> void:
 var path: Array = road.path
 for index_value: Variant in road.get("raised_indices",[]):
  var index: int = int(index_value)
  if index < 1 or index >= path.size()-1: continue
  var points := PackedVector2Array()
  for i: int in range(index-1,index+1):
   for j: int in range(6): points.append(offset+(RoadGeometry.point(path,i,float(j)/6.0,geometry_anchors)+Vector2(0.5,0.5))*cell)
  points.append(offset+(RoadGeometry._vector(path[index+1])+Vector2(0.5,0.5))*cell)
  var width: float = _road_width(road,cell)
  draw_polyline(points,Color(0.12,0.17,0.16,0.4),width+maxf(5.0,cell*0.22),true)
  draw_polyline(points,Color("ded4c0"),width+maxf(3.0,cell*0.12),true)
  draw_polyline(points,_road_color(road),width,true)

func _draw_vehicle(vehicle: Dictionary, offset: Vector2, cell: float) -> void:
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

func _draw_hud(size: Vector2) -> void:
 var font: Font = ThemeDB.fallback_font
 draw_rect(Rect2(0,0,size.x,48),Color(0.04,0.09,0.10,0.9))
 var hud: String = "%.0f €    Ingresos %.0f € · Gastos %.0f €    Penalización hoy %.0f €    Viajes %d    Día %d    %s" % [state.money,state.income,state.expenses,state.today_penalties,state.completed,1+int(state.elapsed/120.0),"Pausa" if simulation_speed == 0 else str(simulation_speed)+"×"]
 draw_string(font,Vector2(20,31),hud,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color.WHITE)
 draw_rect(Rect2(0,size.y-86,size.x,86),Color(0.04,0.09,0.10,0.94))
 var details: String = "%s · %s · (%d, %d) · %s" % [tool,Balance.ROADS[selected_type].name,cursor.x,cursor.y,state.world.terrain(cursor)]
 if drawing:
  if proposal.has("error"): details += " · " + str(proposal.error)
  elif proposal.has("length"): details += " · %.0f € · puente %d" % [state.price(proposal,selected_type),proposal.water]
 draw_string(font,Vector2(20,size.y-53),details,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("f5e6ad"))
 var help: String = "A marcar / confirmar   B cancelar / demoler   Y inspector   X menú   LB/RB vía   Start pausa" if last_device == "mando" else "Intro marcar / confirmar   Esc cancelar / demoler   I inspector   M menú   Q/E vía   P pausa   Tab herramienta"
 draw_string(font,Vector2(20,size.y-22),help,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
 if view_mode == "tráfico":
  draw_rect(Rect2(20,size.y-124,560,30),Color(0.04,0.09,0.10,0.9))
  draw_string(font,Vector2(30,size.y-103),"Tráfico: verde fluido · ámbar cargado · rojo saturado",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
 if notice_time > 0.0:
  draw_rect(Rect2(20,60,minf(size.x-40,900),38),Color(0.06,0.12,0.13,0.93))
  draw_string(font,Vector2(32,85),notice,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
