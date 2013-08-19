//
//  TiVoContainerLoader.m
//  ConnectT
//
//  Created by DougT on 1/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TiVoContainer.h"
#import "TiVoServerLoader.h"


@implementation TiVoServerLoader


- (void)dealloc {
    [super dealloc];
    
    [currentStringValue release];
}

-(void) setListener: (id) list
{
    listener = list;
}

-(void) load: (NSString*) url
{
    [self retain];
        
    //printf("loading... %s\n", [url UTF8String]);
    pool = [[NSAutoreleasePool alloc] init];
    
    NSMutableURLRequest *theRequest=[NSMutableURLRequest
                                     requestWithURL: [NSURL URLWithString:url]
                                     cachePolicy:NSURLRequestUseProtocolCachePolicy
                                     timeoutInterval:10.0];
    NSURLResponse *theResponse = NULL;
    NSError *nserror = NULL;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    NSData *data = [[[NSURLConnection sendSynchronousRequest: theRequest
                                           returningResponse: &theResponse
                                                       error: &nserror] retain] autorelease];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (!data) {
        UIAlertView *alert = [UIAlertView alloc];
        [[alert initWithTitle:@"Connection Error" 
                      message:@"We couldn't connect to the Tivo Desktop."
                     delegate:self
            cancelButtonTitle:nil 
            otherButtonTitles:@"Ok", nil] autorelease];
        [alert show];    
        return;
    }
    
    Class NSXMLParserClass = NSClassFromString(@"NSXMLParser");
    NSXMLParser *xmlParser = [[[NSXMLParserClass alloc] initWithData:data] autorelease];
    [xmlParser setDelegate:self];
    [xmlParser parse];

    [pool release];
    [self release];
    
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
}


- (void)postURL:(NSString*) url
{
    SEL callback = @selector(tivoServerFound:);
    NSMethodSignature* signature = [listener methodSignatureForSelector: callback];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:listener];
    [invocation setSelector:callback];
    [invocation setArgument:&url atIndex:2];
    
    // Since the callback might touch the UI, we need to make sure that the callback happens
    // on the UI thread.    
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];    
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{        
    
    if (currentStringValue)
        [currentStringValue release];
    
    currentStringValue = [[NSMutableString alloc] initWithCapacity:50];

    if ([elementName isEqualToString:@"Item"])
    {
        isImage = false;
        [currentURL release];
        currentURL = NULL;
    }
                                    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!currentStringValue) {
        // currentStringValue is an NSMutableString instance variable
        currentStringValue = [[NSMutableString alloc] initWithCapacity:50];
    }
    [currentStringValue appendString:string];    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    
    if ([elementName isEqualToString:@"Url"]) {
        currentURL = [currentStringValue copy];
        return;
    }
    
    if ([elementName isEqualToString:@"SourceFormat"]) {
        if ([currentStringValue isEqualToString:@"x-container/tivo-photos"])
            isImage = true;
        return;
    }               
    
    if ([elementName isEqualToString:@"Item"] && isImage)
    {
        [self postURL: currentURL];
    }            
}

@end
