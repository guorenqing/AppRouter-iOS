//
//  RouteResult.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import Foundation

/// 路由结果封装类
public struct RouteResult {
    public let isSuccess: Bool
    public let message: String?
    public let data: Any?
    
    public init(isSuccess: Bool, message: String? = nil, data: Any? = nil) {
        self.isSuccess = isSuccess
        self.message = message
        self.data = data
    }
    
    /// 成功结果
    public static func success(data: Any? = nil) -> RouteResult {
        return RouteResult(isSuccess: true, data: data)
    }
    
    /// 失败结果
    public static func failure(_ message: String) -> RouteResult {
        return RouteResult(isSuccess: false, message: message)
    }
}

/// 支持返回数据的页面协议
public protocol RouteResultProvider {
    var routeResult: Any? { get set }
}
