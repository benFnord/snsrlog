// The BSD 2-Clause License (aka "FreeBSD License")
// 
// Copyright (c) 2012, Benjamin Thiel
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met: 
// 
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer. 
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//
//  Gyroscope.h
//  snsrlog
//
//  Created by Benjamin Thiel on 11.03.11.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CMMotionManager.h>
#import "AbstractSensor.h"
#import "Listener.h"
#import "Preferences.h"


@interface Gyroscope : AbstractSensor {
    CMMotionManager *motionManager;
    NSOperationQueue *queue;
	NSMutableSet *accelerometerListeners;
	BOOL isAccelerometerActive;
    
    //as CMMotionManager seems to be unable to report a correct activity status,
    //we track it ourselves. isActive is actually used to express whether it should
    //turned on, not whether it isnt
    BOOL isMotionManagerActive;
    
    //the start of the timestamps in CMDeviceMotion is not defined in the documentation
    //maybe it starts at device boot up?? Oh, Apple....
    NSTimeInterval timestampOffsetFrom1970;
    BOOL timestampOffsetInitialized;
    
    //counts how many values we have skipped due to heavy load conditions
    NSUInteger skipCount;
    
    NSTimer *pollingTimer;
}

@property(nonatomic,readonly) BOOL isAccelerometerActive;
@property(nonatomic) int frequency;

//singleton pattern
+(Gyroscope *)sharedInstance;
-(void)actuallyStart;
-(void)actuallyStop;
-(void)actuallyStopStart;

//methods called by Accelerometer if it acts as a dummy
-(void)startAccelerometer;
-(void)stopAccelerometer;
-(void)addAccelerometerListener:(id <Listener>)listener;
-(void)removeAccelerometerListener:(id<Listener>)listener;
-(void)removeAllAccelerometerListeners;

@end
