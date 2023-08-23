class_name CarSimulation extends Node;

var Car = preload("res://Car/CarObject.tscn");

@onready var spawnPoints : Node = $Spawnpoints;
@onready var hud : HUD = $"../HUD";
@onready var rewardGates : Node = $RewardGates;
@onready var agentController : Node = $AgentController;

# TRACKING
var aliveCars : int;
var generationCount : int = 0;
var totalCars : int = 0;
var highestFitness : float = 0;
var timePassed : float = 0;

# SIMULATION FUNCTIONS
var hasPurgedGeneration : bool = false;
var timeSinceLastClear : float = 0;

func _ready() -> void:
	hud.generations_info.info_text = generationCount;
	hud.generation_alive_info.info_text = "%d/%d" % [config_params.cars_per_generation, config_params.cars_per_generation];
	hud.highest_fitness_info.info_text = "%.1f" % highestFitness;
	
	hud.kill_full_generation.button_down.connect(actionKillFullGeneration);
	hud.kill_filtered_generation.button_down.connect(actionKillFilteredGeneration);
	hud.clear_dead_from_screen.button_down.connect(actionClearDeadFromScreen);
	hud.next_generation.button_down.connect(actionNextGeneration);
	hud.clear_dead_switch.pressed.connect(func(): config_params.do_auto_clear_dead = hud.clear_dead_switch.is_pressed());
	
	spawnNewGeneration(config_params.cars_per_generation);

func load_config_from_menu(data: Dictionary) -> void:
	pass

func _process(delta: float) -> void:
	focusHandler();
	
	if config_params.do_auto_clear_dead: timeSinceLastClear += delta;
	if timeSinceLastClear >= config_params.auto_clear_dead_interval && config_params.do_auto_clear_dead:
		actionClearDeadFromScreen();
		timeSinceLastClear = 0;
	
	timePassed += delta;
	hud.time_passed_info.info_text = "%.1fs" % [round(timePassed*10)/10];
	if (timePassed > config_params.purge_generation_threshold && !hasPurgedGeneration) && config_params.use_purge_generation:
		actionRemoveStuckCars();
		hasPurgedGeneration = true;
	if timePassed > config_params.generation_time_limit && config_params.use_generation_time_limit: actionNextGeneration();

func _physics_process(delta: float) -> void:
	if config_params.use_compute_shaders: return;
	for car in agentController.get_children():
		if car == null: return;
		car.cpu_update(delta);

func actionRemoveStuckCars() -> void:
	for car in agentController.get_children():
		if car.rewardGatePoints == 0:
			car.die();

func actionKillFullGeneration() -> void:
	for car in agentController.get_children():
		car.timeAlive = 0;
		car.die();

func actionKillFilteredGeneration() -> void:
	var bestCarIdx = findBestCarIndex(false);
	var bestCarID = agentController.get_children()[bestCarIdx].generationID;
	
	for car in agentController.get_children():
		if car.generationID == bestCarID || car.is_dead: continue;
		car.timeAlive = 0;
		car.die();
		
func actionClearDeadFromScreen() -> void:
	if agentController.get_children().any(func(car): return car.is_dead):
		
		var curr_car_idx : int = 0;
		var best_car_idx : int = findBestCarIndex(false);
		for car in agentController.get_children():
			if car.is_dead && curr_car_idx != best_car_idx:
				agentController.get_children().remove_at(agentController.get_children().find(car));
				car.queue_free();
			curr_car_idx += 1;

func actionNextGeneration() -> void:
	var bestCarIdx = findBestCarIndex(false);
	var bestCarID = agentController.get_children()[bestCarIdx].generationID;
	
	for car in agentController.get_children():
		if car.generationID == bestCarID: car.die();
		car.timeAlive = 0;
		car.die();

func spawnNewGeneration(generationSize: int) -> void:
	generationCount += 1;
	totalCars += generationSize;
	hud.total_cars_info.info_text = totalCars;
	
	aliveCars = generationSize;
	agentController.get_children().clear();
	agentController.get_children().resize(generationSize);
	
	var brainData: Dictionary;
	
	if generationCount == 1 && !config_params.do_reset_brain:
		brainData = load_brain_from_file(config_params.initial_brain_load_path)[0] if FileAccess.file_exists(config_params.initial_brain_load_path) else {};
	else:
		brainData = load_brain_from_file(config_params.brain_data_save_directory + config_params.brain_data_save_file_name)[0] if FileAccess.file_exists(config_params.brain_data_save_directory + config_params.brain_data_save_file_name) else {};
	
	for i in generationSize:
		var spawnedCar : CarObject = Car.instantiate();
		
		var newBrain : NeuralNetwork = NeuralNetwork.new();
		if (generationCount != 1 || !config_params.do_reset_brain) && !brainData.is_empty():
			newBrain.loadNetwork(brainData.duplicate(true));
			newBrain.mutateNetwork(float(config_params.mutation_per_generation)/100);
		else:
			newBrain.createNewNetwork(config_params.brain_structure);
		
		spawnedCar.brain = newBrain;
		
		var spawnPoint : Node2D = spawnPoints.get_children().pick_random() if config_params.use_multiple_spawnpoints else spawnPoints.get_children()[0];
		spawnedCar.global_position = spawnPoint.position;
		spawnedCar.global_rotation = spawnPoint.rotation + 90;
		
		spawnedCar.generationID = i;
		agentController.add_child(spawnedCar);
		spawnedCar.on_car_death.connect(generationDeathHandler);
		
		for rewardGate in rewardGates.get_children():
			rewardGate.rewardGatePassed.connect(spawnedCar.onRewardGateEntered);
			
		agentController.get_children()[i] = spawnedCar;
	
	hud.generation_alive_info.info_text = "%d/%d" % [aliveCars, config_params.cars_per_generation];

func generationDeathHandler(_id: int):
#	aliveCars -= 1;
	aliveCars = agentController.get_children().filter(func(car): return !car.is_dead).size();
	hud.generations_info.info_text = generationCount;
	hud.generation_alive_info.info_text = "%d/%d" % [aliveCars, config_params.cars_per_generation];
	
	if(aliveCars == 0):
		hud.generations_info.info_text = generationCount;
		
		var bestCarIdx : int = findBestCarIndex(false);
		if agentController.get_children()[bestCarIdx].fitnessScore > highestFitness:
			highestFitness = agentController.get_children()[bestCarIdx].fitnessScore;
			save_brain_to_file(config_params.brain_data_save_directory + config_params.brain_data_save_file_name, agentController.get_children()[bestCarIdx]);
		
		for car in agentController.get_children():
			agentController.get_children().remove_at(agentController.get_children().find(car))
			car.queue_free();
		
		hud.highest_fitness_info.info_text = "%.1f" % highestFitness;
		timePassed = 0;
		hasPurgedGeneration = false;
		spawnNewGeneration(config_params.cars_per_generation);
		
func focusHandler() -> void:
	for car in agentController.get_children():
		if car == null: return;
		car.sprite.modulate.a = 0.2;
	
	var bestCar : CarObject = agentController.get_children()[findBestCarIndex(true)];
	
	bestCar.sprite.modulate.a = 1;
	hud.current_highest_fitness_info.info_text = "%.1f" % bestCar.fitnessScore;

func findBestCarIndex(mustBeAlive : bool) -> int:
	var bestCarIndex = 0;
	for i in agentController.get_children().size():
		if i == 0: continue;
		if agentController.get_children()[i].fitnessScore > agentController.get_children()[bestCarIndex].fitnessScore:
			if(agentController.get_children()[i].is_dead && mustBeAlive): continue;
			bestCarIndex = i;
	return bestCarIndex;
	
func load_brain_from_file(filePath : String) -> Array[Dictionary]:
	if !FileAccess.file_exists(filePath): return [];
	var save_game = FileAccess.open(filePath, FileAccess.READ);
	
	var brainData: Array[Dictionary] = [];
	
	if save_game.get_position() < save_game.get_length():
		if save_game.get_line() != config_params.brain_data_save_file_header:
			return [];
	
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

func save_brain_to_file(filePath : String, car : CarObject) -> void:
	var saved_brain : Dictionary = car.brain.serialize();
	var save_game = FileAccess.open(filePath, FileAccess.WRITE);
	save_game.store_line(config_params.brain_data_save_file_header);
	save_game.store_line(JSON.stringify(saved_brain));
	save_game.store_line(JSON.stringify(Time.get_datetime_dict_from_system()));
	save_game.store_line(JSON.stringify( {maxFitness = highestFitness, layerSizes = car.brain.getNetworkLayerSizes()} ));
