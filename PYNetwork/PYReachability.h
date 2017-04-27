//
//  PYReachability.h
//  PYNetwork
//
//  Created by ChenPush on 1/25/15.
//  Copyright (c) 2015 PushLab. All rights reserved.
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
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>
#import <PYCore/PYCore.h>

// The event id of reachability statue changed.
#define PYReachabilityChangeNotification        0x0FFF0001

// Monitor Network Statues changed.
#define PYReachabilityNetworkReachable          0x0FFF0002
#define PYReachabilityNetworkNotReachable       0x0FFF0003

// The status of network
typedef NS_ENUM(NSInteger, PYNetworkStatus)
{
    PYNetworkStatusNotReachable     = 0,
    PYNetworkStatusViaWWAN          = 1,
    PYNetworkStatusViaWiFi          = 2
};

// Pre-defined in PYCore
@class PYActionDispatcher;

/*!
 Test network reachability
 */
@interface PYReachability : PYActionDispatcher

/*!
 If current network is reachable via WWAN
 */
@property (nonatomic, readonly) BOOL        isReachableViaWWAN;
/*!
 If current network is reachable via WiFi
 */
@property (nonatomic, readonly) BOOL        isReachableViaWiFi;
/*!
 If current network is reachable.
 */
@property (nonatomic, readonly) BOOL        isNetworkReachable;
/*!
 The status of network reachability
 */
@property (nonatomic, readonly) PYNetworkStatus reachableStatus;

/*!
 Start to monitor the network status changing events
 */
- (BOOL)startMonitor;
/*
 Stop to monitor the network status changing events
 */
- (void)stopMonitor;

/*!
 If current can connect to specified host.
 The hostname can be an IP address or a domain.
 It will test the DNS lookup and the route to the host.
 @return: PYNetworkStatusNotReachable for not reachable,
 otherwise the route to the specified host
 */
+ (instancetype)reachabilityWithHostname:(NSString *)hostname;

/*!
 Test if current device can connect to the Internet via either
 WWAN or WiFi.
 @return PYNetworkStatusNotReachable for not reachable,
 or the way to connect to the internet
 */
+ (instancetype)reachabilityForInternetConnection;

/*!
 Test if current can connect to specified address.
 @param hostAddress the socket address structure to peer
 */
+ (instancetype)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress;

/*!
 Check if has access to local network
 @return Will only return <code>PYNetworkStatusNotReachable</code> or <code>PYNetworkStatusViaWiFi</code>
 */
+ (instancetype)reachabilityForLocalWiFi;

// Flags

/*!
 WWAN may be available, but not active until a connection has been established.
 */
@property (nonatomic, readonly) BOOL    isWWANConnectionRequired;

/*!
 If is a on demand connection
 */
@property (nonatomic, readonly) BOOL    isConnectionOnDemand;

/*!
 Is user intervention required?
 */
@property (nonatomic, readonly) BOOL    isUserInterventionRequired;

/*!
 Reachability Flags
 */
@property (nonatomic, readonly) SCNetworkReachabilityFlags  reachabilityFlags;

/*!
 Reachability Flags String
 */
@property (nonatomic, readonly) NSString    *reachabilityString;

@end

@interface PYReachability (Private)

// Private Initialize Method. Not allowed to invoke
- (id)init;

@end
