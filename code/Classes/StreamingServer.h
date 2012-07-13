//
//  StreamingServer.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 23.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "Listener.h"
#import "PacketEncoderDecoder.h"

//we package more than one value per packet to reduce transmission overhead
#define kAccelerometerValuesPerPacket 6

@protocol StreamingServerDelegate <NSObject>

-(void)serverStatusChanged;

@end

@interface StreamingServer : NSObject <Listener, GKSessionDelegate, PacketEncoderDecoderCommandsReceiveDelegate> {

	GKSession *p2pSession;
	ConnectionState connectionState;
    
    //the clients to send the data to
    NSMutableArray *receivers;
    
    //necessary because both sensors are handled in the same CompassAndGPS object
    BOOL transmitGPS, transmitCompass;
    
    //counter
    int numberOfAcceleromterValuesAlreadyEncoded;
    
    dispatch_queue_t accelerometerSendingQueue;
}

@property (nonatomic, retain) NSString *currentClientScreenName;
@property (nonatomic, retain) NSString *currentClientID;
@property (readonly) ConnectionState connectionState;

@property (assign) id<StreamingServerDelegate> delegate;

//singleton
+(StreamingServer *) sharedInstance;

- (void) start;
- (void) stop;
- (BOOL) isStarted;

@end




