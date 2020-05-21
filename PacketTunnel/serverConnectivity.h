//
//  serverConnectivity.h
//

#ifndef serverConnectivity_h
#define serverConnectivity_h

#include <stdio.h>

int serverConnectivity(const char *host, int port);
int convertHostNameToIpString (const char *host, char *ipString, size_t len);

#endif /* serverConnectivity_h */
