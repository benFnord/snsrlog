//
//  AccelerometerAndGyroscopeView.h
//  snsrlog
//
//  Created by Benjamin Thiel on 26.07.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveView.h"
#import "GraphView.h"

@interface AccelerometerAndGyroscopeView : UIView <LiveSubView>
{
    BOOL showAccelerometer;
    BOOL showGyroscope;
    
    BOOL isDrawing;
    
    GraphView *accelerometer;
    GraphView *gyroRotationRate;
    GraphView *gyroDeviceOrientation;
    
    PortionOfView currentPortion;
}

@property(nonatomic) BOOL showAccelerometer, showGyroscope;

-(void)userSwiped:(UISwipeGestureRecognizer *)sender;

-(void)didReceiveAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z;

-(void)didReceiveGyroscopeValueWithX:(double)x Y:(double)y Z:(double)z roll:(double)roll pitch:(double)pitch yaw:(double)yaw;

//to be called on the main thread
-(void)setAccelerometerStatusString:(NSString *)accStatus;
//to be called on the main thread
-(void)setGyroscopeStatusString:(NSString *)gyroStatus;

-(void)startDrawing;
-(void)stopDrawing;

@end
