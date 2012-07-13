//
//  RecordingsFileViewController.h
//  snsrlog
//
//  Created by Benjamin Thiel on 28.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RecordingsFileViewController : UIViewController <UIWebViewDelegate> {
    
    NSString *filePath;
}

@property(retain) IBOutlet UIWebView* webView;
@property(retain) UIActivityIndicatorView *activityIndicator;

-(id)initWithTitle:(NSString *)title showContentsOfFileAtPath:(NSString *)path;

@end
