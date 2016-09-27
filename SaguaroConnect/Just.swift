//
//  Just.swift
//  Just
//
//  Created by Daniel Duan on 4/21/15.
//  Copyright (c) 2015 JustHTTP. All rights reserved.
//

import Foundation

public enum HTTPFile {
    case url(Foundation.URL,String?) // URL to a file, mimetype
    case data(String,Foundation.Data,String?) // filename, data, mimetype
    case text(String,String,String?) // filename, text, mimetype
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
    let originalRequest: URLRequest?
    var data: NSMutableData
    let progressHandler: TaskProgressHandler?
    let completionHandler: TaskCompletionHandler?
}

public struct JustSessionDefaults {
    public var JSONReadingOptions = JSONSerialization.ReadingOptions(rawValue: 0)
    public var JSONWritingOptions = JSONSerialization.WritingOptions(rawValue: 0)
    public var headers:[String:String] = [:]
    public var multipartBoundary = "Ju5tH77P15Aw350m3"
    public var encoding = String.Encoding.utf8
}


public struct HTTPProgress {
    public enum HttpProgressType {
        case upload
        case download
    }
    
    public let type:HttpProgressType
    public let bytesProcessed:Int64
    public let bytesExpectedToProcess:Int64
    public var percent: Float {
        return Float(bytesProcessed) / Float(bytesExpectedToProcess)
    }
}

let errorDomain = "net.justhttp.Just"

open class Just: NSObject, URLSessionDelegate {
    
    class var shared: Just {
        struct Singleton {
            static let instance = Just()
        }
        return Singleton.instance
    }
    
    public init(session:Foundation.URLSession? = nil, defaults:JustSessionDefaults? = nil) {
        super.init()
        if let initialSession = session {
            self.session = initialSession
        } else {
            self.session = Foundation.URLSession(configuration: URLSessionConfiguration.default, delegate:self, delegateQueue:nil)
        }
        if let initialDefaults = defaults {
            self.defaults = initialDefaults
        } else {
            self.defaults = JustSessionDefaults()
        }
    }
    
    var taskConfigs:[TaskID:TaskConfiguration]=[:]
    var defaults:JustSessionDefaults!
    var session: Foundation.URLSession!
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
    
    func queryComponents(_ key: String, _ value: AnyObject) -> [(String, String)] {
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
			let tuple = (percentEncodeString(key), percentEncodeString("\(value)"))
            components.append(tuple)
        }
        
        return components
    }
    
    func query(_ parameters: [String: AnyObject]) -> String {
        var components = [String]()
        for key in Array(parameters.keys).sorted(by: <) {
            let value: AnyObject! = parameters[key]
            components.append("\(key)=\(value)")
        }

        return components.joined(separator: "&")
    }
    
    func percentEncodeString(_ originalObject: Any) -> String {
        if originalObject is NSNull {
            return "null"
        } else {
            guard let originalString = originalObject as? String else {
                return "null"
            }
            
            let legalURLCharactersToBeEscaped = CharacterSet(charactersIn: ":&=;+!@#$()',*").inverted
            
            guard let escaped = originalString.addingPercentEncoding( withAllowedCharacters: legalURLCharactersToBeEscaped ) else {
                return "null"
            }
            
            return escaped
        }
    }
    
    
    func makeTask(_ request:URLRequest, configuration: TaskConfiguration) -> URLSessionDataTask? {
        let task:URLSessionDataTask = session.dataTask(with: request)
		taskConfigs[task.taskIdentifier] = configuration
        return task
    }
    
    func synthesizeMultipartBody(_ data:[String:AnyObject], files:[String:HTTPFile]) -> Data? {
        let body = NSMutableData()
        let boundary = "--\(self.defaults.multipartBoundary)\r\n".data(using: defaults.encoding)!
        for (k,v) in data {
            let valueToSend:AnyObject = v is NSNull ? "null" as AnyObject : v
            body.append(boundary)
            body.append("Content-Disposition: form-data; name=\"\(k)\"\r\n\r\n".data(using: defaults.encoding)!)
            body.append("\(valueToSend)\r\n".data(using: defaults.encoding)!)
        }
        
        for (k,v) in files {
            body.append(boundary)
            var partContent: Data? = nil
            var partFilename:String? = nil
            var partMimetype:String? = nil
            switch v {
            case let .url(url, mimetype):
				partFilename = url.lastPathComponent
                if let URLContent = try? Data(contentsOf: url) {
                    partContent = URLContent
                }
                partMimetype = mimetype
            case let .text(filename, text, mimetype):
                partFilename = filename
                if let textData = text.data(using: defaults.encoding) {
                    partContent = textData
                }
                partMimetype = mimetype
            case let .data(filename, data, mimetype):
                partFilename = filename
                partContent = data
                partMimetype = mimetype
            }
            if let content = partContent, let filename = partFilename {
                body.append(NSData(data: "Content-Disposition: form-data; name=\"\(k)\"; filename=\"\(filename)\"\r\n".data(using: defaults.encoding)!) as Data)
                if let type = partMimetype {
                    body.append("Content-Type: \(type)\r\n\r\n".data(using: defaults.encoding)!)
                } else {
                    body.append("\r\n".data(using: defaults.encoding)!)
                }
                body.append(content)
                body.append("\r\n".data(using: defaults.encoding)!)
            }
        }
        if body.length > 0 {
            body.append("--\(self.defaults.multipartBoundary)--\r\n".data(using: defaults.encoding)!)
        }
        return body as Data
    }
    
    func synthesizeRequest(
        _ method:HTTPMethod,
        URLString:String,
        params:[String:AnyObject],
        data:[String:AnyObject],
        json:[String:AnyObject]?,
        headers:CaseInsensitiveDictionary<String,String>,
        files:[String:HTTPFile],
        timeout:Double?,
        requestBody:Data?,
        URLQuery:String?
        ) -> URLRequest? {
            if var urlComponent = URLComponents(string: URLString) {
                let queryString = query(params)
                
                if queryString.characters.count > 0 {
                    urlComponent.percentEncodedQuery = queryString
                }
                
                var finalHeaders = headers
                var contentType:String? = nil
                var body:Data?
                
                if let requestData = requestBody {
                    body = requestData
                } else if files.count > 0 {
                    body = synthesizeMultipartBody(data, files:files)
                    contentType = "multipart/form-data; boundary=\(self.defaults.multipartBoundary)"
                } else {
                    if let requestJSON = json {
                        contentType = "application/json"
                        do {
                            body = try JSONSerialization.data(withJSONObject: requestJSON, options: defaults.JSONWritingOptions)
                        } catch _ {
                            body = nil
                        }
                    } else {
                        if data.count > 0 {
                            if headers["content-type"]?.lowercased() == "application/json" { // assume user wants JSON if she is using this header
                                do {
                                    body = try JSONSerialization.data(withJSONObject: data, options: defaults.JSONWritingOptions)
                                } catch _ {
                                    body = nil
                                }
                            } else {
                                contentType = "application/x-www-form-urlencoded"
                                body = query(data).data(using: defaults.encoding)
                            }
                        }
                    }
                }
                
                if let contentTypeValue = contentType {
                    finalHeaders["Content-Type"] = contentTypeValue
                }
                
                if let URL = urlComponent.url {
                    let request = NSMutableURLRequest(url: URL)
                    request.cachePolicy = .reloadIgnoringLocalCacheData
                    request.httpBody = body
                    request.httpMethod = method.rawValue
                    if let requestTimeout = timeout {
                        request.timeoutInterval = requestTimeout
                    }
                    
                    for (k,v) in defaults.headers {
                        request.addValue(v, forHTTPHeaderField: k)
                    }
                    
                    for (k,v) in finalHeaders {
                        request.addValue(v, forHTTPHeaderField: k)
                    }
                    return request as URLRequest
                }
                
            }
            return nil
    }
    
    func request(
        _ method:HTTPMethod,
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
        requestBody:Data?,
        asyncProgressHandler:TaskProgressHandler?,
        asyncCompletionHandler:((HTTPResult?) -> Void)?) -> HTTPResult {
            
            let isSync = asyncCompletionHandler == nil
            let semaphore = DispatchSemaphore(value: 0)
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
                    addCookies(request.url!, newCookies: cookies)
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
                                semaphore.signal()
                            }
                            
                    }
                    if let task = makeTask(request, configuration:config) {
                        task.resume()
                    }
                    if isSync {
                        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
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
    
    func addCookies(_ URL:Foundation.URL, newCookies:[String:String]) {
        for (k,v) in newCookies {
            if let cookie = HTTPCookie(properties: [
                HTTPCookiePropertyKey.name: k,
                HTTPCookiePropertyKey.value: v,
                HTTPCookiePropertyKey.originURL: URL,
                HTTPCookiePropertyKey.path: "/"
                ]) {
                    session.configuration.httpCookieStorage?.setCookie(cookie)
            }
        }
    }
}


extension Just: URLSessionTaskDelegate, URLSessionDataDelegate {
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            var endCredential:URLCredential? = nil
            
            if let credential = taskConfigs[task.taskIdentifier]?.credential {
                if !(challenge.previousFailureCount > 0) {
                    endCredential = URLCredential(user: credential.0, password: credential.1, persistence: .forSession)
                }
            }
            
            completionHandler(.useCredential, endCredential)
    }
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void
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
    
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
        ) {
            if let handler = taskConfigs[task.taskIdentifier]?.progressHandler {
                handler(
                    HTTPProgress(
                        type: .upload,
                        bytesProcessed: totalBytesSent,
                        bytesExpectedToProcess: totalBytesExpectedToSend
                    )
                )
            }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let handler = taskConfigs[dataTask.taskIdentifier]?.progressHandler {
            handler(
                HTTPProgress(
                    type: .download,
                    bytesProcessed: dataTask.countOfBytesReceived,
                    bytesExpectedToProcess: dataTask.countOfBytesExpectedToReceive
                )
            )
        }
        if taskConfigs[dataTask.taskIdentifier]?.data != nil {
            taskConfigs[dataTask.taskIdentifier]?.data.append(data)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let config = taskConfigs[task.taskIdentifier], let handler = config.completionHandler {
            let result = HTTPResult(
                data: config.data as Data,
                response: task.response,
                error: error as NSError?,
                request: config.originalRequest ?? task.originalRequest
            )
            result.JSONReadingOptions = self.defaults.JSONReadingOptions
            result.encoding = self.defaults.encoding
            handler(result)
        }
        taskConfigs.removeValue(forKey: task.taskIdentifier)
    }
}



