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
//  Accelerometer.h
//  snsrlog
//
//  Created by Benjamin Thiel on 07.03.11.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CMMotionManager.h>
#import "AbstractSensor.h"


@interface Accelerometer : AbstractSensor {
	CMMotionManager *motionManager;
    NSOperationQueue *queue;

    //the start of the timestamps in CMDeviceMotion is not defined in the documentation
    //maybe it starts at device boot up?? Oh, Apple....
    NSTimeInterval timestampOffsetFrom1970;
    BOOL timestampOffsetInitialized;
    
    //YES if this class acts as a dummy and forwards its calls to Gyroscope
	BOOL isDummy;
    
    //counts how many values we have skipped due to heavy load conditions
    NSUInteger skipCount;
}

//YES if this class acts as a dummy and forwards its calls to Gyroscope
@property(readonly,nonatomic) BOOL isDummy;
@property(nonatomic) int frequency;

//singleton pattern
+(Accelerometer *)sharedInstance;
-(BOOL)isAvailable;
-(void)actuallyStart;
-(void)actuallyStop;

@end
