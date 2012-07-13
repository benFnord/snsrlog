//
//  Listener.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 06.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CMAttitude.h>
#import <AudioToolbox/AudioToolbox.h>


@protocol Listener

-(void)didReceiveAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z timestamp:(NSTimeInterval)timestamp label:(int)label skipCount:(NSUInteger)skipCount;

-(void)didReceiveGyroscopeValueWithX:(double)x Y:(double)y Z:(double)z roll:(double)roll pitch:(double)pitch yaw:(double)yaw quaternion:(CMQuaternion)quaternion timestamp:(NSTimeInterval)timestamp label:(int)label skipCount:(NSUInteger)skipCount;

-(void)didReceiveChangeToLabel:(int)label timestamp:(NSTimeInterval)timestamp;

-(void)didReceiveGPSvalueWithLongitude:(double)longitude latitude:(double)latitude altitude:(double)altitude speed:(double)speed course:(double)course horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy timestamp:(NSTimeInterval)timestamp label:(int)label;

-(void)didReceiveCompassValueWithMagneticHeading:(double)magneticHeading trueHeading:(double)trueHeading headingAccuracy:(double)headingAccuracy X:(double)x Y:(double)y Z:(double)z timestamp:(NSTimeInterval)timestamp label:(int)label;

-(void)didReceiveWifiList:(NSArray *)list scanBegan:(NSTimeInterval)beginning scanEnded:(NSTimeInterval)end label:(int)label;

- (void) didReceiveNewAudioBuffer:(AudioQueueBufferRef)buffer inQueue:(AudioQueueRef)queue  withAudioFormat:(AudioStreamBasicDescription)format withNumberOfPackets:(UInt32)number withPacketDescription:(const AudioStreamPacketDescription *)description atTime:(NSTimeInterval)timestamp;

@optional

-(void)didReceiveNewLabelNames:(NSArray *)newLabels;

@end
