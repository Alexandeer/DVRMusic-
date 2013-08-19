//
//  RootViewController.h
//  ConnectT
//
//  Created by DougT on 1/19/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TiVoContainer.h"
#import "TiVoContainerLoader.h"
#import "TiVoServerLoader.h"


@interface RootViewController : UITableViewController {
    IBOutlet UITableView * tableView;
    UIActivityIndicatorView * activityIndicator;

    bool loading;
    TiVoContainerLoader* tivoLoader;
    TiVoServerLoader* tivoServerLoader;

    CGSize cellSize;
    
    NSMutableArray * tivoContainers;

    NSMutableArray * history;
    
    NSString * selectedIP;
    NSString * selectedPort;

}

- (void) loadUrl: (NSString*) url;
- (void) tivoServerFound: (NSString*) url;

@end
