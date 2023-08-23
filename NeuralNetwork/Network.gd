class_name NeuralNetwork extends Object;

var layers : Array[Layer];

func createNewNetwork(layerSizes : Array[int]) -> void:
	layers.resize(layerSizes.size()-1);
	for i in range(layers.size()):
		layers[i] = Layer.new(layerSizes[i], layerSizes[i+1]);
		layers[i].randomizeLayer();

func loadNetwork(serialized : Dictionary) -> void:
	layers.resize(serialized.size());
	for i in layers.size():
		layers[i] = dict_to_inst(serialized.get(str(i)));
		
		#when read from file, int member variables are in float form, but treated as int
		var int_float_fix : float = layers[i].numInputNodes;
		layers[i].numInputNodes = int(int_float_fix);
		
		int_float_fix = layers[i].numOutputNodes;
		layers[i].numOutputNodes = int(int_float_fix);

func calculateOutputs(inputs : Array) -> Array:
	for layer in layers:
		inputs = layer.calculateOutputs(inputs);
	return inputs;

func classify(inputs : Array) -> Array[int]:
	var outputs : Array = calculateOutputs(inputs);
	var classified : Array[int] = [];
	for output in outputs:
		classified.append(1 if output > 0 else 0);
	return classified;

func getNetworkWeightsAsArray() -> Array[float]:
	var networkWeights : Array[float] = [];
	for layer in layers:
		networkWeights.append_array(layer.weights);
	return networkWeights;

func getNetworkBiasesAsArray() -> Array[float]:
	var networkBiases : Array[float] = [];
	for layer in layers:
		networkBiases.append_array(layer.biases);
	return networkBiases;

func getNetworkLayerSizes() -> Array[int]:
	var networkLayerSizes : Array[int] = [layers[0].numInputNodes];
	for layer in layers:
		networkLayerSizes.append(layer.numOutputNodes);
	return networkLayerSizes;

func getNetworkWeightsCount() -> int:
	var networkStructure = getNetworkLayerSizes();
	var totalWeights : int = 0;
	
	for i in networkStructure.size() -1:
		totalWeights += networkStructure[i] * networkStructure[i+1];
	
	return totalWeights

func getNetworkBiasesCount() -> int:
	var networkStructure : Array[int] = getNetworkLayerSizes();
	var totalBiases : int = networkStructure.reduce(func(accum, sum): return accum + sum, 0);
	return totalBiases - networkStructure[0];

func serialize() -> Dictionary:
	var serialized : Dictionary = {};
	for i in layers.size():
		serialized[i] = inst_to_dict(layers[i]);
	return serialized;

func mutateNetwork(mutationAmount : float) -> void:
	for layer in layers:
		layer.mutate(mutationAmount);
