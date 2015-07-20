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
    }

    func testCreateSimpleRemoteRequest() {

    }

    func testCreateQueryRequest() {

    }
}
