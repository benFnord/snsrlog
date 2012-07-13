//
//  Preferences.h
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 10.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

#define MY_PRODUCT_NAME @"iPhone Logger"

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
extern NSString* const kWifiOn;
extern NSString* const kGyroscopeOn;

extern NSString* const kShowAccelerometer;
extern NSString* const kShowGyroscope;
extern NSString* const kShowGps;
extern NSString* const kShowCompass;
extern NSString* const kShowMicrophone;
extern NSString* const kShowWifi;

extern NSString* const kRecordAccelerometer;
extern NSString* const kRecordGyroscope;
extern NSString* const kRecordGps;
extern NSString* const kRecordCompass;
extern NSString* const kRecordMicrophone;
extern NSString* const kRecordWifi;

extern NSString* const kStreamAccelerometer;
extern NSString* const kStreamGyroscope;
extern NSString* const kStreamGps;
extern NSString* const kStreamCompass;

extern NSString* const kWifiScanInterval;
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
