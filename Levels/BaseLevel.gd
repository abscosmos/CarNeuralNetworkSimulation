class_name BaseLevel extends Node;

signal level_changed(level: LevelManager.LevelTypes);

@export var level_type: LevelManager.LevelTypes;

func _free_level():
	queue_free();

func _change_level(new_level_type: LevelManager.LevelTypes) -> void:
	emit_signal("level_changed", new_level_type);

func _load_data_from_scene(data: Dictionary) -> void:
	pass;

func _get_data_to_transfer() -> Dictionary:
	return {};
