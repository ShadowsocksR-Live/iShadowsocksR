//
//  OverTlsWrapper.h
//  overtls
//
//  Created by ssrlive on 2023/4/23.
//

#ifndef OverTlsWrapper_h
#define OverTlsWrapper_h

@interface OverTlsWrapper : NSObject

+ (void) startWithConfig:(NSString*)filePath handler:(void (*)(int port, void *ctx))handler context:(void*)ctx;
+ (void) shutdown;

@end

#endif /* OverTlsWrapper_h */
