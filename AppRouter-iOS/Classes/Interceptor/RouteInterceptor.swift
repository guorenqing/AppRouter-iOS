//
//  RouteInterceptor.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import Foundation

/// 拦截器结果
public enum InterceptorResult {
    case `continue`                    // 继续执行原路由
    case redirect(RouteConfig)         // 重定向到新路由，成功后继续原路由
    case replace(RouteConfig)          // 替换原路由（不执行原路由）
    case reject(Error)                 // 拒绝并终止
}


/// 路由拦截器协议
public protocol RouteInterceptor: AnyObject {
    /// 拦截路由
    func intercept(path: String, params: [String: Any]?) async -> InterceptorResult
}
