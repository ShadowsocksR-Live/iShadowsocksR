//
//  ProxyManager.h
//
//  Created by LEI on 2/23/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ProxyCompletion)(int port, NSError *error);

extern int sock_port (int fd);

@interface ProxyManager : NSObject

+ (ProxyManager *)sharedManager;
- (void)startHttpProxyServer:(NSURL*)httpProxyConfUrl completion:(ProxyCompletion)completion;
- (void)stopHttpProxy;
- (void) startShadowsocks:(NSURL*)proxyConfUrl completion:(ProxyCompletion)completion;
- (void)stopShadowsocks;
@end
