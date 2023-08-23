class_name Layer extends Object;

var numInputNodes : int;
var numOutputNodes : int;

var weights : Array[float] = [];
var biases : Array[float] = [];

func _init(inputNodes : int, outputNodes : int) -> void:
	self.numInputNodes = inputNodes;
	self.numOutputNodes = outputNodes;
	
	weights.resize(self.numInputNodes * self.numOutputNodes);
	
	biases.resize(self.numOutputNodes);
	
func calculateOutputs(inputs : Array) -> Array:
	var activations : Array[float] = [];

	activations.resize(numOutputNodes);

	for nodeOut in range(numOutputNodes):
		var weightedInput : float = biases[nodeOut];
 
		for nodeIn in range(numInputNodes):
			weightedInput += inputs[nodeIn] * getWeightValue(nodeIn, nodeOut);

		activations[nodeOut] = hyperbolicTangent(weightedInput);

	return activations;

func hyperbolicTangent(weightedInput : float) -> float:
	var e2w : float = exp(2 * weightedInput);
	return (e2w-1) / (e2w+1);

func randomizeLayer() -> void:
	var rng : RandomNumberGenerator = RandomNumberGenerator.new();
	
	for i in range(weights.size()):
		weights[i] = rng.randf()*2-1;
	
	for i in range(biases.size()):
		biases[i] = rng.randf()*2-1;

func getWeightValue(nodeIn : int, nodeOut: int) -> float:
	return weights[nodeOut * numInputNodes + nodeIn];

func mutate(mutationAmount : float) -> void:
	var rng : RandomNumberGenerator = RandomNumberGenerator.new();
	
	for i in range(weights.size()):
		weights[i] = lerp(weights[i], rng.randf()*2-1, mutationAmount);
	
	for i in range(biases.size()):
		biases[i] = lerp(biases[i], rng.randf()*2-1, mutationAmount);
