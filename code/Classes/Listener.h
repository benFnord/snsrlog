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
//  Listener.h
//  snsrlog
//
//  Created by Benjamin Thiel on 06.03.11.
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

- (void) didReceiveNewAudioBuffer:(AudioQueueBufferRef)buffer inQueue:(AudioQueueRef)queue  withAudioFormat:(AudioStreamBasicDescription)format withNumberOfPackets:(UInt32)number withPacketDescription:(const AudioStreamPacketDescription *)description atTime:(NSTimeInterval)timestamp;

@optional

-(void)didReceiveNewLabelNames:(NSArray *)newLabels;

@end
