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
//  LiveViewController.h
//  snsrlog
//
//  Created by Benjamin Thiel on 12.05.11.
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