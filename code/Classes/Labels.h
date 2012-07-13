//
//  Labels.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 15.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AbstractSensor.h"


@interface Labels : AbstractSensor {
    
    //labels should not be mutable while recording
    BOOL mutable;
    int currentLabel;
    NSMutableArray *labels;
}

@property BOOL mutable;
@property(nonatomic) int currentLabel;
@property(readonly) NSArray *labels;

//singleton
+(Labels *) sharedInstance;

-(void)addLabel:(NSString *)newLabel;
-(void)removeLabelAtIndex:(int)index;

-(NSString *)getNameForLabelAtIndex:(int)index;
-(int)count;

@end
