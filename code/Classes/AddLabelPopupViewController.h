//
//  AddLabelPopupViewController.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 28.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddLabelDelegate <NSObject>

-(void)userEnteredLabelOrNil:(NSString *)newLabel;

@end

@interface AddLabelPopupViewController : UIViewController <UITextFieldDelegate> {
    
}

@property (assign, nonatomic) id<AddLabelDelegate> delegate;
@property (retain, nonatomic) IBOutlet UITextField *textField;

-(IBAction)cancel:(UITabBarItem *)sender;
-(IBAction)save:(UITabBarItem *)sender;

@end
