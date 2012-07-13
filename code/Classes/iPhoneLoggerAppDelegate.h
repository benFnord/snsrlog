//
//  iPhoneLoggerAppDelegate.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 06.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveViewController.h"
#import "RecordingViewController.h"
#import "ArchiveViewController.h"
#import "StreamingMainViewController.h"
#import "MBProgressHUD.h"

@interface iPhoneLoggerAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    
    UITabBarController *myTabBarController;
    LiveViewController *liveViewController;
    RecordingViewController *recordingViewController;
    ArchiveViewController *archiveViewController;
    StreamingMainViewController *streamingViewController;
    
    //used to show the status of the proximity sensor
    MBProgressHUD *proximityHUD;
    UIImageView *lockView;

    BOOL isProximitySensingAvailable;
    //counting the requests to enableProximitySensing: and preventAutoLock:
    int proximitySensingCounter;
    int preventAutoLockCounter;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

-(void)preferencesChanged:(NSNotification *)notification;
-(void)audioInputAvailabilityChanged:(NSNotification *)notification;

//calls to these method need to be balanced (YES, followed by NO) as the requests are counted
-(void)enableProximitySensing:(BOOL)enable;
-(void)preventAutoLock:(BOOL)enable;

@end

