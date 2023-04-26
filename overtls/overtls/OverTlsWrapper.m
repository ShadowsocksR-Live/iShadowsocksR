//
//  OverTlsWrapper.m
//  overtls
//
//  Created by ssrlive on 2023/4/23.
//

#import <Foundation/Foundation.h>

#import "OverTlsWrapper.h"
#include "overtls-ios.h"

@implementation OverTlsWrapper

+ (void) startWithConfig:(NSString*)filePath handler:(void (*)(int port, void *ctx))handler context:(void*)ctx {
    over_tls_client_run(filePath.UTF8String, 1, handler, ctx);
}

+ (void) shutdown {
    over_tls_client_stop();
}

@end
