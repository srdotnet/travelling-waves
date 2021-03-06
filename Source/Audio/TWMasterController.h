//
//  TWMasterController.h
//  Travelling Waves
//
//  Created by Govinda Ram Pingali on 9/21/18.
//  Copyright © 2018 Govinda Ram Pingali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TWOscView.h"
#import "TWMixerView.h"
#import "TWHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface TWMasterController : NSObject

+ (instancetype)sharedController;

- (BOOL)isAudioRunning;

@property (nonatomic, weak) NSArray<TWOscView*>* oscViews;
@property (nonatomic, weak) TWOscView* currentOscView;
@property (nonatomic, weak) TWMixerView* mixerView;

@property (nonatomic, assign) float rootFrequency;
@property (nonatomic, assign) float tempo;
@property (nonatomic, assign) float beatsPerBar;
@property (nonatomic, assign) int   rampTime_ms;


//--- FrequencyChartViewController Caches ---//
@property (nonatomic, strong) NSIndexPath* equalTemperamentSelectedIndexPath;
@property (nonatomic, assign) CGPoint equalTemparementSelectedScrollPosition;
@property (nonatomic, assign) NSInteger frequencyChartSelectedSegmentIndex;


- (int)incNumeratorRatioForControl:(TWTimeRatioControl)control atSourceIdx:(int)idx;
- (int)decNumeratorRatioForControl:(TWTimeRatioControl)control atSourceIdx:(int)idx;
- (int)incDenominatorRatioForControl:(TWTimeRatioControl)control atSourceIdx:(int)idx;
- (int)decDenominatorRatioForControl:(TWTimeRatioControl)control atSourceIdx:(int)idx;

- (void)setNumeratorRatioForControl:(TWTimeRatioControl)control withValue:(int)numerator atSourceIdx:(int)idx;
- (void)setDenominatorRatioForControl:(TWTimeRatioControl)control withValue:(int)denominator atSourceIdx:(int)idx;
- (int)getNumeratorRatioForControl:(TWTimeRatioControl)control atSourceIdx:(int)idx;
- (int)getDenominatorRatioForControl:(TWTimeRatioControl)control atSourceIdx:(int)idx;


- (BOOL)saveProjectWithFilename:(NSString*)filename;
- (int)loadProjectFromFilename:(NSString*)filename;
- (BOOL)deleteProjectWithFilename:(NSString*)filename;
- (int)loadProjectFromFilepath:(NSString*)filepath;
- (NSArray<NSString*>*)getListOfSavedFilenames;
@property (nonatomic, readonly)NSString* projectsDirectory;
@property (nonatomic, strong)NSString* projectName;


- (NSArray<NSString*>*)getListOfPresetDrumPadSets;

- (void)copyOscParamsAtSourceIdx:(int)sourceIdx;
- (void)pasteOscParamsAtSourceIdx:(int)sourceIdx;

@property (nonatomic, readonly)NSArray* osterCurve;

@end

NS_ASSUME_NONNULL_END
