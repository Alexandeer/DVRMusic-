//
//  EnterIPViewController.m
//  ConnectT
//
//  Created by DougT on 1/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EnterIPViewController.h"
#import "Reachability.h"

@implementation EnterIPViewController

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    [cancelButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [okayButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];
    [okayButton setTitleColor: [UIColor grayColor] forState:UIControlStateDisabled];

    
    connectionLabel.text = @"";
    connectionLabel.font = [UIFont boldSystemFontOfSize:14.0];
    connectionLabel.textColor = [UIColor blackColor];
    
    validIPString = nil;
    
    [okayButton setEnabled:NO];
    
    NSString *enteredIP = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastManuallyEnteredIP"];
    if (enteredIP)
        ipText.text = enteredIP;
    
    [NSTimer scheduledTimerWithTimeInterval:0.02
                                     target:self
                                   selector:@selector(ipTextWasChanged:)
                                   userInfo:NULL
                                    repeats:NO];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
    
    [validIPString release];
}


-(IBAction) ipTextWasChanged:(id)sender
{
    activityView.hidden = NO;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [NSRunLoop currentRunLoop];
    
    // Check internet connection status
	NetworkStatus internetConnectionStatus	= [[Reachability sharedReachability] internetConnectionStatus];
    
    if (internetConnectionStatus == NotReachable) {
		UIAlertView *v = [[UIAlertView alloc] initWithTitle:@"Reporting failed" message:@"You need to be connected to the internet to report a problem." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[v show];
		[v release];		
		return;
    }

    
    
    NSString* url = [NSString stringWithFormat:@"http://%s:8101", [ipText.text UTF8String]];
    
    NSMutableURLRequest *theRequest=[NSMutableURLRequest
                                     requestWithURL: [NSURL URLWithString:url]
                                     cachePolicy:NSURLRequestUseProtocolCachePolicy
                                     timeoutInterval:1.0];
    NSURLResponse *theResponse = NULL;
    NSError *nserror = NULL;
    
    NSData *data =[[NSURLConnection
                    sendSynchronousRequest: theRequest
                    returningResponse: &theResponse
                    error: &nserror] retain];
    
    if (!data || [ipText.text length] == 0) {
        [okayButton setEnabled:NO];
        
        [validIPString release];
        validIPString = nil;
        connectionLabel.text = @"";
    }
    else {
        [okayButton setEnabled:YES];

        [validIPString release];
        validIPString = [ipText.text copy];
        connectionLabel.text = @"connected successfully";
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    activityView.hidden = YES;

}

-(IBAction) cancelWasPressed:(id)sender
{
    [owner dismissModalViewControllerAnimated: YES];
}

-(IBAction) okayWasPressed:(id)sender
{
    
    NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                               validIPString, @"resolvedIP", @"User Defined", @"serviceName", @"8101", @"port", nil];
    
    
    SEL callback = @selector(tivoSelected:);
    NSMethodSignature* signature = [owner methodSignatureForSelector: callback];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:owner];
    [invocation setSelector:callback];
    [invocation setArgument:&dictionary atIndex:2];
    
    // Since the callback might touch the UI, we need to make sure that the callback happens
    // on the UI thread.    
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES]; 
    
    [[NSUserDefaults standardUserDefaults] setObject:validIPString forKey:@"LastManuallyEnteredIP"];

    [owner dismissModalViewControllerAnimated: YES];
}


-(void) setOwner: (id) o
{
    owner = o;    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // hide our text field
    [ipText resignFirstResponder];
}


@end
