//
//  PYDomainSwitcher.m
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

#import "PYDomainSwitcher.h"
#import <PYCore/PYCore.h>

static NSArray *__gDS_defaultDomains = nil;
static NSString *__gDS_defaultProtocol = nil;

@implementation PYDomainSwitcher

+ (void)setDefaultHttpDomains:(NSArray *)domains
{
    [PYDomainSwitcher setDefaultDomains:domains protocol:@"http"];
}
+ (void)setDefaultDomains:(NSArray *)domains protocol:(NSString *)protocol
{
    PYSingletonLock
    __gDS_defaultDomains = [domains copy];
    __gDS_defaultProtocol = [protocol copy];
    PYSingletonUnLock
}

+ (instancetype)defaultDomainSwitcher
{
    return [PYDomainSwitcher
            initWithDomains:__gDS_defaultDomains
            protocol:__gDS_defaultProtocol];
}

+ (instancetype)initWithHttpDomains:(NSArray *)domains
{
    return [PYDomainSwitcher initWithDomains:domains protocol:@"http"];
}

+ (instancetype)initWithDomains:(NSArray *)domains protocol:(NSString *)protocol
{
    if ( [domains count] == 0 || [protocol length] == 0 ) return nil;
    PYDomainSwitcher *_ds = [PYDomainSwitcher object];
    //_ds->_baseDomains = [domains copy];
    NSMutableArray *_pureDomains = [NSMutableArray array];
    for ( NSString *_d in domains ) {
        NSArray *_dschema = [_d componentsSeparatedByString:@"://"];
        if ( [_dschema count] > 1 ) {
            [_pureDomains addObject:[_dschema safeObjectAtIndex:1]];
        } else {
            [_pureDomains addObject:_d];
        }
    }
    _ds->_baseDomains = [NSArray arrayWithArray:_pureDomains];
    _ds->_urlProtocol = [protocol copy];
    _ds->_selectedIndex = 0;
    return _ds;
}

// Switch to the next domain, if reach end of the list, return NO.
- (BOOL)next
{
    PYSingletonLock
    ++_selectedIndex;
    if ( _selectedIndex >= [_baseDomains count] ) return NO;
    return YES;
    PYSingletonUnLock
}

// Get current selected domain, along with the protocol
@dynamic selectedDomain;
- (NSString *)selectedDomain
{
    return [NSString stringWithFormat:@"%@://%@",
            _urlProtocol, [_baseDomains safeObjectAtIndex:_selectedIndex]];
}

// Get all domain list.
@synthesize domainList = _baseDomains;

@dynamic isAvailable;
- (BOOL)isAvailable
{
    return (_selectedIndex < [_baseDomains count]);
}

@end

// @littlepush
// littlepush@gmail.com
// PYLab
