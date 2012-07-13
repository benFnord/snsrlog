//
//  WiFiView.h
//  snsrlog
//
//  Created by Benjamin Thiel on 20.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveView.h"


@interface WiFiView : UIView <LiveSubView> {
    
    UITextView *textView;
    UIImageView *wifiIcon;
    
    //used for automatic scrolling
    NSMutableArray *entryRanges;
    NSTimer *autoScrollTimer;
    int currentScrollPositon;
}

-(void)updateWifiList:(NSArray *)list;

@end
