//
//  AudioInput.m
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 10.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AudioInput.h"
#import "Preferences.h"

NSString* const AudioInputAvailabilityChangedNotification = @"AudioInputBecameAvailableNotification";

#pragma mark callbacks

//audio session property listener callback
static void audioRouteChanged (
                         void                    *inClientData,
                         AudioSessionPropertyID  inID,
                         UInt32                  inDataSize,
                         const void              *inData
                               ) {
   
    // This callback, being outside the implementation block, needs a reference to the 
	//	AudioInput object -- which it gets via the inUserData parameter.
	AudioInput *audioInput = (AudioInput *) inClientData;
    
    if (inID == kAudioSessionProperty_AudioRouteChange) {
        
        CFNumberRef reason = CFDictionaryGetValue(inData, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
        CFStringRef oldRoute = CFDictionaryGetValue(inData, CFSTR(kAudioSession_AudioRouteChangeKey_OldRoute));
        
        UInt32 propertySize = 0;
        AudioSessionGetPropertySize(kAudioSessionProperty_AudioRoute, &propertySize);
        CFStringRef newRoute = NULL;
        
        AudioSessionGetProperty (
                                 kAudioSessionProperty_AudioRoute,
                                 &propertySize,
                                 &newRoute
                                 );
        
        [audioInput audioRouteChangedFrom:(NSString *) oldRoute
                                       to:(NSString *) newRoute
                                forReason:(NSNumber *) reason];
    }
}

// Audio queue poperty callback function, called when an audio queue running state changes.
static void runningStateChanged (
                                 void					*inUserData,
                                 AudioQueueRef			queueObject,
                                 AudioQueuePropertyID	propertyID
                                 ) {
    //ToDo: find something useful to do here
}

int gapCounter = 0;

// Audio queue recording callback
static void recordingCallback (
							   void                                 *inUserData,
							   AudioQueueRef						inAudioQueue,
							   AudioQueueBufferRef					inBuffer,
							   const AudioTimeStamp                 *inStartTime,
							   UInt32								inNumPackets,
							   const AudioStreamPacketDescription	*inPacketDesc
                               ) {
	
    // This callback, being outside the implementation block, needs a reference to the 
	//	AudioInput object -- which it gets via the inUserData parameter.
	AudioInput *audioInput = (AudioInput *) inUserData;
    
    //we are not in the main thread
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    BOOL useSoundBits = USE_SOUNDBITS ? YES : NO;
    
    //is there any audio data
    if (inNumPackets > 0) {
        
        if (useSoundBits) {
            
            // we record only sound bits for privacy reasons - 1 buffer gets written to file and (kSoundBitPortion - 1) are being left out
            if ( ++gapCounter % kSoundBitPortion == 0 ) {

                [audioInput didReceiveNewAudioBuffer:inBuffer 
                                 withNumberOfPackets:inNumPackets 
                               andPacketDescription:inPacketDesc];
                
                // reset the gap counter so that we leave out another (kSoundBitPortion - 1) buffers
                gapCounter = 0;
            }
            
        } else { // we record complete audio
            
            [audioInput didReceiveNewAudioBuffer:inBuffer 
                             withNumberOfPackets:inNumPackets 
                           andPacketDescription:inPacketDesc];
        }
    }
    
    // if not stopping, re-enqueue the buffer so that it can be filled again
    if (audioInput.isActive) {
        
        AudioQueueEnqueueBuffer (
                                 inAudioQueue,
                                 inBuffer,
                                 0,
                                 NULL
                                 );
    }
    [pool release];
}


//anonymous category extending the class with "private" methods
@interface AudioInput () 

- (void) setupAudioFormat;
- (void) setupRecording;
- (void) setLevelMetering;

@end


@implementation AudioInput

@synthesize hardwareSampleRate;
@synthesize levelMeteringEnabled;

static AudioInput *sharedSingleton;

+(AudioInput *)sharedInstance {
    
    return sharedSingleton;
}


#pragma mark -
#pragma mark initialization methods

//Is called by the runtime in a thread-safe manner exactly once, before the first use of the class.
//This makes it the ideal place to set up the singleton.
+ (void)initialize
{
	//is necessary, because +initialize may be called directly
    static BOOL initialized = NO;
    
	if(!initialized)
    {
        initialized = YES;
        sharedSingleton = [[AudioInput alloc] init];
    }
}

- (id) init {
	
    self = [super init];
	
    if (self != nil) {
        
        interruptedDuringRecording = NO;
        levelMeteringEnabled = NO;
        
        //initialize the audio session
        AudioSessionInitialize ( NULL, NULL, NULL, self);
        
        //set as AVAudioSession delegate, in order to listen to audio input availability changes and audio session interruptions
        [[AVAudioSession sharedInstance] setDelegate:self];
        
        //listen for changes in the audio route
        AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange,
                                        audioRouteChanged,
                                        self);
        
        //define intentions: record audio, mute any playback
        UInt32 sessionCategory = kAudioSessionCategory_RecordAudio;
        AudioSessionSetProperty (
                                 kAudioSessionProperty_AudioCategory,
                                 sizeof (sessionCategory),
                                 &sessionCategory
                                 );
        
        //(dis)allow Bluetooth devices as input
        UInt32 allowBluetoothInput = 0;
        AudioSessionSetProperty (
                                 kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
                                 sizeof (allowBluetoothInput),
                                 &allowBluetoothInput
                                 );
            
        //check for availability of audio input
        [self isAvailable];
            
        [self setupAudioFormat];
        
        // allocate memory to hold audio level values
		audioLevels = calloc (audioFormat.mChannelsPerFrame, sizeof (AudioQueueLevelMeterState));
		
        //listen for changes of the audio queue's running state
		AudioQueueAddPropertyListener (
									   queueObject,
									   kAudioQueueProperty_IsRunning,
									   runningStateChanged,
									   self
									   );
	}
	return self;
}

-(void)dealloc {
    
    //also frees the audio buffers
    AudioQueueDispose (
					   queueObject,
					   TRUE
					   );
    free(audioLevels);
    [super dealloc];
    
}


#pragma mark -
#pragma mark Overriding AbstractSensor methods

- (BOOL) isAvailable {
    
    return isAvailable = [[AVAudioSession sharedInstance] inputIsAvailable];
}

- (BOOL) isActive {
	
	UInt32		isRunning;
	UInt32		propertySize = sizeof (UInt32);
	OSStatus	result;
	
	result =	AudioQueueGetProperty (
									   queueObject,
									   kAudioQueueProperty_IsRunning,
									   &isRunning,
									   &propertySize
									   );
	
	if (result != noErr) {
		return false;
	} else {
		return isActive = isRunning;
	}
}


- (void)actuallyStart {
    
    if (isAvailable && !self.isActive) {

        // activate the audio session immediately before recording starts
        AudioSessionSetActive (true);
        
        AudioQueueNewInput (
                            &audioFormat,
                            recordingCallback,
                            self,					// userData
                            NULL,					// run loop
                            NULL,					// run loop mode
                            0,						// flags
                            &queueObject
                            );
		
		// get the recording format back from the audio queue's audio converter --
		// the file may require a more specific stream description than was 
		// necessary to create the encoder.
		UInt32 sizeOfRecordingFormatASBDStruct = sizeof (audioFormat);
		
		AudioQueueGetProperty (
							   queueObject,
							   kAudioQueueProperty_StreamDescription,	// this constant is only available in iPhone OS
							   &audioFormat,
							   &sizeOfRecordingFormatASBDStruct
							   );
		
        [self setLevelMetering];
        [self setupRecording];
        
        AudioQueueStart (
                         queueObject,
                         NULL			// start time. NULL means as soon as possible.
                         );
    }
}

- (void)actuallyStop {
    
    if (self.isActive) {
        
        AudioQueueStop (
                        queueObject,
                        FALSE       //TRUE: stop immediately, FALSE: process buffers already enqueued
                        );
        
        //dispose the queue, also frees the audio buffers
        AudioQueueDispose (
                           queueObject,
                           FALSE
                           );
        
        AudioSessionSetActive(false);
    }
}

#pragma mark -
#pragma mark setup methods

// Called if audio input availability changes. Configures the audio data format for recording.
- (void) setupAudioFormat {
    
    // Specify the recording format. Options are:
    //
    //		kAudioFormatLinearPCM
    //		kAudioFormatAppleLossless
    //		kAudioFormatAppleIMA4
    //		kAudioFormatiLBC
    //		kAudioFormatULaw
    //		kAudioFormatALaw
    UInt32 formatID = kAudioFormatLinearPCM;
    
	// Obtains the hardware sample rate for use in the recording
	// audio format. Each time the audio route changes, the sample rate
	// needs to get updated.
	UInt32 propertySize = sizeof (hardwareSampleRate);
	
	AudioSessionGetProperty (
							 kAudioSessionProperty_CurrentHardwareSampleRate,
							 &propertySize,
							 &hardwareSampleRate
							 );
	
#if TARGET_IPHONE_SIMULATOR
	audioFormat.mSampleRate = 44100.0;
#else
	audioFormat.mSampleRate = hardwareSampleRate;
#endif
	
	audioFormat.mFormatID			= formatID;
	audioFormat.mChannelsPerFrame	= 1;
	
	if (formatID == kAudioFormatLinearPCM) {
		
		audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
		audioFormat.mFramesPerPacket	= 1;
		audioFormat.mBitsPerChannel		= 16;
		audioFormat.mBytesPerPacket		= 2;
		audioFormat.mBytesPerFrame		= 2;
	}
}

//allocates and enqueues audio buffers to record to
- (void) setupRecording {
   	
    // allocate and enqueue buffers
	int bufferByteSize = kBufferByteSize;		// this is the maximum buffer size used by the player class (64 * 1024)
	int bufferIndex;
	
	for (bufferIndex = 0; bufferIndex < kNumberAudioDataBuffers; ++bufferIndex) {
		
		AudioQueueBufferRef buffer;
		
		AudioQueueAllocateBuffer (
								  queueObject,
								  bufferByteSize, &buffer
								  );
		
		AudioQueueEnqueueBuffer (
								 queueObject,
								 buffer,
								 0,
								 NULL
								 );
	} 
}


#pragma mark -
#pragma mark Audio specific methods

//called by audioRouteChanged property listener callback when the audio route changes
- (void) audioRouteChangedFrom:(NSString *)oldRoute to:(NSString *)newRoute forReason:(NSNumber *)reason {
    
    NSString *explanation;
    
    switch ([reason intValue]) {
        
        case kAudioSessionRouteChangeReason_Unknown:
            explanation = @"unknown";
            break;
        case kAudioSessionRouteChangeReason_NewDeviceAvailable:
            explanation = @"new device available";
            break;
        case kAudioSessionRouteChangeReason_OldDeviceUnavailable:
            explanation = @"old device unavailable";
            break;
        case kAudioSessionRouteChangeReason_CategoryChange:
            explanation = @"audio session category changed";
            break;
        case kAudioSessionRouteChangeReason_Override:
            explanation = @"audio route has been overridden";
            break;
        case kAudioSessionRouteChangeReason_WakeFromSleep:
            explanation = @"device woke up from sleep";
            break;
        case kAudioSessionRouteChangeReason_NoSuitableRouteForCategory:
            explanation = @"no audio hardware route for the audio session category";
            break;
        default:
            explanation = @"undefined";
            break;
    }
    
    NSLog(@"Audio route changed from %@ to %@, reason: %@.", oldRoute, newRoute, explanation);
    
    //ToDo: find something useful to do here.
    
    /* This method is also invoked when the Audio Session category changes, filtering for interesting events needs to be done. 
     * If the audio input hardware changes, the audio queue still is functional and even seems to keep
     * its sample rate (interpolation?). One could check for changes of the native sample rate of the respective
     * hardware and restart the audio queue with updated settings. While this seems to work with recording to a CAF container,
     * other containers may have problems with different sample rates in one file. In this case, FileWriter needs
     * to be notified and its implementation adapted.
     */
}

//called by recording callback
- (void) didReceiveNewAudioBuffer:(AudioQueueBufferRef)buffer withNumberOfPackets:(UInt32)number andPacketDescription:(const AudioStreamPacketDescription *)description {
    
    NSTimeInterval timestamp = [self getTimestamp];
    
    //mutex allows adding/removing of listeners while being active
    dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_FOREVER);
    
        for (id<Listener> listener in listeners) {
            
            [listener didReceiveNewAudioBuffer:buffer
                                       inQueue:queueObject
                               withAudioFormat:audioFormat
                           withNumberOfPackets:number 
                         withPacketDescription:description
                                        atTime:timestamp];
        }
    
    dispatch_semaphore_signal(listenersSemaphore);
}

//Tells the audio queue (not) to provide audio level information, according
//to the value of levelMeteringEnabled.
- (void) setLevelMetering {
	
    UInt32 value = self.levelMeteringEnabled ? 1 : 0;
	
	AudioQueueSetProperty (
						   queueObject,
						   kAudioQueueProperty_EnableLevelMetering,
						   &value,
						   sizeof (UInt32)
						   );
}

//Overriding the synthesized setter. Sets the variable and tells the audio queue to behave as specified.
- (void) setLevelMeteringEnabled:(BOOL)beOn {
    
    if (levelMeteringEnabled != beOn) {
     
        levelMeteringEnabled = beOn;
        [self setLevelMetering];
    }
}

// gets audio levels from the audio queue object, to 
// display using the bar graph in the application UI
- (void) getAudioLevels: (Float32 *) levels peakLevels: (Float32 *) peakLevels {
	
	UInt32 propertySize = sizeof(audioLevels);
	
	AudioQueueGetProperty (
						   queueObject,
                           kAudioQueueProperty_CurrentLevelMeter,
						   audioLevels,
						   &propertySize
						   );
	
	levels[0]		= audioLevels[0].mAveragePower;
	peakLevels[0]	= audioLevels[0].mPeakPower;
}

#pragma mark -
#pragma mark AVAudioSessionDelegate implementation

//called, when the audio session is interrupted (e.g. by a phone call)
- (void) beginInterruption {
    
    if (self.isActive) {
        
        interruptedDuringRecording = YES;
        AudioQueuePause(queueObject);
        
        NSLog(@"AudioInput got interrupted.");
    }
}

//called, when the interruption ends
- (void) endInterruptionWithFlags:(NSUInteger)flags {
    
    // Test if the interruption that has just ended was one from which this app 
    //    should resume recording.
    if (flags & AVAudioSessionInterruptionFlags_ShouldResume) {
        
        if (interruptedDuringRecording) {
            
            interruptedDuringRecording = NO;
            
            //start the paused audio queue again
            AudioQueueStart (queueObject,
                             NULL			// start time. NULL means as soon as possible.
                             );
           
            NSLog(@"AudioInput did recover from interruption");
        }
    }
}

- (void) inputIsAvailableChanged:(BOOL)isInputAvailable {
    
    isAvailable = isInputAvailable;
    
    if (isAvailable) {
       
        //update the audio format due to different audio hardware properties
        [self setupAudioFormat];
    }
    NSLog(@"Audio input became %@available!", isAvailable?@"":@"un");
    [[NSNotificationCenter defaultCenter] postNotificationName:AudioInputAvailabilityChangedNotification object:self];
}


@end
