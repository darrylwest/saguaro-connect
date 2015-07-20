//
//  InternetReachabilityTests.swift
//  SaguaroConnect
//
//  Created by darryl west on 7/20/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import XCTest
import SaguaroConnect

class InternetReachabilityTests: XCTestCase {

    func testInstance() {
        let reachable = InternetReachability()

        XCTAssertNotNil(reachable, "should not be nil")
        XCTAssertEqual(reachable.lastCheck, 0.0, "check should be zero")
        XCTAssertEqual(reachable.minTimeBetweenSocketChecks, 15.0, "min check should be 15")
    }

    func testIsInternetReachable() {
        let reachable = InternetReachability( minTimeBetweenSocketChecks: 5 )

        let connected = reachable.isInternetReachable()

        XCTAssertEqual( connected, true, "should not be connected")
        XCTAssertEqual(reachable.minTimeBetweenSocketChecks, 5.0, "min check should be 5")
    }
    
}
