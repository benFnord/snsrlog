//
//  LockScreen.m
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 30.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LockScreenViewController.h"


@implementation LockScreenViewController

@synthesize delegate;
@synthesize slider;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.delegate = nil;
    }
    return self;
}

- (void)dealloc
{
    self.slider = nil;
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
    
    //change the thumb image of the slider to a key (could not be done in IB)
    UIImage *key = [UIImage imageNamed:@"key.png"];
    [self.slider setThumbImage:key forState:UIControlStateNormal];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.slider = nil;
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque
                                                animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(IBAction) sliderValueChanged:(UISlider *)sender {
    
    if (sender.value < 0.99) {
        
        sender.value = 0;
    
    } else {
        
        [self.delegate userUnlockedScreen];
    }
}

@end
