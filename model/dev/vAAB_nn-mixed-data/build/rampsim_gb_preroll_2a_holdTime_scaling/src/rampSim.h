/*
 * rampSim.h
 *
 *  Created on: Apr 13, 2017
 *      Author: Brandon
 */

#ifndef RAMPSIM_H_
#define RAMPSIM_H_

#include <string>

typedef std::vector <std::vector<double> > vec2d;

#define STRING_EQUAL 0
#define CALL_TYPE_INITIALIZE 0
#define CALL_TYPE_RUN 1
#define CALL_TYPE_FINISHED 2
#define WAV_SCALE 5
#define VDD 2.5

/*
 * Structure to store information about the simulation.
 */
struct simulationInformation {
	int sampleRate;
	int numSamples;
	int numInputChannels;
	int numNets;
	int numOutputNets;
	std::string inputWav;
	std::string outputWav;
	std::string resultsCsv;
};


#endif /* RAMPSIM_H_ */
