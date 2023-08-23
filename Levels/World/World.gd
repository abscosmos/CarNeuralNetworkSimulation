class_name World extends BaseLevel;

@onready var hud: HUD = $HUD;

func _ready() -> void:
	hud.menu_button.button_down.connect(func(): _change_level(LevelManager.LevelTypes.MENU));
	config_params.has_started_game = true;
