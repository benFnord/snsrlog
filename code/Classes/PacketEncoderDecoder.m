//
//  PacketEncoderDecoder.m
//  snsrlog
//
//  Created by Benjamin Thiel on 23.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PacketEncoderDecoder.h"

@interface PacketEncoderDecoder ()

+(void)encodeDouble:(double)value into:(NSMutableData *)data;
+(double)decodeDoubleFrom:(NSData *)data atOffset:(int *)offset;

+(void)encodeInt32:(uint32_t)value into:(NSMutableData *)data;
+(uint32_t)decodeInt32From:(NSData *)data atOffset:(int *)offset;

+(void)decodeAccelerometerValuesFrom:(NSData *)data atOffset:(int *)offset delegateTo:(id<PacketEncoderDecoderDataReceiveDelegate>)delegate;

+(void)decodeChangeToLabelFrom:(NSData *)data atOffset:(int *)offset delegateTo:(id<PacketEncoderDecoderDataReceiveDelegate>)delegate;

+(void)decodeListOfLabelsFrom:(NSData *)data atOffset:(int *)offset delegateTo:(id<PacketEncoderDecoderDataReceiveDelegate>)delegate;

+(void)decodeGPSvalueFrom:(NSData *)data atOffset:(int *)offset delegateTo:(id<PacketEncoderDecoderDataReceiveDelegate>)delegate;

+(void)decodeCompassValueFrom:(NSData *)data atOffset:(int *)offset delegateTo:(id<PacketEncoderDecoderDataReceiveDelegate>)delegate;

+(void)decodeCommandToChangeLabelFrom:(NSData *)data atOffset:(int *)offset delegateTo:(id<PacketEncoderDecoderCommandsReceiveDelegate>)delegate;


@end


@implementation PacketEncoderDecoder


+(NSMutableData *)startNewPacketOfType:(PacketType)type withPayloadLength:(int)length{
    
    header_t header = (header_t) type;
    
    NSMutableData *newPacket = [NSMutableData dataWithCapacity:length + sizeof(header_t)];
    [newPacket appendBytes:&header length:sizeof(header)];
    
    return newPacket;
}

//MARK: - value encoding

+(void)encodeDouble:(double)value into:(NSMutableData *)data {
    
    CFSwappedFloat64 swappedValue = CFConvertDoubleHostToSwapped(value);
    [data appendBytes:&swappedValue length:sizeof(CFSwappedFloat64)];
}

/*
 * Returns the decoded value AND increases *offset for the next potential
 * call of a decode... method.
 */
+(double)decodeDoubleFrom:(NSData *)data atOffset:(int *)offset {
    
    NSRange range = {*offset, sizeof(CFSwappedFloat64)};
    *offset += range.length;
    
    CFSwappedFloat64 swappedValue;
    [data getBytes:&swappedValue range:range];
    
    return CFConvertDoubleSwappedToHost(swappedValue);
}

+(void)encodeInt32:(uint32_t)value into:(NSMutableData *)data {
    
    uint32_t swappedValue = CFSwapInt32HostToLittle(value);
    [data appendBytes:&swappedValue length:sizeof(uint32_t)];
}

+(uint32_t)decodeInt32From:(NSData *)data atOffset:(int *)offset {
    
    NSRange range = {*offset, sizeof(uint32_t)};
    *offset += range.length;
    
    uint32_t swappedValue;
    [data getBytes:&swappedValue range:range];
    
    return CFSwapInt32LittleToHost(swappedValue);
}

//MARK: - actual packets

static const int accelerometerPayloadSize = 3 * sizeof(double) + sizeof(uint32_t);

+(NSMutableData *)encodeAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z skipCount:(long)skipCount {
    
    NSMutableData *newPacket = [self startNewPacketOfType:AccelerometerValue
                                        withPayloadLength:accelerometerPayloadSize];
    
    [self appendAccelerometerValueWithX:x Y:y Z:z skipCount:skipCount ToPacket:newPacket];
    
    return newPacket;
}

+(void)appendAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z skipCount:(long)skipCount ToPacket:(NSMutableData *)packet {
    
    [self encodeDouble:x into:packet];
    [self encodeDouble:y into:packet];
    [self encodeDouble:z into:packet];
    [self encodeInt32:skipCount into:packet];

}

+(void)decodeAccelerometerValuesFrom:(NSData *)data atOffset:(int *)offset delegateTo:(id<PacketEncoderDecoderDataReceiveDelegate>)delegate {
 
    double x = [self decodeDoubleFrom:data atOffset:offset];
    double y = [self decodeDoubleFrom:data atOffset:offset];
    double z = [self decodeDoubleFrom:data atOffset:offset];
    uint32_t skipCount = [self decodeInt32From:data atOffset:offset];
    
    [delegate didReceiveAccelerometerValueWithX:x 
                                              Y:y
                                              Z:z 
                                    skipCount:skipCount];
}

//MARK: -
static const int changeToLabelPayloadSize = sizeof(uint32_t);

+(NSData *)encodeChangeToLabel:(int)label {
    
    NSMutableData *newPacket = [self startNewPacketOfType:ChangeToLabel
                                        withPayloadLength:changeToLabelPayloadSize];
    
    [self encodeInt32:label into:newPacket];
    
    return newPacket;
}

+(void)decodeChangeToLabelFrom:(NSData *)data atOffset:(int *)offset delegateTo:(id<PacketEncoderDecoderDataReceiveDelegate>)delegate {
    
    uint32_t label = [self decodeInt32From:data atOffset:offset];
    
    [delegate didReceiveChangeToLabel:label];
}

//MARK: -
+(NSData *)encodeListOfLabels:(NSArray *)labels {
    
    NSData *labelData = [NSKeyedArchiver archivedDataWithRootObject:labels];
    
    NSMutableData *newPacket = [self startNewPacketOfType:ListOfLabels
                                        withPayloadLength:[labelData length]];
    
    [newPacket appendData:labelData];
    
    return newPacket;
}

+(void)decodeListOfLabelsFrom:(NSData *)data atOffset:(int *)offset delegateTo:(id<PacketEncoderDecoderDataReceiveDelegate>)delegate {
    
    NSRange payloadRange;
    payloadRange.location = *offset;
    payloadRange.length = [data length] - *offset;
    
    NSData *payload = [data subdataWithRange:payloadRange];
    
    NSArray *labels = (NSArray *) [NSKeyedUnarchiver unarchiveObjectWithData:payload];
    
    [delegate didReceiveListOfLabels:labels];
}

//MARK: -
static const int gpsPayloadSize = 8 * sizeof(CFSwappedFloat64);

+(NSData *)encodeGPSvalueWithLongitude:(double)longitude latitude:(double)latitude altitude:(double)altitude speed:(double)speed course:(double)course horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy timestamp:(NSTimeInterval)timestamp {
    
    NSMutableData *newPacket = [self startNewPacketOfType:GpsValue
                                        withPayloadLength:gpsPayloadSize];
    
    [self encodeDouble:longitude into:newPacket];
    [self encodeDouble:latitude into:newPacket];
    [self encodeDouble:altitude into:newPacket];
    [self encodeDouble:speed into:newPacket];
    [self encodeDouble:course into:newPacket];
    [self encodeDouble:horizontalAccuracy into:newPacket];
    [self encodeDouble:verticalAccuracy into:newPacket];
    [self encodeDouble:timestamp into:newPacket];
    
    return newPacket;
}

+(void)decodeGPSvalueFrom:(NSData *)data atOffset:(int *)offset delegateTo:(id<PacketEncoderDecoderDataReceiveDelegate>)delegate {
    
    double longitude = [self decodeDoubleFrom:data atOffset:offset];
    double latitude = [self decodeDoubleFrom:data atOffset:offset];
    double altitude = [self decodeDoubleFrom:data atOffset:offset];
    double speed = [self decodeDoubleFrom:data atOffset:offset];
    double course = [self decodeDoubleFrom:data atOffset:offset];
    double horizontalAccuracy = [self decodeDoubleFrom:data atOffset:offset];
    double verticalAccuracy = [self decodeDoubleFrom:data atOffset:offset];
    double timstamp = [self decodeDoubleFrom:data atOffset:offset];
    
    [delegate didReceiveGPSvalueWithLongitude:longitude
                                     latitude:latitude
                                     altitude:altitude
                                        speed:speed
                                       course:course
                           horizontalAccuracy:horizontalAccuracy
                             verticalAccuracy:verticalAccuracy
                                    timestamp:timstamp];
}

//MARK: - 

static const int compassPayloadSize = 6 * sizeof(double);

+(NSData *)encodeCompassValueWithMagneticHeading:(double)magneticHeading trueHeading:(double)trueHeading headingAccuracy:(double)headingAccuracy x:(double)x y:(double)y z:(double)z {
    
    NSMutableData *newPacket = [self startNewPacketOfType:CompassValue
                                        withPayloadLength:compassPayloadSize];
    
    [self encodeDouble:magneticHeading into:newPacket];
    [self encodeDouble:trueHeading into:newPacket];
    [self encodeDouble:headingAccuracy into:newPacket];
    [self encodeDouble:x into:newPacket];
    [self encodeDouble:y into:newPacket];
    [self encodeDouble:z into:newPacket];
    
    return newPacket;
}

+(void)decodeCompassValueFrom:(NSData *)data atOffset:(int *)offset delegateTo:(id<PacketEncoderDecoderDataReceiveDelegate>)delegate {
    
    double magneticHeading = [self decodeDoubleFrom:data atOffset:offset];
    double trueHeading = [self decodeDoubleFrom:data atOffset:offset];
    double headingAccuracy = [self decodeDoubleFrom:data atOffset:offset];
    double x = [self decodeDoubleFrom:data atOffset:offset];
    double y = [self decodeDoubleFrom:data atOffset:offset];
    double z = [self decodeDoubleFrom:data atOffset:offset];
    
    [delegate didReceiveCompassValueWithMagneticHeading:magneticHeading
                                            trueHeading:trueHeading
                                        headingAccuracy:headingAccuracy
                                                      x:x
                                                      y:y 
                                                      z:z];
}

//MARK: -
static const int commandToChangeLabelPayload = sizeof(uint32_t);

+(NSData *)encodeCommandToChangeLabelTo:(int)label {
    
    NSMutableData *newPacket = [self startNewPacketOfType:ChangeLabelTo
                                        withPayloadLength:commandToChangeLabelPayload];
    
    [self encodeInt32:label into:newPacket];
    
    return newPacket;
}

+(void)decodeCommandToChangeLabelFrom:(NSData *)data atOffset:(int *)offset delegateTo:(id<PacketEncoderDecoderCommandsReceiveDelegate>)delegate {
    
    int label = [self decodeInt32From:data atOffset:offset];
    
    [delegate didReceiveCommandToChangeLabelTo:label];
}

//MARK: -
+(NSData *)encodeCommand:(PacketType)command {
    
    return [self startNewPacketOfType:command 
                    withPayloadLength:0];
}


//No decodeCommand, this is done in decodePacket:delegateCommandsTo:delegateDataTo:

+(void)decodePacket:(NSData*)data delegateCommandsTo:(id<PacketEncoderDecoderCommandsReceiveDelegate>)commandsDelegate delegateDataTo:(id<PacketEncoderDecoderDataReceiveDelegate>)dataDelegate {
    
    PacketType header;
    int payloadLength = [data length] - sizeof(header_t);
    
    //data contains a at least a header?
    if (payloadLength >= 0) {
        
        //get the header
        NSRange headerRange = {0, sizeof(header_t)};
        header_t headerValue;
        [data getBytes:&headerValue range:headerRange];
        header = (PacketType) headerValue;
        
        int offset = headerRange.length;
        
        switch (header) {
                
            case AccelerometerValue:
                if ((payloadLength % accelerometerPayloadSize) == 0) {
                    
                    for (int numberOfValues = payloadLength / accelerometerPayloadSize; numberOfValues > 0; numberOfValues--) {
                        
                        [self decodeAccelerometerValuesFrom:data atOffset:&offset delegateTo:dataDelegate];    
                    }
                }
                break;
             
            case GpsValue:
                if (payloadLength == gpsPayloadSize) {
                    
                    [self decodeGPSvalueFrom:data atOffset:&offset delegateTo:dataDelegate];
                }
                break;
            
            case CompassValue:
                if (payloadLength == compassPayloadSize) {
                    
                    [self decodeCompassValueFrom:data atOffset:&offset delegateTo:dataDelegate];
                }
                break;
            
            case ChangeToLabel:
                if (payloadLength == changeToLabelPayloadSize) {
                    
                    [self decodeChangeToLabelFrom:data atOffset:&offset delegateTo:dataDelegate];
                }
                break;
            
            case ListOfLabels:
                if (payloadLength > 0) { //we don't know the size of the label array
                    
                    [self decodeListOfLabelsFrom:data atOffset:&offset delegateTo:dataDelegate];
                }
                break;
            
            //command with payload
            case ChangeLabelTo:
                if (payloadLength == changeToLabelPayloadSize) {
                    
                    [self decodeCommandToChangeLabelFrom:data atOffset:&offset delegateTo:commandsDelegate];
                }
                break;

            //commands without payload
            default:
                
                //is it a command? WARNING: there is no check whether header is actually a member of the PacketType enum
                if (payloadLength == 0) {
                    
                    [commandsDelegate didReceiveCommand:header];
                }
                break;
        }
    }

}

@end
