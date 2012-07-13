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
//  WiFiScanner.m
//  snsrlog
//
//  Created by Benjamin Thiel on 22.03.11.
//

#import "WiFiScanner.h"
#import <dlfcn.h>
#import "Labels.h"
#import "Preferences.h"

//anonymous category extending the class by private methods and variables
@interface WiFiScanner ()

- (void)scan;
- (void)waitForNewScan:(id)param;

@end


@implementation WiFiScanner

@synthesize isScanning;

static WiFiScanner *sharedSingleton;

+(WiFiScanner *)sharedInstance {
    
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
        sharedSingleton = [[WiFiScanner alloc] init];
    }
}

- (id) init {
	
    self = [super init];
	
    if (self != nil) {
        
        //reverse engineered "documentation" of arguments can be found at: https://code.google.com/p/iphone-wireless/wiki/Apple80211Scan
        parameters = [[NSDictionary alloc] initWithObjectsAndKeys:
                      
                      //specifies whether the function should discard multiple BSSIDs for the same network name
                      [NSNumber numberWithBool:NO], @"SCAN_MERGE",
                      
                      nil];
        
        //determine the major OS version
        NSString *fullOSVersion = [[UIDevice currentDevice] systemVersion];
        NSString *majorVersion = [[fullOSVersion componentsSeparatedByString:@"."] objectAtIndex:0];
        
        //trying to get the library handle
        if ([majorVersion intValue] <= 4) {
            
            //prior to iOS5 the following worked flawlessly:
            libHandle = dlopen("/System/Library/SystemConfiguration/WiFiManager.bundle/WiFiManager", RTLD_LAZY);
            
        } else {
            
            /*
             * With iOS5, the library seems to have moved, but the scan function always returns NULL
             * the reason seems to be the sandboxing, since every call yields to a "deny system socket" in the console
             * http://code.google.com/p/iphone-wireless/issues/detail?id=45 discusses the problem, no solution yet. (last visit on October 26th, 2011)
             */
            libHandle = dlopen("/System/Library/SystemConfiguration/IPConfiguration.bundle/IPConfiguration", RTLD_LAZY);
        }

        //assign the libray function addresses to local variables
		open = dlsym(libHandle, "Apple80211Open");
		bind = dlsym(libHandle, "Apple80211BindToInterface");
		close = dlsym(libHandle, "Apple80211Close");
		scan = dlsym(libHandle, "Apple80211Scan");
		
        const char *error = dlerror();
        
        if (error) {
            
            NSLog(@"Loading of WiFi library failed! Reason: %s", error);
            isAvailable = NO;
            
        } else {
            
            isAvailable = YES;
            open(&libHandle);
            bind(libHandle, @"en0");
        }
        
        
        isActive = NO;
        autoscanTimer = nil;
	}
    
	return self;
}

-(void)dealloc {
    
    [self actuallyStop];
    
    if (isAvailable) {
        
        close(libHandle);
    }
    
    //unloading the library
    //always fails, I don't know why :(
    /*if (dlclose(libHandle)) {
        
            NSLog(@"Unloading of WiFi library failed! Reason: %s", dlerror());
    }  */   

    if (parameters) [parameters release];
    
    [super dealloc];
    
}

#pragma mark -
#pragma mark scanning related methods

- (void)actuallyStart {
	
    if (isAvailable && !isActive) {
        
        isActive = YES;
        [self scan];
        autoscanTimer = [NSTimer scheduledTimerWithTimeInterval: [[NSUserDefaults standardUserDefaults] integerForKey:kWifiScanInterval] //seconds
                                                         target: self
                                                       selector: @selector (waitForNewScan:)
                                                       userInfo: nil
                                                        repeats: YES];       
    }
}


- (void)actuallyStop {
    
    if (isAvailable && isActive) {
        
     	[autoscanTimer invalidate];
        isActive = NO;
    }
}

//called periodically by the timer
- (void)waitForNewScan:(id)param {
	
    // quit in case of an ongoing scan
    if (!isScanning) {

		[NSThread detachNewThreadSelector:@selector(scan) toTarget:self withObject:nil];
	}
}

//launched in a new thread
- (void)scan {
    
    isScanning = YES;
    
    //we are not in the main thread -> create an NSAutoreleasePool
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	NSArray *scan_networks = nil;
	
	// start scanning
	
	NSTimeInterval timeOfStart = [self getTimestamp];
    
	scan(libHandle, &scan_networks, parameters);
	
    NSTimeInterval timeOfFinish = [self getTimestamp];
    
    int label = [[Labels sharedInstance] currentLabel];
	
    
    //mutex allows adding/removing of listeners while being active
    dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_FOREVER);
    
        for (id<Listener> listener in listeners) {
            
            [listener didReceiveWifiList:scan_networks 
                               scanBegan:timeOfStart 
                               scanEnded:timeOfFinish 
                                   label:label];
        }
    dispatch_semaphore_signal(listenersSemaphore);

	isScanning = NO;
    
    //don't forget to flush!
	[pool drain];
}

@end
