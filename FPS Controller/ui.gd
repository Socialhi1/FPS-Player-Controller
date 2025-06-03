extends CanvasLayer

func _on_proto_controller_jump_updated(current: Variant, max: Variant) -> void:
	$JumpLabel.text = "Jumps: %d / %d" % [current, max]
