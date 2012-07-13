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
//  PacketEncoderDecoder.h
//  snsrlog
//
//  Created by Benjamin Thiel on 23.04.11.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CMMotionManager.h>

//Bonjour-name of the service advertised
#define SESSIONID @"snsrlog"

typedef enum {
	
    Off,
    NetworkUnavailable,
    Disconnected,
    Connecting,
	Connected
    
} ConnectionState;

typedef enum {
    
    //sensor values
    AccelerometerValue,
    GpsValue,
    CompassValue,
    ChangeToLabel,
    ListOfLabels,
    
    //commands with values
    ChangeLabelTo = 50,
    
    //start commands
    StartAccelerometer = 100,
    StartGyroscope,
    StartCompass,
    StartGPS,
    RequestListOfLabelsAndCurrentLabel,
    
    //stop commands
	StopAccelerometer = 150,
    StopGyroscope,
    StopCompass,
    StopGPS

} PacketType;

//packet header type
typedef uint8_t header_t;	//"256 values ought to be enough for anybody!" hahaha 


@protocol PacketEncoderDecoderDataReceiveDelegate

-(void)didReceiveAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z skipCount:(long)skipCount;

-(void)didReceiveChangeToLabel:(int)label;

-(void)didReceiveListOfLabels:(NSArray *)labels;

-(void)didReceiveGPSvalueWithLongitude:(double)longitude latitude:(double)latitude altitude:(double)altitude speed:(double)speed course:(double)course horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy timestamp:(double)timestamp;

-(void)didReceiveCompassValueWithMagneticHeading:(double)magneticHeading trueHeading:(double)trueHeading headingAccuracy:(double)headingAccuracy x:(double)x y:(double)y z:(double)z;

@end


@protocol PacketEncoderDecoderCommandsReceiveDelegate

-(void)didReceiveCommand:(PacketType)command;

-(void)didReceiveCommandToChangeLabelTo:(int)label;

@end

//NSData objects encoded/decoded with this class basically consist of a header of "PacketType",
//followed by the respective integer types in little endian and the doubles in a -- according to Apple --
//"platform-independant" representation (presumably big endian?)
@interface PacketEncoderDecoder : NSObject {
	
}

+(NSMutableData *)encodeAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z skipCount:(long)skipCount;
+(void)appendAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z skipCount:(long)skipCount ToPacket:(NSMutableData *)packet;

+(NSData *)encodeChangeToLabel:(int)label;

+(NSData *)encodeListOfLabels:(NSArray *)labels;

+(NSData *)encodeGPSvalueWithLongitude:(double)longitude latitude:(double)latitude altitude:(double)altitude speed:(double)speed course:(double)course horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy timestamp:(NSTimeInterval)timestamp;

+(NSData *)encodeCompassValueWithMagneticHeading:(double)magneticHeading trueHeading:(double)trueHeading headingAccuracy:(double)headingAccuracy x:(double)x y:(double)y z:(double)z;

+(NSData *)encodeCommand:(PacketType)command;

+(NSData *)encodeCommandToChangeLabelTo:(int)label;

+(void)decodePacket:(NSData*)data delegateCommandsTo:(id<PacketEncoderDecoderCommandsReceiveDelegate>)commandsDelegate delegateDataTo:(id<PacketEncoderDecoderDataReceiveDelegate>)dataDelegate;

@end
