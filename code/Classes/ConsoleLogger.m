//
//  ConsoleLogger.m
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 06.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ConsoleLogger.h"


@implementation ConsoleLogger

-(void)didReceiveAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z timestamp:(NSTimeInterval)timestamp label:(int)label  skipCount:(NSUInteger)skipCount {
	
    NSLog(@"    Acc: %10.3f  %f  %f  %f  %i %i", timestamp, x, y, z, label, skipCount);
}
-(void)didReceiveGyroscopeValueWithX:(double)x Y:(double)y Z:(double)z roll:(double)roll pitch:(double)pitch yaw:(double)yaw quaternion:(CMQuaternion)quaternion timestamp:(NSTimeInterval)timestamp label:(int)label skipCount:(NSUInteger)skipCount {
   
    NSLog(@"   Gyro: %10.3f  %i  %f  %f  %f  %f  %f  %f  %f  %f  %f  %f  %i", timestamp, skipCount, x, y, z, roll, pitch, yaw, quaternion.x, quaternion.y, quaternion.z, quaternion.w, label);
}

-(void)didReceiveChangeToLabel:(int)label timestamp:(NSTimeInterval)timestamp {
    
    NSLog(@"  Label: %10.3f  %i", timestamp, label);
}

-(void)didReceiveGPSvalueWithLongitude:(double)longitude latitude:(double)latitude altitude:(double)altitude speed:(double)speed course:(double)course horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy timestamp:(NSTimeInterval)timestamp label:(int)label {

    NSLog(@"    GPS: %10.3f %f  %f  %f  %f  %f  %f  %f  %i", timestamp, longitude, latitude, altitude, speed, course, horizontalAccuracy, verticalAccuracy, label);
}

-(void)didReceiveCompassValueWithMagneticHeading:(double)magneticHeading trueHeading:(double)trueHeading headingAccuracy:(double)headingAccuracy X:(double)x Y:(double)y Z:(double)z timestamp:(NSTimeInterval)timestamp label:(int)label {

    NSLog(@"Compass: %10.3f  %f  %f  %f  %f  %f  %f  %i", timestamp, magneticHeading, trueHeading, headingAccuracy, x, y, z, label);
}

-(void)didReceiveWifiList:(NSArray *)list scanBegan:(NSTimeInterval)beginning scanEnded:(NSTimeInterval)end label:(int)label {
#ifndef APP_STORE    
    NSMutableString *summary = [NSMutableString stringWithFormat:@"   WiFi: Found %i networks in %1.3f seconds: ", [list count], end - beginning];
    
    for (NSDictionary *item in list) {
    
        [summary appendFormat:@"%@, ", [item objectForKey:@"SSID_STR"]];
    }
    
    NSLog(@"%@", summary);
#endif
}

- (void)didReceiveNewAudioBuffer:(AudioQueueBufferRef)buffer inQueue:(AudioQueueRef)queue withAudioFormat:(AudioStreamBasicDescription)format withNumberOfPackets:(UInt32)number withPacketDescription:(const AudioStreamPacketDescription *)description atTime:(NSTimeInterval)timestamp {
    
    NSLog(@" Audio: %10.3f buffer size=%lu, sample rate=%5.1f", timestamp, buffer->mAudioDataByteSize, format.mSampleRate);
}

@end
