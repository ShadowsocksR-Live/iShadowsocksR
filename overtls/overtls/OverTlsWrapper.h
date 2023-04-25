//
//  OverTlsWrapper.h
//  overtls
//
//  Created by ssrlive on 2023/4/23.
//

#ifndef OverTlsWrapper_h
#define OverTlsWrapper_h

@interface OverTlsWrapper : NSObject

+ (void) startWithConfig:(NSString*)config handler:(void (*)(int, void *))handler context:(void*)context;
+ (void) shutdown;

@end

#endif /* OverTlsWrapper_h */
