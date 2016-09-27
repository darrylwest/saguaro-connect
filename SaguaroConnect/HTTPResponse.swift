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
    public final var content:Data?
    public var response:URLResponse?
    public var error:NSError?
    public var request:URLRequest?
    public var encoding = String.Encoding.utf8
    public var JSONReadingOptions = JSONSerialization.ReadingOptions(rawValue: 0)
    
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
            let urlString = request?.url?.absoluteString,
            let method = request?.httpMethod
        {
            return "\(method) \(urlString) \(status)"
        } else {
            return "<Empty>"
        }
    }
    
    init(data:Data?, response:URLResponse?, error:NSError?, request:URLRequest?) {
        self.content = data
        self.response = response
        self.error = error
        self.request = request
    }
    
    public var json: Any? {
        if let theData = self.content {
            do {
                return try JSONSerialization.jsonObject(with: theData, options: JSONReadingOptions)
            } catch _ {
                return nil
            }
        }
        return nil
    }
    public var statusCode: Int? {
        if let theResponse = self.response as? HTTPURLResponse {
            return theResponse.statusCode
        }
        return nil
    }
    
    public var text:String? {
        if let theData = self.content {
            return NSString(data:theData, encoding:encoding.rawValue) as? String
        }
        return nil
    }
    
    public lazy var headers:CaseInsensitiveDictionary<String,String> = {
        return CaseInsensitiveDictionary<String,String>(dictionary: (self.response as? HTTPURLResponse)?.allHeaderFields as? [String:String] ?? [:])
        }()
    
    public lazy var cookies:[String:HTTPCookie] = {
        let foundCookies: [HTTPCookie]
        if let responseHeaders = (self.response as? HTTPURLResponse)?.allHeaderFields as? [String: String] {
            foundCookies = HTTPCookie.cookies(withResponseHeaderFields: responseHeaders, for:URL(string:"")!) as [HTTPCookie]
        } else {
            foundCookies = []
        }
        var result:[String:HTTPCookie] = [:]
        for cookie in foundCookies {
            result[cookie.name] = cookie
        }
        return result
        }()
    
    public var ok:Bool {
        return statusCode != nil && !(statusCode! >= 400 && statusCode! < 600)
    }
    
    public var url:URL? {
        return response?.url
    }
}

