//
//  SARemoteServiceTests.swift
//  SaguaroConnect
//
//  Created by darryl west on 7/20/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import XCTest
@testable import SaguaroConnect

class SARemoteServiceTests: XCTestCase {

    func testInstance() {
        let serviceName = "TestService"

        let service = SARemoteService(serviceName: serviceName)

        XCTAssertNotNil(service, "should exist")
        XCTAssertEqual(service.serviceName, serviceName, "name match")
    }

    func testCreateError() {
        let errorType = SAErrorType(code: 100, message: "This is an error")
        let request = SARemoteRequest()

        let service = SARemoteService(serviceName: "TestService")

        let error = service.createError(errorType, request: request)

        XCTAssertNotNil(error, "should not be nil")
        XCTAssertEqual(error.domain, service.serviceName, "error domain test")
        XCTAssertEqual(error.code, errorType.code)
        XCTAssertNotNil(error.userInfo, "info should not be nil")
        XCTAssertEqual(error.userInfo.count, 3, "should have minimum number of params")
    }

    func testCreateErrorWithUserInfo() {
        let errorType = SAErrorType(code: 100, message: "This is an error")
        let request = SARemoteRequest()
        let info = [
            "username":"flerb",
            "session":"9999999",
            "loginTime":NSDate(),
            "count":25
        ]

        let service = SARemoteService(serviceName: "TestService")

        let error = service.createError(errorType, request: request, userInfo: info)

        XCTAssertNotNil(error, "should not be nil")
        XCTAssertEqual(error.domain, service.serviceName, "error domain test")
        XCTAssertEqual(error.code, errorType.code)
        XCTAssertNotNil(error.userInfo, "info should not be nil")
        XCTAssertEqual(error.userInfo.count, 7, "should have correctnumber of params")

        XCTAssertEqual(error.userInfo[ "username" ] as! String, info["username"] as! String, "user name")
        XCTAssertEqual(error.userInfo[ "session" ] as! String, info["session"] as! String, "session")
        XCTAssertEqual(error.userInfo[ "loginTime" ] as! NSDate, info["loginTime"] as! NSDate, "time")
        XCTAssertEqual(error.userInfo[ "count" ] as! Int, info["count"] as! Int, "time")
    }

    func testCreateSimpleRemoteRequest() {
        let requestTime = NSDate().timeIntervalSince1970
        let request = SARemoteRequest()

        XCTAssertNotNil(request, "should exist")
        XCTAssertNotNil(request.id, "id should exist")
        XCTAssertNotNil(request.requestTime, "request time should exist")
        XCTAssert(requestTime <= request.requestTime, "validate the request time")
    }

    func testCreateQueryRequest() {
        let params = [
            "username":"flerb",
            "session":"9999999",
            "loginTime":NSDate(),
            "count":25
        ]

        let request = SAQueryRequest(params: params)

        XCTAssertNotNil(request, "should exist")
        XCTAssertEqual(request.params[ "username" ] as! String, params["username"] as! String, "user name")
        XCTAssertEqual(request.params[ "session" ] as! String, params["session"] as! String, "session")
        XCTAssertEqual(request.params[ "loginTime" ] as! NSDate, params["loginTime"] as! NSDate, "time")
        XCTAssertEqual(request.params[ "count" ] as! Int, params["count"] as! Int, "time")
    }
}
