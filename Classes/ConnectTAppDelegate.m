//
//  ConnectTAppDelegate.m
//  ConnectT
//
//  Created by DougT on 1/19/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//
// images from http://www.rubysoftware.nl


#import "ConnectTAppDelegate.h"
#import "RootViewController.h"

#import "CFBonjour.h"

@implementation ConnectTAppDelegate

@synthesize window;
@synthesize navigationController;



- (void)applicationDidFinishLaunching:(UIApplication *)application {
	// Configure and show the window
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];
 }

- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
    /*
    NSEnumerator *enumerator = [detected keyEnumerator];
    NSString *key;
    while ((key = [enumerator nextObject]) != NULL) {
        NSDictionary *dict = [detected objectForKey:key];
        
        NSEnumerator *enumerator1 = [dict keyEnumerator];
        NSString *key1;
        while ((key1 = [enumerator1 nextObject]) != NULL) {
            NSString *string = [dict objectForKey:key1];
            
            printf("%s=%s\n", [key1 UTF8String], [string UTF8String]);
        }
    }
     */
    

    
}


- (void)dealloc {
	[navigationController release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Detected TiVo" object:nil];
    
	[window release];
	[super dealloc];
}

@end
