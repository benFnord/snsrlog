//
//  StreamingClient.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 23.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "PacketEncoderDecoder.h"
#import "AbstractSensor.h"

@protocol StreamingClientDelegate <NSObject>

-(void)clientConnectionStatusChanged;
-(void)serverAvailabilityChanged;

@end

@interface StreamingClient : NSObject <GKSessionDelegate> {
	
	GKSession *p2pSession;
	ConnectionState connectionState;
    NSMutableArray *availablePeers;
    NSString *currentServerScreenName;
    NSString *currentServerID;
    
    BOOL receiveAccelerometer;
    BOOL receiveGyroscope;
    BOOL receiveGPS;
    BOOL receiveCompass;
    
    id<StreamingClientDelegate> delegate;
}

@property (nonatomic, retain) NSString *currentServerScreenName;
@property (nonatomic, retain) NSString *currentServerID;
@property (readonly) ConnectionState connectionState;
@property (nonatomic, readonly) NSArray *availablePeers;

@property (nonatomic) BOOL receiveAccelerometer, receiveGyroscope, receiveGPS, receiveCompass;

@property (assign) id<StreamingClientDelegate> delegate;
@property (assign) id<PacketEncoderDecoderDataReceiveDelegate> dataReceiver;

//singleton
+ (StreamingClient *) sharedInstance;

-(void)start;
-(void)stop;

-(BOOL)isStarted;
-(void)connectTo:(NSString *)serverID;
-(void)disconnect;
-(NSString *)displayNameForServer:(NSString *)serverID;

-(void)sendCommand:(PacketType)command;
-(void)sendCommandToChangeLabel:(int)label;

@end
