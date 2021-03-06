//
//  TWTremolo.h
//  Travelling Waves
//
//  Created by Govinda Ram Pingali on 9/25/18.
//  Copyright © 2018 Govinda Ram Pingali. All rights reserved.
//

#ifndef TWTremolo_h
#define TWTremolo_h

#include <stdio.h>
#include "TWParameter.h"
#include "TWOscillator.h"

class TWTremolo {
    
public:
    
    TWTremolo();
    ~TWTremolo();
    
    void prepare(float sampleRate);
    void process(float& leftSample, float& rightSample);
    void release();
    
    void setWaveform(TWOscillator::TWWaveform waveform);
    void setFrequency(float newFrequency, float rampTime_ms);
    void setDepth(float newDepth, float rampTime_ms);
    void setSoftClipp(float newSoftClipp, float rampTime_ms);
    void setPhaseOffset(float newPhaseOffset, float rampTime_ms);
    
    TWOscillator::TWWaveform getWaveform();
    float getFrequency();
    float getDepth();
    float getSoftClipp();
    float getPhaseOffset();
    
    void resetPhase(float rampTimeInSamples);
    
    void setDebugID(int debugID);
    
private:
    
    float           _sampleRate;
    TWParameter     _depth;
    TWOscillator*   _lfo;
    
    long            _debugCount;
    int             _debugID;
};


#endif /* TWTremolo_h */
