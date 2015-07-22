//
//  TestDataset.swift
//  SaguaroConnect
//
//  Created by darryl west on 7/21/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import Foundation
import SaguaroConnect

class TestDataset {
    let jnparser = JNParser()

    func createDocumentIdentifierMap() -> [String:AnyObject] {
        let uuid = NSUUID().UUIDString.lowercaseString
        let mid = uuid.stringByReplacingOccurrencesOfString("-", withString:"")

        let map = [
            "id":mid,
            "dateCreated":NSDate(),
            "lastUpdated":NSDate(),
            "version":"1.0"
        ]

        return map
    }

    func createComplexJSONMap() -> [String:AnyObject] {
        let name = "farley"
        let age = 42
        let height = 4.3
        let created = jnparser.dateFromString( "2015-06-18T09:47:49.427+0000" )!

        var model = createDocumentIdentifierMap()
        model[ "names" ] = ["jon","jane","joe"]
        model[ "jobs" ] = [
            "job1":"my job 1",
            "job2":"my second job",
            "job 3":"my third job",
            "color":UIColor(red: 100.0/255, green:110.0/255, blue:120.0/255, alpha: 1.0)
        ]

        let obj:[String:AnyObject] = [
            "name": name,
            "age": age,
            "height": height,
            "created": created,
            "hasHair": false,
            "newcolor": UIColor.blueColor(),
            "nullvalue":NSNull(),
            "model":model
        ]

        return obj
    }
}