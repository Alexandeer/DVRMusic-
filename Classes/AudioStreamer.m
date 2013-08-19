// based on AudioFileStreamExample

#import "AudioStreamer.h"


#ifdef TARGET_OS_IPHONE			
#import <CFNetwork/CFNetwork.h>
#endif

#define MY_DEBUG

#ifdef MY_DEBUG
#define myprintf printf
#else
#define myprintf
#endif


static void print_status( OSStatus s )
{
    const char *r = "whatev";
    
    switch( s ) {
        case  kAudioFileUnspecifiedError:
            r = "kAudioFileUnspecifiedError";
            break;
        case  kAudioFileUnsupportedFileTypeError:
            r =  "kAudioFileUnsupportedFileTypeError";
            break;
        case kAudioFileStreamError_IllegalOperation:
            r = "kAudioFileStreamError_IllegalOperation";
            break;
        case kAudioFileUnsupportedDataFormatError:
            r = "kAudioFileUnsupportedDataFormatError";
            break;
        case kAudioFileInvalidFileError:
            r="kAudioFileInvalidFileError";
            break;
        case kAudioFileStreamError_ValueUnknown:
            r="kAudioFileStreamError_ValueUnknown";
            break;
        case kAudioFileStreamError_DataUnavailable:
            r="kAudioFileStreamError_DataUnavailable";
            break;
    }
    
    if( s ) {
        const char *e = (const char*)&s;
        myprintf( "ERROR status: %s %c%c%c%c\n", r, e[3],e[2],e[1],e[0] );
    }
    else
        myprintf("Error was %s\n", r);
}

void MyPropertyListenerProc(void *							inClientData,
                            AudioFileStreamID				inAudioFileStream,
							AudioFileStreamPropertyID		inPropertyID,
							UInt32 *						ioFlags)
{	

	AudioStreamer* myData = (AudioStreamer*)inClientData;
	OSStatus err = noErr;

	switch (inPropertyID) {
		case kAudioFileStreamProperty_ReadyToProducePackets :
		{
			myData->discontinuous = true;

			AudioStreamBasicDescription asbd;
			UInt32 asbdSize = sizeof(asbd);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
			if (err) {
                myprintf("AudioFileStreamGetProperty (%d)\n", err);
                print_status(err);
                myData->error_status = err;
                myData->failed = true;
                break;
            }
			
			err = AudioQueueNewOutput(&asbd, MyAudioQueueOutputCallback, myData, NULL, NULL, 0, &myData->audioQueue);
			if (err) {
                myprintf("AudioQueueNewOutput (%d)\n", err);
                print_status(err);
                myData->error_status = err;
                myData->failed = true; 
                break;
            }
			
			for (unsigned int i = 0; i < kNumAQBufs; ++i) {
				err = AudioQueueAllocateBuffer(myData->audioQueue, kAQBufSize, &myData->audioQueueBuffer[i]);
				if (err) {
                    myprintf("AudioQueueAllocateBuffer (%d)\n", err);
                    myData->error_status = err;
                    print_status(err);	
                    myData->failed = true;
                    break;
                }
			}
            
            // get the cookie size
			UInt32 cookieSize;
			Boolean writable;
			err = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
			if (err) { break; }
            
			// get the cookie data
			void* cookieData = calloc(1, cookieSize);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
			if (err) { myprintf("2 kAudioFileStreamProperty_MagicCookieData\n"); free(cookieData); break; }
            
			// set the cookie on the queue.
			err = AudioQueueSetProperty(myData->audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
			free(cookieData);
			if (err) { myprintf("kAudioQueueProperty_MagicCookie\n"); break; }
			break;
            
           /*
            UInt32 trueValue = true;
            AudioQueueSetProperty(myData->audioQueue, kAudioQueueProperty_EnableLevelMetering, &trueValue, sizeof (UInt32));
            */
		}
	}
}

void MyPacketsProc(void *							inClientData,
					UInt32							inNumberBytes,
					UInt32							inNumberPackets,
					const void *					inInputData,
					AudioStreamPacketDescription	*inPacketDescriptions)
{
	AudioStreamer* myData = (AudioStreamer*)inClientData;
	OSStatus err;
    
	myData->discontinuous = false;

	// the following code assumes we're streaming VBR data. for CBR data, the second branch is used.
	if (inPacketDescriptions)
	{
		for (int i = 0; i < inNumberPackets; ++i) {
			SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
			SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
			
			// If the audio was terminated before this point, then
			// exit.
			if (myData->finished)
			{
				return;
			}

			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			size_t bufSpaceRemaining = kAQBufSize - myData->bytesFilled;
			if (bufSpaceRemaining < packetSize) {
				err = MyEnqueueBuffer(myData);
                if (err) { 
                    return;
                }
			}
			
			pthread_mutex_lock(&myData->mutex2);

			// If the audio was terminated while waiting for a buffer, then
			// exit.
			if (myData->finished)
			{
				pthread_mutex_unlock(&myData->mutex2);
				return;
			}
			 
			// copy data to the audio queue buffer
			AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
            if (!fillBuf)
            {
                myData->failed = true;
                myData->error_status = -1;
                myprintf("fillBuf was null!\n");
				pthread_mutex_unlock(&myData->mutex2);
				return;
			}
            
            memcpy((char*)fillBuf->mAudioData + myData->bytesFilled, (const char*)inInputData + packetOffset, packetSize);
			
			pthread_mutex_unlock(&myData->mutex2);
			
			// fill out packet description
			myData->packetDescs[myData->packetsFilled] = inPacketDescriptions[i];
			myData->packetDescs[myData->packetsFilled].mStartOffset = myData->bytesFilled;
			// keep track of bytes filled and packets filled
			myData->bytesFilled += packetSize;
			myData->packetsFilled += 1;

			// if that was the last free packet description, then enqueue the buffer.
			size_t packetsDescsRemaining = kAQMaxPacketDescs - myData->packetsFilled;
			if (packetsDescsRemaining == 0) {
				err = MyEnqueueBuffer(myData);
                if (err) { 
                    return;
                }
			}
		}	
	}
	else
	{
		size_t offset = 0;
		while (inNumberBytes)
		{
			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			size_t bufSpaceRemaining = kAQBufSize - myData->bytesFilled;
			if (bufSpaceRemaining < inNumberBytes) {
				err = MyEnqueueBuffer(myData);
                if (err) { 
                    return;
                }
			}
			
			pthread_mutex_lock(&myData->mutex2);

			// If the audio was terminated while waiting for a buffer, then
			// exit.
			if (myData->finished)
			{
				pthread_mutex_unlock(&myData->mutex2);
				return;
			}
			
			// copy data to the audio queue buffer
			AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
			bufSpaceRemaining = kAQBufSize - myData->bytesFilled;
			size_t copySize;
			if (bufSpaceRemaining < inNumberBytes)
			{
				copySize = bufSpaceRemaining;
			}
			else
			{
				copySize = inNumberBytes;
			}
			memcpy((char*)fillBuf->mAudioData + myData->bytesFilled, (const char*)(inInputData + offset), copySize);

			pthread_mutex_unlock(&myData->mutex2);

			// keep track of bytes filled and packets filled
			myData->bytesFilled += copySize;
			myData->packetsFilled = 0;
			inNumberBytes -= copySize;
			offset += copySize;
		}
	}
}

OSStatus MyEnqueueBuffer(AudioStreamer* myData)
{
	OSStatus err = noErr;
	myData->inuse[myData->fillBufferIndex] = true;		// set in use flag
	
	// enqueue buffer
	AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
	fillBuf->mAudioDataByteSize = myData->bytesFilled;
	
	if (myData->packetsFilled)
	{
		err = AudioQueueEnqueueBuffer(myData->audioQueue, fillBuf, myData->packetsFilled, myData->packetDescs);
	}
	else
	{
		err = AudioQueueEnqueueBuffer(myData->audioQueue, fillBuf, 0, NULL);
	}

	if (err) {
        // It happens when one tries to enqueue a buffer when the queue in question is no longer running.  //-66632

        myprintf("AudioQueueEnqueueBuffer (%d)\n", err);
        myData->error_status = err;
        myData->failed = true;
        return err;
    }		
	
	if (!myData->started) {		// start the queue if it has not been started already
		err = AudioQueueStart(myData->audioQueue, NULL);

        
		if (err)
        { 
            myprintf("AudioQueueStart (%d)\n", err);
            myData->error_status = err;
            myData->failed = true;
            return err;
        }		

		myData->started = true;
	}

	// go to next buffer
	if (++myData->fillBufferIndex >= kNumAQBufs) 
        myData->fillBufferIndex = 0;
    
	myData->bytesFilled = 0;		// reset bytes filled
	myData->packetsFilled = 0;		// reset packets filled
   
	// wait until next buffer is not in use
	pthread_mutex_lock(&myData->mutex); 
    while (myData->inuse[myData->fillBufferIndex] && !myData->finished)
	{
		pthread_cond_wait(&myData->cond, &myData->mutex);
    }
	pthread_mutex_unlock(&myData->mutex);

	return err;
}

int MyFindQueueBuffer(AudioStreamer* myData, AudioQueueBufferRef inBuffer)
{
	for (unsigned int i = 0; i < kNumAQBufs; ++i) {
		if (inBuffer == myData->audioQueueBuffer[i]) 
			return i;
	}
	return -1;
}

void MyAudioQueueOutputCallback(void*					inClientData, 
								AudioQueueRef			inAQ, 
								AudioQueueBufferRef		inBuffer)
{
	// this is called by the audio queue when it has finished decoding our data. 
	// The buffer is now free to be reused.
	AudioStreamer* myData = (AudioStreamer*)inClientData;
	unsigned int bufIndex = MyFindQueueBuffer(myData, inBuffer);
	
	// signal waiting thread that the buffer is free.
	pthread_mutex_lock(&myData->mutex);
	myData->inuse[bufIndex] = false;
	pthread_cond_signal(&myData->cond);
	pthread_mutex_unlock(&myData->mutex);
}


#ifdef TARGET_OS_IPHONE			
void MyAudioSessionInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
    myprintf("MyAudioSessionInterruptionListener\n");
}
#endif

void MyReadStreamCallBack (CFReadStreamRef stream,
                           CFStreamEventType eventType,
                           void* dataIn)
{
    AudioStreamer *myData = (AudioStreamer *)dataIn;
    
    CFHTTPMessageRef reply = (CFHTTPMessageRef) CFReadStreamCopyProperty(stream, 
                                                                         kCFStreamPropertyHTTPResponseHeader);
    int statusCode = -1;
    
    if (reply) {
        statusCode = CFHTTPMessageGetResponseStatusCode(reply);
        CFRelease(reply);
    }
    	
	if (eventType == kCFStreamEventErrorOccurred)
	{
        CFStreamError error = CFReadStreamGetError(stream);
        myprintf("kCFStreamEventErrorOccurred: %d, %d", error.domain, error.error);

		myData->failed = true;
	}
	else if (eventType == kCFStreamEventEndEncountered)
	{
		if (myData->failed || myData->finished)
		{
			return;
		}
		
		//
		// If there is a partially filled buffer, pass it to the AudioQueue for
		// processing
		//
		if (myData->bytesFilled)
		{
			MyEnqueueBuffer(myData);
		}

		//
		// If the AudioQueue started, then flush it (to make certain everything
		// sent thus far will be processed) and subsequently stop the queue.
		//
		if (myData->started)
		{
			OSStatus err = AudioQueueFlush(myData->audioQueue);
			if (err) {
                myprintf("AudioQueueFlush (%d)\n", err);
                myData->error_status = err;
                return;
            }
			
			err = AudioQueueStop(myData->audioQueue, false);
			if (err) {
                myprintf("AudioQueueStop (%d)\n", err);
                myData->error_status = err;
                return;
            }

			CFReadStreamClose(stream);
			CFRelease(stream);
			myData->stream = nil;
		}
		else
		{
			// If we have reached the end of the file without starting, then we
			// have failed to find any audio in the file. Abort.
			//
            myprintf("EOF without starting\n");

			myData->failed = true;
		}
	}
	else if (eventType == kCFStreamEventHasBytesAvailable)
	{
		if (myData->failed || myData->finished)
		{
			return;
		}
		
		//
		// Read the bytes from the stream
		//
		UInt8 bytes[kAQBufSize];
		CFIndex length = CFReadStreamRead(stream, bytes, kAQBufSize);
		
		if (length == -1)
		{
            myprintf("CFReadStreamRead (%d)\n", -1);

            myData->error_status = -1;
			myData->failed = true;
			return;
		}
		
		//
		// Parse the bytes read by sending them through the AudioFileStream
		//
		if (length > 0)
		{
			OSStatus err = AudioFileStreamParseBytes(myData->audioFileStream, length, bytes, myData->discontinuous ? kAudioFileStreamParseFlag_Discontinuity : 0);
			if (err) { 
                myprintf("AudioFileStreamParseBytes (%d)\n", err);
                myData->error_status = err;
                myData->failed = true;
            }
        }
	}
}


@implementation AudioStreamer

@synthesize isPaused;

- (void) setURL: (NSURL *) newURL
{
    url = [newURL retain];
}

- (NSURL *) getURL
{
    return url;   
}

- (id) init
{
    isRunning = false;
    error_status = 0;
    
#ifdef TARGET_OS_IPHONE____X		
	AudioSessionInitialize (NULL,
                            NULL,
                            MyAudioSessionInterruptionListener,
                            self);
    
	UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
	AudioSessionSetProperty (kAudioSessionProperty_AudioCategory,
                             sizeof (sessionCategory),
                             &sessionCategory);
	AudioSessionSetActive(true);
#endif
    
	// initialize a mutex and condition so that we can block on buffers in use.
	pthread_mutex_init(&mutex, NULL);
	pthread_cond_init(&cond, NULL);
	pthread_mutex_init(&mutex2, NULL);
    return self;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
    [self stop];
    //AudioSessionSetActive(false);

	[url release];
	[super dealloc];
}


- (void)startDataPump
{
	[self retain];
	isRunning = true;
    
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	    
	// create an audio file stream parser
	OSStatus err = AudioFileStreamOpen(self,
                                       MyPropertyListenerProc, 
                                       MyPacketsProc, 
                                       0,
                                       &audioFileStream);  
    
    if (err) {
        myprintf("AudioFileStreamOpen (%d)\n", err);
        error_status = err;
        goto cleanup;
    }
    
    
    CFHTTPMessageRef message = CFHTTPMessageCreateRequest(NULL, (CFStringRef)@"GET", (CFURLRef)url, kCFHTTPVersion1_1);
    //CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Cache-Control"), CFSTR("no-cache"));
    
    stream = CFReadStreamCreateForHTTPRequest(NULL, message);
    
    CFRelease(message);
    
    
    if (!CFReadStreamOpen(stream))
	{
        CFRelease(stream);
		goto cleanup;
    }
    
	//
	// Set our callback function to receive the data
	//
	CFStreamClientContext context = {0, self, NULL, NULL, NULL};
	CFReadStreamSetClient(stream,
                          kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered,
                          MyReadStreamCallBack,
                          &context);

	CFReadStreamScheduleWithRunLoop(stream, 
                                    CFRunLoopGetCurrent(), 
                                    kCFRunLoopCommonModes);
	do
	{
		CFRunLoopRunInMode(kCFRunLoopDefaultMode,
                           0.25,
                           false);   
	
    } while (!finished && !failed);
	
cleanup:
    if (started) {
        AudioQueueStop(audioQueue, true);
        
        for (unsigned int i = 0; i < kNumAQBufs; ++i) {
            err = AudioQueueFreeBuffer(audioQueue, audioQueueBuffer[i]);
            if (err) {
                myprintf("AudioQueueFreeBuffer (%d)\n", err);
            }
        }
        
    
        AudioFileStreamClose(audioFileStream);
        AudioQueueDispose(audioQueue, true);
    }
    
    if (stream) {
        CFReadStreamClose(stream);
        CFRelease(stream);
        stream = NULL;
	}
    
/*
 if (failed && error_status != -308) 
    {
        UIAlertView *alert = [UIAlertView alloc];
        [[alert initWithTitle:@"Playback Error" 
                      message:@"We couldn't play the selected file, or a network error occured."
                     delegate:self
            cancelButtonTitle:nil 
            otherButtonTitles:@"Ok", nil] autorelease];
        [alert show];    
    }
*/   
    myprintf("media       %d\n", error_status);
    
    [pool release];

    isRunning = false;
  
	[self release];
}
//
// start
//
// Calls startInternal in a new thread.
//
- (void)play: (NSURL *) newURL
{
    url = [newURL retain];

    isPaused = NO;
    userAborted = NO;
    finished = NO;
    failed = false;
    
	[NSThread detachNewThreadSelector:@selector(startDataPump) toTarget:self withObject:nil];
}

- (void)pause
{
    if( isPaused )
        AudioQueueStart( audioQueue, NULL );
    else
        AudioQueuePause( audioQueue );
    
    isPaused = !isPaused;
    isPaused = isPaused;
}

- (void) stop
{
    finished = true;
    
    pthread_mutex_lock(&mutex);
	pthread_cond_signal(&cond);
	pthread_mutex_unlock(&mutex);
    
    while (isRunning)
        [NSRunLoop currentRunLoop];
}

- (Float64)getCurrentTime
{
    AudioTimeStamp ts;
    AudioQueueGetCurrentTime(audioQueue, NULL, &ts, NULL);
    
    AudioStreamBasicDescription asbd;
    UInt32 asbdSize = sizeof(asbd);
    AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
        
    return ts.mSampleTime / asbd.mSampleRate;  // do we need to * mSampleTime by mRateScalar?
}

- (BOOL) isDonePlaying
{
    return finished && !userAborted;   
}


@end
