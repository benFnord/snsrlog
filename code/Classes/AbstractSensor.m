//
//  AbstractSensor.m
//  snsrlog
//
//  Created by Benjamin Thiel on 06.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AbstractSensor.h"


@implementation AbstractSensor

@synthesize isActive;
@synthesize isAvailable;

-(id)init {
	
    self = [super init];
	
    if (self != nil) {
        
        listeners = [[NSMutableSet alloc] initWithCapacity:3];
        listenersSemaphore = dispatch_semaphore_create(1);
        
        beginningOfEpoch = [[NSDate alloc] initWithTimeIntervalSince1970:0.0];
        isActive = NO;
        isAvailable = NO;
        shouldRestartIfListenersAvailable = NO;
    }
    
	return self;
}

-(void)dealloc {
    
	[listeners release];
	[beginningOfEpoch release];
    dispatch_release(listenersSemaphore);
	[super dealloc];
}

-(void)addListener:(id <Listener>)listener {
    
    /*
     * Perform the operation now if the call comes from the main thread,
     * schedule it there otherwise.
     * This allows sensor subclasses working on the main thread to ommit using the listenersSemaphore.
     */
    if ([NSThread isMainThread]) {
        
        //mutex to allow listener adding/removing while sensors are running
        dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_FOREVER);
        
            [listeners addObject:listener];
            NSUInteger listenerCount = [listeners count];
    	
        dispatch_semaphore_signal(listenersSemaphore);
        
        
        if (shouldRestartIfListenersAvailable && (listenerCount > 0)) {
            
            [self actuallyStart];
            shouldRestartIfListenersAvailable = NO;
            NSLog(@"(Re)started %@ because %@ has been added.", NSStringFromClass([self class]), NSStringFromClass([(NSObject *)listener class]));
        }
    
    } else {
        
        //block the calling thread and call from the main thread
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            
            [self addListener:listener];
        });
    }
}

-(void)removeListener:(id<Listener>)listener {
    
    /*
     * Perform the operation now if the call comes from the main thread,
     * schedule it there otherwise.
     * This allows sensor subclasses working on the main thread to ommit using the listenersSemaphore.
     */
    if ([NSThread isMainThread]) {
        
        dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_FOREVER);
        
            [listeners removeObject:listener];
            NSUInteger listenerCount = [listeners count];
        
        dispatch_semaphore_signal(listenersSemaphore);
        
        
        //we use the inActive property here, allowing subclasses to override it
        if (listenerCount == 0 && self.isActive) {
            
            shouldRestartIfListenersAvailable = YES;
            [self actuallyStop];
            NSLog(@"Stopped %@ because nobody is listening.", NSStringFromClass([self class]));
        }   
    
    } else {
        
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            
            [self removeListener:listener];
        });
    }
}

-(void)removeAllListeners {
    
    /*
     * Perform the operation now if the call comes from the main thread,
     * schedule it there otherwise.
     * This allows sensor subclasses working on the main thread to ommit using the listenersSemaphore.
     */
    if ([NSThread isMainThread]) {
        
        dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_FOREVER);
        
            [listeners removeAllObjects];
        
        dispatch_semaphore_signal(listenersSemaphore);
        
        //we use the property here, allowing subclasses to override it
        if (self.isActive) {
            
            shouldRestartIfListenersAvailable = YES;
            [self actuallyStop];
            NSLog(@"Stopped %@ because nobody is listening.", NSStringFromClass([self class]));
        }
    
    } else {
        
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            
            [self removeAllListeners];
        });
    }
}


-(NSTimeInterval)getTimestamp {
	
	NSTimeInterval timestamp = -[beginningOfEpoch timeIntervalSinceNow];
	return timestamp;
}


-(void)start {
    
    dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_FOREVER);
        
        NSUInteger listenerCount = [listeners count];
    
    dispatch_semaphore_signal(listenersSemaphore);
    

        if (listenerCount > 0) {
            
            shouldRestartIfListenersAvailable = NO;
            [self actuallyStart];
            
        } else {
            
            shouldRestartIfListenersAvailable = YES;
        }
}

-(void)stop {
    
    shouldRestartIfListenersAvailable = NO;
    [self actuallyStop];
}

//to be implemented by subclasses

- (void)actuallyStart {
    
    [NSException raise:NSInternalInconsistencyException 
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

- (void)actuallyStop {
    
    [NSException raise:NSInternalInconsistencyException 
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

@end
