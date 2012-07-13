//
//  LiveView.h
//  snsrlog
//
//  Created by Benjamin Thiel on 16.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

//tags to identify the subviews by; needed in layoutSubviews.
//ATTENTION: The order of this enum specifies the vertical
//order of the respective subview (top to bottom).
typedef enum {
    
    AccelerometerViewTag,
    GPSViewTag,
    CompassViewTag,
    AudioLevelMeterViewTag,
    WifiViewTag,
    GyroscopeViewTag,
    
    //only used in StreamingLiveViewController:
    LabelTableViewTag,
    FlipSideViewButtonTag
    
} LiveViewTags;

typedef enum {
    
    leftSide,
    center,
    rightSide
    
} PortionOfView;

#define kLiveSubviewNumberOfFingersForSwipeGesture 1
#define kLiveViewLayoutingAnimationDuration 0.7

@protocol LiveSubView <NSObject>

//Creation of views is simplified if the views know the space they take up
+ (CGSize) preferredSize;

@end


@interface LiveView : UIView {
    
}

@end

