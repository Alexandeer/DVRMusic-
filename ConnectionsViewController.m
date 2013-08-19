//
//  ConnectionsViewController.m
//  ConnectT
//
//  Created by DougT on 1/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ConnectionsViewController.h"
#import "EnterIPViewController.h"

@implementation ConnectionsViewController


-(void) bonjourClientAdded:(NSNotification *) notification
{
    /*
    NSString *tmpStr;
    \* a = [notification userInfo];
    NSEnumerator *keyEnumerator = [a keyEnumerator];
    while((tmpStr = [keyEnumerator nextObject]))
        printf("%s\n", [tmpStr UTF8String]);
    */
    
    
    // contains: serviceName resolvedIP port
    NSMutableDictionary *dict = [[notification userInfo] copy];
    NSString* ipAddr = [dict objectForKey:@"resolvedIP"];
    NSString* port = [dict objectForKey:@"port"];
    
    @synchronized (foundTivos) {
        
        //check to see if we have seen this one:
        
        for (int i = 0 ; i < [foundTivos count]; i++) {
            
            if ([ipAddr isEqualToString: [[foundTivos objectAtIndex:i] objectForKey:@"resolvedIP"]])
            {
                // found match;
                [dict release];
                return;
            }
        }

        [foundTivos addObject: dict];
    }
    
    [ourTableView reloadData];
}

- (void) addBackTable {
    [rb removeFromSuperview];
    [rb addTarget:self action:@selector(actionRemove) forControlEvents:UIControlEventTouchUpInside];
    [rb release];
    
    ourTableView.hidden = NO;
    
    // Set up an alert to reminder the user that we can continue searching, but haven't found anything  (30 seconds)
    NSTimer *timer = [NSTimer timerWithTimeInterval:30.0 target:self selector:@selector(anyTivosFound) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}


- (void) replaceTableWithSearchButton
{
    // Hide the table, and replace it with a button that allows a rescan.
    
    ourTableView.hidden = YES;
    
    rb = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
    rb.frame = CGRectMake(0, 0, 250, 60);
    rb.backgroundColor = [UIColor clearColor];
    [rb setTitle:@"Search for TiVo® Desktops" forState:UIControlStateNormal];
    [rb setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];

    
    rb.center = self.view.center;
    
    [rb addTarget:self action:@selector(addBackTable) forControlEvents:UIControlEventTouchUpInside];    
    
    [self.view addSubview:rb];
}

- (void) anyTivosFound
{
    if ([foundTivos count] > 0)
    {
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:@"No Tivos have been found on this network."
                                                   delegate:NULL
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    
    [alert show];
    [alert release];
    
    [self replaceTableWithSearchButton];
    
}

- (void) checkForTivos {
    if ([foundTivos count] == 0)
    {
        [self replaceTableWithSearchButton];
        return;
    }
    else
        ourTableView.hidden = NO;
}


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




- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {    
	return [foundTivos count] + 1; /* one extra for the waiting one */
}

//This method will be called n number of times.
//Where n = total number of items in the array.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"MyIdentifier";
    UITableViewCell *cell;
    
    if (indexPath.row ==  [foundTivos count])
    {        
        cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
            
            UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(cell.bounds.size.width/2,
                                                                                                    cell.bounds.size.height/2, 
                                                                                                    20, 
                                                                                                    20 )];
            
            [ai setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
            [ai sizeToFit];
            
            ai.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                   UIViewAutoresizingFlexibleRightMargin |
                                   UIViewAutoresizingFlexibleTopMargin |
                                   UIViewAutoresizingFlexibleBottomMargin);
            
            [ai startAnimating];
            [ai setCenter:[cell.contentView center]];
            
            [cell.contentView addSubview:ai];
            
            [ai release];
        }
        return cell;
    }
        
	cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) 
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
        
    UILabel* label = [[UILabel alloc] initWithFrame:cell.bounds];
    label.text = [[foundTivos objectAtIndex:indexPath.row] objectForKey:@"serviceName"];;
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Marker Felt" size:20];
    [label sizeToFit];
        
    [label setCenter:[cell.contentView center]];
        
    label.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                             UIViewAutoresizingFlexibleRightMargin |
                             UIViewAutoresizingFlexibleTopMargin |
                             UIViewAutoresizingFlexibleBottomMargin);
        
    [cell.contentView addSubview:label];
	// return the table cell.
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// Navigation logic
    
    // how do we get the previous cell so that we can revert the multi view stuff?
    [ourTableView reloadData];
    
    // check to see if this is the one with the progress ui in it.
    if (indexPath.row == [foundTivos count])
    {
        return;
    }
    
	int index = [indexPath indexAtPosition: [indexPath length] - 1];
    NSDictionary* selectedTivo = [foundTivos objectAtIndex: index];
    
    [self tivoSelected: selectedTivo];    
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
 
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];  
 
    foundTivos = [[NSMutableArray alloc] init];
    
    bonjour = [[CFBonjour alloc] init];
    [bonjour CFBonjourStartBrowsingForServices:@"_tivo-music._tcp." inDomain:@""];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bonjourClientAdded:) name:@"bonjourClientAdded" object:nil];
    
    // Set up an alert to reminder the user that we can continue searching, but haven't found anything
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.0 target:self selector:@selector(checkForTivos) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
    ourTableView.backgroundColor = [UIColor clearColor];
    [manuallyEnterButton setTitleColor: [UIColor blackColor] forState:UIControlStateNormal];

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
    //[bonjour CFBonjourStopCurrentService];
    [bonjour release];
}

- (void) setOwner: (id) aOwner
{
    owner = aOwner;
}

-(IBAction) buttonWasPressed:(id)sender
{
    [owner dismissModalViewControllerAnimated: YES];
}

- (void) tivoSelected: (NSDictionary*) tivo
{
    SEL callback = @selector(tivoSelected:);
    NSMethodSignature* signature = [owner methodSignatureForSelector: callback];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:owner];
    [invocation setSelector:callback];
    [invocation setArgument:&tivo atIndex:2];
    
    // Since the callback might touch the UI, we need to make sure that the callback happens
    // on the UI thread.    
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO]; 
    [owner dismissModalViewControllerAnimated: YES];    

}

-(IBAction) enterIPAddress:(id)sender
{
    EnterIPViewController *evc = [[EnterIPViewController alloc] initWithNibName:@"EnterTivoIP" bundle:[NSBundle mainBundle]];
    [evc setOwner: self];
    [self presentModalViewController: evc animated: YES];
    [evc release];
}

@end
