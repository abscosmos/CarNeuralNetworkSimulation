class_name AgentController extends Node;

const shaderFile = preload("res://NeuralNetwork/neuralNetwork.glsl");
@onready var worldNode = $"..";

# Compute Shader Steps
var renderingDevice : RenderingDevice;
var shader : RID;
var pipeline : RID;

const datasetParameterCount : int = 7;
const invocation_size : float = 64.0;

const size_int : int = 4;
const size_float : int = 4;

# Buffers
var bufferSet : RID;
var datasetInfoBuffer : RID;
var networkInputBuffer : RID;
var networkOutputBuffer : RID;
var networkLayerSizesBuffer : RID;
var networkWeightsBuffer : RID;
var networkBiasesBuffer : RID;
var processBuffer : RID;
var activationsBuffer : RID;

# Buffer Sizes
var datasetInfoBufferMaxSize : int;
var networkInputBufferMaxSize : int;
var networkOutputBufferMaxSize : int;
var networkLayerSizesBufferMaxSize : int;
var networkWeightsBufferMaxSize : int;
var networkBiasesBufferMaxSize : int;
var processBufferMaxSize : int;

# Bindings & Set
const bufferSetIndex : int = 0;
const datasetInfoBindIndex : int = 0;
const networkInputBindIndex : int = 1;
const networkOutputBindIndex : int = 2;
const networkLayerSizesBindIndex : int = 3;
const networkWeightsBindIndex : int = 4;
const networkBiasesBindIndex : int = 5;
const processBufferBindIndex : int = 6;
const activationsBufferBindIndex : int = 7;

var waitingForCompute : bool = false;
var frame : int = 0;
var lastComputeDispatchFrame : int;
var numWaitframesGpusync : int = 16;


# Start Data
var generationSize : int;
var networkStructure : Array[int];

# Data

func _ready() -> void:
	await worldNode.ready;
	generationSize = config_params.cars_per_generation;
	networkStructure = config_params.brain_structure;
	
	init_compute();

func _physics_process(delta: float) -> void:
	if !config_params.use_compute_shaders: return;
	if waitingForCompute:
		fetch_data();
	elif !waitingForCompute:
		sendCompute();
	
	var output : Array = fetch_data();
	var outputNodes : int = networkStructure[-1];
	var current : int = 0;

	for car in get_children():
		if !(car is CarObject): current += 1; continue;
		if car.is_dead: continue;
		
		car.gpu_update(delta, CarObject.get_input_from_brain([output[outputNodes * current], output[outputNodes * current + 1], output[outputNodes * current + 2], output[outputNodes * current + 3]]));
		current += 1;
	
	frame += 1;

func sendCompute():
	var carCount : int = 0;
	var carInputs : Array[float] = [];
	var carWeights : Array[float] = [];
	var carBiases : Array[float] = [];
	
	for car in get_children():
		if !(car is CarObject): continue;
		if car.is_dead: continue;
		carCount += 1;
		carInputs.append_array(convertSensorInput(car.get_sensor_input()));
		carWeights.append_array(car.brain.getNetworkWeightsAsArray());
		carBiases.append_array(car.brain.getNetworkBiasesAsArray());
		
	run_compute(carCount, carInputs, carWeights, carBiases);

func init_compute() -> void:
	renderingDevice = RenderingServer.create_local_rendering_device();
	shader = renderingDevice.shader_create_from_spirv(shaderFile.get_spirv());
	
	# NetworksToProcess
	datasetInfoBufferMaxSize = datasetParameterCount * size_int;
	
	datasetInfoBuffer = renderingDevice.storage_buffer_create(datasetInfoBufferMaxSize);
	var datasetInfoUniform : RDUniform = RDUniform.new();
	datasetInfoUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER;
	datasetInfoUniform.binding = datasetInfoBindIndex;
	datasetInfoUniform.add_id(datasetInfoBuffer);
	
	# NetworkInput
	var inputNodeCount : int = networkStructure[0];
	networkInputBufferMaxSize = inputNodeCount * generationSize * size_float;
	
	networkInputBuffer = renderingDevice.storage_buffer_create(networkInputBufferMaxSize);
	var networkInputUniform : RDUniform = RDUniform.new();
	networkInputUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER;
	networkInputUniform.binding = networkInputBindIndex;
	networkInputUniform.add_id(networkInputBuffer);
	
	# NetworkOutput
	var outputNodes : int = networkStructure[-1];
	networkOutputBufferMaxSize = outputNodes * generationSize * size_float;
	
	networkOutputBuffer = renderingDevice.storage_buffer_create(networkOutputBufferMaxSize);
	var networkOutputUniform : RDUniform = RDUniform.new();
	networkOutputUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER;
	networkOutputUniform.binding = networkOutputBindIndex;
	networkOutputUniform.add_id(networkOutputBuffer);
	
	# NetworkLayerSizes
	var networkLayers : int = networkStructure.size();
	networkLayerSizesBufferMaxSize = networkLayers * size_float;
	
	var networkStructureBytes : PackedByteArray = PackedInt32Array(networkStructure).to_byte_array();
	
	networkLayerSizesBuffer = renderingDevice.storage_buffer_create(networkLayerSizesBufferMaxSize, networkStructureBytes);
	var networkLayerSizesUniform : RDUniform = RDUniform.new();
	networkLayerSizesUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER;
	networkLayerSizesUniform.binding = networkLayerSizesBindIndex;
	networkLayerSizesUniform.add_id(networkLayerSizesBuffer);
	
	# NetworkWeights
	networkWeightsBufferMaxSize = getWeightsPerNetwork(networkStructure) * generationSize * size_float;
	
	networkWeightsBuffer = renderingDevice.storage_buffer_create(networkWeightsBufferMaxSize);
	var networkWeightsUniform : RDUniform = RDUniform.new();
	networkWeightsUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER;
	networkWeightsUniform.binding = networkWeightsBindIndex;
	networkWeightsUniform.add_id(networkWeightsBuffer);
	
	# NetworkBiases
	networkBiasesBufferMaxSize = getBiasesPerNetwork(networkStructure) * generationSize * size_float;
	
	networkBiasesBuffer = renderingDevice.storage_buffer_create(networkBiasesBufferMaxSize);
	var networkBiasesUniform : RDUniform = RDUniform.new();
	networkBiasesUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER;
	networkBiasesUniform.binding = networkBiasesBindIndex;
	networkBiasesUniform.add_id(networkBiasesBuffer);
	
	# ProcessBuffer
	processBufferMaxSize = networkStructure.max() * generationSize * size_int;
	
	processBuffer = renderingDevice.storage_buffer_create(processBufferMaxSize);
	var processBufferUniform : RDUniform = RDUniform.new();
	processBufferUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER;
	processBufferUniform.binding = processBufferBindIndex;
	processBufferUniform.add_id(processBuffer);
	
	# ActivationsBuffer
	activationsBuffer = renderingDevice.storage_buffer_create(processBufferMaxSize);
	var activationsBufferUniform : RDUniform = RDUniform.new();
	activationsBufferUniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER;
	activationsBufferUniform.binding = activationsBufferBindIndex;
	activationsBufferUniform.add_id(activationsBuffer);
	
	# Buffer setter & pipeline
	var buffersArray : Array[RDUniform] = [datasetInfoUniform, networkInputUniform, networkOutputUniform, networkLayerSizesUniform, networkWeightsUniform, networkBiasesUniform, processBufferUniform, activationsBufferUniform];
	pipeline = renderingDevice.compute_pipeline_create(shader);
	bufferSet = renderingDevice.uniform_set_create(buffersArray, shader, bufferSetIndex);
	
func run_compute(networkCount : int, inputs : Array[float], weights : Array[float], biases : Array[float]) -> void:
	if waitingForCompute: return;
	
	var datasetInfo : Array[int] = [networkCount, networkStructure[0], networkStructure[-1], networkStructure.size(), getWeightsPerNetwork(networkStructure), getBiasesPerNetwork(networkStructure), int(networkStructure.max())];
	var datasetInfoBytes = PackedInt32Array(datasetInfo).to_byte_array();
	renderingDevice.buffer_update(datasetInfoBuffer, 0, datasetInfoBytes.size(), datasetInfoBytes);
	
	var networkInputBytes = PackedFloat32Array(inputs).to_byte_array();
	renderingDevice.buffer_update(networkInputBuffer, 0, networkInputBytes.size(), networkInputBytes);
	
	# !! NO NEED TO UPDATE OUTPUT BUFFER !!
	
	var networkWeightsBytes = PackedFloat32Array(weights).to_byte_array();
	renderingDevice.buffer_update(networkWeightsBuffer, 0, networkWeightsBytes.size(), networkWeightsBytes);
	
	var networkBiasesBytes = PackedFloat32Array(biases).to_byte_array();
	renderingDevice.buffer_update(networkBiasesBuffer, 0, networkBiasesBytes.size(), networkBiasesBytes);
	
	# Compute List
	var workgroups = ceil(inputs.size()/float(networkStructure[0]) / float(invocation_size));
	
	var computeList = renderingDevice.compute_list_begin();
	renderingDevice.compute_list_bind_compute_pipeline(computeList, pipeline);
	renderingDevice.compute_list_bind_uniform_set(computeList, bufferSet, bufferSetIndex);
	renderingDevice.compute_list_dispatch(computeList, workgroups, 1, 1);
	renderingDevice.compute_list_end();
	
	renderingDevice.submit();
	lastComputeDispatchFrame = frame;
	waitingForCompute = true;

func fetch_data() -> Array:
	renderingDevice.sync();
	waitingForCompute = false;
	return renderingDevice.buffer_get_data(networkOutputBuffer).to_float32_array() as Array[float];

func getWeightsPerNetwork(networkLayers : Array[int]) -> int:
	var totalWeights : int = 0;
	
	for i in networkLayers.size() -1:
		totalWeights += networkLayers[i] * networkLayers[i+1];
	
	return totalWeights;

func getBiasesPerNetwork(networkLayers : Array[int]) -> int:
	var totalBiases : int = networkLayers.reduce(func(accum, sum): return accum + sum, 0);
	return totalBiases - networkLayers[0];

func convertSensorInput(sensor : Dictionary) -> Array[float]:
	return [sensor.forward, sensor.left, sensor.right];

func flatten2DArrayFloat(arr2d : Array[Array]) -> Array[float]:
	var flat : Array[float] = [];
	for arr in arr2d:
		for val in arr: flat.append(val);
	return flat;
