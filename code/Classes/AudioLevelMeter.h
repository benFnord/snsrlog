//
//  AudioLevelMeter.h
//  snsrlog
//
//  Created by Benjamin Thiel on 16.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveView.h"


@interface AudioLevelMeter : UIView <LiveSubView> {
    
    UIImageView *soundIcon;
    //a C array of the different image views for the respective level
    UIImageView **audioLevelImageViews;
    int lastLevel;
}

- (void)updateSoundLevel:(float)percentage;

@end
