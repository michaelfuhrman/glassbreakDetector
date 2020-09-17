/*
 * rampSim.cpp
 *
 *  Created on: Apr 13, 2017
 *      Author: Brandon Rumberg
 */

/*
 * Setup in Eclipse CDT:
 *  - Include soundfile
 *  - Include boost
 *  - Link mingw stuff:
 *    Goto Project > Properties > C/C++ Build > Settings > Tool Settings (Tab)
 *    > MinGW C++ Linker (Option) > Add Command (g++ -static-libgcc -static-libstdc++)
 *    (default command is only g++)
 *  - To switch over to C++11
 *  There are two tabs at Project --> Properties --> C/C++ General --> Preprocessor Include Paths, Macros etc.
In the Providers tab, select the proper builtin provider and set the command (globally or locally) to:
${COMMAND} -std=c++11 ${FLAGS} -E -P -v -dD "${INPUTS}"
Then press Apply..
 */

/*
 * To do items:
 *  - Can't afford to keep a full matrix of all nodes at all time steps, need to remove that
 *  - Clean up function templates
 *  - Use global arrays to clean up and speed stuff up
 *  - Stress test with big wav files and lots of nets
 *  - Add functions: linear transformation, log, square, rectify
 */

#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <random>
#include <algorithm>
#include <math.h>
#include <boost/lexical_cast.hpp>
#include <boost/assign/list_of.hpp>
#include <boost/function.hpp>
#include <boost/math/constants/constants.hpp>
#include <boost/circular_buffer.hpp>
#include "sndfile.hh"
#include "rampSim.h"

//#include "circuitElements.h"

#define STRING_NPOS_32 4294967295 // 32-bit value for string::npos which is returned by string::find() even on 64-bit compile
#define PARAM_NOISE 0
#define PARAM_OFFSET_MEAN 1
#define PARAM_OFFSET_SIGMA 2
#define PARAM_SATURATE 3
#define PARAM_RUNPERIOD 4

#define ADD_NOISE dist(generator)*elements[elem].defaultParams[PARAM_NOISE]
#define ADD_OFFSET elements[elem].defaultParams[PARAM_OFFSET_MEAN]
#define SATURATION_VALUE elements[elem].defaultParams[PARAM_SATURATE]

#define INPUT(NODE,DELAY) nodeValues[!toggle DELAY ][elements[elem].nodes[ NODE ]]
#define INPUT2(NODE,DELAY) elements[elem].internalCircular[ NODE ][elements[elem].internalCircular[ NODE ].size() DELAY]

#define OUTPUT(NODE) nodeValues[toggle][elements[elem].nodes[ NODE ]]


using boost::lexical_cast;
using namespace std;
using namespace boost::assign;

// For splines,,, Also created src subdirectory
#include "Spline/Splines.hh"
using namespace SplinesLoad;
using Splines::real_type;
using Splines::integer;

inline double Saturate(double in, double limit) {
	return abs(in+limit)/2 - abs(in-limit)/2;
}

#include "compileIn.h"

/*
 * Structure for defining circuit elements from the netlist. Defines the type name, the
 * number of the type (and integer used to address the type in the elementDefinitions),
 * the arguments from the netlist (names and values), and the circuit nodes for each terminal,
 * and the parameters that define the circuit's operation.
 */
struct circElement {
	string type; // device type (e.g. "Vsrc" for voltage source
	int typeNum; // location of the device type in the "elementDefs" vector
	vector<string> argNames; // list of argument names read directly from the netlist (just a queue used for temp storage)
	vector<string> argValues; // list of argument values read directly from the netlist (just a queue used for temp storage)
	vector<int> nodes; // net/node number for each terminal of the device
	vector<double> params; // numeric values for the parameters
	vector<int> internalInt; // integer vector to allow circuit element to keep track of it's internal stuff
	vector<double> internalDouble; // double vector to allow circuit element to keep track of it's internal stuff
	vector<boost::circular_buffer<double>> internalCircular; // circular buffer for ring buffer element
	vector<double> defaultParams;
};

/*
 * Structure for holding information about the nets: name, number of drivers, etc.
 */
struct netInfo {
	string name; // name of the net
	int numDrivers; // Number of circuits driving the net. Use to ensure all nets are driven by a single circuit
};

// Format for calling circuit functions.
typedef boost::function<int(int, int, double, int, vec2d&, vec2d&, vector<circElement>&, simulationInformation, int)> circuitFunction;

/*
 * Structure for defining circuit elements. Defines the circuit type, the terminals and
 *   parameters of the circuit, and the function that is used to run the circuit
 */
struct elementDef {
	string type; // device type (e.g. "Vsrc" for voltage source
	vector<string> terminals; // list of terminal names for the device
	vector<string> params; // list of parameter names for the device
	vector<unsigned int> outputs; //which terminals are outputs
	/*
	 * Binding for the function that implements the circuit device:
	 * Returns void
	 * Inputs are call type, device ID number, time, location in time array, voltage source value array,
	 * node voltage value array, elements array (for nodes and parameters)
	 */
	circuitFunction function;
};

enum VerbosityStates {Minimal, Progress};
enum VerbosityStates Verbosity = Minimal;

// Seed with a real random value, if available
//std::random_device r;
// Setup the number generator -- NOTE: may not be uniquely seeded
std::default_random_engine generator;
// Define a normal distribution
const double mean = 0.0;
const double stddev = 1.0;
std::normal_distribution<double> dist(mean, stddev);

void ModuleInitialize(int elem, vector<circElement>& elements, unsigned int memoryLength, vector<int> nodesWMemory, unsigned int internalInt, unsigned int internalDouble) {
   // Initialize circular buffer memory
	elements[elem].internalCircular.resize(elements[elem].nodes.size());
	for (unsigned int node_index=0; node_index<nodesWMemory.size(); node_index++) {
      elements[elem].internalCircular[ nodesWMemory[node_index] ].resize(memoryLength);
	}
	// Initialize int array and double array
   if (internalInt>0)
      elements[elem].internalInt.resize(internalInt);
   if (internalDouble>0)
      elements[elem].internalDouble.resize(internalDouble);
}

inline void ModularCircularPush(int elem, vector<circElement>& elements, vector<int>nodesWMemory, vec2d& nodeValues, int toggle) {
   for (unsigned int node_index=0; node_index<nodesWMemory.size(); node_index++) {
	   elements[elem].internalCircular[ nodesWMemory[node_index] ].push_back(INPUT( nodesWMemory[node_index] ,));
	}
}

#define PUTVARS elem, elements, toggle, nodeValues
inline double Input(unsigned int Term, int Delay, int elem, vector<circElement>& elements, int toggle, vec2d& nodeValues) {
   if (Delay==0)
     return nodeValues[!toggle][elements[elem].nodes[ Term ]];
	else{
      return elements[elem].internalCircular[ Term ][ elements[elem].internalCircular[ Term ].size() + Delay ];
	}

} 

/*
 * Random numbers for modeling noise and mismatch
 */
double genRand() {
	return dist(generator);
}


int printWaveFile(int samplingRate, int numSamples, int numChannels, vec2d inputWaves);
int writeWaveFile(int samplingRate, int numSamples, int numChannels, vector<circElement>& elements, int elem, char* fileName, char* fileNameTemplate);

int csvWriteLine(simulationInformation simInfo, string line, int callType){
	static ofstream dumpFile;
	/*
	if (callType==CALL_TYPE_INITIALIZE) {
		dumpFile.open(simInfo.resultsCsv);
	}
	else if (callType==CALL_TYPE_RUN) {
		dumpFile << line;
	}
	else if (callType==CALL_TYPE_FINISHED) {
		dumpFile.close();
	}
	*/
	return 0;
}

/****************************************************************************************
 * Begin circuit functions
 ****************************************************************************************/
int Vsrc(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_Pos=0, Term_Neg=1;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Vdc=0, Param_WavChan=1;
   static const unsigned int WavChan=0;

	if (callType==CALL_TYPE_INITIALIZE) {
      static const int memoryLength=0, internalIntSize=1, internalDoubleSize=0;
  		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);
		elements[elem].internalInt[WavChan]= (int)round( elements[elem].params[Param_WavChan] );
		if (simInfo.numInputChannels <= elements[elem].internalInt[WavChan]) {
			cerr << "\nError: Vsrc: WavChan is greater than number of channels in wav file.\n";
			return -1;
		}
	}
	else if (callType==CALL_TYPE_RUN){
		if (elements[elem].internalInt[WavChan]<0) {
			// Use dc value
			OUTPUT(Term_Pos) = elements[elem].params[Param_Vdc] + Input(Term_Neg, 0, PUTVARS);
		}
		else {
			// otherwise use wav input
			OUTPUT(Term_Pos) = sourceData[tn][elements[elem].internalInt[WavChan]] + Input(Term_Neg, 0, PUTVARS);
		}
	}
	return 0;
}

int AmpX(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Av=0;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			OUTPUT(Term_Out) = (INPUT(Term_In,) + ADD_NOISE + ADD_OFFSET) * elements[elem].params[Param_Av];
			OUTPUT(Term_Out) = Saturate(OUTPUT(Term_Out), SATURATION_VALUE);
		}
	}
	return 0;
}


int ADC(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
	// floor ( (in - min) / (max - min) * 2^(bits) )

	if (callType==CALL_TYPE_INITIALIZE) {
		elements[elem].internalDouble.resize(2);
		// pre calculate 2^(bits)
		elements[elem].internalDouble[0] = pow(2,elements[elem].params[2]);
		// pre calculate 2^(bits) / (max - min)
		elements[elem].internalDouble[1] = pow(2,elements[elem].params[2])
				/ ( elements[elem].params[1] - elements[elem].params[0] );
	}
	else if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(2) = 0;
			OUTPUT(3) = 0;
		}
		else {
			// Only sample if we have a clock rising edge
			if (INPUT(1,) > 0.5 && INPUT(1,-1) < 0.5) {
				double temp = INPUT(0,);
				// simulate ADC quantization
				temp = floor( ( temp - elements[elem].params[0] ) * elements[elem].internalDouble[1] );
				// normalize to between 0 and 1
				temp = temp / elements[elem].internalDouble[0];
				// apply limits
				temp = max(temp, 0.0);
				temp = min(temp, 1.0);
				OUTPUT(2) = temp; // Store output
				OUTPUT(3) = VDD; // Signal that value is ready
			}
			else if (nodeValues[tn-1][elements[elem].nodes[1]] > 0.5) {
				// While high, hold the value and hold ready signal
				OUTPUT(2) = INPUT(2,); // Store output
				OUTPUT(3) = VDD; // Signal that value is ready
			}
			else {
				// Otherwise, hold the value but mark as not ready
				OUTPUT(2) = INPUT(2,); // Store output
				OUTPUT(3) = 0; // Signal that value is ready
			}
		}
	}
	return 0;
}

int Gate(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Gate=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			if ( INPUT(Term_Gate,) > 0.5 ) {
				OUTPUT(Term_Out) = INPUT(Term_In,);
			}
			else {
				OUTPUT(Term_Out) = 0;
			}
		}
	}
	return 0;
}

int Add2(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In1=0, Term_In2=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Av=0;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			OUTPUT(Term_Out) = (INPUT(Term_In1,) + INPUT(Term_In2,) + ADD_NOISE+ADD_OFFSET) * elements[elem].params[Param_Av];
			OUTPUT(Term_Out) = Saturate(OUTPUT(Term_Out), SATURATION_VALUE);
		}
	}
	return 0;
}


int Bump(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_Pos=0, Term_Neg=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_OuterScale=0, Param_InnerScale=1;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			double diff = INPUT(Term_Pos,) - INPUT(Term_Neg,);
			OUTPUT(Term_Out) = elements[elem].params[Param_OuterScale]/cosh(elements[elem].params[Param_InnerScale]*diff);
		}
	}
	return 0;
}


int Multiplier(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In1=0, Term_In2=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Av=0;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			double in1 = Saturate( INPUT(Term_In1,), SATURATION_VALUE);
			double in2 = Saturate( INPUT(Term_In2,), SATURATION_VALUE);
			OUTPUT(Term_Out) = ( in1 + ADD_NOISE +ADD_OFFSET) * ( in2 + ADD_NOISE +ADD_OFFSET) * elements[elem].params[Param_Av];
		}
	}
	return 0;
}

int Sigmoid_nn(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Av=0;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			OUTPUT(Term_Out) = 1.0/(1.0+exp(-INPUT(Term_In,))) * elements[elem].params[Param_Av];
		}
	}
	return 0;
}

int TANH_nn(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Av=0;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			OUTPUT(Term_Out) = tanh(INPUT(Term_In,)) * elements[elem].params[Param_Av];
		}
	}
	return 0;
}

int RELU_nn(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Av=0;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			OUTPUT(Term_Out) = max(INPUT(Term_In,),0.0) * elements[elem].params[Param_Av];
		}
	}
	return 0;
}

int MultiplierReference(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_X=0, Term_Y=1, Term_Ref=2, Term_Out=3;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Av=0;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			double in1 = Saturate( INPUT(Term_X,) - INPUT(Term_Ref,), SATURATION_VALUE);
			double in2 = Saturate( INPUT(Term_Y,) - INPUT(Term_Ref,), SATURATION_VALUE);
			OUTPUT(Term_Out) = ( in1 + ADD_NOISE +ADD_OFFSET) * ( in2 + ADD_NOISE +ADD_OFFSET) * elements[elem].params[Param_Av];
		}
	}
	return 0;
}

int GainControl(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_PosEnv=0, Term_NegEnv=1, Term_AvOut=2;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_V2I_Gm=0, Param_Iknee=1, Param_RefLog=2, Param_MinLog=3, Param_MaxGain=4, Param_AGCexp=5;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_AvOut) = 0;
		}
		else {
			double b = elements[elem].params[Param_V2I_Gm]*(INPUT(Term_PosEnv,)-INPUT(Term_NegEnv,))-elements[elem].params[Param_Iknee];
			double a = elements[elem].params[Param_RefLog]/max(elements[elem].params[Param_MinLog],b);
			OUTPUT(Term_AvOut) = elements[elem].params[Param_MaxGain]*pow(a,elements[elem].params[Param_AGCexp]);
		}
	}
	return 0;
}

int HalfWave(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Av=0;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			if (INPUT(Term_In,)>0) {
				OUTPUT(Term_Out) =	elements[elem].params[Param_Av]*abs(INPUT(Term_In,));
			}
			else {
				OUTPUT(Term_Out)=0;
			}
		}
	}
	return 0;
}


int MACn(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
  static const unsigned int Term_Out = 8, Param_Offset = 8, Num_Inputs = 8;

	if (callType==CALL_TYPE_RUN) {
    OUTPUT(Term_Out) = elements[elem].params[Param_Offset];
    for (unsigned int i=0; i<Num_Inputs; i++) {
      OUTPUT(Term_Out) += elements[elem].params[i] * INPUT(i,);
		}
	}
	return 0;
}

int LosslessInt(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_rateUp=0, Param_rateDown=1, Param_zeroRes=2, Param_IC=3;
	static const unsigned int rateUpDoub=0, rateDownDoub=1, storage=2;

	if (callType==CALL_TYPE_INITIALIZE) {
		double rateUp=elements[elem].params[Param_rateUp];
		double rateDown=elements[elem].params[Param_rateDown];
		elements[elem].internalDouble.resize(3);
		elements[elem].internalDouble[rateUpDoub] = rateUp/simInfo.sampleRate;
		elements[elem].internalDouble[rateDownDoub] = rateDown/simInfo.sampleRate;
		elements[elem].internalDouble[storage] = elements[elem].params[Param_IC]; // storage element
	}

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = elements[elem].params[Param_IC]; // set initial condition
		}
		else {
			double inputCharge=0;
			if (INPUT(Term_In,) > 0) {
				inputCharge = INPUT(Term_In,) * elements[elem].internalDouble[rateUpDoub];
			}
			else {
				inputCharge = INPUT(Term_In,) * elements[elem].internalDouble[rateDownDoub];
			}
			elements[elem].internalDouble[storage] = max(0.0,elements[elem].internalDouble[storage]+inputCharge);
			elements[elem].internalDouble[storage] = min(2.5,elements[elem].internalDouble[storage]);
			OUTPUT(Term_Out) = elements[elem].internalDouble[storage] + inputCharge*elements[elem].params[Param_zeroRes];
		}
	}
	return 0;
}


int Sub2(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_Pos=0, Term_Neg=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Av=0;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			OUTPUT(Term_Out) =	(INPUT(Term_Pos,) - INPUT(Term_Neg,) + ADD_NOISE + ADD_OFFSET) * elements[elem].params[Param_Av];
			OUTPUT(Term_Out) = Saturate(OUTPUT(Term_Out), SATURATION_VALUE);
		}
	}
	return 0;
}

// OTAx
int OTAx(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_Pos=0, Term_Neg=1, Term_Ibp=2, Term_Out=3;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Ib=0, Param_Scale=1;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			double diff = INPUT(Term_Pos,) - INPUT(Term_Neg,) + ADD_NOISE + ADD_OFFSET;
			if (elements[elem].params[Param_Ib]>0) { // Using floating gate to bias
				OUTPUT(Term_Out) = elements[elem].params[Param_Ib] * tanh(elements[elem].params[Param_Scale] * diff);
			}
			else { // Using pin to adapt bias
				OUTPUT(Term_Out) = -INPUT(Term_Ibp,) * tanh(elements[elem].params[Param_Scale] * diff);
			}
		}
	}
	return 0;
}

// OTAp
int OTAp(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_Pos=0, Term_Neg=1, Term_Ib=2, Term_Vb=3, Term_Out=4;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_PreLog=0, Param_InLog=1, Param_Scale=2, Param_BiaType=3;
   static const unsigned int BiaType=0;

	if (callType==CALL_TYPE_INITIALIZE) {
		elements[elem].internalInt.resize(1);
		elements[elem].internalInt[BiaType] = round(elements[elem].params[Param_BiaType]);
	}
	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0; // OTA output
			if (elements[elem].internalInt[BiaType] == 0) { // bias current input, so bias voltage output
				OUTPUT(Term_Vb)=VDD;
			}
		}
		else {
			double diff = INPUT(Term_Pos,) - INPUT(Term_Neg,) + ADD_NOISE + ADD_OFFSET;
			double biaCurrent;

			if (elements[elem].internalInt[BiaType] == 0) { // bias current input, so bias voltage output
				biaCurrent = - INPUT(Term_Ib,);
				if (biaCurrent > 0) {
					OUTPUT(Term_Vb)=VDD - (elements[elem].params[Param_PreLog] * log(biaCurrent/elements[elem].params[Param_InLog]));
				}
				else {
					OUTPUT(Term_Vb)=VDD;
				}
			}
			else { // bias voltage input
				biaCurrent = elements[elem].params[Param_InLog] * exp( (VDD-INPUT(Term_Vb,))/elements[elem].params[Param_PreLog] );
				OUTPUT(Term_Ib) = -biaCurrent;
			}
			OUTPUT(Term_Out) = biaCurrent * tanh(elements[elem].params[Param_Scale] * diff);
		}
	}
	return 0;
}


// N current mirror
int Exp1(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_PreExp=0, Param_InExp=1;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			if (INPUT(Term_In,) > 0) {
				OUTPUT(Term_Out)= elements[elem].params[Param_PreExp] * exp(INPUT(Term_In,)*elements[elem].params[Param_InExp]);
			}
			else { // mirror won't pass negative currents
				OUTPUT(Term_Out)=0;
			}
		}
	}
	return 0;
}

// N current mirror
int NMir(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
  static const unsigned int Term_In=0, Term_Log=1, Term_MirOut=2;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_PreLog=0, Param_InLog=1, Param_Ioff=2;

	if (callType==CALL_TYPE_RUN) {
    double temp = elements[elem].params[Param_Ioff];
    if (tn>0) {
      temp += INPUT(Term_In,);
    }
    if (elements[elem].nodes[Term_In] == 0) {
      temp=elements[elem].params[Param_Ioff];
    }
    if (temp > 0) {
      OUTPUT(Term_Log)= elements[elem].params[Param_PreLog] * log(temp/elements[elem].params[Param_InLog]);
      OUTPUT(Term_MirOut)=-temp; // mirror current output
    }
    else { // mirror won't pass negative currents
      OUTPUT(Term_Log)=0;
      OUTPUT(Param_Ioff)=0;
    }
	}
	return 0;
}

// P current mirror
int PMir(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
  static const unsigned int Term_In=0, Term_Log=1, Term_MirOut=2;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_PreLog=0, Param_InLog=1, Param_Ioff=2;

	if (callType==CALL_TYPE_RUN) {
    double temp = elements[elem].params[Param_Ioff];
    if (tn>0) {
      temp += INPUT(Term_In,);
    }
    if (elements[elem].nodes[Term_In] == 0) {
      temp=elements[elem].params[Param_Ioff];
    }
    if (temp < 0) {
      OUTPUT(Term_Log)= VDD - ( elements[elem].params[Param_PreLog] * log(-temp/elements[elem].params[Param_InLog]) );
      OUTPUT(Term_MirOut)=-temp; // mirror current output
    }
    else { // mirror won't pass positive currents
      OUTPUT(Term_Log)=VDD;
      OUTPUT(Param_Ioff)=0;
    }
	}
	return 0;
}

int Comparator(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_Pos=0, Term_Neg=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Hysteresis=0;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0) {
         OUTPUT(Term_Out) = 0;
		}
		else {
			double diff = INPUT(Term_Pos,) - INPUT(Term_Neg,);
			// setup hysteresis
			double thresh = elements[elem].params[Param_Hysteresis];
			if (INPUT(Term_Out,) > 0.5) {
				thresh = -thresh;
			}
			if ( ( diff+ADD_NOISE+ADD_OFFSET ) > thresh ) {
				OUTPUT(Term_Out) = VDD;
			}
			else {
				OUTPUT(Term_Out) = 0;
			}
		}
	}
	return 0;
}

int ComparatorSettle(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
  static const unsigned int Term_Pos=0, Term_Neg=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Hysteresis=0, Param_SettleTime=1;

	if (callType==CALL_TYPE_RUN) {
		if (tn==0) {
      OUTPUT(Term_Out) = 0;
		}
		else {
			double diff = INPUT(Term_Pos,) - INPUT(Term_Neg,);
			// setup hysteresis
			double thresh = elements[elem].params[Param_Hysteresis];
			if (INPUT(Term_Out,) > 0.5) {
				thresh = -thresh;
			}
			if ( ( diff+ADD_NOISE+ADD_OFFSET ) > thresh && t>elements[elem].params[Param_SettleTime]) {
				OUTPUT(Term_Out) = VDD;
			}
			else {
				OUTPUT(Term_Out) = 0;
			}
		}
	}
	return 0;
}

int LUT(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
	if (callType==CALL_TYPE_INITIALIZE) {
		elements[elem].internalInt.resize(64);
		for (int i=0; i<64; i++) {
			elements[elem].internalInt[i] = round(elements[elem].params[i]) + 2*round(elements[elem].params[i+64]);
		}
	}

	if (callType==CALL_TYPE_RUN) {
		if (tn==0) {
			OUTPUT(6) = 0;
			OUTPUT(7) = 0;
		}
		else {
			unsigned int address=0;
			int numInputs=6;

			// set outputs to zero by default
			OUTPUT(6) = 0;
			OUTPUT(7) = 0;

			for (int i=0; i<numInputs; i++) {
				if ( INPUT(i,) > 0.5 ) {
					address += pow(2,i);
				}
			}

			if (elements[elem].internalInt[address]%2) {
				OUTPUT(6) = VDD;
			}
			if (elements[elem].internalInt[address]/2) {
				OUTPUT(7) = VDD;
			}

		}
	}
	return 0;
}

int And(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In1=0, Term_In2=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};

	if (callType==CALL_TYPE_RUN) {
		if (tn==0) {
			OUTPUT(Term_Out) = 0;
		}
		else {
			if ( INPUT(Term_In1,) > .5 && INPUT(Term_In2,) > .5) {
				OUTPUT(Term_Out) = VDD;
			}
			else {
				OUTPUT(Term_Out) = 0;
			}
		}
	}
	return 0;
}

int Or(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In1=0, Term_In2=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};

	if (callType==CALL_TYPE_RUN) {
		if (tn==0) {
			OUTPUT(Term_Out) = 0;
		}
		else {
			if ( INPUT(Term_In1,) > .5 || INPUT(Term_In2,) > .5) {
				OUTPUT(Term_Out) = VDD;
			}
			else {
				OUTPUT(Term_Out) = 0;
			}
		}
	}
	return 0;
}

int SaHo(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Clk=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};

	if (callType==CALL_TYPE_RUN) {
		if (tn==0) {
			OUTPUT(Term_Out) = 0;
		}
		else {
			if ( INPUT(Term_Clk,) > .5 ) {
				OUTPUT(Term_Out) = INPUT(Term_In,);
			}
			else {
				OUTPUT(Term_Out) = INPUT(Term_Out,);
			}
		}
	}
	return 0;
}

// Circular buffer
int CBuf(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
  static const unsigned int Term_In=0, Term_Clk=1, Term_BufferLoc=2;
  static const vector<int> nodesWMemory = {};
  static const unsigned int Param_Capacity=0;
  static const unsigned int Clk=0;

  if (callType==CALL_TYPE_INITIALIZE) {
    elements[elem].internalDouble.resize(1);
    elements[elem].internalDouble[Clk]=0;
    elements[elem].internalCircular.resize( 1 );
    elements[elem].internalCircular[0].resize( elements[elem].params[Param_Capacity] );
  }
  if (callType==CALL_TYPE_RUN) {
    OUTPUT(Term_BufferLoc) = elem;
    if (tn<=1) {
    }
    else {
      // All the peaks and times are linearly placed in the buffer
      if ( (INPUT(Term_Clk,) > .5) && (elements[elem].internalDouble[Clk] < .5)) {
        elements[elem].internalCircular[0].push_back( t );
        elements[elem].internalCircular[0].push_back( INPUT(Term_In,) );
      }
    }
    elements[elem].internalDouble[Clk]=INPUT(Term_Clk,);
  }
  if (callType==CALL_TYPE_FINISHED) {

  }
  return 0;
}


// Write direct to ONod's output buffer. Allows to fill in old time values
inline void writeONod(double value, unsigned int timeStep, unsigned int ONodElem, unsigned int ONodTerm, vector<circElement>& elements) {
		  //cout << "writeONod: " << ONodTerm << ", " << timeStep << ", " << value << "\n";
	elements[ONodElem].internalCircular[ONodTerm][timeStep]=value;
}

// Read direct from ONod's output buffer
inline double readONod(unsigned int timeStep, unsigned int ONodElem, unsigned int ONodTerm, vector<circElement>& elements) {
	return elements[ONodElem].internalCircular[ONodTerm][timeStep];
}

// Find ONod's place in elements vector and the desired terminal's place in ONod
void findONod(unsigned int& ONodElem, unsigned int& ONodTerm, vector<circElement>& elements, unsigned int elem, unsigned int term) {
	// Find ONod's place
	for (unsigned int i=0; i<elements.size(); i++) {
		if (elements[i].type.compare("ONod") == STRING_EQUAL) {
			ONodElem=i;
		}
	}
	// Find terminal
	for (unsigned int i=0; i<elements[ONodElem].nodes.size(); i++) {
		if (elements[ONodElem].nodes[i] == elements[elem].nodes[term]) {
			ONodTerm=i;
		}
	}
}

// Reconstruction
int Reco(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_BufferLoc=0, Term_ReconTrigger=1, Term_Out=2;
	static const vector<int> nodesWMemory = {Term_ReconTrigger};
	static const unsigned int Param_Method=0, Param_Duration=1;
	static const unsigned int ReconTrigger=0;

	// The spline type is 'pchip'
    PchipSpline    pc;

	// Needed to interpolate,,, use simInfo.sampleRate
	double timeNow = 0.0;

	if (callType==CALL_TYPE_INITIALIZE) {
      int memoryLength=1, internalIntSize=0, internalDoubleSize=1;
  		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);
		elements[elem].internalDouble[ReconTrigger]=0;
	}
	if (callType==CALL_TYPE_RUN) {
		if (tn<=1) {
		}
		else {
			if ( (INPUT(Term_ReconTrigger,) > .5) && (elements[elem].internalDouble[ReconTrigger] < .5)) {

				// Space for over 16000 points (1 second) at 16kHz sampling rate
				// when running pchip interpolation
				double X[16000];
				double Y[16000];

				// Place one last sample into circular buffer
				// Not doing this since we don't want to kick the
				// oldest value out of the circular buffer
				 //cout << "Time is now: " << t << "\n";
				//double currentVal = nodeValues[tn-1][elements[INPUT(0,)].nodes[0]];
				//elements[INPUT(0,)].internalCircular.push_back( t );
				//elements[INPUT(0,)].internalCircular.push_back( currentVal );

				// Only go back 0.5 seconds at most,,, and make sure sample time > 0
				int j = 0;
				for (unsigned int i=0; i<elements[INPUT(Term_BufferLoc,)].internalCircular[0].size()/2; i++) {
					if ((elements[INPUT(Term_BufferLoc,)].internalCircular[0][i*2] > t-0.5) && (elements[INPUT(Term_BufferLoc,)].internalCircular[0][i*2] > 0)){
						// Place into X and Y with increasing time X
						X[j] = elements[INPUT(Term_BufferLoc,)].internalCircular[0][i*2];
						Y[j] = elements[INPUT(Term_BufferLoc,)].internalCircular[0][i*2+1];
						//cout << "CB i "  << i << " j " << j << ", " <<  " X[j] " << X[j] << " Y[j] " << Y[j] << "\n";
						j++;
					}
				}
				// Drop the current value into the last place
				double currentVal = nodeValues[!toggle][elements[INPUT(Term_BufferLoc,)].nodes[0]];
				X[j] = t;
				Y[j] = currentVal;
				j++;
				//cout << "The last time in CBuf is " << X[j-1] << "\n";
			    // Build the spline, then evaluate the spline
			    int numPts = j; //elements[INPUT(0,)].internalCircular.size()/2;
				//cout << "Buffer CAPACITY: numPts = " << numPts << "\n";
				//cout << "Building the Spline\n" ;
			    if (numPts>1) {
				    pc.build(X,Y, numPts);
			    }

				// Zero the buffer when finished with it. Necessary? How to do it? Need to push numbers in?
				// Should Recon even be able to do this?
				//for (unsigned int i=0; i<elements[INPUT(0,)].internalCircular[0].size()/2; i++) {
					//INPUT(2,-i*2) = 0;
					//INPUT(2,-i*2+1) = 0;
				//}
				// And evaluate the spline
				//cout << "Evaluating the Spline\n";
				// The earliest time and the latest time
				// timeNow is the current node time. Would like it to be very close an just after
				// the last time in the circular buffer which is the latest
				timeNow = t; //X[numPts-1];
				//cout << "Start Time (Beginning of Buffer): " << X[0] << "\n";
				//cout << "End Time (Last Sampled Peak before Trigger): " << timeNow << "\n";

				unsigned int ONodElem=0, ONodTerm=0;
				findONod(ONodElem, ONodTerm, elements, elem, Term_Out);
				//cout << "ONodElem " << ONodElem << " ONodTerm " << ONodTerm << "\n";
				int i = 0;
				//cout << "tn-i " << tn-i << "; timeNow " << timeNow << "\n";
				while (timeNow > X[0] && i < simInfo.sampleRate) {
					if (timeNow <= ( X[numPts-1] + 0.5/simInfo.sampleRate ) ) {
						// cout << "Pchip Output:" << ", " << timeNow << ", " << pc(timeNow) << "\n";

						// Filling the buffer in reverse order
						//INPUT(2,-i) = pc(timeNow);
						if (numPts>1) {
						    writeONod(pc(timeNow), tn-i, ONodElem, ONodTerm, elements);
						}

					}
					// Going backward in time from the last sampled point
					timeNow = timeNow - 1.0/simInfo.sampleRate;
					i++;
				}
				//cout << "tn-i " << tn-i << "; timeNow " << timeNow << "\n";
				//cout << "Spline evaluated at sampling rate\n";

			}
		}
		if ( (INPUT(Term_ReconTrigger,) < .5) && (elements[elem].internalDouble[ReconTrigger] > .5)) {
			// Clear out on falling edge
			for (unsigned int i=0; i<elements[INPUT(Term_BufferLoc,)].internalCircular[0].size(); i++) {
 				elements[INPUT(Term_BufferLoc,)].internalCircular[0][i]=0;
			}
		}
		elements[elem].internalDouble[ReconTrigger]=INPUT(Term_ReconTrigger,);
	}
	if (callType==CALL_TYPE_FINISHED) {

	}
	return 0;
}

int Nand(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In1=0, Term_In2=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};

	if (callType==CALL_TYPE_RUN) {
		if (tn==0) {
			OUTPUT(Term_Out) = 0;
		}
		else {
			if ( INPUT(Term_In1,) < .5 || INPUT(Term_In2,) < .5) {
				OUTPUT(Term_Out) = VDD;
			}
			else {
				OUTPUT(Term_Out) = 0;
			}
		}
	}
	return 0;
}

int Nor(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In1=0, Term_In2=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};

	if (callType==CALL_TYPE_RUN) {
		if (tn==0) {
			OUTPUT(Term_Out) = 0;
		}
		else {
			if ( INPUT(Term_In1,) < .5 && INPUT(Term_In2,) < .5) {
				OUTPUT(Term_Out) = VDD;
			}
			else {
				OUTPUT(Term_Out) = 0;
			}
		}
	}
	return 0;
}


int Timr(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
	static const unsigned int Term_In=0, Term_Out=1; 
	static const vector<int> nodesWMemory = {Term_In};
	static const unsigned int Param_Slope=0;
	static const unsigned int Slope=0, InternalCharge=1;

	if (callType==CALL_TYPE_INITIALIZE) {
		static const int memoryLength=1, internalIntSize=0, internalDoubleSize=2;
		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);
		// discrete slope = continuous slope / Fs
		elements[elem].internalDouble[Slope] = elements[elem].params[Param_Slope]/simInfo.sampleRate;
	}

	if (callType==CALL_TYPE_RUN) {
		if (tn<=1) {
			OUTPUT(Term_Out) = 0; // initialize output
			elements[elem].internalDouble[InternalCharge] = 0; // initialize timer duration count
		}
		else {	
			if (Input(Term_In, 0, PUTVARS) > 0.5 && Input(Term_In,-1,PUTVARS) < 0.5) {
				OUTPUT(Term_Out) = elements[elem].internalDouble[InternalCharge];
				elements[elem].internalDouble[InternalCharge] = 0;
			}
			else {
				OUTPUT(Term_Out) = INPUT(Term_Out,);
			}

			elements[elem].internalDouble[InternalCharge] += elements[elem].internalDouble[Slope];
			if (elements[elem].internalDouble[InternalCharge] > VDD) {
				elements[elem].internalDouble[InternalCharge] = VDD;
			}
		}
		ModularCircularPush(elem, elements, nodesWMemory, nodeValues, toggle); 
	}
	return 0;
}

int Not(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
   static const vector<int> nodesWMemory = {};

	if (callType==CALL_TYPE_RUN) {
		if (tn==0) {
			OUTPUT(Term_Out) = 0;
		}
		else {
			if ( INPUT(Term_In,) < .5 ) {
				OUTPUT(Term_Out) = VDD;
			}
			else {
				OUTPUT(Term_Out) = 0;
			}
		}
	}
	return 0;
}


int Pulse(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {Term_In};
	static const unsigned int Param_Time=0;
   static const unsigned int PulseSamples=0, SamplesHigh=1;

	if (callType==CALL_TYPE_INITIALIZE) {
      static const int memoryLength=1, internalIntSize=2, internalDoubleSize=0;
  		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);
		elements[elem].internalInt[PulseSamples] = round(elements[elem].params[Param_Time]*simInfo.sampleRate)-1;
	}

	if (callType==CALL_TYPE_RUN) {
		if (tn<=1) {
			OUTPUT(Term_Out) = 0; // initialize output
			elements[elem].internalInt[SamplesHigh]=0; // intitalize pulse duration count
		}
		else {
			if (Input(Term_In, 0, PUTVARS)<0.5) {
				OUTPUT(Term_Out)=0;
				elements[elem].internalInt[Term_Out]=0;
			}
			else if (Input(Term_In, 0, PUTVARS) > 0.5 && Input(Term_In,-1,PUTVARS) < 0.5) {
				OUTPUT(Term_Out)=VDD;
				elements[elem].internalInt[SamplesHigh]++;
			}
			// input is high, not original transition
			else {
				if (elements[elem].internalInt[SamplesHigh]<=elements[elem].internalInt[PulseSamples]) {
					OUTPUT(Term_Out)=VDD;
					elements[elem].internalInt[SamplesHigh]++;
				}
				else {
					OUTPUT(Term_Out)=0;
				}
			}
		}
		ModularCircularPush(elem, elements, nodesWMemory, nodeValues, toggle); 
	}
	return 0;
}

int Delay(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {Term_In};
	static const unsigned int Param_Delay=0;
   static const unsigned int Delay=0;

	if (callType==CALL_TYPE_INITIALIZE) {
	   int memoryLength=round(elements[elem].params[Param_Delay]*simInfo.sampleRate)-1;
      static const int internalIntSize=1, internalDoubleSize=0;
  		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);
      elements[elem].internalInt[Delay] = memoryLength;
	}

	if (callType==CALL_TYPE_RUN) {
		if (tn > elements[elem].internalInt[Delay]) {
			// OUTPUT(Term_Out) = INPUT2(Term_In,-elements[elem].internalInt[Delay]);
      OUTPUT(Term_Out) = Input(Term_In, -elements[elem].internalInt[Delay], PUTVARS);
		}
		else {
			OUTPUT(Term_Out) = 0;
		}
		ModularCircularPush(elem, elements, nodesWMemory, nodeValues, toggle);
	}
	return 0;
}

int DelaySamples(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {Term_In};
	static const unsigned int Param_Delay=0;

	if (callType==CALL_TYPE_INITIALIZE) {
	   int memoryLength=elements[elem].params[Param_Delay];
      static const int internalIntSize=0, internalDoubleSize=0;
  		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);
	}

	if (callType==CALL_TYPE_RUN) {
		if (tn > elements[elem].params[Param_Delay]) {
			// OUTPUT(Term_Out) = INPUT(Term_In,-elements[elem].params[Param_Delay]);
      OUTPUT(Term_Out) = Input(Term_In, -elements[elem].params[Param_Delay], PUTVARS);
		}
		else {
			OUTPUT(Term_Out) = 0;
		}
		ModularCircularPush(elem, elements, nodesWMemory, nodeValues, toggle); 
	}
	return 0;
}

int FreqDiv(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {Term_In};
	static const unsigned int Param_Div=0;
   static const unsigned int Div=0, CycleCount=1;

	if (callType==CALL_TYPE_INITIALIZE) {
      static const int memoryLength=1, internalIntSize=2, internalDoubleSize=0;
  		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);
		elements[elem].internalInt[Div] = round(elements[elem].params[Param_Div]);
		elements[elem].internalInt[CycleCount] = 0;
	}

	if (callType==CALL_TYPE_RUN) {
		if (tn > 2) {

			// if input toggles
			if ( (INPUT2(Term_In,-1) < 0.5 && INPUT(Term_In,) >= 0.5) || (INPUT(Term_In,-1) >= 0.5 && INPUT(Term_In,) < 0.5) ) {
				// then increment cycle count
				elements[elem].internalInt[CycleCount]++;

				// and if cycle count reaches parameter
				if (elements[elem].internalInt[CycleCount]==elements[elem].internalInt[Div]) {
					// then reset the cycle count
					elements[elem].internalInt[CycleCount] = 0;

					// and toggle the output
					if (INPUT(Term_Out,) < 0.5) {
						OUTPUT(Term_Out) = VDD;
					}
					else {
						OUTPUT(Term_Out) = 0;
					}

				}
				else {
					if (INPUT(Term_Out,) > 0.5) {
						OUTPUT(Term_Out) = VDD;
					}
					else {
						OUTPUT(Term_Out) = 0;
					}
				}

			}
			else {
				if (INPUT(Term_Out,) > 0.5) {
					OUTPUT(Term_Out) = VDD;
				}
				else {
					OUTPUT(Term_Out) = 0;
				}
			}
		}
		else {
			OUTPUT(Term_Out) = 0;
		}
		ModularCircularPush(elem, elements, nodesWMemory, nodeValues, toggle); 
	}
	return 0;
}

int DFF(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_D=0, Term_Clk=1, Term_R=2, Term_Q=3;
	static const vector<int> nodesWMemory = {Term_Clk};

	if (callType==CALL_TYPE_INITIALIZE) {
      static const int memoryLength=1, internalIntSize=0, internalDoubleSize=0;
  		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);
	}
	if (callType==CALL_TYPE_RUN) {
		if (tn<2){
			OUTPUT(Term_Q) = 0;
		}
		else {
			// keep previous value by default
			OUTPUT(Term_Q) = INPUT(Term_Q,);

			// if clock is high
			if (INPUT(Term_Clk,) > 0.5 && INPUT2(Term_Clk,-1) < 0.5) {
				// and if D input is high
				if (INPUT(Term_D,) > 0.5) {
					// then set the output
					OUTPUT(Term_Q) = VDD;
				}
				else {
					OUTPUT(Term_Q) = 0;
				}
			}
			// if reset
			if (INPUT(Term_R,) > 0.5) {
				OUTPUT(Term_Q) = 0;
			}
		}
		ModularCircularPush(elem, elements, nodesWMemory, nodeValues, toggle); 
	}
	return 0;
}


int JKFF(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_J=0, Term_K=1, Term_Clk=2, Term_Q=3;
	static const vector<int> nodesWMemory = {Term_Clk};

	if (callType==CALL_TYPE_INITIALIZE) {
      static const int memoryLength=1, internalIntSize=0, internalDoubleSize=0;
  		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);
	}
	if (callType==CALL_TYPE_RUN) {
		if (tn<2){
			OUTPUT(Term_Q) = 0;
		}
		else {
			// keep previous value by default
			OUTPUT(Term_Q) = INPUT(Term_Q,);

			// if clock is high
			if (INPUT(Term_Clk,) > 0.5) {
				// if J and K are high
				if (INPUT(Term_J,) > 0.5 && INPUT(Term_K,) > 0.5) {
					// then toggle if this was rising clock edge
					if (INPUT2(Term_Clk,-1) < 0.5) {
						if (INPUT(Term_Q,)>0.5) {
							OUTPUT(Term_Q)=0;
						}
						else {
							OUTPUT(Term_Q)=VDD;
						}
					}
				}
				// otherwise treat as SR flip flop
				// if J input is high & K input is low
				else if (INPUT(Term_J,) > 0.5 && INPUT(Term_K,) < 0.5) {
					// then set the output
					OUTPUT(Term_Q) = VDD;
				}
				// or if J input is low & K input is high
				else if (INPUT(Term_J,) < 0.5 && INPUT(Term_K,) > 0.5) {
					// then reset the output
					OUTPUT(Term_Q) = 0;
				}
			}
		}
		ModularCircularPush(elem, elements, nodesWMemory, nodeValues, toggle); 
	}
	return 0;
}


int PkDe(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
   static const unsigned int Param_a=0, Param_d=1, Param_At=2, Param_Ro=3, Param_f=4;

	if (callType==CALL_TYPE_INITIALIZE) {
		double p, At, RO, f, Re, L, Rg, RHS, d, a;
		const double pi = boost::math::constants::pi<double>();

		// allocate space for the attack and decay parameters
		elements[elem].internalDouble.resize(2);

		// check if we're using tracking level
		if (elements[elem].params[Param_a]<1e-4) {
			// calculate the tracking levels
			At = elements[elem].params[Param_At];
			RO = elements[elem].params[Param_Ro];
			f = elements[elem].params[Param_f];

			//cout << "At=" << At << " RO=" << RO << " f=" << f << " pi=" << pi << "\n";
			RO=RO/2;
			//%--------------------------------------------
			//%--- harmonic balance iterating method ------
			//%--------------------------------------------
			p=-pi/2;
			Re=sqrt(1+RO*RO-RO*cos(p));
			L=2/pi*(Re/At*sqrt(1-(At*At)/(Re*Re))+asin(At/Re));
			Rg=-(1+L)/(1-L);
			RHS=Re*(Rg+1)/(4*RO)+Re*(1-Rg)/(pi*2*RO)*asin(At/Re)+At*(1-Rg)/(2*pi*RO)*sqrt(1-(At*At)/(Re*Re));
			d=1/sqrt((RHS*RHS-1)/(2*2*pi*pi*f*f));

			//cout << "p=" << p << " Re=" << Re << " L=" << " Rg=" << " RHS=" << RHS << " d=" << d << "\n";
			//for (int i=0
			    p=atan(-2*pi*f/d);
			    Re=sqrt(1+RO*RO-RO*cos(p));
			    L=2/pi*(Re/At*sqrt(1-(At*At)/(Re*Re))+asin(At/Re));
			    Rg=-(1+L)/(1-L);
			    RHS=Re*(Rg+1)/(4*RO)+Re*(1-Rg)/(pi*2*RO)*asin(At/Re)+At*(1-Rg)/(2*pi*RO)*sqrt(1-At*At/(Re*Re));
			    d=1/sqrt((RHS*RHS-1)/(2*2*pi*pi*f*f));
			//end
			a=Rg*d;
			//cout << "p=" << p << " Re=" << Re << " L=" << " Rg=" << " RHS=" << RHS << " d=" << d << " a=" << a << "\n";

			elements[elem].internalDouble[Param_a]= a / simInfo.sampleRate * elements[elem].defaultParams[PARAM_RUNPERIOD];
			elements[elem].internalDouble[Param_d]= d / simInfo.sampleRate * elements[elem].defaultParams[PARAM_RUNPERIOD];
		}
		else {
			// use the attack and decay rates
			elements[elem].internalDouble[Param_a]=elements[elem].params[Param_a] / simInfo.sampleRate * elements[elem].defaultParams[PARAM_RUNPERIOD];
			elements[elem].internalDouble[Param_d]=elements[elem].params[Param_d] / simInfo.sampleRate * elements[elem].defaultParams[PARAM_RUNPERIOD];
		}
	}
	else if (callType==CALL_TYPE_RUN){

		if (tn==0){
			OUTPUT(Term_Out) = OUTPUT(Term_In);
		}
		else {
			double diff=( INPUT(Term_In,) - INPUT(Term_Out,) ) + ADD_NOISE + ADD_OFFSET;
			diff = Saturate(diff, SATURATION_VALUE);
			if (diff>0) {
				// attack
				OUTPUT(Term_Out) = INPUT(Term_Out,) + diff*elements[elem].internalDouble[Param_a];
			}
			else {
				// decay
				OUTPUT(Term_Out) = INPUT(Term_Out,) + diff*elements[elem].internalDouble[Param_d];
			}
		}

	}
	return 0;
}


int PkDeDynamic(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
   static const unsigned int Param_a=0, Param_d=1, Param_At=2, Param_Ro=3, Param_f=4, Param_Par=5, Param_a_par=2, Param_d_par=3;
   static const unsigned int atkMem=4, decMem=5;

	if (callType==CALL_TYPE_INITIALIZE) {
		double p, At, RO, f, Re, L, Rg, RHS, d, a;
		const double pi = boost::math::constants::pi<double>();

		// allocate space for the attack and decay parameters and attack and decay parasitic charge parameters and storing attack and decay parasitic nodes
		elements[elem].internalDouble.resize(6);

		// check if we're using tracking level
		if (elements[elem].params[Param_a]<1e-4) {
			// calculate the tracking levels
			At = elements[elem].params[Param_At];
			RO = elements[elem].params[Param_Ro];
			f = elements[elem].params[Param_f];

			//cout << "At=" << At << " RO=" << RO << " f=" << f << " pi=" << pi << "\n";
			RO=RO/2;
			//%--------------------------------------------
			//%--- harmonic balance iterating method ------
			//%--------------------------------------------
			p=-pi/2;
			Re=sqrt(1+RO*RO-RO*cos(p));
			L=2/pi*(Re/At*sqrt(1-(At*At)/(Re*Re))+asin(At/Re));
			Rg=-(1+L)/(1-L);
			RHS=Re*(Rg+1)/(4*RO)+Re*(1-Rg)/(pi*2*RO)*asin(At/Re)+At*(1-Rg)/(2*pi*RO)*sqrt(1-(At*At)/(Re*Re));
			d=1/sqrt((RHS*RHS-1)/(2*2*pi*pi*f*f));

			//cout << "p=" << p << " Re=" << Re << " L=" << " Rg=" << " RHS=" << RHS << " d=" << d << "\n";
			//for (int i=0
			    p=atan(-2*pi*f/d);
			    Re=sqrt(1+RO*RO-RO*cos(p));
			    L=2/pi*(Re/At*sqrt(1-(At*At)/(Re*Re))+asin(At/Re));
			    Rg=-(1+L)/(1-L);
			    RHS=Re*(Rg+1)/(4*RO)+Re*(1-Rg)/(pi*2*RO)*asin(At/Re)+At*(1-Rg)/(2*pi*RO)*sqrt(1-At*At/(Re*Re));
			    d=1/sqrt((RHS*RHS-1)/(2*2*pi*pi*f*f));
			//end
			a=Rg*d;
			//cout << "p=" << p << " Re=" << Re << " L=" << " Rg=" << " RHS=" << RHS << " d=" << d << " a=" << a << "\n";

			elements[elem].internalDouble[Param_a]= a / simInfo.sampleRate * elements[elem].defaultParams[PARAM_RUNPERIOD];
			elements[elem].internalDouble[Param_d]= d / simInfo.sampleRate * elements[elem].defaultParams[PARAM_RUNPERIOD];
		}
		else {
			// use the attack and decay rates
			elements[elem].internalDouble[Param_a]=elements[elem].params[Param_a] / simInfo.sampleRate * elements[elem].defaultParams[PARAM_RUNPERIOD];
			elements[elem].internalDouble[Param_d]=elements[elem].params[Param_d] / simInfo.sampleRate * elements[elem].defaultParams[PARAM_RUNPERIOD];
		}
    elements[elem].internalDouble[Param_a_par]= elements[elem].internalDouble[Param_a] * elements[elem].params[Param_Par];
    elements[elem].internalDouble[Param_d_par]= elements[elem].internalDouble[Param_d] * elements[elem].params[Param_Par];
    elements[elem].internalDouble[atkMem] = 0;
    elements[elem].internalDouble[decMem] = 0;
	}
	else if (callType==CALL_TYPE_RUN){

		if (tn==0){
			OUTPUT(Term_Out) = OUTPUT(Term_In);
		}
		else {
			double diff=( INPUT(Term_In,) - INPUT(Term_Out,) ) + ADD_NOISE + ADD_OFFSET;
      OUTPUT(Term_Out) = INPUT(Term_Out,);
			diff = Saturate(diff, SATURATION_VALUE);

      // Charge parasitic nodes
      elements[elem].internalDouble[atkMem] = elements[elem].internalDouble[atkMem] * (1 - elements[elem].internalDouble[Param_a_par]) + diff * elements[elem].internalDouble[Param_a_par];
      elements[elem].internalDouble[decMem] = elements[elem].internalDouble[decMem] * (1 - elements[elem].internalDouble[Param_d_par]) + diff * elements[elem].internalDouble[Param_d_par];
			if (elements[elem].internalDouble[atkMem]>0) {
				// attack
				OUTPUT(Term_Out) = OUTPUT(Term_Out) + elements[elem].internalDouble[atkMem]*elements[elem].internalDouble[Param_a];
			}
      if (elements[elem].internalDouble[decMem]<0) {
        // decay
				OUTPUT(Term_Out) = OUTPUT(Term_Out) + elements[elem].internalDouble[decMem]*elements[elem].internalDouble[Param_d];
			}
		}

	}
	return 0;
}


int Res2(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_1M=0, Term_Tap=1, Term_100k=2;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Resistance=0;


	if (callType==CALL_TYPE_INITIALIZE) {

	}
	else if (callType==CALL_TYPE_RUN){

		if (tn==0){
			OUTPUT(Term_Tap) = 0;
		}
		else {
			if (elements[elem].params[Param_Resistance] > 500e3) { // 1M
				OUTPUT(Term_Tap) = INPUT(Term_1M,) + elements[elem].params[Param_Resistance]*INPUT(Term_100k,);
			}
			else { // 100k
				OUTPUT(Term_Tap) = INPUT(Term_100k,) + elements[elem].params[Param_Resistance]*INPUT(Term_1M,);
			}
		}

	}
	return 0;
}

int PrintTimeStamp(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
	static const unsigned int Term_Trig=0;
	static const vector<int> nodesWMemory = {Term_Trig};
	static const unsigned int State=0, LastTime=0;

	if (callType==CALL_TYPE_INITIALIZE) {
		static const int memoryLength=1, internalIntSize=1, internalDoubleSize=1;
		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);
    elements[elem].internalInt[State]= 0;
	}

	if (callType==CALL_TYPE_RUN) {
    elements[elem].internalDouble[LastTime]= t;
		if (tn>1) {	
      // Rising edge
			if (Input(Term_Trig, 0, PUTVARS) > 0.5 && Input(Term_Trig,-1,PUTVARS) < 0.5) {
        printf("Event trigger from %fs",t);
        elements[elem].internalInt[State]= 1;
			}
      // Falling edge
			if (Input(Term_Trig, 0, PUTVARS) < 0.5 && Input(Term_Trig,-1,PUTVARS) > 0.5 && elements[elem].internalInt[State]==1) {
        printf(" to %fs\n",t);
        elements[elem].internalInt[State]= 0;
			}
		}
		ModularCircularPush(elem, elements, nodesWMemory, nodeValues, toggle);
	}

  // Check if need to close out an event
  if (callType==CALL_TYPE_FINISHED) {
    if (elements[elem].internalInt[State] == 1) {
      printf(" to %fs\n",elements[elem].internalDouble[LastTime]);
    }
  }
	return 0;
}


int ChPu(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Down=0, Param_Up=1;


	if (callType==CALL_TYPE_INITIALIZE) {

	}
	else if (callType==CALL_TYPE_RUN){

		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			if (INPUT(Term_In,) > (VDD/2)) {
				OUTPUT(Term_Out) = -elements[elem].params[Param_Down];
			}
			else {
				OUTPUT(Term_Out) = elements[elem].params[Param_Up];
			}

		}
	}
	return 0;
}

int ChP2(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_Up=0, Term_Down=1, Term_Out=2;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Down=0, Param_Up=1;

	if (callType==CALL_TYPE_INITIALIZE) {

	}
	else if (callType==CALL_TYPE_RUN){
		OUTPUT(Term_Out)=0;
		if (tn>0) {
			if (INPUT(Term_Up,) > (VDD/2)) {
				OUTPUT(Term_Out) += -elements[elem].params[Param_Down];
			}
			if (INPUT(Term_Down,) > (VDD/2)) {
				OUTPUT(Term_Out) += elements[elem].params[Param_Up];
			}
		}
	}
	return 0;
}

int AdTa(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_rate=0, Param_S=1;

	if (callType==CALL_TYPE_INITIALIZE) {

	}
	else if (callType==CALL_TYPE_RUN){

		if (tn==0){
			OUTPUT(Term_Out) = 0;
		}
		else {
			double diff=( INPUT(Term_In,) - INPUT(Term_Out,) )*0.7/.0259 + ADD_NOISE + ADD_OFFSET;
			//diff = Saturate(diff, SATURATION_VALUE);
			double rate = elements[elem].params[Param_rate] // Ib/C
						 * (sinh(diff))
						 / (1+elements[elem].params[Param_S]/2.0+cosh(diff));
			OUTPUT(Term_Out) = INPUT(Term_In,) + rate / simInfo.sampleRate;
		}

	}
	return 0;
}


int bilinearTransform(double a2, double a1, double a0, double b2, double b1, double b0,
	double& az2, double& az1, double& az0, double& bz2, double& bz1, double& bz0, int sampleRate){
	double c, c_sq;
	// Apply bilinear transform
	c=2*sampleRate; // 2*Fs
	c_sq=c*c;
	if (a2<0) { // 1st order filter
		az0=(0*c_sq+a1*c+a0);
		bz0=(0*c_sq+b1*c+b0)/az0;
		bz1=(-2*0*c_sq+2*b0)/az0;
		bz2=(0*c_sq-b1*c+b0)/az0;
		az1=(-2*0*c_sq+2*a0)/az0;
		az2=(0*c_sq-a1*c+a0)/az0;
		az0=1;

		// remap since we only have two coefficients
		az1=az2;
		az2=0;
		bz1=bz2;
		bz2=0;
	}
	else { // 2nd order filter
		az0=(a2*c_sq+a1*c+a0);
		bz0=(b2*c_sq+b1*c+b0)/az0;
		bz1=(-2*b2*c_sq+2*b0)/az0;
		bz2=(b2*c_sq-b1*c+b0)/az0;
		az1=(-2*a2*c_sq+2*a0)/az0;
		az2=(a2*c_sq-a1*c+a0)/az0;
		az0=1;

	}
	return 0;
}

int FiltTF(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Out=1;
	static const vector<int> nodesWMemory = {Term_In, Term_Out};
	static const unsigned int Param_Num2=0, Param_Num1=1, Param_Num0=2, Param_Den2=3, Param_Den1=4, Param_Den0=5;

	if (callType==CALL_TYPE_INITIALIZE) {
		double a2, a1, a0, b2, b1, b0, az0, bz0, az1, bz1, az2, bz2;

      static const int memoryLength=2, internalIntSize=0, internalDoubleSize=6;
  		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);

		// Copy user's parameters
		a2=elements[elem].params[Param_Den2]; // Den2
		a1=elements[elem].params[Param_Den1]; // Den1
		a0=elements[elem].params[Param_Den0]; // Den0
		b2=elements[elem].params[Param_Num2]; // Num2
		b1=elements[elem].params[Param_Num1]; // Num1
		b0=elements[elem].params[Param_Num0]; // Num0

		bilinearTransform(a2, a1, a0, b2, b1, b0, az2, az1, az0, bz2, bz1, bz0, simInfo.sampleRate);

		// Store z-domain coefficients
		elements[elem].internalDouble[0]=az0;
		elements[elem].internalDouble[1]=az1;
		elements[elem].internalDouble[2]=az2;
		elements[elem].internalDouble[3]=bz0;
		elements[elem].internalDouble[4]=bz1;
		elements[elem].internalDouble[5]=bz2;
	}
	else if (callType==CALL_TYPE_RUN){
		OUTPUT(Term_Out) = 0; // initialize output node
		// apply numerator
		for (int i=0; i<3; i++) {
			OUTPUT(Term_Out) += (Input(Term_In,-i, PUTVARS) + ADD_NOISE + ADD_OFFSET) * elements[elem].internalDouble[3+i];
		}
		// apply denominator
		for (int i=1; i<3; i++) {
			OUTPUT(Term_Out) -= Input(Term_Out,-i+1, PUTVARS) * elements[elem].internalDouble[i];
		}
		OUTPUT(Term_Out) = Saturate(OUTPUT(Term_Out), SATURATION_VALUE);
		ModularCircularPush(elem, elements, nodesWMemory, nodeValues, toggle); 
	}
	return 0;
}


int Filt(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Ref=1, Term_Out=2;
	static const vector<int> nodesWMemory = {Term_In, Term_Out};
	static const unsigned int Param_fc=0, Param_Q=1, Param_fhi=2, Param_flo=3, Param_Av=4, Param_type=5, Param_order=6;

	if (callType==CALL_TYPE_INITIALIZE) {
		double a2, a1, a0, b2, b1, b0, az0, bz0, az1, bz1, az2, bz2, fc, Q, fhi, flo, Av, type, order, tauc, taul, tauh;
		const double pi = boost::math::constants::pi<double>();

      static const int memoryLength=2, internalIntSize=0, internalDoubleSize=6;
  		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);

		// Copy user's parameters
		fc=elements[elem].params[Param_fc];
		Q=elements[elem].params[Param_Q];
		fhi=elements[elem].params[Param_fhi];
		flo=elements[elem].params[Param_flo];
		Av=elements[elem].params[Param_Av];
		type=elements[elem].params[Param_type];
		order=elements[elem].params[Param_order];
		if (abs(Av)<1e-5) {
			Av=1;
		}
		if (fc>1e-3) { // use fc/Q biasing
			tauc = 1/(fc*2*pi);

			if (order<1.5) { // first order
				// denominator
				a2=-1; // -1 because we're not using it
				a1=tauc;
				a0=1;
				// numerator
				b2=-1;
				if (type<.5) { // lpf
					b1=0;
					b0=Av;
				}
				else { // hpf
					b1=tauc*Av;
					b0=0;
				}
			}
			else { // 2nd order
				// denominator
				a2=tauc*tauc;
				a1=tauc/Q;
				a0=1;
				// numerator
				if (type<.5) { // lpf
					b2=0;
					b1=0;
					b0=Av;
				}
				else if (type < 1.5) { // hpf
					b2=tauc*tauc*Av;
					b1=0;
					b0=0;
				}
				else { // bpf
					b2=0;
					b1=tauc/Q*Av;
					b0=0;
				}
			}
		}
		else { // use flo, fhi biasing
			taul=1/(2*pi*flo);
			tauh=1/(2*pi*fhi);

			// denominator
			a2=taul*tauh;
			a1=taul+tauh;
			a0=1;

			// numerator
			b2=0;
			b1=Av*(taul+tauh);
			b0=0;
		}

		bilinearTransform(a2, a1, a0, b2, b1, b0, az2, az1, az0, bz2, bz1, bz0, simInfo.sampleRate);

		// Store z-domain coefficients
		elements[elem].internalDouble[0]=az0;
		elements[elem].internalDouble[1]=az1;
		elements[elem].internalDouble[2]=az2;
		elements[elem].internalDouble[3]=bz0;
		elements[elem].internalDouble[4]=bz1;
		elements[elem].internalDouble[5]=bz2;
	}
	else if (callType==CALL_TYPE_RUN){
		OUTPUT(Term_Out) = 0; // initialize output node
		// apply numerator
		for (int i=0; i<3; i++) {
			OUTPUT(Term_Out) += (Input(Term_In,-i, PUTVARS)+ADD_NOISE + ADD_OFFSET) * elements[elem].internalDouble[3+i];
		}
		// apply denominator
		for (int i=1; i<3; i++) {
			OUTPUT(Term_Out) -= Input(Term_Out,-i+1, PUTVARS) * elements[elem].internalDouble[i];
		}
		OUTPUT(Term_Out) =	Saturate(OUTPUT(Term_Out), SATURATION_VALUE);
		ModularCircularPush(elem, elements, nodesWMemory, nodeValues, toggle);
	}
	return 0;
}


int FiltCntrl(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_In=0, Term_Ctrl=1, Term_Out=2;
	static const vector<int> nodesWMemory = {Term_In, Term_Out};
	static const unsigned int Param_fc=0, Param_Q=1, Param_fhi=2, Param_flo=3, Param_Av=4, Param_type=5, Param_order=6, Param_fScale=7, Param_CtrlRef=8;

	if (callType==CALL_TYPE_INITIALIZE) {
      static const int memoryLength=2, internalIntSize=0, internalDoubleSize=7;
  		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);
   }

	if (callType==CALL_TYPE_RUN && tn>0) {
		double a2, a1, a0, b2, b1, b0, az0, bz0, az1, bz1, az2, bz2, fc, Q, fhi, flo, Av, type, order, tauc, taul, tauh;
		const double pi = boost::math::constants::pi<double>();

		// Copy user's parameters
		fc=elements[elem].params[Param_fc];
		Q=elements[elem].params[Param_Q];
		fhi=elements[elem].params[Param_fhi];
		flo=elements[elem].params[Param_flo];
		Av=elements[elem].params[Param_Av];
		type=elements[elem].params[Param_type];
		order=elements[elem].params[Param_order];

		if (abs(Av)<1e-5) {
			Av=1;
		}
		if (fc>1e-3) { // use fc/Q biasing
			tauc = 1/(2*pi * (fc + ((INPUT(Term_Ctrl,)-elements[elem].params[Param_CtrlRef]) * elements[elem].params[Param_fScale]))); // scale by input and scale parameter

			if (order<1.5) { // first order
				// denominator
				a2=-1; // -1 because we're not using it
				a1=tauc;
				a0=1;
				// numerator
				b2=-1;
				if (type<.5) { // lpf
					b1=0;
					b0=Av;
				}
				else { // hpf
					b1=tauc*Av;
					b0=0;
				}
			}
			else { // 2nd order
				// denominator
				a2=tauc*tauc;
				a1=tauc/Q;
				a0=1;
				// numerator
				if (type<.5) { // lpf
					b2=0;
					b1=0;
					b0=Av;
				}
				else if (type < 1.5) { // hpf
					b2=tauc*tauc*Av;
					b1=0;
					b0=0;
				}
				else { // bpf
					b2=0;
					b1=tauc/Q*Av;
					b0=0;
				}
			}
		}
		else { // use flo, fhi biasing
			taul=1/(2*pi*(flo + (INPUT(Term_Ctrl,)-elements[elem].params[Param_CtrlRef]) * elements[elem].params[Param_fScale])); // scale by input and scale parameter
			tauh=1/(2*pi*(fhi + (INPUT(Term_Ctrl,)-elements[elem].params[Param_CtrlRef]) * elements[elem].params[Param_fScale])); // scale by input and scale parameter

			// denominator
			a2=taul*tauh;
			a1=taul+tauh;
			a0=1;

			// numerator
			b2=0;
			b1=Av*(taul+tauh);
			b0=0;
		}

		bilinearTransform(a2, a1, a0, b2, b1, b0, az2, az1, az0, bz2, bz1, bz0, simInfo.sampleRate);

		// Store z-domain coefficients
		elements[elem].internalDouble[0]=az0;
		elements[elem].internalDouble[1]=az1;
		elements[elem].internalDouble[2]=az2;
		elements[elem].internalDouble[3]=bz0;
		elements[elem].internalDouble[4]=bz1;
		elements[elem].internalDouble[5]=bz2;

		// OUTPUT(2) = 0; // initialize output node
		// // apply numerator
		// for (int i=0; i<3; i++) {
		// 	OUTPUT(Term_Out) += (Input(Term_In,-i, PUTVARS)+ADD_NOISE + ADD_OFFSET) * elements[elem].internalDouble[3+i];
		// }
		// // apply denominator
		// for (int i=1; i<3; i++) {
		// 	OUTPUT(Term_Out) -= Input(Term_In,-i+1, PUTVARS) * elements[elem].internalDouble[i];
		// }
		// OUTPUT(Term_In) =	Saturate(OUTPUT(Term_In), SATURATION_VALUE);

    OUTPUT(Term_Out) = 0; // initialize output node
		// apply numerator
		for (int i=0; i<3; i++) {
			OUTPUT(Term_Out) += (Input(Term_In,-i, PUTVARS)+ADD_NOISE + ADD_OFFSET) * elements[elem].internalDouble[3+i];
		}
		// apply denominator
		for (int i=1; i<3; i++) {
			OUTPUT(Term_Out) -= Input(Term_Out,-i+1, PUTVARS) * elements[elem].internalDouble[i];
		}
		OUTPUT(Term_Out) =	Saturate(OUTPUT(Term_Out), SATURATION_VALUE);
		ModularCircularPush(elem, elements, nodesWMemory, nodeValues, toggle);

	}
	return 0;
}


int VCOi(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
   static const unsigned int Term_Freq=0, Term_OutCos=1, Term_OutSin=2;
	static const vector<int> nodesWMemory = {};
	static const unsigned int Param_Amp=0;
   static const unsigned int Cosine=0, Sine=1;

	if (callType==CALL_TYPE_INITIALIZE) {
		// Reserve space for angle -- [0] is cosine, [1] is sine
      static const int memoryLength=0, internalIntSize=0, internalDoubleSize=2;
  		ModuleInitialize(elem, elements, memoryLength, nodesWMemory, internalIntSize, internalDoubleSize);
		elements[elem].internalDouble[Cosine]=1; // cos(0)=1
		elements[elem].internalDouble[Sine]=0; // sin(0)=0
	}
	else if (callType==CALL_TYPE_RUN) {
		double d_phi, cosP, sinP;
		const double pi = boost::math::constants::pi<double>();

		if (tn>0) {
			// d_phi = 2*pi * f(i)/Fs;
			d_phi = 2*pi* INPUT(Term_Freq,) / simInfo.sampleRate;
			// Temporarily store the previous value
			cosP = elements[elem].internalDouble[Cosine];
			sinP = elements[elem].internalDouble[Sine];
			// Rotate the angle
			elements[elem].internalDouble[Cosine] = cos(d_phi)*cosP - sin(d_phi)*sinP;
			elements[elem].internalDouble[Sine] = sin(d_phi)*cosP + cos(d_phi)*sinP;
		}

		// multiply by actual amplitude of the sine wave to assign to the output
		OUTPUT(Term_OutCos) = ADD_NOISE + ADD_OFFSET
				+ elements[elem].params[Param_Amp] * elements[elem].internalDouble[Cosine]; // cosine
		OUTPUT(Term_OutSin) = ADD_NOISE + ADD_OFFSET
				+ elements[elem].params[Param_Amp] * elements[elem].internalDouble[Sine]; // sine
	}
	return 0;
}

/*
int ONod(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
	if (callType==CALL_TYPE_FINISHED) {
		// Used to store the output nodes.
		vec2d outputWaves;
		int numChannels=elements[elem].argNames.size();

		outputWaves.resize(simInfo.numSamples, vector<double>(numChannels));

		// copy output nodes into output waveform
		for (int i=0; i<simInfo.numSamples; i++){
			for (int channel=0; channel<numChannels;channel++){
				outputWaves[i][channel] = nodeValues[i][elements[elem].nodes[channel]];
			}
		}

		char *outputFile = &(simInfo.outputWav[0]);
		char *inputFile = &(simInfo.inputWav[0]);
		writeWaveFile(simInfo.sampleRate, simInfo.numSamples, numChannels, outputWaves, outputFile, inputFile);
		//printWaveFile(simInfo.sampleRate, simInfo.numSamples, numChannels, outputWaves);
	}
	return 0;
}
*/

/*
 * Runs after simulation is finished to stitch together reconstructed signal w/ gated signal
 * Must run before ONod
 */
int Stitcher(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
	static const unsigned int Term_In1=0, Term_In2=1, Term_Out=2;

	if (callType==CALL_TYPE_FINISHED) {
		unsigned int ONodElem=0, ONod_In1=0, ONod_In2=0, ONod_Out=0;
		findONod(ONodElem, ONod_In1, elements, elem, Term_In1);
		findONod(ONodElem, ONod_In2, elements, elem, Term_In2);
		findONod(ONodElem, ONod_Out, elements, elem, Term_Out);
		for (tn=1; tn<simInfo.numSamples; tn++) {
			writeONod( readONod(tn-1, ONodElem, ONod_In1, elements) + readONod(tn, ONodElem, ONod_In2, elements), tn, ONodElem, ONod_Out, elements);
		}
	}
	return 0;
}

int ONod(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
	static const unsigned int Param_numChanToOutput=0;

   if (callType==CALL_TYPE_INITIALIZE) {
      elements[elem].internalCircular.resize(elements[elem].argNames.size());
		for (unsigned int i=0; i<elements[elem].argNames.size(); i++) {
         elements[elem].internalCircular[i].resize(simInfo.numSamples);
		}
	}
	if (callType==CALL_TYPE_RUN) {
    for (unsigned int i=0; i<elements[elem].argNames.size(); i++) {
         elements[elem].internalCircular[i][tn] = nodeValues[!toggle][elements[elem].nodes[i]];
		}
    if (tn==1) {
      for (unsigned int i=0; i<elements[elem].argNames.size(); i++) {
        elements[elem].internalCircular[i][0] = elements[elem].internalCircular[i][1];
      }
    }
	}
	if (callType==CALL_TYPE_FINISHED) {
		// Used to store the output nodes.
		//vec2d outputWaves;

    // If user didn't specify number of channels to output, then just output all channels
		int numChannels=elements[elem].argNames.size();
    // Otherwise we should the output the specified number of channels
    if (elements[elem].params[Param_numChanToOutput]>0) {
      numChannels=elements[elem].params[Param_numChanToOutput];
    }
		//outputWaves.resize(simInfo.numSamples, vector<double>(numChannels));
		char *outputFile = &(simInfo.outputWav[0]);
		char *inputFile = &(simInfo.inputWav[0]);
		writeWaveFile(simInfo.sampleRate, simInfo.numSamples, numChannels, elements, elem, outputFile, inputFile);
		//printWaveFile(simInfo.sampleRate, simInfo.numSamples, numChannels, outputWaves);
	}
	return 0;
}


int EventDump(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
/*
	if (callType==CALL_TYPE_RUN) {
		stringstream lineStream;
		if (tn>2) {
			// look for trigger
			if (INPUT(0,) > 0.5 && INPUT(0,-1) < 0.5) {

				int numNodes = elements[elem].argNames.size() - 1;
				// Dump nodes to csv
				lineStream << t;
				for (int i=0; i<numNodes; i++) {
					lineStream << ", " << elements[elem].nodes[i+1] <<
							", " << nodeValues[tn-1][elements[elem].nodes[i+1]];
				}
				lineStream << endl;
				csvWriteLine(simInfo, lineStream.str(), callType);
			}
		}
	}
*/
	return 0;
}

int analyzeSteps(vector<double>& phasors) {
	for (unsigned int i=0; i<phasors.size(); i++) {

	}
	return 0;
}

int MCUmodel(int callType, int elem, double t, int tn, vec2d& sourceData, vec2d& nodeValues, vector<circElement>& elements, simulationInformation simInfo, int toggle){
/*
	// terminals = {"Trig","Clk","DataReady","Real0","Imag0","Real1","Imag1","Real2","Imag2"};
	// params = {"Triggered","SamplingFreq"};
	if (callType==CALL_TYPE_INITIALIZE) {
		// Number of samples for sampling frequency
		elements[elem].internalInt.resize(4);
		// Divided by 2 because it's time between either edge
		elements[elem].internalInt[0] = round(simInfo.sampleRate/2/elements[elem].params[1]);
		// Whether this is triggered or not
		elements[elem].internalInt[1] = round(elements[elem].params[0]);
		// [2] records whether we're looking for a trigger
		elements[elem].internalInt[2] = 1;
		// [3] records number of samples since last clock
		elements[elem].internalInt[3] = 0;
	}
	else if (callType==CALL_TYPE_RUN) {
		bool checkForData=false;
		if (tn>2) {
			// If not triggered operation
			if (elements[elem].internalInt[1]==0) {
				checkForData=true;
			}
			// If triggered operation
			else {
				// If looking for trigger
				if (elements[elem].internalInt[2]==1) {
					// If found trigger
					if (nodeValues[tn-1][elements[elem].nodes[0]] > 0.5
							&& nodeValues[tn-2][elements[elem].nodes[0]] < 0.5) {
						// Start clock
						nodeValues[tn][elements[elem].nodes[1]] = VDD;
						elements[elem].internalInt[3] = 0;
						// Set to not looking for trigger
						elements[elem].internalInt[2]=0;
					}
				}
				// Else waiting for end of step
				else {
					checkForData=true;
				}
			}


			if (checkForData==true) {
				// If data ready
				if (nodeValues[tn-1][elements[elem].nodes[2]] > 0.5
										&& nodeValues[tn-2][elements[elem].nodes[2]] < 0.5) {
				  // Run analysis
					// Pack data into vector
					vector<double> phasors (6);
					int result;
					for (int i=0; i<6; i++){
						phasors[i] = nodeValues[tn-1][elements[elem].nodes[3+i]];
					}
					result=analyzeSteps(phasors);
					// If step done and triggered operation, then change to not looking for trigger
					if (result==1) {
						elements[elem].internalInt[2]=0;
						nodeValues[tn][elements[elem].nodes[1]] = 0;
					}
				}
				// Update clock
				if (elements[elem].internalInt[2] > elements[elem].internalInt[0]) {
					// If number cycles has reached a half cycle
					// Then toggle the clock
					if (nodeValues[tn-1][elements[elem].nodes[1]] > 0.5) {
						nodeValues[tn][elements[elem].nodes[1]] = 0;
					}
					else {
						nodeValues[tn][elements[elem].nodes[1]] = VDD;
					}
					// And reset the number of cycles
					elements[elem].internalInt[2] = 0;
				}
				// Increment the number of cycles
				elements[elem].internalInt[2]++;
			}
			else {
				nodeValues[tn][elements[elem].nodes[1]] = 0;
			}
		}
	}
*/
	return 0;
}


/****************************************************************************************
 * End circuit functions
 ****************************************************************************************/


/*
 * Populates fields of a single circuit element
 */
int populateElementFields(vector<elementDef>& elements, string type, circuitFunction function, vector<string> terminals, vector<string> params, vector<int> outputs){
	int n;

	// Allocate new element
	elements.push_back(elementDef());
	n=elements.size()-1;

	// Copy type and function
	elements[n].type=type;
	elements[n].function=function;

	// Copy terminal names
	for (unsigned int i=0; i<terminals.size(); i++) {
		elements[n].terminals.push_back(string());
		elements[n].terminals[i]=terminals[i];
	}

	// Copy parameter names
	for (unsigned int i=0; i<params.size(); i++) {
		elements[n].params.push_back(string());
		elements[n].params[i]=params[i];
	}
	
	//if (strcmp(outputs, "") != 0) {
	if (outputs.size() != 0) {
		for (unsigned int i=0; i<outputs.size(); i++) {
			elements[n].outputs.push_back(int());
			elements[n].outputs[i]=outputs[i];
		}
	}

	return 0;
}

/*
 * Defines the circuit element module definitions. For now, the modules properties are hardcoded here.
 */
int populateElementDefinitions(vector<elementDef>& elements){
	vector<string> terminals, params;

	// Voltage source
	terminals = {"Pos","Neg"}; // terminals = list_of("Pos")("Neg");
	params = {"Vdc", "WavChan"}; // params = list_of("Vdc")("WavChan");
	vector<int> outputs = {0};
	populateElementFields(elements, "Vsrc", Vsrc, terminals, params, outputs);

	// OTAx
	terminals = {"Pos","Neg","Ibp","Out"}; // terminals = list_of("Pos")("Neg");
	params = {"Ib", "Scale"}; // params = list_of("Vdc")("WavChan");
	outputs = {3};
	populateElementFields(elements, "OTAx", OTAx, terminals, params, outputs);

	// OTAp
	terminals = {"Pos","Neg","Ib","Vb","Out"}; // terminals = list_of("Pos")("Neg");
	params = {"PreLog", "InLog", "Scale","BiaType"}; // params = list_of("Vdc")("WavChan");
	outputs = {4};
	populateElementFields(elements, "OTAp", OTAp, terminals, params, outputs);

	// Amplifier
	terminals = {"In", "Out"}; // terminals = list_of("In")("Out");
	params = {"Av"}; // params = list_of("Av");
	outputs = {1};
	populateElementFields(elements, "AmpX", AmpX, terminals, params, outputs);

	// Charge pump
	terminals = {"In", "Out"}; // terminals = list_of("In")("Out");
	params = {"Down","Up"}; // params = list_of("Av");
	outputs = {1};
	populateElementFields(elements, "ChPu", ChPu, terminals, params, outputs);

	// Proper charge pump
	terminals = {"Up", "Down", "Out"}; // terminals = list_of("In")("Out");
	params = {"DownRate","UpRate"}; // params = list_of("Av");
	outputs = {2};
	populateElementFields(elements, "ChP2", ChP2, terminals, params, outputs);
	
	// Circular Buffer
	terminals = {"In", "Clk","BufferLoc"}; // terminals = list_of("In")("Clk")("BufferLoc");
	params = {"Capacity"}; // params = list_of("Capacity"); Actual size = 2*Capacity
	outputs = {2};
	populateElementFields(elements, "CBuf", CBuf, terminals, params, outputs);

	// Reconstruction
	terminals = {"BufferLoc", "ReconTrigger", "Out"}; // terminals = list_of("BufferLoc")("ReconTrigger")("Out");
	params = {"Method", "Duration"}; // params = list_of("Capacity"); Actual size = 2*Capacity
	outputs = {2};
	populateElementFields(elements, "Reco", Reco, terminals, params, outputs);	
	// Sample and hold
	terminals = {"In","Clk", "Out"}; // terminals = list_of("In")("Out");
	params = {"na"}; // params = list_of("Av");
	outputs = {2};
	populateElementFields(elements, "SaHo", SaHo, terminals, params, outputs);

	// Half wave
	terminals = {"In", "Out"}; // terminals = list_of("In")("Out");
	params = {"Av"}; // params = list_of("Av");
	outputs = {1};
	populateElementFields(elements, "Half", HalfWave, terminals, params, outputs);

	// Peak detector
	terminals = {"In", "Out"}; // terminals = list_of("In")("Out");
	params = {"a", "d", "At", "Ro", "f"}; // params = list_of("a")("d")("At")("Ro")("f");
	outputs = {1};
	populateElementFields(elements, "PkDe", PkDe, terminals, params, outputs);

	// Peak detector
	terminals = {"In", "Out"}; // terminals = list_of("In")("Out");
	params = {"a", "d", "At", "Ro", "f", "Par"}; // params = list_of("a")("d")("At")("Ro")("f");
	outputs = {1};
	populateElementFields(elements, "PkDD", PkDeDynamic, terminals, params, outputs);

	// Adaptive time constant
	terminals = {"In", "Out"}; // terminals = list_of("In")("Out");
	params = {"rate","S"}; // params = list_of("a")("d")("At")("Ro")("f");
	outputs = {1};
	populateElementFields(elements, "AdTa", AdTa, terminals, params, outputs);

	// Output nets assignment
	terminals = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15"}; // terminals = list_of("0")("1")("2")("3")("4")("5");
	params={"numChanToOutput"}; // params = list_of("");
	outputs = {};
	populateElementFields(elements, "ONod", ONod, terminals, params, outputs);

	// Multiply accumulate
	terminals = {"In0", "In1", "In2", "In3", "In4", "In5", "In6", "In7", "Out"}; // terminals = list_of("0")("1")("2")("3")("4")("5");
	params={"Av0", "Av1", "Av2", "Av3", "Av4", "Av5", "Av6", "Av7", "Offset"}; // params = list_of("");
	outputs = {8};
	populateElementFields(elements, "MACn", MACn, terminals, params, outputs);

	// Continuous time filter -- 1st order or 2nd order, given as transfer function
	terminals = {"In", "Out"}; // terminals = list_of("In")("Out");
	params = {"Num2", "Num1", "Num0", "Den2", "Den1", "Den0"}; // params = list_of("Num2")("Num1")("Num0")("Den2")("Den1")("Den0");
	outputs = {1};
	populateElementFields(elements, "FiTF", FiltTF, terminals, params, outputs);

	// Continuous time filter -- 1st order or 2nd order, given as fc, Q, order, and type
	terminals = {"In", "Ref", "Out"}; // terminals = list_of("In")("Out");
	params = {"fc", "Q", "fhi", "flo", "Av", "type", "order"}; // params = list_of("fc")("Q")("type")("order");
	outputs = {2};
	populateElementFields(elements, "Filt", Filt, terminals, params, outputs);

	// Continuous time filter with adjustable frequency -- 1st order or 2nd order, given as fc, Q, order, and type
	terminals = {"In", "Cntl", "Out"}; // terminals = list_of("In")("Out");
	params = {"fc", "Q", "fhi", "flo", "Av", "type", "order","fScale","CtrlRef"}; // params = list_of("fc")("Q")("type")("order");
	outputs = {2};
	populateElementFields(elements, "VCFx", FiltCntrl, terminals, params, outputs);

	// Adder
	terminals = {"In1", "In2", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"Av"}; // params = list_of("Av");
	outputs = {2};
	populateElementFields(elements, "Add2", Add2, terminals, params, outputs);

	// Stitcher
	terminals = {"In1", "In2", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {""}; // params = list_of("Av");
	outputs = {2};
	populateElementFields(elements, "Stch", Stitcher, terminals, params, outputs);
	// Lossless integrator
	terminals = {"In", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"rateUp", "rateDown", "zeroRes", "IC"}; // params = list_of("Av");
	outputs = {1};
	populateElementFields(elements, "LInt", LosslessInt, terminals, params, outputs);

	// Timer
	terminals = {"In", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"Slope"}; // params = list_of("Av");
	outputs = {1};
	populateElementFields(elements, "Timr", Timr, terminals, params, outputs);

	// Multiplier
	terminals = {"In1", "In2", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"Av"}; // params = list_of("Av");
	outputs = {2};
	populateElementFields(elements, "Mlt2", Multiplier, terminals, params, outputs);

	// Bump
	terminals = {"Pos", "Neg", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"OuterScale","InnerScale"}; // params = list_of("Av");
	outputs = {2};
	populateElementFields(elements, "Bump", Bump, terminals, params, outputs);

	// Multiplier with reference
	terminals = {"X", "Y", "Ref", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"Av"}; // params = list_of("Av");
	outputs = {3};
	populateElementFields(elements, "Mult", MultiplierReference, terminals, params, outputs);

	// sigmoid
	terminals = {"In", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"Av"}; // params = list_of("Av");
	outputs = {1};
	populateElementFields(elements, "SIGD", Sigmoid_nn, terminals, params, outputs);

	// tanh
	terminals = {"In", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"Av"}; // params = list_of("Av");
	outputs = {1};
	populateElementFields(elements, "TANH", TANH_nn, terminals, params, outputs);

	// RELU
	terminals = {"In", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"Av"}; // params = list_of("Av");
	outputs = {1};
	populateElementFields(elements, "RELU", RELU_nn, terminals, params, outputs);

	// Gain control
	terminals = {"PosEnv", "NegEnv", "AvOut"}; // terminals = list_of("PosEnv")("NegEnv")("AvOut");
	params = {"V2I_Gm","Iknee","RefLog","MinLog","MaxGain","AGCexp"}; // params = list_of("V2I_Gm","Iknee","AGCRefLog","MinLog","MaxGain","AGCexp");
	outputs = {2};
	populateElementFields(elements, "Kcnt", GainControl, terminals, params, outputs);

	// Subtractor
	terminals = {"Pos", "Neg", "Out"}; // terminals = list_of("Pos")("Neg")("Out");
	params = {"Av"}; // params = list_of("Av");
	outputs = {2};
	populateElementFields(elements, "Sub2", Sub2, terminals, params, outputs);

	// N current mirror
	terminals = {"In", "Log", "MirOut"}; // terminals = list_of("Pos")("Neg")("Out");
	params = {"PreLog","InLog","Ioff"}; // params = list_of("Av");
	outputs = {1,2};
	populateElementFields(elements, "NMir", NMir, terminals, params, outputs);

	// P current mirror
	terminals = {"In", "Log", "MirOut"}; // terminals = list_of("Pos")("Neg")("Out");
	params = {"PreLog","InLog","Ioff"}; // params = list_of("Av");
	outputs = {1,2};
	populateElementFields(elements, "PMir", PMir, terminals, params, outputs);

	// Exponential
	terminals = {"In", "Out"}; // terminals = list_of("Pos")("Neg")("Out");
	params = {"PreExp","InExp"}; // params = list_of("Av");
	outputs = {1};
	populateElementFields(elements, "Exp1", Exp1, terminals, params, outputs);

	// Ideal VCO
	terminals = {"Freq", "OutCos", "OutSin"}; // terminals = list_of("Freq")("OutCos")("OutSin");
	params = {"Amp"}; // params = list_of("Amp");
	outputs = {1,2};
	populateElementFields(elements, "VCOi", VCOi, terminals, params, outputs);

	// Delay Flip Flop
	terminals = {"D", "Clk", "R", "Q"}; // terminals = list_of("D")("Clk")("R")("Q");
	params = {"Delay"}; // params = list_of("Delay");
	outputs = {3};
	populateElementFields(elements, "DFF0", DFF, terminals, params, outputs);

	// JK Flip Flop
	terminals = {"J", "K", "Clk", "Q"}; // terminals = list_of("J")("K")("Clk")("Q");
	params = {"Delay"}; // params = list_of("Delay");
	outputs = {3};
	populateElementFields(elements, "JKFF", JKFF, terminals, params, outputs);

	// And
	terminals = {"In1", "In2", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"Delay"}; // params = list_of("Delay");
	outputs = {2};
	populateElementFields(elements, "And0", And, terminals, params, outputs);

	// Or
	terminals = {"In1", "In2", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"Delay"}; // params = list_of("Delay");
	outputs = {2};
	populateElementFields(elements, "Orx0", Or, terminals, params, outputs);

	// Nand
	terminals = {"In1", "In2", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"Delay"}; // params = list_of("Delay");
	outputs = {2};
	populateElementFields(elements, "Nand", Nand, terminals, params, outputs);

	// Res2
	terminals = {"1M", "Tap", "100k"}; // terminals = list_of("In1")("In2")("Out");
	params = {"Resistance"}; // params = list_of("Delay");
	outputs = {};
	populateElementFields(elements, "Res2", Res2, terminals, params, outputs);

	// Nor
	terminals = {"In1", "In2", "Out"}; // terminals = list_of("In1")("In2")("Out");
	params = {"Delay"}; // params = list_of("Delay");
	outputs = {2};
	populateElementFields(elements, "Nor0", Nor, terminals, params, outputs);

	// Not
	terminals = {"In1", "Out"}; // terminals = list_of("In1")("Out");
	params = {"Delay"}; // params = list_of("Delay");
	outputs = {1};
	populateElementFields(elements, "Not0", Not, terminals, params, outputs);

	// LUT
	terminals = {"X0","X1","X2","X3","X4","X5","Y0","Y1"}; // terminals = list_of("In1")("Out");
	params = {"0_0","0_1","0_2","0_3","0_4","0_5","0_6","0_7","0_8","0_9","0_10","0_11","0_12","0_13","0_14","0_15",
			"0_16","0_17","0_18","0_19","0_20","0_21","0_22","0_23","0_24","0_25","0_26","0_27","0_28","0_29",
			"0_30","0_31","0_32","0_33","0_34","0_35","0_36","0_37","0_38","0_39","0_40","0_41","0_42","0_43",
			"0_44","0_45","0_46","0_47","0_48","0_49","0_50","0_51","0_52","0_53","0_54","0_55","0_56","0_57",
			"0_58","0_59","0_60","0_61","0_62","0_63","1_0","1_1","1_2","1_3","1_4","1_5","1_6","1_7","1_8",
			"1_9","1_10","1_11","1_12","1_13","1_14","1_15","1_16","1_17","1_18","1_19","1_20","1_21","1_22",
			"1_23","1_24","1_25","1_26","1_27","1_28","1_29","1_30","1_31","1_32","1_33","1_34","1_35","1_36",
			"1_37","1_38","1_39","1_40","1_41","1_42","1_43","1_44","1_45","1_46","1_47","1_48","1_49","1_50",
			"1_51","1_52","1_53","1_54","1_55","1_56","1_57","1_58","1_59","1_60","1_61","1_62","1_63"}; // params = list_of("Delay");
	outputs = {6,7};
	populateElementFields(elements, "LUTx", LUT, terminals, params, outputs);

	// Pulse
	terminals = {"In", "Out"}; // terminals = list_of("In1")("Out");
	params = {"Time"}; // params = list_of("Delay");
	outputs = {1};
	populateElementFields(elements, "Puls", Pulse, terminals, params, outputs);

	// Comparator
	terminals = {"Pos", "Neg", "Out"}; // terminals = list_of("Pos")("Neg")("Out");
	params = {"Hysteresis"}; // params = list_of("Hysteresis");
	outputs = {2};
	populateElementFields(elements, "CmpX", Comparator, terminals, params, outputs);

	// Comparator that doesn't eval until settling time has passed
	terminals = {"Pos", "Neg", "Out"}; // terminals = list_of("Pos")("Neg")("Out");
	params = {"Hysteresis","SettleTime"}; // params = list_of("Hysteresis");
	outputs = {2};
	populateElementFields(elements, "CmpS", ComparatorSettle, terminals, params, outputs);

	// Delay
	terminals = {"In", "Out"}; // terminals = list_of("In")("Out");
	params = {"Delay"}; // params = list_of("Delay");
	outputs = {1};
	populateElementFields(elements, "Dly0", Delay, terminals, params, outputs);

	// Delay
	terminals = {"In", "Out"}; // terminals = list_of("In")("Out");
	params = {"Delay"}; // params = list_of("Delay");
	outputs = {1};
	populateElementFields(elements, "DlyI", DelaySamples, terminals, params, outputs);

	// Frequency divider
	terminals = {"In", "Out"}; // terminals = list_of("In")("Out");
	params = {"Div"}; // params = list_of("Div");
	outputs = {1};
	populateElementFields(elements, "FDiv", FreqDiv, terminals, params, outputs);

	// Gate
	terminals = {"In", "Gate", "Out"}; // terminals = list_of("In")("Gate")("Out");
	params = {""}; // params = list_of("");
	outputs = {2};
	populateElementFields(elements, "Gate", Gate, terminals, params, outputs);

	// ADC
	terminals = {"In","Clk","Out","Ready"}; // terminals = list_of("In")("Out");
	params = {"Min","Max","Bits"}; // params = list_of("Min")("Max")("Bits");
	outputs = {2,3};
	populateElementFields(elements, "ADCm", ADC, terminals, params, outputs);

	// Event-triggered variable dump
	terminals = {"Trig","0","1","2","3","4"}; // terminals = list_of("Trig")("0")("1")("2")("3")("4");
	params = {""}; // params = list_of("");
	outputs = {};
	populateElementFields(elements, "Dump", EventDump, terminals, params, outputs);

	// Print event time stamps
	terminals = {"Trig"};
	params = {""}; // params = list_of("");
	outputs = {};
	populateElementFields(elements, "Stmp", PrintTimeStamp, terminals, params, outputs);

	// Analyze Steps
	terminals = {"Trig","Clk","DataReady","Real0","Imag0","Real1","Imag1","Real2","Imag2"};
	params = {"Triggered","SamplingFreq"};
	outputs = {};
	populateElementFields(elements, "MCUm", MCUmodel, terminals, params, outputs);

	return 0;
}

/*
 * Print the definitions of all circuit element module definitions
 */
int printElementDefinitions(vector<elementDef> elements){
	cout << "Printing definitions of the circuit element modules: \n";
	for (unsigned int i=0; i<elements.size(); i++) {
		cout << "Type=" << elements[i].type << "; Function=" << elements[i].function << "; ";
		for (unsigned int j=0; j<elements[i].terminals.size(); j++){
			cout << "Term" << j << "=" << elements[i].terminals[j] << "; ";
		}
		for (unsigned int j=0; j<elements[i].params.size(); j++){
			cout << "Param" << j << "=" << elements[i].params[j] << "; ";
		}
		cout << "\n";
	}
	cout << "\n";

	return 0;
}

/*
 * Print the properties of all circuit elements in the netlist
 */
int printCircuitElements(vector<elementDef> modules, vector<circElement> elements){
	cout << "Printing properties of the netlist circuit elements: \n";

	for (unsigned int i=0; i<elements.size(); i++) {
		cout << "Type=" << elements[i].type << "; TypeNum=" << elements[i].typeNum << "; ";
		for (unsigned int j=0; j<elements[i].argNames.size(); j++){
			cout << elements[i].argNames[j] << "=" << elements[i].argValues[j] << "; ";
		}

		for (unsigned int j=0; j<elements[i].nodes.size(); j++) {
			cout << modules[elements[i].typeNum].terminals[j] << "=" << elements[i].nodes[j] << "; ";
		}
		for (unsigned int j=0; j<elements[i].params.size(); j++) {
			cout << modules[elements[i].typeNum].params[j] << "=" << elements[i].params[j] << "; ";
		}
		cout << "\n";
	}
	cout << "\n";

	return 0;
}

/*
 * Called by parseNetlistLine after device type has been copied from netlist line.
 * Copies the remaining device arguments into the circuit element structure.
 */
int pushNetlistArguments(string& line, int elNum, vector<circElement>& elements, char token) {
	unsigned int tokenLocation;
	int paramNum;
	int lastArgument=0;

	tokenLocation=line.find(token);
	// if token not found
	if (tokenLocation>=STRING_NPOS_32){
		if (token=='=') {
			// '=' not found to match argument name, so throw error
			cerr << "\nError: pushNetlistArguments: No matching '=' for last argument: " << line << "\n";
			return -1;
		}
		else if (token==' ') {
			tokenLocation=line.length();
			lastArgument=true;
		}
	}

	// extract argument name
	if (token=='=') {
		elements[elNum].argNames.push_back(string());
		paramNum=elements[elNum].argNames.size()-1;
		elements[elNum].argNames[paramNum]=line.substr(0,tokenLocation);
	}
	// extract argument value
	else if (token==' ') {
		elements[elNum].argValues.push_back(string());
		paramNum=elements[elNum].argValues.size()-1;
		elements[elNum].argValues[paramNum]=line.substr(0,tokenLocation);
	}
	// remove portion that was extracted
	if (!lastArgument) {
		line=line.substr(tokenLocation+1); // remove argument and token
	}
	return lastArgument;
}

/*
 * Parse a single line from the netlist.
 * Add to the circuit elements vector.
 */
int parseNetlistLine(string line, vector<circElement>& elements){
	int elNum;
	int tokenLocation;
	int loopDone = false;
	if (line[0] == '%') {
		// it's a comment, so skip it
	}
	else if (line=="") {
		// it's an empty line, so skip it
	}
	else {
		// Check that "device type" is four characters
		tokenLocation=line.find(' ');
		if (tokenLocation != 4) {
			cerr << "\nError: parseNetlistLine: Device name must have 4 characters: " << line << "\n";
			return -1;
		}

		// add a new element entry for this line and pull the device type
		elements.push_back(circElement());
		elNum=elements.size()-1;
		elements[elNum].type=line.substr(0,tokenLocation); // tokenLocation=4
		line=line.substr(tokenLocation+1); // remove already-assigned portion of line

		// push the arguments into the element's argument queue
		while (line.length()>1 && !loopDone) {
      
			// get the argument name
			loopDone=pushNetlistArguments(line, elNum, elements, '=');
			if (loopDone) {
				// we shouldn't be finished before we get the value, so throw an error
				cerr << "\nError: parseNetlistLine: Should have a matching value for the argument: " << line << "\n";
				return -1;
			}
			if (loopDone == -1) {
				cerr << "\nError: parseNetlistLine: Error returned from pushNetlistArguments\n";
				return -1; // loopDone carries error from pushNetlistArguments
			}
			// get the argument value
			loopDone=pushNetlistArguments(line, elNum, elements, ' ');
			if (loopDone == -1) {
				cerr << "\nError: parseNetlistLine: Error returned from pushNetlistArguments\n";
				return -1; // loopDone carries error from pushNetlistArguments
			}
		}
	}
	return 0;
}


/*
 * Open the netlist and send each line to the line parser
 */
int readNetlist(char* netFile, vector<circElement>& elements){
	string line;
	int error, lineNumber=1;
	ifstream myfile (netFile);
	if (myfile.is_open()) {
		while ( getline (myfile,line) ) {
			error=parseNetlistLine(line, elements);
			if (error==-1) {
				cerr << "Error: readNetlist: Error returned from parseNetlistLine (line #" << lineNumber << ", " << line << ")\n";
				return -1;
			}
			lineNumber++;
	    }
	    myfile.close();
	}
	else {
		cerr << "Unable to open file\n";
		return -1;
	}

	return 0;
}


/*
 * Open the netlist and send each line to the line parser
 */
int readNetlistStrings(vector<circElement>& elements){
	int error;

	for (unsigned int i=0; i<netlistStrings.size(); i++) {
		error=parseNetlistLine(netlistStrings[i], elements);
		if (error==-1) {
			cerr << "Error: readNetlist: Error returned from parseNetlistLine\n";
			return -1;
		}
	}

	return 0;
}

/*
 * Associate netlist element to device type
 */
int mapElementToDevice(int n, vector<elementDef> modules, vector<circElement>& elements) {
	int devMap=-1;

	// Associate line with device type
	for (unsigned int d=0; d<modules.size(); d++){
		if (elements[n].type.compare(modules[d].type) == STRING_EQUAL) {
			devMap=d;

			// allocate space for node and parameters
			elements[n].nodes.resize(modules[d].terminals.size());
			elements[n].params.resize(modules[d].params.size());
		}
	}
	if (devMap==-1) {
		cerr << "\nError: mapElementToDevice: Couldn't  associate netlist device " << elements[n].type << " with a module\n";
		return -1;
	}
	elements[n].typeNum=devMap;
	return devMap;
}

/*
 * Match terminals between circuit in netlist and circuit definition.
 */
int matchTerminals(vector<elementDef> modules, vector<circElement>& elements, int devMap, int n, vector<netInfo>& netMap) {
	int map;
	bool terminalMatched;

	// Match up device terminals
	for (unsigned int te=0; te<modules[devMap].terminals.size(); te++){
    elements[n].nodes[te] = 0; // initialize to ground in case it isn't used
		terminalMatched=false;

		for (unsigned int p=0; p<elements[n].argNames.size(); p++) {
			if (modules[devMap].terminals[te].compare(elements[n].argNames[p]) == STRING_EQUAL) {
				// Map net
				map=-1;
				for (unsigned int nm=0; nm<netMap.size(); nm++){
					if (netMap[nm].name.compare(elements[n].argValues[p]) == STRING_EQUAL) {
						map=nm;
					}
				}

				if (map==-1) { // couldn't find match
					netMap.push_back(netInfo());
					map=netMap.size()-1;
					netMap[map].name=elements[n].argValues[p];
				}
				elements[n].nodes[te]=map;
				terminalMatched=true;
				
				// is this element terminal an output that drives the net?
				for (unsigned int on=0; on<modules[devMap].outputs.size(); on++) {
					if (te==modules[devMap].outputs[on]) {
						netMap[map].numDrivers++;
					}
				}
			}
		}

		// If we couldn't match one of the terminals and it isn't the ONod device or the MACn
		// which is used for mapping output nodes, then throw an error
		if (!terminalMatched && (modules[devMap].type.compare("ONod") != STRING_EQUAL) && (modules[devMap].type.compare("MACn") != STRING_EQUAL)) {
			cerr << "\nError: matchTerminals: missing terminal \"" << modules[devMap].terminals[te] << "\" from device \""
					<< modules[devMap].type << "\"\n";
			return -1;
		}
	}
	return 0;
}

/*
 * Match parameters for circuit in netlist to parameters for circuit definition
 */
int matchParameters(vector<elementDef> modules, vector<circElement>& elements, int devMap, int n){
	bool parameterMatched;

	// Match up device params
	for (unsigned int dp=0; dp<modules[devMap].params.size(); dp++){
		parameterMatched=false;
		for (unsigned int p=0; p<elements[n].argNames.size(); p++) {
			if (modules[devMap].params[dp].compare(elements[n].argNames[p]) == STRING_EQUAL) {
				elements[n].params[dp]=lexical_cast<double>(elements[n].argValues[p]);
				parameterMatched=true;
			}
		}
		if (!parameterMatched){
			elements[n].params[dp]=0;
		}
	}
	return 0;
}

/*
 * Match single default parameter
 */
int matchSingleParameter(string paramType, vector<circElement>& elements, int n, int paramNum, simulationInformation simInfo) {
	bool parameterMatched=false;
	for (unsigned int p=0; p<elements[n].argNames.size(); p++) {
		if (elements[n].argNames[p].compare(paramType) == STRING_EQUAL) {
			elements[n].defaultParams[paramNum]=lexical_cast<double>(elements[n].argValues[p]);
			parameterMatched=true;
		}
	}
	if ((paramNum == PARAM_RUNPERIOD) && parameterMatched) {
		elements[n].defaultParams[paramNum] = floor(simInfo.sampleRate/elements[n].defaultParams[paramNum]);
	}
	if (!parameterMatched){
		if (paramNum==PARAM_SATURATE){
			elements[n].defaultParams[paramNum]=VDD;
		}
		else if (paramNum==PARAM_RUNPERIOD){
			elements[n].defaultParams[paramNum]=1;
		}
		else {
			elements[n].defaultParams[paramNum]=0;
		}
	}
	return 0;
}

/*
 * Match default parameters such as noise, offset, etc.
 */
int matchDefaultParameters(vector<circElement>& elements, int n, simulationInformation simInfo){
	elements[n].defaultParams.resize(5);

	matchSingleParameter("Noise",elements,n,PARAM_NOISE,simInfo);
	matchSingleParameter("OffsetMean",elements,n,PARAM_OFFSET_MEAN,simInfo);
	matchSingleParameter("OffsetSigma",elements,n,PARAM_OFFSET_SIGMA,simInfo);
	matchSingleParameter("Saturate",elements,n,PARAM_SATURATE,simInfo);
	matchSingleParameter("RunFrequency",elements,n,PARAM_RUNPERIOD,simInfo);

	return 0;
}

/*
 * Map circuit elements from the netlist to circuit definitions. Initialize the circuit elements.
 * Also map numbers to nets.
 */
int initializeCircuits(vector<elementDef> modules, vector<circElement>& elements, vector<netInfo>& netMap, simulationInformation simInfo){
	int devMap;
	int error;
	// Initialize "Gnd" net, which is always '0'.
	netMap.push_back(netInfo());
	netMap[0].name="Gnd";

	for (unsigned int n=0; n<elements.size(); n++){
		devMap=mapElementToDevice(n, modules, elements);
		if (devMap==-1) {
			cerr << "Error: initializeCircuits: Error returned from mapElementToDevice\n";
			return -1; // devMap also carries error.
		}
		error=matchTerminals(modules, elements, devMap, n, netMap);
		if (error==-1) {
			cerr << "Error: initializeCircuits: Error returned from matchTerminals()\n";
			return -1;
		}
		matchParameters(modules, elements, devMap, n);
		matchDefaultParameters(elements, n, simInfo);

	}
	return 0;
}


/*
 * Read a wav file and store it into a waveform matrix.
 */
int readWaveFile(char* wavFile, simulationInformation& simInfo, vec2d& inputWaves) {

	SNDFILE* sndfile;
	SF_INFO sfinfo;
	sndfile = sf_open(wavFile, SFM_READ, &sfinfo);
	
	if(sndfile == 0){
		cerr << "could not open audio file" << wavFile << endl;
	}

	sf_count_t countRead = 0;
	sf_count_t moreToGo = 1;
	sf_count_t finalCount = 0;

	double *bufferTest = new double[sfinfo.frames];

	while (moreToGo == 1){
		finalCount = sf_read_double(sndfile, bufferTest, sfinfo.channels*10); // must read an integer multiple of the channels
		if (finalCount == 0){
			moreToGo = 0;
		}
		else {
			countRead += finalCount;
		}
	}

	simInfo.numSamples = countRead;

	sf_close(sndfile);

	sndfile = sf_open(wavFile, SFM_READ, &sfinfo);

	if(sndfile == 0){
		cerr << "could not open audio file" << wavFile << endl;
	}

	simInfo.sampleRate = sfinfo.samplerate;
	simInfo.numSamples = simInfo.numSamples/sfinfo.channels;
	simInfo.numInputChannels = sfinfo.channels;

	double *audioIn = new double[countRead];
	sf_read_double(sndfile, audioIn, countRead); 

	inputWaves.resize(simInfo.numSamples, vector<double>(simInfo.numInputChannels));	
	
	for (int i=0; i<simInfo.numSamples; i++){
	   for (int channel=0; channel<simInfo.numInputChannels; channel++){
			inputWaves[i][channel] = audioIn[i*sfinfo.channels + channel]*WAV_SCALE;
	   }
	}

	sf_close(sndfile);   

	delete[] bufferTest;
	delete[] audioIn;	

	return 0;
}

/*
 * Print contents of a waveform matrix.
 */
int printWaveNodes(int numSamples, int numChannels, vec2d inputWaves) {
	for (int i=0; i<numSamples; i++){
		cout << i << " | ";
		for (int channel=0; channel<numChannels;channel++){
			cout << inputWaves[i][channel] << " | ";
		}
		cout << "\n";
	}
	return 0;
}

/*
 * Print details and contents of a wav file.
 */
int printWaveFile(int samplingRate, int numSamples, int numChannels, vec2d inputWaves) {
	cout << samplingRate << "Hz\n";
	cout << numSamples << " samples\n";
	cout << numChannels << " channels\n";

	printWaveNodes(numSamples, numChannels, inputWaves);
	return 0;
}

int writeWaveFile(int samplingRate, int numSamples, int numChannels, vector<circElement>& elements, int elem, char* fileName, char* fileNameTemplate) {

	SNDFILE* sndfile;
	SF_INFO sfinfo;

	sfinfo.format = SF_FORMAT_WAV | SF_FORMAT_DOUBLE;
	sfinfo.channels = numChannels;
	sfinfo.samplerate = samplingRate;
	//sfinfo.frames = numChannels*numSamples;

	sndfile = sf_open(fileName, SFM_WRITE, &sfinfo);
	
	double *buffer = new double[numSamples*numChannels];
	//SndfileHandle fileWrite;
	//fileWrite = SndfileHandle(fileName, SFM_WRITE, SF_FORMAT_WAV | SF_FORMAT_DOUBLE, numChannels, samplingRate);
	for (int channel = 0; channel < numChannels; channel++) {
	   for (int i=0; i<numSamples; i++) {
				buffer[i*numChannels + channel] = (elements[elem].internalCircular[channel][i])/WAV_SCALE;
		}
	}

	sf_write_double(sndfile, buffer, numSamples*numChannels);

	sf_close(sndfile);

	delete[] buffer;

	return 0;
}

/*
 * Verify the netlist
 * No undriven nets, no nets driver by multiple outputs, etc.
 */
int netlistChecks(vector<elementDef> elementDefs, vector<circElement> circElements, vector<netInfo> netMap, simulationInformation simInfo) {
	// Start at 1 to skip over ground, which is net 0
	for (unsigned int i=1; i<netMap.size(); i++) {
		if (netMap[i].numDrivers<1) {
			cerr << "Error: Net " << netMap[i].name << " is undriven\n";
			return -1;
		}
		if (netMap[i].numDrivers>1) {
			cerr << "Error: Net " << netMap[i].name << " is driven by " << netMap[i].numDrivers << " nets\n";
			return -1;
		}
	}
	return 0;
}

int simpleSimulator(int callType, vector<circElement>& elements, vector<elementDef> modules, vec2d inputWaves, vector<netInfo> netMap, simulationInformation simInfo, vec2d & nodeValues) {
	double t=0;
	int startSample=0;
	int error, tn;
  unsigned int elem;
  int DEBUG=0;
	int toggle = 1; 	// OUTPUT => toggle
							// INPUT  => !toggle	
  if (Verbosity == Progress) cout << "Simulator " << callType << endl;
	// If we're initializing or finished, then only run 1 time step
	if (callType==CALL_TYPE_INITIALIZE || callType==CALL_TYPE_FINISHED) {
		startSample=simInfo.numSamples-1;
		// Open / close csv file
		csvWriteLine(simInfo, "", callType);
	}
  // Establish initial conditions
  if (callType==CALL_TYPE_RUN) {

	  // Run initial time step
	  tn = 0;
	  for (elem=0; elem<elements.size(); elem++) {
		  nodeValues[toggle][0] = 0; // set ground node to zero each time in case an element tried to overwrite it
		  nodeValues[!toggle][0] = 0; // set ground node to zero each time in case an element tried to overwrite it
		  error=modules[elements[elem].typeNum].function(callType, elem, t, tn, inputWaves, nodeValues, elements, simInfo, toggle);
		  if (error==-1) {
			  cerr << "Error: simpleSimulator: Error returned from circuit block\n";
			  return -1;
		  }
	  }
	  toggle = !toggle;

	  // Run second time step until delta clears
	  double difference;
	  // 	t=t+1.0/simInfo.sampleRate;
	  tn = 1;
	  int deltaExceeded=1;
	  double acceptableDelta = 1e-5;
	  int convergeCount = 0;
	  while ( deltaExceeded > 0 || convergeCount<1) {
		  // run all modules
		  for (elem=0; elem<elements.size(); elem++) {
			  nodeValues[toggle][0] = 0; // set ground node to zero each time in case an element tried to overwrite it
			  nodeValues[!toggle][0] = 0; // set ground node to zero each time in case an element tried to overwrite it
			  error=modules[elements[elem].typeNum].function(callType, elem, t, tn, inputWaves, nodeValues, elements, simInfo, toggle);
			  nodeValues[toggle][0] = 0; // set ground node to zero each time in case an element tried to overwrite it
			  nodeValues[!toggle][0] = 0; // set ground node to zero each time in case an element tried to overwrite it
			  if (error==-1) {
				  cerr << "Error: simpleSimulator: Error returned from circuit block\n";
				  return -1;
			  }
		  }
		  // look for deltas that exceed max
		  deltaExceeded = 0;
		  double eps=1e-10; // epsilon for equality comparison
		  for (unsigned int node=0; node<nodeValues[0].size(); node++) {
			  // Check if new node value equals old node value, this ensures we don't divide by zero
			  difference = nodeValues[toggle][node]-nodeValues[!toggle][node];
			  if ( abs(difference) > eps ) {
				  // Check if new node value differs from old value significantly percentage wise
				  if ( abs(difference)/max(nodeValues[toggle][node], nodeValues[!toggle][node]) > acceptableDelta) {
					  deltaExceeded++;
				  }
			  }
		  }
		  toggle = !toggle;
		  convergeCount++;
	  }
	  startSample=2;
	  // 	t=t+1.0/simInfo.sampleRate;
  }
  int progressUpdate = simInfo.numSamples/100;
  if (Verbosity == Progress) cout << "Progress: 0%" << std::flush;
	for (tn=startSample; tn<simInfo.numSamples; tn++) {
    if ((tn % progressUpdate) == 0) {
      if (Verbosity == Progress) cout << "\rProgress: " << tn/progressUpdate << "%" << std::flush;
    }
    if (DEBUG) {
      cout << "tn = " << tn << "; t = " << t << endl;
    }
		for (elem=0; elem<elements.size(); elem++) {
      if (DEBUG) {
        cout << "  elem = " << elem << "; " << modules[elements[elem].typeNum].type << endl;
      }
			nodeValues[toggle][0] = 0; // set ground node to zero each time in case an element tried to overwrite it
			nodeValues[!toggle][0] = 0; // set ground node to zero each time in case an element tried to overwrite it
			if(callType==CALL_TYPE_INITIALIZE || callType==CALL_TYPE_FINISHED) {
				error=modules[elements[elem].typeNum].function(callType, elem, t, tn, inputWaves, nodeValues, elements, simInfo, toggle);
				if (error==-1) {
					cerr << "Error: simpleSimulator: Error returned from circuit block\n";
					return -1;
				}
			}
			else {
				if (tn % (int)elements[elem].defaultParams[PARAM_RUNPERIOD] != 0) {
					for(unsigned int y=0; y<modules[elements[elem].typeNum].outputs.size(); y++){
						OUTPUT(modules[elements[elem].typeNum].outputs[y]) = INPUT(modules[elements[elem].typeNum].outputs[y],);
					}
				}
				else{
					error=modules[elements[elem].typeNum].function(callType, elem, t, tn, inputWaves, nodeValues, elements, simInfo, toggle);
				}

				if (error==-1) {
					cerr << "Error: simpleSimulator: Error returned from circuit block\n";
					return -1;
				}
			}
		}
		toggle = !toggle;
		t=t+1.0/simInfo.sampleRate;
	}
  if (Verbosity == Progress) cout << endl;

	return 0;
}


/*
 * Arguments include:
 * 1) Netlist file
 *  - Includes a line for each device
 *  - Specifies which nets to output
 * 2) Wav file will all input sources
 * 	- May have multiple channels
 * 	- In the netlist file, sources can say they take input from n-th channel of wav file
 * 	- The sampling frequency and duration are set by the wav file
 *
 * Files written by main include:
 * 1) Wav file with all output nets
 *
 * Text output by main include:
 *  - Use argument in config file to suppress debug statements
 */
int main( int argc , char **argv ) {
	vector<elementDef> elementDefs;
	vector<circElement> circElements;
	vec2d inputWaves;
	vec2d nodeValues;
	vector<netInfo> netMap;
	simulationInformation simInfo;
	int error;

	/*
	 * Handle command line arguments
	 */
  int inWav, outWav;
#if COMPILE_IN > 0
  inWav=1;
  outWav=2;
  if (argc == 3) {
  }
  else if ( argc==4 ) {
    Verbosity = Progress;
  }
  else {
		cerr << "ERROR: command syntax is rampSim.exe input.wav output.wav\n";
		return 0;
  }
#else
  inWav=2;
  outWav=3;
  if (argc == 4) {
		simInfo.resultsCsv = "temp.csv";
	}
	else if (argc == 5) {
    Verbosity = Progress;
		simInfo.resultsCsv = argv[4];
	}
	else {
		cerr << "ERROR: command syntax is rampSim netlist.net input.wav output.wav\n";
		return 0;
	}
#endif

	/*
	 * Read and handle input files
	 */
	// Read config file
	populateElementDefinitions(elementDefs);

	//printElementDefinitions(elementDefs);
	// Read netlist file
  if (Verbosity == Progress) cout << "Reading netlist...";
#if COMPILE_IN > 0
	error=readNetlistStrings(circElements);
	if (error==-1) {
		cerr << "Error: main: Error returned from readNetlistStrings\n";
		return -1;
	}

#else
	error=readNetlist(argv[1], circElements);
	if (error==-1) {
		cerr << "Error: main: Error returned from readNetlist\n";
		return -1;
	}
#endif
  if (Verbosity == Progress) cout << " done\n";

	//printCircuitElements(elementDefs, circElements);

	// Read wav file
  if (Verbosity == Progress) cout << "Reading wav file...";

	readWaveFile(argv[inWav], simInfo, inputWaves);
//printWaveFile(simInfo.sampleRate, simInfo.numSamples, simInfo.numInputChannels, inputWaves);
  if (Verbosity == Progress) cout << " done\n";
	simInfo.outputWav = argv[outWav];
	simInfo.inputWav = argv[inWav];

	/*
	 * Initialization
	 */
	// Map nets and initialize parameters for circuit models
  if (Verbosity == Progress) cout << "Initializing circuits...";
	error=initializeCircuits(elementDefs,circElements,netMap,simInfo);
	if (error==-1) {
		cerr << "Error: main: Error returned from initializeCircuits\n";
		return -1;
	}
  if (Verbosity == Progress) cout << " Done\n";
	//printCircuitElements(elementDefs, circElements);

  if (Verbosity == Progress) cout << "Checking netlist...";
	error=netlistChecks(elementDefs,circElements,netMap,simInfo);
	if (error==-1) {
		cerr << "Error: main: Error returned from netlistChecks\n";
		return -1;
	}
  if (Verbosity == Progress) cout << " Done\n";
	/*
	 * Run simulation, pass handle to model
	 */
	///nodeValues.resize(simInfo.numSamples, vector<double>(netMap.size()));
	nodeValues.resize(2, vector<double>(netMap.size()));
	//cout << "Number of nets: " << netMap.size() << endl;
	error=simpleSimulator(CALL_TYPE_INITIALIZE, circElements, elementDefs, inputWaves, netMap, simInfo, nodeValues);
	if (error==-1) {
		cerr << "Error: main: Error returned from simpleSimulator(INITIALIZE)\n";
		return -1;
	}
	error=simpleSimulator(CALL_TYPE_RUN, circElements, elementDefs, inputWaves, netMap, simInfo, nodeValues);
	if (error==-1) {
		cerr << "Error: main: Error returned from simpleSimulator(RUN)\n";
		return -1;
	}
	// if ~differentialSolver, then call voltage-only stepper
	// else call odeint

	/*
	 * Write results
	 */
	// Write wav file
	// Write results to stdout
	//printWaveNodes(simInfo.numSamples, netMap.size(), nodeValues);
	error=simpleSimulator(CALL_TYPE_FINISHED, circElements, elementDefs, inputWaves, netMap, simInfo, nodeValues);
	if (error==-1) {
		cerr << "Error: main: Error returned from simpleSimulator(FINISHED)\n";
		return -1;
	}
	/*
	 * Clean up and exit
	 */

	//cout << "Simulation finished - low memory\n";
	return 0;
}
