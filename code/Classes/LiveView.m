//
//  LiveView.m
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 16.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LiveView.h"


@implementation LiveView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // Initialization code
        self.autoresizesSubviews = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin 
                              | UIViewAutoresizingFlexibleBottomMargin;
        self.backgroundColor = [UIColor blackColor];

    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

static const CGFloat fixedSpacerSize = 10;

//positions the views, so that they have the same vertical space between them (and the top/bottom)
- (void)layoutSubviews {
    
    CGFloat availableHeight = self.bounds.size.height;
    int numberOfSubviews = self.subviews.count; 
    
    for (UIView *subView in self.subviews) {
        
        availableHeight -= subView.frame.size.height;
    }
    
    //Check for the presence of the table view and resize it such that there are fixedSpacerSize points between every subview.
    //Otherwise the space between the view is dynamically evened out.
    UIView *tableView = [self viewWithTag:LabelTableViewTag];
    if (tableView) {
        
        CGFloat enlargeTableViewHeightBy = availableHeight - ((numberOfSubviews + 1) * fixedSpacerSize);
        
        CGRect oldFrame = tableView.frame;
        CGFloat newHeight = oldFrame.size.height + enlargeTableViewHeightBy;
        
        CGRect newFrame = CGRectMake(oldFrame.origin.x,
                                     oldFrame.origin.y,
                                     oldFrame.size.width,
                                     newHeight);

        [UIView animateWithDuration:kLiveViewLayoutingAnimationDuration animations:^(void) {
            
            tableView.frame = newFrame;
        }];
        
        availableHeight -= enlargeTableViewHeightBy;
    }
    
    //compute the height of the space between the views
    CGFloat spacerHeight = roundf( availableHeight / (numberOfSubviews + 1) - 0.5 );
    //subviews greater than available space?
    if (spacerHeight < 0) spacerHeight = 0;
    
    //create an array of the views sorted by their tag -> this specifies their order on the screen
    NSSortDescriptor *tagDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"tag"
                                                                   ascending:YES] autorelease];
    NSArray *sortedViews = [self.subviews sortedArrayUsingDescriptors:[NSArray arrayWithObject:tagDescriptor]];
    
    
    //position the views and animate the changes
    [UIView animateWithDuration:kLiveViewLayoutingAnimationDuration animations:^(void) {
        
        CGFloat currentY = 0;
        
        for (UIView *subView in sortedViews) {
            
            CGRect oldFrame = subView.frame;
            CGFloat newY = currentY + spacerHeight;
            
            CGRect newFrame = CGRectMake(oldFrame.origin.x,
                                         newY,
                                         oldFrame.size.width,
                                         oldFrame.size.height);
            
            currentY = newY + newFrame.size.height;
            
            //move the view to its place
            subView.frame = newFrame;
        }
    }];
}

- (void)dealloc
{
    [super dealloc];
}

@end
