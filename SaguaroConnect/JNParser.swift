//
//  JNParser.swift
//  SaguaroConnect
//
//  Created by darryl west on 7/21/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import Foundation

public typealias UnixTimestamp = Int

public protocol JSONDateType {
    func dateFromString(dateString: String) -> NSDate?
    func stringFromDate(date:NSDate) -> String
    func createUnixTimestamp() -> UnixTimestamp
}

public protocol JSONParserType {
    func parseDate(obj:AnyObject?) -> NSDate?
    func stringify(map:[String:AnyObject]) -> String?
    func parse(jsonString: String) -> [String:AnyObject]?
}

public struct JNDateFormatter: JSONDateType {
    private let formatter:NSDateFormatter

    public func dateFromString(dateString:String) -> NSDate? {
        guard let date = formatter.dateFromString( dateString ) as NSDate! else {
            return nil
        }

        return date
    }

    public func stringFromDate(date:NSDate) -> String {
        return formatter.stringFromDate( date )
    }

    public func createUnixTimestamp() -> UnixTimestamp {
        return Int( NSDate().timeIntervalSince1970 * 1000 )
    }

    init() {
        formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = NSTimeZone(abbreviation: "UTC")
    }
}

/// JNParser - this is the primary json parse interface.  It's primary fuctions are to serialize (stringify) objects to json
/// strings or to prase strings to return a object graph
public struct JNParser: JSONParserType, JSONDateType {

    public let formatter:JNDateFormatter

    public init() {
        formatter = JNDateFormatter()
    }

    public func parseDate(obj:AnyObject?) -> NSDate? {
        switch obj {
        case is NSDate:
            return obj as? NSDate
        case is String:
            return formatter.dateFromString( obj as! String )
        default:
            return nil
        }
    }

    public func dateFromString(dateString: String) -> NSDate? {
        return formatter.dateFromString( dateString )
    }

    public func stringFromDate(date:NSDate) -> String {
        return formatter.stringFromDate(date)
    }

    public func prepareObjectArray(list:[AnyObject]) -> [AnyObject] {
        var array = [AnyObject]()

        for value in list {

            switch value {
            case let date as NSDate:
                array.append( stringFromDate( date ) )
            case let objMap as [String:AnyObject]:
                array.append( self.prepareObjectMap( objMap ))
            case let objArray as [AnyObject]:
                array.append( self.prepareObjectArray( objArray ))
            default:
                array.append( value )
            }
        }

        return array
    }

    public func prepareObjectMap(map:[String:AnyObject]) -> [String:AnyObject] {
        var obj = [String:AnyObject]()

        // walk the object to convert all dates to strings: won't handle an array of dates, but that's unlikely...
        for (key, value) in map {
            switch value {
            case let date as NSDate:
                obj[ key ] = stringFromDate( date )
            case let objMap as [String:AnyObject]:
                obj[ key ] = self.prepareObjectMap( objMap )
            case let objArray as [AnyObject]:
                obj[ key ] = self.prepareObjectArray( objArray )
            default:
                obj[ key ] = value
            }
        }

        return obj
    }

    public func createUnixTimestamp() -> UnixTimestamp {
        return formatter.createUnixTimestamp()
    }

    public func stringify(map: [String : AnyObject]) -> String? {
        return self.stringify(map, pretty: false)
    }

    public func stringify(map:[String:AnyObject], pretty:Bool? = false) -> String? {
        let obj = prepareObjectMap( map )

        if (!NSJSONSerialization.isValidJSONObject(obj)) {
            NSLog("\( __FUNCTION__ ): serialization validation error for object: \( obj )")
            assert(false, "serialization error")
            return nil
        }

        do {
            // this mess is to get around the 2.0 way of handling options
            let data:NSData

            if pretty! {
                data = try NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions.PrettyPrinted)
            } else {
                data = try NSJSONSerialization.dataWithJSONObject(obj, options: [])
            }

            if let json = NSString(data: data, encoding: NSUTF8StringEncoding) {
                return json as String
            }

        } catch {
            NSLog( "\( __FUNCTION__ ): stringify could not serialize data with json object: \( obj )")
            assert(false, "serialization error")
        }

        return nil
    }

    public func parse(jsonString: String) -> [String:AnyObject]? {

        // TODO: implement me
        guard let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding) else {
            NSLog("\( __FUNCTION__ ): parse error in json string: \( jsonString )")
            return nil
        }

        do {
            let obj = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers )

            return (obj as! [String : AnyObject])
        } catch {
            NSLog("\( __FUNCTION__ ): parse failed on json string: \( jsonString )")
            return nil
        }
    }
}

