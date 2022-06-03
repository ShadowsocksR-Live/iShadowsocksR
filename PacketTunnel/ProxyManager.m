//
//  ProxyManager.m
//
//  Created by LEI on 2/23/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

#import "ProxyManager.h"
#import <ShadowPath/ShadowPath.h>
#import <netinet/in.h>
#import "Profile.h"
#include <ssrNative/ssrNative.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
static DDLogLevel ddLogLevel = DDLogLevelWarning;

@interface ProxyManager () {
    ProxyCompletion _shadowsocksCompletion;
    
    BOOL _httpProxyRunning;
    ProxyCompletion _httpCompletion;
}
- (void)onHttpProxyCallback: (int)fd;
- (void)onShadowsocksCallback:(int)fd;
@end

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
    config->over_tls_enable = (profile.ot_enable != NO);
    string_safe_assign(&config->over_tls_server_domain, profile.ot_domain.UTF8String);
    string_safe_assign(&config->over_tls_path, profile.ot_path.UTF8String);
    
    return config;
}

void shadowsocks_handler(int fd, void *udata) {
    ProxyManager *provider = (__bridge ProxyManager *)udata;
    [provider onShadowsocksCallback:fd];
}

struct ssr_client_state *g_state = NULL;
void feedback_state(struct ssr_client_state *state, void *p) {
    g_state = state;
    shadowsocks_handler(ssr_get_listen_socket_fd(state), p);
    state_set_force_quit(state, true, 1000);
}

void info_callback(int dump_level, const char *info, void *p) {
    DDLogWarn(@"%s", info);
}

void ssr_main_loop(Profile *profile, unsigned short listenPort, const char *appPath, void *context) {
    struct server_config *config = NULL;
    do {
        config = build_config_object(profile, listenPort);
        if (config == NULL) {
            break;
        }
        
        if (config->method == NULL || config->password==NULL || config->remote_host==NULL) {
            break;
        }
        
        config_ssrot_revision(config);
        
        set_app_name(appPath);
        [DDLog addLogger:[DDASLLogger sharedInstance]]; // ASL = Apple System Logs
        set_dump_info_callback(&info_callback, context);
        ssr_run_loop_begin(config, &feedback_state, context);
        g_state = NULL;
    } while(0);
    
    config_release(config);
}

void ssr_stop(void) {
    ssr_run_loop_shutdown(g_state);
}

@implementation ProxyManager {
    int _socksProxyPort;
}

+ (ProxyManager *)sharedManager {
    static dispatch_once_t onceToken;
    static ProxyManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [ProxyManager new];
    });
    return manager;
}

# pragma mark - Shadowsocks 

- (void) startShadowsocks:(NSURL*)proxyConfUrl completion:(ProxyCompletion)completion {
    _shadowsocksCompletion = [completion copy];
    [NSThread detachNewThreadSelector:@selector(_startShadowsocks:) toTarget:self withObject:proxyConfUrl];
}

- (void)_startShadowsocks:(NSURL*)proxyConfUrl {
    NSString *confContent = [NSString stringWithContentsOfURL:proxyConfUrl encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[confContent dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingAllowFragments error:nil];
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
        _socksProxyPort = sock_port(fd);
    } else {
        error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:100 userInfo:@{NSLocalizedDescriptionKey: @"Fail to start http proxy"}];
    }
    if (_shadowsocksCompletion) {
        _shadowsocksCompletion(_socksProxyPort, error);
    }
}

# pragma mark - Http Proxy

- (void) startHttpProxyServer:(NSURL*)httpProxyConfUrl completion:(ProxyCompletion)completion {
    _httpCompletion = [completion copy];
    NSAssert(httpProxyConfUrl, @"httpProxyConfUrl must have a valid value!");
    [NSThread detachNewThreadSelector:@selector(_startHttpProxyServer:) toTarget:self withObject:httpProxyConfUrl];
}

void http_proxy_handler(int fd, void *udata) {
    ProxyManager *provider = (__bridge ProxyManager *)udata;
    [provider onHttpProxyCallback:fd];
}

- (void)_startHttpProxyServer: (NSURL *)confURL {
    struct forward_spec *proxy = NULL;
    if (_socksProxyPort > 0) {
        proxy = calloc(1, sizeof(*proxy));
        proxy->type = SOCKS_5;
        proxy->gateway_host = "127.0.0.1";
        proxy->gateway_port = _socksProxyPort;
    }
    shadowpath_main(strdup([[confURL path] UTF8String]), proxy, http_proxy_handler, (__bridge void *)self);
}

- (void)onHttpProxyCallback:(int)fd {
    NSError *error;
    int httpProxyPort = 0;
    if (fd > 0) {
        httpProxyPort = sock_port(fd);
        _httpProxyRunning = YES;
    }else {
        error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:100 userInfo:@{NSLocalizedDescriptionKey: @"Fail to start http proxy"}];
    }
    if (_httpCompletion) {
        _httpCompletion(httpProxyPort, error);
    }
}

- (void)stopHttpProxy {
//    polipoExit();
//    _httpProxyRunning = NO;
}

@end

