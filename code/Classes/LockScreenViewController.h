//
//  LockScreen.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 30.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LockScreenDelegate

-(void)userUnlockedScreen;

@end

@interface LockScreenViewController : UIViewController {
    
}

@property(nonatomic, assign) id<LockScreenDelegate> delegate;
@property(nonatomic, retain) IBOutlet UISlider *slider;

-(IBAction) sliderValueChanged:(UISlider *)sender;

@end
