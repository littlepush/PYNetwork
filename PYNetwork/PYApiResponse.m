//
//  PYApiResponse.m
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

#import "PYApiResponse.h"
#import <PYCore/PYCore.h>

@implementation PYApiResponse

@synthesize errorCode;
@synthesize errorMessage;

@dynamic error;
- (NSError *)error
{
    if ( self.errorCode == 0 ) return nil;
    return [self errorWithCode:(int)self.errorCode message:self.errorMessage];
}

// Override
- (BOOL)parseBodyWithData:(NSData *)data
{
    return NO;
}

@end

@implementation PYApiJSONResponse

- (BOOL)parseBodyWithData:(NSData *)data
{
    NSError *_error;
    id object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:NSJSONReadingAllowFragments
                 error:&_error];
    if ( _error || object == nil ) {
        self.errorCode = _error.code;
        self.errorMessage = _error.localizedDescription;
        return NO;
    }
    return [self parseBodyWithJSON:object];
}

// Override
- (BOOL)parseBodyWithJSON:(id)jsonObject
{
    return NO;
}

@end

// @littlepush
// littlepush@gmail.com
// PYLab
