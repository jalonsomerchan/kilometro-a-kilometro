class_name SettingsStore
extends RefCounted

static func read_settings(path: String = "user://settings.cfg") -> Dictionary:
 var defaults: Dictionary = {"grid":true,"fullscreen":false,"ui_scale":1.0,"keys":{}}
 var config := ConfigFile.new()
 if config.load(path) != OK: return defaults
 defaults.grid = bool(config.get_value("display","grid",true))
 defaults.fullscreen = bool(config.get_value("display","fullscreen",false))
 defaults.ui_scale = clampf(float(config.get_value("display","ui_scale",1.0)),1.0,1.4)
 var keys: Variant = config.get_value("controls","keys",{})
 if keys is Dictionary: defaults.keys = keys
 return defaults

static func write_settings(settings: Dictionary, path: String = "user://settings.cfg") -> Error:
 var config := ConfigFile.new()
 config.set_value("display","grid",bool(settings.grid))
 config.set_value("display","fullscreen",bool(settings.fullscreen))
 config.set_value("display","ui_scale",float(settings.ui_scale))
 config.set_value("controls","keys",settings.keys)
 return config.save(path)
