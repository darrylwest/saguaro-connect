//
//  InternetReachability.swift
//  SaguaroConnect
//
//  Created by darryl west on 7/20/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import Foundation
import SystemConfiguration

public protocol InternetReachableType {
    var lastCheck:TimeInterval { get }
    func isInternetReachable() -> Bool
}

open class InternetReachability: InternetReachableType {

    public final fileprivate(set) var lastCheck:TimeInterval = 0
    fileprivate var connected = false
    public final fileprivate(set) var minTimeBetweenSocketChecks:TimeInterval

    public init() {
        self.minTimeBetweenSocketChecks = 15
    }

    public init(minTimeBetweenSocketChecks:TimeInterval) {
        self.minTimeBetweenSocketChecks = minTimeBetweenSocketChecks
    }

    final public func isInternetReachable() -> Bool {

        if Date().timeIntervalSince1970 - lastCheck > minTimeBetweenSocketChecks {
            var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
            zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
            zeroAddress.sin_family = sa_family_t(AF_INET)

            let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
                SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer(OpaquePointer($0)))
            }

            var flags = SCNetworkReachabilityFlags.connectionAutomatic
            if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
                return false
            }

            let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
            let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0


            let con = (isReachable && !needsConnection)
            if con != connected {
                connected = con
            }

            lastCheck = Date().timeIntervalSince1970
        }
        
        return connected
    }
}
