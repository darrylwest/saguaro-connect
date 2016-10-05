//
//  TestDataset.swift
//  SaguaroConnect
//
//  Created by darryl west on 7/21/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import Foundation
import SaguaroJSON
import SaguaroConnect

class TestDataset {
    let jnparser = JNParser()

    var fixturePath:String {
        var parts = #file.components(separatedBy: "/")

        parts.removeLast()

        return "/" + parts.joined(separator: "/")
    }

    func readFixtureFile(_ filename:String) -> String? {
        let path = fixturePath + "/" + filename

        do {
            let text = try String(contentsOfFile: path, encoding: String.Encoding.utf8)

            return text
        } catch let error as NSError {
            NSLog("error reading \( path ) : \(error)")
            return nil
        }
    }

    func createDocumentIdentifierMap() -> [String : AnyObject] {
        let uuid = NSUUID().uuidString.lowercased()
        let mid = uuid.replacingOccurrences(of: "-", with:"")

		let map = [
            "id":mid,
            "dateCreated":Date(),
            "lastUpdated":Date(),
            "version":"1.0"
        ] as [String : Any]

		return map as [String : AnyObject]
    }

    func createModel() -> [String : AnyObject] {
        var model = createDocumentIdentifierMap()
        model["names"] = ["jon", "jane", "joe"] as AnyObject
        model["jobs"] = [
            "job1": "my job 1",
            "job2": "my second job",
            "job 3": "my third job",
            "color": UIColor(red: 100.0/255, green:110.0/255, blue:120.0/255, alpha: 1.0)
        ] as AnyObject

        return model
    }

    func createModelList(_ count:Int? = 20) -> [[String : AnyObject]] {
        var list = [[String : AnyObject]]()
        var cc = count!

        while (cc > 0) {
            list.append( createModel() )
            cc -= 1
        }

        return list
    }

    func createComplexJSONMap() -> [String:Any] {
        let name = "farley"
        let age = 42
        let height = 4.3
        let created = jnparser.dateFromString( "2015-06-18T09:47:49.427+0000" )!

        let model = createModel()

        let obj:[String:Any] = [
            "name": name,
            "age": age,
            "height": height,
            "created": created,
            "hasHair": false,
            "newcolor": UIColor.blue,
            "nullvalue":NSNull(),
            "model":model
        ]

        return obj
    }
}
