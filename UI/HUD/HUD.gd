class_name HUD extends CanvasLayer;

@onready var kill_full_generation: Button = %KillFullGeneration;
@onready var kill_filtered_generation: Button = %KillFilteredGeneration;
@onready var clear_dead_from_screen: Button = %ClearDeadFromScreen;
@onready var next_generation: Button = %NextGeneration;
@onready var clear_dead_switch: CheckBox = %ClearDeadSwitch;

@onready var generations_info: InformationChip = $Control/MarginContainer/Information/Generations;
@onready var generation_alive_info: InformationChip = $Control/MarginContainer/Information/GenerationAlive;
@onready var current_highest_fitness_info: InformationChip = $Control/MarginContainer/Information/CurrentHighestFitness;
@onready var total_cars_info: InformationChip = $Control/MarginContainer/Information/TotalCars;
@onready var highest_fitness_info: InformationChip = $Control/MarginContainer/Information/HighestFitness;
@onready var time_passed_info: InformationChip = $Control/MarginContainer/Information/TimePassed;

@onready var menu_button: Button = %MenuButton;
