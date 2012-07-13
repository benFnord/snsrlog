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
//  StreamingLiveFlipsideViewController.m
//  snsrlog
//
//  Created by Benjamin Thiel on 15.07.11.
//

#import "StreamingLiveFlipsideViewController.h"
#import "StreamingClient.h"

@implementation StreamingLiveFlipsideViewController

- (id)initWithStyle:(UITableViewStyle)style streamingLiveViewController:(StreamingLiveViewController *)liveViewController
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
        liveView = liveViewController;
        
        UISwitch *accSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        accSwitch.on = liveView.showAccelerometer; //set to current status
        [accSwitch addTarget:self 
                      action:@selector(showAccelerometer:) 
            forControlEvents:UIControlEventValueChanged];
        
        UISwitch *compassSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        compassSwitch.on = liveView.showCompass;
        [compassSwitch addTarget:self 
                      action:@selector(showCompass:) 
            forControlEvents:UIControlEventValueChanged];
        
        UISwitch *gpsSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        gpsSwitch.on = liveView.showGPS;
        [gpsSwitch addTarget:self 
                      action:@selector(showGPS:) 
            forControlEvents:UIControlEventValueChanged];
        
        switches = [[NSArray arrayWithObjects:accSwitch, compassSwitch, gpsSwitch, nil] retain];
        displayNames = [[NSArray arrayWithObjects:@"show accelerometer", @"show compass", @"show GPS", nil] retain];
        
        //switches are now retained by the NSArray
        [accSwitch release];
        [compassSwitch release];
        [gpsSwitch release];
    }
    return self;
}

- (void)dealloc
{
    [switches release];
    [displayNames release];
    
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
 
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self 
                                                                                action:@selector(doneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    [doneButton release];
    
    self.tableView.backgroundColor = [UIColor blackColor];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//MARK: - reacting to buttons

-(void)doneButtonPressed:(UIButton *)sender {
    
    [self dismissModalViewControllerAnimated:YES];
}

-(void)showGPS:(UISwitch *)sender {
    
    liveView.showGPS = sender.isOn;
}

-(void)showAccelerometer:(UISwitch *)sender {
    
    liveView.showAccelerometer = sender.isOn;
}

-(void)showCompass:(UISwitch *)sender {
    
    liveView.showCompass = sender.isOn;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        
        case 0:
            return [switches count];
        case 1:
            return 1;
        
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 
    //dirty hack to increase the space between the sections
    return @" ";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    switch (indexPath.section) {
        case 0:
            cell.accessoryView = [switches objectAtIndex:indexPath.row];
            cell.backgroundColor = [UIColor whiteColor];
            cell.textLabel.textColor = [UIColor blackColor];
            cell.textLabel.textAlignment = UITextAlignmentLeft;
            cell.textLabel.text = [displayNames objectAtIndex:indexPath.row];
            break;
         
        case 1: 
            cell.accessoryView = nil;
            cell.backgroundColor = [UIColor redColor];
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.textLabel.text = @"Disconnect";
            break;
        default:
            break;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (indexPath.section == 1) {
        
        [[StreamingClient sharedInstance] disconnect];
    }
}

@end
