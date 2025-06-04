extends CanvasLayer

func _on_proto_controller_jump_updated(current: Variant, max: Variant) -> void:
	$JumpLabel.text = "Jumps: %d / %d" % [current, max]


func _on_proto_controller_accel_updated(current: Variant) -> void:
	$AccelLabel.text = "Accel: %d" % [current]


func _on_proto_controller_state_updated(state: Variant) -> void:
	$StateLabel1.text = "State: %s" % [state]
