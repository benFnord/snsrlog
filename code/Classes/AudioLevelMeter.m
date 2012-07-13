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
//  AudioLevelMeter.m
//  snsrlog
//
//  Created by Benjamin Thiel on 16.05.11.
//

#import "AudioLevelMeter.h"


@implementation AudioLevelMeter

+(CGSize) preferredSize {
    
    return CGSizeMake(320, 45);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        // create the sound image
        UIImage *soundImage = [UIImage imageNamed:@"microphone.png"];
        CGFloat centeredIconY = roundf((self.bounds.size.height / 2) - (soundImage.size.height / 2));
        CGRect soundIconFrame = CGRectMake(5, centeredIconY - 1, soundImage.size.width, soundImage.size.height);
        soundIcon = [[UIImageView alloc] initWithFrame:soundIconFrame];
        soundIcon.image = soundImage;
        soundIcon.alpha = 1;
        
        [self addSubview:soundIcon];

        
        //add the different audio level image views
        CGFloat leftMargin = 50;
        CGRect soundImageFrame = CGRectMake(leftMargin, 0, self.bounds.size.width - leftMargin, 45);
        
        int numberOfSoundLevels = 21;
        audioLevelImageViews = malloc(numberOfSoundLevels * sizeof(UIImageView *));
        
        //add all images to the view and hide them
        for (int i = 0; i < numberOfSoundLevels; i++) {
            
            UIImage *soundLevelImage = [UIImage imageNamed:[NSString stringWithFormat:@"SoundLevel_%i.png", i]];
            UIImageView *levelMeter = [[UIImageView alloc] initWithFrame:soundImageFrame];
            levelMeter.image = soundLevelImage;
            levelMeter.alpha = 1;
            levelMeter.hidden = YES;
            
            audioLevelImageViews[i] = levelMeter;
            [self addSubview:levelMeter];
            [levelMeter release];
        }
        
        //display the empty audio level image
        lastLevel = 1;
        [self updateSoundLevel:0];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    free(audioLevelImageViews);
    [soundIcon release];
    [super dealloc];
}


- (void)updateSoundLevel:(float)percentage {
	
	// compute the number of the image we have to display and crop it if neccessary
	int currentLevel = log2f(1 + percentage) * 20;
	if (currentLevel > 20) { currentLevel = 20; }
	if (currentLevel < 0) { currentLevel = 0; }

    if (currentLevel != lastLevel) {
     
        //hide the last level and show the new one
        audioLevelImageViews[currentLevel].hidden = NO;
        audioLevelImageViews[lastLevel].hidden = YES;
        lastLevel = currentLevel;
    }
}

@end
