//
//  JustTests.swift
//  SaguaroConnect
//
//  Created by Darryl West on 6/24/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import XCTest
@testable import SaguaroConnect

class JustTests: XCTestCase {
    
    
    func testInstance() {
        let just = Just()
        
        XCTAssertNotNil(just, "should not be nil")
        
    }
    
    func testPercentEncodeString() {
        let just = Just()
        
        let str = "test?mypara=my value with spaces&email=dpw@rcs.com"
        
        let escaped = just.percentEncodeString(str)
        
        print( escaped )
        
        XCTAssertNotEqual(escaped, "null", "should not be null")
        XCTAssertEqual(escaped, "test?mypara%3Dmy value with spaces%26email%3Ddpw%40rcs.com", "should equal the escaped string")
    }
}
