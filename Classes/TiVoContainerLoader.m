//
//  TiVoContainerLoader.m
//  ConnectT
//
//  Created by DougT on 1/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TiVoContainer.h"
#import "TiVoContainerLoader.h"


@implementation TiVoContainerLoader


- (void)dealloc {
    [super dealloc];
    
    [containers release];
    [currentStringValue release];
}

-(void) setListener: (id) list
{
    listener = list;
}

-(void) load: (NSString*) url
{
    [self retain];
    
    container = nil;
    
    //printf("loading... %s\n", [url UTF8String]);
    pool = [[NSAutoreleasePool alloc] init];

    if (containers)
        [containers release];
    
    containers = [[NSMutableArray alloc] init];
    
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
    addingURL = NO;
    addingDetails = NO;    
}


- (void)postTitle:(NSString*) title
{
    SEL callback = @selector(tivoContaierTitleUpdated:);
    NSMethodSignature* signature = [listener methodSignatureForSelector: callback];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:listener];
    [invocation setSelector:callback];
    [invocation setArgument:&title atIndex:2];
    
    // Since the callback might touch the UI, we need to make sure that the callback happens
    // on the UI thread.    
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];    
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    // broadcast! containers;

    // notify any listeners of the change
    SEL callback = @selector(tivoContaiersUpdated:);
    NSMethodSignature* signature = [listener methodSignatureForSelector: callback];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:listener];
    [invocation setSelector:callback];
    [invocation setArgument:&containers atIndex:2];
    
    // Since the callback might touch the UI, we need to make sure that the callback happens
    // on the UI thread.    
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{        
    
    if (currentStringValue)
        [currentStringValue release];
    
    currentStringValue = [[NSMutableString alloc] initWithCapacity:50];
    
    if ([elementName isEqualToString:@"Item"]) {
        container = [[TiVoContainer alloc] init];
        return;
    }
    
    if ([elementName isEqualToString:@"Details"]) {
        
        if (container)
        {
            addingDetails = YES;
        }
        return;
    }
    
    if ([elementName isEqualToString:@"Url"]) {
        addingURL = YES;
        return;
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
    if (!container)
    {
        if ([elementName isEqualToString:@"Title"])
        {
            [self postTitle: currentStringValue];
        }
            
        [currentStringValue release];
        currentStringValue = NULL;
        return;
    }
    
    if ([elementName isEqualToString:@"Item"]) {
        [containers addObject: container];
        [container release];
        return;
    }
    
    if ([elementName isEqualToString:@"Url"]) {
        [container setURL:currentStringValue];
        [currentStringValue release];
        currentStringValue = NULL;
        return;
    }
    
    if ([elementName isEqualToString:@"Details"]) {
        if (container)
        {
            addingDetails = NO;
        }
        return;
    }
    
    if (addingDetails == YES) {
        // stuff I do not care about:
        
        if (![elementName isEqualToString:@"Links"] && 
            ![elementName isEqualToString:@"Content"] ) {
            
            [container addDetail:elementName withValue:currentStringValue];
        }
        
        [currentStringValue release];
        currentStringValue = NULL;
        return;
    }
    
    if ([elementName isEqualToString:@"Details"]) {
        addingDetails = NO;
        return;
    }
}

@end
