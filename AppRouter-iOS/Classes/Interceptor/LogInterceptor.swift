//
//  LogInterceptor.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import Foundation

/// 日志拦截器
public class LogInterceptor: RouteInterceptor {
    public init() {}
    
    public func intercept(path: String, params: [String: Any]?) async -> InterceptorResult {
        print("""
        🚀 路由跳转日志:
          路径: \(path)
          参数: \(params ?? [:])
          时间: \(Date())
        """)
        return InterceptorResult.continue
    }
}
