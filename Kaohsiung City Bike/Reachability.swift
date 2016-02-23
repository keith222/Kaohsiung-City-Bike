//
//  Reachability.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2016/1/9.
//  Copyright © 2016年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import SystemConfiguration

public class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
    
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else {
            return false
        }
        
        var flags : SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.Reachable)
        let needsConnection = flags.contains(.ConnectionRequired)
        return (isReachable && !needsConnection)
    }
}
