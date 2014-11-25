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
//  FileWriter.h
//  snsrlog
//
//  Created by Benjamin Thiel on 14.03.11.
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
    BOOL usedAudio;
    
    NSFileManager *fileManager;
	
    //text files
	FILE *accelerometerFile;
	FILE *gpsFile;
	FILE *gyroFile;
	FILE *labelLogFile;
	FILE *compassFile;
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
    NSString *audioTimestampFileName;
    NSURL *audioFileURL;
    
}

@property(nonatomic, readonly) BOOL isRecording;
@property(nonatomic, retain) NSString *currentFilePrefix;

-(void)startRecording;
-(void)stopRecording;


@end
