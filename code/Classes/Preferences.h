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
//  Preferences.h
//  snsrlog
//
//  Created by Benjamin Thiel on 10.03.11.
//
#import <Foundation/Foundation.h>

#define MY_PRODUCT_NAME @"snsrlog"

// ########################### AUDIO RECORDING ##################################
#define USE_SOUNDBITS 0

// the ratio of the sound bits - e.g. '5' means recording one
// fifth of the incoming buffers
#define kSoundBitPortion 5

// we have to use different settings for sound bit recording and
// complete audio recording
#if USE_SOUNDBITS == 1

// the number of buffers that are available for audio data 
// during the recording
#define kNumberAudioDataBuffers	20

// the size of each audio buffer
#define kBufferByteSize 4 * 1024

#else
/*
 These parameters have the same meaning as those used for the
 sound bit recording. However, for recording complete audio
 we need less buffers that are greater in size.
 */
#define kNumberAudioDataBuffers 3
#define kBufferByteSize 64 * 1024
#endif

//NOTE: These keys need to be kept in sync with Root.plist (and other plists in the settings bundle)!
extern NSString* const kAccelerometerOn;
extern NSString* const kGpsOn;
extern NSString* const kCompassOn;
extern NSString* const kMicrophoneOn;
extern NSString* const kGyroscopeOn;

extern NSString* const kShowAccelerometer;
extern NSString* const kShowGyroscope;
extern NSString* const kShowGps;
extern NSString* const kShowCompass;
extern NSString* const kShowMicrophone;

extern NSString* const kRecordAccelerometer;
extern NSString* const kRecordGyroscope;
extern NSString* const kRecordGps;
extern NSString* const kRecordCompass;
extern NSString* const kRecordMicrophone;

extern NSString* const kStreamAccelerometer;
extern NSString* const kStreamGyroscope;
extern NSString* const kStreamGps;
extern NSString* const kStreamCompass;

extern NSString* const kAccelerometerFrequency;

extern NSString* const kLabels;

@interface Preferences : NSObject {

}

/* Loads user preferences database from Settings.bundle plists.
 * This needs to be done every time the app launches. NSUserDefaults looks up
 * values for the keys in the application domain (= changes made by the user),
 * which is persitent, first. In case of not finding the value it looks in the
 * registration domain, which should contain default values, is non-persistent
 * and hence initialized in this method.
 */
+(void)registerDefaults;

@end
