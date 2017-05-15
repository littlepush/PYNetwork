//
//  PYApiManager.m
//  PYNetwork
//
//  Created by Push Chen on 7/24/14.
//  Copyright (c) 2014 PushLab. All rights reserved.
//

/*
 LGPL V3 Lisence
 This file is part of cleandns.
 
 PYNetwork is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 PYData is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with cleandns.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 LISENCE FOR IPY
 COPYRIGHT (c) 2013, Push Chen.
 ALL RIGHTS RESERVED.
 
 REDISTRIBUTION AND USE IN SOURCE AND BINARY
 FORMS, WITH OR WITHOUT MODIFICATION, ARE
 PERMITTED PROVIDED THAT THE FOLLOWING CONDITIONS
 ARE MET:
 
 YOU USE IT, AND YOU JUST USE IT!.
 WHY NOT USE THIS LIBRARY IN YOUR CODE TO MAKE
 THE DEVELOPMENT HAPPIER!
 ENJOY YOUR LIFE AND BE FAR AWAY FROM BUGS.
 */

/*
 PYNetwork is an API manager library for iOS Applications.
 This library is an extend for PYCore and PYData.
 *Important*: Must link with PYCore.framework and PYData.framework
 */

#import "PYApiManager.h"
#import <PYData/PYData.h>

static PYApiManager *_g_apiManager;
static BOOL _isDebug = NO;

@interface PYApiManager ()
{
    PYApiActionFailed       _defaultFailed;
    NSString                *_304RequestField;
    NSString                *_304ResponseField;
}
@end

@interface PYApiManager (Internal)
// Singleton interface.
+ (instancetype)shared;
// The operation queue.
@property (nonatomic, readonly) NSOperationQueue        *apiOpQueue;

// Update the modified time
- (void)updateModifiedField:(NSString *)modifyInfo forIdentifier:(NSString *)reqIdentifier;

// Generate error object
+ (NSError *)apiErrorWithCode:(PYApiErrorCode)code;

// To invoke default failed handler
+ (void)onRequestFailed:(NSError *)error;

// Get specified api's last request time.
+ (NSString *)lastRequest304FieldForApi:(NSString *)identifier;

@end

@implementation PYApiManager

PYSingletonAllocWithZone(_g_apiManager)
PYSingletonDefaultImplementation

- (id)init
{
    self = [super init];
    if ( self ) {
        _apiOpQueue = [NSOperationQueue object];
        [_apiOpQueue setMaxConcurrentOperationCount:10];
        
        // Initialize the api cache to store the request info.
        _apiCache = [PYGlobalDataCache gdcWithIdentify:@"com.ipy.network.apicache"];
        
        _defaultFailed = nil;
        _304RequestField = @"Last-Modified-Since";
        _304ResponseField = @"";
    }
    return self;
}

// Set 304 Request Header Field
+ (void)setNotModifiedRequestHeaderField:(NSString *)field
{
    PYSingletonLock
    [PYApiManager shared]->_304RequestField = [field copy];
    PYSingletonUnLock
}
// Set 304 Check Response Header Field
+ (void)setNotModifiedResponseHeaderField:(NSString *)field
{
    PYSingletonLock
    [PYApiManager shared]->_304ResponseField = [field copy];
    PYSingletonUnLock
}

+ (void)enableDebug:(BOOL)enable
{
    _isDebug = enable;
}

+ (NSString *)errorMessageWithCode:(PYApiErrorCode)code
{
    static NSString *_errorMsg[] = {
        @"Success",
        @"No such API Request Object",
        @"Failed to create request object",
        @"No such API Response Object",
        @"Failed to create response object",
        @"Reach max retry times",
        @"Failed to parse the response body"
    };
    if ( code == PYApiSuccess ) return _errorMsg[0];
    if ( code >= PYApiErrorInvalidateRequestClass && code <= PYApiErrorFailedToParseResponse ) {
        return _errorMsg[code - 100];
    }
    return @"Unknow code";
}

+ (void)defaultFailedHandler:(PYApiActionFailed)failed
{
    PYSingletonLock
    [PYApiManager shared]->_defaultFailed = [failed copy];
    PYSingletonUnLock
}

+ (void)invokeApi:(NSString *)apiname
   withParameters:(NSDictionary *)parameters
           onInit:(PYApiActionInit)init
        onSuccess:(PYApiActionSuccess)success
         onFailed:(PYApiActionFailed)failed
{
    NSString *_requestClassName = [apiname stringByAppendingString:@"Request"];
    Class _requestClass = NSClassFromString(_requestClassName);
    if ( _requestClass == nil ) {
        NSError *_err = [PYApiManager apiErrorWithCode:PYApiErrorInvalidateRequestClass];
        if ( failed ) failed( _err );
        else [PYApiManager onRequestFailed:_err];
        return;
    }
    PYApiRequest *_req = [_requestClass requestWithParameters:parameters];
    if ( _req == nil ) {
        NSError *_err = [PYApiManager apiErrorWithCode:PYApiErrorFailedToCreateRequestObject];
        if ( failed ) failed( _err );
        else [PYApiManager onRequestFailed:_err];
        return;
    }
    NSString *_responseClassName = [apiname stringByAppendingString:@"Response"];
    Class _responseClass = NSClassFromString(_responseClassName);
    if ( _responseClassName == nil ) {
        NSError *_err = [PYApiManager apiErrorWithCode:PYApiErrorInvalidateResponseClass];
        if ( failed ) failed( _err );
        else [PYApiManager onRequestFailed:_err];
        return;
    }
    PYApiResponse *_resp = [_responseClass object];
    if ( _resp == nil ) {
        NSError *_err = [PYApiManager apiErrorWithCode:PYApiErrorFailedToCreateResponseObject];
        if ( failed ) failed( _err );
        else [PYApiManager onRequestFailed:_err];
        return;
    }
    
    // Initialize the request object
    if ( init ) {
        init( _req );
    }
    
    NSBlockOperation *_workingOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSString *_requestIdentifier = [[_req class] requestIdentifyWithParameter:parameters];
        NSError *_error = nil;
        do {
            NSMutableURLRequest *_urlReq = [_req generateRequest];
            if ( _urlReq == nil ) {
                // Reach Max Retry Times.
                if ( _error == nil ) {
                    _error = [PYApiManager apiErrorWithCode:PYApiErrorReachMaxRetryTimes];
                }
                BEGIN_MAINTHREAD_INVOKE
                // Return the last error object
                if ( failed ) failed( _error );
                else [PYApiManager onRequestFailed:_error];
                END_MAINTHREAD_INVOKE
                break;
            }
            if ( _req.containsModifiedSinceFlag ) {
                NSString *_lastModifyInfo =
                [PYApiManager lastRequest304FieldForApi:_requestIdentifier];
                if ( [_lastModifyInfo length] > 0 ) {
                    [_urlReq addValue:_lastModifyInfo
                   forHTTPHeaderField:[PYApiManager shared]->_304RequestField];
                }
            }
            
            NSHTTPURLResponse *_response;
            NSData *_data = nil;
            BOOL _shouldTryNextDomain = NO;
            BOOL _onErrorOccured = NO;
            for ( ; ; ) {
                if ( _isDebug ) {
                    BEGIN_MAINTHREAD_INVOKE
                    NSString *_httpMethod = [_urlReq.HTTPMethod lowercaseString];
                    NSString *_contentType = [[[_urlReq valueForHTTPHeaderField:@"Content-Type"]
                                               lowercaseString] substringToIndex:9];
                    BOOL _displayBodyString = (![_contentType isEqualToString:@"multiple"]);
                    if ( [_httpMethod isEqualToString:@"post"] || [_httpMethod isEqualToString:@"put"] ) {
                        ALog(@"{\nRequest URL: %@\nMethod: %@\nBody: %@\n}",
                             _urlReq.URL.absoluteString,
                             _urlReq.HTTPMethod,
                             (_displayBodyString ?
                              [[NSString alloc] initWithData:_urlReq.HTTPBody encoding:NSUTF8StringEncoding] :
                              _urlReq.HTTPBody)
                             );
                    } else {
                        ALog(@"{\nRequest URL: %@\nMethod: %@\n}",
                             _urlReq.URL.absoluteString,
                             _urlReq.HTTPMethod);
                    }
                    END_MAINTHREAD_INVOKE
                }
                _data = [NSURLConnection
                         sendSynchronousRequest:_urlReq
                         returningResponse:&_response
                         error:&_error];
                if ( _error ) { _shouldTryNextDomain = YES; break; }
                
                if ( _response.statusCode >= 400 ) {
                    // Server error
                    BEGIN_MAINTHREAD_INVOKE
                    if ( _isDebug ) {
                        ALog(@"Request Failed: %d", (int)_response.statusCode);
                    }
                    NSError* _err = [self
                                     errorWithCode:(int)_response.statusCode
                                     message:[[NSString alloc]
                                              initWithData:_data
                                              encoding:NSUTF8StringEncoding]];
                    if ( failed ) failed( _err );
                    else [PYApiManager onRequestFailed:_err];
                    END_MAINTHREAD_INVOKE
                    _onErrorOccured = YES;
                    break;
                } else if ( _response.statusCode == 301 || _response.statusCode == 302 ) {
                    NSDictionary *_hf = [_response allHeaderFields];
                    NSString *_location = nil;
                    for ( NSString *_key in _hf ) {
                        if ( [[_key lowercaseString] isEqualToString:@"location"] ) {
                            _location = [_hf objectForKey:_key];
                            break;
                        }
                    }
                    if ( [_location length] == 0 ) {
                        BEGIN_MAINTHREAD_INVOKE
                        NSError *_err = [self
                                         errorWithCode:(int)_response.statusCode
                                         message:@"No validate location to redirect."];
                        if ( failed ) failed( _err );
                        else [PYApiManager onRequestFailed:_err];
                        END_MAINTHREAD_INVOKE
                        _onErrorOccured = YES;
                        break;
                    }
                    // Re-generate Request Object
                    NSString *_absUrlString = [_req.requestURLString copy];
                    // Get parameters
                    NSArray *_paramPart = [_absUrlString componentsSeparatedByString:@"?"];
                    NSString *_parameterString = @"";
                    if ( [_paramPart count] == 2 ) {
                        _parameterString = [NSString stringWithFormat:@"?%@", [_paramPart objectAtIndex:1]];
                    }
                    
                    NSString *_newUrl = @"";
                    if ( [_location rangeOfString:@"://"].location != NSNotFound ) {
                        _newUrl = [_location stringByAppendingString:_parameterString];
                    } else {
                        NSString *_temp = _paramPart[0];
                        NSRange _protocolRange = [_temp rangeOfString:@"://"];
                        NSRange _slashRange = [_temp
                                               rangeOfString:@"/"
                                               options:NSCaseInsensitiveSearch
                                               range:NSMakeRange(_protocolRange.location + _protocolRange.length,
                                                                 _temp.length - _protocolRange.location)];
                        NSString *_protocolAndDomain = [_temp substringToIndex:_slashRange.location];
                        _newUrl = [_protocolAndDomain stringByAppendingFormat:@"%@%@", _location, _parameterString];
                    }
                    DUMPObj(_newUrl);
                    [_urlReq setURL:[NSURL URLWithString:_newUrl]];
                    _shouldTryNextDomain = YES;
                } else {
                    // Correct response
                    break;
                }
            }
            
            if ( _shouldTryNextDomain == YES ) continue;
            if ( _onErrorOccured == YES ) break;
            
            // Set Status Code
            _resp.statusCode = _response.statusCode;
            
            // Update modified time
            NSString *_lastModifiedField = @"";
            NSString *_304respField = [PYApiManager shared]->_304ResponseField;
            if ( [_304respField length] > 0 ) {
                _lastModifiedField = [_response.allHeaderFields objectForKey:_304respField];
            }
            if ( [_lastModifiedField length] > 0 ) {
                [[PYApiManager shared]
                 updateModifiedField:_lastModifiedField
                 forIdentifier:_requestIdentifier];
            }
            
            if ( _isDebug ) {
                if ( _resp.statusCode != 304 ) {
                    NSString *_sBody = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
                    BEGIN_MAINTHREAD_INVOKE
                    ALog(@"Response: \n%@", _sBody);
                    END_MAINTHREAD_INVOKE
                } else {
                    BEGIN_MAINTHREAD_INVOKE
                    ALog(@"Response get 304");
                    END_MAINTHREAD_INVOKE
                }
            }

            // Parse the data
            @try {
                if ( _resp.statusCode == 304 ) {
                    if ( success ) success(_resp);
                } else {
                    if ( [_resp parseBodyWithData:_data] ) {
                        BEGIN_MAINTHREAD_INVOKE
                        if ( success ) success ( _resp );
                        END_MAINTHREAD_INVOKE
                    } else {
                        BEGIN_MAINTHREAD_INVOKE
                        if ( failed ) failed ( _resp.error );
                        else [PYApiManager onRequestFailed:_resp.error];
                        END_MAINTHREAD_INVOKE
                    }
                }
            } @catch ( NSException *ex ) {
                ALog(@"%@\n%@", ex.reason, ex.callStackSymbols);
                continue;
            }
            break;
        } while ( true );
    }];
    
    [[PYApiManager shared].apiOpQueue addOperation:_workingOperation];
}

@end

@implementation PYApiManager (Internal)

@dynamic apiOpQueue;
- (NSOperationQueue *)apiOpQueue { return _apiOpQueue; }

+ (NSString *)lastRequest304FieldForApi:(NSString *)identifier
{
    PYSingletonLock
    return [[PYApiManager shared]->_apiCache objectForKey:identifier];
    PYSingletonUnLock
}

// Update the modified time
- (void)updateModifiedField:(NSString *)modifyInfo forIdentifier:(NSString *)reqIdentifier
{
    PYSingletonLock
    [_apiCache setObject:modifyInfo forKey:reqIdentifier];
    PYSingletonUnLock
}

// Generate error object
+ (NSError *)apiErrorWithCode:(PYApiErrorCode)code
{
    return [self errorWithCode:code message:[PYApiManager errorMessageWithCode:code]];
}

+ (instancetype)shared
{
    PYSingletonLock
    if ( _g_apiManager == nil ) {
        _g_apiManager = [PYApiManager object];
    }
    return _g_apiManager;
    PYSingletonUnLock
}

+ (void)onRequestFailed:(NSError *)error
{
    PYSingletonLock
    if ( [PYApiManager shared]->_defaultFailed == nil ) return;
    [PYApiManager shared]->_defaultFailed(error);
    PYSingletonUnLock
}

@end

PY_JSON_API_COMMON_IMPL( TestApi, @"/api/login/username/<username>/password/<password>") {
    return YES;
}
PY_END_API

// @littlepush
// littlepush@gmail.com
// PYLab
