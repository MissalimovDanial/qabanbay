extends Node2D

const Chapters = preload("res://scripts/chapter_data.gd")
@export_range(1, 5) var chapter_number: int = 1
var stage: Dictionary = {}
var route_rocks: Array = []
var route_charms: Array = []
var route_supplies: Array = []
var collected_supplies: Dictionary = {}
const WindTrial = preload("res://scripts/wind_trial.gd")
var wind_trial := WindTrial.new()
var boss_max_hp := 5
var heal_timer := 0.0
var footstep_timer := 0.0
var boss_chain := 0
var boss_attack_start := 0.0
var boss_attack_target := 0.0
var boss_combo_left := 0
var route_platforms: Array = []
var route_gaps: Array = []
var grounded := true
var landing_timer := 0.0
var swing_hits: Dictionary = {}
var attack_buffer := 0.0
var npc_passed := false
var npc_bubble: PanelContainer
var npc_text: Label
var attack_count := 0
var training_stage := 0
var lesson_open := false
var lesson_target := "right"
var lesson_arrow: Line2D
var lesson_hint:Label
var run_distance := 0.0

const Art = preload("res://scripts/level_art.gd")
const Sound = preload("res://scripts/audio.gd")
const AttackButton = preload("res://scripts/ui/attack_button.gd")
const ChapterPresentation = preload("res://scripts/chapter_presentation.gd")
const MAX_HP := 6
const FLOOR_Y := 550.0
var WORLD_END := 72000.0
var ARENA_START := 70000.0
const SPEED := 185.0
const RUN_SPEED := 265.0
const MAX_STAMINA := 100.0
const STAMINA_SEGMENT := MAX_STAMINA / 5.0
const STAMINA_DRAIN := STAMINA_SEGMENT / 5.0
const STAMINA_RECOVERY := STAMINA_SEGMENT / 3.0
const STAMINA_RESUME := STAMINA_SEGMENT
var stamina := MAX_STAMINA
var exhausted := false
var stride_moving := false
var camera_y := 0.0
var super_hits := 0
const SUPER_HITS_REQUIRED := 11
var horse_event := -1.0
var horse_fled := false
var victory_timer := -1.0
var victory_line := ""
var route_depths: Array = []
var checkpoint_x := 180.0
var checkpoint_y := 550.0
var exploration:Node2D
const GRAVITY := 1700.0
const BOAR_MAX_HP := 5
const SAVE_PATH := Chapters.SAVE_PATH
enum Phase { TITLE, INTRO, EXPLORE, ENCOUNTER, FIGHT, OUTRO, WON, LOST, CINEMATIC }

const INTRO := [
 ["Зайсан · начало XVIII века", "Ерасыл колет дрова у юрты. С пастбища к нему бежит пастух."],
 ["Пастух", "Ерасыл! Кабан напал на табун у реки. Лошади в опасности! Помоги нам!"],
 ["Ерасыл", "Уведите людей в аул. Я возьму копьё и найду табун."]
]
const OUTRO := [
 ["Табун спасён", "Опасность миновала. Лошади возвращаются к пастуху, а Ерасыл опускает копьё."],
 ["Пастух", "Ты не отступил, Ерасыл. Сегодня ты защитил наш аул. Мы запомним твою смелость."],
 ["Первое испытание", "Так начинается путь будущего Кабанбай батыра. Впереди — дорога к Аягозу. Но это уже следующая глава."]
]
const ROCKS := [Rect2(980, FLOOR_Y - 45, 90, 45), Rect2(1930, FLOOR_Y - 60, 100, 60), Rect2(2760, FLOOR_Y - 50, 110, 50)]
const HERBS := [4140.0, 5080.0]
const CHARMS := [Vector2(720, 495), Vector2(1025, 400), Vector2(1720, 495), Vector2(1980, 390), Vector2(2815, 400), Vector2(3440, 495)]

var phase := Phase.TITLE
var hero := Vector2(180, FLOOR_Y)
var vertical_speed := 0.0
var facing := 1.0
var hp := MAX_HP
var boar := Vector2(4680, FLOOR_Y)
var boar_hp := BOAR_MAX_HP
var boar_state := "approach"
var boar_timer := 0.0
var charge_direction := -1.0
var boar_facing := -1.0
var attack_timer := 0.0
var attack_cooldown := 0.0
var super_timer := 0.0
const SUPER_EFFECT_TIME := 0.48
const SUPER_DAMAGE := 5
var empowered := false
var super_used := false
const SUPER_RECOVERY := 4.0
var attack_landed := false
var dodge_timer := 0.0
var dodge_cooldown := 0.0
var invulnerable := 0.0
var camera_x := 0.0
var clock := 0.0
var elapsed := 0.0
var run_clock := 0.0
var hit_flash := 0.0
var shake := 0.0
var paused := false
var muted := false
var touch_actions: Dictionary = {}
var screen_touches: Dictionary = {}
var keys: Dictionary = {}
var previous: Dictionary = {}
var dialog_index := 0
var collected: Dictionary = {}
var herbs := [false, false]
var dive_previous_y:=0.0
var elder_started_at:=-1.0
var air_kick:=false
var dummy_hp := 3
var checkpoint := false
var completed := false
var best_time := 0.0
var deaths := 0
var damage_taken := 0
var tutorial := {"move": false, "jump": false, "attack": false, "run": false}
var banner_text := ""
var banner_timer := 0.0
var particles: Array[Dictionary] = []
var qa_enabled := false
var art = Art.new()
const CharacterFrames = preload("res://scripts/character_frames.gd")
var character_frames := CharacterFrames.new()
var defeated_at := 0.0
var death_at:=-1.0
var audio: Node
var ui: CanvasLayer
var hud: Label
var player_hud: Control
var loot_label: Label
var objective: Label
var hint: Label
var boss_label: Label
var banner: Label
var panel: PanelContainer
var heading: Label
var body: RichTextLabel
var primary: Button
var secondary: Button
var pause_button: Button
var sound_button: Button
var controls: Control
var action_buttons: Dictionary = {}
var chapter_screen: Control

func _ready() -> void:
 qa_enabled = OS.has_feature("web") and OS.get_cmdline_user_args().has("--qa")
 stage = Chapters.stage(chapter_number)
 character_frames.hero_age=chapter_number
 # Authored scene nodes are the source of truth when an editable Layout exists.
 # Script-only fixtures and older scenes keep the original chapter defaults.
 var layout := get_node_or_null("Layout")
 if layout != null and layout.has_method("data"):
  stage.merge(layout.data(), true)
 WORLD_END = float(stage.get("world_end",WORLD_END))
 ARENA_START = float(stage.get("arena_start",ARENA_START))
 route_depths = stage.get("ravines",[])
 route_rocks = stage.get("rocks", ROCKS).duplicate()
 route_platforms = stage.platforms.duplicate()
 route_gaps = stage.gaps.duplicate()
 route_charms = CHARMS.duplicate()
 if chapter_number > 1:
  route_charms = [Vector2(550,495), Vector2(850,380), Vector2(1650,495), Vector2(2300,380), Vector2(2850,380), Vector2(3650,495)]
 route_charms = stage.get("charms", route_charms).duplicate()
 route_supplies = stage.get("supplies", [])
 wind_trial.configure(stage.get("wind_trial", {}))
 for i in range(route_charms.size()):
  route_charms[i] = preload("res://scripts/landform.gd").collectible_position(route_charms[i], route_platforms, route_depths)
 for name in ["yurt","dead_tree","grass_tuft","rock","heart","empty_heart","practice_dummy","secret_door","golden_man","kumys"]:
  art._asset(name)
 var hero_bank := CharacterFrames.hero_bank(chapter_number)
 for kind in [hero_bank,"elder","boar","horse"]:
  if not character_frames.action_banks.has(kind):character_frames.action_banks[kind]=load("res://art/animation/actions/"+kind+".res")
 art._surface_strip(null,0,WORLD_END,FLOOR_Y,route_depths)
 boss_max_hp = stage.hp
 boar_hp = boss_max_hp
 if not _chapter_unlocked():
  get_tree().call_deferred("change_scene_to_file", "res://scenes/campaign_map.tscn")
  return
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 audio = Sound.new()
 audio.chapter=chapter_number
 add_child(audio)
 audio.set_chapter(chapter_number)
 _load_progress()
 _build_ui()
 ui.layer=10
 var overlay:=CanvasLayer.new()
 overlay.layer=5
 add_child(overlay)
 exploration=load("res://scripts/exploration.gd").new()
 exploration.setup(self)
 overlay.add_child(exploration)
 _title()

func _chapter_unlocked() -> bool:
 return true

func _return_title() -> void:
 _open_campaign_map()

func _open_campaign_map() -> void:
 paused = false
 _clear_input()
 if ResourceLoader.exists("res://scenes/campaign_map.tscn"):
  get_tree().change_scene_to_file("res://scenes/campaign_map.tscn")
 else:
  _title()

func _load_progress() -> void:
 Chapters.import_first_trial()
 var save := ConfigFile.new()
 if save.load(SAVE_PATH) == OK:
  completed = save.get_value("level%d" % chapter_number, "completed", false)
  best_time = save.get_value("level%d" % chapter_number, "best_time", 0.0)
  muted = save.get_value("settings", "muted", false)
 audio.enabled = not muted

func _save_progress() -> void:
 var save := ConfigFile.new()
 save.load(SAVE_PATH)
 save.set_value("level%d" % chapter_number, "completed", completed)
 save.set_value("level%d" % chapter_number, "best_time", best_time)
 save.set_value("settings", "muted", muted)
 if save.save(SAVE_PATH) != OK:
  _notice("Не удалось сохранить прогресс. Играть можно продолжить.")

func _title() -> void:
 phase = Phase.TITLE
 _clear_input()
 panel.hide()
 chapter_screen.configure(chapter_number, stage, completed, _time(best_time))
 chapter_screen.show()
 chapter_screen.map_button.visible=ResourceLoader.exists("res://scenes/campaign_map.tscn")
 _refresh_ui()

func _label(size: int, color := Color("f4e6bf")) -> Label:
 var label := Label.new()
 label.add_theme_font_size_override("font_size", size)
 label.add_theme_color_override("font_color", color)
 label.add_theme_color_override("font_shadow_color", Color("11232b"))
 label.add_theme_constant_override("shadow_offset_x", 2)
 label.add_theme_constant_override("shadow_offset_y", 2)
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return label

func _style(color: Color, border: Color) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = color
 style.border_color = border
 style.set_border_width_all(3)
 style.set_corner_radius_all(4)
 style.content_margin_left = 24
 style.content_margin_right = 24
 style.content_margin_top = 16
 style.content_margin_bottom = 16
 return style

func _button(text: String) -> Button:
 var button := Button.new()
 button.text = text
 button.focus_mode = Control.FOCUS_NONE
 button.add_theme_font_size_override("font_size", 22)
 button.add_theme_color_override("font_color", Color("f4e6bf"))
 button.add_theme_stylebox_override("normal", _style(Color("133d48"), Color("c79c53")))
 button.add_theme_stylebox_override("pressed", _style(Color("93682e"), Color("ffdda0")))
 button.add_theme_stylebox_override("hover", _style(Color("28616a"), Color("ffdda0")))
 return button

func _build_ui() -> void:
 ui = CanvasLayer.new()
 add_child(ui)
 var root := Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 ui.add_child(root)
 player_hud = preload("res://scripts/ui/player_hud.gd").new()
 player_hud.name = "PlayerHUD"
 player_hud.position = Vector2(18, 16)
 player_hud.size = Vector2(285, 91)
 player_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(player_hud)
 var hero_bank := CharacterFrames.hero_bank(chapter_number)
 player_hud.configure(character_frames.action_banks[hero_bank], chapter_number, art.icon("heart"), art.icon("empty_heart"))
 hud = _label(22)
 hud.position = Vector2(25, 18)
 root.add_child(hud)
 loot_label = _label(22)
 loot_label.position = Vector2(350, 18)
 root.add_child(loot_label)
 objective = _label(23)
 objective.position = Vector2(25, 58)
 root.add_child(objective)
 hint = _label(18, Color("f5d793"))
 hint.position = Vector2(25, 96)
 root.add_child(hint)
 boss_label = _label(20, Color("ffcc96"))
 boss_label.position = Vector2(690, 22)
 root.add_child(boss_label)
 banner = _label(24, Color("ffe8a1"))
 banner.position = Vector2(300, 35)
 banner.size = Vector2(680, 60)
 banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 root.add_child(banner)
 pause_button = _button("II")
 pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 pause_button.position = Vector2(-84, 18)
 pause_button.size = Vector2(60, 55)
 pause_button.pressed.connect(_toggle_pause)
 root.add_child(pause_button)
 sound_button = _button("M")
 sound_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 sound_button.position = Vector2(-194, 18)
 sound_button.size = Vector2(100, 55)
 sound_button.pressed.connect(_toggle_sound)
 root.add_child(sound_button)
 controls = Control.new()
 controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(controls)
 _add_action("left", Vector2(30, -115), false)
 _add_action("right", Vector2(144, -115), false)
 _add_action("power", Vector2(-476, -115), true)
 _add_action("jump", Vector2(-368, -115), true)
 _add_action("run", Vector2(-250, -115), true)
 _add_action("attack", Vector2(-132, -115), true)
 panel = PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 panel.position = Vector2(-380, -265)
 panel.size = Vector2(760, 530)
 panel.add_theme_stylebox_override("panel", _style(Color("102c38f5"), Color("c79c53")))
 root.add_child(panel)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 14)
 panel.add_child(column)
 heading = _label(38,Color("f3c871"))
 heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 column.add_child(heading)
 body = RichTextLabel.new()
 body.bbcode_enabled = true
 body.fit_content = true
 body.scroll_active = false
 body.mouse_filter = Control.MOUSE_FILTER_IGNORE
 body.add_theme_font_size_override("normal_font_size",23)
 body.add_theme_font_size_override("bold_font_size",25)
 body.add_theme_font_size_override("italics_font_size",23)
 body.add_theme_constant_override("line_separation",5)
 body.add_theme_color_override("default_color",Color("f4e6bf"))
 body.custom_minimum_size = Vector2(700, 275)
 body.size_flags_vertical = Control.SIZE_EXPAND_FILL
 column.add_child(body)
 primary = _button("Начать")
 primary.custom_minimum_size.y = 58
 primary.pressed.connect(_advance)
 column.add_child(primary)
 secondary = _button("Пропустить вступление")
 secondary.custom_minimum_size.y = 48
 secondary.pressed.connect(_secondary)
 column.add_child(secondary)
 npc_bubble = PanelContainer.new()
 npc_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
 npc_bubble.size = Vector2(360, 112)
 npc_bubble.add_theme_stylebox_override("panel", _style(Color("132d35f5"), Color("dfbb76")))
 root.add_child(npc_bubble)
 npc_text = _label(19)
 npc_text.custom_minimum_size = Vector2(310, 75)
 npc_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 npc_bubble.add_child(npc_text)
 lesson_arrow = Line2D.new()
 lesson_arrow.width = 6
 lesson_arrow.default_color = Color("ffe394")
 ui.add_child(lesson_arrow)
 lesson_hint=_label(17,Color("ffdf9c"))
 lesson_hint.size=Vector2(220,54)
 lesson_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 lesson_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 ui.add_child(lesson_hint)
 chapter_screen = ChapterPresentation.new()
 chapter_screen.hide()
 root.add_child(chapter_screen)
 root.move_child(sound_button, root.get_child_count() - 1)
 chapter_screen.start_requested.connect(_advance)
 chapter_screen.map_requested.connect(_open_campaign_map)

func _add_action(action: String, offset: Vector2, right_side: bool) -> void:
 var button: Button = AttackButton.new()
 button.action = action
 if action=="power":
  button.super_symbol = true
 button.focus_mode = Control.FOCUS_NONE
 button.expand_icon = true
 button.add_theme_constant_override("icon_max_width", 88)
 for state in ["normal", "hover", "pressed", "focus"]:
  button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
 button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT if right_side else Control.PRESET_BOTTOM_LEFT)
 button.position = offset
 button.size = Vector2(100, 100)
 button.button_down.connect(func():
  touch_actions[action] = true
  _queue_attack(action))
 button.button_up.connect(func(): touch_actions[action] = false)
 controls.add_child(button)
 action_buttons[action] = button

func _show_panel(title: String, text: String, action: String) -> void:
 var story := phase in [Phase.INTRO,Phase.OUTRO] or (chapter_number in [3,5] and phase==Phase.ENCOUNTER)
 body.custom_minimum_size = Vector2(950,70) if story else Vector2(700,275)
 panel.offset_left = -550 if story else -380
 panel.offset_right = 550 if story else 380
 panel.offset_top = 34 if story else -265
 panel.offset_bottom = 342 if story else 265
 heading.add_theme_font_size_override("font_size",26 if story else 38)
 _clear_input()
 if is_instance_valid(chapter_screen):
  chapter_screen.hide()
 heading.text = title
 body.text = _story_markup(text)
 primary.text = action
 panel.show()
 secondary.visible = phase in [Phase.INTRO, Phase.WON, Phase.LOST] or paused
 secondary.text = "Карта пути" if phase in [Phase.WON,Phase.LOST] or paused else "Пропустить вступление"

func _advance() -> void:
 if lesson_open:
  lesson_open = false
  lesson_arrow.hide()
  panel.hide()
  _clear_input()
  _refresh_ui()
  return
 if paused:
  _toggle_pause()
 elif phase == Phase.TITLE:
  _restart(false)
  phase = Phase.INTRO
  dialog_index = 0
  _show_dialog(INTRO)
 elif phase == Phase.INTRO:
  dialog_index += 1
  if dialog_index < INTRO.size():
   _show_dialog(INTRO)
  else:
   phase = Phase.EXPLORE
   panel.hide()
   banner_timer = 0
 elif phase == Phase.ENCOUNTER:
  phase = Phase.FIGHT
  boar_state = "approach"
  panel.hide()
 elif phase == Phase.OUTRO:
  dialog_index += 1
  if dialog_index < OUTRO.size():
   _show_dialog(OUTRO)
  else:
   phase = Phase.WON
   _show_results()
 elif phase == Phase.WON:
  _open_campaign_map()
 elif phase == Phase.LOST:
  _retry()
 _refresh_ui()

func _secondary() -> void:
 if phase == Phase.INTRO:
  phase = Phase.EXPLORE
  panel.hide()
  _clear_input()
 elif phase == Phase.WON:
  _return_title()
 else:
  _return_title()
  return
 _refresh_ui()

func _retry() -> void:
 if checkpoint:
  _restart(true)
 else:
  var kept_loot := collected.duplicate()
  var kept_deaths := deaths
  var kept_elapsed := elapsed
  _restart(false)
  collected = kept_loot
  deaths = kept_deaths
  elapsed = kept_elapsed

func _show_dialog(lines: Array) -> void:
 _show_panel(lines[dialog_index][0], lines[dialog_index][1], "В путь" if phase == Phase.INTRO and dialog_index == 2 else "Далее")

func _restart(at_encounter: bool) -> void:
 wind_trial.reset(at_encounter)
 _reset_stamina()
 death_at=-1.0
 victory_timer=-1.0
 horse_event=-1.0
 horse_fled=false
 super_hits=0
 position.y=0
 camera_y=0
 chapter_screen.hide()
 hero = Vector2(checkpoint_x, checkpoint_y) if at_encounter else stage.get("hero_spawn", Vector2(180, FLOOR_Y))
 boar = stage.get("boss_spawn", Vector2(4680, FLOOR_Y))
 hp = MAX_HP
 grounded = true
 landing_timer = 0
 swing_hits.clear()
 attack_buffer = 0
 heal_timer = 0
 footstep_timer = 0
 boss_chain = 0
 boss_combo_left = 0
 boss_attack_start = boar.x
 boss_attack_target = boar.x
 boar_facing = -1
 charge_direction = -1
 boar_hp = boss_max_hp
 boar_state = "approach"
 boar_timer = 0
 vertical_speed = 0
 facing = 1
 attack_timer = 0
 air_kick=false
 elder_started_at=-1.0
 super_timer = 0
 empowered = false
 super_used = false
 dodge_timer = 0
 dodge_cooldown = 0
 invulnerable = 0
 shake = 0
 hit_flash = 0
 if not at_encounter:
  npc_passed = false
  training_stage = 0
  run_distance = 0
  lesson_open = false
  route_platforms = stage.platforms.duplicate()
  attack_count = 0
  collected.clear()
  collected_supplies.clear()
  herbs = [false, false]
  dummy_hp = 3
  checkpoint = false
  checkpoint_x=180
  checkpoint_y=FLOOR_Y
  elapsed = 0
  deaths = 0
  damage_taken = 0
  tutorial = {"move": false, "jump": false, "attack": false, "run": false}
 particles.clear()
 if is_instance_valid(exploration) and not at_encounter:
  exploration.reset()
 phase = Phase.FIGHT if at_encounter and checkpoint_x>=ARENA_START else Phase.EXPLORE
 if at_encounter:
  horse_fled=checkpoint_x>=ARENA_START
  horse_event=6.0 if horse_fled else -1.0
 paused = false
 _clear_input()
 panel.hide()
 camera_x = clampf(hero.x - 430, 0, WORLD_END - 1280)
 _refresh_ui()

func _clear_input() -> void:
 touch_actions.clear()
 screen_touches.clear()
 keys.clear()
 previous.clear()
 attack_buffer = 0.0

func _toggle_pause() -> void:
 if lesson_open:
  return
 if phase not in [Phase.EXPLORE, Phase.FIGHT]:
  return
 paused = not paused
 _clear_input()
 if paused:
  _show_panel("Привал", "Шаг: A / D · Бег: K + направление или стрелки · Суперудар: L\nПрыжок: пробел\nУдар копьём: J / G · Бег: удерживать K\nПауза: Esc · Звук: M\n\nПерепрыгни атаку кабана.\nУдарь сбоку, пока он отдыхает.", "Продолжить")
 else:
  panel.hide()
 _refresh_ui()

func _toggle_sound() -> void:
 muted = not muted
 audio.enabled = not muted
 _save_progress()
 _refresh_ui()

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(panel) and not paused:
  _toggle_pause()

func _input(event: InputEvent) -> void:
 if event is InputEventScreenTouch or event is InputEventScreenDrag:
  screen_touches.erase(event.index)
  if not (event is InputEventScreenTouch and not event.pressed) and controls.visible:
   for action in action_buttons:
    if action_buttons[action].get_global_rect().has_point(event.position):
     screen_touches[event.index] = action
     if event is InputEventScreenTouch:
      _queue_attack(action)
     break
 if event is InputEventKey:
  var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
  if event.echo:
   return
  if event.pressed:
   if code == KEY_ESCAPE:
    _toggle_pause()
   elif code == KEY_M:
    _toggle_sound()
   elif code == KEY_ENTER and (panel.visible or phase == Phase.TITLE):
    _advance()
  if code in [KEY_A, KEY_LEFT, KEY_D, KEY_RIGHT, KEY_SPACE, KEY_J, KEY_G, KEY_K, KEY_L]:
   keys[code] = event.pressed
   if event.pressed and code in [KEY_J,KEY_G]:
    _queue_attack("attack")

func _queue_attack(action: String) -> void:
 if action=="attack" and _control_unlocked(action) and not paused and not lesson_open and phase in [Phase.EXPLORE,Phase.FIGHT]:
  attack_buffer = 0.34

func _held(action: String) -> bool:
 if not _control_unlocked(action):
  return false
 if screen_touches.values().has(action) or touch_actions.get(action, false):
  return true
 var bindings := {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE], "attack": [KEY_J, KEY_G], "run": [KEY_K], "power": [KEY_L]}
 for key in bindings[action]:
  if keys.get(key, false):
   return true
 return false

func _reset_stamina() -> void:
 stamina = MAX_STAMINA
 exhausted = false
 stride_moving = false
 run_clock = 0.0

func _wants_to_sprint(movement: float) -> bool:
 return movement != 0.0 and not exhausted and _held("run") and not air_kick

func _step_stride(delta: float, distance: float, sprinting: bool, on_ground: bool) -> void:
 stride_moving = on_ground and distance > 0.1
 if not on_ground:
  return
 if stride_moving:
  run_clock = fposmod(run_clock + distance / (225.0 if _is_mounted() else 114.0), 1.0)
 if sprinting and stride_moving:
  stamina = maxf(0.0, stamina - STAMINA_DRAIN * delta)
  if stamina == 0.0:
   exhausted = true
 else:
  stamina = minf(MAX_STAMINA, stamina + STAMINA_RECOVERY * delta)
  if stamina >= STAMINA_RESUME:
   exhausted = false

func _stride_frame() -> int:
 return floori(run_clock * 6.0)

func _physics_process(delta: float) -> void:
 if not paused:
  clock += delta
  if phase==Phase.CINEMATIC:
   _tick_cinematic(delta)
  banner_timer = maxf(0, banner_timer - delta)
  if phase in [Phase.EXPLORE, Phase.FIGHT]:
   _tick(delta)
  _tick_particles(delta)
  shake = move_toward(shake, 0, delta * 35)
  hit_flash = maxf(0, hit_flash - delta)
 var focus_x:float=ARENA_START+320 if chapter_number==1 and phase==Phase.CINEMATIC and victory_timer<0 else hero.x
 var target := clampf(focus_x - 430, 0, WORLD_END - 1280)
 camera_x = lerpf(camera_x, target, minf(1, delta * 5))
 camera_y = move_toward(camera_y,maxf(0,hero.y-FLOOR_Y) if phase in [Phase.EXPLORE,Phase.FIGHT] else 0,delta*300)
 position.y = -camera_y
 if lesson_open:
  lesson_arrow.position.y=sin(clock*6)*5
 _refresh_ui()
 if qa_enabled:
  var state := {"phase": Phase.keys()[phase], "x": hero.x, "y": hero.y, "hp": hp, "boar_x": boar.x, "boar_hp": boar_hp, "boar_state": boar_state, "boar_timer": boar_timer, "facing": facing, "collected": collected.size(), "paused": paused, "elapsed": elapsed, "completed": completed, "best_time": best_time}
  JavaScriptBridge.eval("window.__qabanbayState=" + JSON.stringify(state), true)
 queue_redraw()

func _tick(delta: float) -> void:
 if phase not in [Phase.EXPLORE, Phase.FIGHT] or paused:
  return
 if is_instance_valid(exploration) and exploration.step(delta):
  return
 _tutorial_step()
 elapsed += delta
 if hp < MAX_HP:
  heal_timer += delta
  if heal_timer >= 5.0:
   hp = mini(MAX_HP, hp + 1)
   heal_timer = 0
   audio.play("heal")
   _burst(hero - Vector2(0, 55), Color("a4df88"), 7)
 else:
  heal_timer = 0
 footstep_timer = maxf(0, footstep_timer - delta)
 grounded = _supported(hero)
 landing_timer = maxf(0, landing_timer - delta)
 attack_buffer = maxf(0, attack_buffer - delta)
 if _held("attack") and not previous.get("attack", false):
  attack_buffer = maxf(attack_buffer,0.34)
 attack_timer = maxf(0, attack_timer - delta)
 super_timer = maxf(0, super_timer - delta)
 dodge_timer = maxf(0, dodge_timer - delta)
 dodge_cooldown = maxf(0, dodge_cooldown - delta)
 invulnerable = maxf(0, invulnerable - delta)
 var movement := float(_held("right")) - float(_held("left"))
 if movement != 0 and dodge_timer <= 0:
  facing = signf(movement)
  tutorial.move = true
 if _held("jump") and not previous.get("jump", false) and grounded:
  vertical_speed = -715 if _is_mounted() else -690
  tutorial.jump = true
  audio.play("jump")
 var sprinting := _wants_to_sprint(movement)
 if sprinting:
  tutorial.run = true
 if int(elapsed/13.0)>int((elapsed-delta)/13.0):
  audio.play("bird")
 var old_x := hero.x
 if elder_started_at<0 and hero.x>335:elder_started_at=elapsed
 var speed := RUN_SPEED if sprinting else SPEED
 if _is_mounted():
  speed = 315.0 if sprinting else 235.0
 var horizontal_speed := movement * speed
 _move_hero(delta, horizontal_speed)
 _step_stride(delta, absf(hero.x - old_x), sprinting, grounded)
 if is_instance_valid(exploration):
  exploration.after_motion()
  if exploration.inside or exploration.bounce>0:return
 if phase == Phase.LOST:
  return
 if grounded and absf(hero.x - old_x) > 0.1 and dodge_timer <= 0 and footstep_timer <= 0:
  audio.play("hoof" if _is_mounted() else "step")
  footstep_timer = (0.14 if sprinting else 0.18) if _is_mounted() else (0.22 if sprinting else 0.30)
  if sprinting and not _is_mounted():
   _burst(hero - Vector2(facing * 13, 3), Color("#c8ad7c"), 2)
 if attack_timer <= 0:
  if _held("power") and super_hits >= SUPER_HITS_REQUIRED:
   _attack(true)
  elif (_held("attack") or attack_buffer > 0) and (grounded or _is_mounted() or attack_buffer>0):
   _attack()
   attack_buffer = 0
 _resolve_attack()
 if grounded and air_kick:
  _burst(hero-Vector2(0,3),Color("c8ad7c"),6)
  attack_timer=0
  air_kick=false
 for span in stage.spikes:
  if hero.x+14>span.x and hero.x-14<span.y and hero.y>_floor_at(hero.x)-23 and invulnerable<=0:
   _hurt()
   break
 if lesson_open and _held(lesson_target):
  lesson_open=false
  lesson_arrow.hide()
 if chapter_number==1 and training_stage<6:
  if training_stage==3 and dummy_hp>0:
   hero.x = minf(hero.x,1460)
  _tutorial_step()
 if hero.x > _elder_x() + 75:
  npc_passed = true
 for action in ["jump", "run", "attack"]:
  previous[action] = _held(action)
 _pickups()
 match wind_trial.step(hero, route_platforms, delta):
  WindTrial.Result.EXPIRED:
   _notice("Время вышло · начни с первого знака")
  WindTrial.Result.COMPLETE:
   hp = mini(MAX_HP, hp + 1)
   stamina = MAX_STAMINA
   exhausted = false
   _burst(hero - Vector2(0, 28), Color("#ffdc99"), 16)
   _notice("Тропа ветра пройдена · +1 сердце")
   audio.play("pickup")
 for point in stage.get("checkpoints",[]):
  if hero.x>=point and hero.x<point+130 and grounded and point>checkpoint_x:
   checkpoint=true
   checkpoint_x=point
   checkpoint_y=hero.y
   _notice("Привал найден")
   audio.play("pickup")
 if chapter_number==1 and grounded and _floor_exists(hero.x) and hero.x>ARENA_START-650 and checkpoint_x<ARENA_START:
  checkpoint = true
  checkpoint_x=ARENA_START+80
  _notice("Контрольная точка · восстановление +1 HP каждые 5 с")
  audio.play("pickup")
 if chapter_number==1 and phase==Phase.EXPLORE and hero.x>=ARENA_START-420 and horse_event<0:
  horse_event=0.0
  phase=Phase.CINEMATIC
  _clear_input()
  _notice("Кабан атакует табун!")
 if chapter_number == 1 and phase == Phase.FIGHT:
  _tick_boar(delta)

func _pickups() -> void:
 for i in range(route_charms.size()):
  if not collected.has(i) and hero.distance_to(route_charms[i]) < 35:
   collected[i] = true
   _burst(route_charms[i], Color("f1d6a6"), 7)
   if collected.size() == 1:
    _notice("Асык · найденная игральная косточка")
   audio.play("pickup")
 for index in range(route_supplies.size()):
  if collected_supplies.has(index):
   continue
  var at: Vector2 = route_supplies[index]
  if absf(hero.x - at.x) > 30.0 or absf(hero.y - at.y) > 24.0:
   continue
  collected_supplies[index] = true
  stamina = MAX_STAMINA
  exhausted = false
  hp = mini(MAX_HP, hp + 1)
  _burst(at - Vector2(0, 28), Color("#8ed3bd"), 9)
  _notice("Припасы · силы восстановлены")
  audio.play("pickup")

func _is_mounted() -> bool:
 return chapter_number in [2,3]

func _attack(power: bool = false) -> void:
 if attack_timer > 0.0 or (power and super_hits < SUPER_HITS_REQUIRED):
  return
 empowered = power
 var indoors: bool = is_instance_valid(exploration) and exploration.inside
 air_kick = not power and (not exploration.room_grounded if indoors else not _is_mounted() and not grounded)
 attack_timer = 0.30
 dive_previous_y=exploration.room_y if indoors else hero.y
 if air_kick:
  if exploration.inside:exploration.room_vy=2300.0
  else:vertical_speed=2300.0
 if power:
  super_used = true
  super_hits = 0
  super_timer = SUPER_EFFECT_TIME
  audio.play("charge")
  shake = 5
 attack_count += 1
 swing_hits.clear()
 tutorial.attack = true
 attack_landed = false
 audio.play("spear")

func _register_hit() -> void:
 if not empowered and super_hits < SUPER_HITS_REQUIRED:
  super_hits = mini(SUPER_HITS_REQUIRED,super_hits+1)
  if super_hits==SUPER_HITS_REQUIRED:
   audio.play("pickup")

func _strike_damage() -> int:
 return SUPER_DAMAGE if empowered else 1

func _weapon_rect() -> Rect2:
 if air_kick:return Rect2(hero.x-38,minf(dive_previous_y,hero.y)-5,76,absf(hero.y-dive_previous_y)+65)
 var reach := 235.0 if empowered else 175.0 if _is_mounted() else 150.0
 var height := 156.0 if _is_mounted() else 101.0
 return Rect2(hero.x + (0.0 if facing > 0 else -reach), hero.y-height, reach, height)

func _can_hit(target: Rect2, key: String) -> bool:
 return (air_kick and attack_timer>0 or attack_timer <= 0.24 and attack_timer >= 0.06) and not swing_hits.has(key) and _weapon_rect().intersects(target)

func _resolve_attack() -> void:
 if attack_timer <= 0 or phase not in [Phase.EXPLORE, Phase.FIGHT]:
  return
 if dummy_hp > 0 and _can_hit(Rect2(1385, FLOOR_Y - 100, 50, 100), "dummy"):
  dummy_hp -= 1
  swing_hits.dummy = true
  _register_hit()
  attack_landed = true
  _burst(Vector2(1410, FLOOR_Y - 70), Color("cfb77a"), 9)
  audio.play("hit")
  if dummy_hp == 0:
   _notice("Три точных удара! Продолжай путь.")
   audio.play("break")
 if phase == Phase.FIGHT and boar_hp > 0 and _can_hit(Rect2(boar.x - 48, FLOOR_Y - 105, 96, 105), "boss"):
  swing_hits.boss = true
  _register_hit()
  boar_hp = maxi(0, boar_hp - _strike_damage())
  attack_landed = true
  hit_flash = 0.16
  shake = 8 if empowered else 3
  if boar_state == "recover":
   boar_state = "stagger"
   boar_timer = 0.28
  _burst(boar - Vector2(0, 60), Color("ffdb8f"), 12)
  audio.play("hit")
  if boar_hp <= 0:
   _win()

func _solids() -> Array:
 return route_platforms

func _floor_at(x:float) -> float:
 return preload("res://scripts/landform.gd").surface(x,route_depths,FLOOR_Y)

func _floor_exists(x:float) -> bool:
 return _floor_at(x)<10000

func _supported(at: Vector2) -> bool:
 if absf(at.y - _floor_at(at.x)) < 0.5:
  return true
 for solid in route_platforms:
  if absf(at.y - solid.position.y) < 0.5 and at.x + 17 > solid.position.x and at.x - 17 < solid.end.x:
   return true
 return false

func _move_hero(delta:float,horizontal_speed:float)->void:
 dive_previous_y=hero.y
 var distance:=maxf(absf(horizontal_speed),absf(vertical_speed)+GRAVITY*delta)*delta
 var steps:=clampi(ceili(distance/8.0),1,64)
 for i in range(steps):
  _move_hero_step(delta/steps,horizontal_speed*(0.35 if air_kick else 1.0))
  if phase==Phase.LOST:break

func _move_hero_step(delta: float, horizontal_speed: float) -> void:
 var old := hero
 var next_x := clampf(hero.x + horizontal_speed * delta, ARENA_START + 40 if phase == Phase.FIGHT else 50, WORLD_END - 80)
 var old_floor:=_floor_at(old.x)
 if old_floor<10000 and old.y>old_floor+0.1:
  old.y=old_floor
  hero.y=old_floor
  vertical_speed=0
  grounded=true
 # The terrain is solid below its surface, including the inside of both banks.
 var side:=signf(horizontal_speed)
 if side!=0 and not (grounded and vertical_speed>=0):
  var allowance:=0.2
  if _floor_at(next_x+side*16)<old.y-allowance:
   var safe_x:=old.x
   var blocked_x:=next_x
   for scan in range(10):
    var mid:float=(safe_x+blocked_x)*0.5
    if _floor_at(mid+side*16)>=old.y-allowance:safe_x=mid
    else:blocked_x=mid
   next_x=safe_x
 hero.x = next_x
 vertical_speed += GRAVITY * delta
 var next_y := hero.y + vertical_speed * delta
 var terrain_y:=_floor_at(hero.x)
 var ground_follow:=grounded and vertical_speed>=0 and absf(terrain_y-old.y)<18
 if ground_follow:
  next_y=terrain_y
  vertical_speed=0
 var landing_y := _floor_at(hero.x)
 var landed_rock: Rect2 = Rect2()
 for solid in _solids():
  if hero.x + 17 <= solid.position.x or hero.x - 17 >= solid.end.x:
   continue
  if vertical_speed >= 0 and old.y <= solid.position.y + 0.1 and next_y >= solid.position.y:
   if solid.position.y < landing_y:
    landing_y = solid.position.y
    landed_rock = solid if route_rocks.has(solid) else Rect2()
  elif not route_platforms.has(solid) and vertical_speed < 0 and old.y - 96 >= solid.end.y - 0.1 and next_y - 96 < solid.end.y:
   next_y = solid.end.y + 96
   vertical_speed = 0
 var was_grounded := grounded
 grounded = false
 if vertical_speed >= 0 and old.y <= landing_y + 0.1 and next_y >= landing_y:
  next_y = landing_y
  vertical_speed = 0
  grounded = true
  if landed_rock.size.x>0:
   grounded = false
   var slide := signf(hero.x-landed_rock.get_center().x)
   if absf(horizontal_speed)>1:
    slide = signf(horizontal_speed)
   if slide==0:
    slide = -facing
   hero.x += slide*maxf(absf(horizontal_speed),180)*delta
  if not was_grounded and landing_timer<=0:
   landing_timer = 0.12
   audio.play("platform" if route_platforms.any(func(platform): return absf(platform.position.y-next_y)<1) else "land")
 if ground_follow and vertical_speed==0:grounded=true
 hero.y = next_y
 if hero.y > FLOOR_Y + 450:
  hp = 0
  deaths += 1
  phase = Phase.LOST
  audio.play("hurt")
  _show_panel("Овраг", "Перепрыгивай между каменными уступами.\n\nШаг — A / D · Бег — K · Прыжок — пробел.\nНайденные припасы сохранятся.", "Повторить путь")

func _decor_clear(x: float, half_width: float = 20.0) -> bool:
 for gap in route_gaps:
  if x + half_width > gap.x and x - half_width < gap.y:
   return false
 return true

func _elder_x() -> float:
 var home:float=stage.get("elder_x",390.0)
 return home+70*smoothstep(0,1,clampf((elapsed-elder_started_at)/1.8,0,1)) if elder_started_at>=0 else home

func _draw_layout_decor() -> bool:
 wind_trial.draw(self, route_platforms, camera_x, clock)
 for index in range(route_supplies.size()):
  if not collected_supplies.has(index):
   art.supply(self, route_supplies[index] - Vector2(camera_x, 0), clock)
 if not stage.has("decor"):
  return false
 for entry in stage.decor:
  var at: Vector2 = entry.at
  if at.x<camera_x-500 or at.x>camera_x+1800:
   continue
  if entry.name not in ["banner","crate","tumbleweed"] and (int(entry.get("platform",-1))>=0 or _decor_clear(at.x, float(entry.get("clearance", entry.size.x * 0.5)))):
   at.y = _floor_at(at.x)
   var support:int=int(entry.get("platform",-1))
   if support>=0 and support<route_platforms.size():
    at=route_platforms[support].position+Vector2(entry.get("offset",0.0),0)
   art.prop(self, entry.name, at - Vector2(camera_x, 0), entry.size)
 for door in stage.get("doors",[]):
  if door.at.x<camera_x-450 or door.at.x>camera_x+1700:continue
  if door.kind=="secret":art.cave_mouth(self,door.at-Vector2(camera_x,0))
  else:art.prop(self,"yurt",door.at-Vector2(camera_x,0),Vector2(420,295))
 return true

func _refresh_npc() -> void:
 if is_instance_valid(npc_bubble):npc_bubble.hide()
 return

func _unused_npc_text() -> void:
 if not is_instance_valid(npc_bubble):
  return
 npc_bubble.visible = phase == Phase.EXPLORE and not paused and not lesson_open and not npc_passed and hero.x < _elder_x() + 75
 if not npc_bubble.visible:
  return
 var lines := ["Держи путь вправо. Перед краем оврага прыгни!", "Держись тропы. Не пропусти тренировочный манекен.", "Удар копья достаёт впереди. Подойди и бей J / G."]
 if chapter_number >= 3:
  lines = ["Через широкую пропасть иди по подвесным платформам.", "Перед прыжком выбери место приземления.", "Пережди выпад противника и отвечай точным ударом."]
 npc_text.text = "Старейшина\n" + lines[int(elapsed / 4.0) % lines.size()]
 npc_bubble.position = Vector2(clampf(_elder_x() - camera_x - 150, 15, 905), 245)

func _tick_boar(delta: float) -> void:
 boar_timer -= delta
 var enraged := boar_hp <= boss_max_hp / 2
 match boar_state:
  "approach":
   boar_facing = signf(hero.x - boar.x)
   boar.x = move_toward(boar.x, hero.x, 125 * delta)
   if absf(boar.x - hero.x) < 430:
    boar_state = "windup"
    boar_timer = stage.windup * (0.82 if enraged else 1.0)
    charge_direction = signf(hero.x - boar.x)
  "windup":
   if boar_timer <= 0:
    boar_state = "charge"
    boar_timer = 0.85
    boar_facing = charge_direction
    audio.play("charge")
  "charge":
   boar.x += charge_direction * (stage.speed * (1.12 if enraged else 1.0)) * delta
   if boar_timer <= 0 or boar.x < ARENA_START + 70 or boar.x > WORLD_END - 100:
    boar.x = clampf(boar.x, ARENA_START + 70, WORLD_END - 100)
    if chapter_number == 5 and enraged and boss_chain == 0:
     boss_chain = 1
     boar_state = "windup"
     boar_timer = 0.62
     charge_direction = signf(hero.x - boar.x)
     boar_facing = charge_direction
    else:
     boss_chain = 0
     boar_state = "recover"
     boar_timer = stage.recover * (0.9 if enraged else 1.0)
  "recover", "stagger":
   if boar_timer <= 0:
    boar_state = "approach"
 if boar_state in ["charge", "approach"] and absf(hero.x - boar.x) < 75 and hero.y > FLOOR_Y - 85 and invulnerable <= 0:
  _hurt()

func _hurt() -> void:
 hp -= 1
 heal_timer = 0
 damage_taken += 1
 invulnerable = 1.4
 shake = 9
 audio.play("hurt")
 _burst(hero - Vector2(0, 55), Color("ef9269"), 12)
 var away := signf(hero.x - boar.x)
 if away == 0:
  away = -boar_facing
 hero.x = clampf(hero.x + away * 80, ARENA_START + 40 if phase == Phase.FIGHT else 50, WORLD_END - 80)
 if hp <= 0:
  phase = Phase.LOST
  deaths += 1
  _show_panel("Поднимись, Ерасыл","Перепрыгни бросок кабана и отвечай копьём. K — удерживать для бега.","Повторить бой")

func _win() -> void:
 if victory_timer>=0:
  return
 defeated_at=clock
 boar_state="down"
 victory_timer=0.0
 victory_line="Это моё первое сражение. Я победил и спас табун."
 phase=Phase.CINEMATIC
 _clear_input()
 audio.play("win")

func _finish_level() -> void:
 phase=Phase.OUTRO
 completed=true
 dialog_index=0
 if best_time<=0 or elapsed<best_time:
  best_time=elapsed
 _save_progress()
 _show_dialog(OUTRO if chapter_number==1 else stage.outro)

func _tick_cinematic(dt:float) -> void:
 if victory_timer>=0:
  victory_timer+=dt
  if victory_timer>=4.5:
   _finish_level()
 elif chapter_number==1:
  horse_event+=dt
  if horse_event<1.0:
   boar.x=move_toward(boar.x,ARENA_START+660,dt*260)
   boar_state="charge"
   boar_facing=1
  elif horse_event<1.2 and not horse_fled:
   horse_fled=true
   audio.play("hit")
   audio.play("horse")
   _burst(Vector2(ARENA_START+760,FLOOR_Y-70),Color("efcba3"),8)
  elif horse_event>=3.8:
   phase=Phase.FIGHT
   hero.x=maxf(hero.x,ARENA_START+40)
   boar_state="approach"
   _notice("Табун убегает. Защити его!")

func _draw_horse_scene() -> void:
 for i in range(3):
  var flee:=maxf(0,horse_event-1.0-i*0.18)*570
  var p:=Vector2(ARENA_START+780+i*175+flee-camera_x,FLOOR_Y)
  if p.x<-220 or p.x>1500:
   continue
  var clip:="gallop" if flee>45 else "idle"
  var tint:=Color("ff9c83") if horse_event>1 and horse_event<1.25 and i==0 else Color.WHITE
  character_frames.pose(self,"horse",clip,int(clock*(12 if flee>45 else 3)+i)%6,p,1,tint)

func _draw_victory_line() -> void:
 if victory_timer<0 or victory_timer>4.5:
  return
 var p:=hero-Vector2(camera_x,0)
 var box:=Rect2(clampf(p.x-230,20,790),p.y-(275 if _is_mounted() else 225),465,64)
 draw_style_box(_style(Color("173b3a"),Color("edcf88")),box)
 draw_colored_polygon(PackedVector2Array([Vector2(p.x-9,box.end.y),Vector2(p.x+9,box.end.y),p-Vector2(0,135)]),Color("173b3a"))
 draw_multiline_string(ThemeDB.fallback_font,box.position+Vector2(16,25),victory_line,HORIZONTAL_ALIGNMENT_LEFT,430,19,-1,Color("fff2ce"))

func _show_results() -> void:
 var stars := 1 + int(collected.size() >= route_charms.size()*0.65) + int(deaths == 0)
 var title: String = "Вернёмся сильнее" if chapter_number == 5 else "Уровень %d завершён" % chapter_number
 _show_panel(title,"%s\n\nНаграды: %d / 3 · Время: %s\nНаходки: %d · Поражений: %d\n\n%s" % [stage.title,stars,_time(elapsed),collected.size(),deaths,"Отряд отступил. Память о поединке останется с воинами." if chapter_number == 5 else "Новая глава открыта на карте пути."],"На карту пути")
 if not ResourceLoader.exists("res://scenes/campaign_map.tscn"):
  primary.text="Повторить уровень"
 secondary.hide()

func _story_markup(text: String) -> String:
 var formatted := text.replace("[","\uff3b").replace("]","\uff3d")
 for word in ["Ерасыл","Кабанбай","Старейшина","Зайсан","Аягоз"]:
  formatted = formatted.replace(word,"[color=#f2c76f][b]"+word+"[/b][/color]")
 for word in ["Прыжок","прыжок","копьё","Копьё","Бег","Бег","Пробел","Shift","J / G"]:
  formatted = formatted.replace(word,"[color=#92d3c1]"+word+"[/color]")
 return "[center]"+formatted+"[/center]"

func _control_unlocked(action: String) -> bool:
 if chapter_number!=1 or phase not in [Phase.EXPLORE,Phase.FIGHT]:
  return true
 match action:
  "jump": return training_stage>=2
  "attack": return training_stage>=3
  "run": return training_stage>=4
  "power": return training_stage>=5
 return true

func _lesson(stage_number: int, target: String, title: String, text: String) -> void:
 training_stage = stage_number
 lesson_open = true
 lesson_target = target
 _notice(title+" · "+{"right":"A / D","jump":"Пробел","attack":"J / G","run":"K + направление","power":"L"}[target])
 _refresh_ui()
 var center: Vector2 = action_buttons[target].get_global_rect().get_center()
 lesson_arrow.points = PackedVector2Array([center+Vector2(0,-94),center+Vector2(0,-52),center+Vector2(-12,-66),center+Vector2(0,-52),center+Vector2(12,-66)])
 lesson_arrow.show()
 audio.play("tutorial")

func _tutorial_step() -> void:
 if chapter_number!=1 or phase!=Phase.EXPLORE or lesson_open:
  return
 if training_stage==0:
  _lesson(1,"right","ПЕРВЫЕ ШАГИ","Путь начинается здесь.\n\nЭти две кнопки двигают героя влево и вправо.\nНа клавиатуре: A / D или стрелки.\n\nДойди до края сухого оврага. Остальное освоим постепенно.")
 elif training_stage==1 and hero.x>=470:
  _lesson(2,"jump","ПРЫЖОК","Сначала потренируй прыжок на свободной тропе. Дальше будут большие овраги.\n\nНажми Прыжок перед краем и держи направление.\nКлавиатура: Пробел. Для нового прыжка нажми заново.\n\nОстановись и выбери место приземления.")
 elif training_stage==2 and hero.x>=1190:
  _lesson(3,"attack","КОПЬЁ И МАНЕКЕН","Перед тобой тренировочный манекен.\n\nПодойди, повернись к нему и нанеси три удара.\nКопьё: J / G. Следующий взмах можно начать сразу после предыдущего.\n\nДальше пройдёшь, когда манекен будет разбит.")
 elif training_stage==3 and dummy_hp<=0:
  _lesson(4,"run","БЕГ ПО СТЕПИ","Удерживай K вместе с направлением, чтобы бежать.\n\nБег расходует выносливость. На шаге и остановке она восстанавливается.\n\nПробеги до следующего указателя.")
 elif training_stage==4 and tutorial.run and hero.x>=1530:
  super_hits = SUPER_HITS_REQUIRED
  _lesson(5,"power","СИЛА БАТЫРА","Суперудар заряжается за 11 обычных попаданий. Промахи не считаются. Заряд сохранится, пока не нажмёшь L.\n\nСейчас дан один учебный заряд. Испытай его!")
 elif training_stage==5 and super_used:
  training_stage = 6
  _notice("Обучение пройдено · потренируйся на тропе перед боем")

func _notice(text: String) -> void:
 banner_text = text
 banner_timer = 3.2

func _time(seconds: float) -> String:
 return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]

func _refresh_ui() -> void:
 _refresh_npc()
 var active := phase in [Phase.EXPLORE, Phase.FIGHT]
 player_hud.visible = active
 player_hud.update_status(hp, stamina, exhausted)
 lesson_hint.visible=lesson_open and active and not paused
 if lesson_hint.visible:
  var target:Vector2=action_buttons[lesson_target].get_global_rect().get_center()
  lesson_hint.position=Vector2(clampf(target.x-110,5,1055),target.y-153)
  lesson_hint.text="Нажми: "+{"right":"вправо · D","jump":"прыжок · Пробел","attack":"удар · J / G","run":"бег · K","power":"суперудар · L"}[lesson_target]
 hud.text = "ЕРАСЫЛ"
 loot_label.text = "Асыки: %d / %d" % [collected.size(), route_charms.size()]
 objective.text = "ГЛАВА I  /  Защити табун" if phase == Phase.FIGHT else "ГЛАВА I  /  Найди лошадей у реки >"
 if phase == Phase.FIGHT:
  hint.text = {"approach": "Держи дистанцию. Кабан готовится к броску.", "windup": "СЕЙЧАС БРОСОК! Прыжок — пробел · Бег — K", "charge": "УКЛОНЯЙСЯ!", "recover": "АТАКУЙ СБОКУ! Копьё — J", "stagger": "Есть попадание! Отойди и приготовься к броску."}.get(boar_state, "")
 elif hero.x < 800:
  hint.text = "Шаг: A / D · Бег: K + направление · Суперудар: L · собирай асыки"
 elif hero.x < 1200:
  hint.text = "Прыжок: Пробел. Беги вдоль тропы к мишени."
 elif hero.x < 1650:
  hint.text = "Потренируй копьё на мишени: J · 3 попадания"
 elif hero.x < 3100:
  hint.text = "Бег: K · Лечение: +1 HP каждые 5 секунд без урона"
 else:
  hint.text = "Следуй к табуну > Контрольная точка перед боем"
 boss_label.text = "КАБАН    %d / %d" % [maxi(0, boar_hp), boss_max_hp]
 controls.visible = active and not paused
 hud.visible = false
 loot_label.visible = false
 objective.visible = false
 hint.visible = false
 pause_button.visible = active
 sound_button.visible = active or phase == Phase.TITLE
 sound_button.text = "ВЫКЛ" if muted else "ЗВУК"
 sound_button.tooltip_text = "Звук: включить / выключить (M)"
 boss_label.visible = false
 banner.text = banner_text
 banner.visible = active and banner_timer > 0 and not lesson_open and not exploration.inside
 if active and wind_trial.seconds_left > 0.0 and not exploration.inside:
  banner.text = "ТРОПА ВЕТРА   %d / %d     %d с" % [wind_trial.progress, WindTrial.MARKS, ceili(wind_trial.seconds_left)]
  banner.visible = true
 for action in action_buttons:
  action_buttons[action].visible = _control_unlocked(action)
  action_buttons[action].charge_ratio = float(super_hits)/SUPER_HITS_REQUIRED if action == "power" else 1.0
  action_buttons[action].modulate = Color.WHITE

func _burst(at: Vector2, color: Color, count: int) -> void:
 for i in range(count):
  var angle := TAU * i / count
  particles.append({"p": at, "v": Vector2(cos(angle), sin(angle)) * (65 + i * 13), "life": 0.45, "color": color})

func _tick_particles(delta: float) -> void:
 for i in range(particles.size() - 1, -1, -1):
  particles[i].life -= delta
  particles[i].p += particles[i].v * delta
  particles[i].v.y += 450 * delta
  if particles[i].life <= 0:
   particles.remove_at(i)

func _draw() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 if phase in [Phase.INTRO,Phase.OUTRO]:
  chapter_screen.draw_story(self,0 if phase==Phase.INTRO else 2,clock,true)
  return
 var size := get_viewport_rect().size
 var offset := Vector2(sin(clock * 70), cos(clock * 53)) * shake
 draw_set_transform(offset)
 art.background(self, camera_x, size,chapter_number)
 art.ground(self, camera_x, size.x, FLOOR_Y, route_gaps,route_depths)
 for platform_rect in route_platforms:
  art.platform(self, platform_rect, camera_x, chapter_number, route_depths)
 if not _draw_layout_decor():
  for x in [160.0, 480.0]:
   if not _decor_clear(x, 140):
    continue
   art.prop(self, "yurt", Vector2(x - camera_x, FLOOR_Y), Vector2(280, 217))
  for x in [830.0, 2200.0, 3310.0, 5070.0]:
   if not _decor_clear(x, 50):
    continue
   art.prop(self, "tree", Vector2(x - camera_x, FLOOR_Y), Vector2(160, 247))
  for x in [610.0, 1580.0, 3040.0, 3570.0]:
   if not _decor_clear(x, 32):
    continue
   art.prop(self, "reeds", Vector2(x - camera_x, FLOOR_Y), Vector2(65, 96))
  for x in [760.0,1200.0,1700.0,2400.0,3100.0,3800.0,5200.0]:
   if _decor_clear(x,22):
    art.prop(self,"grass_tuft",Vector2(x-camera_x,FLOOR_Y),Vector2(44,28))
 _draw_elder(Vector2(_elder_x() - camera_x, FLOOR_Y))
 for rock in route_rocks:
  art.scenic_rock(self, rock, camera_x, FLOOR_Y)

 for i in range(route_charms.size()):
  if not collected.has(i):
   art.asyk(self, route_charms[i] - Vector2(camera_x, 0), i)
 if dummy_hp>0:
  art.prop(self,"practice_dummy",Vector2(1410-camera_x,FLOOR_Y),Vector2(105,145))
  if training_stage==3 and not lesson_open:
   var finger:=Vector2(1410-camera_x,FLOOR_Y-180+sin(clock*6)*5)
   draw_circle(finger,10,Color("73512f"))
   draw_line(finger-Vector2(0,20),finger+Vector2(0,13),Color("fff1cd"),9,true)
   draw_colored_polygon(PackedVector2Array([finger+Vector2(-10,7),finger+Vector2(0,24),finger+Vector2(10,7)]),Color("fff1cd"))
 for span in stage.spikes:
  art.spikes(self,span,camera_x,FLOOR_Y)
 _draw_horse_scene()
 _draw_hero(hero - Vector2(camera_x, 0))
 _draw_boar(boar - Vector2(camera_x, 0))
 _draw_super_strike(self, hero - Vector2(camera_x, 0), false)
 for particle in particles:
  var p: Vector2 = particle.p - Vector2(camera_x, 0)
  draw_rect(Rect2(p, Vector2(5, 5)), particle.color)
 draw_set_transform(Vector2.ZERO)
 _draw_victory_line()
 draw_rect(Rect2(0,584,size.x,maxf(0,size.y-584)),Color(0.02,0.05,0.03,0.14))
 if phase not in [Phase.EXPLORE, Phase.FIGHT] or paused:
  draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.07, 0.1, 0.38))

func _draw_elder(p:Vector2)->void:
 if elder_started_at<0 or p.x< -180 or p.x>1460:return
 var direction:float=-1.0 if hero.x<_elder_x() else 1.0
 var clip:="point" if int(clock*0.6)%2==0 else "talk"
 character_frames.pose(self,"elder",clip,int(clock*7)%6,p,direction)

func _draw_hero(p: Vector2) -> void:
 if hp<=0:
  if death_at<0:death_at=clock
  var t:=clampf((clock-death_at)/0.8,0,1)
  character_frames.pose(self,"hero","hurt",clampi(int(t*6),0,5),p,facing,Color.WHITE,t*1.35*facing)
  return
 if grounded:
  _shadow(p,31)
 var clip := "idle"
 var step := int(clock*5)%6
 if is_instance_valid(exploration) and exploration.bounce>0:
  clip="hurt"
  step=clampi(int((0.85-exploration.bounce)*7),0,5)
 elif attack_timer>0:
  clip="kick" if air_kick else "super" if empowered else "attack"
  step=clampi(int((1.0-attack_timer/0.30)*6),0,5)
 elif not grounded:
  clip="jump"
  step=clampi(int((vertical_speed+700)/235),0,5)
 elif invulnerable>1.15:
  clip="hurt"
  step=clampi(int((1.4-invulnerable)*24),0,5)
 elif landing_timer>0:
  clip="land"
  step=clampi(int((0.12-landing_timer)*50),0,5)
 elif stride_moving:
  clip="run"
  step=_stride_frame()
 character_frames.pose(self,"hero",clip,step,p+Vector2(0,18 if clip=="kick" else 0),facing,Color("ffe3c9") if invulnerable>1.05 else Color.WHITE)

func _draw_super_strike(canvas: CanvasItem, foot: Vector2, mounted: bool) -> void:
 if super_timer <= 0.0:
  return
 var t := 1.0 - super_timer / SUPER_EFFECT_TIME
 var center := (foot - Vector2(0, 114 if mounted else 70)).round()
 var span := 48.0 + 169.0 * ease(t, 0.45)
 var fade := 1.0 - t
 var tail := Vector2(span * 0.31, 19.0)
 var edge := Vector2(span, -12.0 + t * 24.0)
 canvas.draw_set_transform(center, 0.0, Vector2(facing, 1.0))
 canvas.draw_colored_polygon(PackedVector2Array([Vector2(span * 0.15, 19), Vector2(span * 0.60, -42), edge + Vector2(6, 0), Vector2(span * 0.83, 29)]), Color(1.0, 0.63, 0.22, fade * 0.29))
 canvas.draw_colored_polygon(PackedVector2Array([tail, Vector2(span * 0.66, -25), edge, Vector2(span * 0.81, 17)]), Color(0.78, 0.49, 0.21, fade * 0.84))
 canvas.draw_colored_polygon(PackedVector2Array([Vector2(span * 0.20, 7), Vector2(span * 0.67, -16), edge, Vector2(span * 0.75, 5)]), Color(1.0, 0.96, 0.77, fade))
 var flare := edge.round()
 canvas.draw_rect(Rect2(flare - Vector2(2, 11), Vector2(4, 22)), Color(1.0, 0.91, 0.61, fade))
 canvas.draw_rect(Rect2(flare - Vector2(9, 2), Vector2(18, 4)), Color(1.0, 0.91, 0.61, fade))
 for i in range(7):
  var point := Vector2(span * (0.46 + i * 0.07), float(i * 13 % 38) - 18.0 + t * (i - 3) * 8.0).round()
  canvas.draw_rect(Rect2(point, Vector2(5 + i % 3 * 2, 3)), Color(1.0, 0.72, 0.36, fade))
 canvas.draw_set_transform(Vector2.ZERO)


func _draw_boar(p: Vector2) -> void:
 _shadow(p,60)
 var clip := "idle"
 var step := int(clock*6)%6
 if boar_hp<=0:
  clip="down"
  step=clampi(int((clock-defeated_at)*9),0,5)
 elif hit_flash>0:
  clip="hurt"
  step=clampi(int((0.16-hit_flash)*36),0,5)
 elif boar_state=="charge":
  clip="run"
  step=int(clock*15)%6
 elif boar_state=="windup":
  clip="windup"
  step=clampi(int((1.0-boar_timer/stage.windup)*6),0,5)
 elif boar_state in ["recover","stagger"]:
  clip="recover"
 character_frames.pose(self,"boar",clip,step,p,boar_facing)
 if boar_state == "windup" and phase == Phase.FIGHT:
  draw_line(p + Vector2(0,-165),p + Vector2(0,-145),Color("ffdc77"),6)
  draw_circle(p + Vector2(0,-135),4,Color("ffdc77"))
  draw_line(p+Vector2(boar_facing*40,0),p+Vector2(boar_facing*230,0),Color(1,0.4,0.2,0.45),4)

func _shadow(p: Vector2, width: float) -> void:
 var points := PackedVector2Array()
 for i in range(20):
  var a := TAU * i / 20
  points.append(p + Vector2(cos(a) * width, sin(a) * 7 + 3))
 draw_colored_polygon(points, Color(0.03, 0.05, 0.03, 0.24))
