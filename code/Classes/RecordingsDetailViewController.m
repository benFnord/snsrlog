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
//  RecordingsDetailViewController.m
//  snsrlog
//
//  Created by Benjamin Thiel on 27.06.11.
//

#import "RecordingsDetailViewController.h"
#import "RecordingsFileViewController.h"
#import "MediaPlayer/MPMoviePlayerViewController.h"
#import "MediaPlayer/MPMoviePlayerController.h"
#import "FileWriter.h"

@interface  RecordingsDetailViewController ()

@property(retain) NSMutableArray* displayNames, *fileNames;

-(void)loadContents;

@end

@implementation RecordingsDetailViewController

@synthesize displayNames, fileNames;

- (id)initWithRecordingName:(NSString *)directoryName displayName:(NSString *)displayName
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {

        recordingName = [directoryName copy];
        self.title = displayName;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        recordingDirectory = [[[paths lastObject] stringByAppendingPathComponent:recordingName] retain];
    }
    return self;
}

- (void)dealloc
{
    [recordingName release];
    [recordingDirectory release];
    self.fileNames = nil;
    self.displayNames = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    self.fileNames = nil;
    self.displayNames = nil;
}

-(NSString *)fullPathForFileWithAppendix:(NSString *)appendix andExtension:(NSString *)extension {
    
    NSString *fileName = [[recordingName stringByAppendingString:appendix] stringByAppendingPathExtension:extension];
    NSString *fullPath = [recordingDirectory stringByAppendingPathComponent:fileName];
    
    return fullPath;
}

-(void)loadContents {
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    self.displayNames = [NSMutableArray arrayWithCapacity:7];
    self.fileNames  = [NSMutableArray arrayWithCapacity:7];
    
    NSString *accFile = [self fullPathForFileWithAppendix:kAccelerometerFileAppendix andExtension:@"txt"];
    if ([fileManager fileExistsAtPath:accFile]) {
        
        [displayNames addObject:@"Accelerometer"];
        [fileNames addObject:accFile];
    }
    
    NSString *gyroFile = [self fullPathForFileWithAppendix:kGyroscopeFileAppendix andExtension:@"txt"];
    if ([fileManager fileExistsAtPath:gyroFile]) {
        
        [displayNames addObject:@"Gyroscope"];
        [fileNames addObject:gyroFile];
    }
    
    NSString *compFile = [self fullPathForFileWithAppendix:kCompassFileAppendix andExtension:@"txt"];
    if ([fileManager fileExistsAtPath:compFile]) {
        
        [displayNames addObject:@"Compass"];
        [fileNames addObject:compFile];
    }
    
    NSString *gpsFile = [self fullPathForFileWithAppendix:kGpsFileAppendix andExtension:@"txt"];
    if ([fileManager fileExistsAtPath:gpsFile]) {
        
        [displayNames addObject:@"GPS"];
        [fileNames addObject:gpsFile];
    }
    
    NSString *timestampFile = [self fullPathForFileWithAppendix:kAudioTimestampFileAppendix andExtension:@"txt"];
    if ([fileManager fileExistsAtPath:timestampFile]) {
        
        [displayNames addObject:@"Audio Timestamps"];
        [fileNames addObject:timestampFile];
    }
    
    NSString *audioFile = [self fullPathForFileWithAppendix:kAudioFileAppendix andExtension:@"caf"];
    if ([fileManager fileExistsAtPath:audioFile]) {
        
        [displayNames addObject:@"Audio"];
        [fileNames addObject:audioFile];
    }
    
    NSString *labelFile = [self fullPathForFileWithAppendix:kLabelFileAppendix andExtension:@"txt"];
    if ([fileManager fileExistsAtPath:labelFile]) {
        
        [displayNames addObject:@"Labels"];
        [fileNames addObject:labelFile];
    }
    
    [fileManager release];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadContents];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault
                                                animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //deselect the row upon return from a pushed view controller to give a visual cue of the item selected (standard iOS behaviour)
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    return [displayNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    cell.textLabel.text = [displayNames objectAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == 0) {
        
        return @"Recorded Sensors:";
        
    } else {
        
        return nil;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //textfile? open in webView
    if ([[[fileNames objectAtIndex:indexPath.row] pathExtension] isEqualToString:@"txt"]) {
        
        RecordingsFileViewController *detailViewController = [[RecordingsFileViewController alloc] initWithTitle:[displayNames objectAtIndex:indexPath.row]
                                                                                        showContentsOfFileAtPath:[fileNames objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:detailViewController animated:YES];
        [detailViewController release];
    }
    
    //audio file?
    if ([[[fileNames objectAtIndex:indexPath.row] pathExtension] isEqualToString:@"caf"]) {
        
        NSURL *fileURL = [NSURL fileURLWithPath:[fileNames objectAtIndex:indexPath.row]];
        MPMoviePlayerViewController *detailViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:fileURL];

        /* the system's audio session is set up for recording and not for playback,
         * hence the movie player must use its own audio session (default is YES)
         */
        detailViewController.moviePlayer.useApplicationAudioSession = NO;
        
        [self presentMoviePlayerViewControllerAnimated:detailViewController];
        
        [detailViewController release];
    }
}

@end
