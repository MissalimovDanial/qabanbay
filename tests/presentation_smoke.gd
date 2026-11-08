extends SceneTree
const Presentation = preload("res://scripts/chapter_presentation.gd")
const Chapters = preload("res://scripts/chapter_data.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 for number in range(1,6):
  var cover = Presentation.new()
  root.add_child(cover)
  cover.configure(number,Chapters.stage(number),false,"")
  check(cover.get_node("StartButton") is Button,"Chapter %d has primary button" % number)
  check(cover.get_node("MapButton") is Button,"Chapter %d has map button" % number)
  check(cover.chapter == number and cover.title_label.text == Chapters.CHAPTERS[number-1].title.to_upper(),"Chapter %d has unique title" % number)
  check(cover.hook_label.text == Chapters.CHAPTERS[number-1].hook,"Chapter %d has unique story hook" % number)
  check(cover.status_label.text.begins_with("НОВОЕ"),"Chapter %d fresh status" % number)
  check(cover.start_button.position.y+cover.start_button.size.y<=720,"Chapter %d action fits viewport" % number)
  cover.configure(number,Chapters.stage(number),true,"1:23")
  check(cover.status_label.text.contains("1:23") and cover.start_button.text.begins_with("Пройти"),"Chapter %d replay status" % number)
  var callbacks := {"start":false,"map":false}
  cover.start_requested.connect(func(): callbacks.start=true)
  cover.map_requested.connect(func(): callbacks.map=true)
  cover.start_button.pressed.emit()
  cover.map_button.pressed.emit()
  check(callbacks.start and callbacks.map,"Chapter %d callbacks work" % number)
  cover.free()
 print("Chapter presentation: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
