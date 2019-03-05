//
//  InfoInternal.m
//
//  Created by ssrlive on 2019/1/19.
//  Copyright © 2019 TouchingApp. All rights reserved.
//

#import "InfoInternal.h"

@implementation InfoInternal {
    NSDictionary<NSString *, id> *_infoDict;
}

+ (instancetype) sharedInstance {
    static id sharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });

    return sharedInstance;
}

- (instancetype) initPrivate {
    if ((self = [super init])) {
        _infoDict = [[NSBundle mainBundle] infoDictionary][@"PotatsoInternal"];
    }
    return self;
}

- (NSString *) getGroupIdentifier {
    return _infoDict[@"GroupIdentifier"];
}

- (NSString *) getLogglyAPIKey {
    return _infoDict[@"LogglyAPIKey"];
}

@end
