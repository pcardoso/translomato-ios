//
//  Translomato.h
//  Translomato
//
//  Created by João on 11/04/14.
//  Copyright (c) 2014 CherryPeek. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define TMATO_BEGIN(x) [[Translomato manager] loadFromGDoc:x withCallbackBlock:^(NSError *error, id response) {
#define TMATO_END }];
#else
#define TMATO_BEGIN(x)
#define TMATO_END
#endif

//#undef NSLocalizedString
//#define NSLocalizedString(key, _comment) [[Translomato manager] translateThis:key comment:_comment]

typedef void (^CallbackBlock) (NSError *error, id response);

@interface Translomato : NSObject {
}

+ (id)manager;
- (NSString *)translateThis:(NSString *)key comment:(NSString *)comment;

// load from gdoc. needs to be published (file -> publish)
- (void)loadFromGDoc:(NSString *)identifier withCallbackBlock:(CallbackBlock)callbackBlock;
@end