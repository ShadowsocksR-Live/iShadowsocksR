//
//  serverConnectivity.c
//

#include "serverConnectivity.h"

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <errno.h>
#include <netinet/in.h>
#include <string.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>

#define MAXDATASIZE 100

int serverConnectivity(const char *host, int port) {
    int cliSock = -1;

    int result = -1;
    struct addrinfo *addr = NULL;

    do {
        if (host==NULL || port==0) {
            break;
        }
        struct addrinfo hints = { 0 };
        hints.ai_flags = AI_NUMERICHOST;
        hints.ai_family = AF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        hints.ai_protocol = IPPROTO_TCP;
        
        struct hostent *he = NULL;
        struct sockaddr_in dest_addr = { 0 };

        if (getaddrinfo(host, NULL, &hints, &addr) != 0) {
            if ((he = gethostbyname(host)) == NULL) {
                break;
            }
            
            dest_addr.sin_family = AF_INET;
            dest_addr.sin_port = htons(port);
            dest_addr.sin_addr = *((struct in_addr *)he->h_addr);
        }
        
        if (addr) {
        if ((cliSock = socket(addr->ai_family, addr->ai_socktype, 0)) == -1) {
            printf("Socket Error: %d\n", errno);
            break;
        } else {
            printf("Client Socket %d created\n", cliSock);
        }

        if (addr->ai_family == AF_INET) {
            ((struct sockaddr_in *)addr->ai_addr)->sin_port = htons(port);
        } else if (addr->ai_family == AF_INET6) {
            ((struct sockaddr_in6 *)addr->ai_addr)->sin6_port = htons(port);
        }

        int c = connect(cliSock, addr->ai_addr, addr->ai_addrlen);
        if (c != 0) {
            printf("Connect Error: %d\n", errno);
            break;
        } else {
            printf("Client Connection created\n");
        }
        } else {
            if ((cliSock = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
                break;
            }
            int c = connect(cliSock, (struct sockaddr *)&dest_addr, sizeof(struct sockaddr));
            if (c != 0) {
                break;
            }
        }

        /*
        {
            int numbytes;
            char buf[MAXDATASIZE], msg[MAXDATASIZE];

            sprintf(msg, "4 8 15 16 23 42");
            send(cliSock, msg, MAXDATASIZE, 0);
            printf("Client sent %s to %s\n", msg, inet_ntoa(dest_addr.sin_addr));

            numbytes = recv(cliSock, buf, MAXDATASIZE, 0);
            buf[numbytes] = '\0';
            printf("Received Message: %s\n", buf);
        }
        // */

        result = 0;
    } while (0);
    
    if (addr) {
        freeaddrinfo(addr);
    }
    
    if (cliSock != -1) {
        close(cliSock);
        printf("Client Sockets closed\n");
    }

    return result;
}

int convertHostNameToIpString (const char *host, char *ipString, size_t len) {
    int result = -1;
    do {
        if (host==NULL || ipString==NULL || len<16) {
            break;
        }
        struct hostent *he;

        if ((he = gethostbyname(host)) == NULL) {
            printf("Couldn't get hostname\n");
            break;
        }

        char *ip = inet_ntoa( *((struct in_addr *)he->h_addr) );

        if (ip == NULL) {
            break;
        }
        strncpy(ipString, ip, len);
        result = 0;
    } while (0);
    return result;
}
