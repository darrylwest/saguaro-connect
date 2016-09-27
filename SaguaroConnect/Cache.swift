//
//  Cache.swift
//  SaguaroConnect
//
//  Created by darryl west on 7/21/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import Foundation
import SaguaroJSON

/// Cache - backed by map[String:AnyObject] to persist to disk similar to mongo/redis/etc.
/// NOTES:
///     - NSCache was not used because iOS may remove objects without warning
///     - NSDictionary was not used because it doesn't implement try/catch on write
///     - JSON was used to serialize and make it easy to upload/download pre-loaded caches
///     - two directory options are offered-one in caches and another more stable location in Library
open class Cache {
    open static let JSON_PARSE_ERROR_CODE = 120
    
    let jnparser: JNParser
    let fileManager: FileManager

    var cache = [String:AnyObject]()
    open let cacheFile: String
    
    // TODO : create a mutator for this...
    open var lastRefresh:Date = Date.distantPast

    /// this is the index to all cache items
    final public var count:Int {
        return cache.count
    }

    open let name:String
    
    /// return all the cached items as an array of maps
    final public func getItems() -> [String:AnyObject] {
        // make a copy?
        return cache
    }

    public init(name:String, cacheFile:String? = nil) {
        jnparser = JNParser()
        self.name = name

        // use the shared instance
        fileManager = FileManager.default

        if let file = cacheFile {
            self.cacheFile = file
        } else {
            if let path = Cache.createCachePath( name ) {
                self.cacheFile = path
            } else {
                NSLog("could not locate cache path using ns search path")
                self.cacheFile = ""
            }
        }

    }

    /// save the key to the cache
    final public func saveKeyValue(_ value:[String:AnyObject], id key:String) {
        // if key/value exists, see if this is an update; trigger save required
        cache[ key ] = value as AnyObject?
    }

    /// find and return the value from key if it exists in the cache
    final public func findKeyValueById(_ id:String) -> [String:AnyObject]? {
        guard let item = cache[ id ] as? [String:AnyObject] else {
            return nil
        }

        return item
    }

    /// find and remove the item by id
    final public func removeById(_ id:String) -> [String:AnyObject]? {
        guard let item = findKeyValueById( id ) else {
            return nil
        }

        // remove it
        cache[ id ] = nil

        return item
    }

    /// searches by lowercased prefix and returns list of item, i.e., models sorted by the field
    open func queryByField(_ field:String, value:String) -> [[String:AnyObject]] {
        let search = value.lowercased()
        var list = [[String:AnyObject]]()

        for (_, obj) in cache {
            if let val = obj[ field ] as? String {
                if val.lowercased().hasPrefix( search ) {
                    list.append( obj as! [String:AnyObject] )
                }
            }
        }

        let sorted = list.sorted { v1, v2 in
            if let s1 = v1[ field ] as? String, let s2 = v2[ field ] as? String {
                return s1 < s2
            } else {
                return false
            }
        }

        return sorted
    }

    /// clear all objects from the cache; this does not remove or affect the cache file
    final public func clearAll() {
        cache.removeAll()
    }
    
    /// remove the cache file; return true if no errors
    final public func removeCacheFile() -> Bool {
        
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem( atPath: cacheFile )
        } catch let err {
            NSLog("error removing cache file: \( err )")
            return false
        }
        
        return true
    }

    /// read all keys from the cache index; copy all objects; wrap the object list and return as a json string
    final public func createJSON(_ listName:String) -> String? {
        var list = [AnyObject]()

        for (_,value) in cache {
            list.append( value )
        }

        let wrapper = JSONResponseWrapper.createWrapper(key:listName, value:list as AnyObject)

        return jnparser.stringify( wrapper )
    }
    
    final public func parseJSONResponse(_ json:String) -> ([String:AnyObject]?, JSONResponseWrapper?, NSError?) {
        func createError(_ reason:String) -> ([String:AnyObject]?, JSONResponseWrapper?, NSError?) {
            let info = [ "parse": name, "reason": reason ]
            return (nil, nil, NSError( domain: self.name, code: Cache.JSON_PARSE_ERROR_CODE, userInfo: info))
        }
        
        guard let jsonObject = jnparser.parse( json ) else {
            return createError("error parsing json string")
        }
        
        guard let wrapper = JSONResponseWrapper( jsonObject: jsonObject ) else {
            return createError("error creating wrapper from object \( jsonObject )")
        }
        
        return (jsonObject, wrapper, nil)
    }

    /// read and return the cache file contents if they exist; read on startup if off-line
    final public func readCacheFromDisk() -> String? {
        if fileManager.fileExists( atPath: cacheFile ) {

            do {
                let str = try String(contentsOfFile: cacheFile, encoding: String.Encoding.utf8)

                return str
            } catch let error as NSError {
                NSLog("could not read file contents: \( error )")
            }
        }

        return nil
    }

    /// use this to write json files directly to the cache folder, e.g., on startup when on-line
    final public func writeCacheToDisk(_ contents:String) -> Bool {
        if cacheFile.characters.isEmpty {
            return false
        }

        do {
            try createCacheFolder()
            try contents.write(toFile: cacheFile, atomically: true, encoding: String.Encoding.utf8)

            return true
        } catch let error as NSError {
            NSLog("error writing cache file to \( cacheFile ), \( error )")
        }

        return false
    }

    /// find the latest update based on parameter "lastUpdated" (complient with data model DOI)
    final public func findLatestUpdateDate() -> Date {
        var latestDate = Date(timeIntervalSinceReferenceDate: 0.0)

        for (_,item) in getItems() {
            if let map = item as? [String:AnyObject] {
                if let date = jnparser.parseDate( map[ "lastUpdated" ]) {
                    if latestDate.compare( date ) == ComparisonResult.orderedAscending {
                        latestDate = date
                    }
                }
            }
        }

        return latestDate
    }

    /// write the cached data models to local disk with standard wrapper
    final public func syncToDisk(_ listName:String) -> Bool {
        guard let json = createJSON( listName ) else { return false }
        return writeCacheToDisk( json )
    }

    /// read the data models from local disk and save to cache; data models must include an id
    final public func syncFromDisk(_ listName:String) -> (Int?, NSError?) {
        guard let str = readCacheFromDisk() else {
            return (0, nil)
        }

        let (jobj, wrap, err) = parseJSONResponse( str )

        if let error = err {
            return (nil, error)
        }

        guard let jsonObject = jobj, let wrapper = wrap else {
            return (nil, err)
        }

        if wrapper.isOk == false {
            return (nil, NSError(domain: name, code: Cache.JSON_PARSE_ERROR_CODE, userInfo: [ "reason": wrapper.reason ]))
        }

        guard let list = jsonObject[ listName ] as? [[String:AnyObject]] else {
            return (nil, NSError(domain: name, code: Cache.JSON_PARSE_ERROR_CODE, userInfo: [ "reason":"could not locate list from name: \( listName )"]))
        }

        for item in list {
            if let id = item["id"] as? String {
                // no need to fully parse, just save the raw item
                saveKeyValue( item, id: id )
            }
        }
        
        return (count, nil)
    }

    // return a list of stats, filename, size, count, etc
    open func listStats() -> [String:Any] {
        var stats: [String : Any] = [
            "name": self.name,
            "filename": self.cacheFile,
            "elementCount": self.cache.count
        ]

        do {
            let fileAttrs = try fileManager.attributesOfItem( atPath: cacheFile )

            stats["fileSize"] = fileAttrs[FileAttributeKey.size]
            stats[ "fileDate"] = fileAttrs[FileAttributeKey.modificationDate]
        } catch let err {
            stats[ "fileError" ] = err as NSError?
        }

        return stats
    }

    /// create the cache folder from the specified cache file path
    final public func createCacheFolder() throws {
        let filename = fileManager.displayName( atPath: cacheFile )
        guard let range:Range<String.Index> = cacheFile.range( of: filename ) else {
            NSLog("could not find filename \( filename ) from path: \( cacheFile )")
            return
        }

        var cacheFolder = cacheFile
        cacheFolder.removeSubrange( range )

        if fileManager.fileExists( atPath: cacheFolder ) == false {
            try fileManager.createDirectory(atPath: cacheFolder, withIntermediateDirectories: true, attributes: nil)
        }
    }

    /// creates a standard path for temporary cache files; this may not be the best place for the cache files. your
    /// subclass may require a more stable folder to insure that iOS neither removes files or discards data
    static open func createCachePath(_ name:String) -> String? {
        guard let path = NSSearchPathForDirectoriesInDomains( .cachesDirectory, .userDomainMask, true ).first else {
            return nil
        }

        return "\( path )/com.vecore.caches/\( name.lowercased() ).json"
    }

    /// a permanent cache location
    static open func createPermanentCachePath(_ name:String) -> String? {
        guard let path = NSSearchPathForDirectoriesInDomains( .libraryDirectory , .userDomainMask, true ).first else {
            return nil
        }
        
        return "\( path )/com.vecore.caches/\( name.lowercased() ).json"
    }
}
