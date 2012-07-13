//
//  ArchiveViewController.h
//  snsrlog
//
//  Created by Benjamin Thiel on 23.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ArchiveViewController : UITableViewController {
    
    NSFileManager *fileManager;
    NSString *documentDirectory;
    
    //used to detect recording directories on the basis of their name
    NSRegularExpression *recordingsMatcher;
    NSRange acceptRange;
    
    BOOL fileWriterIsRecording;
    
    //used to load contents lazily on demand
    BOOL needsReload;
}

@property(copy) NSString* currentFileWriterRecordingDirectory;

//notification by FileWriter
-(void)recordingStatusChanged:(NSNotification *)notification;

//invoked by the reload button
-(void)reload;

@end
