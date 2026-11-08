extends Node
## Original procedural foley: no external recordings or runtime network access.
## Chapters use grass, gravel, stone, dry earth and hard stone respectively.
const CUES := ["jump", "spear", "hit", "hurt", "pickup", "charge", "win", "step", "land", "dodge", "heal", "enemy", "unlock", "bird", "water", "gate", "break", "tutorial", "platform","hoof","bow","horse"]
const RATE := 22050
const PROFILES := [
 {"pitch": 0.94, "grit": 0.28, "body": 88.0},
 {"pitch": 1.00, "grit": 0.60, "body": 120.0},
 {"pitch": 0.88, "grit": 0.78, "body": 165.0},
 {"pitch": 1.08, "grit": 0.48, "body": 106.0},
 {"pitch": 0.82, "grit": 0.88, "body": 195.0}
]
var enabled := true
var chapter := 1
var players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
static var _profile_cache: Dictionary = {}
var _step_count := 0

func _ready() -> void:
 for i in range(10):
  var player := AudioStreamPlayer.new()
  player.volume_db = -13
  add_child(player)
  players.append(player)
 set_chapter(chapter)

func set_chapter(number: int) -> void:
 chapter = clampi(number, 1, 5)
 if not _profile_cache.has(chapter):
  var bank: Dictionary = {}
  for cue in CUES:
   var path:="res://art/audio/chapter%d/%s.res"%[chapter,cue]
   bank[cue] = load(path) if ResourceLoader.exists(path) else _make_sound(cue)
  var path:="res://art/audio/chapter%d/step_alt.res"%chapter
  bank["step_alt"] = load(path) if ResourceLoader.exists(path) else _make_sound("step", true)
  _profile_cache[chapter] = bank
 sounds = _profile_cache[chapter]

func play(name: String) -> void:
 if not enabled or not sounds.has(name):
  return
 var cue := name
 if name == "step":
  _step_count += 1
  cue = "step_alt" if _step_count % 2 else "step"
 var target: AudioStreamPlayer
 for player in players:
  if not player.playing:
   target = player
   break
 # Steps never interrupt a hit or victory. Important action cues can replace
 # the oldest short cue when all channels are occupied.
 if target == null:
  if name in ["step", "bird", "water", "platform"]:
   return
  target = players[0] if not players.is_empty() else null
 if target == null:
  return
 target.stream = sounds[cue]
 target.pitch_scale = 0.98 if cue == "step_alt" else 1.0
 target.volume_db = -27 if name == "bird" else -25 if name == "water" else -24 if name == "platform" else -20 if name in ["step", "tutorial"] else -17 if name in ["land", "jump"] else -15 if name in ["gate", "break"] else -13
 target.play()

func _make_sound(name: String, alternate: bool = false) -> AudioStreamWAV:
 var profile: Dictionary = PROFILES[chapter - 1]
 var duration := 0.18
 match name:
  "horse": duration=0.85
  "hoof": duration=0.19
  "bow": duration=0.15
  "step": duration = 0.085
  "land": duration = 0.16
  "jump": duration = 0.15
  "spear": duration = 0.22
  "hit": duration = 0.20
  "hurt": duration = 0.28
  "dodge": duration = 0.28
  "charge": duration = 0.40
  "enemy": duration = 0.23
  "pickup", "heal": duration = 0.42
  "unlock": duration = 0.70
  "win": duration = 1.25
  "bird": duration = 0.72
  "water": duration = 0.90
  "gate": duration = 0.68
  "break": duration = 0.30
  "tutorial": duration = 0.19
  "platform": duration = 0.24
 var data := PackedByteArray()
 data.resize(int(duration * RATE) * 2)
 var rng := RandomNumberGenerator.new()
 rng.seed = 5903 + chapter * 1009 + int(name.hash()) + (711 if alternate else 0)
 var low_noise := 0.0
 var last_noise := 0.0
 var phase := 0.0
 for i in range(data.size() / 2):
  var t := float(i) / RATE
  var progress := t / duration
  var noise := rng.randf_range(-1, 1)
  low_noise = lerpf(low_noise, noise, 0.10 + float(profile.grit) * 0.23)
  var high_noise := noise - last_noise
  last_noise = noise
  var value := 0.0
  var pitch: float = profile.pitch
  var attack := minf(1, t * 500)
  var decay := exp(-t * 25)
  match name:
   "horse":
    phase+=TAU*(580-260*progress+70*sin(t*38))/RATE
    value=(sin(phase)+0.3*sin(phase*2.01))*pow(sin(PI*progress),0.65)*0.35
   "hoof":
    var second:=maxf(0,t-0.072)
    value=(sin(TAU*78*t)*0.7+low_noise*0.4)*exp(-t*36)
    if t>0.072:
     value+=(sin(TAU*116*second)*0.6+high_noise*0.32)*exp(-second*41)
   "bow":
    value=(sin(TAU*(590*t-470*t*t))*0.58+high_noise*0.2)*exp(-t*32)
   "step", "land":
    var weight := 1.4 if name == "land" else 1.0
    var body: float = profile.body * (0.92 if alternate else 1.0)
    value = (sin(TAU * body * t) * 0.52 + low_noise * (0.5 + float(profile.grit)) + high_noise * float(profile.grit) * 0.12) * decay * weight
   "jump":
    value = low_noise * sin(PI * progress) * 0.48 + sin(TAU * (135 * pitch * t - 170 * t * t)) * decay * 0.35
   "spear", "dodge":
    # A soft attack and fast airy swish, rather than a pitched electronic beep.
    var swish := pow(sin(PI * progress), 2)
    value = (low_noise * 0.9 + high_noise * 0.16) * swish
    if name == "spear":
     value += sin(TAU * 190 * pitch * t) * decay * 0.22
   "hit":
    value = (sin(TAU * 92 * pitch * t) * 0.7 + low_noise * 0.8 + sin(TAU * 680 * pitch * t) * 0.12) * exp(-t * 24)
   "hurt":
    phase += TAU * (125 - progress * 45) * pitch / RATE
    value = (sin(phase) * 0.55 + sin(phase * 2.03) * 0.15 + low_noise * 0.25) * sin(PI * progress) * exp(-t * 5)
   "charge":
    var pulse := 0.35 + 0.65 * pow(maxf(0, sin(TAU * 14 * t)), 3)
    value = (low_noise * 0.8 + sin(TAU * 64 * pitch * t) * 0.38) * pulse * sin(PI * progress)
   "enemy":
    value = (sin(TAU * 145 * pitch * t) * 0.5 + sin(TAU * 213 * pitch * t) * 0.3 + low_noise * 0.4) * decay
   "bird":
    # A rasped two-part raptor call: falling formants, breath and irregular trill.
    var local := t-0.045 if t<0.31 else t-0.34
    var span := 0.24 if t<0.31 else 0.31
    if local>0 and local<span:
     var envelope:=pow(sin(PI*local/span),0.7)
     var bend:=1.0-local/span
     var frequency: float=(1050+760*bend+90*sin(TAU*32*t))*pitch
     phase+=TAU*frequency/RATE
     var rasp:=sin(phase+sin(phase*0.49)*0.9)*0.24+sin(phase*2.01)*0.11
     value=(rasp+high_noise*0.14+low_noise*0.10)*envelope*(0.76+0.24*sin(TAU*46*t))
   "water":
    # Low stream rush with quiet irregular bubble resonances, never a constant hiss.
    var bubble_time:=fmod(t,0.073)
    var bubble_index:=int(t/0.073)
    var bubble_frequency: float=(760+430*sin(bubble_index*2.31)+220*cos(bubble_index*1.27))*pitch
    var bubble:=sin(TAU*(bubble_frequency*bubble_time-950*bubble_time*bubble_time))*exp(-bubble_time*62)*0.12
    value=(low_noise*0.62+high_noise*0.055+bubble)*(0.72+0.16*sin(TAU*3.7*t))*pow(sin(PI*progress),0.45)
   "gate":
    # Timber strains as the rope raises it, then settles with two wooden knocks.
    phase+=TAU*(92+24*sin(TAU*4.5*t)+11*sin(TAU*17*t))*pitch/RATE
    var friction:=sin(phase+sin(phase*0.23)*0.6)*0.18+low_noise*0.32
    var creak:=friction*pow(sin(PI*progress),0.8)*(0.55+0.45*absf(sin(TAU*11*t)))
    var first_knock: float=(sin(TAU*126*pitch*t)*0.43+low_noise*0.30)*exp(-t*43)
    var last_time:=maxf(0,t-0.52)
    var last_knock: float=0.0
    if t>0.52:
     last_knock=(sin(TAU*108*pitch*last_time)*0.37+low_noise*0.22)*exp(-last_time*42)
    value=creak+first_knock+last_knock
   "break":
    # Short crack, splinters and two diminishing wood-body resonances.
    var crack: float=(high_noise*0.40+noise*0.45)*exp(-t*70)
    var fragments:=absf(sin(TAU*37*t))*low_noise*0.55*exp(-t*13)
    var body: float=(sin(TAU*165*pitch*t)*0.37+sin(TAU*309*pitch*t)*0.16)*exp(-t*27)
    value=crack+fragments+body
   "tutorial":
    # A page-like brush and soft wooden tap rather than a notification beep.
    var brush:=low_noise*0.28*pow(sin(PI*progress),2)
    var tap: float=(sin(TAU*230*pitch*t)*0.23+high_noise*0.12)*exp(-t*55)
    value=brush+tap
   "platform":
    # A restrained load-bearing plank creak for a landing, not an ambient loop.
    phase+=TAU*(145+35*sin(TAU*6*t))*pitch/RATE
    var rub: float=(sin(phase)*0.17+sin(phase*2.07)*0.055+low_noise*0.24)*sin(PI*progress)
    value=rub*(0.6+0.4*absf(sin(TAU*23*t)))+sin(TAU*91*pitch*t)*exp(-t*35)*0.22
   "pickup", "heal", "unlock", "win":
    # Short plucked notes for positive feedback; longer cues form a cadence.
    var note_length := 0.16 if name in ["unlock", "win"] else 0.14
    var note_index := int(t / note_length)
    var local_t := fmod(t, note_length)
    var notes := [1.0, 1.25, 1.5, 2.0, 1.5, 2.0, 2.5, 3.0]
    var base := 330.0 if name == "win" else 440.0 if name == "heal" else 550.0
    var frequency: float = base * notes[mini(notes.size() - 1, note_index)] * pitch
    value = (sin(TAU * frequency * local_t) * 0.50 + sin(TAU * frequency * 2.01 * local_t) * 0.16) * exp(-local_t * 23) * minf(1, local_t * 700)
  var fade := minf(1, (duration - t) * 250)
  value *= attack * fade
  data.encode_s16(i * 2, int(clampf(value, -0.95, 0.95) * 26000))
 var sound := AudioStreamWAV.new()
 sound.format = AudioStreamWAV.FORMAT_16_BITS
 sound.mix_rate = RATE
 sound.data = data
 return sound
