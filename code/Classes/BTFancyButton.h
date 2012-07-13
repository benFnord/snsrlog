//
//  BTFancyButton.h
//  snsrlog
//
//  Created by Benjamin Thiel on 06.12.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#define kBTFancyButtonGradientLightColorSummand 0.85

@interface BTFancyButton : UIButton {
    
    CAGradientLayer *gradientLayer;
}

+(UIColor *)aestheticallyPleasingGreen;

@end
