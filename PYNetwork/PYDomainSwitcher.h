//
//  PYDomainSwitcher.h
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

/*!
 The DNS server may down, or cache poisoning caused by some country,
 to make sure the user can always reach the server, we set the directly
 IP address of our server as a backup to the main domain.
 When the server is unreachable by the domain, the request can switch
 to the backup domains/ips.
 */
@interface PYDomainSwitcher : NSObject
{
    // Domain List
    NSArray                     *_baseDomains;
    // Default is http, can set your own protocol
    NSString                    *_urlProtocol;
    // Current using domain's index
    NSUInteger                  _selectedIndex;
}

/*! 
 Set Default Domains and Protocol
 Only the lastest invocation will take affect.
 */
+ (void)setDefaultHttpDomains:(NSArray *)domains;
+ (void)setDefaultDomains:(NSArray *)domains protocol:(NSString *)protocol;

/*!
 Create a domain switcher with default setting.
 */
+ (instancetype)defaultDomainSwitcher;
/*! 
 Initialize the domain switcher with HTTP protocol and specified domains
 */
+ (instancetype)initWithHttpDomains:(NSArray *)domains;
/*! 
 Initialize the domain switcher with specified protocol and domains. 
 */
+ (instancetype)initWithDomains:(NSArray *)domains protocol:(NSString *)protocol;

/*! 
 Switch to the next domain, if reach end of the list, return NO.
 */
- (BOOL)next;

/*! 
 Get current selected domain, along with the protocol
 */
@property (nonatomic, readonly) NSString        *selectedDomain;

/*! 
 Get all domain list.
 */
@property (nonatomic, readonly) NSArray         *domainList;

// Domain Switch Status, if has unused domain
@property (nonatomic, readonly) BOOL            isAvailable;

@end

#define PYDefaultDomainSwitcher     [PYDomainSwitcher defaultDomainSwitcher]
#define PYDomains(...)              [PYDomainSwitcher initWithHttpDomains:              \
                                        [NSArray arrayWithObjects:##__VA_ARGS__, nil]

// @littlepush
// littlepush@gmail.com
// PYLab

