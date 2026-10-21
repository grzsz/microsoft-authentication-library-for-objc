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

#import <XCTest/XCTest.h>
#import "MSALGlobalConfig.h"
#import "MSALHTTPConfig.h"
#import "MSALHttpClientFactory.h"
#import "MSIDURLSessionManager.h"
#import "MSIDHttpRequest.h"

@interface MSALHTTPConfigTestSession : NSURLSession

@property (nonatomic) BOOL invalidateAndCancelCalled;

@end

@implementation MSALHTTPConfigTestSession

- (NSURLSessionConfiguration *)configuration
{
    return [NSURLSessionConfiguration ephemeralSessionConfiguration];
}

- (void)invalidateAndCancel
{
    self.invalidateAndCancelCalled = YES;
}

@end

@interface MSALHTTPConfigTestFactory : NSObject <MSALHttpClientFactory>

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSInteger callCount;

@end

@implementation MSALHTTPConfigTestFactory

- (NSURLSession *)urlSession
{
    self.callCount++;
    return self.session;
}

@end

@interface MSALHTTPConfigTests : XCTestCase

@end

@implementation MSALHTTPConfigTests

- (void)tearDown
{
    MSALGlobalConfig.httpConfig.httpClientFactory = nil;
    [super tearDown];
}

#pragma mark - Tests

- (void)testHttpClientFactory_byDefault_shouldBeNil
{
    XCTAssertNil(MSALGlobalConfig.httpConfig.httpClientFactory);
}

- (void)testSetHttpClientFactory_shouldRoundTrip
{
    __auto_type factory = [MSALHTTPConfigTestFactory new];
    factory.session = [MSALHTTPConfigTestSession new];

    MSALGlobalConfig.httpConfig.httpClientFactory = factory;

    XCTAssertEqual(MSALGlobalConfig.httpConfig.httpClientFactory, factory);
}

- (void)testSetHttpClientFactory_shouldProvideSessionToDefaultManager
{
    __auto_type factory = [MSALHTTPConfigTestFactory new];
    factory.session = [MSALHTTPConfigTestSession new];

    MSALGlobalConfig.httpConfig.httpClientFactory = factory;

    XCTAssertEqual(MSIDURLSessionManager.defaultManager.session, factory.session);
    XCTAssertEqual(factory.callCount, 1);
}

- (void)testSetHttpClientFactory_shouldProvideSessionToHttpRequests
{
    __auto_type factory = [MSALHTTPConfigTestFactory new];
    factory.session = [MSALHTTPConfigTestSession new];
    MSALGlobalConfig.httpConfig.httpClientFactory = factory;

    MSIDHttpRequest *request = [MSIDHttpRequest new];

    XCTAssertEqual(request.sessionManager.session, factory.session);
}

- (void)testSetHttpClientFactory_shouldNotInvalidateProvidedSession
{
    __auto_type factory = [MSALHTTPConfigTestFactory new];
    __auto_type session = [MSALHTTPConfigTestSession new];
    factory.session = session;
    MSALGlobalConfig.httpConfig.httpClientFactory = factory;

    @autoreleasepool
    {
        MSIDHttpRequest *request = [MSIDHttpRequest new];
        XCTAssertEqual(request.sessionManager.session, session);
        request = nil;
    }

    XCTAssertFalse(session.invalidateAndCancelCalled);
}

- (void)testSetHttpClientFactoryToNil_shouldRestoreDefaultSession
{
    MSIDURLSessionManager *defaultManager = MSIDURLSessionManager.defaultManager;
    __auto_type factory = [MSALHTTPConfigTestFactory new];
    factory.session = [MSALHTTPConfigTestSession new];
    MSALGlobalConfig.httpConfig.httpClientFactory = factory;
    XCTAssertEqual(MSIDURLSessionManager.defaultManager.session, factory.session);

    MSALGlobalConfig.httpConfig.httpClientFactory = nil;

    XCTAssertNil(MSALGlobalConfig.httpConfig.httpClientFactory);
    XCTAssertEqual(MSIDURLSessionManager.defaultManager, defaultManager);
}

@end
