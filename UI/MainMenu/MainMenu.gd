class_name MainMenuLevel extends BaseLevel;

const LayerNodeScene: PackedScene = preload("res://UI/MainMenu/LayerNode.tscn");

# CREATION DIALOG PARAMS
@onready var reset_brain_check_box: CheckBox = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/ResetBrain/CheckBox;
@onready var cars_per_generation_spin_box: SpinBox = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/CarsPerGeneration/SpinBox;
@onready var mutation_slider: HSlider = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/Mutation/HSlider;
@onready var mutation_slider_value: Label = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/Mutation/SliderValue;
@onready var generation_time_spin_box: SpinBox = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/GenerationTime/HBoxContainer/SpinBox
@onready var generation_time_check_box: CheckBox = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/GenerationTime/HBoxContainer/CheckBox
@onready var purge_generation_spin_box: SpinBox = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/PurgeGeneration/HBoxContainer/SpinBox;
@onready var purge_generation_check_box: CheckBox = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/PurgeGeneration/HBoxContainer/CheckBox;
@onready var auto_clear_dead_spin_box: SpinBox = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/AutoClearDead/HBoxContainer/SpinBox;
@onready var auto_clear_dead_check_box: CheckBox = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/AutoClearDead/HBoxContainer/CheckBox;
@onready var multiple_spawnpoints_check_box: CheckBox = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/MultipleSpawnPoints/CheckBox;
@onready var use_compute_shaders_check_box: CheckBox = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/UseComputeShaders/CheckBox;

# FORM SUMBIT
@onready var start_simulation_button: Button = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/SubmitForm/StartButton;
@onready var reset_settings_button: Button = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/SubmitForm/ResetSettings;

# LAYER EDITOR
@onready var brain_structure: HBoxContainer = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/BrainStructure
@onready var brain_structure_label: Label = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/BrainStructure/StructureDisplay/HBoxContainer/MarginContainer/Label
@onready var layer_editor: HBoxContainer = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/LayerEditor
@onready var hidden_layers_container: HFlowContainer = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/LayerEditor/Hidden

# FILE SYSTEM
@onready var load_brain_container: HBoxContainer = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/LoadBrain;
@onready var load_brain_metadata: Label = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/LoadBrain/CenterContainer/Metadata;
@onready var load_file_dialog: FileDialog = $Dialogs/LoadFile;
@onready var select_folder_dialog: FileDialog = $Dialogs/SelectDirectory;
@onready var brain_data_not_found_dialog: AcceptDialog = $Dialogs/BrainDataNotFound;
@onready var invalid_map_dialog: AcceptDialog = $Dialogs/InvalidMap;
@onready var path_tooltip: PanelContainer = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/LoadBrain/PathTooltip;
@onready var save_directory_label: Label = $Control/MarginContainer/CenterContainer/HBoxContainer/ConfigureSimulation/MarginContainer/VBoxContainer/Parameters/SaveDirectory/StructureDisplay/MarginContainer/Label

# LEVEL SELECT
@onready var left_level_display: PanelContainer = $Control/MarginContainer/CenterContainer/HBoxContainer/VBoxContainer/MapSelection/MarginContainer/VBoxContainer/CenterContainer/MarginContainer/HBoxContainer/HBoxContainer/Left;
@onready var main_level_display: PanelContainer = $Control/MarginContainer/CenterContainer/HBoxContainer/VBoxContainer/MapSelection/MarginContainer/VBoxContainer/CenterContainer/MarginContainer/HBoxContainer/HBoxContainer/Main;
@onready var right_level_display: PanelContainer = $Control/MarginContainer/CenterContainer/HBoxContainer/VBoxContainer/MapSelection/MarginContainer/VBoxContainer/CenterContainer/MarginContainer/HBoxContainer/HBoxContainer/Right;
@onready var level_selected_label: Label = $Control/MarginContainer/CenterContainer/HBoxContainer/VBoxContainer/MapSelection/MarginContainer/VBoxContainer/CenterContainer/MarginContainer/HBoxContainer/HBoxContainer/Main/MarginContainer/Label;

@export var DEFAULT_LAYER_NODE_COUNT: int = 1;
@export var MAX_HIDDEN_LAYERS: int = 11;
@export var LOAD_FILE_DIALOG_SIZE := Vector2(400,500);

const defaultSimulationParameters: Dictionary = {
	resetBrain = true,
	brainStructure = [3,5,4],
	carsPerGeneration = 100,
	mutationPerGeneration = 25,
	useGenerationTimeLimit = true,
	generationTimeLimit = 30.0,
	usePurgeGenerationTime = true,
	purgeGenerationTime = 1.0,
	useAutoClearDeadTime = false,
	autoClearDeadTime = 5.0,
	useMultipleSpawnPoints = true,
	useComputeShaders = true,
	selectedStartingLevel = 0,
	initialLoadPath = "/CarNeuralNetworkSimulation/saved_brain.braindata",
	saveDirectory = "/CarNeuralNetworkSimulation/",
	saveFileName = "saved_brain.braindata",
	saveFileHeader = "#[Car Simulation Brain Save File]",
};

var level_select_images: Array = [
	load("res://UI/Maps/level1.png"),
	load("res://UI/Maps/level2.png"),
]

const valid_maps: Array[int] = [0];

var selectedInitialLoadPath: String;
var isInitialLoadPathValid: bool;
var selected_level: int;

var selectedSaveDirectory: String;

func _ready() -> void:
	
	if !config_params.has_started_game:
		reset_params(defaultSimulationParameters);
	
	load_parameters_into_dialog();
	DirAccess.make_dir_absolute(selectedSaveDirectory);
	load_file_dialog.current_dir = config_params.brain_data_save_directory;

# INITIAL PAGE
func _on_quit_button_pressed() -> void:
	get_tree().quit();

# CREATION DIALOG PARAMS
func _on_reset_brain_check_box_update() -> void:
	brain_structure.visible = reset_brain_check_box.button_pressed;
	load_brain_container.visible = !reset_brain_check_box.button_pressed;
	layer_editor.visible = false;

func _on_mutation_slider_update(value: float) -> void:
	mutation_slider_value.text = str(value) + "%";

func _on_purge_generation_check_box_update() -> void:
	purge_generation_spin_box.visible = purge_generation_check_box.button_pressed;

func _on_auto_clear_dead_check_box_update() -> void:
	auto_clear_dead_spin_box.visible = auto_clear_dead_check_box.button_pressed;

func _on_generation_time_check_box_update() -> void:
	generation_time_spin_box.visible = generation_time_check_box.button_pressed;

# LAYER EDITOR
func _on_open_layer_editor_button_pressed() -> void:
	layer_editor.visible = !layer_editor.visible;

func _on_new_layer_button_pressed() -> void:
	create_layer_node(DEFAULT_LAYER_NODE_COUNT);

func on_layer_editor_update() -> void:
	brain_structure_label.text = str(get_array_from_layer_editor()).replace(" ", "");

func get_array_from_layer_editor() -> Array[int]:
	var layerNodes: Array[Node] = hidden_layers_container.get_children();
	var structure: Array[int] = [];
	structure.resize(layerNodes.size() + 1);
	structure[0] = 3;
	
	for i in range(layerNodes.size() -1):
		structure[i+1] = layerNodes[i].layer_value;
	structure[-1] = 4;
	return structure;

func create_layer_node(value: int):
	if !((hidden_layers_container.get_child_count() - 1) < MAX_HIDDEN_LAYERS): return;
	var layerNode: NetworkLayerNode = LayerNodeScene.instantiate();
	layerNode.layer_update.connect(on_layer_editor_update);
	layerNode.delete_layer_node.connect(remove_layer_node);
	hidden_layers_container.add_child(layerNode);
	hidden_layers_container.move_child(layerNode, hidden_layers_container.get_child_count() -2);
	layerNode.layer_value = value;
	on_layer_editor_update();

func remove_layer_node(node: NetworkLayerNode) -> void:
	hidden_layers_container.remove_child(node);
	node.queue_free()
	on_layer_editor_update();

func setup_layer_editor(structure: Array):
	structure.pop_front();
	structure.pop_back();
	
	while hidden_layers_container.get_child_count() > 1:
		remove_layer_node(hidden_layers_container.get_children()[0]);
	
	while !structure.is_empty():
		create_layer_node(structure.pop_front());

# CREATION DIALOG SUBMIT
func _on_start_simulation_button_pressed() -> void:
	if !isInitialLoadPathValid && !reset_brain_check_box.button_pressed:
		brain_data_not_found_dialog.visible = true;
		return;
	if !selected_level in valid_maps:
		invalid_map_dialog.visible = true;
		return;
	set_config_params();
	_change_level(LevelManager.LevelTypes.WORLD);

func _on_reset_settings_pressed() -> void:
	reset_params(defaultSimulationParameters);
	load_parameters_into_dialog();

# FILE SYSTEM
func _on_open_load_brain_button_pressed():
	load_file_dialog.visible = true;

func set_load_brain_info_display(path: String) -> bool:
	selectedInitialLoadPath = path;
	var data: Array[Dictionary] = load_brain_from_file(path);
	if data.size() == 0:
		path_tooltip.visible = false;
		load_brain_metadata.text = "Brain Data Not Found";
		load_brain_metadata.modulate = Color(1, 0.5, 0.5, 0.65);
		path_tooltip.visible = false;
		isInitialLoadPathValid = false;
		return false;
	
	path_tooltip.visible = true;
	path_tooltip.tooltip_text = ProjectSettings.globalize_path(path);
	set_metadata_label_info(data, false);
	isInitialLoadPathValid = true;
	
	load_brain_metadata.modulate = Color(0.5, 1, 0.5, 0.65);
	return true;

func _on_metadata_label_size_chage() -> void:
	if load_brain_metadata == null: return;
	
	if !(load_brain_metadata.size.x > 335): return;
	var data: Array[Dictionary] = load_brain_from_file(selectedInitialLoadPath);
	if data.size() == 0: return;
	set_metadata_label_info(data, true);

func set_metadata_label_info(data: Array[Dictionary], clip_layer_sizes: bool) -> void:
	var displayParams: Array = [
		str(data[1].month).pad_zeros(2), str(data[1].day).pad_zeros(2), str(data[1].year).substr(2,2),
		str(data[1].hour).pad_zeros(2), str(data[1].minute).pad_zeros(2),
		str(data[2].layerSizes).replace(" ", ""), str(data[2].maxFitness).pad_decimals(1),
	];
	
	if clip_layer_sizes: displayParams[5] = "[%d,...,%d]" % [data[2].layerSizes[0], data[2].layerSizes[-1]];
	load_brain_metadata.text = "Brain %s/%s/%s %s:%s: %s, Fitness: %s" % displayParams;

func _on_open_select_save_directory_button_pressed() -> void:
	if DirAccess.dir_exists_absolute(selectedSaveDirectory):
		select_folder_dialog.current_dir = selectedSaveDirectory;
	else:
		select_folder_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS);
	select_folder_dialog.visible = true;

func _on_save_directory_selected(dir: String) -> void:
	selectedSaveDirectory = dir;
	save_directory_label.text = selectedSaveDirectory;

# LEVEL SELECT
func _on_level_select_left_button_pressed() -> void:
	cycle_level_select(-1);

func _on_level_select_right_button_pressed() -> void:
	cycle_level_select(1);

func cycle_level_select(direction: int) -> void:
	if !(direction in [-1,0,1]): return;
	var level_options: int = level_select_images.size();
	selected_level += direction;
	selected_level %= level_options;
	
	main_level_display.material.set("shader_parameter/texture", level_select_images[selected_level]);
	right_level_display.material.set("shader_parameter/texture", level_select_images[(selected_level + 1) % level_options]);
	left_level_display.material.set("shader_parameter/texture", level_select_images[selected_level -1]);
	
	if selected_level + 1 < 1: selected_level += level_options;
	level_selected_label.text = "%d/%d" % [selected_level + 1, level_options];

# HELPER
func reset_params(default: Dictionary):
	config_params.do_reset_brain = default.resetBrain;
	config_params.brain_structure = fix_array_int(default.brainStructure);
	config_params.cars_per_generation = default.carsPerGeneration;
	config_params.mutation_per_generation = default.mutationPerGeneration;
	config_params.use_generation_time_limit = default.useGenerationTimeLimit;
	config_params.generation_time_limit = default.generationTimeLimit;
	config_params.use_purge_generation = default.usePurgeGenerationTime;
	config_params.purge_generation_threshold = default.purgeGenerationTime;
	config_params.do_auto_clear_dead = default.useAutoClearDeadTime;
	config_params.auto_clear_dead_interval = default.autoClearDeadTime;
	config_params.use_multiple_spawnpoints = default.useMultipleSpawnPoints;
	config_params.use_compute_shaders = default.useComputeShaders;
	config_params.selected_tilemap = default.selectedStartingLevel;
	config_params.initial_brain_load_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + default.initialLoadPath;
	config_params.brain_data_save_directory = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + default.saveDirectory;
	config_params.brain_data_save_file_name = default.saveFileName;
	config_params.brain_data_save_file_header = default.saveFileHeader;

func load_parameters_into_dialog() -> void:
	reset_brain_check_box.button_pressed = config_params.do_reset_brain;
	brain_structure.visible = reset_brain_check_box.button_pressed;
	load_brain_container.visible = !reset_brain_check_box.button_pressed;
	layer_editor.visible = false;
	
	setup_layer_editor(config_params.brain_structure.duplicate());
	
	cars_per_generation_spin_box.value = config_params.cars_per_generation;
	mutation_slider.value = config_params.mutation_per_generation;
	mutation_slider_value.text = str(config_params.mutation_per_generation) + "%";
	
	generation_time_spin_box.value = config_params.generation_time_limit;
	generation_time_check_box.button_pressed = config_params.use_generation_time_limit;
	generation_time_spin_box.visible = generation_time_check_box.button_pressed;
	
	purge_generation_spin_box.value = config_params.purge_generation_threshold;
	purge_generation_check_box.button_pressed = config_params.use_purge_generation;
	purge_generation_spin_box.visible = purge_generation_check_box.button_pressed;
	
	auto_clear_dead_spin_box.value = config_params.auto_clear_dead_interval;
	auto_clear_dead_check_box.button_pressed = config_params.do_auto_clear_dead;
	auto_clear_dead_spin_box.visible = auto_clear_dead_check_box.button_pressed;
	
	multiple_spawnpoints_check_box.button_pressed = config_params.use_multiple_spawnpoints;
	use_compute_shaders_check_box.button_pressed = config_params.use_compute_shaders;
	
	selected_level = config_params.selected_tilemap;
	cycle_level_select(0);
	
	selectedInitialLoadPath = config_params.initial_brain_load_path;
	set_load_brain_info_display(selectedInitialLoadPath);
	
	selectedSaveDirectory = config_params.brain_data_save_directory;
	save_directory_label.text = selectedSaveDirectory;

func set_config_params() -> void:
	config_params.do_reset_brain = reset_brain_check_box.button_pressed;
	
	config_params.brain_structure = get_array_from_layer_editor() if reset_brain_check_box.button_pressed else fix_array_int(load_brain_from_file(selectedInitialLoadPath)[2].layerSizes);
	
	config_params.cars_per_generation = int(cars_per_generation_spin_box.value);
	config_params.mutation_per_generation = float(mutation_slider.value);
	config_params.use_generation_time_limit = generation_time_check_box.button_pressed;
	config_params.generation_time_limit = float(generation_time_spin_box.value);
	config_params.use_purge_generation = purge_generation_check_box.button_pressed;
	config_params.purge_generation_threshold = purge_generation_spin_box.value;
	config_params.do_auto_clear_dead = auto_clear_dead_check_box.button_pressed;
	config_params.auto_clear_dead_interval = float(auto_clear_dead_spin_box.value);
	config_params.use_multiple_spawnpoints = multiple_spawnpoints_check_box.button_pressed;
	config_params.use_compute_shaders = use_compute_shaders_check_box.button_pressed;
	config_params.selected_tilemap = selected_level;
	config_params.initial_brain_load_path = selectedInitialLoadPath;
	config_params.brain_data_save_directory = selectedSaveDirectory;
	config_params.brain_data_save_file_name = defaultSimulationParameters.saveFileName;
	config_params.brain_data_save_file_header = defaultSimulationParameters.saveFileHeader;

func load_brain_from_file(filePath : String) -> Array[Dictionary]:
	if !FileAccess.file_exists(filePath): return [];
	var save_game = FileAccess.open(filePath, FileAccess.READ);
	
	var brainData: Array[Dictionary] = [];
	
	if save_game.get_position() < save_game.get_length():
		if save_game.get_line() != defaultSimulationParameters.saveFileHeader: return [];
	
	while(save_game.get_position() < save_game.get_length()):
		var json_string = save_game.get_line();
		var json = JSON.new();
		
		var parse_result = json.parse(json_string);
		if not parse_result == OK:
			print("Error while scanning brain data file.");
			return [];
		else:
			brainData.push_back(json.get_data());
	return brainData;

func fix_array_int(arr: Array) -> Array[int]:
	var output: Array[int] = [];
	output.resize(arr.size());
	
	for i in range(arr.size()):
		var temp_float: float = float(arr[i]);
		output[i] = int(temp_float);
		
	return output;
