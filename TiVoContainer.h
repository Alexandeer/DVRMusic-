//
//  TiVoContainer.h
//  ConnectT
//
//  Created by DougT on 1/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TiVoContainer;

@interface TiVoContainer : NSObject {
  NSMutableString     *url;
  NSMutableDictionary *details;
}

- (void)setURL:(NSString*)url;
- (NSString *) getURL;

- (void)addDetail:(NSString*) elementName withValue: (NSString*) currentStringValue;
- (NSString *) getDetail:(NSString *)key;


- (void)dump;

@end
