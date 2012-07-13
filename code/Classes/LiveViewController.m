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
//  LiveViewController.m
//  snsrlog
//
//  Created by Benjamin Thiel on 12.05.11.
//

#import "LiveViewController.h"
#import "CompassView.h"
#import "GPSView.h"
#import "AudioInput.h"
#import "CompassAndGPS.h"
#import "Accelerometer.h"
#import "Preferences.h"
#import "Gyroscope.h"

#ifndef APP_STORE
    #import "WiFiScanner.h"
#endif

#pragma mark private methods
@interface LiveViewController ()

@property (nonatomic, retain) CADisplayLink *audioLevelUpdater;
@property (nonatomic, retain) LiveView *compositeView;
@property (nonatomic, retain) AccelerometerAndGyroscopeView *accAndGyroView;
@property (nonatomic, retain) AudioLevelMeter *levelMeter;
@property (nonatomic, retain) CompassView *compassView;
@property (nonatomic, retain) GPSView *gpsView;
@property (nonatomic, retain) WiFiView *wifiView;

@property (nonatomic, retain) NSTimer *sampleRateMeter;

-(void)measureAccAndGyroSampleRate;
-(void)startSampleRateMeasurement;
-(void)stopSampleRateMeasurement;

-(void)updateAudioLevels;
-(void)startAudioUpdates;
-(void)stopAudioUpdates;

-(void)wireMeUpAccordingToPreferences;

-(void)releaseViews;

@end


@implementation LiveViewController

@synthesize showAccelerometer, showGyroscope, showGPS, showAudio, showCompass, showWifi;
@synthesize audioLevelUpdater, sampleRateMeter;
@synthesize compositeView, accAndGyroView, levelMeter, compassView, gpsView, wifiView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
       
        // Custom initialization
        showWifi = NO;
        showAccelerometer = NO;
        showAudio = NO;
        showCompass = NO;
        showGPS = NO;
        showGyroscope = NO;
        
        self.audioLevelUpdater = nil;
        audioInput = nil;
        
        viewIsOnScreen = NO;
    }
    return self;
}

- (void)dealloc
{
    [self stopSampleRateMeasurement];
    [self releaseViews];
    [super dealloc];
}

-(void) releaseViews {
    
    self.compositeView = nil;
    self.accAndGyroView = nil;
    self.compassView = nil;
    self.gpsView = nil;
    self.wifiView = nil;
    
    [self stopAudioUpdates];
    self.levelMeter = nil;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    //try to get the fullscreen, will be shrunk by tab bar and status bar anyway.
    CGRect fullscreen = CGRectMake(0.0, 0.0, 480, 320);
    compositeView = [[LiveView alloc] initWithFrame:fullscreen];
    
    //create the subviews. all views have (0, 0) as origin, as the layout is handled in LiveView's layoutSubviews
    CGRect accelerometerFrame = CGRectMake(0, 0, [AccelerometerAndGyroscopeView preferredSize].width, [AccelerometerAndGyroscopeView preferredSize].height);
    accAndGyroView = [[AccelerometerAndGyroscopeView alloc] initWithFrame:accelerometerFrame];
    accAndGyroView.tag = AccelerometerViewTag;
    
    CGRect compassFrame = CGRectMake(0, 0, [CompassView preferredSize].width, [CompassView preferredSize].height);
    compassView = [[CompassView alloc] initWithFrame:compassFrame];
    compassView.tag = CompassViewTag;
    
    CGRect gpsFrame = CGRectMake(0, 0, [GPSView preferredSize].width, [GPSView preferredSize].height);
    gpsView = [[GPSView alloc] initWithFrame:gpsFrame];
    gpsView.tag = GPSViewTag;
    
    CGRect audioLevelFrame = CGRectMake(0, 0, [AudioLevelMeter preferredSize].width, [AudioLevelMeter preferredSize].height);
    levelMeter = [[AudioLevelMeter alloc] initWithFrame:audioLevelFrame];
    levelMeter.tag = AudioLevelMeterViewTag;
    
    CGRect wifiFrame = CGRectMake(0, 0, [WiFiView preferredSize].width, [WiFiView preferredSize].height);
    wifiView = [[WiFiView alloc] initWithFrame:wifiFrame];
    wifiView.tag = WifiViewTag;

    //adding the subviews to compositeView happens in the setShow... methods, hence
    //we need to call them again in case of recovering from an unloaded view due to a memory warning
    self.showGPS = showGPS;
    self.showWifi = showWifi;
    self.showAccelerometer = showAccelerometer;
    self.showAudio = showAudio;
    self.showCompass = showCompass;
    self.showGyroscope = showGyroscope;
    
    self.view = compositeView;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
/*- (void)viewDidLoad
{
    [super viewDidLoad];
}*/


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self releaseViews];
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque
                                                animated:YES];
}

-(void)viewDidAppear:(BOOL)animated {
    
    viewIsOnScreen = YES;
    [super viewDidAppear:animated];
    
    if (showAccelerometer || showGyroscope) {
        
        [accAndGyroView startDrawing];
        [self startSampleRateMeasurement];
    }
    
    if (showCompass) {
        
        [compassView startDrawing];
    }
    
    //schedule the starting of sensors, since calling the method directly would make the view appear after its finished.
    //-> perceptable lag
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        [self wireMeUpAccordingToPreferences]; 
    });
}

-(void)viewDidDisappear:(BOOL)animated {
    
    viewIsOnScreen = NO;
    
    [super viewDidDisappear:animated];
    
    [accAndGyroView stopDrawing];
    [compassView stopDrawing];
    
    [self stopSampleRateMeasurement];
    
    //since the view only disappears when this method returns,
    //we schedule the potential sensor shutdown for later
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        //we don't want any new data and we should not want to, since the views might get deallocated by a memory warning
        if (showAccelerometer) [[Accelerometer sharedInstance] removeListener:self];
        if (showGyroscope) [[Gyroscope sharedInstance] removeListener:self];
        if (showGPS || showCompass) [[CompassAndGPS sharedInstance] removeListener:self];
        if (showAudio) [self stopAudioUpdates];
#ifndef APP_STORE
        if (showWifi) [[WiFiScanner sharedInstance] removeListener:self];
#endif
    });
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)wireMeUpAccordingToPreferences {
    
    //we want to receive data again
    if (showAccelerometer) [[Accelerometer sharedInstance] addListener:self];
    if (showGyroscope) [[Gyroscope sharedInstance] addListener:self];
    if (showGPS || showCompass) [[CompassAndGPS sharedInstance] addListener:self];
    if (showAudio) [self startAudioUpdates]; 
#ifndef APP_STORE
    if (showWifi) [[WiFiScanner sharedInstance] addListener:self];
#endif
}

#pragma mark -
#pragma mark helper methods for the audio level meter

//fetches the current audio level value from AudioInput and updates the view
- (void)updateAudioLevels {
    
    Float32 level = 0;
    Float32 peakLevels = 0;
    [audioInput getAudioLevels:&level peakLevels:&peakLevels];
    [levelMeter updateSoundLevel:level];
}

-(void)startAudioUpdates {
    
    audioInput = [AudioInput sharedInstance];
    [audioInput setLevelMeteringEnabled:YES];
    [audioInput addListener:self];
    
    [self.audioLevelUpdater invalidate];
    self.audioLevelUpdater = [CADisplayLink displayLinkWithTarget:self
                                                         selector:@selector(updateAudioLevels)];
	[self.audioLevelUpdater setFrameInterval:3];//fire for every n-th frame, 60Hz/3 = 20Hz
	[self.audioLevelUpdater addToRunLoop:[NSRunLoop mainRunLoop]
                                 forMode:NSDefaultRunLoopMode];
}

-(void)stopAudioUpdates {
    
    [audioInput removeListener:self];
    [self.audioLevelUpdater invalidate];
    self.audioLevelUpdater = nil;
    
    [audioInput setLevelMeteringEnabled:NO];
}


#pragma mark -
#pragma mark overriding the synthesized setters for showing/hiding views

-(void)setShowGPS:(BOOL)shouldShowGPS {
    
    if (shouldShowGPS) {
        
        [compositeView addSubview:gpsView];
        if (viewIsOnScreen) [[CompassAndGPS sharedInstance] addListener:self];
        
    } else {
        
        //check whether the compass view would like to have updates (CompassAndGPS only offers one listener for both)
        if (!showCompass) [[CompassAndGPS sharedInstance] removeListener:self];
        [gpsView removeFromSuperview];
        
    }
    showGPS = shouldShowGPS;
}

-(void)setShowCompass:(BOOL)shouldShowCompass {
    
    if (shouldShowCompass) {
        
        [compositeView addSubview:compassView];
        if (viewIsOnScreen) [[CompassAndGPS sharedInstance] addListener:self];
        
    } else {
        
        //check whether the GPS view would like to have updates (CompassAndGPS only offers one listener for both)
        if (!showGPS) [[CompassAndGPS sharedInstance] removeListener:self];
        [compassView removeFromSuperview];
        
    }
    showCompass = shouldShowCompass;
}

-(void)setShowAccelerometer:(BOOL)shouldShowAccelerometer {
    
    if (shouldShowAccelerometer) {
        
        [compositeView addSubview:accAndGyroView];
        if (viewIsOnScreen) {
            
            [[Accelerometer sharedInstance] addListener:self];
            [accAndGyroView startDrawing];
            [self startSampleRateMeasurement];
        }
        
    } else {
        
        [[Accelerometer sharedInstance] removeListener:self];
        if (!showGyroscope) {
            
            [accAndGyroView stopDrawing];
            [self stopSampleRateMeasurement];
            [accAndGyroView removeFromSuperview];
        }
        
    }
    showAccelerometer = shouldShowAccelerometer;
    
    accAndGyroView.showAccelerometer = showAccelerometer;
}

-(void)setShowGyroscope:(BOOL)shouldShowGyroscope {
    
    if (shouldShowGyroscope) {
        
        [compositeView addSubview:accAndGyroView];
        if (viewIsOnScreen) {
            
            [[Gyroscope sharedInstance] addListener:self];
            [self startSampleRateMeasurement];
            [accAndGyroView startDrawing];
        }
        
    } else {
        
        [[Gyroscope sharedInstance] removeListener:self];
        if (!showAccelerometer) {
            
            [accAndGyroView stopDrawing];
            [self stopSampleRateMeasurement];
            [accAndGyroView removeFromSuperview];
        }
        
    }
    showGyroscope = shouldShowGyroscope;
    
    accAndGyroView.showGyroscope = showGyroscope;
}

-(void)setShowAudio:(BOOL)shouldShowAudio {
    
    if (shouldShowAudio) {
        
        [compositeView addSubview:levelMeter];
        if (viewIsOnScreen) [self startAudioUpdates];
        
    } else {
        
        [self stopAudioUpdates];
        [levelMeter removeFromSuperview];
        
    }
    showAudio = shouldShowAudio;
    
}
#ifndef APP_STORE
-(void)setShowWifi:(BOOL)shouldShowWifi {
    
    if (shouldShowWifi) {
        
        [compositeView addSubview:wifiView];
        if (viewIsOnScreen) [[WiFiScanner sharedInstance] addListener:self];
        
    } else {
        
        [[WiFiScanner sharedInstance] removeListener:self];
        [wifiView removeFromSuperview];
        
    }
    showWifi = shouldShowWifi;
}
#endif

//MARK: - sample rate measurement of accelerometer and gyroscope
-(void)startSampleRateMeasurement {
    
    [self stopSampleRateMeasurement];
    
    accelerometerSampleRateCounter = 0;
    gyroscopeSampleRateCounter = 0;
    self.sampleRateMeter = [NSTimer scheduledTimerWithTimeInterval:1
                                                            target:self
                                                          selector:@selector(measureAccAndGyroSampleRate)
                                                          userInfo:nil
                                                           repeats:YES];
}

-(void)stopSampleRateMeasurement {
    
    [self.sampleRateMeter invalidate];
    self.sampleRateMeter = nil;
}

-(void)measureAccAndGyroSampleRate {

    if (viewIsOnScreen) {
        
        if (showGyroscope) {
            
            accAndGyroView.gyroscopeStatusString = [NSString stringWithFormat:@"actual sampling rate: %d Hz, skipped values: %d",
                                                    gyroscopeSampleRateCounter, skipCount];
        }
        
        if (showAccelerometer) {
            
            accAndGyroView.accelerometerStatusString = [NSString stringWithFormat:@"actual sampling rate: %d Hz, skipped values: %d",
                                                        accelerometerSampleRateCounter, skipCount];
        }
    }
    
    accelerometerSampleRateCounter = 0;
    gyroscopeSampleRateCounter = 0;
}


#pragma mark -
#pragma mark Listener Protocol
-(void)didReceiveAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z timestamp:(NSTimeInterval)timestamp label:(int)label skipCount:(NSUInteger)skippedCount {
    
    if (showAccelerometer && viewIsOnScreen) {
        
        [accAndGyroView didReceiveAccelerometerValueWithX:x
                                                        Y:y
                                                        Z:z];
    }
    accelerometerSampleRateCounter++;
    skipCount = skippedCount;
}

-(void)didReceiveGyroscopeValueWithX:(double)x Y:(double)y Z:(double)z roll:(double)roll pitch:(double)pitch yaw:(double)yaw quaternion:(CMQuaternion)quaternion timestamp:(NSTimeInterval)timestamp label:(int)label skipCount:(NSUInteger)skippedCount {
    
    if (showGyroscope && viewIsOnScreen) {
        
        [accAndGyroView didReceiveGyroscopeValueWithX:x
                                                    Y:y
                                                    Z:z
                                                 roll:roll
                                                pitch:pitch
                                                  yaw:yaw];
    }
    gyroscopeSampleRateCounter++;
    skipCount = skippedCount;
}

-(void)didReceiveChangeToLabel:(int)label timestamp:(NSTimeInterval)timestamp {
    
}

-(void)didReceiveGPSvalueWithLongitude:(double)longitude latitude:(double)latitude altitude:(double)altitude speed:(double)speed course:(double)course horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy timestamp:(NSTimeInterval)timestamp label:(int)label {
    
    if (showGPS && viewIsOnScreen) {
        
        [gpsView updateGpsLong:longitude
                           Lat:latitude
                           Alt:altitude
                         Speed:speed
                        Course:course
                          HAcc:horizontalAccuracy
                          VAcc:verticalAccuracy
                     timestamp:timestamp];
    }
    
}

-(void)didReceiveCompassValueWithMagneticHeading:(double)magneticHeading trueHeading:(double)trueHeading headingAccuracy:(double)headingAccuracy X:(double)x Y:(double)y Z:(double)z timestamp:(NSTimeInterval)timestamp label:(int)label {
    
    if (showCompass && viewIsOnScreen) {
        
        [compassView updateCompassWithMagneticHeading:magneticHeading
                                          trueHeading:trueHeading
                                             accuracy:headingAccuracy
                                                    x:x
                                                    y:y
                                                    z:z];
    }
}

-(void)didReceiveWifiList:(NSArray *)list scanBegan:(NSTimeInterval)beginning scanEnded:(NSTimeInterval)end label:(int)label {
#ifndef APP_STORE    
    if (showWifi && viewIsOnScreen) {
        //we're coming from a different thread and UIKit requires calls to be made from the main thread
        [wifiView performSelectorOnMainThread:@selector(updateWifiList:) withObject:list waitUntilDone:YES];
    }
#endif
}

- (void) didReceiveNewAudioBuffer:(AudioQueueBufferRef)buffer inQueue:(AudioQueueRef)queue  withAudioFormat:(AudioStreamBasicDescription)format withNumberOfPackets:(UInt32)number withPacketDescription:(const AudioStreamPacketDescription *)description atTime:(NSTimeInterval)timestamp {
    
    //we don't handle raw audio data
}

@end
