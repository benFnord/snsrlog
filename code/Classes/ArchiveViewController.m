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
//  ArchiveViewController.m
//  snsrlog
//
//  Created by Benjamin Thiel on 23.06.11.
//

#import "ArchiveViewController.h"
#import "RecordingsDetailViewController.h"
#import "FileWriter.h"
#import "sys/param.h"
#import "sys/mount.h"

//MARK: private methods declaration
//determines the order in which the sections appear
//ATTENTION: changes may break calls to [self.tableView reloadSections:(NSIndexSet)...]
enum ArchiveViewControllerSections {
    
    RecordingsSection,
    CurrentRecordingSection,
    StatisticsSection
};

@interface ArchiveViewController ()

@property(retain) NSMutableArray *recordingDirectoryNames, *recordingSizes, *recordingDisplayNames;
@property(retain) NSString *currentRecordingDisplayName, *currentRecordingDisplaySize;

-(void)loadContents;
-(void)releaseContents;

-(unsigned long long)summedSizeOfFilesInDirectory:(NSString *)path;
-(NSString *)humanReadableStringFromFileSize:(float)theSize;
-(unsigned long long)freeDiskSpace;

@end

//MARK: -
@implementation ArchiveViewController

//used to display the name of the recording
@synthesize recordingDisplayNames;
//the size of each recording
@synthesize recordingSizes;
//the actual directory name (used for deleting)
@synthesize recordingDirectoryNames;

@synthesize currentFileWriterRecordingDirectory;
@synthesize currentRecordingDisplayName, currentRecordingDisplaySize;

//MARK: initialization methods
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
        fileManager = [[NSFileManager alloc] init];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentDirectory = [[paths lastObject] retain];
        
        //try to match directories following the naming schema: "YYYY-MM-DD HH.MM.SS", though not checking for valid dates
        NSString *regex = @"^\\d{4}-\\d{2}-\\d{2}\\s\\d{2}\\.\\d{2}\\.\\d{2}";
        //we only accept directories that begin with this schema
        acceptRange = NSMakeRange(0, 19);
        recordingsMatcher = [[NSRegularExpression alloc] initWithPattern:regex
                                                                 options:NSRegularExpressionCaseInsensitive
                                                                   error:NULL];
        //trigger the loading of contents
        needsReload = YES;
        
        //we want to know about the recording status of the FileWriter in order to disallow deletion of a directory currently recorded to
        fileWriterIsRecording = NO;
        self.currentFileWriterRecordingDirectory = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(recordingStatusChanged:)
                                                     name:FileWriterRecordingStatusChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fileManager release];
    [documentDirectory release];
    [recordingsMatcher release];
    self.currentFileWriterRecordingDirectory = nil;
    [self releaseContents];
    
    [super dealloc];
}

- (void)releaseContents {
    
    self.recordingSizes = nil;
    self.recordingDirectoryNames = nil;
    self.recordingDisplayNames = nil;
    self.currentRecordingDisplayName = nil;
    self.currentRecordingDisplaySize = nil;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    [self releaseContents];
    needsReload = YES;
}

//MARK: - own methods

//invoked by reload button
-(void)reload {
    
    [self loadContents];
    [self.tableView reloadData];
}

-(void)recordingStatusChanged:(NSNotification *)notification {
    
    FileWriter *fileWriter = (FileWriter *) [notification object];
    
    fileWriterIsRecording = fileWriter.isRecording;
    
    if (fileWriterIsRecording) {
        
        self.currentFileWriterRecordingDirectory = fileWriter.currentFilePrefix;
    
    } else {
        
        self.currentFileWriterRecordingDirectory = nil;
    }
    
    needsReload = YES;
}

//search for recordings in the document directory and compute their sizes (<- expensive)
- (void)loadContents {

    needsReload = NO;
    
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:documentDirectory error:NULL];
    
    //initialize the arrays
    self.recordingDirectoryNames = [NSMutableArray arrayWithCapacity:[recordingDirectoryNames count]];
    self.recordingDisplayNames = [NSMutableArray arrayWithCapacity:[recordingDirectoryNames count]];
    self.recordingSizes = [NSMutableArray arrayWithCapacity:[recordingDirectoryNames count]];
    
    //iterarte through the document directory
    for (NSString *directoryName in directoryContents) {
        
        NSString *fullPath = [documentDirectory stringByAppendingPathComponent:directoryName];
        
        //check for directory
        BOOL isDirectory = NO;
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        
        //try to match the directory name
        NSRange matchedRange = [recordingsMatcher rangeOfFirstMatchInString:directoryName options:NSMatchingAnchored range:NSMakeRange(0, [directoryName length])];
        
        BOOL seemsToBeArecording = (matchedRange.location == acceptRange.location) && (matchedRange.length == acceptRange.length) && isDirectory;
        
        if (seemsToBeArecording) {
            
            //truncate the string and replace "." with ":" in the recording time
            NSString *displayName = [[directoryName substringToIndex:19] stringByReplacingOccurrencesOfString:@"."
                                                                                                   withString:@":"];
            unsigned long long directorySize = [self summedSizeOfFilesInDirectory:fullPath];
            NSString *displaySize = [self humanReadableStringFromFileSize:(float)directorySize];
            
            //is FileWriter currently recording to that directory?
            if (fileWriterIsRecording && [directoryName isEqualToString:currentFileWriterRecordingDirectory]) {
                
                //don't show it in the RecordingsSection but in CurrentRecordingSection
                self.currentRecordingDisplayName = displayName;
                self.currentRecordingDisplaySize = displaySize;
                
            } else {
                
                [self.recordingDisplayNames addObject:displayName];
                [self.recordingDirectoryNames addObject:fullPath];
                [self.recordingSizes addObject:displaySize];
            }
        }
    }
}

//MARK: - file size methods

//very EXPENSIVE and dumb. there seems to be no other API doing the same job, though.
//Attention: shallow search! This method does not traverse into directories!
-(unsigned long long)summedSizeOfFilesInDirectory:(NSString *)path {
    
    unsigned long long directorySize = 0;
    
    //determine the directory size by adding the file sizes
    for (NSString* fileName in [fileManager contentsOfDirectoryAtPath:path error:NULL]) {
        
        NSString *fullFilePath = [path stringByAppendingPathComponent:fileName];
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:fullFilePath error:NULL];
        directorySize += [attributes fileSize];
    }
    
    return directorySize;
}

//turns out to be quite inaccurate in practice. constantly computes size larger than those
//shown in iTunes and the Preferences app on the device.
-(unsigned long long)freeDiskSpace {
    
    struct statfs tStats;
    
    statfs([documentDirectory UTF8String], &tStats);
    
    return tStats.f_bavail * tStats.f_bsize;
}

- (NSString *)humanReadableStringFromFileSize:(float)theSize
{
	float floatSize = theSize;
	
    if (theSize<1023)
		return([NSString stringWithFormat:@"%i bytes",theSize]);
	
    floatSize = floatSize / 1024;
    if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f KB",floatSize]);
	
    floatSize = floatSize / 1024;
    if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f MB",floatSize]);
	
    floatSize = floatSize / 1024;
	return([NSString stringWithFormat:@"%1.1f GB",floatSize]);
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.title = @"Recordings";
    
    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                                                                  target:self 
                                                                                  action:@selector(reload)];
    self.navigationItem.leftBarButtonItem = reloadButton;
    [reloadButton release];
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
    if (needsReload) [self reload];
    
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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
            
        case StatisticsSection:
            return 1;
        
        case RecordingsSection:
            if (needsReload) [self loadContents];
            return [self.recordingDisplayNames count];
        
        case CurrentRecordingSection:
            return fileWriterIsRecording?1:0;
            
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    switch (section) {
        case StatisticsSection:
            return nil;
            
        case RecordingsSection:
            return nil;
            
        case CurrentRecordingSection:
            return fileWriterIsRecording?@"Currently recording:":nil;
        
        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    
    switch (indexPath.section) {
        
        case StatisticsSection:
            cell.textLabel.text = @"free disk space:";
            cell.detailTextLabel.text = [self humanReadableStringFromFileSize:(float)[self freeDiskSpace]];
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
            
        case RecordingsSection:
            cell.textLabel.text = [recordingDisplayNames objectAtIndex:indexPath.row];
            cell.detailTextLabel.text = [self.recordingSizes objectAtIndex:indexPath.row];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        case CurrentRecordingSection:
            cell.textLabel.text = self.currentRecordingDisplayName;
            cell.detailTextLabel.text = self.currentRecordingDisplaySize;
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
        default:
            break;
    }
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if (indexPath.section == RecordingsSection) {
        
        return YES;
        
    } else {
        
        return NO;
    }
}



//Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        //try to remove the item
        NSError *error = nil;
        [fileManager removeItemAtPath:[self.recordingDirectoryNames objectAtIndex:indexPath.row] error:&error];
        
        if (!error) {
            
            //update the model
            [self.recordingDirectoryNames removeObjectAtIndex:indexPath.row];
            [self.recordingDisplayNames removeObjectAtIndex:indexPath.row];
            [self.recordingSizes removeObjectAtIndex:indexPath.row];
            
            //update the view
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }   
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    
    if (indexPath.section == RecordingsSection) {
        
        NSString *recordingName = [[recordingDirectoryNames objectAtIndex:indexPath.row] lastPathComponent];
        RecordingsDetailViewController *detailViewController = [[RecordingsDetailViewController alloc] initWithRecordingName:recordingName 
                                                                                                                 displayName:[recordingDisplayNames objectAtIndex:indexPath.row]];
        [self.navigationController pushViewController:detailViewController animated:YES];
        [detailViewController release];
        
        //deselecting the row takes place in viewDidAppear
    
    } else {
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
