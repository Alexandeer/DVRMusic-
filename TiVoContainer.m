//
//  TiVoContainer.m
//  ConnectT
//
//  Created by DougT on 1/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TiVoContainer.h"


@implementation TiVoContainer

- (id)init
{
    [super init];
    details = [[NSMutableDictionary alloc] init];
    url = NULL;
    return self;
}

- (void)setURL:(NSString*) aUrl
{
    url = [aUrl copy];
}

- (NSString *) getURL
{
    return url;   
}


- (void)addDetail:(NSString*) elementName withValue: (NSString*) value
{
    if (value == nil || elementName == nil)
        return;
    
    [details setObject:value forKey:elementName];
}

- (NSString *) getDetail:(NSString *)key
{
    return [details objectForKey:key];
}


- (void)dealloc
{
    [url release];
    [details release];
    
	[super dealloc];
}


- (void)dump {
    printf("---- url=%s\n", [url UTF8String]);
    
    id key;
    NSEnumerator *keys = [details keyEnumerator];
    while (key = [keys nextObject])
    {
        printf("\t%s=%s\n",
                [key UTF8String], 
                [[details objectForKey:key] UTF8String]);
    }
    
    

}

@end
