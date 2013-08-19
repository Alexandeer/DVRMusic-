//
//  TiVoContainerLoader.h
//  ConnectT
//
//  Created by DougT on 1/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TiVoServerLoader : NSObject {
    id               listener;
    NSMutableString  *currentStringValue;
    
    Boolean isImage;
    NSMutableString* currentURL;
    NSAutoreleasePool *pool;
}

-(void) load: (NSString*) url;
-(void) setListener: (id) list;

@end
