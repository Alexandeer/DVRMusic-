
#ifdef TARGET_OS_IPHONE			
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif TARGET_OS_IPHONE			

#include <pthread.h>
#include <AudioToolbox/AudioToolbox.h>

#define kNumAQBufs 6			// number of audio queue buffers we allocate
#define kAQBufSize 32 * 1024		// number of bytes in each audio queue buffer
#define kAQMaxPacketDescs 512		// number of packet descriptions in our array

@class AudioStreamer;

void MyReadStreamCallBack(CFReadStreamRef stream,
                          CFStreamEventType eventType,
                          void* dataIn);

void MyAudioQueueOutputCallback(void* inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);

void MyPropertyListenerProc(	void *							inClientData,
                            AudioFileStreamID				inAudioFileStream,
                            AudioFileStreamPropertyID		inPropertyID,
                            UInt32 *						ioFlags);
void MyPacketsProc(				void *							inClientData,
                   UInt32							inNumberBytes,
                   UInt32							inNumberPackets,
                   const void *					inInputData,
                   AudioStreamPacketDescription	*inPacketDescriptions);

OSStatus MyEnqueueBuffer(AudioStreamer* myData);

#ifdef TARGET_OS_IPHONE			
void MyAudioSessionInterruptionListener(void *inClientData, UInt32 inInterruptionState);
#endif


@interface AudioStreamer : NSObject
{

    BOOL isPaused;
	
@public
    

	AudioFileStreamID audioFileStream;	// the audio file stream parser

	AudioQueueRef audioQueue;								// the audio queue
	AudioQueueBufferRef audioQueueBuffer[kNumAQBufs];		// audio queue buffers
	
	AudioStreamPacketDescription packetDescs[kAQMaxPacketDescs];	// packet descriptions for enqueuing audio
	
	unsigned int fillBufferIndex;	// the index of the audioQueueBuffer that is being filled
	size_t bytesFilled;				// how many bytes have been filled
	size_t packetsFilled;			// how many packets have been filled

    bool userAborted;
	bool inuse[kNumAQBufs];			// flags to indicate that a buffer is still in use
	bool started;					// flag to indicate that the queue has been started
	bool failed;					// flag to indicate an error occurred
	bool finished;				    // flag to inidicate that termination is requested
    bool isRunning;					
	bool discontinuous;			// flag to trigger bug-avoidance
    OSStatus error_status;
    
	pthread_mutex_t mutex;			// a mutex to protect the inuse flags
	pthread_cond_t cond;			// a condition varable for handling the inuse flags
	pthread_mutex_t mutex2;			// a mutex to protect the AudioQueue buffer

	CFReadStreamRef stream;
    
    NSURL *url;

}

@property BOOL isPaused;

- (id) init;

- (NSURL *) getURL;

- (void) play: (NSURL *) newURL;

- (void)stop;
- (void)pause;

- (BOOL) isDonePlaying;

- (Float64)getCurrentTime;

@end
