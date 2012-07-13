//
//  AccelerometerAndGyroscopeView.m
//  snsrlog
//
//  Created by Benjamin Thiel on 26.07.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AccelerometerAndGyroscopeView.h"

typedef enum {
    
    left,
    right,
    noMove
    
} ViewMovement;

static const float radToDegFactor = 180.0f / M_PI;

@interface AccelerometerAndGyroscopeView ()

-(void)startDrawingForCurrentPortion;
-(void)moveToPortion:(PortionOfView)portion;
-(void)moveView:(ViewMovement)movement;

@end

@implementation AccelerometerAndGyroscopeView

@synthesize showGyroscope, showAccelerometer;

+(CGSize)preferredSize {
    
    return CGSizeMake(960, [GraphView preferredSize].height);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        currentPortion = leftSide;
        isDrawing = NO;
        
        //create the graph
        CGRect accelerometerFrame = CGRectMake(0, 0, [GraphView preferredSize].width, [GraphView preferredSize].height);
        accelerometer = [[GraphView alloc] initWithFrame:accelerometerFrame
                                            MaximumValue:3
                      labelsFor7LinesFromHighestToLowest:[NSArray arrayWithObjects:@"3.0",@"2.0",@"1.0",@"0.0",@"-1.0",@"-2.0",@"-3.0", nil]
                                            xDescription:@"acceleration x in G"
                                            yDescription:@"acceleration y in G"
                                            zDescription:@"acceleration z in G"];
        accelerometer.frameRateDivider = 2;//draw only every 2nd frame (60/2 = 30fps)
        
        [self addSubview:accelerometer];
        
        CGRect gyroRotationRateFrame = CGRectMake(320, 0, [GraphView preferredSize].width, [GraphView preferredSize].height);
        gyroRotationRate = [[GraphView alloc] initWithFrame:gyroRotationRateFrame
                            //hack: GraphView actually draws a graph with the x-axis in the middle
                            //we need to take that into consideration
                                               MaximumValue:360
                         labelsFor7LinesFromHighestToLowest:[NSArray arrayWithObjects:@"360°",@"240°",@"120°",@"0°",@"-120°",@"-240°",@"-360°", nil]
                                               xDescription:@"rotation rate x"
                                               yDescription:@"rotation rate y"
                                               zDescription:@"rotation rate z"];
        gyroRotationRate.frameRateDivider = 2;//draw only every 2nd frame (60/2 = 30fps)
        
        [self insertSubview:gyroRotationRate aboveSubview:accelerometer]; //we need to cover up the view left of us, cause it makes ugly things
        
        CGRect gyroDeviceOrientationFrame = CGRectMake(640, 0, [GraphView preferredSize].width, [GraphView preferredSize].height);
        gyroDeviceOrientation = [[GraphView alloc] initWithFrame:gyroDeviceOrientationFrame
                                 //hack: GraphView actually draws a graph with the x-axis in the middle
                                 //we need to take that into consideration
                                                    MaximumValue:180
                              labelsFor7LinesFromHighestToLowest:[NSArray arrayWithObjects:@"180°",@"120°",@"60°",@"0°",@"-60°",@"-120°",@"-180°", nil]
                                                    xDescription:@"roll"
                                                    yDescription:@"pitch"
                                                    zDescription:@"yaw"];
        gyroDeviceOrientation.frameRateDivider = 2;//draw only every 2nd frame (60/2 = 30fps)
        
        [self insertSubview:gyroDeviceOrientation aboveSubview:gyroRotationRate];
        
        //recognize swipes
        UISwipeGestureRecognizer *swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                                   action:@selector(userSwiped:)];
        swipeRightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        swipeRightRecognizer.numberOfTouchesRequired = kLiveSubviewNumberOfFingersForSwipeGesture;
        [self addGestureRecognizer:swipeRightRecognizer];
        [swipeRightRecognizer release];
        
        UISwipeGestureRecognizer *swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                                  action:@selector(userSwiped:)];
        swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        swipeLeftRecognizer.numberOfTouchesRequired = kLiveSubviewNumberOfFingersForSwipeGesture;
        [self addGestureRecognizer:swipeLeftRecognizer];
        [swipeLeftRecognizer release];
    }
    return self;
}

-(void)dealloc {
    
    [self stopDrawing];
    
    [accelerometer release];
    [gyroRotationRate release];
    [gyroDeviceOrientation release];
    
    [super dealloc];
}

//MARK: - overriding the setters

-(void)setShowGyroscope:(BOOL)newShowGyroscope {
    
    showGyroscope = newShowGyroscope;
    
    //move to accelerometer view
    if (!showGyroscope) {
        
        [self moveToPortion:leftSide];
        if (isDrawing) [self startDrawingForCurrentPortion];

    } else {
        
        //we shouldn't be on screen anyway
    }
}

-(void)setShowAccelerometer:(BOOL)newShowAccelerometer {
    
    showAccelerometer = newShowAccelerometer;
    
    //move to gyroscope view
    if (!showAccelerometer && (currentPortion == leftSide)) {
        
        [self moveToPortion:center];
        if (isDrawing) [self startDrawingForCurrentPortion];
    
    } else {
        
        //we shouldn't be on screen anyway
    }
}

//MARK: - new data 

-(void)didReceiveAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z {
    
    if (currentPortion == leftSide) {
        
        [accelerometer addX:x
                          y:y
                          z:z];
    }    
}

-(void)setAccelerometerStatusString:(NSString *)accStatus {
    
    if (currentPortion == leftSide) {
        
        accelerometer.statusString = accStatus;
    }
}

-(void)didReceiveGyroscopeValueWithX:(double)x Y:(double)y Z:(double)z roll:(double)roll pitch:(double)pitch yaw:(double)yaw {
    
    if (currentPortion == center) {
        
        [gyroRotationRate addX:(x * radToDegFactor)
                             y:(y * radToDegFactor)
                             z:(z * radToDegFactor)];
    }

    if (currentPortion == rightSide) {
        
        [gyroDeviceOrientation addX:(roll * radToDegFactor)
                                  y:(pitch * radToDegFactor) 
                                  z:(yaw * radToDegFactor)];
    }
}

-(void)setGyroscopeStatusString:(NSString *)gyroStatus {
    
    if (currentPortion == center) {
        
        gyroRotationRate.statusString = gyroStatus;
    }
    
    if (currentPortion == rightSide) {
        
        gyroDeviceOrientation.statusString = gyroStatus;   
    }
}

//MARK: - react to swipes

-(void)userSwiped:(UISwipeGestureRecognizer *)sender {
    
    PortionOfView newPortion = currentPortion;
    
    if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
        
        newPortion++;
    }
    
    if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
        
        newPortion--;
    }
    
    //swipe to accelerometer although forbidden?
    if (!showAccelerometer && (newPortion == leftSide)) {
        
        return;
    }
    
    //swipe to gyroscope although forbidden?
    if (!showGyroscope && (newPortion > leftSide)) {
        
        return;
    }
    
    //try to move the view
    [self moveToPortion:newPortion];
    [self startDrawingForCurrentPortion];
}

//MARK: - moving the view

/*
 * Moves the view, if possible, to the desired portion.
 */
-(void)moveToPortion:(PortionOfView)portion {
    
    if (   (portion != currentPortion)
        && (portion >= leftSide)
        && (portion <= rightSide)) {
        
        int numberOfMovesToTheRight = currentPortion - portion;
        
        if (numberOfMovesToTheRight > 0) {
            
            for (int i = 0; i < numberOfMovesToTheRight; i++) {
                
                [self moveView:right];
            }
        
        } else {//-numberOfMovesToTheRight = moves to the left
            
            for (int i = 0; i < - numberOfMovesToTheRight; i++) {
                
                [self moveView:left];
            }
        }
        currentPortion = portion;
    }
}

static const double kAnimationDuration = 0.3;
static const float screenWidth = 320;

//actually moves the view (without bounds checking!)
-(void)moveView:(ViewMovement)movement {
    
    CGFloat moveBy;
    
    switch (movement) {
            
        case left:
            moveBy = - screenWidth;
            break;
            
        case right:
            moveBy = screenWidth;
            break;
            
        default:
            moveBy = 0;
            break;
    }
    
    CGAffineTransform newTransform = CGAffineTransformTranslate(self.transform, moveBy, 0);
    
    [UIView animateWithDuration:kAnimationDuration animations:^(void) {
        
        self.transform = newTransform;
    }];
}

//MARK: -
-(void)startDrawing {
    
    if (!isDrawing) {
        
        isDrawing = YES;
        [self startDrawingForCurrentPortion];
    }
}

-(void)startDrawingForCurrentPortion {
    
    [self stopDrawing];
    
    switch (currentPortion) {
        
        case leftSide:
            [accelerometer startDrawing];
            isDrawing = YES;
            break;
            
        case center:
            [gyroRotationRate startDrawing];
            isDrawing = YES;
            break;
            
        case rightSide:
            [gyroDeviceOrientation startDrawing];
            isDrawing = YES;
            break;
            
        default:
            break;
    }
}

-(void)stopDrawing {
    
    if (isDrawing) {
        
        isDrawing = NO;
        
        [accelerometer stopDrawing];
        [gyroRotationRate stopDrawing];
        [gyroDeviceOrientation stopDrawing];
    }
}


@end
