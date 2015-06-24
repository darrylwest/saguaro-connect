//
//  HTTPResponse.swift
//  Sandbox
//
//  Created by Daniel Duan on 4/21/15.
//  Copyright (c) 2015 JustHTTP. All rights reserved.
//

import Foundation


/// The only reason this is not a struct is the requirements for
/// lazy evaluation of `headers` and `cookies`, which is mutating the
/// struct. This would make those properties unusable with `HTTPResult`s
/// declared with `let`
public final class HTTPResult : NSObject {
    public final var content:NSData?
    public var response:NSURLResponse?
    public var error:NSError?
    public var request:NSURLRequest?
    public var encoding = NSUTF8StringEncoding
    public var JSONReadingOptions = NSJSONReadingOptions(rawValue: 0)
    
    public var reason:String {
        if  let code = self.statusCode,
            let text = statusCodeDescriptions[code] {
                return text
        }
        if let error = self.error {
            return error.localizedDescription
        }
        return "Unkown"
    }
    public var isRedirect:Bool {
        if let code = self.statusCode {
            return code >= 300 && code < 400
        }
        return false
    }
    
    public var isPermanentRedirect:Bool {
        return self.statusCode == 301
    }
    
    public override var description:String {
        if let status = statusCode,
            urlString = request?.URL?.absoluteString,
            method = request?.HTTPMethod
        {
            return "\(method) \(urlString) \(status)"
        } else {
            return "<Empty>"
        }
    }
    
    init(data:NSData?, response:NSURLResponse?, error:NSError?, request:NSURLRequest?) {
        self.content = data
        self.response = response
        self.error = error
        self.request = request
    }
    
    public var json:AnyObject? {
        if let theData = self.content {
            do {
                return try NSJSONSerialization.JSONObjectWithData(theData, options: JSONReadingOptions)
            } catch _ {
                return nil
            }
        }
        return nil
    }
    public var statusCode: Int? {
        if let theResponse = self.response as? NSHTTPURLResponse {
            return theResponse.statusCode
        }
        return nil
    }
    
    public var text:String? {
        if let theData = self.content {
            return NSString(data:theData, encoding:encoding) as? String
        }
        return nil
    }
    
    public lazy var headers:CaseInsensitiveDictionary<String,String> = {
        return CaseInsensitiveDictionary<String,String>(dictionary: (self.response as? NSHTTPURLResponse)?.allHeaderFields as? [String:String] ?? [:])
        }()
    
    public lazy var cookies:[String:NSHTTPCookie] = {
        let foundCookies: [NSHTTPCookie]
        if let responseHeaders = (self.response as? NSHTTPURLResponse)?.allHeaderFields as? [String: String] {
            foundCookies = NSHTTPCookie.cookiesWithResponseHeaderFields(responseHeaders, forURL:NSURL(string:"")!) as [NSHTTPCookie]
        } else {
            foundCookies = []
        }
        var result:[String:NSHTTPCookie] = [:]
        for cookie in foundCookies {
            result[cookie.name] = cookie
        }
        return result
        }()
    
    public var ok:Bool {
        return statusCode != nil && !(statusCode! >= 400 && statusCode! < 600)
    }
    
    public var url:NSURL? {
        return response?.URL
    }
}

