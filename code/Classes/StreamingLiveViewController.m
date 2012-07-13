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
//  StreamingLiveViewController.m
//  snsrlog
//
//  Created by Benjamin Thiel on 06.07.11.
//

#import "StreamingLiveViewController.h"
#import "StreamingClient.h"
#import "LiveView.h"
#import "GraphView.h"
#import "CompassView.h"
#import "GPSView.h"
#import "StreamingLiveFlipsideViewController.h"

@interface StreamingLiveViewController ()

@property (nonatomic, retain) LiveView *compositeView;
@property (nonatomic, retain) GraphView *accelerometerView;
@property (nonatomic, retain) CompassView *compassView;
@property (nonatomic, retain) GPSView *gpsView;
@property (nonatomic, retain) UITableView *labelTableView;
@property (nonatomic, retain) UIButton *flipSideButton;
@property (retain) NSArray *labels;

-(void)releaseSubviews;

@end

@implementation StreamingLiveViewController

@synthesize showAccelerometer, showGPS, showCompass;
@synthesize compositeView, accelerometerView, compassView, gpsView, labelTableView, flipSideButton;
@synthesize labels;

//MARK: -
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        
        //the "defaults" for streaming
        showGPS = YES;
        showAccelerometer = YES;
        showCompass = YES;
        
        lastLabel = 0;
    }
    return self;
}

- (void)dealloc
{
    //we don't want new data
    [StreamingClient sharedInstance].dataReceiver = nil;
    
    self.labels = nil;
    [self releaseSubviews];
    
    [super dealloc];
}

-(void)releaseSubviews {
    
    self.compositeView = nil;
    self.accelerometerView = nil;
    self.compassView = nil;
    self.gpsView = nil;
    self.labelTableView = nil;
    self.flipSideButton = nil;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    
    //try to get the fullscreen, will be shrunk by tab bar and status bar anyway.
    CGRect fullscreen = CGRectMake(0.0, 0.0, 480, 320);
    self.compositeView = [[[LiveView alloc] initWithFrame:fullscreen] autorelease];
    
    
    //create the subviews. all views have (0, 0) as origin, as the layout is handled in LiveView's layoutSubviews
    
    CGRect accelerometerFrame = CGRectMake(0, 0, [GraphView preferredSize].width, [GraphView preferredSize].height);
    self.accelerometerView = [[[GraphView alloc] initWithFrame:accelerometerFrame
                                                 MaximumValue:3
                           labelsFor7LinesFromHighestToLowest:[NSArray arrayWithObjects:@"3.0",@"2.0",@"1.0",@"0.0",@"-1.0",@"-2.0",@"-3.0", nil]
                                                 xDescription:@"acceleration x"
                                                 yDescription:@"acceleration y"
                                                 zDescription:@"acceleration z"] autorelease];
    self.accelerometerView.frameRateDivider = 2;//=approx 60/2 = 30fps
    self.accelerometerView.tag = AccelerometerViewTag;
    
    
    CGRect compassFrame = CGRectMake(0, 0, [CompassView preferredSize].width, [CompassView preferredSize].height);
    self.compassView = [[[CompassView alloc] initWithFrame:compassFrame] autorelease];
    self.compassView.tag = CompassViewTag;
    
    
    CGRect gpsFrame = CGRectMake(0, 0, [GPSView preferredSize].width, [GPSView preferredSize].height);
    self.gpsView = [[[GPSView alloc] initWithFrame:gpsFrame] autorelease];
    self.gpsView.tag = GPSViewTag;
    
    
    CGRect labelTableViewFrame = CGRectMake(0, 0, 320, 160);
    self.labelTableView = [[[UITableView alloc] initWithFrame:labelTableViewFrame 
                                                        style:UITableViewStyleGrouped] autorelease];
    self.labelTableView.backgroundColor = [UIColor blackColor];
    self.labelTableView.tag = LabelTableViewTag;
    self.labelTableView.delegate = self;
    self.labelTableView.dataSource = self;
    [self.compositeView addSubview:self.labelTableView]; //always show it
    
    
    self.flipSideButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    CGRect oldFrame = self.flipSideButton.frame;
    self.flipSideButton.frame = CGRectMake(290,
                                           oldFrame.origin.y,
                                           oldFrame.size.width,
                                           oldFrame.size.height);
    self.flipSideButton.tag = FlipSideViewButtonTag;
    [self.flipSideButton addTarget:self 
                            action:@selector(infoButtonPressed:) 
                  forControlEvents:UIControlEventTouchUpInside];
    [self.compositeView addSubview:self.flipSideButton]; //always show it
    
    
    //triggers adding of the respective view upon reception of data (also after recovering from a memory warning)
    isGPSViewOnScreen = NO;
    isAccelerometerViewOnScreen = NO;
    isCompassViewOnScreen = NO;
    
    self.view = self.compositeView;
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //ready to receive data
    [StreamingClient sharedInstance].dataReceiver = self;
    
    //request the labels
    [[StreamingClient sharedInstance] sendCommand:RequestListOfLabelsAndCurrentLabel];
    
    //start/stop streaming and showing/not showing the view
    self.showGPS = showGPS;
    self.showAccelerometer = showAccelerometer;
    self.showCompass = showCompass;
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [self releaseSubviews];
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque
                                                animated:YES];
}


-(void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
}

//MARK: - responding to buttons
-(void)infoButtonPressed:(UIButton *)sender {
    
    StreamingLiveFlipsideViewController *flipside = [[StreamingLiveFlipsideViewController alloc] initWithStyle:UITableViewStyleGrouped 
                                                                                   streamingLiveViewController:self];
    flipside.title = [StreamingClient sharedInstance].currentServerScreenName;
    flipside.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    //"hack": we need the navigation controller to display a navigation bar in the flipside view
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:flipside];
    navController.navigationBar.barStyle = UIBarStyleBlack;
    
    [self presentModalViewController:navController animated:YES];
    
    [flipside release];
    [navController release];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//MARK: - overriding the synthesized setters
-(void)setShowGPS:(BOOL)shouldShowGPS {
    
    showGPS = shouldShowGPS;
    [StreamingClient sharedInstance].receiveGPS = showGPS; //start/stop transmission of data
    
    if (!showGPS) {
        
        [self.gpsView removeFromSuperview];
        isGPSViewOnScreen = NO;
    }
}

-(void)setShowCompass:(BOOL)shouldShowCompass {
    
    showCompass = shouldShowCompass;
    [StreamingClient sharedInstance].receiveCompass = showCompass; //start/stop transmission of data
    
    if (!showCompass) {

        [self.compassView stopDrawing];
        [self.compassView removeFromSuperview];
        isCompassViewOnScreen = NO;
    }
}

-(void)setShowAccelerometer:(BOOL)shouldShowAccelerometer {
    
    showAccelerometer = shouldShowAccelerometer;
    [StreamingClient sharedInstance].receiveAccelerometer = showAccelerometer; //start/stop transmission of data
    
    if (!showAccelerometer) {

        [accelerometerView stopDrawing];
        [self.accelerometerView removeFromSuperview];
        isAccelerometerViewOnScreen = NO;
        
    }
}

//MARK: - PacketEncoderDecoderDataReceiveDelegate
-(void)didReceiveAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z skipCount:(long)skipCount {
    
    if (showAccelerometer) {
        
        if (!isAccelerometerViewOnScreen) {
            
            [self.compositeView addSubview:self.accelerometerView];
            isAccelerometerViewOnScreen = YES;
            
            [accelerometerView startDrawing];
        }
        
        [accelerometerView addX:x
                              y:y
                              z:z
                      skipCount:skipCount];
    }
}

-(void)didReceiveChangeToLabel:(int)label {
    
    //uncheck the old entry
    UITableViewCell *oldCell = [self.labelTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:lastLabel inSection:0]];
    [oldCell setAccessoryType:UITableViewCellAccessoryNone];
    
    lastLabel = label;
    
    //bounds checking
    if ((label >= 0) && (label < [labels count])) {
        
        //add checkmark to the new entry
        NSIndexPath *newCellPosition = [NSIndexPath indexPathForRow:label inSection:0];
        UITableViewCell *newCell = [self.labelTableView cellForRowAtIndexPath:newCellPosition];
        [newCell setAccessoryType:UITableViewCellAccessoryCheckmark];
        
        //scroll into visibility
        [self.labelTableView scrollToRowAtIndexPath:newCellPosition
                                   atScrollPosition:UITableViewScrollPositionNone
                                           animated:YES]; 
    }
}

-(void)didReceiveListOfLabels:(NSArray *)newLabels {
    
    labelTableView.dataSource = nil; //prevent the table view from querying the array while it is updated
    self.labels = newLabels;
    labelTableView.dataSource = self;
    
    [self.labelTableView reloadData];
}

-(void)didReceiveGPSvalueWithLongitude:(double)longitude latitude:(double)latitude altitude:(double)altitude speed:(double)speed course:(double)course horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy timestamp:(double)timestamp {
    
    if (showGPS) {
        
        if (!isGPSViewOnScreen) {
            
            [self.compositeView addSubview:self.gpsView];
            isGPSViewOnScreen = YES;
        }
        
        [gpsView updateGpsLong:longitude
                           Lat:latitude
                           Alt:altitude
                         Speed:speed
                        Course:course
                          HAcc:horizontalAccuracy
                          VAcc:verticalAccuracy
                     timestamp:timestamp];
    }
}

-(void)didReceiveCompassValueWithMagneticHeading:(double)magneticHeading trueHeading:(double)trueHeading headingAccuracy:(double)headingAccuracy x:(double)x y:(double)y z:(double)z {
    
    if (showCompass) {
        
        if (!isCompassViewOnScreen) {
            
            [self.compositeView addSubview:self.compassView];
            isCompassViewOnScreen = YES;
            
            [self.compassView startDrawing];
        }
        
        [compassView updateCompassWithMagneticHeading:magneticHeading
                                          trueHeading:trueHeading
                                             accuracy:headingAccuracy
                                                    x:x 
                                                    y:y
                                                    z:z];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.labels count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    cell.textLabel.text = [NSString stringWithFormat:@"%2d - %@", indexPath.row, [self.labels objectAtIndex:indexPath.row]];
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.textColor = [UIColor blackColor];
    
    //Due to recycling of the cells, we need to uncheck the cell if it is not the current label.
    //Otherwise, the checkmark may appear on a cell, although it is not the current label.
    if (indexPath.row == lastLabel) {
        
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark]; 
        
    } else {
        
        [cell setAccessoryType:UITableViewCellAccessoryNone]; 
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //try to set the label, setting the checkmark is done in didReceiveChangeToLabel:, 
    //since the label may have been changed on the server
    [[StreamingClient sharedInstance] sendCommandToChangeLabel:indexPath.row];
    
    //deselect the currently selected row (=makes the blue background color of the cell disappear)
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
