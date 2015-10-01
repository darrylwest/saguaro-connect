//
//  SARemoteService.swift
//  SaguaroConnect
//
//  Created by darryl west on 7/20/15.
//  Copyright © 2015 darryl.west@raincitysoftware.com. All rights reserved.
//

import Foundation
import SaguaroJSON

public enum SAResponseCallback<T1: Any, T2: ErrorType> {
    case Ok(T1)
    case Fail(T2)
}

public protocol SARemoteRequestModel {
    var id:String { get }
    var requestTime:NSTimeInterval { get }
}

public protocol SAServiceErrorType {
    var code:Int { get }
    var message:String { get }
}

public protocol SARemoteServiceType {
    var serviceName:String { get }
}

public extension SARemoteServiceType {
    public func createError(errorType: SAServiceErrorType, request:SARemoteRequestModel, userInfo:[String:AnyObject]? = [:]) -> NSError {
        var info = userInfo!

        info[ "requestId" ] = request.id
        info[ "requestTime" ] = request.requestTime
        info[ "message" ] = errorType.message

        return NSError(domain: serviceName, code: errorType.code, userInfo: info)
    }
}

public struct SAErrorType: SAServiceErrorType {
    public let code:Int
    public let message:String

    public init(code:Int, message:String) {
        self.code = code
        self.message = message
    }
}

public class SARemoteRequest: SARemoteRequestModel {
    static let jnparser = JNParser()

    final public let id:String
    final public let requestTime:NSTimeInterval

    public init() {
        self.id = NSUUID().UUIDString.lowercaseString
        self.requestTime = NSDate().timeIntervalSince1970
    }
}

/// create with optional params; any object includes NSDate which gets set to JSON string (ISO8601)
public class SAQueryRequest: SARemoteRequest {
    public let params:[String:AnyObject]

    public init(params:[String:AnyObject]? = [String:AnyObject]()) {
        var p = [String:AnyObject]()

        for (key, value) in params! {
            if let dt = value as? NSDate {
                p[ key ] = SARemoteRequest.jnparser.stringFromDate( dt )
            } else {
                p[ key ] = value
            }
        }

        self.params = p
        super.init()
    }
}

class SARemoteService: SARemoteServiceType {
    let serviceName:String

    init(serviceName:String) {
        self.serviceName = serviceName
    }
}