//
//  GPSView.m
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 16.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GPSView.h"
#import "QuartzCore/QuartzCore.h"


@implementation GPSView

+(CGSize) preferredSize {
    
    //the view should have the twice the screen width since we want to swipe between to differnt views
    return CGSizeMake(640, 75);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        currentPortion = leftSide; //the left side of the view is displayed initially
        
        // create the GPS icon
        UIImage *gpsImage = [UIImage imageNamed:@"satellite.png"];
        CGFloat centeredIconY = roundf((self.bounds.size.height / 2) - (gpsImage.size.height / 2));
        CGRect gpsImageFrame = CGRectMake(8, centeredIconY, gpsImage.size.width, gpsImage.size.height);
        gpsIcon = [[UIImageView alloc] initWithFrame:gpsImageFrame];
        gpsIcon.image = gpsImage;
        
        [self addSubview:gpsIcon];
        
        
        // create the text
        CGFloat leftMargin = 65;
        CGRect textRect = CGRectMake(leftMargin, 0, self.bounds.size.width - leftMargin, self.bounds.size.height);
        valueText = [[UILabel alloc] initWithFrame:textRect];
        valueText.font = [UIFont systemFontOfSize:12];
        valueText.textColor = [UIColor whiteColor];
        valueText.numberOfLines = 5;
        valueText.backgroundColor = [UIColor clearColor];
        
        [self addSubview:valueText];
        //initialize the text with random values
        [self updateGpsLong:0 Lat:0 Alt:0 Speed:0 Course:0 HAcc:0 VAcc:0 timestamp:0];
        
        //create the map view
        CGRect mapViewFrame = CGRectMake(320, 0, 320, self.bounds.size.height); //the rightSide of the view
        mapView = [[MKMapView alloc] initWithFrame:mapViewFrame];
        mapView.scrollEnabled = YES;
        mapView.zoomEnabled = YES;
        mapView.showsUserLocation = YES; //display the circle representing the current position and accuracy
        mapView.mapType = MKMapTypeHybrid;
        
        //make the web view a rounded rect
        mapView.backgroundColor = [UIColor blackColor];
        mapView.layer.cornerRadius = 8;
        mapView.layer.masksToBounds = YES;
        
        //set intial region to University of Passau :)
        CLLocationCoordinate2D coordinates = {48.56772, 13.45328}; //48.56683, 13.45185
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinates, 200, 200); //distances in meters, implicitly sets the zoom factor
        mapView.region = region;
        
        [self addSubview:mapView];
        
        
        //recognize swipes
        UISwipeGestureRecognizer *swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self 
                                                                                              action:@selector(userSwipedToTheRight:)];
        swipeRightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        swipeRightRecognizer.numberOfTouchesRequired = kLiveSubviewNumberOfFingersForSwipeGesture;
        //we want to be notified when our recognizer interferes with mapView's recognizers
        swipeRightRecognizer.delegate = self;
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
    mapView.delegate = nil;
    [mapView release];
    [valueText release];
    [gpsIcon release];
    [super dealloc];
}


- (void)updateGpsLong:(double)longitude Lat:(double)latitude Alt:(double)altitude Speed:(double)speed Course:(double)course HAcc:(double)hAcc VAcc:(double)vAcc timestamp:(NSTimeInterval)timestamp{
    
    //update the map view
    CLLocationCoordinate2D coordinates = {latitude, longitude};
    [mapView setCenterCoordinate:coordinates animated:YES];
    
    //update the text
	NSString *myLong;
	NSString *myLat;
	
	// create the longitude-string
	if( signbit(longitude) ) {
		// negative longitude indicates a western position
		myLong = [NSString stringWithFormat:@"%.5f° West", fabs(longitude)];
		
	} else {
		// positive longitude indicates an eastern position
		myLong = [NSString stringWithFormat:@"%.5f° East", fabs(longitude)];
		
	}
	
	// create the latitude-string
	if( signbit(latitude) ) {
		// negative latitude indicates a southern position
		myLat = [NSString stringWithFormat:@"%.5f° South", fabs(latitude)];
		
	} else {
		// positive latitude indicates a northern position
		myLat = [NSString stringWithFormat:@"%.5f° North", fabs(latitude)];
		
	}
	
	// combine both strings
	NSString *myPos = [NSString stringWithFormat:@"Position:\t%@ / %@", myLat, myLong];
    NSString *myAccuracy = [NSString stringWithFormat:@"Accuracy:\t%.2f m", hAcc];
	
	// create the strings for altitude and accuracy
	NSString *myAltitude;
    
    if (signbit(vAcc)) {
       
        myAltitude = @"Altitude:\tnot available";

    } else {
       
        myAltitude = [NSString stringWithFormat:@"Altitude:\t%.2f m, Accuracy: %.2f m", altitude, vAcc];
    }
    	
    // create the string for the speed
	NSString *mySpeed;
	
    if (signbit(speed)) {
	
        mySpeed = @"Speed:\tn/a";
	
    } else {
	
        mySpeed = [NSString stringWithFormat:@"Speed:\t%.1f m/s (%.1f km/h)", speed, speed * 3.6];
	}
	
	// create the string for the course
	NSString *myCourse;
	
    if (signbit(course)) {
	
        // -1 indicates that there is no course information available
		myCourse = @"Course:\tn/a";
	
    } else {
	
        myCourse = [NSString stringWithFormat:@"Course:\t%.2f°", course];
	}
    
    //create the time string
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeStyle:NSDateFormatterLongStyle];
    NSString *time = [NSString stringWithFormat:@"Last update:\t%@", [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]]];
    [formatter release];
	
	// combine all strings
	NSString *result = [NSString stringWithFormat:@"%@\n%@\n%@\n%@, %@\n%@", myPos, myAccuracy, myAltitude, mySpeed, myCourse, time];
	
	// update the GPS buffer with the new string
    valueText.text = result;
}


//MARK: - gesture handling

static const double kAnimationDuration = 0.3;

-(void)userSwipedToTheRight:(UISwipeGestureRecognizer *)sender {
    
    if (currentPortion == rightSide) {
        
        currentPortion = leftSide;
        
        CGAffineTransform moveViewToTheRight = CGAffineTransformIdentity;
        [UIView animateWithDuration:kAnimationDuration animations:^(void) {
            
            self.transform = moveViewToTheRight;
        }];
        
    }
}

-(void)userSwipedToTheLeft:(UISwipeGestureRecognizer *)sender {

    if (currentPortion == leftSide) {
        
        currentPortion = rightSide;
        
        CGAffineTransform moveViewToTheLeft = CGAffineTransformMakeTranslation(-320, 0);
        [UIView animateWithDuration:kAnimationDuration animations:^(void) {
            
            self.transform = moveViewToTheLeft;
        }];
    }
}

//MARK: - UIGestureRecognizerDelegateProtocol

//necessary due to the map view trying to recognize its own gestures and the default is NO
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        
        UIPanGestureRecognizer *panRecognizerOfMapView = (UIPanGestureRecognizer *) otherGestureRecognizer;
        CGFloat horizontalVelocity = [panRecognizerOfMapView velocityInView:mapView].x;
        
        //consider pans faster than 400 points/sec as swipes
        if (horizontalVelocity < 400) {
            
            return NO;
            
        } else {
            
            //prevent the mapView from receiving the pan gesture by cancelling it
            panRecognizerOfMapView.enabled = NO;
            panRecognizerOfMapView.enabled = YES;
            
            //allow simultaneous recognition of "our" swipe recognizer and panRecognizerOfMapView
            return YES;
        }
        
    } else {
        
        return NO;
    }
}

@end
