//
//  Just.swift
//  Just
//
//  Created by Daniel Duan on 4/21/15.
//  Copyright (c) 2015 JustHTTP. All rights reserved.
//

import Foundation

public enum HTTPFile {
    case URL(NSURL,String?) // URL to a file, mimetype
    case Data(String,NSData,String?) // filename, data, mimetype
    case Text(String,String,String?) // filename, text, mimetype
}

// Supported request types; public to enable mock
public enum HTTPMethod: String {
    case DELETE = "DELETE"
    case GET = "GET"
    case HEAD = "HEAD"
    case OPTIONS = "OPTIONS"
    case PATCH = "PATCH"
    case POST = "POST"
    case PUT = "PUT"
}

typealias TaskID = Int
typealias Credentials = (username:String, password:String)
typealias TaskProgressHandler = (HTTPProgress!) -> Void
typealias TaskCompletionHandler = (HTTPResult) -> Void
struct TaskConfiguration {
    let credential:Credentials?
    let redirects:Bool
    let originalRequest: NSURLRequest?
    var data: NSMutableData
    let progressHandler: TaskProgressHandler?
    let completionHandler: TaskCompletionHandler?
}

public struct JustSessionDefaults {
    public var JSONReadingOptions = NSJSONReadingOptions(rawValue: 0)
    public var JSONWritingOptions = NSJSONWritingOptions(rawValue: 0)
    public var headers:[String:String] = [:]
    public var multipartBoundary = "Ju5tH77P15Aw350m3"
    public var encoding = NSUTF8StringEncoding
}


public struct HTTPProgress {
    public enum Type {
        case Upload
        case Download
    }
    
    public let type:Type
    public let bytesProcessed:Int64
    public let bytesExpectedToProcess:Int64
    public var percent: Float {
        return Float(bytesProcessed) / Float(bytesExpectedToProcess)
    }
}

let errorDomain = "net.justhttp.Just"

public class Just: NSObject, NSURLSessionDelegate {
    
    class var shared: Just {
        struct Singleton {
            static let instance = Just()
        }
        return Singleton.instance
    }
    
    public init(session:NSURLSession? = nil, defaults:JustSessionDefaults? = nil) {
        super.init()
        if let initialSession = session {
            self.session = initialSession
        } else {
            self.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate:self, delegateQueue:nil)
        }
        if let initialDefaults = defaults {
            self.defaults = initialDefaults
        } else {
            self.defaults = JustSessionDefaults()
        }
    }
    
    var taskConfigs:[TaskID:TaskConfiguration]=[:]
    var defaults:JustSessionDefaults!
    var session: NSURLSession!
    var invalidURLError = NSError(
        domain: errorDomain,
        code: 0,
        userInfo: [NSLocalizedDescriptionKey:"[Just] URL is invalid"]
    )
    
    var syncResultAccessError = NSError(
        domain: errorDomain,
        code: 1,
        userInfo: [NSLocalizedDescriptionKey:"[Just] You are accessing asynchronous result synchronously."]
    )
    
    func queryComponents(key: String, _ value: AnyObject) -> [(String, String)] {
        var components: [(String, String)] = []
        if let dictionary = value as? [String: AnyObject] {
            for (nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)", value)
            }
        } else {
            components.extend([(percentEncodeString(key), percentEncodeString("\(value)"))])
        }
        
        return components
    }
    
    func query(parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []
        for key in Array(parameters.keys).sort(<) {
            let value: AnyObject! = parameters[key]
            components += self.queryComponents(key, value)
        }
        
        return "&".join(components.map{"\($0)=\($1)"} as [String])
    }
    
    func percentEncodeString(originalObject: AnyObject) -> String {
        if originalObject is NSNull {
            return "null"
        } else {
            guard let originalString = originalObject as? String else {
                return "null"
            }
            
            let legalURLCharactersToBeEscaped = NSCharacterSet(charactersInString: ":&=;+!@#$()',*").invertedSet
            
            guard let escaped = originalString.stringByAddingPercentEncodingWithAllowedCharacters( legalURLCharactersToBeEscaped ) else {
                return "null"
            }
            
            return escaped
        }
    }
    
    
    func makeTask(request:NSURLRequest, configuration: TaskConfiguration) -> NSURLSessionDataTask? {
        if let task = session.dataTaskWithRequest(request) {
            taskConfigs[task.taskIdentifier] = configuration
            return task
        }
        return nil
    }
    
    func synthesizeMultipartBody(data:[String:AnyObject], files:[String:HTTPFile]) -> NSData? {
        let body = NSMutableData()
        let boundary = "--\(self.defaults.multipartBoundary)\r\n".dataUsingEncoding(defaults.encoding)!
        for (k,v) in data {
            let valueToSend:AnyObject = v is NSNull ? "null" : v
            body.appendData(boundary)
            body.appendData("Content-Disposition: form-data; name=\"\(k)\"\r\n\r\n".dataUsingEncoding(defaults.encoding)!)
            body.appendData("\(valueToSend)\r\n".dataUsingEncoding(defaults.encoding)!)
        }
        
        for (k,v) in files {
            body.appendData(boundary)
            var partContent: NSData? = nil
            var partFilename:String? = nil
            var partMimetype:String? = nil
            switch v {
            case let .URL(URL, mimetype):
                if let component = URL.lastPathComponent {
                    partFilename = component
                }
                if let URLContent = NSData(contentsOfURL: URL) {
                    partContent = URLContent
                }
                partMimetype = mimetype
            case let .Text(filename, text, mimetype):
                partFilename = filename
                if let textData = text.dataUsingEncoding(defaults.encoding) {
                    partContent = textData
                }
                partMimetype = mimetype
            case let .Data(filename, data, mimetype):
                partFilename = filename
                partContent = data
                partMimetype = mimetype
            }
            if let content = partContent, let filename = partFilename {
                body.appendData(NSData(data: "Content-Disposition: form-data; name=\"\(k)\"; filename=\"\(filename)\"\r\n".dataUsingEncoding(defaults.encoding)!))
                if let type = partMimetype {
                    body.appendData("Content-Type: \(type)\r\n\r\n".dataUsingEncoding(defaults.encoding)!)
                } else {
                    body.appendData("\r\n".dataUsingEncoding(defaults.encoding)!)
                }
                body.appendData(content)
                body.appendData("\r\n".dataUsingEncoding(defaults.encoding)!)
            }
        }
        if body.length > 0 {
            body.appendData("--\(self.defaults.multipartBoundary)--\r\n".dataUsingEncoding(defaults.encoding)!)
        }
        return body
    }
    
    func synthesizeRequest(
        method:HTTPMethod,
        URLString:String,
        params:[String:AnyObject],
        data:[String:AnyObject],
        json:[String:AnyObject]?,
        headers:CaseInsensitiveDictionary<String,String>,
        files:[String:HTTPFile],
        timeout:Double?,
        requestBody:NSData?,
        URLQuery:String?
        ) -> NSURLRequest? {
            if let urlComponent = NSURLComponents(string: URLString) {
                let queryString = query(params)
                
                if queryString.characters.count > 0 {
                    urlComponent.percentEncodedQuery = queryString
                }
                
                var finalHeaders = headers
                var contentType:String? = nil
                var body:NSData?
                
                if let requestData = requestBody {
                    body = requestData
                } else if files.count > 0 {
                    body = synthesizeMultipartBody(data, files:files)
                    contentType = "multipart/form-data; boundary=\(self.defaults.multipartBoundary)"
                } else {
                    if let requestJSON = json {
                        contentType = "application/json"
                        do {
                            body = try NSJSONSerialization.dataWithJSONObject(requestJSON, options: defaults.JSONWritingOptions)
                        } catch _ {
                            body = nil
                        }
                    } else {
                        if data.count > 0 {
                            if headers["content-type"]?.lowercaseString == "application/json" { // assume user wants JSON if she is using this header
                                do {
                                    body = try NSJSONSerialization.dataWithJSONObject(data, options: defaults.JSONWritingOptions)
                                } catch _ {
                                    body = nil
                                }
                            } else {
                                contentType = "application/x-www-form-urlencoded"
                                body = query(data).dataUsingEncoding(defaults.encoding)
                            }
                        }
                    }
                }
                
                if let contentTypeValue = contentType {
                    finalHeaders["Content-Type"] = contentTypeValue
                }
                
                if let URL = urlComponent.URL {
                    let request = NSMutableURLRequest(URL: URL)
                    request.cachePolicy = .ReloadIgnoringLocalCacheData
                    request.HTTPBody = body
                    request.HTTPMethod = method.rawValue
                    if let requestTimeout = timeout {
                        request.timeoutInterval = requestTimeout
                    }
                    
                    for (k,v) in defaults.headers {
                        request.addValue(v, forHTTPHeaderField: k)
                    }
                    
                    for (k,v) in finalHeaders {
                        request.addValue(v, forHTTPHeaderField: k)
                    }
                    return request
                }
                
            }
            return nil
    }
    
    func request(
        method:HTTPMethod,
        URLString:String,
        params:[String:AnyObject],
        data:[String:AnyObject],
        json:[String:AnyObject]?,
        headers:[String:String],
        files:[String:HTTPFile],
        auth:Credentials?,
        cookies: [String:String],
        redirects:Bool,
        timeout:Double?,
        URLQuery:String?,
        requestBody:NSData?,
        asyncProgressHandler:TaskProgressHandler?,
        asyncCompletionHandler:((HTTPResult!) -> Void)?) -> HTTPResult {
            
            let isSync = asyncCompletionHandler == nil
            let semaphore = dispatch_semaphore_create(0)
            var requestResult:HTTPResult = HTTPResult(data: nil, response: nil, error: syncResultAccessError, request: nil)
            
            let caseInsensitiveHeaders = CaseInsensitiveDictionary<String,String>(dictionary:headers)
            if let request = synthesizeRequest(
                method,
                URLString: URLString,
                params: params,
                data: data,
                json: json,
                headers: caseInsensitiveHeaders,
                files: files,
                timeout:timeout,
                requestBody:requestBody,
                URLQuery: URLQuery
                ) {
                    addCookies(request.URL!, newCookies: cookies)
                    let config = TaskConfiguration(
                        credential:auth,
                        redirects:redirects,
                        originalRequest:request,
                        data:NSMutableData(),
                        progressHandler: asyncProgressHandler
                        ) { (result) in
                            if let handler = asyncCompletionHandler {
                                handler(result)
                            }
                            if isSync {
                                requestResult = result
                                dispatch_semaphore_signal(semaphore)
                            }
                            
                    }
                    if let task = makeTask(request, configuration:config) {
                        task.resume()
                    }
                    if isSync {
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                        return requestResult
                    }
            } else {
                let erronousResult = HTTPResult(data: nil, response: nil, error: invalidURLError, request: nil)
                if let handler = asyncCompletionHandler {
                    handler(erronousResult)
                } else {
                    return erronousResult
                }
            }
            return requestResult
            
    }
    
    func addCookies(URL:NSURL, newCookies:[String:String]) {
        for (k,v) in newCookies {
            if let cookie = NSHTTPCookie(properties: [
                NSHTTPCookieName: k,
                NSHTTPCookieValue: v,
                NSHTTPCookieOriginURL: URL,
                NSHTTPCookiePath: "/"
                ]) {
                    session.configuration.HTTPCookieStorage?.setCookie(cookie)
            }
        }
    }
}


extension Just: NSURLSessionTaskDelegate, NSURLSessionDataDelegate {
    public func URLSession(
        session: NSURLSession,
        task: NSURLSessionTask,
        didReceiveChallenge challenge: NSURLAuthenticationChallenge,
        completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void
        ) {
            var endCredential:NSURLCredential? = nil
            
            if let credential = taskConfigs[task.taskIdentifier]?.credential {
                if !(challenge.previousFailureCount > 0) {
                    endCredential = NSURLCredential(user: credential.0, password: credential.1, persistence: .ForSession)
                }
            }
            
            completionHandler(.UseCredential, endCredential)
    }
    
    public func URLSession(
        session: NSURLSession,
        task: NSURLSessionTask,
        willPerformHTTPRedirection response: NSHTTPURLResponse,
        newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void
        ) {
            if let allowRedirects = taskConfigs[task.taskIdentifier]?.redirects {
                if !allowRedirects {
                    completionHandler(nil)
                    return
                }
                completionHandler(request)
            } else {
                completionHandler(request)
            }
    }
    
    public func URLSession(
        session: NSURLSession,
        task: NSURLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
        ) {
            if let handler = taskConfigs[task.taskIdentifier]?.progressHandler {
                handler(
                    HTTPProgress(
                        type: .Upload,
                        bytesProcessed: totalBytesSent,
                        bytesExpectedToProcess: totalBytesExpectedToSend
                    )
                )
            }
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if let handler = taskConfigs[dataTask.taskIdentifier]?.progressHandler {
            handler(
                HTTPProgress(
                    type: .Download,
                    bytesProcessed: dataTask.countOfBytesReceived,
                    bytesExpectedToProcess: dataTask.countOfBytesExpectedToReceive
                )
            )
        }
        if taskConfigs[dataTask.taskIdentifier]?.data != nil {
            taskConfigs[dataTask.taskIdentifier]?.data.appendData(data)
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let config = taskConfigs[task.taskIdentifier], let handler = config.completionHandler {
            let result = HTTPResult(
                data: config.data,
                response: task.response,
                error: error,
                request: config.originalRequest ?? task.originalRequest
            )
            result.JSONReadingOptions = self.defaults.JSONReadingOptions
            result.encoding = self.defaults.encoding
            handler(result)
        }
        taskConfigs.removeValueForKey(task.taskIdentifier)
    }
}



