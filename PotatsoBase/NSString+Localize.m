//
//  NSString+Localize.m
//
//  Created by ssrlive on 2019/1/29.
//  Copyright © 2019 ssrLive. All rights reserved.
//

#import "NSString+Localize.h"

@implementation NSString (Localize)

- (NSString *) localized {
    NSString *path = [[NSBundle mainBundle] pathForResource:[Localize currentLanguage] ofType:@"lproj"];
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    if ([bundle isKindOfClass:[NSBundle class]]) {
        return [bundle localizedStringForKey:self value:nil table:nil];
    } else {
        path = [[NSBundle mainBundle] pathForResource:@"Base" ofType:@"lproj"];
        bundle = [NSBundle bundleWithPath:path];
        if ([bundle isKindOfClass:[NSBundle class]]) {
            return [bundle localizedStringForKey:self value:nil table:nil];
        }
    }
    return self;
}

+ (NSString *) stringLocalizedFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *s = [[NSString alloc] initWithFormat:[format localized] arguments:args];
    va_end(args);
    return s;
}

+ (NSString *) stringLocalizedPlural:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *s = [[NSString alloc] initWithFormat:[format localized]
                                            locale:[NSLocale currentLocale]
                                         arguments:args];
    va_end(args);
    return s;
}

@end


static NSString *const LCLCurrentLanguageKey = @"LCLCurrentLanguageKey";
static NSString *const LCLDefaultLanguage = @"en";

@implementation Localize

+ (NSArray<NSString *> *) availableLanguages {
    return [[NSBundle mainBundle] localizations];
}

+ (NSString *) currentLanguage {
    NSString *currentLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:LCLCurrentLanguageKey];
    if ([currentLanguage isKindOfClass:[NSString class]]) {
        return currentLanguage;
    }
    return [self defaultLanguage];
}

+ (void) setCurrentLanguage:(NSString *)currentLanguage {
    NSString *selectedLanguage = [[self availableLanguages] containsObject:currentLanguage] ? currentLanguage : [self defaultLanguage];
    if ([selectedLanguage isEqualToString:[self currentLanguage]] == NO) {
        [[NSUserDefaults standardUserDefaults] setObject:selectedLanguage forKey:LCLCurrentLanguageKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:LCLLanguageChangeNotification object:nil];
    }
}

+ (NSString *) defaultLanguage {
    NSString *defaultLanguage = nil;
    NSString *preferredLanguage = [[NSBundle mainBundle] preferredLocalizations].firstObject;
    if ([preferredLanguage isKindOfClass:[NSString class]] == NO) {
        return LCLDefaultLanguage;
    }
    NSArray<NSString *> *availableLanguages = [self availableLanguages];
    if ([availableLanguages containsObject:preferredLanguage]) {
        defaultLanguage = preferredLanguage;
    } else {
        defaultLanguage = LCLDefaultLanguage;
    }
    return defaultLanguage;
}

+ (void) resetCurrentLanguageToDefault {
    [self setCurrentLanguage:[self defaultLanguage]];
}

+ (NSString *) displayNameForLanguage:(NSString *)language {
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:[self currentLanguage]];
    NSString *displayName = [locale displayNameForKey:locale.languageCode value:language];
    if ([displayName isKindOfClass:[NSString class]]) {
        return displayName;
    }
    return @"";
}

@end
