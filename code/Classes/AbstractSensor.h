//
//  AbstractSensor.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 06.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Listener.h"


@interface AbstractSensor : NSObject {
	
    /* Using NSMutableSet is a naive implementation for managing the listeners.
     * Performance could be gained by fetching the methods addresses from the runtime
     * and making a C-function call instead of Objective-C messaging.
     */
	NSMutableSet *listeners;
    //a mutex to make sure "listeners" isn't changed while being enumerated
    dispatch_semaphore_t listenersSemaphore;
    
	NSDate *beginningOfEpoch;
    BOOL isAvailable;
    BOOL isActive;

    //describes: 1. if the sensor has been stopped because there are no listeners
    //           2. why actuallyStart/actuallyStop are called
    BOOL shouldRestartIfListenersAvailable;
}

@property(nonatomic,readonly) BOOL isActive;
@property(nonatomic,readonly) BOOL isAvailable;

-(void)addListener:(id<Listener>)listener;
-(void)removeListener:(id<Listener>)listener;
-(void)removeAllListeners;

-(NSTimeInterval)getTimestamp;

//to be implemented by subclasses:
//raises an exception if called
- (void) actuallyStart;
- (void) actuallyStop;

//to be called by the users of sensors
-(void)start;
-(void)stop;

@end
