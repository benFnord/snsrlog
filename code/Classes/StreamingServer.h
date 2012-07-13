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
//  StreamingServer.h
//  snsrlog
//
//  Created by Benjamin Thiel on 23.04.11.
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




