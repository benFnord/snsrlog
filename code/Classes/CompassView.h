//
//  CompassView.h
//  snsrlog
//
//  Created by Benjamin Thiel on 16.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveView.h"
#import "GraphView.h"

@interface CompassView : UIView <LiveSubView> {
    
    UILabel *values;
    UIImageView *compassIcon;
    
    double lastHeading;
    
    GraphView *compassGraph;
    
    PortionOfView currentPortion;
}

- (void)updateCompassWithMagneticHeading:(double)magneticH trueHeading:(double)trueH accuracy:(double)acc x:(double)x y:(double)y z:(double)z;

-(void)userSwipedToTheLeft:(UISwipeGestureRecognizer *)sender;
-(void)userSwipedToTheRight:(UISwipeGestureRecognizer *)sender;

-(void)startDrawing;
-(void)stopDrawing;

@end
