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
//  FileWriter.m
//  snsrlog
//
//  Created by Benjamin Thiel on 14.03.11.
//

#import "FileWriter.h"
#import "Preferences.h"
#import "Labels.h"

NSString* const FileWriterRecordingStatusChangedNotification = @"FileWriterRecordingStatusChangedNotification";

NSString* const kAccelerometerFileAppendix = @"_Accel";
NSString* const kGyroscopeFileAppendix = @"_Gyro";
NSString* const kAudioFileAppendix = @"_Sound";
NSString* const kAudioTimestampFileAppendix = @"_SoundTimeStamps";
NSString* const kCompassFileAppendix = @"_Comp";
NSString* const kGpsFileAppendix = @"_GPS";
NSString* const kLabelFileAppendix = @"_Labels";

//anonymous category extending the class with "private" methods
//MARK: private methods
@interface FileWriter ()

@property(nonatomic) BOOL useHighPassFilter;

@property(nonatomic, retain) NSString *currentRecordingDirectory;
@property(nonatomic, retain) NSString *accelerometerFileName;
@property(nonatomic, retain) NSString *gpsFileName;
@property(nonatomic, retain) NSString *gyroFileName;
@property(nonatomic, retain) NSString *labelLogFileName;
@property(nonatomic, retain) NSString *compassFileName;
@property(nonatomic, retain) NSString *audioTimestampFileName;
@property(nonatomic, retain) NSURL *audioFileURL;

-(NSString *)initTextFile:(FILE **)file withBaseFileName:(NSString *)baseFileName appendix:(NSString *)appendix dataDescription:(NSString *) description subtitle:(NSString *) subtitle columnDescriptions:(NSArray *)columnDescriptions;

- (void)initAccelerometerFile:(NSString*)name;
- (void)initGpsFile:(NSString*)name;
- (void)initGyroFile:(NSString*)name;
- (void)initCompassFile:(NSString*)name;
- (void)initLabelLog:(NSString*)name;
- (void)initAudioTimestampFile:(NSString*)name;
- (void)initAudioFileWithFileName:(NSString *)name audioFormat:(AudioStreamBasicDescription)format queue:(AudioQueueRef) theQueue;

//audio codecs other than PCM require meta-information about the codec to be written to the audio file
- (void) writeAudioEncoderMagicCookieToFile: (AudioFileID) theFile fromQueue: (AudioQueueRef) theQueue;
@end


@implementation FileWriter

@synthesize isRecording;

@synthesize useHighPassFilter;

@synthesize currentFilePrefix, currentRecordingDirectory;
@synthesize accelerometerFileName;
@synthesize gpsFileName;
@synthesize gyroFileName;
@synthesize labelLogFileName;
@synthesize compassFileName;
@synthesize audioTimestampFileName;
@synthesize audioFileURL;

#pragma mark -
#pragma mark initialization methods
-(id)init {
    
    self = [super init];
    
    if (self != nil) {
        
        //The alloc-inited NSFileManager is thread-safe in contrast to the singleton (see documentation)
        fileManager = [[NSFileManager alloc] init];
    }
    
    return self;
}

-(void)dealloc {
    
    [self stopRecording];
    
    //release by setting to nil with the synthesized (retain)-setter
    self.currentFilePrefix = nil;
    self.accelerometerFileName = nil;
    self.gpsFileName = nil;
    self.gyroFileName = nil;
    self.labelLogFileName = nil;
    self.compassFileName = nil;
    self.audioFileURL = nil;
    self.audioTimestampFileName = nil;
    
    [fileManager release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark recording methods

-(void)startRecording {
    
    if (!isRecording) {
        
        //make labels immutable, because they are written into the file's headers
        [Labels sharedInstance].mutable = NO;
        
        //use the current date and time as a basis for the filename and directory
        NSDate *now = [NSDate date];
       
        //remove colons (which are represented as slashes in HFS+ and vice versa) from the directory name, as they might be interpreted as actual directory seperators
        self.currentFilePrefix = [[now description] stringByReplacingOccurrencesOfString:@":" withString:@"."];
        
        //create a directory for the recordings and the file name
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = [paths lastObject];
        //we're also using the file prefix as the name for our new directory
        self.currentRecordingDirectory = [documentDirectory stringByAppendingPathComponent:self.currentFilePrefix];
        [fileManager createDirectoryAtPath:self.currentRecordingDirectory withIntermediateDirectories:NO attributes:nil error:NULL];
        
        //init the files (and their filenames)
        [self initAccelerometerFile:self.currentFilePrefix];
        [self initGyroFile:self.currentFilePrefix];
        [self initLabelLog:self.currentFilePrefix];
        [self initGpsFile:self.currentFilePrefix];
        [self initCompassFile:self.currentFilePrefix];

        if (USE_SOUNDBITS) [self initAudioTimestampFile:self.currentFilePrefix];
        
        //audio file is initialized lazily, because incoming audio data is needed to set up the file
        isAudioFileInitialized = NO;
        
        //used to determine whether the respective file has been written to
        usedAccelerometer = NO;
        usedGyro = NO;
        usedGPS = NO;
        usedCompass = NO;
        usedAudio = NO;
        
        isRecording = YES;
        
        NSNotification *notification = [NSNotification notificationWithName:FileWriterRecordingStatusChangedNotification
                                                                     object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:notification 
                                                   postingStyle:NSPostWhenIdle];
    }
}

-(void)stopRecording {
    
    if (isRecording) {
        
        isRecording = NO;
        
        //make labels mutable again (until next recording session, because they are written into the file's headers)
        [Labels sharedInstance].mutable = YES;
        
        //close all open files
        fclose(accelerometerFile);
        fclose(gyroFile);
        fclose(gpsFile);
        fclose(compassFile);

        fclose(audioTimestampFile);
        AudioFileClose(audioFileID);
        
        // finish the label file
        fprintf(labelLogFile,"%10.3f\t %i\n", [[NSDate date] timeIntervalSince1970], -1);
        fclose(labelLogFile);
        
        //check for usage of files and delete them if unused
        //no check if label file has been used, it is always kept
        if (!usedAccelerometer) [fileManager removeItemAtPath:self.accelerometerFileName error:NULL];
        if (!usedGyro) [fileManager removeItemAtPath:self.gyroFileName error:NULL];
        if (!usedCompass) [fileManager removeItemAtPath:self.compassFileName error:NULL];
        if (!usedGPS) [fileManager removeItemAtPath:self.gpsFileName error:NULL];
        if (!usedAudio) {
            if (USE_SOUNDBITS) [fileManager removeItemAtPath:self.audioTimestampFileName error:NULL];
            [fileManager removeItemAtURL:audioFileURL error:NULL];
        }
        
        NSNotification *notification = [NSNotification notificationWithName:FileWriterRecordingStatusChangedNotification
                                                                     object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:notification 
                                                   postingStyle:NSPostWhenIdle];
    }
}


#pragma mark -
#pragma mark file initialization methods

//creates "file", returns its "filename" and writes a header to the file containing the information provided in the arguments
-(NSString *)initTextFile:(FILE **)file withBaseFileName:(NSString *)baseFileName appendix:(NSString *)appendix dataDescription:(NSString *) description subtitle:(NSString *) subtitle columnDescriptions:(NSArray *)columnDescriptions {
    

    NSString *fileName = [[baseFileName stringByAppendingString:appendix] stringByAppendingPathExtension:@"txt"];
	NSString *completeFilePath = [currentRecordingDirectory stringByAppendingPathComponent:fileName];
	
	// create the file for the record
	*file = fopen([completeFilePath UTF8String],"a");
	
	// write an initial header
	fprintf(*file, "%% %s recorded with '%s'\n%% \n", [description UTF8String], [MY_PRODUCT_NAME UTF8String]);
	
    if (subtitle) {
        
        fprintf(*file, "%s", [subtitle UTF8String]);
    }
	
	fprintf(*file, "%% \n");
	fprintf(*file, "%% Label description:\n");	
    
    Labels *labels = [Labels sharedInstance];
	for (int i = 0; i < [labels count]; i++) {
		fprintf(*file, "%% \t %i: %s\n", i, [[labels getNameForLabelAtIndex:i] UTF8String]);
	}
	
	fprintf(*file, "%% \n%% Column description:\n");
    
    for (int i = 0; i < [columnDescriptions count]; i++) {
        
        fprintf(*file, "%% \t %i: %s\n", i + 1, [[columnDescriptions objectAtIndex:i] UTF8String]);
    }
	
	fprintf(*file, "%% \n%% \n");
    
    return completeFilePath;
}

- (void)initAccelerometerFile:(NSString*)name {
    
    self.accelerometerFileName = [self initTextFile:&accelerometerFile 
                                   withBaseFileName:name 
                                           appendix:kAccelerometerFileAppendix
                                  dataDescription:@"Accelerometer data"
                                           subtitle:[NSString stringWithFormat:@"%% Sampling frequency: %i Hz\n", [[NSUserDefaults standardUserDefaults] integerForKey:kAccelerometerFrequency]]
                                 columnDescriptions:[NSArray arrayWithObjects:
                                                     @"Seconds.milliseconds since 1970",
                                                     @"Number of skipped measurements",
                                                     @"Acceleration value in x-direction",
                                                     @"Acceleration value in y-direction",
                                                     @"Acceleration value in z-direction",
                                                     @"Label used for the current sample",
                                                     nil]
                                  ];
	
}

- (void)initGyroFile:(NSString*)name {
    
    self.gyroFileName = [self initTextFile:&gyroFile
                         withBaseFileName:name
                                 appendix:kGyroscopeFileAppendix
                          dataDescription:@"Gyrometer data"
                                 subtitle:nil
                       columnDescriptions:[NSArray arrayWithObjects:
                                           @"Seconds.milliseconds since 1970",
                                           @"Number of skipped measurements",
                                           @"Gyro X",
                                           @"Gyro Y",
                                           @"Gyro Z",
                                           @"Roll of the device",
                                           @"Pitch of the device",
                                           @"Yaw of the device",
                                           @"Quaternion X",
                                           @"Quaternion Y",
                                           @"Quaternion Z",
                                           @"Quaternion W",
                                           @"Label used for the current sample",
                                           nil]
                        ];
}

- (void)initLabelLog:(NSString*)name {
    
    self.labelLogFileName = [self initTextFile:&labelLogFile
                              withBaseFileName:name
                                      appendix:kLabelFileAppendix
                               dataDescription:@"Label data"
                                      subtitle:nil
                            columnDescriptions:[NSArray arrayWithObjects:
                                                @"Seconds.milliseconds since 1970",
                                                @"Label used for the current sample",
                                                nil]
                             ];
}

- (void)initGpsFile:(NSString*)name {
	
    self.gpsFileName = [self initTextFile:&gpsFile
                         withBaseFileName:name
                                 appendix:kGpsFileAppendix
                          dataDescription:@"GPS data"
                                 subtitle:nil
                       columnDescriptions:[NSArray arrayWithObjects:
                                           @"Seconds.milliseconds since 1970",
                                           @"Longitude - east/west location measured in degrees (positive values: east / negative values: west)",
                                           @"Latitude - north/south location measured in degrees (positive values: north / negative values: south)",
                                           @"Altitude - hight above sea level measured in meters",
                                           @"Speed - measured in meters per second",
                                           @"Course - direction measured in degrees starting at due north and continuing clockwise (e.g. east = 90) - negative values indicate invalid values",
                                           @"Horizontal accuracy - negative values indicate invalid values",
                                           @"Vertical accuracy - negative values indicate invalid values",
                                           @"Label used for the current sample",
                                           nil]
                        ];	
}

- (void)initCompassFile:(NSString*)name {
    
    self.compassFileName = [self initTextFile:&compassFile
                             withBaseFileName:name
                                     appendix:kCompassFileAppendix 
                              dataDescription:@"Compass data"
                                     subtitle:nil
                           columnDescriptions:[NSArray arrayWithObjects:
                                               @"Seconds.milliseconds since 1970",
                                               @"Magnetic heading in degrees starting at due north and continuing clockwise (e.g. east = 90) - negative values indicate invalid values\n% \t\t NOTE: True heading only provides valid values when GPS is activated at same time!",
                                               @"True heading in degrees starting at due north and continuing clockwise (e.g. east = 90) - negative values indicate invalid values",
                                               
                                               @"Error likelihood - negative values indicate invalid values",
                                               @"Geomagnetic data for the x-axis measured in microteslas",
                                               @"Geomagnetic data for the y-axis measured in microteslas",
                                               @"Geomagnetic data for the z-axis measured in microteslas",
                                               @"Label used for the current sample"
                                               , nil]
                            ];	
}

- (void)initAudioTimestampFile:(NSString *)name {
    
    self.audioTimestampFileName = [self initTextFile:&audioTimestampFile
                                    withBaseFileName:name
                                            appendix:kAudioTimestampFileAppendix
                                     dataDescription:@"Timing information for Sound Bits" 
                                            subtitle:nil
                                  columnDescriptions:[NSArray arrayWithObjects:
                                                      @"Seconds.milliseconds since 1970",
                                                      @"Size of sound buffer (in Bytes)",
                                                      nil]
                                   ];
}

- (void)initAudioFileWithFileName:(NSString *)name audioFormat:(AudioStreamBasicDescription)format queue:(AudioQueueRef) theQueue {
    
    audioFilePacketPosition = 0;
    
	NSString *fileName = [[name stringByAppendingString:kAudioFileAppendix] stringByAppendingPathExtension:@"caf"];
	NSString *completePath = [self.currentRecordingDirectory stringByAppendingPathComponent:fileName];
	
	// create the file URL that identifies the file that the recording audio queue object records into
	self.audioFileURL =	[NSURL fileURLWithPath:completePath
                                   isDirectory:NO];
	
    // create the audio file
    AudioFileCreateWithURL (
                            (CFURLRef) audioFileURL,
                            kAudioFileCAFType,
                            &format,
                            kAudioFileFlags_EraseFile,
                            &audioFileID
                            );		
	
	// copy the cookie first to give the file object as much info as possible about the data going in
	[self writeAudioEncoderMagicCookieToFile: audioFileID fromQueue: theQueue];
}

- (void) writeAudioEncoderMagicCookieToFile: (AudioFileID) theFile fromQueue: (AudioQueueRef) theQueue {
	
	OSStatus	result;
	UInt32		propertySize;
	
	// get the magic cookie, if any, from the converter		
	result =	AudioQueueGetPropertySize (
										   theQueue,
										   kAudioQueueProperty_MagicCookie,
										   &propertySize
										   );
	
	if (result == noErr && propertySize > 0) {
		// there is valid cookie data to be fetched;  get it
		Byte *magicCookie = (Byte *) malloc (propertySize);
		
		AudioQueueGetProperty (
							   theQueue,
							   kAudioQueueProperty_MagicCookie,
							   magicCookie,
							   &propertySize
							   );
		
		// now set the magic cookie on the output file
		AudioFileSetProperty (
							  theFile,
							  kAudioFilePropertyMagicCookieData,
							  propertySize,
							  magicCookie
							  );
		
		free (magicCookie);
	}
}

#pragma mark -
#pragma mark implementation of Listener protocol (writing the data)

-(void)didReceiveAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z timestamp:(NSTimeInterval)timestamp label:(int)label  skipCount:(NSUInteger)skipCount {
    
    if (isRecording) {
        
		//double xVal;
		//double yVal;
		//double zVal;
		
		// If filtering is active, apply a basic high-pass filter to remove the gravity influence from the accelerometer values
		/*if (useHighPassFilter) {
         acceleration[0] = x * kFilteringFactor + acceleration[0] * (1.0 - kFilteringFactor);
         x = x - acceleration[0];
         acceleration[1] = y * kFilteringFactor + acceleration[1] * (1.0 - kFilteringFactor);
         y = y - acceleration[1];
         acceleration[2] = z * kFilteringFactor + acceleration[2] * (1.0 - kFilteringFactor);
         z = z - acceleration[2];
         }*/		
		// write the acceleration data to the file
		fprintf(accelerometerFile,"%10.3f\t %i\t %f\t %f\t %f\t %i\n", timestamp, skipCount, x, y, z, label);
        usedAccelerometer = YES;
	}
    
}

-(void)didReceiveGyroscopeValueWithX:(double)x Y:(double)y Z:(double)z roll:(double)roll pitch:(double)pitch yaw:(double)yaw quaternion:(CMQuaternion)quaternion timestamp:(NSTimeInterval)timestamp label:(int)label skipCount:(NSUInteger)skipCount {
    
    if (isRecording) {
        
		fprintf(gyroFile, "%10.3f\t %i\t %f\t %f\t %f\t %f\t %f\t %f\t %f\t %f\t %f\t %f\t %i\n", timestamp, skipCount, x, y, z, roll, pitch, yaw, quaternion.x, quaternion.y, quaternion.z, quaternion.w, label);
        usedGyro = YES;
        
	}
    
}

-(void)didReceiveChangeToLabel:(int)label timestamp:(NSTimeInterval)timestamp {
    
    if (isRecording) {
        
        fprintf(labelLogFile,"%10.3f\t %i\n", timestamp, label);
    }
}

-(void)didReceiveGPSvalueWithLongitude:(double)longitude latitude:(double)latitude altitude:(double)altitude speed:(double)speed course:(double)course horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy timestamp:(NSTimeInterval)timestamp label:(int)label {
    
    if (isRecording) {
        
        fprintf(gpsFile,"%10.3f\t %f\t %f\t %f\t %f\t %f\t %f\t %f\t %i\n", timestamp, longitude, latitude, altitude, speed, course, horizontalAccuracy, verticalAccuracy, label);
        usedGPS = YES;
    }
    
}

-(void)didReceiveCompassValueWithMagneticHeading:(double)magneticHeading trueHeading:(double)trueHeading headingAccuracy:(double)headingAccuracy X:(double)x Y:(double)y Z:(double)z timestamp:(NSTimeInterval)timestamp label:(int)label {
    
    if (isRecording) {
        
        fprintf(compassFile,"%10.3f\t %f\t %f\t %f\t %f\t %f\t %f\t %i\n", timestamp, magneticHeading, trueHeading, headingAccuracy, x, y, z, label);
        usedCompass = YES;
        
    }
}

- (void) didReceiveNewAudioBuffer:(AudioQueueBufferRef)buffer inQueue:(AudioQueueRef)queue withAudioFormat:(AudioStreamBasicDescription)format withNumberOfPackets:(UInt32)number withPacketDescription:(const AudioStreamPacketDescription *)description atTime:(NSTimeInterval)timestamp {
    
    if (isRecording) {
        
        if (!isAudioFileInitialized) {
            
            [self initAudioFileWithFileName:self.currentFilePrefix audioFormat:format queue:queue];
            isAudioFileInitialized = YES;
        }
        
        
        //write audio buffer
        AudioFileWritePackets (
                               audioFileID,
                               FALSE,
                               buffer->mAudioDataByteSize,
                               description,
                               audioFilePacketPosition,
                               &number,
                               buffer->mAudioData
                               );
        audioFilePacketPosition += number;
        
        //write time stamp
        if (USE_SOUNDBITS) {
            
            fprintf(audioTimestampFile, "%10.3f\t %lu\n", timestamp, buffer->mAudioDataByteSize);
        }
        
        usedAudio = YES;
    }
    
}


@end
