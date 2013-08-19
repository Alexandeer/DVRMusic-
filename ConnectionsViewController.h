//
//  ConnectionsViewController.h
//  ConnectT
//
//  Created by DougT on 1/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CFBonjour.h"


@interface ConnectionsViewController : UIViewController {
    IBOutlet UITableView* ourTableView;
    
    UIButton *rb;
    IBOutlet UIButton* manuallyEnterButton;

    CFBonjour *bonjour;
    
    id owner;

    NSMutableArray* foundTivos;
}

-(IBAction) buttonWasPressed:(id)sender;
-(IBAction) enterIPAddress:(id)sender;

- (void) tivoSelected: (NSDictionary*) tivo;

- (void) setOwner: (id) owner;

@end
