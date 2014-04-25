//
//  Translomato.m
//  Translomato
//
//  Created by João on 11/04/14.
//  Copyright (c) 2014 CherryPeek. All rights reserved.
//

#import "Translomato.h"
#import <objc/runtime.h>

#define kGDocIndexAddress @"https://spreadsheets.google.com/feeds/worksheets/%@/public/basic?alt=json"
#define kGDocSheetAddress @"https://spreadsheets.google.com/feeds/list/%@/%@/public/values?alt=json"

// simple gcd based json fetcher
void _fetchJSON(NSString *url, CallbackBlock completion)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,0), ^{
        NSError *error = nil;
        NSString *str = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:url]
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];
        if (error) {
            completion(error, nil);
            return;
        }
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:0
                                                               error:&error];
        if (error) {
            completion(error, nil);
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, json);
        });
    });

}

#pragma mark - language helper

@interface TMTLanguage : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *title;
+ (TMTLanguage *)languageWithKey:(NSString *)key title:(NSString *)title;


@end

@implementation TMTLanguage

+ (TMTLanguage *)languageWithKey:(NSString *)key title:(NSString *)title {
    TMTLanguage *lang = [[TMTLanguage alloc] init];
    lang.key = key;
    lang.title = title;
    return lang;
}

@end

#pragma mark - NSBundle Method Swizzling

@interface NSBundle (Translomato)
@end

@implementation NSBundle (Translomato)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);

        SEL originalSelector = @selector(localizedStringForKey:value:table:);
        SEL swizzledSelector = @selector(translomato_localizedStringForKey:value:table:);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        BOOL didAddMethod = class_addMethod(class,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (NSString *)translomato_localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName NS_FORMAT_ARGUMENT(1)
{
    return [[Translomato manager] translateThis:key comment:nil];
}

@end

#pragma mark - Translomato

@interface Translomato () <UIAlertViewDelegate>
@property (nonatomic, strong) NSString *documentIdentifier;
@property (nonatomic, strong) CallbackBlock callback;
@property (nonatomic, strong) NSArray *languages;
@property (nonatomic, strong) NSDictionary *translations;
@end

@implementation Translomato

+ (id)manager
{
    static Translomato *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (NSString *)translateThis:(NSString *)key comment:(NSString *)comment
{
    NSString *localizedString = [[NSBundle mainBundle] translomato_localizedStringForKey:key
                                                                       value:key
                                                                       table:nil];
    NSString *translatedString = [_translations valueForKey:key];
    return translatedString ?: localizedString;
}

- (void)loadFromGDoc:(NSString *)identifier withCallbackBlock:(CallbackBlock)callbackBlock
{
    self.documentIdentifier = identifier;
    self.callback = callbackBlock;
    [self loadIndex];
}

- (void)loadIndex
{
    NSString *address = [NSString stringWithFormat:kGDocIndexAddress, self.documentIdentifier];

    _fetchJSON(address, ^(NSError *error, id response) {
        NSMutableArray *languages = [NSMutableArray new];

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"lang?"
                                                        message:@"pick one"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:nil];

        for (id item in [response valueForKeyPath:@"feed.entry"]) {
            NSString *title = item[@"content"][@"$t"];
            NSString *key = [[item[@"id"][@"$t"] componentsSeparatedByString:@"/"] lastObject];
            NSLog(@"sheet %@: %@", key, title);
            [languages addObject:[TMTLanguage languageWithKey:key title:title]];
            [alert addButtonWithTitle:title];
        }
        self.languages = languages;
        [alert show];
    });
}

- (void)loadSheet:(NSString *)sheetIdentifier
{
    NSString *address = [NSString stringWithFormat:kGDocSheetAddress, self.documentIdentifier, sheetIdentifier];

    _fetchJSON(address, ^(NSError *error, id response) {
        NSMutableDictionary *translations = [NSMutableDictionary new];

        for (id item in [response valueForKeyPath:@"feed.entry"]) {
            NSString *key = item[@"gsx$key"][@"$t"];
            NSString *value = item[@"gsx$value"][@"$t"];
            [translations setObject:value forKey:key];
        }

        self.translations = translations;
        self.callback(nil, nil);
    });
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if (buttonIndex != alertView.cancelButtonIndex) {
        for (TMTLanguage *item in self.languages) {
            if ([item.title isEqualToString:title]) {
                [self loadSheet:item.key];
                break;
            }
        }
    }
}

@end