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

        for i in 0 ..< customers.count {
            let obj = customers[ i ]
            let id = obj[ "id" ] as! String

            cache.saveKeyValue( obj, id: id )
        }

        XCTAssertEqual(customers.count, cache.count, "counts")
    }
    
    func testGetItems() {
        if (cache.count == 0) {
            loadCache()
        }
        
        let items = cache.getItems()
        XCTAssertEqual(items.count, 820, "count")
        
        let map = items.map {
            return $0
        }
        
        XCTAssertEqual(map.count, items.count, "map count")
    }

    func testSearch() {
        if (cache.count == 0) {
            loadCache()
        }

        XCTAssert( true )

        let c1 = cache.queryByField("name", value:"sa")
        XCTAssertEqual(c1.count, 10, "search for 'sa' should yeild 10")

        /*
        for item in c1 {
            let name = item[ "name" ] as! String

            let id = item[ "id" ] as! String

            print( "\( name ) \( id )" )
        }
        */

        let c2 = cache.queryByField("name", value: "sch")
        XCTAssertEqual(c2.count, 40, "search for 'sa' should yeild 10")
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

        XCTAssertEqual(item["id"] as? String, id, "id match")
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

    func testRemoteById() {
        let cache = Cache(name: "Test" )
        let count = 10

        let list = dataset.createModelList( count )
        var removeId:String? = nil

        for item in list {
            let id = item["id"] as! String

            cache.saveKeyValue(item, id: id)

            if removeId == nil {
                removeId = id
            }
        }

        let rid = removeId!

        XCTAssertEqual(cache.count, count, "count match")
        guard let removed = cache.removeById( rid ) else {
            return XCTFail("remove failed for id \( rid )")
        }

        print( removed )

        XCTAssertEqual(cache.count, count - 1, "count match")
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
    
    func testReadCacheFromDisk() {
        let cache = Cache(name: "Test" )
        guard let str = cache.readCacheFromDisk() else {
            return XCTFail("could not read file")
        }
        print("string: \( str )")
        XCTAssertNotNil( str, "should read something back")
        
        let stats = cache.listStats()
        print( stats )
    }

    func testListStats() {

        let cache = Cache(name: "Test")

        let stats = cache.listStats()
        print( stats )
        XCTAssertNotNil( stats, "should not be nil")

        XCTAssertNotNil( stats[ "name" ], "should have name element")
        XCTAssertNotNil( stats[ "filename" ], "should have filename element")
        XCTAssertNotNil( stats[ "elementCount" ], "should have elementCount element")
        XCTAssertNotNil( stats[ "fileSize" ], "should have fileSize element")
        XCTAssertNotNil( stats[ "fileDate" ], "should have fileDate element")
    }
    
    func testRemoveCacheFile() {
        let cache = Cache(name: "Test")
        
        XCTAssert(cache.removeCacheFile(), "should return true")
    }
    
    func testParseJSONResponse() {
        let cache = Cache(name: "Test")
        
        guard let str = cache.readCacheFromDisk() else {
            return XCTFail("could not read file")
        }
        print("string: \( str )")
        
        let (jobj, wrap, err) = cache.parseJSONResponse( str )
        
        XCTAssertNil( err, "error should be nil")
        XCTAssertNotNil(jobj, "json should not be nil")
        
        guard let jsonObject = jobj else {
            return XCTFail("could not create json object")
        }
        
        guard let wrapper = wrap else {
            print( "fail: \( wrap )" )
            return XCTFail("wrapper should not be nil")
        }
        
        XCTAssertEqual( wrapper.status, "ok", "status ok")
        XCTAssertEqual( wrapper.isOk, true, "ok true")
        
        guard let list = jsonObject[ "customers" ] as? [[String:AnyObject]] else {
            return XCTFail("could not locate customer list")
        }
        
        XCTAssertEqual(list.count, 10, "verify customer count")
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
            let fileManager = FileManager.default
            try fileManager.removeItem(atPath: cacheFolder)
        } catch {
            XCTFail("failed to create folder for \(cacheFolder)")
        }
    }

    func testFindLatestUpdateDate() {
        let cache = Cache(name: "Test")
        let count = 10
        var dates = [String]()

        for i in 0 ..< count {
            let rt = TimeInterval( Double( arc4random_uniform( 100000000 )) + 1000000.0 )
            let dt = Date( timeIntervalSinceReferenceDate: rt )
            let id = "id-\( i )"

			let obj: [String : AnyObject] = [
                "id": id as AnyObject,
                "lastUpdated": jnparser.stringFromDate(dt) as AnyObject
            ]

            dates.append( "\( dt )")

            cache.saveKeyValue(obj, id: id)
        }

        let last = dates.sorted().last!
        print( last )

        XCTAssertEqual( cache.count, count, "size" )

        let date = cache.findLatestUpdateDate()
        print( "latest: \( date )")

        XCTAssertEqual("\( date )", "\( last )", "check latest")
    }


}
