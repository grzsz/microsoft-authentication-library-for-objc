//------------------------------------------------------------------------------
//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
    Factory used by MSAL to obtain the `NSURLSession` for its HTTP requests (token, discovery and metadata endpoints).
    This is the counterpart of `IMsalHttpClientFactory` in MSAL.NET and lets an app route MSAL traffic through
    an HTTP proxy or reuse its own session. Set an instance on `MSALGlobalConfig.httpConfig.httpClientFactory`.

    Implementation guidelines:
    - Implementations must be thread-safe. MSAL calls `urlSession` for every request.
    - Return a long-lived session rather than creating a new one per call.
    - MSAL never invalidates the returned session; its lifetime is owned by the app.
    - Not used for interactive browser traffic (`ASWebAuthenticationSession`, `SFSafariViewController`, `WKWebView`)
      or for broker flows, which run out of process. For `MSALWebviewTypeWKWebView`, pass a `WKWebView` via
      `MSALWebviewParameters.customWebview` whose `WKWebsiteDataStore.proxyConfigurations` is set.

    Proxy example with credentials. Proxy host and port are set on the session configuration, and the 407
    proxy challenge is answered by the session delegate:

    @code
    @interface ProxySessionFactory : NSObject <MSALHttpClientFactory, NSURLSessionTaskDelegate>
    @end

    @implementation ProxySessionFactory
    {
        NSURLSession *_session;
    }

    - (instancetype)init
    {
        self = [super init];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.connectionProxyDictionary = @{ @"HTTPSEnable": @1, @"HTTPSProxy": @"proxy.corp.example", @"HTTPSPort": @8080,
                                              @"HTTPEnable": @1,  @"HTTPProxy": @"proxy.corp.example",  @"HTTPPort": @8080 };
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
        return self;
    }

    - (NSURLSession *)urlSession
    {
        return _session;
    }

    - (void)URLSession:(NSURLSession *)session
                  task:(NSURLSessionTask *)task
    didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
     completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
    {
        if (challenge.protectionSpace.isProxy && challenge.previousFailureCount == 0)
        {
            NSURLCredential *credential = [NSURLCredential credentialWithUser:@"user"
                                                                     password:@"secret"
                                                                  persistence:NSURLCredentialPersistenceForSession];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            return;
        }

        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }

    @end

    MSALGlobalConfig.httpConfig.httpClientFactory = [ProxySessionFactory new];
    @endcode
*/
@protocol MSALHttpClientFactory <NSObject>

/**
    Returns the `NSURLSession` MSAL should use for the next request.
 */
- (NSURLSession *)urlSession;

@end

NS_ASSUME_NONNULL_END
