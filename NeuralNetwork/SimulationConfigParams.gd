class_name SimulationConfigParams extends Node;

var do_reset_brain: bool;
var brain_structure: Array[int];

var cars_per_generation: int;
var mutation_per_generation: int;

var use_generation_time_limit: bool;
var generation_time_limit: float;

var use_purge_generation: bool;
var purge_generation_threshold: float;

var do_auto_clear_dead: bool;
var auto_clear_dead_interval: float;

var use_multiple_spawnpoints: bool;
var use_compute_shaders: bool;

var selected_tilemap: int;

var initial_brain_load_path: String;
var brain_data_save_directory: String;
var brain_data_save_file_name: String;
var brain_data_save_file_header: String;

var has_started_game: bool = false;
