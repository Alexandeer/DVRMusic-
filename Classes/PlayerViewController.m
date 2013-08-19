//
//  PlayerViewController.m
//  ConnectT
//
//  Created by DougT on 1/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PlayerViewController.h"
#import "TiVoContainer.h"

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@implementation PlayerViewController

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

-(void) checkPauseIcon {
    UIImage * image;
    if (streamer && ([streamer isPaused] == YES || streamer->error_status != 0)) {
        image = [UIImage imageNamed:@"play-48x48.png"];
    }
    else {
        image = [UIImage imageNamed:@"pause-48x48.png"];
    }
    
    [pauseButton setImage: image forState: UIControlStateNormal];    
}

- (void) playCurrentSong {
    
    // bug work around?
   TiVoContainer* tc = [songList objectAtIndex: currentSong];
    
    int duration = [[tc getDetail: @"Duration"] intValue];
    duration = duration / 1000; // in seconds.
    
    if (duration > 0)
        endTimeLabel.text = [NSString stringWithFormat:@"%d:%02d", duration / 60, (duration % (60))];
    else
        endTimeLabel.text = @"Unknown";
        
    NSString *title = [tc getDetail: @"Title"];
    NSString *artist = [tc getDetail: @"ArtistName"];
    
    artistLabel.text = artist;
    artistLabel.font = [UIFont fontWithName:@"Marker Felt" size:28];

    songLabel.text = title;
    songLabel.font = [UIFont fontWithName:@"Marker Felt" size:20];
    
    NSString * str = @"http://";
    str = [str stringByAppendingString:tivoIP];
    str = [str stringByAppendingString:@":"];
    str = [str stringByAppendingString:tivoPort];

    str = [str stringByAppendingString: [tc getURL]];
    
    
//    printf("url:  %s\n", [str UTF8String]);
    
    NSURL *url = [NSURL URLWithString:str];
    
    [streamer stop];
    [streamer release];
    
    streamer = [[AudioStreamer alloc] init];
    [streamer play:url];    
    [self checkPauseIcon];

    
}

- (void) tick
{
    [self checkPauseIcon];

    if (!streamer || !streamer->audioQueue || [streamer isPaused])
        return;

    TiVoContainer* tc = [songList objectAtIndex: currentSong];
    int currentTime = [streamer getCurrentTime];
    
    int duration = [[tc getDetail: @"Duration"] intValue];
    duration = duration / 1000; // in seconds.
    
    startTimeLabel.text = [NSString stringWithFormat:@"%0d:%02d",  currentTime / 60, (currentTime % 60)];
    
    if (duration == 0)
    {
        startTimeLabel.text = [NSString stringWithFormat:@"??:??"];
        progressView.progress = 0;
    }
    else
    {
        progressView.progress = (float) (currentTime) / (float) duration;
    }

    if (streamer->error_status != 0)
    {
     // try again?
        
        AudioSessionSetActive(false);
        
        if (streamer) {
            [streamer stop];
            [streamer release];
            streamer = NULL;
        }
        
        [[NSRunLoop currentRunLoop]
         runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 3]];
        
        AudioSessionSetActive(true);
        
        [self playCurrentSong];
        return; 
    }
    
    if ([streamer isDonePlaying] == YES || currentTime >= duration)
    {
        if ([songList count] > currentSong+1)
        {
            currentSong++;
            [self playCurrentSong];
        }
        else
        {
            currentSong = 0;
            [self playCurrentSong];
        }
    }
    
    // mChannelsPerFrame
#if 0
    AudioStreamBasicDescription asbd;
    UInt32 asbdSize = sizeof(asbd);
    AudioFileStreamGetProperty(streamer->audioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
    
    UInt32 propertySize = sizeof (AudioQueueLevelMeterState) * (asbd.mChannelsPerFrame);
    AudioQueueLevelMeterState* audioLevels = (AudioQueueLevelMeterState*) malloc ((asbd.mChannelsPerFrame) * sizeof (AudioQueueLevelMeterState));
    
    AudioQueueGetProperty (streamer->audioQueue,
                           (AudioQueuePropertyID) kAudioQueueProperty_CurrentLevelMeter,
                           audioLevels,
                           &propertySize);
    
    for (int i = 0 ; i < (asbd.mChannelsPerFrame); i++) {

        float f = audioLevels[0].mAveragePower * 10;
//        imageView.transform = CGAffineTransformMakeScale(f, f);
        
        
       // [imageView setFrame:CGRectMake(0.0f, 0.0f, audioLevels[0].mAveragePower * 100, audioLevels[0].mAveragePower * 100)];
        //[ imageView setBounds: NSMakeRect(0, 0, audioLevels[0].mAveragePower * 100, audioLevels[0].mAveragePower * 100)];
        
      // printf("\tChannel %d >%f / %f\n", i, audioLevels[i].mAveragePower, audioLevels[i].mPeakPower);
    }
#endif


}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [progressView setTintColor: [UIColor blackColor]];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.02
                                             target:self
                                           selector:@selector(tick)
                                           userInfo:NULL
                                            repeats:YES];
    
    [self playCurrentSong];
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
    [timer release];
    [tivoPort release];
    [tivoIP release];

    [songList release];
    
    if (streamer) {
        [streamer stop];
        [streamer release];
        streamer = NULL;
    }
}

-(IBAction) pauseWasPressed:(id)sender
{
    if (streamer) {
        [streamer pause];
    }
    else {
        [self playCurrentSong];
    }
}

-(IBAction) rewindWasPressed:(id)sender
{
    // Just rewind track if the current time is large
    int currentTime = [streamer getCurrentTime];
    
    if (currentTime > 2)
    {
        [self playCurrentSong];
        return;
    }

    if (currentSong == 0)
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        // beep disable the forward button?
        return;
    }
    
    currentSong--;
    
    [self playCurrentSong];
}

-(IBAction) forwardWasPressed:(id)sender
{
    if ([songList count] - 1 <= currentSong)
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);

        // beep disable the forward button?
        return;
    }
    currentSong++;
    [self playCurrentSong];
}

-(IBAction) stopWasPressed:(id)sender
{
    [streamer stop];
    [streamer release];
    streamer = NULL;
    
    [owner dismissModalViewControllerAnimated: YES];
}

- (void) setOwner: (id) aOwner
{
    owner = aOwner;
}


-(void) setTivoIP: (NSString*) ip
{
    tivoIP = ip;
}

-(void) setTivoPort: (NSString*) port
{
    tivoPort = port;
}

-(void) setCurrentSongInList: (int) index
{
    currentSong = index;   
}

-(void) setSongList: (NSArray*) list
{
    songList = list;   
}


@end
