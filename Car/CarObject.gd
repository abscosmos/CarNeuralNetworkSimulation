class_name CarObject extends CharacterBody2D;

const grayscale_shader =  preload("res://Car/Grayscale.gdshader");

@onready var sprite : Sprite2D = $Car;

const ACCELERATION : float = 600;
const MAX_SPEED : float = 175;
const FRICTION : float = 750;

const TURN_ACCEL : float = 50;
const MAX_TURN_SPEED : float = PI/50;
const TURN_FRICTION : float = 0.5;

var forwardVelocity : float = 0;
var turnVelocity : float = 0;

var is_dead : bool = false;
signal on_car_death;

var brain : NeuralNetwork;

var timeIdle : float = 0;
var generationID : int;

var timeAlive : float = 0;
var rewardGatePoints : float = 0;
var fitnessScore : float:
	get: return 0.1 * timeAlive + (1 * rewardGatePoints);

@onready var sensorBase : Node2D = $Sensors;
@onready var forwardSensor : RayCast2D = $Sensors/ForwardRayCast;
@onready var leftSensor : RayCast2D = $Sensors/LeftRayCast;
@onready var rightSensor : RayCast2D = $Sensors/RightRayCast;

func _ready() -> void:
	pass
	
func cpu_update(delta: float) -> void:
	if is_dead: return;
	
	var sensor : Dictionary = get_sensor_input();
	var aiResult : Array[int] = brain.classify([sensor.forward, sensor.left, sensor.right]);
	var input : Dictionary = CarObject.get_input_from_brain(aiResult);
			
	move(input.forwardInput, input.turningAxis, delta);
	
	for idx in get_slide_collision_count(): if get_slide_collision(idx).get_collider() is TileMap: die();
	
	check_if_idle(input, delta);
	timeAlive += delta;

func gpu_update(delta: float, input : Dictionary) -> void:
	if is_dead: return;
	
	move(input.forwardInput, input.turningAxis, delta);
	for idx in get_slide_collision_count(): if get_slide_collision(idx).get_collider() is TileMap: die();
	
	check_if_idle(input, delta);
	timeAlive += delta;

func get_input_from_player() -> Dictionary:
	return {
		forwardInput = Input.get_axis("move_up", "move_down"),
		turningAxis = Input.get_axis("move_left", "move_right")
	}
	
static func get_input_from_brain(input : Array[int]) -> Dictionary:
	return{
		forwardInput = input[0]-input[1],
		turningAxis = input[2]-input[3]
	}

func move(forwardInput : float, turningAxis : float, delta : float):
	if forwardInput != 0:
		forwardVelocity = move_toward(forwardVelocity, forwardInput * MAX_SPEED, ACCELERATION * delta);
	else:
		forwardVelocity = move_toward(forwardVelocity, 0, FRICTION * delta);
		
	if turningAxis != 0:
		turnVelocity = move_toward(turnVelocity, turningAxis * MAX_TURN_SPEED, TURN_ACCEL * delta);
	else:
		turnVelocity = move_toward(turnVelocity, 0, TURN_FRICTION * delta);
	
	rotation += turnVelocity;
	
	var rotationVector = -Vector2(sin(rotation), -cos(rotation));
	velocity = rotationVector * forwardVelocity;
	
	move_and_slide();

func get_sensor_input() -> Dictionary:
	return {
		forward = get_sensor_distance(forwardSensor) if forwardSensor.is_colliding() else 1.0,
		left = get_sensor_distance(leftSensor) if leftSensor.is_colliding() else 1.0,
		right = get_sensor_distance(rightSensor) if rightSensor.is_colliding() else 1.0
	};

func get_sensor_distance(sensor: RayCast2D) -> float:
	return clamp((sensorBase.global_position - sensor.get_collision_point()).length() / abs(sensor.target_position.y), 0, 1);

func check_if_idle(input: Dictionary, delta : float):
	var hasNoInput : bool = input.forwardInput == 0 && input.turningAxis == 0;
	if hasNoInput && timeIdle < 1:
		timeIdle += delta
	elif hasNoInput && timeIdle >= 1:
		timeAlive -= timeIdle;
		die();
	else: timeIdle = 0;

func onRewardGateEntered(node: Node2D, points: float) -> void:
	if node != self: return;
	rewardGatePoints += points;

func die() -> void:
	if is_dead: return;
	
	is_dead = true;
	var grayscale_shader_material : ShaderMaterial = ShaderMaterial.new();
	grayscale_shader_material.shader = grayscale_shader;
	grayscale_shader_material.set_shader_parameter("opacity", 0.2);
	sprite.material = grayscale_shader_material;
	
	emit_signal("on_car_death", generationID);
