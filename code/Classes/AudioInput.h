//
//  AudioInput.h
//  snsrlog
//
//  Created by Benjamin Thiel on 10.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVAudioSession.h>
#import "AbstractSensor.h"

extern NSString* const AudioInputAvailabilityChangedNotification;

@interface AudioInput : AbstractSensor <AVAudioSessionDelegate> {
    
    AudioQueueRef				queueObject; // the audio queue object being used
    AudioQueueLevelMeterState	*audioLevels;
    Float64						hardwareSampleRate;
    AudioStreamBasicDescription	audioFormat;
    
    BOOL                        interruptedDuringRecording;
    BOOL                        levelMeteringEnabled;
}

@property (nonatomic, readonly) Float64 hardwareSampleRate;
@property (nonatomic, readwrite) BOOL levelMeteringEnabled;

//singleton
+ (AudioInput *)sharedInstance;
- (void) actuallyStart;
- (void) actuallyStop;

//audio levels can be queried if levelMeteringEnabled == YES
- (void) getAudioLevels: (Float32 *) levels peakLevels: (Float32 *) peakLevels;

//called by callbacks
- (void) didReceiveNewAudioBuffer:(AudioQueueBufferRef)buffer withNumberOfPackets:(UInt32)number andPacketDescription:(const AudioStreamPacketDescription *)description;
- (void) audioRouteChangedFrom:(NSString *)oldRoute to:(NSString *)newRoute forReason:(NSNumber *)reason;

//AVAudioSessionDelegate
- (void) beginInterruption;
- (void) endInterruptionWithFlags:(NSUInteger)flags;
- (void) inputIsAvailableChanged:(BOOL)isInputAvailable;

@end
