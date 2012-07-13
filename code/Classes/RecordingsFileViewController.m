//
//  RecordingsFileViewController.m
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 28.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RecordingsFileViewController.h"


@implementation RecordingsFileViewController

@synthesize webView;
@synthesize activityIndicator;


- (id)initWithTitle:(NSString *)title showContentsOfFileAtPath:(NSString *)path {
    
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization
        self.title = title;
        filePath = [path copy];
    }
    return self; 
}

- (void)dealloc
{
    self.webView = nil;
    self.activityIndicator = nil;
    [filePath release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault
                                                animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    // Create a 'right hand button' that is a activity Indicator
    CGRect frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
    self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:frame] autorelease];
    [self.activityIndicator sizeToFit];
    self.activityIndicator.autoresizingMask =
    (UIViewAutoresizingFlexibleLeftMargin |
     UIViewAutoresizingFlexibleRightMargin |
     UIViewAutoresizingFlexibleTopMargin |
     UIViewAutoresizingFlexibleBottomMargin);
    
    UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    
    self.navigationItem.rightBarButtonItem = loadingView;
    
    //we don't need it anymore -> release it
    [loadingView release];
    
    //load the file
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]];
    [self.webView loadRequest:request];
}
    
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.webView = nil;
    self.activityIndicator = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
    // Return YES for supported orientations
}

//MARK: - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    [self.activityIndicator stopAnimating];
}

@end
