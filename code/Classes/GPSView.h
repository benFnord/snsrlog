//
//  GPSView.h
//  snsrlog
//
//  Created by Benjamin Thiel on 16.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveView.h"
#import "MapKit/MKMapView.h"


@interface GPSView : UIView <LiveSubView, UIGestureRecognizerDelegate> {
    
    UIImageView *gpsIcon;
    UILabel *valueText;
    
    MKMapView *mapView;
    
    PortionOfView currentPortion;
}

- (void)updateGpsLong:(double)longitude Lat:(double)latitude Alt:(double)altitude Speed:(double)speed Course:(double)course HAcc:(double)hAcc VAcc:(double)vAcc timestamp:(NSTimeInterval)timestamp;

-(void)userSwipedToTheLeft:(UISwipeGestureRecognizer *)sender;
-(void)userSwipedToTheRight:(UISwipeGestureRecognizer *)sender;

@end
