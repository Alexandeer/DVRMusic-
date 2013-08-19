//
//  RootViewController.m
//  ConnectT
//
//  Created by DougT on 1/19/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "RootViewController.h"
#import "ConnectTAppDelegate.h"

#import "PlayerViewController.h"

#import "ConnectionsViewController.h"

#import "EnterIPViewController.h"

@implementation RootViewController


- (void)showConnectionView {
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back)] autorelease];

    ConnectionsViewController *cvc = [[ConnectionsViewController alloc] initWithNibName:@"Connections" bundle:[NSBundle mainBundle]];
    [cvc setOwner: self];
    [self presentModalViewController: cvc animated: YES];
    [cvc release];
   
}    

- (void) tivoContaierTitleUpdated: (NSString*) title {    
    self.title = title;
}

- (void) tivoContaiersUpdated: (NSMutableArray *) arr {
    
/*
    for (int i = 0; i < [arr count]; i++)
    {
        TiVoContainer* tc = [arr objectAtIndex:i];
        [tc dump];
    }
*/
    if (tivoContainers)
        [tivoContainers release];
    tivoContainers = [[NSMutableArray alloc] initWithArray:arr];
    [tableView reloadData];
    loading = false;
}

- (void) back
{
    if ([history count] <= 1)
    {
        [self showConnectionView];
        return;
    }
    
    [history removeLastObject];
    [self loadUrl: [history lastObject]];

    [tableView reloadData];

}

- (void) loadUrl: (NSString*) url
{    
    
    if (loading) {
        return;
    }
    loading = true;
    
    NSString * str = @"http://";
    str = [str stringByAppendingString:selectedIP];
    str = [str stringByAppendingString:@":"];
    str = [str stringByAppendingString:selectedPort];
    str = [str stringByAppendingString:url];

    // printf("Loading.... --- %s\n", [str UTF8String]);

    if (!tivoLoader) {
        tivoLoader = [[TiVoContainerLoader alloc] init];
        [tivoLoader setListener: self];
    }
    
    [NSThread detachNewThreadSelector:@selector(load:) toTarget: tivoLoader 
                           withObject:str];    
}

- (void) tivoSelected: (NSDictionary*) tivo
{
    [selectedIP release];
    selectedIP = [[tivo objectForKey:@"resolvedIP"] copy];
    
    [selectedPort release];
    selectedPort = [[tivo objectForKey:@"port"] copy];
    
    [history release];
    history = [[NSMutableArray alloc] init];
    
    NSString * str = @"http://";
    str = [str stringByAppendingString:selectedIP];
    str = [str stringByAppendingString:@":"];
    str = [str stringByAppendingString:selectedPort];
    str = [str stringByAppendingString:@"/TiVoConnect?Command=QueryContainer"];
    
    //printf("service %s\n", [str UTF8String]);

    if (!tivoServerLoader) {
        tivoServerLoader = [[TiVoServerLoader alloc] init];
        [tivoServerLoader setListener: self];
    }
    
    [NSThread detachNewThreadSelector:@selector(load:) toTarget: tivoServerLoader 
                           withObject:str];    
    
}

- (void) tivoServerFound: (NSString*) url { 
    [history addObject: url];
    [self loadUrl: url];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    
    
    // check to see if we can connect to something we already have seen before.
    // TODO
    
    tivoContainers = nil;
    loading = false;
    
    [self showConnectionView];
        
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

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

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    tableView= tv;
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tivoContainers count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell;// = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
 
    int index = [indexPath indexAtPosition: [indexPath length] - 1];

    NSString *title = [[tivoContainers objectAtIndex: index] getDetail: @"Title"];
    NSString *artist = [[tivoContainers objectAtIndex: index] getDetail: @"ArtistName"];
    
    ///printf("---->>>>>  %s  / %s\n", [title UTF8String], [artist UTF8String]);
    
    cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];

    if (artist == NULL)
    {
        [cell setText:title];
    }
    else
    {
        UILabel *label;
        UILabel *subhead;
        
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
        
        label = [[[UILabel alloc] initWithFrame:CGRectMake(20.0, 8.0, 200.0, 17.0)] autorelease];
        label.tag = 1;
        label.font = [UIFont boldSystemFontOfSize:14.0];
        label.textColor = [UIColor blackColor];
        label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:label];
    
        subhead = [[[UILabel alloc] initWithFrame:CGRectMake(25.0, 24.0, 200, 16.0)] autorelease];
        subhead.tag = 2;
        subhead.font = [UIFont systemFontOfSize:11.0];
        subhead.textColor = [UIColor grayColor];
        subhead.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:subhead];  
        label.text = title;
        subhead.text = artist;
    }

    return cell;
}


- (void)tableView :( UITableView *)tableView didSelectRowAtIndexPath :( NSIndexPath *)indexPath {
	// Navigation logic
    if (loading)
        return;
    
    
	int index = [indexPath indexAtPosition: [indexPath length] - 1];
    
    TiVoContainer *tc = [tivoContainers objectAtIndex: index];
	NSString * link = [tc getURL];
    
    [tc dump];

    
    if ([[tc getDetail:@"ContentType"] isEqualToString:@"audio/mpeg"]) 
    {
        
        PlayerViewController *pvc = [[PlayerViewController alloc] initWithNibName:@"Player" bundle:[NSBundle mainBundle]];
        [pvc setOwner: self];
        
        [pvc setTivoIP: selectedIP];
        [pvc setTivoPort: selectedPort];

        [pvc setCurrentSongInList: index];
        [pvc setSongList: tivoContainers];
        
        [self presentModalViewController: pvc animated: YES];
        
        [pvc release];
        
        return;
    }
        
    if ([[tc getDetail:@"ContentType"] isEqualToString:@"x-container/folder"] ||
        [[tc getDetail:@"ContentType"] isEqualToString:@"x-container/playlist"]) 
    {
        [history addObject: link];
        [self loadUrl: link];
        return;
    }
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)dealloc {
    [super dealloc];
    [tivoLoader release];
    [tivoServerLoader release];
}


@end

