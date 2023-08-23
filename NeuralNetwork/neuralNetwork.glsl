#[compute]
#version 450

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) readonly buffer DatasetInfo {
	int networkCount;
	int inputCount;
	int outputCount;
	int networkLayerCount;
	int weightsPerNetwork;
	int biasesPerNetwork;
	int processBufferPerNetwork;
} dataset_info;

layout(set = 0, binding = 1, std430) buffer NetworkInput {
	float neurons[];
} network_input;

layout(set = 0, binding = 2, std430) buffer NetworkOutput {
	float neurons[];
} network_output;

layout(set = 0, binding = 3, std430) buffer NetworkLayerSizes {
	int layers[];
} network_layer_sizes;

layout(set = 0, binding = 4, std430) buffer NetworkWeights {
	float[] weights;
} network_weights;

layout(set = 0, binding = 5, std430) buffer NetworkBiases {
	float[] biases;
} network_biases;

layout(set = 0, binding = 6, std430) buffer ProcessBuffer {
	float[] data;
} process_buffer;

layout(set = 0, binding = 7, std430) buffer ActivationsBuffer {
	float[] data;
} activations_buffer;


float hyperbolicTangent(float weightedInput);
uint getNetworkInputsStartIndex(uint networkIndex);
uint getNetworkOutputsStartIndex(uint networkIndex);
uint getNetworkWeightsStartIndex(uint networkIndex);
uint getNetworkBiasesStartIndex(uint networkIndex);
uint getLayerWeightCount(uint layerIndex);
uint getLayerBiasCount(uint layerIndex);
uint getWeightValueIndex(uint nodeIn, uint nodeOut, uint layerIndex);
uint getLayerWeightsStartIndex(uint layerIndex);
uint getLayerBiasesStartIndex(uint layerIndex);
float getWeight(uint networkIndex, uint layerIndex, uint nodeIn, uint nodeOut);
float getBias(uint networkIndex, uint layerIndex, uint bias);

void processBufferWrite(uint networkIndex, uint index, float data);
float processBufferRead(uint networkIndex, uint index);
void activationsBufferWrite(uint networkIndex, uint index, float data);
float activationsBufferRead(uint networkIndex, uint index);

void main() {
	uint curr_id = gl_GlobalInvocationID.x;
	if(curr_id > dataset_info.networkCount - 1) return;
	
	for(uint i = 0; i < dataset_info.inputCount; i++) {
		processBufferWrite(curr_id, i, network_input.neurons[getNetworkInputsStartIndex(curr_id) + i]);
	}
	
	for(uint currentLayer = 0; currentLayer < dataset_info.networkLayerCount; currentLayer++) {
		
		uint numInputNodes = network_layer_sizes.layers[currentLayer];
		uint numOutputNodes = network_layer_sizes.layers[currentLayer + 1];
		
		for(uint nodeOut = 0; nodeOut < numOutputNodes; nodeOut++) {
			float weightedInput = getBias(curr_id, currentLayer, nodeOut);
			
			for(uint nodeIn = 0; nodeIn < numInputNodes; nodeIn++) {
				weightedInput += processBufferRead(curr_id, nodeIn) * getWeight(curr_id, currentLayer, nodeIn, nodeOut);
			}
			
			activationsBufferWrite(curr_id, nodeOut, hyperbolicTangent(weightedInput));
		}
		
		for(uint copyPos = 0; copyPos < numOutputNodes; copyPos++) {
			processBufferWrite(curr_id, copyPos, activationsBufferRead(curr_id, copyPos));
			// activationsBufferWrite(curr_id, copyPos, 0);
		}
	}
	
	for(uint copyOutputPos = 0; copyOutputPos < dataset_info.outputCount; copyOutputPos++) {
		network_output.neurons[getNetworkOutputsStartIndex(curr_id) + copyOutputPos] = (processBufferRead(curr_id, copyOutputPos) > 0) ? 1 : 0;
	}
}

// Indexing
uint getNetworkInputsStartIndex(uint networkIndex) { return networkIndex * dataset_info.inputCount; }
uint getNetworkOutputsStartIndex(uint networkIndex) { return networkIndex * dataset_info.outputCount; }
uint getNetworkWeightsStartIndex(uint networkIndex) { return networkIndex * dataset_info.weightsPerNetwork; }
uint getNetworkBiasesStartIndex(uint networkIndex) { return networkIndex * dataset_info.biasesPerNetwork; }
uint getWeightValueIndex(uint nodeIn, uint nodeOut, uint layerIndex) { return nodeOut * network_layer_sizes.layers[layerIndex] + nodeIn; }

uint getLayerWeightsStartIndex(uint layerIndex) {
	uint index = 0;
	for(uint i = 0; i < layerIndex; i++) {
		index += getLayerWeightCount(i);
	}
	
	return index;
}

uint getLayerBiasesStartIndex(uint layerIndex) {
	uint index = 0;
	for(uint i = 0; i < layerIndex; i++) {
		index += getLayerBiasCount(i);
	}
	
	return index;
}

// Counting
uint getLayerWeightCount(uint layerIndex) { return network_layer_sizes.layers[layerIndex] * network_layer_sizes.layers[layerIndex + 1]; }
uint getLayerBiasCount(uint layerIndex) { return network_layer_sizes.layers[layerIndex + 1]; }

// Get Data
float getWeight(uint networkIndex, uint layerIndex, uint nodeIn, uint nodeOut) {
	uint networkStart = getNetworkWeightsStartIndex(networkIndex);
	uint layerStart = getLayerWeightsStartIndex(layerIndex);
	uint weightIndex = getWeightValueIndex(nodeIn, nodeOut, layerIndex);
	
	uint finalIndex = networkStart + layerStart + weightIndex;
	
	return network_weights.weights[finalIndex];
}

float getBias(uint networkIndex, uint layerIndex, uint bias) {
	uint networkStart = getNetworkBiasesStartIndex(networkIndex);
	uint layerStart = getLayerBiasesStartIndex(layerIndex);
	
	uint finalIndex = networkStart + layerStart + bias;
	
	return network_biases.biases[finalIndex];
}

// Process Buffer(s)
void processBufferWrite(uint networkIndex, uint index, float data) { process_buffer.data[(networkIndex * dataset_info.processBufferPerNetwork) + index] = data; }
float processBufferRead(uint networkIndex, uint index) { return process_buffer.data[(networkIndex * dataset_info.processBufferPerNetwork) + index]; }

void activationsBufferWrite(uint networkIndex, uint index, float data) { activations_buffer.data[(networkIndex * dataset_info.processBufferPerNetwork) + index] = data; }
float activationsBufferRead(uint networkIndex, uint index) { return activations_buffer.data[(networkIndex * dataset_info.processBufferPerNetwork) + index]; }

// Neural Network Functions
float hyperbolicTangent(float weightedInput) {
	float e2w = exp(2 * weightedInput);
	return (e2w  - 1.0) / (e2w + 1.0);
}