//
//  RecordingViewController.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 24.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BTFancyButton.h"
#import "Labels.h"
#import "AddLabelPopupViewController.h"
#import "LockScreenViewController.h"
#import "FileWriter.h"

@interface RecordingViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, AddLabelDelegate, LockScreenDelegate>
{
    //weak reference
    Labels *labels;
    int lastLabel;
    
    FileWriter *fileWriter;
}

@property (nonatomic, retain) IBOutlet UITableView *myTableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *removeLabelButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *addLabelButton;
@property (nonatomic, retain) IBOutlet BTFancyButton *recordingButton;
@property (nonatomic, retain) IBOutlet BTFancyButton *lockButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinningWheel;

-(IBAction)recordingPressed:(BTFancyButton *)sender;
-(IBAction)lockScreen:(UIButton *)sender;
-(IBAction)removeLabels:(UIBarButtonItem *)sender;
-(IBAction)addLabel:(UIBarButtonItem *)sender;

//used to listen for label changes
-(void)didReceiveChangeToLabel:(int)label timestamp:(NSTimeInterval)timestamp;

-(void)preferencesChanged:(NSNotification *)notification;

//AppDelegate would like to be able to stop recording when the app terminates
-(void)stopRecording;

@end
