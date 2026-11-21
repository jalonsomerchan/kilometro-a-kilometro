class_name SaveManager
extends RefCounted

static func save_game(state: GameState, automatic: bool = false) -> String:
 var dir := DirAccess.open("user://")
 if dir == null: return "No se puede abrir la carpeta de guardado."
 dir.make_dir_recursive("saves")
 var base: String = state.game_name.validate_filename()
 if base.is_empty(): base = "partida"
 var suffix: String = "_auto%d" % (int(state.elapsed / 120.0) % 3) if automatic else "_manual"
 var path: String = "user://saves/" + base + suffix + ".json"
 var tmp: String = path + ".tmp"
 var f := FileAccess.open(tmp, FileAccess.WRITE)
 if f == null: return "No se pudo escribir el guardado."
 var d: Dictionary = state.data()
 d["automatic"] = automatic
 f.store_string(JSON.stringify(d))
 f.flush()
 var err: Error = f.get_error()
 f.close()
 if err != OK: return "Error al escribir el guardado."
 # Rename the old file only after the temporary file has been written.
 var absolute: String = ProjectSettings.globalize_path(path)
 var backup: String = absolute + ".bak"
 if FileAccess.file_exists(path):
  if FileAccess.file_exists(backup): DirAccess.remove_absolute(backup)
  if DirAccess.rename_absolute(absolute, backup) != OK: return "No se pudo conservar el guardado anterior."
 if DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), absolute) != OK:
  if FileAccess.file_exists(backup): DirAccess.rename_absolute(backup, absolute)
  return "No se pudo finalizar el guardado."
 return ""

static func list_saves() -> Array:
 var result: Array = []
 var dir := DirAccess.open("user://saves")
 if dir == null: return result
 dir.list_dir_begin()
 var file: String = dir.get_next()
 while not file.is_empty():
  if file.ends_with(".json"):
   var path: String = "user://saves/" + file
   var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
   if d is Dictionary and d.has("version") and int(d.version) == 1 and d.has("cities") and d.has("roads") and d.has("vehicles"):
    result.append({"path":path,"data":d,"valid":true})
   else: result.append({"path":path,"valid":false,"file":file})
  file = dir.get_next()
 dir.list_dir_end()
 result.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return FileAccess.get_modified_time(a.path) > FileAccess.get_modified_time(b.path))
 return result
