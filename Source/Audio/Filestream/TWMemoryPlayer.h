//
//  TWMemoryPlayer.h
//  Travelling Waves
//
//  Created by Govinda Ram Pingali on 4/1/19.
//  Copyright © 2019 Govinda Ram Pingali. All rights reserved.
//

#ifndef TWMemoryPlayer_h
#define TWMemoryPlayer_h

#include <stdio.h>
#include <string>
#include <functional>

#include "TWParameter.h"
#include "TWHeader.h"

#include <AudioToolbox/ExtendedAudioFile.h>
#include <dispatch/dispatch.h>

class TWMemoryPlayer {
    
    
public:
    
    
    TWMemoryPlayer();
    ~TWMemoryPlayer();
    
    
    //--- Audio Source Methods ---//
    void prepare(float sampleRate);
    void getSample(float& leftSample, float& rightSample);
    void release();
    
    
    //--- Setup Methods ---//
    void setReadQueue(dispatch_queue_t readQueue);
    void setNotificationQueue(dispatch_queue_t notificationQueue);
    
    int loadAudioFile(std::string filepath);
    
    void setFinishedPlaybackProc(std::function<void(int,bool)>finishedPlaybackProc);
    
    
    //--- Transport Methods ---//
    int start(int32_t startSampleTime);
    void stop(uint32_t fadeOutSamples);
    TWPlaybackStatus getPlaybackStatus();
    float getNormalizedPlaybackProgress();
    
    
    //--- Playback Property Methods ---//
    void setCurrentVelocity(float velocity, float rampTime_ms);
    float getCurrentVelocity();
    
    void setMaxVolume(float maxVolume, float rampTime_ms);
    float getMaxVolume();
    
    void setPlaybackDirection(TWPlaybackDirection newDirection);
    TWPlaybackDirection getPlaybackDirection();
    
    void setDrumPadMode(TWDrumPadMode drumPadMode);
    TWDrumPadMode getDrumPadMode();
    
    void setSourceIdx(int sourceIdx);
    int getSourceIdx();
    
private:
    
    float                   _sampleRate;
    
    float**                 _buffer;
    uint32_t                 _readIdx;
    uint32_t                _lengthInFrames;
    
    
    TWParameter             _currentVelocity;
    TWParameter             _maxVolume;
    TWParameter             _fadeOutGain;
    
    TWDrumPadMode           _drumPadMode;
    TWPlaybackDirection     _playbackDirection;
    
    TWPlaybackStatus        _playbackStatus;
    int                     _sourceIdx;
    
    bool                    _isRunning;
    bool                    _isStopping;
    uint32_t                _stopSampleCounter;
    
    
    std::function<void(int,bool)>   _finishedPlaybackProc;
    
    
    dispatch_queue_t        _readQueue;
    dispatch_queue_t        _notificationQueue;
    
    AudioBufferList*        _readABL;
    ExtAudioFileRef         _audioFile;
    
    void _printASBD(AudioStreamBasicDescription* asbd, std::string context);
    void _printABL(AudioBufferList *abl, std::string context);
    AudioBufferList* _allocateABL(UInt32 channelsPerFrame, UInt32 bytesPerFrame, bool interleaved, UInt32 capacityFrames);
    void _deallocateABL(AudioBufferList* abl);
    
    
    OSStatus _readHelper(uint32_t * framesToRead);
    void _reset();
    
    void _setPlaybackStatus(TWPlaybackStatus newStatus);
    std::string _playbackStatusToString(TWPlaybackStatus status);
    
    void _setIsIORunning(bool isIORunning);
    
    void _stoppingTick();
    
    void _incDecReadIdx();
    void _setReadIdx(int32_t newReadIdx);
    void _fadeOutTailEnd(uint32_t endSamplesToFadeOut);
};

#endif /* TWMemoryPlayer_h */