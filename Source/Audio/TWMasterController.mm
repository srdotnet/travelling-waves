//
//  TWMasterController.m
//  Travelling Waves
//
//  Created by Govinda Ram Pingali on 9/21/18.
//  Copyright © 2018 Govinda Ram Pingali. All rights reserved.
//

#import "TWMasterController.h"
#import "TWAudioController.h"
#import "TWClock.h"

@interface TWMasterController()
{
    int             _timeControlRatios[kNumTimeRatioControls][2][kNumSources];
    NSDictionary*   _copyOscDictionary;
}
@end



@implementation TWMasterController


- (id)init {
    
    if (self = [super init]) {
        
        // Create and initialize TWAudioController
        [TWAudioController sharedController];
        [self initializeDefaults];
        
        // Initialize Clock
        [TWClock sharedClock];
        
        
        // Setup Project Directory
        NSError* error;
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* documentsDirectory = [paths objectAtIndex:0];
        _projectsDirectory = [[NSString alloc] initWithString:[documentsDirectory stringByAppendingPathComponent:@"Projects"]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_projectsDirectory]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_projectsDirectory withIntermediateDirectories:NO attributes:nil error:&error];
            if (error) {
                NSLog(@"Settings Init: Error! creating projectsDirectory: %@", error.description);
            }
        }
        
        [self loadOsterCurve];
        
        [self resetFrequencyChartCaches];
        
        _projectName = @"Default";
        
        _copyOscDictionary = nil;
    }
    
    return self;
}



+ (instancetype)sharedController {
    static dispatch_once_t onceToken;
    static TWMasterController* controller;
    dispatch_once(&onceToken, ^{
        controller = [[TWMasterController alloc] init];
    });
    return controller;
}

- (void)initializeDefaults {
    
    _rootFrequency = kDefaultFrequency;
    _rampTime_ms = kDefaultRampTime_ms;
    _tempo = kDefaultTempo;
    
    for (int idx=0; idx < kNumSources; idx++) {
        for (int control = 0; control < kNumTimeRatioControls; control++) {
            
            int defaultNumerator = 1;
            if (control == TWTimeRatioControl_BeatFrequency) {
                defaultNumerator = 0;
            }
            _timeControlRatios[control][kNumerator][idx]      = defaultNumerator;
            _timeControlRatios[control][kDenominator][idx]    = 1;
            
            [self setValueForTimeControl:(TWTimeRatioControl)control atSourceIdx:idx];
        }
    }
    
    [[TWAudioController sharedController] setOscParameter:TWOscParamID_OscAmplitude withValue:kDefaultAmplitude atSourceIdx:0 inTime:0.0f];
    
    for (int idx=1; idx < kNumSources; idx++) {
        [[TWAudioController sharedController] setOscParameter:TWOscParamID_OscAmplitude withValue:0.0f atSourceIdx:idx inTime:0.0f];
    }
    
    _beatsPerBar = kDefaultBeatsPerBar;
    [self setSeqDurationFromTempo];
}


#pragma mark - API

- (BOOL)isAudioRunning {
    return [[TWAudioController sharedController] isRunning];
}


- (void)setRootFrequency:(float)rootFrequency {
    _rootFrequency = rootFrequency;
    for (int idx=0; idx < kNumSources; idx++) {
        [self setValueForTimeControl:TWTimeRatioControl_BaseFrequency atSourceIdx:idx];
    }
}


- (void)setRampTime_ms:(int)rampTime_ms {
    _rampTime_ms = rampTime_ms;
    for (int idx=0; idx < kNumSources; idx++) {
        [[TWAudioController sharedController] setOscParameter:TWOscParamID_RampTime_ms withValue:_rampTime_ms atSourceIdx:idx inTime:0.0f];
    }
}


- (void)setTempo:(float)tempo {
    _tempo = tempo;
    for (int control = 1; control < kNumTimeRatioControls; control++) {
        for (int idx=0; idx < kNumSources; idx++) {
            [self setValueForTimeControl:(TWTimeRatioControl)control atSourceIdx:idx];
        }
    }
    [self setSeqDurationFromTempo];
}

- (void)setBeatsPerBar:(float)beatsPerBar {
    _beatsPerBar = beatsPerBar;
    [self setSeqDurationFromTempo];
}



- (int)incNumeratorRatioForControl:(TWTimeRatioControl)control atSourceIdx:(int)idx {
    ++_timeControlRatios[control][kNumerator][idx];
    [self setValueForTimeControl:control atSourceIdx:idx];
    return _timeControlRatios[control][kNumerator][idx];
}

- (int)decNumeratorRatioForControl:(TWTimeRatioControl)control atSourceIdx:(int)idx {
    int minValue = 1;
    if (control == TWTimeRatioControl_BeatFrequency) {
        minValue = 0;
    }
    if (--_timeControlRatios[control][kNumerator][idx] <= minValue) {
        _timeControlRatios[control][kNumerator][idx] = minValue;
    }
    [self setValueForTimeControl:control atSourceIdx:idx];
    return _timeControlRatios[control][kNumerator][idx];
}


- (int)incDenominatorRatioForControl:(TWTimeRatioControl)control atSourceIdx:(int)idx {
    ++_timeControlRatios[control][kDenominator][idx];
    [self setValueForTimeControl:control atSourceIdx:idx];
    return _timeControlRatios[control][kDenominator][idx];
}

- (int)decDenominatorRatioForControl:(TWTimeRatioControl)control atSourceIdx:(int)idx {
    if (--_timeControlRatios[control][kDenominator][idx] <= 1) {
        _timeControlRatios[control][kDenominator][idx] = 1;
    }
    [self setValueForTimeControl:control atSourceIdx:idx];
    return _timeControlRatios[control][kDenominator][idx];
}


- (void)setNumeratorRatioForControl:(TWTimeRatioControl)control withValue:(int)numerator atSourceIdx:(int)idx {
    if (numerator <= 1) {
        numerator = 1;
    }
    _timeControlRatios[control][kNumerator][idx] = numerator;
    [self setValueForTimeControl:control atSourceIdx:idx];
}

- (void)setDenominatorRatioForControl:(TWTimeRatioControl)control withValue:(int)denominator atSourceIdx:(int)idx {
    if (denominator <= 1) {
        denominator = 1;
    }
    _timeControlRatios[control][kDenominator][idx] = denominator;
    [self setValueForTimeControl:control atSourceIdx:idx];
}

- (int)getNumeratorRatioForControl:(TWTimeRatioControl)control atSourceIdx:(int)idx {
    return _timeControlRatios[control][kNumerator][idx];
}

- (int)getDenominatorRatioForControl:(TWTimeRatioControl)control atSourceIdx:(int)idx {
    return _timeControlRatios[control][kDenominator][idx];
}




#pragma mark - Project Parameter Saving

// TODO: Add Time Control Ratios to Project Settings

- (BOOL)saveProjectWithFilename:(NSString *)filename {
    NSError* error;
    NSString* filepath = [_projectsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", filename]];
    NSLog(@"Filepath: %@", filepath);
    _projectName = filename;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[self getCurrentParametersAsDictionary] options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"Error in NSJSONSerialization: %@", error.description);
        return NO;
    }
    return [jsonData writeToFile:filepath atomically:NO];
}

- (int)loadProjectFromFilename:(NSString *)filename {
    NSString* filepath = [_projectsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", filename]];
    NSLog(@"Filepath: %@", filepath);
    return [self loadProjectFromFilepath:filepath];
}

- (int)loadProjectFromFilepath:(NSString *)filepath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
        NSData* data = [NSData dataWithContentsOfFile:filepath];
        NSDictionary* dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        if (dictionary == nil) {
            return -2;
        }
        if (![self loadParametersFromDictionary:dictionary]) {
            return -2;
        }
        [self resetFrequencyChartCaches];
        return 0;
    }
    return -1;
}

- (NSArray<NSString*>*)getListOfSavedFilenames {
    NSError* error;
    NSArray* contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_projectsDirectory error:&error];
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for (NSString* filepath in contents) {
        if ([[filepath pathExtension] isEqualToString:@"json"]) {
            NSString* filename = [filepath lastPathComponent];
            [array addObject:[filename stringByDeletingPathExtension]];
        }
    }
    return array;
}

- (BOOL)deleteProjectWithFilename:(NSString *)filename {
    NSString* filepath = [_projectsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", filename]];
    if ([[NSFileManager defaultManager] removeItemAtPath:filepath error:nil]) {
        return YES;
    }
    return NO;
}


- (NSArray<NSString*>*)getListOfPresetDrumPadSets {
    NSArray* array = [[NSArray alloc] initWithObjects:@"Minimal Percs", nil];
    return array;
}

#pragma mark - Private


- (NSDictionary*)getCurrentParametersAsDictionary {
    
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    
    @synchronized(self) {
        
        NSMutableDictionary* project = [[NSMutableDictionary alloc] init];
        
        // Name
        project[@"Name"] = _projectName;
        
        // Parameters
        NSMutableDictionary* parameters = [[NSMutableDictionary alloc] init];
        parameters[@"Root Frequency"] = @(_rootFrequency);
        parameters[@"Base Ramp Time (ms)"] = @(_rampTime_ms);
        parameters[@"Num Sources"] = @(kNumSources);
        parameters[@"Tempo"] = @(_tempo);
        
        NSMutableArray* sources = [[NSMutableArray alloc] init];
        
        for (int sourceIdx=0; sourceIdx < kNumSources; sourceIdx++) {
            NSMutableDictionary* sourceParams = [[NSMutableDictionary alloc] init];
            
            sourceParams[@"Idx"] = @(sourceIdx);
            
            for (int paramID = 0; paramID < kNumTimeRatioControls; paramID++) {
                NSString* key = [self keyForTimeRatioControlParamID:(TWTimeRatioControl)paramID];
                if ((key != nil) && (![key isEqualToString:@""])) {
                    sourceParams[key] = @[@(_timeControlRatios[paramID][kNumerator][sourceIdx]), @(_timeControlRatios[paramID][kDenominator][sourceIdx])];
                }
            }
            
            [sourceParams addEntriesFromDictionary:[self getOscParamsAsDictionaryForSourceIdx:sourceIdx]];
            
            [sources addObject:sourceParams];
        }
        
        parameters[@"Sources"] = sources;
        
        
        
        NSMutableDictionary* sequencer = [[NSMutableDictionary alloc] init];
        NSMutableArray* envelopes = [[NSMutableArray alloc] init];
        NSMutableArray* events = [[NSMutableArray alloc] init];
        for (int sourceIdx=0; sourceIdx < kNumSources; sourceIdx++) {
            NSMutableDictionary* envelope = [[NSMutableDictionary alloc] init];
            int interval = [[TWAudioController sharedController] getSeqIntervalAtSourceIdx:sourceIdx];
            envelope[@"Interval"] = @(interval);
            envelope[@"Enable"] = @([[TWAudioController sharedController] getSeqEnabledAtSourceIdx:sourceIdx]);
            for (int paramID=1; paramID < kSeqNumParams; paramID++) {
                NSString* key = [self keyForSeqParamID:(TWSeqParamID)paramID];
                if ((key != nil) && (![key isEqualToString:@""])) {
                    envelope[key] = @([[TWAudioController sharedController] getSeqParameter:(TWSeqParamID)paramID atSourceIdx:sourceIdx]);
                }
            }
            [envelopes addObject:envelope];
            for (int beat=0; beat < interval; beat++) {
                if ([[TWAudioController sharedController] getSeqNoteAtSourceIdx:sourceIdx atBeat:beat]) {
                    [events addObject:@{@"Src" : @(sourceIdx), @"Beat" : @(beat)}];
                }
            }
        }
        sequencer[@"Envelopes"] = envelopes;
        sequencer[@"Events"] = events;
        sequencer[@"Seq Duration (ms)"] = @([[TWAudioController sharedController] getSeqParameter:TWSeqParamID_Duration_ms
                                                                                      atSourceIdx:-1]);
        
        parameters[@"Sequencer"] = sequencer;
        
        
        NSMutableDictionary* drumPad = [[NSMutableDictionary alloc] init];
        NSMutableArray* drumPadSourceParams = [[NSMutableArray alloc] init];
        
        for (int sourceIdx=0; sourceIdx < kNumSources; sourceIdx++) {
            
            NSMutableDictionary* padParams = [[NSMutableDictionary alloc] init];
            
            for (int paramID = 1; paramID < kPadNumSetParams; paramID++) {
                NSString* key = [self keyForPadParamID:(TWPadParamID)paramID];
                if ((key != nil) && (![key isEqualToString:@""])) {
                    padParams[key] = @([[TWAudioController sharedController] getPadParameter:(TWPadParamID)paramID atSourceIdx:sourceIdx]);
                }
            }
            
            NSString* filename = [[TWAudioController sharedController] getAudioFileTitleAtSourceIdx:sourceIdx];
            padParams[@"Filename"] = [filename stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
            
            [drumPadSourceParams addObject:padParams];
        }
        drumPad[@"Sources"] = drumPadSourceParams;
        
        parameters[@"DrumPad"] = drumPad;
        
        project[@"Parameters"] = parameters;
        
        
        dictionary[@"Travelling Waves Project"] = project;
    }
    
    return dictionary;
}


- (BOOL)loadParametersFromDictionary:(NSDictionary*)dictionary {
    
    if ([dictionary objectForKey:@"Travelling Waves Project"] == nil) {
        return NO;
    }
    
    NSDictionary* project = [dictionary objectForKey:@"Travelling Waves Project"];
    
    // Name
    if ([project objectForKey:@"Name"] != nil) {
        _projectName = dictionary[@"Name"];
    }
    
    // Parameters
    if ([project objectForKey:@"Parameters"] != nil) {
        
        TWAudioController* controller = [TWAudioController sharedController];
        
        NSDictionary* parameters = project[@"Parameters"];
        
        if ([parameters objectForKey:@"Root Frequency"] != nil) {
            _rootFrequency = [parameters[@"Root Frequency"] floatValue];
        }
        
        if ([parameters objectForKey:@"Base Ramp Time (ms)"] != nil) {
            _rampTime_ms = [parameters[@"Base Ramp Time (ms)"] intValue];
        }
        
        if ([parameters objectForKey:@"Tempo"] != nil) {
            _tempo = [parameters[@"Tempo"] floatValue];
        }
        
        int numSources = kNumSources;
        if ([parameters objectForKey:@"Num Sources"] != nil) {
            numSources = [parameters[@"Num Sources"] intValue];
            if (numSources > kNumSources) {
                numSources = kNumSources;
            }
        }
        
        if ([parameters objectForKey:@"Sources"] != nil) {
            
            NSArray* sources = parameters[@"Sources"];
            
            for (int sourceIdx=0; sourceIdx < numSources; sourceIdx++) {
                
                NSDictionary* sourceParams = sources[sourceIdx];
                if (sourceParams == nil) {
                    continue;
                }
                
                
                for (int paramID = 0; paramID < kNumTimeRatioControls; paramID++) {
                    NSString* key = [self keyForTimeRatioControlParamID:(TWTimeRatioControl)paramID];
                    if ((key != nil) && (![key isEqualToString:@""])) {
                        if ([sourceParams objectForKey:key]) {
                            _timeControlRatios[paramID][kNumerator][sourceIdx] = [sourceParams[key][kNumerator] intValue];
                            _timeControlRatios[paramID][kDenominator][sourceIdx] = [sourceParams[key][kDenominator] intValue];
                        }
                    }
                }
                
                
                int rampTime_ms = (int)[controller getOscParameter:TWOscParamID_RampTime_ms atSourceIdx:sourceIdx];
                if ([sourceParams objectForKey:@"Ramp Time (ms)"]) {
                    rampTime_ms = [sourceParams[@"Ramp Time (ms)"] intValue];
                }
                [controller setOscParameter:TWOscParamID_RampTime_ms withValue:rampTime_ms atSourceIdx:sourceIdx inTime:0.0f];
                
                
                for (int control=0; control < kNumTimeRatioControls; control++) {
                    [self setValueForTimeControl:(TWTimeRatioControl)control atSourceIdx:sourceIdx];
                }
                
                for (int paramID = 1; paramID < kOscNumParams; paramID++) {
                    [self setOscParamValue:(TWOscParamID)paramID fromDictionary:sourceParams atSourceIdx:sourceIdx inTime:rampTime_ms];
                }
            }
        }
        
        
        if ([parameters objectForKey:@"Sequencer"] != nil) {
            
            NSDictionary* sequencer = parameters[@"Sequencer"];
            
            if ([sequencer objectForKey:@"Seq Duration (ms)"]) {
                [controller setSeqParameter:TWSeqParamID_Duration_ms
                                  withValue:[sequencer[@"Seq Duration (ms)"] floatValue]
                                atSourceIdx:-1];
            }
            
            if ([sequencer objectForKey:@"Envelopes"] != nil) {
                NSArray* envelopes = sequencer[@"Envelopes"];
                
                for (int sourceIdx = 0; sourceIdx < numSources; sourceIdx++) {
                    NSDictionary* envelope = envelopes[sourceIdx];
                    
                    if (envelope == nil) {
                        continue;
                    }
                    
                    if ([envelope objectForKey:@"Interval"] != nil) {
                        [controller setSeqInterval:[envelope[@"Interval"] intValue] atSourceIdx:sourceIdx];
                    }
                    
                    if ([envelope objectForKey:@"Enable"]) {
                        [controller setSeqEnabled:[envelope[@"Enable"] boolValue] atSourceIdx:sourceIdx];
                    }
                    for (int paramID = 1; paramID < kSeqNumParams; paramID++) {
                        [self setSeqParamValue:(TWSeqParamID)paramID fromDictionary:envelope atSourceIdx:sourceIdx];
                    }
                }
            }
            
            if ([sequencer objectForKey:@"Events"] != nil) {
                [controller clearSeqEvents];
                NSArray* events = sequencer[@"Events"];
                for (NSDictionary* event in events) {
                    [controller setSeqNote:1 atSourceIdx:[event[@"Src"] intValue] atBeat:[event[@"Beat"] intValue]];
                }
            }
        }
        
        
        if ([parameters objectForKey:@"DrumPad"] != nil) {
            
            NSDictionary* drumPad = parameters[@"DrumPad"];
            NSArray* drumPadSources = (NSArray*)drumPad[@"Sources"];
            
            for (int sourceIdx=0; sourceIdx < numSources; sourceIdx++) {
                
                NSDictionary* padParams = [drumPadSources objectAtIndex:sourceIdx];
                
                for (int i=1; i < kPadNumSetParams; i++) {
                    [self setPadParamValue:(TWPadParamID)i fromDictionary:padParams atSourceIdx:sourceIdx];
                }
                
                
                if ([padParams objectForKey:@"Filename"]) {
                    NSString* filename = padParams[@"Filename"];
                    if ((filename != nil) && (![filename isEqualToString:@""])) {
                        NSString* filepath = [[NSBundle mainBundle] pathForResource:filename ofType:@"wav"];
                        NSString* outfilepath = [filepath stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                        [controller loadAudioFile:outfilepath atSourceIdx:sourceIdx];
                    }
                }
            }
        }
    }
    
    return YES;
}




- (void)loadOsterCurve {
    NSString* filepath = [[NSBundle mainBundle] pathForResource:@"OsterCurve" ofType:@"json"];
    NSData* data = [NSData dataWithContentsOfFile:filepath];
    NSDictionary* dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    _osterCurve = [[NSArray alloc] initWithArray:dictionary[@"OsterCurve"]];
}






#pragma mark - Helper Methods


- (void)setOscParamValue:(TWOscParamID)paramID fromDictionary:(NSDictionary*)sourceDictionary atSourceIdx:(int)sourceIdx inTime:(float)rampTime_ms {
    NSString* key = [self keyForOscParamID:paramID];
    if ([sourceDictionary objectForKey:key]) {
        [[TWAudioController sharedController] setOscParameter:paramID withValue:[sourceDictionary[key] floatValue] atSourceIdx:sourceIdx inTime:rampTime_ms];
    }
}


- (void)setSeqParamValue:(TWSeqParamID)paramID fromDictionary:(NSDictionary*)sourceDictionary atSourceIdx:(int)sourceIdx {
    NSString* key = [self keyForSeqParamID:paramID];
    if ([sourceDictionary objectForKey:key]) {
        [[TWAudioController sharedController] setSeqParameter:paramID withValue:[sourceDictionary[key] floatValue] atSourceIdx:sourceIdx];
    }
}


- (void)setPadParamValue:(TWPadParamID)paramID fromDictionary:(NSDictionary*)sourceDictionary atSourceIdx:(int)sourceIdx {
    NSString* key = [self keyForPadParamID:paramID];
    if ([sourceDictionary objectForKey:key]) {
        [[TWAudioController sharedController] setPadParameter:paramID withValue:[sourceDictionary[key] floatValue] atSourceIdx:sourceIdx inTime:0.0];
    }
}


- (void)setValueForTimeControl:(TWTimeRatioControl)control atSourceIdx:(int)sourceIdx {
    
    float numerator = (float)_timeControlRatios[control][kNumerator][sourceIdx];
    float denominator = (float)_timeControlRatios[control][kDenominator][sourceIdx];
    int rampTime_ms = (int)[[TWAudioController sharedController] getOscParameter:TWOscParamID_RampTime_ms atSourceIdx:sourceIdx];
    float value = 0.0f;
    
    switch (control) {
            
        case TWTimeRatioControl_BaseFrequency:
            value = _rootFrequency * numerator / denominator;
            [[TWAudioController sharedController] setOscParameter:TWOscParamID_OscBaseFrequency withValue:value atSourceIdx:sourceIdx inTime:rampTime_ms];
            break;
            
        case TWTimeRatioControl_BeatFrequency:
            value = (_tempo / 60.0f) * numerator / denominator;
            [[TWAudioController sharedController] setOscParameter:TWOscParamID_OscBeatFrequency withValue:value atSourceIdx:sourceIdx inTime:rampTime_ms];
            break;
            
        case TWTimeRatioControl_TremFrequency:
            value = (_tempo / 60.0f) * numerator / denominator;
            [[TWAudioController sharedController] setOscParameter:TWOscParamID_TremoloFrequency withValue:value atSourceIdx:sourceIdx inTime:rampTime_ms];
            break;
            
        case TWTimeRatioControl_ShapeTremFrequency:
            value = (_tempo / 60.0f) * numerator / denominator;
            [[TWAudioController sharedController] setOscParameter:TWOscParamID_ShapeTremoloFrequency withValue:value atSourceIdx:sourceIdx inTime:rampTime_ms];
            break;
            
        case TWTimeRatioControl_FilterLFOFrequency:
            value = (_tempo / 60.0f) * numerator / denominator;
            [[TWAudioController sharedController] setOscParameter:TWOscParamID_FilterLFOFrequency withValue:value atSourceIdx:sourceIdx inTime:rampTime_ms];
            break;
    }
}



- (void)setSeqDurationFromTempo {
    float duration_ms = 60000.0f * _beatsPerBar / _tempo;
    [[TWAudioController sharedController] setSeqParameter:TWSeqParamID_Duration_ms withValue:duration_ms atSourceIdx:-1];
}



- (NSDictionary*)getOscParamsAsDictionaryForSourceIdx:(int)sourceIdx {
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    for (int paramID = 1; paramID < kOscNumParams; paramID++) {
        NSString* key = [self keyForOscParamID:(TWOscParamID)paramID];
        if ((key != nil) && (![key isEqualToString:@""])) {
            dictionary[key] = @([[TWAudioController sharedController] getOscParameter:(TWOscParamID)paramID atSourceIdx:sourceIdx]);
        }
    }
    dictionary[@"Ramp Time (ms)"] = @((int)[[TWAudioController sharedController] getOscParameter:TWOscParamID_RampTime_ms atSourceIdx:sourceIdx]);
    return dictionary;
}


- (void)copyOscParamsAtSourceIdx:(int)sourceIdx {
    if (_copyOscDictionary) {
        _copyOscDictionary = nil;
    }
    _copyOscDictionary = [[NSDictionary alloc] initWithDictionary:[self getOscParamsAsDictionaryForSourceIdx:sourceIdx]];
}

- (void)pasteOscParamsAtSourceIdx:(int)sourceIdx {
    
    if (_copyOscDictionary == nil) {
        return;
    }
    
    int rampTime_ms = (int)[[TWAudioController sharedController] getOscParameter:TWOscParamID_RampTime_ms atSourceIdx:sourceIdx];
    if ([_copyOscDictionary objectForKey:@"Ramp Time (ms)"]) {
        rampTime_ms = [_copyOscDictionary[@"Ramp Time (ms)"] intValue];
    }
    [[TWAudioController sharedController] setOscParameter:TWOscParamID_RampTime_ms withValue:rampTime_ms atSourceIdx:sourceIdx inTime:0.0f];
    
    for (int paramID = 1; paramID < kOscNumParams; paramID++) {
        [self setOscParamValue:(TWOscParamID)paramID fromDictionary:_copyOscDictionary atSourceIdx:sourceIdx inTime:rampTime_ms];
    }
}


#pragma mark - Dictionary Param Keys


- (NSString*)keyForTimeRatioControlParamID:(TWTimeRatioControl)paramID {
    
    NSString* key = nil;
    
    switch (paramID) {
        case TWTimeRatioControl_BaseFrequency:
            key = @"Tunings";
            break;
            
        case TWTimeRatioControl_BeatFrequency:
            key = @"Beat Freq Ratios";
            break;
            
        case TWTimeRatioControl_TremFrequency:
            key = @"Trem Freq Ratios";
            break;
            
        case TWTimeRatioControl_ShapeTremFrequency:
            key = @"Shape Trem Freq Ratios";
            break;
            
        case TWTimeRatioControl_FilterLFOFrequency:
            key = @"Filter LFO Freq Ratios";
            break;
            
        default:
            break;
    }
    
    return key;
}


- (NSString*)keyForOscParamID:(TWOscParamID)paramID {
    
    NSString* key = nil;
    
    switch (paramID) {
        case TWOscParamID_OscWaveform:
            key = @"Osc Wave";
            break;
            
        case TWOscParamID_OscBaseFrequency:
            key = @"Osc Base Frequency";
            break;
            
        case TWOscParamID_OscBeatFrequency:
            key = @"Osc Beat Frequency";
            break;
            
        case TWOscParamID_OscAmplitude:
            key = @"Osc Amplitude";
            break;
            
        case TWOscParamID_OscDutyCycle:
            key = @"Osc Duty Cycle";
            break;
            
        case TWOscParamID_OscMononess:
            key = @"Osc Mononess";
            break;
            
        case TWOscParamID_OscSoftClipp:
            key = @"Osc Soft Clipp";
            break;
            
        case TWOscParamID_TremoloWaveform:
            key = @"Tremolo Waveform";
            break;
            
        case TWOscParamID_TremoloFrequency:
            key = @"Tremolo Frequency";
            break;
            
        case TWOscParamID_TremoloDepth:
            key = @"Tremolo Depth";
            break;
            
        case TWOscParamID_ShapeTremoloFrequency:
            key = @"Shape Tremolo Frequency";
            break;
            
        case TWOscParamID_ShapeTremoloDepth:
            key = @"Shape Tremolo Depth";
            break;
            
        case TWOscParamID_ShapeTremoloSoftClipp:
            key = @"Shape Tremolo Soft Clipp";
            break;
            
        case TWOscParamID_FilterEnable:
            key = @"Filter Enable";
            break;
            
        case TWOscParamID_FilterType:
            key = @"Filter Type";
            break;
            
        case TWOscParamID_FilterCutoff:
            key = @"Filter Cutoff";
            break;
            
        case TWOscParamID_FilterResonance:
            key = @"Filter Q";
            break;
            
        case TWOscParamID_FilterGain:
            key = @"Filter G";
            break;
            
        case TWOscParamID_FilterLFOEnable:
            key = @"Filter LFO Enable";
            break;
            
        case TWOscParamID_FilterLFOWaveform:
            key = @"Filter LFO Waveform";
            break;
            
        case TWOscParamID_FilterLFOFrequency:
            key = @"Filter LFO Rate";
            break;
            
        case TWOscParamID_FilterLFORange:
            key = @"Filter LFO Range";
            break;
            
        case TWOscParamID_FilterLFOOffset:
            key = @"Filter LFO Offset";
            break;
            
        case TWOscParamID_OscFMAmount:
            key = @"Osc FM Amount";
            break;
            
        case TWOscParamID_OscFMFrequency:
            key = @"Osc FM Frequency";
            break;
            
        case TWOscParamID_OscFMWaveform:
            key = @"Osc FM Waveform";
            break;
            
        default:
            key = nil;
            break;
    }
    
    return key;
}


- (NSString*)keyForSeqParamID:(TWSeqParamID)paramID {
    
    NSString* key = nil;
    
    switch (paramID) {
        case TWSeqParamID_AmpAttackTime:
            key = @"Amp Env Attack Time (ms)";
            break;
            
        case TWSeqParamID_AmpSustainTime:
            key = @"Amp Env Sustain Time (ms)";
            break;
            
        case TWSeqParamID_AmpReleaseTime:
            key = @"Amp Env Release Time (ms)";
            break;
            
        case TWSeqParamID_FilterEnable:
            key = @"Filter Env Enable";
            break;
            
        case TWSeqParamID_FilterType:
            key = @"Filter Env Type";
            break;
            
        case TWSeqParamID_FilterAttackTime:
            key = @"Filter Env Attack Time (ms)";
            break;
            
        case TWSeqParamID_FilterSustainTime:
            key = @"Filter Env Sustain Time (ms)";
            break;
            
        case TWSeqParamID_FilterReleaseTime:
            key = @"Filter Env Release Time (ms)";
            break;
            
        case TWSeqParamID_FilterFromCutoff:
            key = @"Filter Env From Cutoff";
            break;
            
        case TWSeqParamID_FilterToCutoff:
            key = @"Filter Env To Cutoff";
            break;
            
        case TWSeqParamID_FilterResonance:
            key = @"Filter Env Q";
            break;
            
        default:
            key = nil;
            break;
    }
    
    return key;
}

- (NSString*)keyForPadParamID:(TWPadParamID)paramID {
    
    NSString* key = nil;
    
    switch (paramID) {
        case TWPadParamID_DrumPadMode:
            key = @"Pad Mode";
            break;
            
        case TWPadParamID_MaxVolume:
            key = @"Pad Max Volume";
            break;
            
        case TWPadParamID_PlaybackDirection:
            key = @"Pad Direction";
            break;
            
        default:
            break;
    }
    
    return key;
}



- (void)resetFrequencyChartCaches {
    _equalTemperamentSelectedIndexPath = nil;
    _frequencyChartSelectedSegmentIndex = 0;
    _equalTemparementSelectedScrollPosition = CGPointMake(0.0f, 0.0f);
}

@end
