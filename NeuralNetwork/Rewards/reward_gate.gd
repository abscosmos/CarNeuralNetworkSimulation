extends Area2D

@export var points : float;
signal rewardGatePassed;

func _on_body_entered(body: Node2D) -> void:
	emit_signal("rewardGatePassed", body, points);
