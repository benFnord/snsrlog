//
//  CompassView.m
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 16.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CompassView.h"

//float is sufficiently accurate since CGFloat is a float anyway
static const float degToRadFactor = M_PI / 180.0f;

/*
 * We use one pixel more than the screen width, because GraphView "reaches" one pixel
 * to the left out of its bounds when a GraphViewSegment is "recycled".
 * To avoid these nasty pixels appearing in the icon and text part of the view,
 * we move the graph one pixel to the right.
 */
#define compassGraphViewX 321

@implementation CompassView

+ (CGSize)preferredSize {
    
    return CGSizeMake(320 + compassGraphViewX, 50);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        lastHeading = 0;
        
        currentPortion = leftSide;
        
        // create the compass image
        UIImage *compassImage = [UIImage imageNamed:@"compassWithoutNeedle.png"];
        CGFloat iconSize = 50; //we assume an icon in shape of a square size=height=width
        CGFloat centeredIconY = roundf((self.bounds.size.height / 2) - (iconSize / 2));
        CGRect compassImageFrame = CGRectMake(5, centeredIconY, iconSize, iconSize);
        compassIcon = [[UIImageView alloc] initWithFrame:compassImageFrame];
        compassIcon.image = compassImage;
        compassIcon.alpha = 1;
        
        [self addSubview:compassIcon];
        
        // create the text
        CGFloat leftMargin = 65;
        CGRect textRect = CGRectMake(leftMargin, 0, self.bounds.size.width - leftMargin, self.bounds.size.height);
        values = [[UILabel alloc] initWithFrame:textRect];
        values.font = [UIFont systemFontOfSize:12];
        values.textColor = [UIColor whiteColor];
        values.numberOfLines = 3;
        values.backgroundColor = [UIColor clearColor];
        [self addSubview:values];
        
        //initialize the text with invalid values
        [self updateCompassWithMagneticHeading:0 trueHeading:0 accuracy:0 x:0 y:0 z:0];
        
        //create the graph
        CGRect compassGraphFrame = CGRectMake(compassGraphViewX, 0, [GraphView preferredSize].width, [GraphView preferredSize].height);
        compassGraph = [[GraphView alloc] initWithFrame:compassGraphFrame MaximumValue:120
                     labelsFor7LinesFromHighestToLowest:[NSArray arrayWithObjects:@"120", @"80",@"40",@"0",@"-40",@"-80",@"-120",nil]  
                                           xDescription:@"x in microteslas"
                                           yDescription:@"y in microteslas"
                                           zDescription:@"z in microteslas"];
        compassGraph.frameRateDivider = 3;//approx 60fps / 2 = 30fps
        
        [self addSubview:compassGraph];
        
        //recognize swipes
        UISwipeGestureRecognizer *swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                                   action:@selector(userSwipedToTheRight:)];
        swipeRightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        swipeRightRecognizer.numberOfTouchesRequired = kLiveSubviewNumberOfFingersForSwipeGesture;
        [self addGestureRecognizer:swipeRightRecognizer];
        [swipeRightRecognizer release];
        
        UISwipeGestureRecognizer *swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                                  action:@selector(userSwipedToTheLeft:)];
        swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        swipeLeftRecognizer.numberOfTouchesRequired = kLiveSubviewNumberOfFingersForSwipeGesture;
        [self addGestureRecognizer:swipeLeftRecognizer];
        [swipeLeftRecognizer release];
    }
    return self;
}

- (void)dealloc
{
    [compassGraph release];
    [values release];
    [compassIcon release];
    [super dealloc];
}

//MARK: -

- (void)updateCompassWithMagneticHeading:(double)magneticH trueHeading:(double)trueH accuracy:(double)acc x:(double)x y:(double)y z:(double)z{
    
    if (currentPortion == rightSide) {
        
        //update the graph
        [compassGraph addX:x
                         y:y
                         z:z];
    }
    
    if (currentPortion == leftSide) {
        
        NSString *myMagneticHeading;
        NSString *myTrueHeading;
        NSString *myHeadingAccuracy;
        
        if ( signbit(magneticH) ) {
            // negative values indicates an invalid heading
            myMagneticHeading = @"Magnetic Heading: not available";
        } else {
            myMagneticHeading = [NSString stringWithFormat:@"Magnetic Heading: %.2f°", magneticH];
        }
        
        if ( signbit(trueH) ) {
            // negative values indicates an invalid heading
            myTrueHeading = @"True Heading: not available";
        } else {
            myTrueHeading = [NSString stringWithFormat:@"True Heading: %.2f°", trueH];
        }
        
        if ( signbit(acc) ) {
            // negative values indicates an invalid estimation
            myHeadingAccuracy = @"Error: invalid heading (interferences?)";
        } else {
            myHeadingAccuracy = [NSString stringWithFormat:@"Deviation: %.2f°", acc];
        }
        
        // combine all strings
        NSString *result = [NSString stringWithFormat:@"%@ \n%@ \n%@", myMagneticHeading, myTrueHeading, myHeadingAccuracy];
        
        //update text
        values.text = result;
        
        if (fabs(lastHeading - magneticH) >= 0.9) {
            
            lastHeading = magneticH;
            
            //rotate the compass icon
            CGFloat rotationInRad = ((float) magneticH) * degToRadFactor;    
            CGAffineTransform rotationMatrix = CGAffineTransformMakeRotation(-rotationInRad);
            compassIcon.transform = rotationMatrix;
        }
    }
}

-(void)startDrawing {
    
    if (currentPortion == rightSide) {
        
        [compassGraph startDrawing];
    }
}

-(void)stopDrawing {
    
    [compassGraph stopDrawing];
}

//MARK: - gesture handling

static const double kAnimationDuration = 0.5;

-(void)userSwipedToTheRight:(UISwipeGestureRecognizer *)sender {
    
    if (currentPortion == rightSide) {
        
        currentPortion = leftSide;
        
        [compassGraph stopDrawing];
        
        //shrink the frame, because we need less space for text & icon view
        self.frame = CGRectMake(self.frame.origin.x,
                                self.frame.origin.y,
                                self.frame.size.width,
                                [[self class] preferredSize].height); //shrink in height
        
        CGAffineTransform moveViewToTheRight = CGAffineTransformIdentity;
        
        [UIView animateWithDuration:kAnimationDuration animations:^(void) {
            
            self.transform = moveViewToTheRight;
        }];
    }
}

-(void)userSwipedToTheLeft:(UISwipeGestureRecognizer *)sender {
    
    if (currentPortion == leftSide) {
        
        currentPortion = rightSide;
        
        [compassGraph startDrawing];
        
        //enlarge the frame to show the GraphView
        self.frame = CGRectMake(self.frame.origin.x,
                                self.frame.origin.y,
                                self.frame.size.width,
                                [GraphView preferredSize].height); //expand in height
        
        CGAffineTransform moveViewToTheLeft = CGAffineTransformMakeTranslation(- compassGraphViewX, 0);
        [UIView animateWithDuration:kAnimationDuration animations:^(void) {
            
            self.transform = moveViewToTheLeft;
        }];
    }
}

@end
