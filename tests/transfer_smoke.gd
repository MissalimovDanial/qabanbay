extends SceneTree
func _initialize() -> void:
 var transfer = load("res://scripts/progress_transfer.gd")
 var path := "user://transfer_test.cfg"
 assert(not transfer.apply_payload(path,{"cleared":6}))
 assert(not transfer.apply_payload(path,{"cleared":-1}))
 assert(not transfer.apply_payload(path,{"cleared":2.5}))
 assert(not transfer.apply_payload(path,{"cleared":"5"}))
 assert(transfer.apply_payload(path,{"cleared":3,"times":[50,70,90],"muted":true}))
 var state: Dictionary = transfer.snapshot(path)
 assert(state.cleared == 3 and state.muted and state.times[2] == 90)
 assert(transfer.apply_payload(path,{"cleared":1,"times":[80],"muted":false}))
 state = transfer.snapshot(path)
 assert(state.cleared == 3 and state.times[0] == 50 and not state.muted)
 print("Progress handoff: 9 checks passed")
 quit()
