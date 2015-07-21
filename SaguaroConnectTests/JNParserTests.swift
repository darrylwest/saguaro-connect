//
//  JNParserTests.swift
//  SaguaroConnect
//
//  Created by darryl west on 7/21/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import XCTest
import SaguaroConnect

class JNParserTests: XCTestCase {
    let dataset = TestDataset()
    let jnparser = JNParser()

    func testStringifyPretty() {
        let obj = dataset.createComplexJSONMap()

        let jstr = jnparser.stringify( obj, pretty:true )!

        print( jstr )
        XCTAssertNotNil(jstr, "should not be nil")

        // not a great test, but it should return predictable results...
        XCTAssertEqual(jstr.characters.count, 510, "should match the character count")
    }

    func testStringify() {
        let obj = dataset.createComplexJSONMap()

        let jstr = jnparser.stringify( obj )!

        print( jstr )
        XCTAssertNotNil(jstr, "should not be nil")

        // not a great test, but it should return predictable non-pretty length...
        XCTAssertEqual(jstr.characters.count, 371, "should match the character count")
    }

    func testParse() {
        let dataset = TestDataset()

        let complexMap = dataset.createComplexJSONMap()

        // print( doiMap )

        let jstr = jnparser.stringify( complexMap )!

        // print( jstr )

        XCTAssertNotNil(jstr, "json string should not be nil")

        let jmap = jnparser.parse( jstr )

        XCTAssertNotNil(jmap, "json map should not be nil")
    }

    func testParseDateFromJSONString() {
        let parts = NSDateComponents()

        parts.year = 2015
        parts.month = 6
        parts.day = 18
        parts.hour = 9
        parts.minute = 47
        parts.second = 49

        let calendar = NSCalendar.currentCalendar()
        guard let date = calendar.dateFromComponents( parts ) else {
            XCTFail("should create a date string")
            return
        }

        guard let ds:String = jnparser.stringFromDate( date ) else {
            XCTFail("should create a date string")
            return
        }

        guard let dt = jnparser.dateFromString( ds ) else {
            XCTFail("should create a date from json string")
            return
        }

        XCTAssertNotNil(dt, "should not be nil")

        XCTAssertEqual(dt, date, "dates should match")

        let parsedParts:NSDateComponents = calendar.components([ .Year, .Month, .Day, .Hour, .Minute, .Second ], fromDate: dt)

        // print( parsedParts )

        XCTAssertEqual(parsedParts.year, parts.year, "should match")
        XCTAssertEqual(parsedParts.month, parts.month, "should match")
        XCTAssertEqual(parsedParts.day, parts.day, "should match")
        XCTAssertEqual(parsedParts.hour, parts.hour, "should match")
        XCTAssertEqual(parsedParts.minute, parts.minute, "should match")
        XCTAssertEqual(parsedParts.second, parts.second, "should match")
    }

    func testParseBadDateFromJSONString() {
        let ds = "2015/06/18 00:47:49"

        let dt = jnparser.dateFromString(ds)

        XCTAssertNil(dt, "should not be nil")
    }
    
}
