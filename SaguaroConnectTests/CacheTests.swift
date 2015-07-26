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
    
    func testInstance() {
        let cache = Cache(name: "Test" )

        XCTAssertNotNil(cache, "cache should exist")
        XCTAssertNotEqual(cache.cacheFile, "", "should have a valid folder")
        XCTAssert(cache.cacheFile.hasSuffix( "Library/Caches/com.vecore.caches/test.json" ))
        XCTAssertEqual(cache.count, 0, "should have zero entries")
    }
/*
    func testSaveKeyValue() {
        let parser = factory.dataModelParser.customerParser
        let cache = Cache(name: "TestCustomer" )

        let customer = dataset.createCustomer( "My Test Customer" )
        let id = customer.doi.id
        let obj = parser.toMap( customer )

        XCTAssertEqual(cache.count, 0, "should have zero entries")
        cache.saveKeyValue(obj, id: id)
        XCTAssertEqual(cache.count, 1, "should have one entry")

        guard let item = cache.findKeyValueById( id ) else {
            XCTFail("should have found item by id: \( id )")
            return
        }

        XCTAssertEqual(item["id"] as! String, id, "id match")
    }


    func testClearAll() {

        let parser = factory.dataModelParser.customerParser
        let cache = Cache(name: "TestCustomer" )
        let count = 100

        let list = dataset.createCustomerList(count)

        for customer in list {
            let id = customer.doi.id
            let obj = parser.toMap( customer )

            cache.saveKeyValue(obj, id: id)
        }

        XCTAssertEqual(cache.count, count, "count match")
        cache.clearAll()
        XCTAssertEqual(cache.count, 0, "should be zero")

        for customer in list {
            let id = customer.doi.id

            let item = cache.findKeyValueById(id)

            XCTAssertNil( item )
        }
    }

    func testCreateJSON() {
        let parser = factory.dataModelParser.customerParser
        let cache = Cache(name: "TestCustomer" )
        let count = 10

        let list = dataset.createCustomerList(count)

        for customer in list {
            let id = customer.doi.id
            let obj = parser.toMap( customer )

            cache.saveKeyValue(obj, id: id)
        }

        guard let json = cache.createJSON( "customers" ) else {
            XCTFail("failed to create json string")
            return
        }

        print( json )

        XCTAssert( json.characters.count > 100, "should be a string" )

    }

    func testWriteCacheToDisk() {
        let parser = factory.dataModelParser.customerParser
        let cache = Cache(name: "TestCustomer", cacheFile: Cache.createPermanentCachePath("test-customer") )
        let count = 100

        let list = dataset.createCustomerList(count)

        for customer in list {
            let id = customer.doi.id
            let obj = parser.toMap( customer )

            cache.saveKeyValue(obj, id: id)
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

    func testReadCacheFromDisk() {
        let parser = factory.dataModelParser.customerParser
        let cache = Cache(name: "TestCustomer" )
        let count = 100

        let list = dataset.createCustomerList(count)

        for customer in list {
            let id = customer.doi.id
            let obj = parser.toMap( customer )

            cache.saveKeyValue(obj, id: id)
        }

        let json = cache.createJSON( "customers" )!
        let ok = cache.writeCacheToDisk(json)

        XCTAssert( ok == true, "should return true")

        print("cache: \( cache.cacheFile )")

        if let contents = cache.readCacheFromDisk() {
            print( contents )
            XCTAssert(contents.characters.count > 100, "should have a reasonable amount of characters")
        } else {
            XCTFail("could not read file")
        }
        
        
        do {
            // now remove it
            let fileManager = NSFileManager.defaultManager()
            try fileManager.removeItemAtPath( cache.cacheFile )
        } catch {
            print("warning! file could not be removed: \( cache.cacheFile )")
        }
    }
   */ 
}
