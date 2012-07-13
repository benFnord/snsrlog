//
//  FileWriter.h
//  snsrlog
//
//  Created by Benjamin Thiel on 14.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Listener.h"

// Constant for the high-pass filter.
#define kFilteringFactor 0.1
extern NSString* const FileWriterRecordingStatusChangedNotification;

extern NSString* const kAccelerometerFileAppendix;
extern NSString* const kGyroscopeFileAppendix;
extern NSString* const kAudioFileAppendix;
extern NSString* const kAudioTimestampFileAppendix;
extern NSString* const kCompassFileAppendix;
extern NSString* const kGpsFileAppendix;
extern NSString* const kLabelFileAppendix;

@interface FileWriter : NSObject <Listener> {
    
    BOOL isRecording;
    
    BOOL useHighPassFilter;
    
    //indicate whether the created files have actually been used
    BOOL usedAccelerometer;
	BOOL usedGPS;
	BOOL usedGyro;
	BOOL usedSound;
	BOOL usedCompass;
	BOOL usedWifi;
    BOOL usedAudio;
    int currentWifiRun;
    
    NSFileManager *fileManager;
	
    //text files
	FILE *accelerometerFile;
	FILE *gpsFile;
	FILE *gyroFile;
	FILE *labelLogFile;
	FILE *compassFile;
	FILE *wifiFile;
    FILE *audioTimestampFile;
    
    //audio file
    AudioFileID audioFileID;
    //current position in audio file to write to
    UInt32 audioFilePacketPosition;
    BOOL isAudioFileInitialized;
    
    NSString *currentFilePrefix;
    NSString *currentRecordingDirectory;
	NSString *accelerometerFileName;
	NSString *gpsFileName;
	NSString *gyroFileName;
	NSString *labelLogFileName;
	NSString *compassFileName;
	NSString *wifiFileName;
    NSString *audioTimestampFileName;
    NSURL *audioFileURL;
    
}

@property(nonatomic, readonly) BOOL isRecording;
@property(nonatomic, retain) NSString *currentFilePrefix;

-(void)startRecording;
-(void)stopRecording;


@end
