//
//  Accelerometer.m
//  snsrlog
//
//  Created by Benjamin Thiel on 07.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Accelerometer.h"
#import "Gyroscope.h"
#import "Preferences.h"
#import "Labels.h"



@implementation Accelerometer

@synthesize isDummy;

static Accelerometer *sharedSingleton;

//singleton method is simple, due to the initialization being done in +(void)initialize
+(Accelerometer *)sharedInstance {
	
	return sharedSingleton;
}

#pragma mark -
#pragma mark initialization methods

//Is called by the runtime in a thread-safe manner exactly once, before the first use of the class.
//This makes it the ideal place to set up the singleton.
+ (void)initialize
{
	//is necessary, because +initialize may be called directly
    static BOOL initialized = NO;
    
	if(!initialized)
    {
        initialized = YES;
        sharedSingleton = [[Accelerometer alloc] init];
    }
}


-(id)init {
	
    self = [super init];
    
    if (self != nil) {
        
        motionManager = [[CMMotionManager alloc] init];
        queue = [[NSOperationQueue alloc] init]; //we are using our own queue, which comes with a separate thread
        
        //handle accelerometer updates in Gyroscope?
        isDummy = [motionManager isDeviceMotionAvailable];
        isAvailable = [motionManager isAccelerometerAvailable];
        
        motionManager.accelerometerUpdateInterval = 1.0 / 60;
        
        if (isDummy || !isAvailable) {
            
            [motionManager release];
            motionManager = nil;
        }
    }
	
	return self;
}

-(void)dealloc {
	if (motionManager) [motionManager release];
    [queue release];
	[super dealloc];
}

#pragma mark -
#pragma mark overriding methods inherited by AbstractSensor to allow this class to act as dummy, passing data to Gyroscope


-(BOOL)isAvailable {
    
    if(isDummy)
        return [[Gyroscope sharedInstance] isAvailable];
    else
        return isAvailable;
}

-(BOOL)isActive {
    
    if (isDummy) {
        return [[Gyroscope sharedInstance] isAccelerometerActive];
    } else {
        return isActive;
    }
}

-(void)addListener:(id<Listener>)listener {
    
    if (isDummy) [[Gyroscope sharedInstance] addAccelerometerListener:listener];
    
    //we call super here in either case, in order to preserve the auto-stopping behaviour (see shouldRestartWhenListenersAvailable in AbstractSensor)
    [super addListener:listener];
}

-(void)removeListener:(id<Listener>)listener {
    
    if (isDummy) [[Gyroscope sharedInstance] removeAccelerometerListener:listener];
    
    //we call super here in either case, in order to preserve the auto-stopping behaviour (see shouldRestartWhenListenersAvailable in AbstractSensor)
    [super removeListener:listener];
}

-(void)removeAllListeners {
    
    if (isDummy) [[Gyroscope sharedInstance] removeAllAccelerometerListeners];
    
    //we call super here in either case, in order to preserve the auto-stopping behaviour (see shouldRestartWhenListenersAvailable in AbstractSensor)
    [super removeAllListeners];
}


#pragma mark
#pragma mark sensor methods

-(void)setFrequency:(int)frequency {
    
    if (isDummy) {
        
        [Gyroscope sharedInstance].frequency = frequency;
        
    } else {
        
        if (frequency > 0) {
            
            motionManager.accelerometerUpdateInterval = 1.0 / frequency;
        }
    }
}

-(int)frequency {
    
    NSTimeInterval interval;
    
    if (isDummy) {
        
        return [Gyroscope sharedInstance].frequency;
        
    } else {
        
        if ((interval = motionManager.accelerometerUpdateInterval) > 0) {
            
            return 1.0 / interval;
            
        } else {
            
            return 0;
        }
    }
}

-(void)actuallyStart {
    
	if (isDummy) {
        
        [[Gyroscope sharedInstance] startAccelerometer];
        
    } else if (!isActive && isAvailable) {
        
        isActive = YES;
        skipCount = 0;

        NSLog(@"Accelerometer sampling frequency is %.1f Hz.", 1 / motionManager.accelerometerUpdateInterval);
        
        [motionManager startAccelerometerUpdatesToQueue:queue
                                            withHandler: ^(CMAccelerometerData *motion, NSError *error)
         {//begin handler
             if (!error && motion) {
                 
                 if (!timestampOffsetInitialized) {
                     
                     timestampOffsetFrom1970 = [self getTimestamp] - motion.timestamp;
                     timestampOffsetInitialized = YES;
                 }

                 NSTimeInterval timestamp = motion.timestamp + timestampOffsetFrom1970;
                 int label = [[Labels sharedInstance] currentLabel];
                 
                 double x = motion.acceleration.x;
                 double y = motion.acceleration.y;
                 double z = motion.acceleration.z;
                 
                 id<Listener> listener;
                 
                 /*
                  * The mutex allows adding and removing listeners while sensor is running.
                  * However we don't wait for the mutex in order to avoid blocking the thread.
                  *
                  * Reason: The NSOperationQueue provided in startDeviceMotionUpdatesToQueue:withHandler:
                  * seems to be spawning several thread to deliver the updates, (un)blocking these
                  * would be expensive. Setting the queue's maxConcurrentOperationCount to 1 on the
                  * other hand doesn't seem to work either, as the performance degrades horribly.
                  *
                  * Using the mainQueue is also not an option as it clogs up the main thread and 
                  * blocks the UI.
                  *
                  * We deliberately risk losing values by not waiting for the mutex, although
                  * this does not appear to be happening very often even at a rate of 100Hz.
                  */
                 if(!dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_NOW)) {
                     
                     for (listener in listeners) {
                         
                         [listener didReceiveAccelerometerValueWithX:x 
                                                                   Y:y
                                                                   Z:z
                                                           timestamp:timestamp
                                                               label:label
                                                           skipCount:skipCount];
                         
                     }
                     dispatch_semaphore_signal(listenersSemaphore);
                     
                 } else {
                     
                     //skip the value
                     skipCount++;
                 }
             }
         }//end handler
         ];
    }
	
}

-(void)actuallyStop {
    
    if (isDummy) {
        
        [[Gyroscope sharedInstance] stopAccelerometer];
        
    } else if (isActive && isAvailable) {
        
        [motionManager stopAccelerometerUpdates];
        isActive = NO;
        timestampOffsetInitialized = NO;
    }
}

@end
