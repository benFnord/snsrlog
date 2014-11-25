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
//  RecordingViewController.m
//  snsrlog
//
//  Created by Benjamin Thiel on 24.05.11.
//

#import "RecordingViewController.h"
#import "Labels.h"
#import "Listener.h"
#import "Accelerometer.h"
#import "Gyroscope.h"
#import "CompassAndGPS.h"
#import "AudioInput.h"
#import "Preferences.h"
#import "snsrlogAppDelegate.h"

#ifndef APP_STORE
    #import "WiFiScanner.h"
#endif

#pragma mark private methods
@interface RecordingViewController()

-(void)startRecording;
-(void)stopRecording;

-(void)adaptRecordingButtonAppearance;

-(void)releaseOutlets;

-(void)wireUpFileWriterAccordingToPreferences;
-(void)removeFileWriterFromAllSensors;

@end

@implementation RecordingViewController

//IBOutlets
@synthesize myTableView, addLabelButton, removeLabelButton, recordingButton, lockButton;

#pragma mark - initialization methods
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        //weak reference for convenience and performance
        labels = [Labels sharedInstance];
        
        //listen for label changes
        [labels addListener:(id<Listener>)self];
        lastLabel = 0;
        
        //create the file writer
        fileWriter = [[FileWriter alloc] init];
        
        //labels changes are always recorded
        [[Labels sharedInstance] addListener:fileWriter];
        
        //listen for changes in preferences. This might also yield to a call of preferencesChanged, hence the fileWriter has to be initialized
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(preferencesChanged:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    }
    return self;
}

-(void)wireUpFileWriterAccordingToPreferences {
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([userDefaults boolForKey:kRecordAccelerometer]) {
        
        [[Accelerometer sharedInstance] addListener:fileWriter];
        
    } else {
        
        [[Accelerometer sharedInstance] removeListener:fileWriter];
    }
    
    if ([userDefaults boolForKey:kRecordGyroscope]) {
        
        [[Gyroscope sharedInstance] addListener:fileWriter];
        
    } else {
        
        [[Gyroscope sharedInstance] removeListener:fileWriter];
    }
    
    //BUG: we record to much here, but I'm to lazy to change CompassAndGPS a.t.m.
    if ([userDefaults boolForKey:kRecordCompass] || [userDefaults boolForKey:kRecordGps]) {
        
        [[CompassAndGPS sharedInstance] addListener:fileWriter];
    }
    if (![userDefaults boolForKey:kRecordCompass] && ![userDefaults boolForKey:kRecordGps]) {
        
        [[CompassAndGPS sharedInstance] removeListener:fileWriter];
    }
    
    if ([userDefaults boolForKey:kRecordMicrophone]) {
        
        [[AudioInput sharedInstance] addListener:fileWriter];
        
    } else {
        
        [[AudioInput sharedInstance] removeListener:fileWriter];
    }
    
#ifndef APP_STORE
    if ([userDefaults boolForKey:kRecordWifi]) {
        
        [[WiFiScanner sharedInstance] addListener:fileWriter];
        
    } else {
        
        [[WiFiScanner sharedInstance] removeListener:fileWriter];
    }
#endif
}

-(void)removeFileWriterFromAllSensors {
    
    [[Accelerometer sharedInstance] removeListener:fileWriter];
    [[Gyroscope sharedInstance] removeListener:fileWriter];
    [[CompassAndGPS sharedInstance] removeListener:fileWriter];
    [[AudioInput sharedInstance] removeListener:fileWriter];
#ifndef APP_STORE
    [[WiFiScanner sharedInstance] removeListener:fileWriter];
#endif
}

//wireing up the filewriter with the sensors according to the preferences
-(void)preferencesChanged:(NSNotification *)notification {
    
    if (fileWriter.isRecording) {
        
        [self wireUpFileWriterAccordingToPreferences]; //accomodate to new preferences
    }
}

-(void)releaseOutlets {
    
    self.myTableView = nil;
    self.addLabelButton = nil;
    self.removeLabelButton = nil;
    self.recordingButton = nil;
    self.lockButton = nil;
}

- (void)dealloc
{
    [self stopRecording];
    [fileWriter release];
    [self releaseOutlets];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - actual recording

-(void)startRecording {
    
    if (!fileWriter.isRecording) {
        
        //prevent labels from being edited
        removeLabelButton.enabled = NO;
        addLabelButton.enabled = NO;
        //end any editing sessions
        [myTableView setEditing:NO animated:YES];
        removeLabelButton.style = UIBarButtonItemStyleBordered;
        
        [self wireUpFileWriterAccordingToPreferences];
        [fileWriter startRecording];

        //prevent the device from sleeping and activate the proximity sensor (which also turns off the display)
        snsrlogAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate preventAutoLock:YES];
        [appDelegate enableProximitySensing:YES];
        
        [self adaptRecordingButtonAppearance];
    }
}

-(void)stopRecording {
    
    if (fileWriter.isRecording) {
        
        [fileWriter stopRecording];
        [self removeFileWriterFromAllSensors];
        
        //make labels editable again
        removeLabelButton.enabled = YES;
        addLabelButton.enabled = YES;
        
        //allow the device to auto-lock itself again and disable proximity sensing
        snsrlogAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate preventAutoLock:NO];
        [appDelegate enableProximitySensing:NO];
        
        [self adaptRecordingButtonAppearance];
    }
}

-(void)adaptRecordingButtonAppearance {
    
    if ([fileWriter isRecording]) {
        
        self.recordingButton.backgroundColor = [UIColor redColor];
        [self.recordingButton setTitle:@"Stop Recording" forState:UIControlStateNormal];
        
    } else {
        
        self.recordingButton.backgroundColor = [BTFancyButton aestheticallyPleasingGreen];
        [self.recordingButton setTitle:@"Start Recording" forState:UIControlStateNormal];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.addLabelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                        target:self
                                                                        action:@selector(addLabel:)];
    self.navigationItem.leftBarButtonItem = [self.addLabelButton autorelease];
    
    self.removeLabelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                           target:self
                                                                           action:@selector(removeLabels:)];
    self.navigationItem.rightBarButtonItem = [self.removeLabelButton autorelease];
    
    //The recording button should reflect the current recording status.
    //This is necessary, since reloading the view after a memory warning
    //may let the view get out of sync with the model
    [self adaptRecordingButtonAppearance];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self releaseOutlets];
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault
                                                animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark responding to buttons
-(IBAction)recordingPressed:(BTFancyButton *)sender {
    
    if ([fileWriter isRecording]) {
        
        [self stopRecording];
    
    } else {
    
        [self startRecording];
    }
}

-(IBAction)lockScreen:(UIButton *)sender {
    
    //show the lock screen
    LockScreenViewController *lockScreen = [[LockScreenViewController alloc] init];
    lockScreen.delegate = self;
    
    lockScreen.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentModalViewController:lockScreen animated:YES];
    [lockScreen release];
}


-(IBAction)removeLabels:(UIBarButtonItem *)sender {
    
    //dirty way to determine whether we're in editing mode
    if (sender.style != UIBarButtonItemStyleDone) {
        
        sender.style = UIBarButtonItemStyleDone; //makes the delete button appear in a brighter blue
        [myTableView setEditing:YES animated:YES];
    
    } else {
        
        sender.style = UIBarButtonItemStyleBordered;
        [myTableView setEditing:NO animated:YES];
    }
}

-(IBAction)addLabel:(UIBarButtonItem *)sender {
    
    //show a view for label entry
    AddLabelPopupViewController *addLabelViewController = [[AddLabelPopupViewController alloc] init];
    addLabelViewController.delegate = self;

    [self presentModalViewController:addLabelViewController animated:YES];
    [addLabelViewController release];
}

#pragma mark LockScreenDelegate protocols
-(void)userUnlockedScreen {
    
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark AddLabelDelegate protocol
-(void)userEnteredLabelOrNil:(NSString *)newLabel {
    
    if (newLabel != nil) {
        
        [labels addLabel:newLabel];
        [myTableView reloadData];
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

    if (section == 0) {
        
        return @"Select your current activity:";
    
    } else {
        
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [labels count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    cell.textLabel.text = [NSString stringWithFormat:@"%2d - %@", indexPath.row, [labels getNameForLabelAtIndex:indexPath.row]];
    //cell.textLabel.textColor = [UIColor whiteColor];
    
    //Due to recycling of the cells, we need to uncheck the cell if it is not the current label.
    //Otherwise, the checkmark may appear on a cell, although it is not the current label.
    if (indexPath.row == [labels currentLabel]) {
        
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark]; 
    
    } else {
        
        [cell setAccessoryType:UITableViewCellAccessoryNone]; 
    }
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //the default label may not be deleted
    if (indexPath.row == 0 || ![labels mutable]) {
        
        return UITableViewCellEditingStyleNone;
    
    } else {
        
        return UITableViewCellEditingStyleDelete;
    }
}


 //support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Delete the row from the data source
        [labels removeLabelAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        //reload for correct numbering of the items
        [tableView reloadData];
    }
}


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //try to set the label, setting the checkmark is done in didReceiveChangeToLabel:, 
    //since the label may have been changed by streaming client
    [labels setCurrentLabel:indexPath.row];
    
    //deselect the currently selected row (=makes the blue background color of the cell disappear)
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - subset of Listener protocol
-(void)didReceiveChangeToLabel:(int)label timestamp:(NSTimeInterval)timestamp {
    
    //uncheck the old entry
    UITableViewCell *oldCell = [myTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:lastLabel inSection:0]];
    [oldCell setAccessoryType:UITableViewCellAccessoryNone];
    
    lastLabel = label;
    
    //add checkmark to the new entry
    NSIndexPath *newCellPosition = [NSIndexPath indexPathForRow:label inSection:0];
    UITableViewCell *newCell = [myTableView cellForRowAtIndexPath:newCellPosition];
    [newCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    
    //scroll into visibility
    [myTableView scrollToRowAtIndexPath:newCellPosition
                               atScrollPosition:UITableViewScrollPositionNone
                                       animated:YES];

}


@end
