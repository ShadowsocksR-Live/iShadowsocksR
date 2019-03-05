//
//  NSString+Localize.h
//
//  Created by ssrlive on 2019/1/29.
//  Copyright © 2019 ssrLive. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Localize)
- (NSString *) localized;
+ (NSString *) stringLocalizedFormat:(NSString *)format, ...;
+ (NSString *) stringLocalizedPlural:(NSString *)format, ...;
@end


static NSString *const LCLLanguageChangeNotification = @"LCLLanguageChangeNotification";

@interface Localize : NSObject
@property(nonatomic, strong, class, readonly) NSArray<NSString *> * availableLanguages;
@property(nonatomic, strong, class) NSString * currentLanguage;
@property(nonatomic, strong, class, readonly) NSString * defaultLanguage;
+ (void) resetCurrentLanguageToDefault;
+ (NSString *) displayNameForLanguage:(NSString *)language;
@end

NS_ASSUME_NONNULL_END
