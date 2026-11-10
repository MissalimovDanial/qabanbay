extends Node2D
## Original steppe atlas: five chapters, opened in story order.
const SAVE_PATH := "user://steppe_sand_campaign.cfg"
const SCENES := ["main", "level_two", "level_three", "level_four", "level_five"]
const Chapters = preload("res://scripts/chapter_data.gd")
var NODE_POSITIONS := [Vector2(160, 528), Vector2(325, 385), Vector2(503, 470), Vector2(663, 319), Vector2(798, 225)]
const ROMAN := ["I", "II", "III", "IV", "V"]
const GOLD := Color("e9c781")
const INK := Color("143734")
const CREAM := Color("f5e7c4")
var completed: Array[bool] = []
var unlocked_count := 1
var selected := 0
var node_buttons: Array[Button] = []
var detail_title: Label
var detail_place: Label
var detail_body: Label
var difficulty: Label
var detail_status: Label
var launch_button: Button
var header: Label
var progress: Label
var phase_clock := 0.0
var _node_names: Array[Label] = []

func _ready() -> void:
 var layout:=get_node_or_null("MapLayout")
 if layout and layout.get_child_count()==5:
  for index in range(5):
   NODE_POSITIONS[index]=layout.get_child(index).position
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 reload_progress()
 _build_ui()
 _select(selected)
 var save := ConfigFile.new()
 save.load(SAVE_PATH)
 var sound = preload("res://scripts/audio.gd").new()
 add_child(sound)
 sound.enabled = not bool(save.get_value("settings", "muted", false))
 var notified := int(save.get_value("settings", "notified_chapter", 1))
 if unlocked_count > notified:
  sound.play("unlock")
  save.set_value("settings", "notified_chapter", unlocked_count)
  save.save(SAVE_PATH)

func reload_progress() -> void:
 Chapters.import_first_trial()
 completed.clear()
 var save := ConfigFile.new()
 save.load(SAVE_PATH)
 for i in range(5):
  completed.append(bool(save.get_value("level%d" % (i+1), "completed", false)))
 unlocked_count = 1
 for i in range(4):
  if not completed[i]:
   break
  unlocked_count = i+2
 selected = mini(4, unlocked_count-1)
 if is_instance_valid(detail_title):
  _select(selected)
  _refresh_progress()

func can_launch(chapter_index: int) -> bool:
 return chapter_index >= 0 and chapter_index < 5 and chapter_index < unlocked_count

func _label(text: String, font_size: int, color: Color, at: Vector2, extent: Vector2, parent: Node) -> Label:
 var label := Label.new()
 label.text = text
 label.position = at
 label.size = extent
 label.add_theme_font_size_override("font_size", font_size)
 label.add_theme_color_override("font_color", color)
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(label)
 return label

func _style(fill: Color, border: Color, radius: int = 14, width: int = 1) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = fill
 style.border_color = border
 style.set_border_width_all(width)
 style.set_corner_radius_all(radius)
 style.content_margin_left = 14
 style.content_margin_right = 14
 style.content_margin_top = 10
 style.content_margin_bottom = 10
 return style

func _build_ui() -> void:
 var ui := CanvasLayer.new()
 add_child(ui)
 var root := Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 ui.add_child(root)
 header = _label("ҚАБАНБАЙ", 36, CREAM, Vector2(42,20), Vector2(600,48), root)
 _label("П У Т Ь   Б А Т Ы Р А", 14, GOLD, Vector2(45,70), Vector2(600,24), root)
 _label("КАРТА ПУТЕШЕСТВИЯ", 14, Color("9cb4a7"), Vector2(866,36), Vector2(370,24), root).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 progress = _label("",19,CREAM,Vector2(920,65),Vector2(316,29),root)
 progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 for i in range(5):
  var button := Button.new()
  button.name = "Chapter%d" % (i+1)
  button.position = NODE_POSITIONS[i]-Vector2(42,42)
  button.size = Vector2(84,84)
  button.tooltip_text = "%s · %s" % [ROMAN[i],Chapters.CHAPTERS[i].title]
  button.accessibility_name = Chapters.CHAPTERS[i].title
  for state in ["normal","hover","pressed","focus"]:
   button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
  button.focus_mode = Control.FOCUS_NONE
  button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  button.pressed.connect(_select.bind(i))
  root.add_child(button)
  node_buttons.append(button)
  var label_offset := Vector2(-80,52) if i == 4 else Vector2(-105,52)
  var label_size := Vector2(185,26) if i == 4 else Vector2(210,26)
  var label := _label(Chapters.CHAPTERS[i].title,16,CREAM,NODE_POSITIONS[i]+label_offset,label_size,root)
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _node_names.append(label)
 _label("З А Й С А Н",15,Color("daeee1"),Vector2(71,253),Vector2(180,28),root)
 _label("А Я Г О З   ·   1 7 1 8",13,Color("e4d3a2"),Vector2(376,601),Vector2(260,24),root)
 _label("СЕВЕР",10,Color("e9ddb5"),Vector2(70,176),Vector2(70,20),root)
 _label("ИСТОРИИ ВЕЛИКОЙ СТЕПИ",11,GOLD,Vector2(953,139),Vector2(276,22),root)
 detail_place = _label("",13,Color("a8c6b9"),Vector2(953,237),Vector2(267,24),root)
 detail_title = _label("",28,CREAM,Vector2(951,271),Vector2(271,83),root)
 detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail_title.add_theme_constant_override("line_spacing",1)
 detail_status = _label("",13,GOLD,Vector2(953,363),Vector2(267,42),root)
 detail_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail_body = _label("",17,Color("c0d1c4"),Vector2(953,417),Vector2(267,129),root)
 detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 difficulty = _label("",13,Color("a9bdac"),Vector2(953,553),Vector2(267,26),root)
 launch_button = Button.new()
 launch_button.name = "LaunchChapter"
 launch_button.position = Vector2(952,594)
 launch_button.size = Vector2(273,55)
 launch_button.add_theme_font_size_override("font_size",19)
 launch_button.add_theme_color_override("font_color",Color("173b35"))
 launch_button.add_theme_color_override("font_disabled_color",Color("7f988b"))
 launch_button.add_theme_stylebox_override("normal",_style(GOLD,Color("ffe8b1"),10))
 launch_button.add_theme_stylebox_override("hover",_style(Color("f6daa1"),Color("fff2d0"),10,2))
 launch_button.add_theme_stylebox_override("pressed",_style(Color("c9aa6b"),GOLD,10))
 launch_button.add_theme_stylebox_override("disabled",_style(Color("243e36"),Color("4d6658"),10))
 launch_button.pressed.connect(_launch)
 root.add_child(launch_button)
 _label("Проходи главы по порядку. К пройденным испытаниям можно вернуться.",14,Color("9bb2a2"),Vector2(43,679),Vector2(900,23),root)
 _label("←  →   ВЫБОР     ENTER  ИГРАТЬ",12,Color("cdb985"),Vector2(948,681),Vector2(289,23),root).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 _refresh_progress()

func _refresh_progress() -> void:
 var done := 0
 for value in completed:
  if not value:
   break
  done += 1
 progress.text = "%d из 5 испытаний пройдено" % done
 header.text = "ЛЕТОПИСЬ АЯГОЗА" if done == 5 else "ҚАБАНБАЙ"
 header.add_theme_font_size_override("font_size",31 if done == 5 else 36)
 for i in range(_node_names.size()):
  _node_names[i].add_theme_color_override("font_color",CREAM if can_launch(i) else Color("b1bc9e"))

func _select(index: int) -> void:
 selected = clampi(index,0,4)
 if not is_instance_valid(detail_title):
  queue_redraw()
  return
 detail_place.text = "ГЛАВА %s  /  %s" % [ROMAN[selected],Chapters.CHAPTERS[selected].place]
 detail_title.text = Chapters.CHAPTERS[selected].title
 if not can_launch(selected):
  detail_status.text = "ЗАКРЫТО · СНАЧАЛА ГЛАВА %s" % ROMAN[selected-1]
  detail_status.add_theme_color_override("font_color",Color("c0aa89"))
 elif completed[selected]:
  detail_status.text = "ПРОЙДЕНО · ПУТЬ ОТКРЫТ"
  detail_status.add_theme_color_override("font_color",Color("a8d9b0"))
 else:
  detail_status.text = "ДОСТУПНО · ТВОЁ ИСПЫТАНИЕ"
  detail_status.add_theme_color_override("font_color",GOLD)
 detail_body.text = Chapters.CHAPTERS[selected].hook
 difficulty.text = "СЛОЖНОСТЬ  %d / 5" % (selected+1)
 launch_button.text = "Глава пока закрыта" if not can_launch(selected) else "Пройти ещё раз" if completed[selected] else "Начать путешествие" if selected == 0 else "Начать главу"
 launch_button.disabled = not can_launch(selected)
 queue_redraw()

var loading_chapter := false

func _launch() -> void:
 if loading_chapter or not can_launch(selected):
  return
 loading_chapter = true
 var path := "res://scenes/%s.tscn" % SCENES[selected]
 var layer := CanvasLayer.new()
 layer.layer = 30
 add_child(layer)
 var loading := preload("res://scripts/ui/chapter_loading.gd").new()
 loading.chapter_title = Chapters.CHAPTERS[selected].title
 loading.tip = [
  "Отталкивайся от края, чтобы перепрыгнуть широкую трещину.",
  "Беги короткими отрезками, чтобы сохранить выносливость.",
  "Пропусти стрелу и перепрыгни встречного всадника.",
  "Подойди к лучнику после того, как он выпустит стрелу.",
  "Одиннадцать обычных попаданий заряжают суперудар."
 ][selected]
 layer.add_child(loading)
 loading.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var tree := get_tree()
 await tree.process_frame
 var chapter_scene: PackedScene
 if OS.has_feature("web"):
  loading.ratio = -1.0
  await tree.create_timer(0.65).timeout
  chapter_scene = load(path) as PackedScene
 elif ResourceLoader.load_threaded_request(path, "PackedScene") == OK:
  var started := Time.get_ticks_msec()
  var progress := []
  var status := ResourceLoader.load_threaded_get_status(path, progress)
  while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
   loading.ratio = progress[0] if not progress.is_empty() else 0.0
   await tree.process_frame
   status = ResourceLoader.load_threaded_get_status(path, progress)
  if status == ResourceLoader.THREAD_LOAD_LOADED:
   chapter_scene = ResourceLoader.load_threaded_get(path) as PackedScene
  var wait_time := 0.65 - (Time.get_ticks_msec() - started) / 1000.0
  if wait_time > 0.0:
   loading.ratio = 1.0 if chapter_scene else 0.0
   await tree.create_timer(wait_time).timeout
 if chapter_scene and tree.change_scene_to_packed(chapter_scene) == OK:
  return
 layer.queue_free()
 loading_chapter = false
 detail_status.text = "Не удалось загрузить главу. Попробуй ещё раз."

func _input(event: InputEvent) -> void:
 if loading_chapter:
  return
 if event is InputEventKey and event.pressed and not event.echo:
  var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
  if key in [KEY_RIGHT,KEY_D]:
   _select(selected+1)
  elif key in [KEY_LEFT,KEY_A]:
   _select(selected-1)
  elif key in [KEY_ENTER,KEY_KP_ENTER]:
   _launch()

func _process(delta: float) -> void:
 phase_clock += delta
 queue_redraw()

func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
 var points := PackedVector2Array()
 for i in range(48):
  var angle := TAU*i/48
  points.append(center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y))
 draw_colored_polygon(points,color)

func _curve(a: Vector2,b: Vector2,bend: float = 30) -> PackedVector2Array:
 var points := PackedVector2Array()
 var tangent := (b-a).normalized().orthogonal()*bend
 for i in range(49):
  var t := float(i)/48
  points.append(a.lerp(b,t)+tangent*sin(t*PI))
 return points

func _motif(at: Vector2, scale_value: float = 1.0, tint: Color = GOLD) -> void:
 draw_set_transform(at,0,Vector2.ONE*scale_value)
 draw_line(Vector2(0,12),Vector2(0,-7),tint,1.5,true)
 draw_arc(Vector2(-6,-5),6,-PI*.75,PI*.75,18,tint,1.5,true)
 draw_arc(Vector2(6,-5),6,PI*.25,PI*1.75,18,tint,1.5,true)
 draw_polyline(PackedVector2Array([Vector2(-13,13),Vector2(0,5),Vector2(13,13)]),tint,1.5,true)
 draw_set_transform(Vector2.ZERO)

func _mountain(p: Vector2, extent: Vector2, shade: Color) -> void:
 _ellipse(p+Vector2(2,extent.y*.65),Vector2(extent.x,extent.y*.23),Color(.13,.25,.20,.14))
 var peak := p-Vector2(0,extent.y)
 var left := p+Vector2(-extent.x,extent.y*.55)
 var right := p+Vector2(extent.x,extent.y*.55)
 draw_colored_polygon(PackedVector2Array([left,p+Vector2(-extent.x*.52,-extent.y*.18),p+Vector2(-extent.x*.29,-extent.y*.6),peak,p+Vector2(extent.x*.43,-extent.y*.12),right]),shade)
 draw_colored_polygon(PackedVector2Array([peak,p+Vector2(extent.x*.43,-extent.y*.12),right,p+Vector2(extent.x*.08,extent.y*.55),p+Vector2(extent.x*.04,-extent.y*.45)]),shade.darkened(.23))
 draw_colored_polygon(PackedVector2Array([peak,p+Vector2(extent.x*.28,-extent.y*.42),p+Vector2(extent.x*.12,-extent.y*.5),p+Vector2(0,-extent.y*.36),p+Vector2(-extent.x*.13,-extent.y*.53),p+Vector2(-extent.x*.25,-extent.y*.44)]),Color("dfdfc4"))
 draw_line(p+Vector2(-extent.x*.45,-extent.y*.1),p+Vector2(-extent.x*.27,extent.y*.29),shade.lightened(.25),1.5,true)

func _yurt(p: Vector2, factor: float = 1.0) -> void:
 draw_set_transform(p,0,Vector2.ONE*factor)
 _ellipse(Vector2(1,17),Vector2(30,8),Color(.1,.2,.13,.23))
 draw_colored_polygon(PackedVector2Array([Vector2(-27,1),Vector2(-23,-12),Vector2(-9,-24),Vector2(8,-24),Vector2(24,-11),Vector2(28,1)]),Color("eee0b6"))
 draw_rect(Rect2(-27,0,55,20),Color("dccb9f"))
 draw_colored_polygon(PackedVector2Array([Vector2(8,-24),Vector2(24,-11),Vector2(28,1),Vector2(28,20),Vector2(12,20)]),Color("c5b38c"))
 draw_line(Vector2(-27,5),Vector2(28,5),Color("9b6047"),3,true)
 draw_rect(Rect2(-6,4,12,16),Color("5e5140"))
 draw_line(Vector2(-6,4),Vector2(6,4),Color("ac7650"),2,true)
 draw_line(Vector2(-10,-24),Vector2(8,-24),Color("a58152"),3,true)
 draw_set_transform(Vector2.ZERO)

func _horse(p: Vector2, factor: float = 1.0, direction: float = 1.0) -> void:
 draw_set_transform(p,0,Vector2(direction*factor,factor))
 _ellipse(Vector2(0,15),Vector2(22,5),Color(.1,.2,.12,.19))
 _ellipse(Vector2(0,0),Vector2(17,7),Color("805a3d"))
 draw_line(Vector2(-11,3),Vector2(-13,17),Color("514231"),3,true)
 draw_line(Vector2(10,3),Vector2(12,17),Color("514231"),3,true)
 draw_line(Vector2(11,-1),Vector2(18,-15),Color("805a3d"),8,true)
 draw_line(Vector2(18,-15),Vector2(26,-13),Color("805a3d"),6,true)
 draw_line(Vector2(-16,-1),Vector2(-25,6),Color("514231"),3,true)
 draw_line(Vector2(16,-19),Vector2(18,-15),Color("514231"),2,true)
 draw_set_transform(Vector2.ZERO)

func _tree(p: Vector2, size_value: float = 1.0) -> void:
 draw_set_transform(p,0,Vector2.ONE*size_value)
 _ellipse(Vector2(3,1),Vector2(13,5),Color(.1,.25,.18,.2))
 draw_line(Vector2.ZERO,Vector2(0,-21),Color("675a3b"),3,true)
 draw_colored_polygon(PackedVector2Array([Vector2(-13,-6),Vector2(-7,-18),Vector2(-9,-18),Vector2(0,-37),Vector2(9,-18),Vector2(7,-18),Vector2(13,-6)]),Color("3f6b50"))
 draw_polyline(PackedVector2Array([Vector2(-8,-11),Vector2(-3,-22),Vector2(0,-31)]),Color("82a176"),1.5,true)
 draw_set_transform(Vector2.ZERO)

func _lake() -> void:
 var center := Vector2(168,319)
 var coast := PackedVector2Array()
 var water := PackedVector2Array()
 for i in range(72):
  var angle := TAU*i/72
  var wobble := 1.0+sin(angle*3)*.09+cos(angle*7)*.04
  coast.append(center+Vector2(cos(angle)*105,sin(angle)*63)*wobble)
  water.append(center+Vector2(cos(angle)*98,sin(angle)*56)*wobble)
 draw_colored_polygon(coast,Color("cbbd88"))
 draw_colored_polygon(water,Color("397e82"))
 _ellipse(center+Vector2(-18,-8),Vector2(67,36),Color("5caaa2"))
 _ellipse(center+Vector2(-27,-14),Vector2(38,20),Color("75b7aa"))
 for i in range(13):
  var x := 104.0+(i*43)%112
  var y := 285.0+i*5
  draw_line(Vector2(x+sin(phase_clock*.4+i)*2,y),Vector2(x+13+i%3*6,y),Color("acd7c1"),1,true)
 for i in range(18):
  var p := Vector2(95+i*6,365+sin(i*.4)*8)
  draw_line(p,p+Vector2(-2,-8-i%3),Color("627b4d"),1.5,true)

func _chapter_icon(chapter: int, center: Vector2, size_value: float, color: Color) -> void:
 draw_set_transform(center,0,Vector2.ONE*size_value)
 match chapter:
  0:
   draw_arc(Vector2(0,-3),12,0,PI,30,color,3,true)
   draw_line(Vector2(-12,-3),Vector2(-12,-15),color,3,true)
   draw_line(Vector2(12,-3),Vector2(12,-15),color,3,true)
   for p in [Vector2(-11,-12),Vector2(-7,2),Vector2(7,2),Vector2(11,-12)]:
    draw_circle(p,1.4,INK)
  1:
   draw_polyline(PackedVector2Array([Vector2(-20,9),Vector2(-14,-6),Vector2(14,-6),Vector2(20,9)]),color,3,true)
   draw_line(Vector2(-19,0),Vector2(19,0),color,2,true)
   for x in range(-12,13,6):
    draw_line(Vector2(x,-9),Vector2(x,8),color,2,true)
   draw_polyline(PackedVector2Array([Vector2(-21,15),Vector2(-10,12),Vector2(0,15),Vector2(10,12),Vector2(21,15)]),color,1.5,true)
  2:
   for side in [-1,1]:
    draw_line(Vector2(-18*side,17),Vector2(18*side,-18),color,3,true)
    draw_colored_polygon(PackedVector2Array([Vector2(20*side,-23),Vector2(18*side,-12),Vector2(12*side,-17)]),color)
  3:
   draw_colored_polygon(PackedVector2Array([Vector2(-19,-15),Vector2(19,-15),Vector2(15,8),Vector2(0,22),Vector2(-15,8)]),color)
   draw_line(Vector2(0,-11),Vector2(0,15),INK,2,true)
  4:
   for y in [-10,5]:
    draw_polyline(PackedVector2Array([Vector2(19,y-4),Vector2(4,y-4),Vector2(4,y-10),Vector2(-19,y+2),Vector2(4,y+12),Vector2(4,y+5),Vector2(19,y+5)]),color,2,true)
 draw_set_transform(Vector2.ZERO)

func _draw_lock(center: Vector2) -> void:
 draw_arc(center+Vector2(0,-3),8,PI,TAU,20,Color("a7b69c"),2,true)
 draw_style_box(_style(Color("61755d"),Color("a7b69c"),3),Rect2(center+Vector2(-11,-3),Vector2(22,18)))
 draw_circle(center+Vector2(0,4),2,Color("324a3b"))
 draw_line(center+Vector2(0,4),center+Vector2(0,9),Color("324a3b"),2,true)

func _draw() -> void:
 # Quiet midnight frame around an illustrated cartographic surface.
 draw_rect(Rect2(0,0,1280,720),Color("102d2a"))
 for row in range(24):
  draw_rect(Rect2(0,row*5,1280,5),Color("1d4038").lerp(Color("102d2a"),row/24.0))
 draw_line(Vector2(43,111),Vector2(1237,111),Color("5d7861"),1,true)
 _motif(Vector2(782,66),1.2,Color("b99e65"))
 for x in range(46,1230,30):
  if x>910:
   _motif(Vector2(x,702),.42,Color(.7,.62,.39,.20))
 draw_style_box(_style(Color(0,0,0,.18),Color(0,0,0,0),18),Rect2(42,136,872,536))
 draw_style_box(_style(Color("9ba36e"),Color("bba773"),18),Rect2(38,129,872,533))
 draw_texture_rect(preload("res://art/animation/journey-map.png"),Rect2(38,129,872,533),false)
 # Compass and the original ram-horn ornament set the cartographic language.
 var compass := Vector2(101,213)
 draw_circle(compass,23,Color(.22,.39,.29,.11))
 draw_arc(compass,22,0,TAU,48,Color("cfc391"),1,true)
 draw_colored_polygon(PackedVector2Array([compass+Vector2(0,-19),compass+Vector2(-6,10),compass,compass+Vector2(6,10)]),Color("f0e2b7"))
 draw_line(compass+Vector2(-12,0),compass+Vector2(12,0),Color("c8bd8b"),1,true)
 for segment in range(4):
  var path := _curve(NODE_POSITIONS[segment],NODE_POSITIONS[segment+1],31 if segment%2 else -34)
  var opened := segment+1<unlocked_count
  draw_polyline(path,Color(.16,.28,.18,.22),11,true)
  draw_polyline(path,Color("e6cb8d") if opened else Color("8d9566"),5,true)
  for i in range(3,path.size()-2,3):
   draw_circle(path[i],1.6,Color("fbebba") if opened else Color("c3bd8a"))
  if opened:
   var travel := fposmod(phase_clock*.18,1.0)
   var point: Vector2 = path[int(travel*(path.size()-1))]
   draw_circle(point,6,Color(1,.86,.48,.13))
   draw_circle(point,2.3,Color("fff1be"))
 # Path medallions show a distinctive place symbol; numbers remain readable.
 for i in range(5):
  var p: Vector2 = NODE_POSITIONS[i]
  var available := can_launch(i)
  _ellipse(p+Vector2(0,19),Vector2(44,21),Color(.09,.21,.15,.20))
  if i==selected:
   var pulse := sin(phase_clock*2.3)
   draw_circle(p,48+pulse,Color(1,.84,.46,.10))
   draw_arc(p,47+pulse,0,TAU,72,GOLD,2,true)
   draw_arc(p,52,PI*.14,PI*.86,32,Color(1,.87,.55,.4),1,true)
   for corner in range(4):
    var angle := PI*0.25+corner*PI*0.5
    var edge := p + Vector2(cos(angle),sin(angle))*53.0
    draw_colored_polygon(PackedVector2Array([edge+Vector2(0,-4),edge+Vector2(4,0),edge+Vector2(0,4),edge+Vector2(-4,0)]),Color("f1ce87"))
  draw_circle(p+Vector2(0,4),37,Color(.06,.17,.12,.33))
  draw_circle(p,37,Color("e4c17d") if available else Color("9baa7d"))
  draw_circle(p,33,Color("244e42") if available else Color("506c50"))
  draw_arc(p,30,PI,TAU,40,Color("5b8565") if available else Color("718362"),1.5,true)
  if available:
   _chapter_icon(i,p,0.8,CREAM)
  else:
   _draw_lock(p)
  draw_circle(p+Vector2(-25,-28),12,INK)
  draw_arc(p+Vector2(-25,-28),12,0,TAU,30,GOLD if available else Color("879a73"),1,true)
  var numeral: String = ROMAN[i]
  var font := ThemeDB.fallback_font
  var width := font.get_string_size(numeral,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
  draw_string(font,p+Vector2(-25-width/2,-24),numeral,HORIZONTAL_ALIGNMENT_LEFT,-1,12,CREAM if available else Color("bdc8aa"))
  var caption_at := p+Vector2(-83,51) if i == 4 else p+Vector2(-108,51)
  var caption_size := Vector2(191,29) if i == 4 else Vector2(216,29)
  draw_style_box(_style(Color("234637") if available else Color("657b54"),Color("aa9c68"),6),Rect2(caption_at,caption_size))
  if completed.size()>i and completed[i] and available:
   draw_circle(p+Vector2(27,-25),11,GOLD)
   draw_polyline(PackedVector2Array([p+Vector2(22,-25),p+Vector2(26,-21),p+Vector2(33,-29)]),INK,2.5,true)
 # Separate editorial card; a single strong action leaves the map uncluttered.
 draw_style_box(_style(Color(0,0,0,.18),Color(0,0,0,0),18),Rect2(934,135,309,534))
 draw_style_box(_style(Color("193b32"),Color("648066"),18),Rect2(929,129,309,533))
 draw_line(Vector2(953,350),Vector2(1214,350),Color("3f6250"),1,true)
 draw_line(Vector2(953,581),Vector2(1214,581),Color("3f6250"),1,true)
 var vignette:=Rect2(953,168,263,62)
 var plate:=preload("res://scripts/chapter_presentation.gd")
 draw_texture_rect_region(plate.CHAPTER_COVERS,vignette,plate.cover_region(selected,vignette.size))
 draw_rect(vignette,GOLD,false,1)
 for i in range(5):
  var at := Vector2(1138+i*16,565)
  var diamond := PackedVector2Array([at+Vector2(0,-4),at+Vector2(4,0),at+Vector2(0,4),at+Vector2(-4,0)])
  draw_colored_polygon(diamond,GOLD if i<=selected else Color("3c5c49"))
 # Rounded corner caps are drawn after terrain to keep the sheet edge clean.
 for p in [Vector2(55,145),Vector2(893,145),Vector2(55,646),Vector2(893,646)]:
  _motif(p,.6,Color("c2b17d"))
