//
//  CompassAndGPS.h
//  snsrlog
//
//  Created by Benjamin Thiel on 17.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "AbstractSensor.h"


@interface CompassAndGPS : AbstractSensor <CLLocationManagerDelegate> {
    
    CLLocationManager *locationManager;
	
	BOOL isGPSactive;
	BOOL isCompassActive;
    
    BOOL shouldRestartCompassIfListenersAvailable; //see AbstractSensor's shouldRestartIfListenersAvailable
    BOOL shouldRestartGPSIfListenersAvailable;
}

@property(nonatomic, readonly) BOOL isGPSactive;
@property(nonatomic, readonly) BOOL isCompassActive;

+ (CompassAndGPS *) sharedInstance;


//starts both
- (void) actuallyStart;

//stops both
- (void) actuallyStop;

- (void) startGPS;
- (void) stopGPS;

- (void) startCompass;
- (void) stopCompass;

@end
