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
public class Cache {
    let jnparser:JNParser
    let fileManager:NSFileManager

    var cache = [String:AnyObject]()
    public let cacheFile:String
    
    // TODO : create a mutator for this...
    public var lastRefresh:NSDate = NSDate.distantPast()

    /// this is the index to all cache items
    final public var count:Int {
        return cache.count
    }

    public let name:String
    
    public func getItems() -> [String:AnyObject] {
        // make a copy?
        return cache
    }

    public init(name:String, cacheFile:String? = nil) {
        jnparser = JNParser()
        self.name = name

        // use the shared instance
        fileManager = NSFileManager.defaultManager()

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
    final public func saveKeyValue(value:[String:AnyObject], id key:String) {
        // if key/value exists, see if this is an update; trigger save required
        cache[ key ] = value
    }

    /// find and return the value from key if it exists in the cache
    final public func findKeyValueById(id:String) -> [String:AnyObject]? {
        guard let item = cache[ id ] as? [String:AnyObject] else {
            return nil
        }

        return item
    }

    /// searches by lowercased prefix and returns list of item, i.e., models sorted by the field
    public func queryByField(field:String, value:String) -> [[String:AnyObject]] {
        let search = value.lowercaseString
        var list = [[String:AnyObject]]()

        for (_, obj) in cache {
            if let val = obj[ field ] as? String {
                if val.lowercaseString.hasPrefix( search ) {
                    list.append( obj as! [String:AnyObject] )
                }
            }
        }

        let sorted = list.sort { v1, v2 in
            if let s1 = v1[ field ] as? String, s2 = v2[ field ] as? String {
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

    /// read all keys from the cache index; copy all objects; wrap the object list and return as a json string
    final public func createJSON(listName:String) -> String? {
        var list = [AnyObject]()

        for (_,value) in cache {
            list.append( value )
        }

        let wrapper = JSONResponseWrapper.createWrapper(key:listName, value:list)

        return jnparser.stringify( wrapper )
    }

    /// read and return the cache file contents if they exist; read on startup if off-line
    final public func readCacheFromDisk() -> String? {
        if fileManager.fileExistsAtPath( cacheFile ) {

            do {
                let str = try String(contentsOfFile: cacheFile, encoding: NSUTF8StringEncoding)

                return str
            } catch let error as NSError {
                NSLog("could not read file contents: \( error )")
            }
        }

        return nil
    }

    /// use this to write json files directly to the cache folder, e.g., on startup when on-line
    final public func writeCacheToDisk(contents:String) -> Bool {
        if cacheFile.characters.isEmpty {
            return false
        }

        do {
            try createCacheFolder()
            try contents.writeToFile(cacheFile, atomically: true, encoding: NSUTF8StringEncoding)

            return true
        } catch let error as NSError {
            NSLog("error writing cache file to \( cacheFile ), \( error )")
        }

        return false
    }

    /// create the cache folder from the specified cache file path
    final public func createCacheFolder() throws {
        let filename = fileManager.displayNameAtPath( cacheFile )
        guard let range:Range<String.Index> = cacheFile.rangeOfString( filename ) else {
            NSLog("could not find filename \( filename ) from path: \( cacheFile )")
            return
        }

        var cacheFolder = cacheFile
        cacheFolder.removeRange( range )

        if fileManager.fileExistsAtPath( cacheFolder ) == false {
            try fileManager.createDirectoryAtPath(cacheFolder, withIntermediateDirectories: true, attributes: nil)
        }
    }

    /// creates a standard path for temporary cache files; this may not be the best place for the cache files. your
    /// subclass may require a more stable folder to insure that iOS neither removes files or discards data
    static public func createCachePath(name:String) -> String? {
        guard let path = NSSearchPathForDirectoriesInDomains( .CachesDirectory, .UserDomainMask, true ).first else {
            return nil
        }

        return "\( path )/com.vecore.caches/\( name.lowercaseString ).json"
    }

    /// a permanent cache location
    static public func createPermanentCachePath(name:String) -> String? {
        guard let path = NSSearchPathForDirectoriesInDomains( .LibraryDirectory , .UserDomainMask, true ).first else {
            return nil
        }
        
        return "\( path )/com.vecore.caches/\( name.lowercaseString ).json"
    }
}