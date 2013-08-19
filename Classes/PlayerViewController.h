//
//  PlayerViewController.h
//  ConnectT
//
//  Created by DougT on 1/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioStreamer.h"


@interface PlayerViewController : UIViewController {
    IBOutlet UILabel *artistLabel;
    IBOutlet UILabel *songLabel;
    
    IBOutlet UIButton *pauseButton;
    
    IBOutlet UILabel *startTimeLabel;
    IBOutlet UILabel *endTimeLabel;
    
    IBOutlet UIProgressView *progressView;

    IBOutlet UIImageView* imageView;

    
    //IBOutlet UISlider *sliderView;
    //BOOL touchIsOnSlider;
    
    id owner;
    
    AudioStreamer* streamer;
    
    NSArray* songList;
    int currentSong;
    NSString *tivoIP;
    NSString *tivoPort;
    
    
    NSTimer* timer;
    
}

-(void) setOwner: (id) owner;
-(void) setTivoIP: (NSString*) ip;
-(void) setTivoPort: (NSString*) port;


-(void) setCurrentSongInList: (int) index;
-(void) setSongList: (NSArray*) list;

-(IBAction) pauseWasPressed:(id)sender;
-(IBAction) rewindWasPressed:(id)sender;
-(IBAction) forwardWasPressed:(id)sender;
-(IBAction) stopWasPressed:(id)sender;

@end
