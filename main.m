//
//  main.m
//  ConnectT
//
//  Created by DougT on 1/19/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#if 0
void mysighandler(int sig, siginfo_t *info, void *context) {
    void *backtraceFrames[128];
    int frameCount = backtrace(backtraceFrames, 128);
}
#endif


int main(int argc, char *argv[]) {
#if 0
struct sigaction mySigAction;
mySigAction.sa_sigaction = mysighandler;
mySigAction.sa_flags = SA_SIGINFO;
sigemptyset(&mySigAction.sa_mask);
sigaction(SIGQUIT, &mySigAction, NULL);
sigaction(SIGILL, &mySigAction, NULL);
sigaction(SIGTRAP, &mySigAction, NULL);
sigaction(SIGABRT, &mySigAction, NULL);
sigaction(SIGEMT, &mySigAction, NULL);
sigaction(SIGFPE, &mySigAction, NULL);
sigaction(SIGBUS, &mySigAction, NULL);
sigaction(SIGSEGV, &mySigAction, NULL);
sigaction(SIGSYS, &mySigAction, NULL);
sigaction(SIGPIPE, &mySigAction, NULL);
sigaction(SIGALRM, &mySigAction, NULL);
sigaction(SIGXCPU, &mySigAction, NULL);
sigaction(SIGXFSZ, &mySigAction, NULL);
#endif
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
