//
//  PYReachability.m
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

#import "PYReachability.h"

#import <sys/socket.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

// The monitor callback function
static void _pyReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info);

@interface PYReachability ()
{
    SCNetworkReachabilityRef        _reachabilityRef;
    SCNetworkReachabilityFlags      _reachabilityFlags;
    BOOL                            _isNetworkReachable;
    dispatch_queue_t                _monitorQueue;
}

// Initialize with specified reachability ref
- (id)initWithReachabilityRef:(SCNetworkReachabilityRef)ref;

// The flags has been changed
- (void)_reachabilityFlagsHasChanged:(SCNetworkReachabilityFlags)flags;

@end

@implementation PYReachability

- (id)initWithReachabilityRef:(SCNetworkReachabilityRef)ref
{
    self = [super init];
    if ( self ) {
        _reachabilityRef = ref;
        SCNetworkReachabilityGetFlags(_reachabilityRef, &_reachabilityFlags);
        
        _isNetworkReachable = NO;
        do {
            if ( !(_reachabilityFlags & kSCNetworkReachabilityFlagsReachable) ) break;
            if ( _reachabilityFlags & (kSCNetworkReachabilityFlagsConnectionRequired |
                                       kSCNetworkReachabilityFlagsTransientConnection) ) break;
            _isNetworkReachable = YES;
        } while( false );
    }
    return self;
}

- (void)dealloc
{
    [self stopMonitor];
    
    if ( _reachabilityRef ) {
        CFRelease(_reachabilityRef);
    }
}

@dynamic isReachableViaWWAN;
- (BOOL)isReachableViaWWAN
{
    PYSingletonLock
    return (
            (_reachabilityFlags & kSCNetworkReachabilityFlagsReachable) &&
            (_reachabilityFlags & kSCNetworkReachabilityFlagsIsWWAN )
            );
    PYSingletonUnLock
}

@dynamic isReachableViaWiFi;
- (BOOL)isReachableViaWiFi
{
    PYSingletonLock
    return (
            (_reachabilityFlags & kSCNetworkReachabilityFlagsReachable) &&
            (!(_reachabilityFlags & kSCNetworkReachabilityFlagsIsWWAN) )
            );
    PYSingletonUnLock
}

@synthesize isNetworkReachable = _isNetworkReachable;

@dynamic reachableStatus;
- (PYNetworkStatus)reachableStatus
{
    PYSingletonLock
    if ( !_isNetworkReachable ) return PYNetworkStatusNotReachable;
    if ( _reachabilityFlags & kSCNetworkReachabilityFlagsIsWWAN )
        return PYNetworkStatusViaWWAN;
    return PYNetworkStatusViaWiFi;
    PYSingletonUnLock
}

/*!
 If current can connect to specified host.
 The hostname can be an IP address or a domain.
 It will test the DNS lookup and the route to the host.
 @return: PYNetworkStatusNotReachable for not reachable,
 otherwise the route to the specified host
 */
+ (instancetype)reachabilityWithHostname:(NSString *)hostname
{
    SCNetworkReachabilityRef _ref = SCNetworkReachabilityCreateWithName(NULL, [hostname UTF8String]);
    return [[PYReachability alloc] initWithReachabilityRef:_ref];
}

/*!
 Test if current device can connect to the Internet via either
 WWAN or WiFi.
 @return PYNetworkStatusNotReachable for not reachable,
 or the way to connect to the internet
 */
+ (instancetype)reachabilityForInternetConnection
{
    struct sockaddr_in _anyAddr;
    memset(&_anyAddr, 0, sizeof(_anyAddr));
    _anyAddr.sin_len = sizeof(_anyAddr);
    _anyAddr.sin_family = AF_INET;
    
    return [self reachabilityWithAddress:&_anyAddr];
}

/*!
 Test if current can connect to specified address.
 @param hostAddress: the socket address structure to peer
 */
+ (instancetype)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress
{
    SCNetworkReachabilityRef _ref = SCNetworkReachabilityCreateWithAddress(NULL, (const struct sockaddr*)hostAddress);
    return [[PYReachability alloc] initWithReachabilityRef:_ref];
}

/*!
 Check if has access to local network
 @return Will only return <code>PYNetworkStatusNotReachable</code> or <code>PYNetworkStatusViaWiFi</code>
 */
+ (instancetype)reachabilityForLocalWiFi
{
    struct sockaddr_in _localWifiAddress;
    memset(&_localWifiAddress, 0, sizeof(_localWifiAddress));
    _localWifiAddress.sin_len = sizeof(_localWifiAddress);
    _localWifiAddress.sin_family = AF_INET;
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
    _localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    
    return [self reachabilityWithAddress:&_localWifiAddress];
}

- (BOOL)startMonitor
{
    if ( _monitorQueue != NULL ) return NO;
    
    SCNetworkReachabilityContext _context = { 0, NULL, NULL, NULL, NULL };
    
    // Create the queue
    _monitorQueue = dispatch_queue_create("com.ipy.reachability", NULL);
    if ( !_monitorQueue ) return NO;
    
    _context.info = (__bridge void *)self;
    
    // Set callback
    if ( !SCNetworkReachabilitySetCallback(_reachabilityRef, _pyReachabilityCallback, &_context) ) {
#ifdef DEBUG
        NSLog(@"SCNetworkReachabilitySetCallback() failed: %s", SCErrorString(SCError()));
#endif
        _monitorQueue = NULL;
        return NO;
    }
    if ( !SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, _monitorQueue) ) {
#ifdef DEBUG
        NSLog(@"SCNetworkReachabilitySetDispatchQueue() failed: %s", SCErrorString(SCError()));
#endif
        // Reset callback
        SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
        _monitorQueue = NULL;
        return NO;
    }

    return YES;
}

- (void)stopMonitor
{
    if ( _monitorQueue == NULL ) return;
    
    // first stop any callbacks!
    SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
    
    // unregister target from the GCD serial dispatch queue
    SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, NULL);
    
    _monitorQueue = NULL;
}

// Flags

/*!
 WWAN may be available, but not active until a connection has been established.
 */
@dynamic isWWANConnectionRequired;
- (BOOL)isWWANConnectionRequired
{
    PYSingletonLock
    return (_reachabilityFlags & kSCNetworkReachabilityFlagsConnectionRequired);
    PYSingletonUnLock
}

/*!
 If is a on demand connection
 */
@dynamic isConnectionOnDemand;
- (BOOL)isConnectionOnDemand
{
    PYSingletonLock
    return (
            _reachabilityFlags & (kSCNetworkReachabilityFlagsConnectionRequired |
                                  kSCNetworkReachabilityFlagsConnectionOnTraffic |
                                  kSCNetworkReachabilityFlagsConnectionOnDemand)
            );
    PYSingletonUnLock
}

/*!
 Is user intervention required?
 */
@dynamic isUserInterventionRequired;
- (BOOL)isUserInterventionRequired
{
    PYSingletonLock
    return (
            _reachabilityFlags & (kSCNetworkReachabilityFlagsConnectionRequired |
                                  kSCNetworkReachabilityFlagsInterventionRequired)
            );
    PYSingletonUnLock
}

/*!
 Reachability Flags
 */
@synthesize reachabilityFlags = _reachabilityFlags;

/*!
 Reachability Flags String
 */
@dynamic reachabilityString;
- (NSString *)reachabilityString
{
    return [NSString stringWithFormat:@"%c%c %c%c%c%c%c%c%c",
            (_reachabilityFlags & kSCNetworkReachabilityFlagsIsWWAN)               ? 'W' : '-',
            (_reachabilityFlags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
            (_reachabilityFlags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
            (_reachabilityFlags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
            (_reachabilityFlags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
            (_reachabilityFlags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
            (_reachabilityFlags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
            (_reachabilityFlags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
            (_reachabilityFlags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-'];
}

- (void)_reachabilityFlagsHasChanged:(SCNetworkReachabilityFlags)flags
{
    PYSingletonLock
    _reachabilityFlags = flags;
    SCNetworkReachabilityGetFlags(_reachabilityRef, &_reachabilityFlags);
    
    _isNetworkReachable = NO;
    do {
        if ( !(_reachabilityFlags & kSCNetworkReachabilityFlagsReachable) ) break;
        if ( _reachabilityFlags & (kSCNetworkReachabilityFlagsConnectionRequired |
                                   kSCNetworkReachabilityFlagsTransientConnection) ) break;
        _isNetworkReachable = YES;
    } while( false );
    PYSingletonUnLock
    
    [self invokeTargetWithEvent:PYReachabilityChangeNotification];
    if ( _isNetworkReachable ) {
        [self invokeTargetWithEvent:PYReachabilityNetworkReachable];
    } else {
        [self invokeTargetWithEvent:PYReachabilityNetworkNotReachable];
    }
}

@end

@implementation PYReachability (Private)

- (id)init
{
    self = [super init];
    if ( self ) {
        // nothing to do...
    }
    return self;
}

@end

// Implementation of the callback
static void _pyReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
#pragma unused (target)
#if __has_feature(objc_arc)
    PYReachability *_reachability = ((__bridge PYReachability*)info);
#else
    PYReachability *_reachability = ((PYReachability*)info);
#endif
    
    // we probably dont need an autoreleasepool here as GCD docs state each queue has its own autorelease pool
    // but what the heck eh?
    @autoreleasepool
    {
        [_reachability _reachabilityFlagsHasChanged:flags];
    }
    
}
