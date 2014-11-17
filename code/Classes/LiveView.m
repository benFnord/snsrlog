// The BSD 2-Clause License (aka "FreeBSD License")
// 
// Copyright (c) 2012, Benjamin Thiel
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met: 
// 
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer. 
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//
//  LiveView.m
//  snsrlog
//
//  Created by Benjamin Thiel on 16.05.11.
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
 * Determines whether this an internal system view only by looking at its tag.
 * Example: auto layout related views, which can be tested with [view conformsToProtocol:@protocol(UILayoutSupport)];
 */
BOOL isSystemView(UIView *view) {
    
    return view.tag == 0;
}

static const CGFloat fixedSpacerSize = 10;

//positions the views, so that they have the same vertical space between them (and the top/bottom)
- (void)layoutSubviews {
    
    CGFloat availableHeight = self.bounds.size.height;
    NSUInteger numberOfSubviews = 0;
    
    for (UIView *subView in self.subviews) {
        
        if (isSystemView(subView)) continue;
        
        numberOfSubviews++;
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

            if (isSystemView(subView)) continue;
            
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
