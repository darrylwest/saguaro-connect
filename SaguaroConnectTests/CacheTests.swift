//
//  CacheTests.swift
//  SaguaroConnect
//
//  Created by darryl west on 7/21/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import XCTest
import SaguaroJSON
import SaguaroConnect

class CacheTests: XCTestCase {
    let dataset = TestDataset()
    let jnparser = JNParser()
    let cache = Cache(name: "TestCustomer")
    
    func testInstance() {
        let ca = Cache(name: "Test" )

        XCTAssertNotNil(ca, "cache should exist")
        XCTAssertNotEqual(ca.cacheFile, "", "should have a valid folder")
        XCTAssert(ca.cacheFile.hasSuffix( "Library/Caches/com.vecore.caches/test.json" ))
        XCTAssertEqual(ca.count, 0, "should have zero entries")
    }

    func testSearch() {
        if (cache.count == 0) {
            loadCache()
        }

        XCTAssert( true )

        let c1 = cache.queryByField("name", value:"sa")
        XCTAssertEqual(c1.count, 10, "search for 'sa' should yeild 10")

        let c2 = cache.queryByField("name", value: "sch")
        XCTAssertEqual(c2.count, 40, "search for 'sa' should yeild 10")
    }

    func loadCache() {
        guard let text = dataset.readFixtureFile("customer-list.json") else {
            return XCTFail("could not read text file")
        }

        guard let obj = JSON.parse( text ) else {
            return XCTFail("could not parse customer list response")
        }

        guard let customers = obj["customers"] as? [[String:AnyObject]] else {
            return XCTFail("could not parse customers")
        }

        XCTAssertEqual(customers.count, 820, "customer count")

        for var i = 0; i < customers.count; i++ {
            let obj = customers[ i ]
            let id = obj[ "id" ] as! String

            cache.saveKeyValue( obj, id: id )
        }

        XCTAssertEqual(customers.count, cache.count, "counts")
    }

    func testSaveKeyValue() {
        let model = dataset.createModel()
        let cache = Cache(name: "Test" )

        let id = model[ "id" ] as! String

        XCTAssertEqual(cache.count, 0, "should have zero entries")
        cache.saveKeyValue(model, id: id)
        XCTAssertEqual(cache.count, 1, "should have one entry")

        guard let item = cache.findKeyValueById( id ) else {
            XCTFail("should have found item by id: \( id )")
            return
        }

        XCTAssertEqual(item["id"] as! String, id, "id match")
    }


    func testClearAll() {
        let cache = Cache(name: "Test" )
        let count = 100

        let list = dataset.createModelList( count )

        for item in list {
            let id = item["id"] as! String

            cache.saveKeyValue(item, id: id)
        }

        XCTAssertEqual(cache.count, count, "count match")
        cache.clearAll()
        XCTAssertEqual(cache.count, 0, "should be zero")

    }

    func testCreateJSON() {
        let cache = Cache(name: "Test" )
        let count = 10

        let list = dataset.createModelList(count)

        for item in list {
            let id = item["id"] as! String

            cache.saveKeyValue(item, id: id)
        }

        XCTAssertEqual(cache.count, count, "count match")

        guard let json = cache.createJSON( "customers" ) else {
            XCTFail("failed to create json string")
            return
        }

        print( json )

        XCTAssert( json.characters.count > 100, "should be a string" )

    }

    func testWriteCacheToDisk() {
        let cache = Cache(name: "Test" )
        let count = 10

        let list = dataset.createModelList(count)

        for item in list {
            let id = item["id"] as! String

            cache.saveKeyValue(item, id: id)
        }

        let json = cache.createJSON( "customers" )!
        let ok = cache.writeCacheToDisk(json)

        XCTAssert( ok == true, "should return true")

        print("path: \( cache.cacheFile )")
    }

    func testCreateCacheFolder() {
        let cacheFolder = NSTemporaryDirectory() + "test-caches/"
        let cacheFile = cacheFolder + "foo.cache.json"
        let cache = Cache(name: "Foo", cacheFile:cacheFile )

        XCTAssertEqual(cache.cacheFile, cacheFile, "file names should match")

        do {
            try cache.createCacheFolder()

            // create again, but this time it exists
            try cache.createCacheFolder()

            // now remove it
            let fileManager = NSFileManager.defaultManager()
            try fileManager.removeItemAtPath( cacheFolder )
        } catch {
            XCTFail("failed to create folder for \(cacheFolder)")
        }
    }

    // TODO read from disk
}
