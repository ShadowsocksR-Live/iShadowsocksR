//
//  ProxyManager.m
//  Potatso
//
//  Created by LEI on 2/23/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

#import "ProxyManager.h"
#import <ShadowPath/ShadowPath.h>
#import <netinet/in.h>
#import "PotatsoBase.h"
#import "Profile.h"
#include <ssrLocal/ssrLocal.h>

@interface ProxyManager () {
    int _shadowsocksProxyPort;
    ShadowsocksProxyCompletion _shadowsocksCompletion;
    
    SocksProxyCompletion _socksCompletion;
    BOOL _socksProxyRunning;
    
    BOOL _httpProxyRunning;
    HttpProxyCompletion _httpCompletion;
}
- (void)onSocksProxyCallback: (int)fd;
- (void)onHttpProxyCallback: (int)fd;
- (void)onShadowsocksCallback:(int)fd;
@end

void http_proxy_handler(int fd, void *udata) {
    ProxyManager *provider = (__bridge ProxyManager *)udata;
    [provider onHttpProxyCallback:fd];
}

void shadowsocks_handler(int fd, void *udata) {
    ProxyManager *provider = (__bridge ProxyManager *)udata;
    [provider onShadowsocksCallback:fd];
}

int sock_port (int fd) {
    struct sockaddr_in sin;
    socklen_t len = sizeof(sin);
    if (getsockname(fd, (struct sockaddr *)&sin, &len) < 0) {
        NSLog(@"getsock_port(%d) error: %s",
              fd, strerror (errno));
        return 0;
    }else{
        return ntohs(sin.sin_port);
    }
}

struct server_config * build_config_object(Profile *profile, unsigned short listenPort) {
    const char *protocol = profile.protocol.UTF8String;
    if (protocol && strcmp(protocol, "verify_sha1") == 0) {
        // LOGI("The verify_sha1 protocol is deprecate! Fallback to origin protocol.");
        protocol = NULL;
    }
    
    struct server_config *config = config_create();
    
    config->udp = true;
    config->listen_port = listenPort;
    string_safe_assign(&config->method, profile.method.UTF8String);
    string_safe_assign(&config->remote_host, profile.server.UTF8String);
    config->remote_port = (unsigned short) profile.serverPort;
    string_safe_assign(&config->password, profile.password.UTF8String);
    string_safe_assign(&config->protocol, protocol);
    string_safe_assign(&config->protocol_param, profile.protocolParam.UTF8String);
    string_safe_assign(&config->obfs, profile.obfs.UTF8String);
    string_safe_assign(&config->obfs_param, profile.obfsParam.UTF8String);
    
    return config;
}

struct ssr_local_state *g_state = NULL;

void feedback_state(struct ssr_local_state *state, void *p) {
    g_state = state;
    shadowsocks_handler(ssr_Local_listen_socket_fd(state), p);
}

void ssr_main_loop(Profile *profile, unsigned short listenPort, const char *appPath, void *context) {
    struct server_config *config = NULL;
    do {
        //set_app_name(appPath);
        config = build_config_object(profile, listenPort);
        if (config == NULL) {
            break;
        }
        
        if (config->method == NULL || config->password==NULL || config->remote_host==NULL) {
            break;
        }
        
        ssr_local_main_loop(config, &feedback_state, context);
        g_state = NULL;
    } while(0);
    
    config_release(config);
}

void ssr_stop(void) {
   // ssr_run_loop_shutdown(g_state);
}

@implementation ProxyManager

+ (ProxyManager *)sharedManager {
    static dispatch_once_t onceToken;
    static ProxyManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [ProxyManager new];
    });
    return manager;
}

- (void)startSocksProxy:(SocksProxyCompletion)completion {
    _socksCompletion = [completion copy];
    NSString *confContent = [NSString stringWithContentsOfURL:[Potatso sharedSocksConfUrl] encoding:NSUTF8StringEncoding error:nil];
    confContent = [confContent stringByReplacingOccurrencesOfString:@"${ssport}" withString:[NSString stringWithFormat:@"%d", _shadowsocksProxyPort]];
    int fd = [[AntinatServer sharedServer] startWithConfig:confContent];
    [self onSocksProxyCallback:fd];
}

- (void)stopSocksProxy {
    [[AntinatServer sharedServer] stop];
    _socksProxyRunning = NO;
}

- (void)onSocksProxyCallback:(int)fd {
    NSError *error;
    if (fd > 0) {
        _socksProxyPort = sock_port(fd);
        _socksProxyRunning = YES;
    }else {
        error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:100 userInfo:@{NSLocalizedDescriptionKey: @"Fail to start socks proxy"}];
    }
    if (_socksCompletion) {
        _socksCompletion(_socksProxyPort, error);
    }
}

# pragma mark - Shadowsocks 

- (void)startShadowsocks: (ShadowsocksProxyCompletion)completion {
    _shadowsocksCompletion = [completion copy];
    [NSThread detachNewThreadSelector:@selector(_startShadowsocks) toTarget:self withObject:nil];
}

- (void)_startShadowsocks {
    NSString *confContent = [NSString stringWithContentsOfURL:[Potatso sharedProxyConfUrl] encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *json = [confContent jsonDictionary];
    Profile *profile = [[Profile alloc] initWithJSONDictionary:json];
    profile.listenPort = 0;
    
    if (profile.server.length && profile.serverPort && profile.password.length) {
        NSString *path = [NSBundle mainBundle].executablePath;
        ssr_main_loop(profile, profile.listenPort, path.UTF8String, (__bridge void *)(self));
    }else {
        if (_shadowsocksCompletion) {
            _shadowsocksCompletion(0, nil);
        }
        return;
    }
}

- (void)stopShadowsocks {
    ssr_stop();
}

- (void)onShadowsocksCallback:(int)fd {
    NSError *error;
    if (fd > 0) {
        _shadowsocksProxyPort = sock_port(fd);
    } else {
        error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:100 userInfo:@{NSLocalizedDescriptionKey: @"Fail to start http proxy"}];
    }
    if (_shadowsocksCompletion) {
        _shadowsocksCompletion(_shadowsocksProxyPort, error);
    }
}

# pragma mark - Http Proxy

- (void)startHttpProxy:(HttpProxyCompletion)completion {
    _httpCompletion = [completion copy];
    [NSThread detachNewThreadSelector:@selector(_startHttpProxy:) toTarget:self withObject:[Potatso sharedHttpProxyConfUrl]];
}

- (void)_startHttpProxy: (NSURL *)confURL {
    struct forward_spec *proxy = NULL;
    if (_shadowsocksProxyPort > 0) {
        proxy = calloc(1, sizeof(*proxy));
        proxy->type = SOCKS_5;
        proxy->gateway_host = "127.0.0.1";
        proxy->gateway_port = _shadowsocksProxyPort;
    }
    shadowpath_main(strdup([[confURL path] UTF8String]), proxy, http_proxy_handler, (__bridge void *)self);
}

- (void)stopHttpProxy {
//    polipoExit();
//    _httpProxyRunning = NO;
}

- (void)onHttpProxyCallback:(int)fd {
    NSError *error;
    if (fd > 0) {
        _httpProxyPort = sock_port(fd);
        _httpProxyRunning = YES;
    }else {
        error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:100 userInfo:@{NSLocalizedDescriptionKey: @"Fail to start http proxy"}];
    }
    if (_httpCompletion) {
        _httpCompletion(_httpProxyPort, error);
    }
}

@end

