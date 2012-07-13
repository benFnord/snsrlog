//
//  Preferences.m
//  iPhoneLogger
//
//  Created by Benjamin Thiel on 10.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Preferences.h"
//NOTE: These keys need to be kept in sync with Root.plist (and other plists in the settings bundle)!
NSString* const kAccelerometerOn = @"accelerometerOn";
NSString* const kGpsOn = @"gpsOn";
NSString* const kCompassOn = @"compassOn";
NSString* const kMicrophoneOn = @"microphoneOn";
NSString* const kWifiOn = @"wifiOn";
NSString* const kGyroscopeOn = @"gyroscopeOn";

NSString* const kShowAccelerometer = @"showAccelerometer";
NSString* const kShowGyroscope = @"showGyroscope";
NSString* const kShowGps = @"showGps";
NSString* const kShowCompass = @"showCompass";
NSString* const kShowMicrophone = @"showMicrophone";
NSString* const kShowWifi = @"showWifi";

NSString* const kRecordAccelerometer = @"recordAccelerometer";
NSString* const kRecordGyroscope = @"recordGyroscope";
NSString* const kRecordGps = @"recordGps";
NSString* const kRecordCompass = @"recordCompass";
NSString* const kRecordMicrophone = @"recordMicrophone";
NSString* const kRecordWifi = @"recordWifi";

NSString* const kStreamAccelerometer = @"streamAccelerometer";
NSString* const kStreamGyroscope = @"streamGyroscope";
NSString* const kStreamGps = @"streamGps";
NSString* const kStreamCompass = @"streamCompass";

NSString* const kWifiScanInterval = @"wifiScanInterval";
NSString* const kAccelerometerFrequency = @"accelerometerFrequency";

NSString* const kLabels = @"labels";

@implementation Preferences


/* Loads user preferences database from Settings.bundle plists.
 * This needs to be done every time the app launches. NSUserDefaults looks up
 * values for the keys in the application domain (= changes made by the user),
 * which is persitent, first. In case of not finding the value it looks in the
 * registration domain, which should contain default values, is non-persistent
 * and hence initialized in this method.
 */
+ (void)registerDefaults
{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
	//Determine the path to our Settings.bundle.
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	NSString *settingsBundlePath = [bundlePath stringByAppendingPathComponent:@"Settings.bundle"];
    
	// Load paths to all .plist files from our Settings.bundle into an array.
	NSArray *allPlistFiles = [NSBundle pathsForResourcesOfType:@"plist" inDirectory:settingsBundlePath];
    
	// Put all of the keys and values into one dictionary,
	// which we then register with the defaults.
	NSMutableDictionary *preferencesDictionary = [NSMutableDictionary dictionary];
    
	// Copy the default values loaded from each plist
	// into the system's sharedUserDefaults database.
	NSString *plistFile;
	for (plistFile in allPlistFiles)
	{
        
		// Load our plist files to get our preferences.
		NSDictionary *settingsDictionary = [NSDictionary dictionaryWithContentsOfFile:plistFile];
		NSArray *preferencesArray = [settingsDictionary objectForKey:@"PreferenceSpecifiers"];
        
		// Iterate through the specifiers, and copy the default
		// values into the DB.
		NSDictionary *item;
		for(item in preferencesArray)
		{
			// Obtain the specifier's key value.
			NSString *keyValue = [item objectForKey:@"Key"];
            
			// Using the key, return the DefaultValue if specified in the plist.
			// Note: We won't know the object type until after loading it.
			id defaultValue = [item objectForKey:@"DefaultValue"];
            
			// Some of the items, like groups, will not have a Key, let alone
			// a default value.  We want to safely ignore these.
			if (keyValue && defaultValue)
			{
				[preferencesDictionary setObject:defaultValue forKey:keyValue];
			}
            
		}
        
	}
    
	// Ensure the version number is up-to-date, too.
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	NSString *shortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	NSString *versionLabel = [NSString stringWithFormat:@"%@ (%d)", shortVersion, [version intValue]];
	[standardUserDefaults setObject:versionLabel forKey:@"appVersion"];
    
	// Now synchronize the user defaults DB in memory
	// with the persistent copy on disk.
	[standardUserDefaults registerDefaults:preferencesDictionary];
	[standardUserDefaults synchronize];
    
    NSLog(@"registered defaults.");
}

@end
