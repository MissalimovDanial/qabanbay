extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var audio = load("res://scripts/audio.gd").new()
 root.add_child(audio)
 audio.enabled = false
 var previous := PackedByteArray()
 for chapter in range(1, 6):
  audio.set_chapter(chapter)
  for cue in audio.CUES:
   var sound: AudioStreamWAV = audio.sounds[cue]
   assert(sound.data.size() > 1000, "%d/%s contains PCM" % [chapter, cue])
   assert(sound.data.count(0) < sound.data.size() - 100, "%d/%s is audible" % [chapter, cue])
  assert(audio.sounds.step.data != previous, "Each chapter has distinct footfalls")
  previous = audio.sounds.step.data
 audio.set_chapter(2)
 assert(audio.chapter == 2 and audio.sounds.has("heal"))
 assert(audio.CUES.size()==21,"Twenty-one named action and atmosphere cues")
 for cue in ["bird","water","gate","break","tutorial","platform","hoof","bow"]:
  assert(audio.sounds.has(cue),"Atmosphere cue registered: "+cue)
 assert(audio.sounds.bird.data!=audio.sounds.water.data,"Bird and stream have distinct waveforms")
 assert(audio.sounds.gate.data!=audio.sounds.platform.data,"Gate strain and plank creak differ")
 print("Audio: five distinct chapter banks, 21 cues each, PCM checks passed")
 audio.queue_free()
 quit()
