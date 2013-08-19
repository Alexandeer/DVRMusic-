//
//  EnterIPViewController.h
//  ConnectT
//
//  Created by DougT on 1/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EnterIPViewController : UIViewController {
    
    
    IBOutlet UITextField *ipText;
    
    IBOutlet UILabel *connectionLabel;
    IBOutlet UIActivityIndicatorView *activityView;
    
    IBOutlet UIButton *cancelButton;
    IBOutlet UIButton *okayButton;

    id owner;

    NSString* validIPString;

}

-(IBAction) ipTextWasChanged:(id)sender;

-(IBAction) cancelWasPressed:(id)sender;
-(IBAction) okayWasPressed:(id)sender;


-(void) setOwner: (id) owner;

@end
