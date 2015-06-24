//
//  SAConnect.swift
//  SaguaroConnect
//
//  Created by Darryl West on 6/23/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import Foundation

public struct HTTPRequest {
    let url:String
    let params:[String:AnyObject]
    let data:[String:AnyObject]
    let json:[String:AnyObject]?
    let headers:[String:String]
    let files:[String:HTTPFile]
    let auth:(String,String)?
    let cookies:[String:String]
    let allowRedirects:Bool
    let timeout:Double?
    let query:String?
    let requestBody:NSData?
    let asyncProgressHandler:((HTTPProgress!) -> Void)?
    let asyncCompletionHandler:((HTTPResult!) -> Void)?
    
    public init(url:String, params:[String:AnyObject] = [:], data:[String:AnyObject] = [:], json:[String:AnyObject]? = nil, headers:[String:String] = [:], files:[String:HTTPFile] = [:], auth:(String,String)? = nil, cookies:[String:String] = [:], allowRedirects:Bool = true, timeout:Double? = nil, query:String? = nil, requestBody:NSData? = nil, asyncProgressHandler:((HTTPProgress!) -> Void)? = nil, asyncCompletionHandler:((HTTPResult!) -> Void)? = nil) {
        self.url = url
        self.params = params
        self.data = data
        self.json = json
        self.headers = headers
        self.files = files
        self.auth = auth
        self.cookies = cookies
        self.allowRedirects = allowRedirects
        self.timeout = timeout
        self.query = query
        self.requestBody = requestBody
        self.asyncProgressHandler = asyncProgressHandler
        self.asyncCompletionHandler  = asyncCompletionHandler
    }
}

public protocol HTTPRemote {
    func get(request:HTTPRequest) -> HTTPResult
    func post(request:HTTPRequest) -> HTTPResult
    func put(request:HTTPRequest) -> HTTPResult
    func head(request:HTTPRequest) -> HTTPResult
    func delete(request:HTTPRequest) -> HTTPResult
    func options(request:HTTPRequest) -> HTTPResult
    func patch(request:HTTPRequest) -> HTTPResult
}

public struct SARemote: HTTPRemote {
    let http:Just = Just()
    
    public func get(request:HTTPRequest) -> HTTPResult {
        return sendRequest( HTTPMethod.GET, request: request)
    }
    
    public func post(request:HTTPRequest) -> HTTPResult {
        return sendRequest( HTTPMethod.POST, request: request)
    }
    
    public func put(request:HTTPRequest) -> HTTPResult {
        return sendRequest( HTTPMethod.PUT, request: request)
    }
    
    public func head(request:HTTPRequest) -> HTTPResult {
        return sendRequest( HTTPMethod.HEAD, request: request)
    }
    
    public func delete(request:HTTPRequest) -> HTTPResult {
        return sendRequest( HTTPMethod.DELETE, request: request)
    }
    
    public func options(request:HTTPRequest) -> HTTPResult {
        return sendRequest( HTTPMethod.OPTIONS, request: request)
    }
    
    public func patch(request:HTTPRequest) -> HTTPResult {
        return sendRequest( HTTPMethod.PATCH, request: request)
    }
    
    func sendRequest(method:HTTPMethod, request:HTTPRequest) -> HTTPResult {
        return http.request(method,
            URLString:request.url,
            params:request.params,
            data:request.data,
            json:request.json,
            headers:request.headers,
            files:request.files,
            auth:request.auth,
            cookies:request.cookies,
            redirects:request.allowRedirects,
            timeout:request.timeout,
            URLQuery:request.query,
            requestBody:request.requestBody,
            asyncProgressHandler:request.asyncProgressHandler,
            asyncCompletionHandler:request.asyncCompletionHandler)
    }
    
    init() {
        
    }
}

