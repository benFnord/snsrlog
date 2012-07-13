//
//  StreamingLiveViewController.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 06.07.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PacketEncoderDecoder.h"

@interface StreamingLiveViewController : UIViewController <PacketEncoderDecoderDataReceiveDelegate, UITableViewDataSource, UITableViewDelegate> {
    
    BOOL showAccelerometer, showGPS, showCompass;
    
     //used to add the subviews lazily (=upon reception of the respective data)
    BOOL isAccelerometerViewOnScreen, isGPSViewOnScreen, isCompassViewOnScreen;
    
    int lastLabel; //the position to remove the checkmark from on label change
}

@property (nonatomic, readwrite) BOOL showAccelerometer, showGPS, showCompass;

-(void)infoButtonPressed:(UIButton *)sender;

@end
