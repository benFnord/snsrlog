//
//  StreamingLiveFlipsideViewController.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 15.07.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StreamingLiveViewController.h"


@interface StreamingLiveFlipsideViewController : UITableViewController {
    
    NSArray *switches;
    NSArray *displayNames;
    
    StreamingLiveViewController *liveView;
}

- (id)initWithStyle:(UITableViewStyle)style streamingLiveViewController:(StreamingLiveViewController *)liveViewController;

-(void)doneButtonPressed:(UIButton *)sender;

-(void)showGPS:(UISwitch *)sender;
-(void)showAccelerometer:(UISwitch *)sender;
-(void)showCompass:(UISwitch *)sender;

@end
