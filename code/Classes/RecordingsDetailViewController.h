//
//  RecordingsDetailViewController.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 27.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RecordingsDetailViewController : UITableViewController {
    
    NSString *recordingName;
    NSString *recordingDirectory;
    
    NSMutableArray *displayNames;
    NSMutableArray *fileNames;
}

- (id)initWithRecordingName:(NSString *)directoryName displayName:(NSString *)displayName;

@end
