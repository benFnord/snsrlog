//
//  StreamingMainViewController.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 02.07.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StreamingClient.h"
#import "StreamingServer.h"
#import "BTFancyButton.h"

@interface StreamingMainViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, StreamingClientDelegate, StreamingServerDelegate> {
    
}

@property(nonatomic, retain) IBOutlet BTFancyButton *serverButton;
@property(nonatomic, retain) IBOutlet UILabel *serverStatus;
@property(nonatomic, retain) IBOutlet UITableView *availableServers;

-(IBAction)serverButtonPressed:(BTFancyButton *)sender;

@end
