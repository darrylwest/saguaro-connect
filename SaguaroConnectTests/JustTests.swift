//
//  JustTests.swift
//  SaguaroConnect
//
//  Created by Darryl West on 6/24/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import XCTest
import Just
@testable import SaguaroConnect

class JustTests: XCTestCase {
    
    
    func testInstance() {
        let just = HTTP()
        
        XCTAssertNotNil(just, "should not be nil")
        
    }
}
