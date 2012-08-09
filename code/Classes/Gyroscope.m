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
//  Gyroscope.m
//  snsrlog
//
//  Created by Benjamin Thiel on 11.03.11.
//

#import "Gyroscope.h"
#import "Labels.h"

/* If defined, this flag will make this class pull the device motion
 * with a NSTimer (which calls from the main thread), which is deemed
 * less efficient, but a workaround for a bug in CoreMotion.
 * Furthermore, this makes locking the listeners obsolete.
 * ATTENTION: This flag not only adds/removes code within methods,
 * but shares code _across_ two methods.
 */
//#define DEVICE_MOTION_POLLING


//anonymous category extending the class with "private" methods
@interface Gyroscope () 

-(void)startMotionManager;
-(void)stopMotionManager;

@end


@implementation Gyroscope

@synthesize isAccelerometerActive, frequency;

static Gyroscope *sharedSingleton;

+(Gyroscope *)sharedInstance {
    
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
        sharedSingleton = [[Gyroscope alloc] init];
    }
}


-(id)init {
    
    self = [super init];
    
    if (self != nil) {
        
        motionManager = [[CMMotionManager alloc] init];

        queue = [[NSOperationQueue alloc] init];
        accelerometerListeners = [[NSMutableSet alloc] initWithCapacity:3]; 
        
        timestampOffsetInitialized = NO;
        
        isMotionManagerActive = NO;
        
        //gyroscope available?
        if ((isAvailable = [motionManager isDeviceMotionAvailable])) {
            
            motionManager.deviceMotionUpdateInterval = 1.0 / 60;
            
        } else {

            [motionManager release];
            motionManager = nil;
        }
        
        pollingTimer = nil;
	}
    
	return self;
}


-(void)dealloc {
    [self stop];
	if (motionManager) [motionManager release];
    [queue release];
    [accelerometerListeners release];
	[super dealloc];
}

#pragma mark -
#pragma mark methods used by Accelerometer if it acts as a dummy


-(void)addAccelerometerListener:(id <Listener>)listener {
    
    //mutex to allow listener adding/removing while sensors are running
    //we are using Gyroscope's mutex here, as it is used in the callback
    dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_FOREVER);
        
        [accelerometerListeners addObject:listener];

	dispatch_semaphore_signal(listenersSemaphore);
}

-(void)removeAccelerometerListener:(id<Listener>)listener {
    
    dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_FOREVER);
        
        [accelerometerListeners removeObject:listener];
    
    dispatch_semaphore_signal(listenersSemaphore);
}

-(void)removeAllAccelerometerListeners {
    
    dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_FOREVER);
        
        [accelerometerListeners removeAllObjects];
    
    dispatch_semaphore_signal(listenersSemaphore);
}

-(void)startAccelerometer {
    
    if (isAvailable) {
        
        isAccelerometerActive = YES;
        if (!isActive) [self startMotionManager];
    }
    
    
}

-(void)stopAccelerometer {
    
    if (isAvailable) {
        
        isAccelerometerActive = NO;
        [self stopMotionManager];
    }
    
    
}

#pragma mark -
#pragma mark sensor methods


-(void)actuallyStart {
    
    if (isAvailable) {
         
        isActive = YES;
        if (!isAccelerometerActive) [self startMotionManager];
    }
}


-(void)actuallyStop {
    
    if (isAvailable) {
        
        isActive = NO;
        [self stopMotionManager]; 
    }
}

-(void)actuallyStopStart {
    [self actuallyStop];
    [self actuallyStart];
}


-(BOOL)isActive {
    
    return isAvailable && [motionManager isDeviceMotionActive];
}

-(void)setFrequency:(int)_frequency {
    
    if (_frequency > 0) {
        
        frequency = _frequency;

#ifndef DEVICE_MOTION_POLLING
        motionManager.deviceMotionUpdateInterval = 1.0 / frequency;
#else
        /*
         * We dispatch the restarting of the timer for later, as testing has
         * shown that - for reasons unknown - the app would stall if resuming
         * from background and this method being called due to changes in frequncy.
         */
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            if (self.isActive) {
                
                //restart the timer
                [pollingTimer invalidate];
                pollingTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / frequency)
                                                                target:self 
                                                              selector:@selector(captureDeviceMotion)
                                                              userInfo:nil
                                                               repeats:YES];
            }
        });
#endif
    }
}

-(int)frequency {
    
#ifndef DEVICE_MOTION_POLLING
    NSTimeInterval interval;
    
    if ((interval = motionManager.deviceMotionUpdateInterval) > 0) {
        
        return 1.0 / interval;
    
    } else {
        
        return 0;
    }
#else
    return frequency;
#endif
}

-(void)startMotionManager {
    
    //should at least one sensor (acc or gyro) be on?
    if (isAvailable && (isAccelerometerActive || isActive)) {
        
        if (!isMotionManagerActive) {//instead of buggy !([motionManager.isDeviceMotionActive])...
            
            isMotionManagerActive = YES;
            skipCount = 0;
#ifndef DEVICE_MOTION_POLLING
            NSLog(@"Device motion sampling frequency is %.1f Hz.", 1 / motionManager.deviceMotionUpdateInterval);
            [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical toQueue :queue
                                                           withHandler: ^(CMDeviceMotion *motion, NSError *error)
             {//begin handler
#else
            //let the motion manage sample at 100Hz, actual polling might be lower     
            motionManager.deviceMotionUpdateInterval = 1.0 / 100;
            
            [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
            
            [pollingTimer invalidate];
            pollingTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / frequency)
                                                                 target:self 
                                                               selector:@selector(captureDeviceMotion)
                                                               userInfo:nil
                                                                repeats:YES];
        }
    }
}

-(void)captureDeviceMotion {
                     
    CMDeviceMotion *motion = motionManager.deviceMotion;
    NSError *error = nil;
#endif

                 if (!error && motion) {
                     
                     if (!timestampOffsetInitialized) {
                         
                         timestampOffsetFrom1970 = [self getTimestamp] - motion.timestamp;
                         timestampOffsetInitialized = YES;
                     }
                     
                     NSTimeInterval timestamp = motion.timestamp + timestampOffsetFrom1970;
                     int label = [[Labels sharedInstance] currentLabel];
                     
#ifndef DEVICE_MOTION_POLLING                     
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
                     if (!dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_NOW)) {
                         
#endif
                         if (isActive) {
                             
                             CMAttitude *attitude = motion.attitude;
                             CMRotationRate rate = motion.rotationRate;
                             CMQuaternion quat = motion.attitude.quaternion;
                             
                             double x = rate.x;
                             double y = rate.y;
                             double z = rate.z;
                             
                             double roll = attitude.roll;
                             double pitch = attitude.pitch;
                             double yaw = attitude.yaw;
                             
                             id<Listener> listener;
                             for (listener in listeners) {
                                 
                                 [listener didReceiveGyroscopeValueWithX:x
                                                                       Y:y
                                                                       Z:z
                                                                    roll:roll
                                                                   pitch:pitch
                                                                     yaw:yaw 
                                                              quaternion:quat
                                                               timestamp:timestamp
                                                                   label:label
                                                               skipCount:skipCount];
                             }
                             
                         }
                         
                         if (isAccelerometerActive) {
                             
                             CMAcceleration accel = motion.userAcceleration;
                             CMAcceleration gravity = motion.gravity;
                             
                             double x = accel.x + gravity.x;
                             double y = accel.y + gravity.y;
                             double z = accel.z + gravity.z;
                             
                             id<Listener> listener;
                             for (listener in accelerometerListeners) {
                                 
                                 [listener didReceiveAccelerometerValueWithX:x 
                                                                           Y:y 
                                                                           Z:z 
                                                                   timestamp:timestamp
                                                                       label:label
                                                                   skipCount:skipCount];
                             }
                         }
#ifndef DEVICE_MOTION_POLLING
                         dispatch_semaphore_signal(listenersSemaphore);
                     } else {
                         
                         //skip the value
                         skipCount++;
                     }
                 }
             }//end handler
             ];
        }
#endif
    }
}

-(void)stopMotionManager {
    
    //stop only if accelerometer AND gyroscope should be off
    if (isAvailable && !isAccelerometerActive && !isActive) {
        
#ifdef DEVICE_MOTION_POLLING
        [pollingTimer invalidate];
        pollingTimer = nil;
#endif
        
        [motionManager stopDeviceMotionUpdates];
        
        isMotionManagerActive = NO;
        timestampOffsetInitialized = NO;
    }
    
}


@end
