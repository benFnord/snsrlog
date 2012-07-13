//
//  Gyroscope.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 11.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CMMotionManager.h>
#import "AbstractSensor.h"
#import "Listener.h"
#import "Preferences.h"


@interface Gyroscope : AbstractSensor {
    CMMotionManager *motionManager;
    CMMotionManager *motionManagerTrueNorth;
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
