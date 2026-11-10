@tool
extends Marker2D
## Drag a marker in 2D; resize it with Dimensions in the Inspector.
## Runtime reads these nodes as data, while the Layout draws the editor preview.

@export_enum("rock", "gap", "platform", "guard", "charm", "decor", "hero_spawn", "elder", "boss_spawn", "spikes", "camp", "checkpoint", "secret", "passage", "lake", "scenic_lake", "supply") var kind: String = "decor":
 set(value):
  kind = value
  _changed()
@export var dimensions := Vector2(80, 60):
 set(value):
  dimensions = Vector2(maxf(1, absf(value.x)), maxf(1, absf(value.y)))
  _changed()
@export_enum("tree", "grass_tuft", "reeds", "yurt", "crate", "banner", "dead_tree", "tumbleweed", "steppe_bloom", "rock") var prop_name: String = "tree":
 set(value):
  prop_name = value
  _changed()
@export var ground_locked := true:
 set(value):
  ground_locked = value
  _changed()
@export_range(0.0, 300.0, 1.0) var clearance := 22.0:
 set(value):
  clearance = value
  _changed()

@export_range(0,220,1) var ravine_depth := 0.0
@export_range(1,8) var enemy_count := 2
@export var archer_first := false
@export var exit_offset:=0.0
@export_group("Secret cave")
@export_range(280,500,10) var cave_first_guard_x := 460.0
@export_range(350,470,10) var cave_guard_spacing := 440.0
@export_group("Platform attachment")
@export var platform_index := -1
@export var platform_offset := 0.0
@export_node_path("Marker2D") var trial_platform: NodePath
@export var ground_trial := false

func _ready() -> void:
 if Engine.is_editor_hint():
  set_notify_transform(true)
  set_notify_local_transform(true)
  _changed()

func _notification(what: int) -> void:
 if Engine.is_editor_hint() and what in [NOTIFICATION_TRANSFORM_CHANGED, NOTIFICATION_LOCAL_TRANSFORM_CHANGED]:
  _changed()

func _changed() -> void:
 if not Engine.is_editor_hint() or not is_inside_tree():
  return
 queue_redraw()
 update_configuration_warnings()
 var ancestor := get_parent()
 while ancestor != null:
  if ancestor.has_method("refresh_preview"):
   ancestor.refresh_preview()
   return
  ancestor = ancestor.get_parent()

func _get_configuration_warnings() -> PackedStringArray:
 var warnings := PackedStringArray()
 if scale != Vector2.ONE or not is_zero_approx(rotation):
  warnings.append("Не меняй Scale/Rotation: размер задаётся через Dimensions, положение — Position.")
 if kind in ["rock", "gap", "spikes", "guard", "hero_spawn", "elder", "boss_spawn"] and not is_equal_approx(position.y, 550):
  warnings.append("Этот объект привязан к земле Y = 550. В игре используется эта высота; меняй только X.")
 return warnings
