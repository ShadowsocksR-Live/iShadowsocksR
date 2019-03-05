//
//  InfoInternal.h
//
//  Created by ssrlive on 2019/1/19.
//  Copyright © 2019 TouchingApp. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface InfoInternal : NSObject
+ (instancetype) sharedInstance;
- (instancetype) init NS_UNAVAILABLE;
- (NSString *) getGroupIdentifier;
- (NSString *) getLogglyAPIKey;
@end

NS_ASSUME_NONNULL_END
