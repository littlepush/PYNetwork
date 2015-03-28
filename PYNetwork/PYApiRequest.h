//
//  PYRequest.h
//  PYNetwork
//
//  Created by Push Chen on 7/23/14.
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

#import <Foundation/Foundation.h>

// Pre-Define
@class PYDomainSwitcher;

/*!
 The api request is an interface for all detail APIs.
 A Request object contains a domain switcher( if needed ), a base url string, 
 which usually contains only the relative path on the server, and the
 parameter to make a final request.
 If the url string contains the domain, then whether set the domain switcher
 or not, it will take no effect.
 For HTTP request, often we get 304 from the server side, and
 in default, the API manager which send the request will add "Last-Modified-Since"
 flag in the request heeader. Set [containsModifiedSinceFlag] to NO to avoid 304
 */
@interface PYApiRequest : NSObject
{
    PYDomainSwitcher            *_domainSwitcher;
    NSString                    *_urlString;
    NSDictionary                *_parameters;
    
    // If need domain switcher to combine the url
    BOOL                        _isNeedDomainSwitcher;
    
    // Retry times.
    NSUInteger                  _retriedTimes;
    NSUInteger                  _minimalRetryTimes; // Default is equal to _domainSwticher.count
    NSUInteger                  _maximalRetryTimes; // Default is equal to _domainSwitcher.count
}

/*!
 Generate the request identifier for each request.
 If the parameters are same and the class of two request are also the same, 
 the identifiers of these two request object will also be the same.
 We idntifiy a request by its class name and the parameter list.
 */
+ (NSString *)requestIdentifyWithParameter:(NSDictionary *)parameters;

/*! 
 Create an api request with parameters.
 */
+ (instancetype)requestWithParameters:(NSDictionary *)parameters;

/*! 
 Before invoking the api, call this method to generate a request object use
 specified domain.
 */
- (NSMutableURLRequest *)generateRequest;

// Retry times
@property (nonatomic, assign)   NSUInteger              minimalRetryTimes;
@property (nonatomic, assign)   NSUInteger              maximalRetryTimes;
@property (nonatomic, readonly) NSUInteger              retriedTimes;

/*!
 The final request URL
 */
@property (nonatomic, readonly) NSString                *requestURLString;

/*!
 HTTP 304, default is YES if the same request has been invoked
 The request manager will maintain a cache to log all invocation data.
 */
@property (nonatomic, assign)   BOOL                    containsModifiedSinceFlag;

/*! 
 Replace the url schema with specified parameters
 */
- (NSString *)formatUrl:(NSString *)url withParameters:(NSDictionary *)parameters;

/*! 
 Should be overwrite by the sub-class
 */
- (void)initializeDomainSwitcher;

/*!
 Set the base url schema
 */
- (void)initializeUrlSchema;

@end

/*!
 We do not support to create the request object by [alloc] & [init].
 */
@interface PYApiRequest (Private)

// Not available
- (id)init;

@end

/*!
 Method: POST
 Overwrite [PYApiRequest generateRequest], set @"POST" as HTTP Method
 */
@interface PYApiPostRequest : PYApiRequest

/*!
 Utility method, invoke this method before setting the post data
 when the Content-Type is multipart/form-data. The method will initialize
 the boundary string and add 'Content-Type' to the request
 */
- (void)beginOfSettingPostData:(NSMutableURLRequest *)req;

/*!
 Utility method, invoke this method at the end of the setting of
 post data. This method will close the data body and set 'Content-Length'
 */
- (void)endOfSettingPostData:(NSMutableURLRequest *)req;

/*!
 Utility method, add image file to the post data
 */
- (void)addPostImage:(id)image forKey:(NSString *)key;

/*!
 Utility method, add value for specified key to the post data
 */
- (void)addPostValue:(NSString *)value forKey:(NSString *)key;

/*!
 Utility method, add normal file to the post data
 */
- (void)addPostFile:(NSString *)filename forKey:(NSString *)key;

@end

// @littlepush
// littlepush@gmail.com
// PYLab
