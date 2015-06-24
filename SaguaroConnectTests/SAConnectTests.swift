//
//  SAConnectTests.swift
//  SaguaroConnect
//
//  Created by Darryl West on 6/23/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import XCTest
@testable import SaguaroConnect

class HTTPRemoteTests: XCTestCase {
    
    // for async tests
    let timeout = NSTimeInterval( 2.0 )
    let expectationName = "httpRequestComplete"
    
    func testSyncronousGet() {
        let http = SARemote()
        
        let request = HTTPRequest(url: "http://httpbin.org/get", params:["page": 3] )
        
        // the httpResponse
        let resp = http.get( request )
        
        print("headers:")
        for (key, value) in resp.headers {
            print("\tkey/value: \( key )=\( value )")
        }
        
        // print( "content: \(r.content)" )
        // print( "text: \(r.text! )" )
        print( "json: \(resp.json! )")
        print( "url: \(resp.url )")
        
        XCTAssertTrue( resp.ok )
        XCTAssertEqual( resp.statusCode!, 200 )
    }
    
    func testAsyncRequest() {
        let expectation = expectationWithDescription( expectationName )
        
        let callback:((HTTPResult!) -> Void)? = { (response:HTTPResult!) -> Void in
            print("status: \( response.ok )")
            print("json: \( response.json )")
            
            XCTAssertTrue(response.ok, "should be ok")
            XCTAssertNotNil(response.json, "json should not be null")
            
            expectation.fulfill()
        }
        
        let http = SARemote()
        let request = HTTPRequest(url: "http://httpbin.org/get", params:["page": 3], asyncCompletionHandler: callback )
        http.get(request)
        
        waitForExpectationsWithTimeout(timeout, handler: { error in
            XCTAssertNil(error, "asyn error: \( error )")
        })
    }
    
    func testHTTPRequest() {
        let request = HTTPRequest(url:"http://httpbin.org/get", params:["page": 3])
        
        XCTAssertEqual(request.url, "http://httpbin.org/get")
        XCTAssertNotNil(request.params, "should not be nil")
    }
    
    func testHTTPPost() {
        let json = ["firstName":"barney", "lastName":"fife"]
        let request = HTTPRequest(url: "http://httpbin.org/post", json:json, timeout:20)
        
        let http = SARemote()
        let resp = http.post( request )
        
        XCTAssertTrue(resp.ok, "should be ok")
        
        print("response: \( resp.json )")
    }
    
    func testTimeout() {
        let http = SARemote()
        
        let resp = http.get(HTTPRequest( url: "http://httpbin.org/delay/5", timeout:0.1 ))
        
        print( resp.reason )
        
        XCTAssertNotNil(resp.reason, "should be a timeout reason")
    }
    
    func testHTTPHead() {
        let json = ["firstName":"barney", "lastName":"fife", "more":"less"]
        let request = HTTPRequest(url: "http://httpbin.org/get", json:json, timeout:20)
        
        let http = SARemote()
        let resp = http.head( request )
        
        print("head response: \( resp )")
        print("json: \( resp.json )")
        
        XCTAssertNil(resp.json, "should be nil")
        
        // XCTAssert(resp.ok, "should be ok")
        print("headers:")
        for (key, value) in resp.headers {
            print("\tkey/value: \( key )=\( value )")
        }
    }
}
