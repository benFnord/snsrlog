//
//  StreamingServer.m
//  snsrlog
//
//  Created by Benjamin Thiel on 23.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamingServer.h"
#import <Foundation/Foundation.h>
#import "Accelerometer.h"
#import "Labels.h"
#import "CompassAndGPS.h"
#import "Preferences.h"

@interface StreamingServer ()

@property (retain, nonatomic) NSMutableData *accelerometerPacket;
@property (retain, nonatomic) NSTimer *restartTimer;

-(void)setConnectionState:(ConnectionState) newState;
-(void)removeAsListenerInAllSensors;

@end


@implementation StreamingServer

@synthesize currentClientID, currentClientScreenName;
@synthesize connectionState;

@synthesize delegate;

@synthesize accelerometerPacket;
@synthesize restartTimer;

static StreamingServer *sharedSingleton;

+(StreamingServer *)sharedInstance {
    
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
        sharedSingleton = [[StreamingServer alloc] init];
    }
}

-(id)init {
    
    self = [super init];
    
    if (self != nil) {
        
        //we only want to send to one peer at a time
        receivers = [[NSMutableArray alloc] initWithCapacity:1];
        
        self.delegate = nil;
        
        self.connectionState = Off;
        
        [[Labels sharedInstance] addListener:self];
        
        numberOfAcceleromterValuesAlreadyEncoded = 0;
        
        accelerometerSendingQueue = dispatch_queue_create("Accelerometer sending queue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

-(void)dealloc{

    [[Labels sharedInstance] removeListener:self];
	
    [self stop];
    [receivers release];
    
    dispatch_release(accelerometerSendingQueue);
    
	[super dealloc];
}

#pragma mark -
#pragma mark server methods

- (void) start {
	
	if (connectionState == Off || connectionState == NetworkUnavailable) {
        
        //prevent further automatic restarts
        [self.restartTimer invalidate];
        self.restartTimer = nil;
        
        p2pSession = [[GKSession alloc] initWithSessionID:SESSIONID 
                                              displayName:[UIDevice currentDevice].name 
                                              sessionMode:GKSessionModeServer];
        p2pSession.delegate = self;
        [p2pSession setDataReceiveHandler:self withContext:nil];

		p2pSession.available = YES;  
        
        self.connectionState = Disconnected;
	}
}

- (void) stop {
	
	if (connectionState != Off || self.restartTimer) {
		
        //prevent further automatic restarts
        [self.restartTimer invalidate];
        self.restartTimer = nil;
        
        [self removeAsListenerInAllSensors];
        
        p2pSession.available = NO;
        [p2pSession disconnectFromAllPeers];
        
        p2pSession.delegate = nil;
        [p2pSession setDataReceiveHandler:nil withContext:nil];
        
        [p2pSession release];
        p2pSession = nil;
        
        [receivers removeAllObjects];
        self.currentClientID = nil;
        self.currentClientScreenName = nil;
        
        self.accelerometerPacket = nil;
        numberOfAcceleromterValuesAlreadyEncoded = 0;
        
        self.connectionState = Off;
    }
}

- (BOOL) isStarted {
    
    return (connectionState != Off || self.restartTimer);
}

-(void)setConnectionState:(ConnectionState) newState {
    
    connectionState = newState;
    [self.delegate serverStatusChanged];
}

-(void)removeAsListenerInAllSensors {
    
    [[Accelerometer sharedInstance] removeListener:self];
    [[CompassAndGPS sharedInstance] removeListener:self];
    
    transmitCompass = NO;
    transmitGPS = NO;
}


#pragma mark -
#pragma mark GKSessionDelegate methods

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error{
	
    NSLog(@"Connection with peer %@ failed. Reason: %@", peerID, [error localizedDescription]);
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error{
	
    NSLog(@"StreamingServer failed. Reason: %@",[error localizedDescription]);
    
    [self stop];
    
    //Did the session fail due to Bluetooth and WiFi being turned off?
    if ((error.code == GKSessionCannotEnableError) && [error.domain isEqualToString:GKSessionErrorDomain]) {
        
        self.connectionState = NetworkUnavailable;
        
    }
    
    //try to restart the session later and pray that it works
    self.restartTimer = [NSTimer scheduledTimerWithTimeInterval:30
                                                         target:self
                                                       selector:@selector(start)
                                                       userInfo:nil
                                                        repeats:NO];
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID{
	
    if (connectionState == Disconnected) {
        
        self.connectionState = Connecting;
        
        NSError *error = nil;
        //accept request from anybody
        [p2pSession acceptConnectionFromPeer:peerID error:&error];
        if (error) NSLog(@"Accepting connection request from peer %@ failed. Reason: %@", peerID, [error localizedDescription]);
    
    } else {
        
        [p2pSession denyConnectionFromPeer:peerID]; //we only want one client at a time
    }
}

//also called, when connection is established
- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state{
	
    switch (state) {
            
        case GKPeerStateAvailable: // not connected to session, but available for connectToPeer:withTimeout:
            break;
        case GKPeerStateUnavailable:  // no longer available
            break;
            
        case GKPeerStateConnected: // connected to the session
        
            self.currentClientID = peerID;
            self.currentClientScreenName = [p2pSession displayNameForPeer:peerID];
            
            //set the connection after getting the peerID (-names), so that a view can display those
            self.connectionState = Connected;
            [receivers addObject:currentClientID];
            
            //make session invisible for further clients
            p2pSession.available = NO;
            break;
            
        case GKPeerStateDisconnected: // disconnected from the session
            
            //is the client that disconnected the one we are currently connected to?
            if ([self.currentClientID isEqualToString:peerID]) {
                
                [self removeAsListenerInAllSensors];
                
                self.connectionState = Disconnected;
                [receivers removeObject:currentClientID];
                self.currentClientID = nil;
                self.currentClientScreenName = nil;
                
                //make session visible again for new clients
                p2pSession.available = YES;
            }
            break;
            
        case GKPeerStateConnecting: // waiting for accept, or deny response
            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark GKSession dataHandler
- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context{
	
	if ([peer isEqualToString:self.currentClientID]) {
        
        [PacketEncoderDecoder decodePacket:data
                        delegateCommandsTo:self 
                            delegateDataTo:nil];
    }
}

#pragma mark -
#pragma mark PacketEncoderDecoderDelegate

-(void)didReceiveCommand:(PacketType)command {
    
    switch (command) {
        
        case StartAccelerometer:
            //check for user preferences before complying to the request
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kStreamAccelerometer]) {
                
                [[Accelerometer sharedInstance] addListener:self];
            }
            break;
        
        case StopAccelerometer:
            [[Accelerometer sharedInstance] removeListener:self];
            break;
        
            
        case StartGPS:
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kStreamGps]) {
                
                [[CompassAndGPS sharedInstance] addListener:self];
                transmitGPS = YES;
            }
            break;
        
        case StopGPS:
            if (!transmitCompass) [[CompassAndGPS sharedInstance] removeListener:self];
            transmitGPS = NO;
            break;
        
            
        case StartCompass:
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kStreamCompass]) {
                
                [[CompassAndGPS sharedInstance] addListener:self];
                transmitCompass = YES;
            }
            break;
        
        case StopCompass:
            if (!transmitGPS) [[CompassAndGPS sharedInstance] removeListener:self];
            transmitCompass = NO;
            break;
         
            
        case RequestListOfLabelsAndCurrentLabel:
            [self didReceiveNewLabelNames:[Labels sharedInstance].labels];
            break;
        default:
            break;
    }
}

-(void)didReceiveCommandToChangeLabelTo:(int)label {
    
    [Labels sharedInstance].currentLabel = label;
}

#pragma mark -
#pragma mark Listener protocol -> sending packets
-(void)didReceiveAccelerometerValueWithX:(double)x Y:(double)y Z:(double)z timestamp:(NSTimeInterval)timestamp label:(int)label skipCount:(NSUInteger)skipCount {
    
    //we want this method to return as fast as it can, so we schedule the sending on the queue
    dispatch_async(accelerometerSendingQueue, ^(void) {
    
        if (connectionState == Connected) {
            
            switch (numberOfAcceleromterValuesAlreadyEncoded) {
                    
                case kAccelerometerValuesPerPacket:{//send
                    
                    NSError *error = nil;
                    [p2pSession sendData:self.accelerometerPacket 
                                 toPeers:receivers 
                            withDataMode:GKSendDataUnreliable //send unreliably due to the mass of values
                                   error:&error];
                    
                    if (error) NSLog(@"Sending the packet failed, reason: %@", [error localizedDescription]);
                    
                    numberOfAcceleromterValuesAlreadyEncoded = 0;
                } 
                    //NOTE: no break; here!
                    
                case 0://start new packet
                    self.accelerometerPacket = [PacketEncoderDecoder encodeAccelerometerValueWithX:x
                                                                                                 Y:y
                                                                                                 Z:z
                                                                                         skipCount:skipCount];
                    break;
                    
                default://append
                    [PacketEncoderDecoder appendAccelerometerValueWithX:x
                                                                      Y:y
                                                                      Z:z
                                                              skipCount:skipCount
                                                               ToPacket:self.accelerometerPacket];
                    break;
            }
            numberOfAcceleromterValuesAlreadyEncoded++;
        }
    });
}

-(void)didReceiveGyroscopeValueWithX:(double)x Y:(double)y Z:(double)z roll:(double)roll pitch:(double)pitch yaw:(double)yaw quaternion:(CMQuaternion)quaternion timestamp:(NSTimeInterval)timestamp label:(int)label skipCount:(NSUInteger)skipCount {
    
}

-(void)didReceiveChangeToLabel:(int)label timestamp:(NSTimeInterval)timestamp {
    
    if (connectionState == Connected) {
        
        NSData *packet = [PacketEncoderDecoder encodeChangeToLabel:label];
        
        NSError *error = nil;
        [p2pSession sendData:packet 
                     toPeers:receivers 
                withDataMode:GKSendDataReliable //send reliably, because it is important to know the label change
                       error:&error];
        
        if (error) NSLog(@"Sending the packet failed, reason: %@", [error localizedDescription]);
    }

}

-(void)didReceiveNewLabelNames:(NSArray *)newLabels {
    
    if (connectionState == Connected) {
        
        NSData *packet = [PacketEncoderDecoder encodeListOfLabels:newLabels];
        
        NSError *error = nil;
        [p2pSession sendData:packet 
                     toPeers:receivers 
                withDataMode:GKSendDataReliable //send reliably due to its importance
                       error:&error];
        
        if (error) NSLog(@"Sending the packet failed, reason: %@", [error localizedDescription]);
    }
}

-(void)didReceiveGPSvalueWithLongitude:(double)longitude latitude:(double)latitude altitude:(double)altitude speed:(double)speed course:(double)course horizontalAccuracy:(double)horizontalAccuracy verticalAccuracy:(double)verticalAccuracy timestamp:(NSTimeInterval)timestamp label:(int)label {
    
    if (transmitGPS && (connectionState == Connected)) {
        
        NSData *packet = [PacketEncoderDecoder encodeGPSvalueWithLongitude:longitude
                                                                  latitude:latitude
                                                                  altitude:altitude 
                                                                     speed:speed
                                                                    course:course
                                                        horizontalAccuracy:horizontalAccuracy
                                                          verticalAccuracy:verticalAccuracy
                                                                 timestamp:timestamp];
        
        NSError *error = nil;
        [p2pSession sendData:packet 
                     toPeers:receivers 
                withDataMode:GKSendDataReliable //send reliably due to the values being rarely updated
                       error:&error];
        
        if (error) NSLog(@"Sending the packet failed, reason: %@", [error localizedDescription]);
    }
}

-(void)didReceiveCompassValueWithMagneticHeading:(double)magneticHeading trueHeading:(double)trueHeading headingAccuracy:(double)headingAccuracy X:(double)x Y:(double)y Z:(double)z timestamp:(NSTimeInterval)timestamp label:(int)label {
    
    if (transmitCompass && (connectionState == Connected)) {
        
        NSData *packet = [PacketEncoderDecoder encodeCompassValueWithMagneticHeading:magneticHeading
                                                                         trueHeading:trueHeading
                                                                     headingAccuracy:headingAccuracy
                                                                                   x:x
                                                                                   y:y
                                                                                   z:z];
        
        NSError *error = nil;
        [p2pSession sendData:packet 
                     toPeers:receivers 
                withDataMode:GKSendDataUnreliable //send unreliably due to the mass of values
                       error:&error];
        
        if (error) NSLog(@"Sending the packet failed, reason: %@", [error localizedDescription]);
    }

}

-(void)didReceiveWifiList:(NSArray *)list scanBegan:(NSTimeInterval)beginning scanEnded:(NSTimeInterval)end label:(int)label {
    
}

- (void) didReceiveNewAudioBuffer:(AudioQueueBufferRef)buffer inQueue:(AudioQueueRef)queue  withAudioFormat:(AudioStreamBasicDescription)format withNumberOfPackets:(UInt32)number withPacketDescription:(const AudioStreamPacketDescription *)description atTime:(NSTimeInterval)timestamp {
    
}

@end
