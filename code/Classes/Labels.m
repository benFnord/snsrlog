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
//  Labels.m
//  snsrlog
//
//  Created by Benjamin Thiel on 15.03.11.
//

#import "Labels.h"
#import "Preferences.h"

@interface Labels () 

-(void)labelArrayChanged;

@end

@implementation Labels

static Labels *sharedSingleton;

//singleton
+(Labels *) sharedInstance {
    return sharedSingleton;
}

@synthesize mutable;
@synthesize currentLabel;
@synthesize labels;

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
        sharedSingleton = [[Labels alloc] init];
    }
}

- (id)init {
    
    self = [super init];
    
    if (self != nil) {
        
        isAvailable = YES;
        mutable = YES;
        
        NSArray *storedLabels = [[NSUserDefaults standardUserDefaults] arrayForKey:kLabels];
        if (storedLabels && ([storedLabels count] > 0)) {
            
            labels = [[NSMutableArray alloc] initWithArray:storedLabels];
            
        } else {
            
            labels = [[NSMutableArray alloc] initWithCapacity:1];
            [labels addObject:@"Default Label"];
        }
        
        currentLabel = 0; 
    }
    
    return self;
}

- (void)dealloc {
    [labels release];
    [super dealloc];
}

#pragma mark -
#pragma mark label methods

//override the synthesized setter
-(void)setCurrentLabel:(int)newLabel {
    
    if (newLabel != currentLabel) {
        
        //bounds checking
        currentLabel = ((newLabel < 0) || (newLabel > ([labels count] - 1))) ? 0 : newLabel;
        
        id<Listener> listener;
        
        //mutex allows adding and removing of listeners while running
        dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_FOREVER);
            
            for (listener in listeners) {
                [listener didReceiveChangeToLabel:currentLabel timestamp:[self getTimestamp]];
            }
        dispatch_semaphore_signal(listenersSemaphore);
    }
}


-(void)addLabel:(NSString *)newLabel {
    
    if (mutable) {
        
        [labels addObject:newLabel];
        [[NSUserDefaults standardUserDefaults] setObject:labels forKey:kLabels];
        
        [self labelArrayChanged];
    }
}


-(void)removeLabelAtIndex:(int)index {
    
    if (mutable) {
        
        //make sure the default label is never removed and index is in valid bounds
        if ((index > 0) && (index < [labels count])) {
            
            [labels removeObjectAtIndex:index];
            [[NSUserDefaults standardUserDefaults] setObject:labels forKey:kLabels];
            
            [self labelArrayChanged];
            
            if (index == currentLabel) {
                
                self.currentLabel = 0;
            }
            
            if (index < currentLabel) {
                
                self.currentLabel = currentLabel - 1;
            }
        }
    }
}

-(void)labelArrayChanged {
    
    //mutex allows adding and removing of listeners while running
    dispatch_semaphore_wait(listenersSemaphore, DISPATCH_TIME_FOREVER);
        
        for (NSObject<Listener> *listener in listeners) {
            
            if ([listener respondsToSelector:@selector(didReceiveNewLabelNames:)]) {
                
                [listener didReceiveNewLabelNames:labels];
            }
        }
    dispatch_semaphore_signal(listenersSemaphore);
}

-(NSString *)getNameForLabelAtIndex:(int)index {
    
    if ((index >= 0) && (index < [labels count])) {
        
        return [labels objectAtIndex:index];
    }
    
    return @"empty label";
    
}

-(int)count {
    
    return [labels count];
}

@end
