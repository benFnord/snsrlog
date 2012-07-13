//
//  PacketEncoderDecoder.h
//  snsrlog
//
//  Created by Benjamin Thiel on 23.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
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
