//
//  RouteError.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import Foundation

/// 路由错误定义
public enum RouteError: Error, LocalizedError {
    case routeNotFound(String)
    case missingRequiredParameter(String)
    case handlerNotImplemented
    case concurrentCallInProgress
    case redirectTooManyTimes
    case navigationControllerNotSet
    case invalidURL(String)
    case cacheError(String)
    case timeoutError(TimeInterval)
    case validationFailed(String)
    case inValidHandlerInSyncContext(String)
    
    public var errorDescription: String? {
        switch self {
        case .routeNotFound(let path):
            return "未找到路由: \(path)"
        case .missingRequiredParameter(let param):
            return "缺少必要参数: \(param)"
        case .handlerNotImplemented:
            return "处理器未实现"
        case .concurrentCallInProgress:
            return "相同功能调用正在进行中"
        case .redirectTooManyTimes:
            return "重定向次数过多"
        case .navigationControllerNotSet:
            return "导航控制器未设置"
        case .invalidURL(let url):
            return "非法的URL: \(url)"
        case .cacheError(let message):
            return "缓存错误: \(message)"
        case .timeoutError(let timeout):
            return "调用超时 (\(timeout)秒)"
        case .validationFailed(let message):
            return "参数验证失败: \(message)"
        case .inValidHandlerInSyncContext(let path):
            return "不正确的handler类型在同步调用上下文: \(path)"
        }
    }
    
    public var code: Int {
        switch self {
        case .routeNotFound: return 404
        case .missingRequiredParameter: return 400
        case .handlerNotImplemented: return 501
        case .concurrentCallInProgress: return 429
        case .redirectTooManyTimes: return 508
        case .navigationControllerNotSet: return 500
        case .invalidURL: return 400
        case .cacheError: return 500
        case .timeoutError: return 408
        case .validationFailed: return 422
        case .inValidHandlerInSyncContext: return 426
            
        }
    }
}
