//
//    TWSignedRequest.m
//    TWiOSReverseAuthExample
//
//    Copyright (c) 2013 Sean Cook
//
//    Permission is hereby granted, free of charge, to any person obtaining a
//    copy of this software and associated documentation files (the
//    "Software"), to deal in the Software without restriction, including
//    without limitation the rights to use, copy, modify, merge, publish,
//    distribute, sublicense, and/or sell copies of the Software, and to permit
//    persons to whom the Software is furnished to do so, subject to the
//    following conditions:
//
//    The above copyright notice and this permission notice shall be included
//    in all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
//    NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
//    USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "OAuthCore.h"
#import "TWSignedRequest.h"

#define TW_HTTP_METHOD_GET @"GET"
#define TW_HTTP_METHOD_POST @"POST"
#define TW_HTTP_METHOD_DELETE @"DELETE"
#define TW_HTTP_HEADER_AUTHORIZATION @"Authorization"
#define TW_CONSUMER_KEY @"TWITTER_CONSUMER_KEY"
#define TW_CONSUMER_SECRET @"TWITTER_CONSUMER_SECRET"

#define REQUEST_TIMEOUT_INTERVAL 8

@interface TWSignedRequest()
{
    NSURL *_url;
    NSDictionary *_parameters;
    TWSignedRequestMethod _signedRequestMethod;
    NSOperationQueue *_signedRequestQueue;
}

@end

@implementation TWSignedRequest

#pragma mark - Public Methods

- (instancetype)initWithURL:(NSURL *)url parameters:(NSDictionary *)parameters requestMethod:(TWSignedRequestMethod)requestMethod
{
    self = [super init];
    if (self) {
        _url = url;
        _parameters = parameters;
        _signedRequestMethod = requestMethod;
        _signedRequestQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)performRequestWithHandler:(TWSignedRequestHandler)handler
{
    NSURLRequest *request = [self _buildRequest];
    [NSURLConnection sendAsynchronousRequest:request queue:_signedRequestQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        handler(data, response, connectionError);
    }];
}

#pragma mark - Private Method

- (NSURLRequest *)_buildRequest
{
    //  Build our parameter string
    NSMutableArray *paramsStrings = [[NSMutableArray alloc] init];
    [_parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [paramsStrings addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
    }];
    NSString *paramsAsString = [paramsStrings componentsJoinedByString:@"&"];

    NSURL *url = _url;
    NSData *bodyData = nil;
    NSString *method;
    
    switch (_signedRequestMethod) {
        case TWSignedRequestMethodPOST:
            bodyData = [paramsAsString dataUsingEncoding:NSUTF8StringEncoding];
            method = TW_HTTP_METHOD_POST;
            break;
        case TWSignedRequestMethodDELETE:
            method = TW_HTTP_METHOD_DELETE;
            break;
        case TWSignedRequestMethodGET:
        default:
            if ( [paramsAsString length] )
            {
                NSString *urlString = [NSString stringWithFormat:@"%@?%@", [_url absoluteString], paramsAsString];
                url = [NSURL URLWithString:urlString];
            }
            method = TW_HTTP_METHOD_GET;
    }

    //  Create the authorization header and attach to our request
    NSString *authorizationHeader = OAuthorizationHeader(url, method, bodyData, _consumerKey, _consumerSecret, _authToken, _authTokenSecret);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setTimeoutInterval:REQUEST_TIMEOUT_INTERVAL];
    [request setHTTPMethod:method];
    [request setValue:authorizationHeader forHTTPHeaderField:TW_HTTP_HEADER_AUTHORIZATION];
    [request setHTTPBody:bodyData];
    
    return request;
}

@end
