//
//  StreamingClient.m
//  snsrlog
//
//  Created by Benjamin Thiel on 23.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamingClient.h"

//anonymous category extending the class with "private" methods
@interface StreamingClient () 

@property (retain, nonatomic) NSTimer *restartTimer;

- (void) setConnectionState:(ConnectionState)newState;

@end

@implementation StreamingClient

@synthesize availablePeers;
@synthesize currentServerID;
@synthesize currentServerScreenName;
@synthesize connectionState;
@synthesize restartTimer;

@synthesize receiveGPS, receiveCompass, receiveGyroscope, receiveAccelerometer;

@synthesize delegate, dataReceiver;

static StreamingClient *sharedSingleton;

+(StreamingClient *)sharedInstance {
    
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
        sharedSingleton = [[StreamingClient alloc] init];
    }
}

-(id)init {
    
    self = [super init];
    
    if (self != nil) {
        
        p2pSession = nil;
        
        availablePeers = [[NSMutableArray alloc] init];
        
        self.connectionState = Off;
        self.delegate = nil;
        self.dataReceiver = nil;
    }
    
    return self;
}

-(void)dealloc{
    
	[self stop]; //also releases p2pSession
    [availablePeers release];
	[super dealloc];
}


#pragma mark -
#pragma mark managing the session

- (void) start {
	
	if (connectionState == Off || connectionState == NetworkUnavailable) {
        
        //prevent further automatic restarts
        [self.restartTimer invalidate];
        self.restartTimer = nil;
        
        p2pSession = [[GKSession alloc] initWithSessionID:SESSIONID
											  displayName:[UIDevice currentDevice].name 
											  sessionMode:GKSessionModeClient];
        
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
        
        p2pSession.available = NO;
        [p2pSession disconnectFromAllPeers];
        
        p2pSession.delegate = nil;
        [p2pSession setDataReceiveHandler:nil withContext:nil];
        
        [p2pSession release];
        p2pSession = nil;
        
        self.currentServerID = nil;
        self.currentServerScreenName = nil;
        
        [availablePeers removeAllObjects];
        [self.delegate serverAvailabilityChanged];
        
        self.connectionState = Off;
    }
}

-(BOOL)isStarted {
    
    return (connectionState != Off || self.restartTimer);
}

-(void)setConnectionState:(ConnectionState) newState {
    
    connectionState = newState;
    [self.delegate clientConnectionStatusChanged];
}

#pragma mark -
#pragma mark client specific methods

-(void)connectTo:(NSString *)serverID {
    
    if (connectionState == Disconnected) {
        
        self.connectionState = Connecting;
        [p2pSession connectToPeer:serverID withTimeout:10.0];
    }
}

-(void)disconnect {
    
    //we set the connection state manually here,
    //as the delegate does not always seem to be called by GKSession
    self.connectionState = Disconnected;
    [p2pSession disconnectFromAllPeers];
}

-(NSString *)displayNameForServer:(NSString *)serverID {
    
    if (connectionState == Off) {
        
        return nil;
        
    } else {
        
        return [p2pSession displayNameForPeer:serverID];
    }
}

-(void)sendCommand:(PacketType)command {
    
    if (connectionState == Connected) {
        
        NSError *error = nil;
        NSData *packet = [PacketEncoderDecoder encodeCommand:command];
        
        [p2pSession sendData:packet
                     toPeers:[NSArray arrayWithObject:currentServerID]
                withDataMode:GKSendDataReliable
                       error:&error];
        if (error) NSLog(@"error sending command: %@", [error localizedDescription]);
    }
}

-(void)sendCommandToChangeLabel:(int)label {
    
    if (connectionState == Connected) {
        
        NSError *error = nil;
        NSData *packet = [PacketEncoderDecoder encodeCommandToChangeLabelTo:label];
        
        [p2pSession sendData:packet
                     toPeers:[NSArray arrayWithObject:currentServerID]
                withDataMode:GKSendDataReliable
                       error:&error];
        if (error) NSLog(@"error sending command: %@", [error localizedDescription]);
    }
}

//overrides the synthesized setters and sents the appropriate command to the server
-(void)setReceiveAccelerometer:(BOOL)shouldReceiveAccelerometer {
    
    receiveAccelerometer = shouldReceiveAccelerometer;
    
    [self sendCommand:receiveAccelerometer?StartAccelerometer:StopAccelerometer];
}

-(void)setReceiveGyroscope:(BOOL)shouldReceiveGyroscope {
    
    receiveGyroscope = shouldReceiveGyroscope;
    
    [self sendCommand:receiveGyroscope?StartGyroscope:StopGyroscope];
    
}

-(void)setReceiveCompass:(BOOL)shouldReceiveCompass {
    
    receiveCompass = shouldReceiveCompass;
    
    [self sendCommand:receiveCompass?StartCompass:StopCompass];
}

-(void)setReceiveGPS:(BOOL)shouldReceiveGPS {
    
    receiveGPS = shouldReceiveGPS;
    
    [self sendCommand:receiveGPS?StartGPS:StopGPS];
    
}

#pragma mark -
#pragma mark GKSessionDelegate methods

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error{
    
	self.connectionState = Disconnected;
    NSString *errorTitle = [NSString stringWithFormat:@"Connection with \"%@\" Failed", [session displayNameForPeer:peerID]];
    NSString *recoverySuggestion = [error localizedRecoverySuggestion] ? [error localizedRecoverySuggestion] : [error localizedDescription];
    
    NSLog(@"%@ Error: %@", errorTitle, [error localizedDescription]);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle
                                                    message:recoverySuggestion
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error{
	
    NSLog(@"StreamingClient failed. Reason: %@",[error localizedDescription]);
    
    [self stop];
    
    //Did the session fail due to Bluetooth and WiFi being turned off?
    if ((error.code == GKSessionCannotEnableError) && [error.domain isEqualToString:GKSessionErrorDomain]) {
        
        self.connectionState = NetworkUnavailable;
        
    }
    
    //try to restart the session later and pray that it works
    self.restartTimer = [NSTimer scheduledTimerWithTimeInterval:20
                                                         target:self
                                                       selector:@selector(start)
                                                       userInfo:nil
                                                        repeats:NO];
    
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID{
	
    //I INITIATE CONNECTION, Y U NO UNDERSTAND?
    [session denyConnectionFromPeer:peerID];
}


- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state{
	
    switch (state) {
            
        case GKPeerStateAvailable: // not connected to session, but available for connectToPeer:withTimeout:

            if (![availablePeers containsObject:peerID]) {
             
                [availablePeers addObject:peerID];
                [self.delegate serverAvailabilityChanged];
            }
            break;
        
        case GKPeerStateUnavailable:  // no longer available
           
            [availablePeers removeObject:peerID];
            [self.delegate serverAvailabilityChanged];
            break;
            
        case GKPeerStateConnected: // connected to the session
            
            self.currentServerID = peerID;
            self.currentServerScreenName = [p2pSession displayNameForPeer:peerID];
            
            //make session invisible for further clients
            p2pSession.available = NO;
            
            self.connectionState = Connected;
            break;
            
        case GKPeerStateDisconnected: // disconnected from the session
            
            //is the client that disconnected the one we are currently connected to?
            if ([self.currentServerID isEqualToString:peerID]) {
                
                self.currentServerID = nil;
                self.currentServerScreenName = nil;
                
                //make session visible again for new clients
                p2pSession.available = YES;
                
                self.connectionState = Disconnected;
            }
            break;
            
        case GKPeerStateConnecting: // waiting for accept, or deny response
            self.connectionState = Connecting;
            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark GKSession dataHandler
- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context{
	
    if (connectionState == Connected) {
        
        [PacketEncoderDecoder decodePacket:data
                        delegateCommandsTo:nil
                            delegateDataTo:self.dataReceiver];
    }
}


@end
