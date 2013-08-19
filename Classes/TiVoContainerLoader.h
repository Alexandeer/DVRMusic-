//
//  TiVoContainerLoader.h
//  ConnectT
//
//  Created by DougT on 1/20/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TiVoContainerLoader : NSObject {
    id               listener;
    Boolean          addingDetails;
    Boolean          addingURL;
    TiVoContainer    *container;
    NSMutableString  *currentStringValue;
    
    NSAutoreleasePool *pool;
    
    NSMutableArray * containers;

}

-(void) load: (NSString*) url;
-(void) setListener: (id) list;

@end
