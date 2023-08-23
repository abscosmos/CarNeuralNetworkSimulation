class_name LevelManager extends Node;

@export var current_level: Node:
	set(lvl):
		current_level = lvl;
		current_level.level_changed.connect(on_level_change);

enum LevelTypes {
	MENU,
	WORLD
}

const LEVEL_SCENE_PATHS : Dictionary = {
	LevelTypes.MENU: "res://UI/MainMenu/MainMenu.tscn",
	LevelTypes.WORLD: "res://Levels/World/World.tscn",
}

func on_level_change(calling_level: LevelTypes) -> void:
	var next_level_path: String = LEVEL_SCENE_PATHS[calling_level];
	
	var previous_level : Node = current_level;
	current_level = load(next_level_path).instantiate();
	add_child(current_level);
	transfer_data_to_scene(previous_level, current_level);
	previous_level._free_level();
	previous_level = null;

func transfer_data_to_scene(old_scene: Node, new_scene: Node) -> void:
	new_scene._load_data_from_scene(old_scene._get_data_to_transfer());
	
