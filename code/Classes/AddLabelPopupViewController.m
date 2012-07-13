//
//  AddLabelPopupViewController.m
//  snsrlog
//
//  Created by Benjamin Thiel on 28.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AddLabelPopupViewController.h"
#import "Labels.h"


@implementation AddLabelPopupViewController

@synthesize delegate;
@synthesize textField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.delegate = nil;
        self.textField = nil;
    }
    return self;
}

- (void)dealloc
{
    self.textField = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //set focus on the text field (also makes the keyboard appear)
    [self.textField becomeFirstResponder];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.textField = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
    return YES;
}

//MARK: - reacting to buttons
-(IBAction)cancel:(UITabBarItem *)sender {
    
    [self.delegate userEnteredLabelOrNil:nil];
}

-(IBAction)save:(UITabBarItem *)sender {
    
    if ([self.textField.text isEqualToString:@""]) {
        
        [self.delegate userEnteredLabelOrNil:nil];
        
    } else {
        
        [self.delegate userEnteredLabelOrNil:self.textField.text];
    }
    
}

//MARK: - UITextFieldDelegate

//called, when the user hits the return button, we interpret this as saving
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [self.textField resignFirstResponder];
    [self save:nil];
    return NO;
}

@end
