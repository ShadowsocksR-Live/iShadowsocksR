//
//  ProxyManager.h
//
//  Created by LEI on 2/23/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SocksProxyCompletion)(int port, NSError *error);
typedef void(^HttpProxyCompletion)(int port, NSError *error);
typedef void(^ShadowsocksProxyCompletion)(int port, NSError *error);

extern int sock_port (int fd);

@interface ProxyManager : NSObject

+ (ProxyManager *)sharedManager;
@property (nonatomic, readonly) int socksProxyPort;
@property (nonatomic, readonly) int httpProxyPort;
- (void)startSocksProxy: (SocksProxyCompletion)completion;
- (void)stopSocksProxy;
- (void)startHttpProxy: (HttpProxyCompletion)completion;
- (void)stopHttpProxy;
- (void)startShadowsocks: (ShadowsocksProxyCompletion)completion;
- (void)stopShadowsocks;
@end
