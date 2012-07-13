//
//  WiFiScanner.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 22.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AbstractSensor.h"


@interface WiFiScanner : AbstractSensor {
	
	BOOL isScanning;

	NSTimer *autoscanTimer;
    
    //function pointers to assign library functions to
    void *libHandle;
	int (*open)(void *);
	int (*bind)(void *, NSString *);
	int (*close)(void *);
	int (*scan)(void *, NSArray **, void *);
    
    //parameters to be handed to scan(...) library call
    NSDictionary *parameters;
}

@property(nonatomic,readonly) BOOL isScanning;

//singleton
+ (WiFiScanner *)sharedInstance;

- (void)actuallyStart;
- (void)actuallyStop;

@end
