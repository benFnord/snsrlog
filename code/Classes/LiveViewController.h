//
//  LiveViewController.h
//  snsrlog
//
//  Created by Benjamin Thiel on 12.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Listener.h"
#import "LiveView.h"
#import "AudioLevelMeter.h"
#import "CompassView.h"
#import "GPSView.h"
#import "AudioInput.h"
#import "WiFiView.h"
#import "AccelerometerAndGyroscopeView.h"


@interface LiveViewController : UIViewController <Listener> {
    
    LiveView *compositeView;
    AccelerometerAndGyroscopeView *accAndGyroView;
    AudioLevelMeter *levelMeter;
    CompassView *compassView;
    GPSView *gpsView;
    WiFiView *wifiView;
    
    //weak reference to the AudioInput singleton, as it is needed frequently
    AudioInput *audioInput;
    
    BOOL showAccelerometer, showGyroscope, showGPS, showAudio, showCompass, showWifi;
    
    //used to determine whether LiveViewController should add itself as listener to the sensors
    BOOL viewIsOnScreen;
    
    int accelerometerSampleRateCounter, gyroscopeSampleRateCounter, skipCount;
}

@property (nonatomic, readwrite) BOOL showAccelerometer, showGyroscope, showGPS, showAudio, showCompass, showWifi;


@end
