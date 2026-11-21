class_name CursorMotion
extends RefCounted

# Map navigation is discrete and uses the same repeat for keyboard, D-pad and
# stick. OS key-repeat and joystick motion event rates never control the speed.
const START_DELAY: float = 0.42
const STICK_ENGAGE: float = 0.55
const STICK_RELEASE: float = 0.35
const AXIS_SWITCH_MARGIN: float = 0.18
const DIRECTIONS: Dictionary = {"move_up":Vector2i.UP,"move_down":Vector2i.DOWN,"move_left":Vector2i.LEFT,"move_right":Vector2i.RIGHT}

var held: Dictionary = {}
var sequence: int = 0
var pending_taps: Array[Vector2i] = []
var stick: Vector2 = Vector2.ZERO
var stick_device: int = -1
var stick_direction: Vector2i = Vector2i.ZERO
var stick_gesture: Vector2i = Vector2i.ZERO
var stick_delivered: bool = false
var current: Vector2i = Vector2i.ZERO
var repeat_left: float = 0.0
var repeat_interval: float = 0.18
var accelerate: bool = false
var held_time: float = 0.0

func reset() -> void:
 held.clear()
 pending_taps.clear()
 stick = Vector2.ZERO
 stick_device = -1
 stick_direction = Vector2i.ZERO
 stick_gesture = Vector2i.ZERO
 stick_delivered = false
 current = Vector2i.ZERO
 repeat_left = 0.0
 held_time = 0.0

func set_speed(mode: String) -> void:
 match mode:
  "lento": repeat_interval = 0.26
  "rapido": repeat_interval = 0.12
  _: repeat_interval = 0.18

func handle_event(event: InputEvent) -> bool:
 if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]:
  if stick_device != event.device:
   stick = Vector2.ZERO
   stick_direction = Vector2i.ZERO
   stick_gesture = Vector2i.ZERO
   stick_delivered = false
   stick_device = event.device
  if event.axis == JOY_AXIS_LEFT_X: stick.x = event.axis_value
  else: stick.y = event.axis_value
  var direction: Vector2i = _desired_stick_direction()
  if direction != Vector2i.ZERO and stick_gesture == Vector2i.ZERO:
   stick_gesture = direction
  elif direction == Vector2i.ZERO and stick_gesture != Vector2i.ZERO:
   if not stick_delivered and pending_taps.size() < 4: pending_taps.append(stick_gesture)
   stick_gesture = Vector2i.ZERO
   stick_delivered = false
  return true
 if not event is InputEventKey and not event is InputEventJoypadButton: return false
 if event is InputEventKey and event.echo: return _is_movement(event)
 var source: String = ""
 if event is InputEventKey:
  var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
  source = "key:%d:%d" % [event.device,code]
 else: source = "pad:%d:%d" % [event.device,event.button_index]
 for action: String in DIRECTIONS:
  if event.is_action_pressed(action):
   if not held.has(source):
    sequence += 1
    held[source] = {"direction":DIRECTIONS[action],"sequence":sequence,"delivered":false}
   return true
  if event.is_action_released(action):
   if held.has(source) and not bool(held[source].delivered):
    # Preserve a very quick tap even if press and release arrive in one frame.
    if pending_taps.size() < 4: pending_taps.append(held[source].direction)
   held.erase(source)
   return true
 return false

func _is_movement(event: InputEvent) -> bool:
 for action: String in DIRECTIONS:
  if event.is_action(action): return true
 return false

func advance(delta: float) -> Vector2i:
 if not pending_taps.is_empty():
  current = Vector2i.ZERO
  repeat_left = 0.0
  return pending_taps.pop_front()
 var desired: Vector2i = _desired_direction()
 if desired != Vector2i.ZERO and held.is_empty(): stick_delivered = true
 if desired == Vector2i.ZERO:
  current = Vector2i.ZERO
  repeat_left = 0.0
  return Vector2i.ZERO
 if desired != current:
  current = desired
  held_time = 0.0
  repeat_left = START_DELAY
  return desired
 held_time += maxf(0.0,delta)
 repeat_left -= maxf(0.0,delta)
 if repeat_left > 0.0: return Vector2i.ZERO
 # Never replay a backlog of moves after a long frame or when returning to game.
 repeat_left = repeat_interval * lerpf(1.0,0.35,clampf((held_time-START_DELAY)/2.0,0.0,1.0)) if accelerate else repeat_interval
 return desired

func _desired_direction() -> Vector2i:
 if not held.is_empty():
  var best: int = -1
  var best_source: String = ""
  var result := Vector2i.ZERO
  for source: String in held:
   var item: Dictionary = held[source]
   if int(item.sequence) > best:
    best = int(item.sequence)
    best_source = source
    result = item.direction
  if not best_source.is_empty(): held[best_source].delivered = true
  return result
 return _desired_stick_direction()

func _desired_stick_direction() -> Vector2i:
 var x: float = absf(stick.x)
 var y: float = absf(stick.y)
 # Keep the active axis when both are close, avoiding an unwanted extra step
 # caused by joystick noise during an otherwise horizontal or vertical move.
 if stick_direction.x != 0 and x >= STICK_RELEASE and y < x+AXIS_SWITCH_MARGIN:
  if signf(stick.x) == float(stick_direction.x): return stick_direction
 if stick_direction.y != 0 and y >= STICK_RELEASE and x < y+AXIS_SWITCH_MARGIN:
  if signf(stick.y) == float(stick_direction.y): return stick_direction
 if maxf(x,y) < STICK_ENGAGE:
  stick_direction = Vector2i.ZERO
 elif x >= y:
  stick_direction = Vector2i.RIGHT if stick.x > 0.0 else Vector2i.LEFT
 else:
  stick_direction = Vector2i.DOWN if stick.y > 0.0 else Vector2i.UP
 return stick_direction
