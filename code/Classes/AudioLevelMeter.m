//
//  AudioLevelMeter.m
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 16.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
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
