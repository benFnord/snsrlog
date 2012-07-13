//
//  Accelerometer.h
//  snsrlog
//
//  Created by Benjamin Thiel on 07.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
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
