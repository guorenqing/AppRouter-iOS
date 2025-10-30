//
//  RouteCallContext.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import Foundation
import CommonCrypto

/// 路由调用标识符
public struct RouteCallID: Hashable, Equatable, CustomStringConvertible {
    public let id: String
    public let timestamp: TimeInterval
    
    public init() {
        self.id = UUID().uuidString
        self.timestamp = Date().timeIntervalSince1970
    }
    
    public static func == (lhs: RouteCallID, rhs: RouteCallID) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public var description: String {
        return "RouteCallID(\(id.prefix(8))...)"
    }
}

/// 路由调用上下文
public struct RouteCallContext: CustomStringConvertible {
    public let id: RouteCallID
    public let path: String
    public let params: [String: Any]
    public let navigationType: NavigationType
    public let timestamp: TimeInterval
    public let routeConfig: RouteConfig
    
    // MARK: - 初始化方法
    
    public init(
        path: String,
        params: [String: Any],
        navigationType: NavigationType,
        routeConfig: RouteConfig
    ) {
        self.id = RouteCallID()
        self.path = path
        self.params = params
        self.navigationType = navigationType
        self.timestamp = Date().timeIntervalSince1970
        self.routeConfig = routeConfig
    }
    
    public init(
        from context: RouteCallContext,
        params: [String: Any],
        routeConfig: RouteConfig? = nil
    ) {
        self.id = context.id
        self.path = context.path
        self.params = params
        self.navigationType = context.navigationType
        self.timestamp = context.timestamp
        self.routeConfig = routeConfig ?? context.routeConfig
    }
    
    public init(
        forRedirectFrom context: RouteCallContext,
        redirectConfig: RouteConfig,
        mergedParams: [String: Any]
    ) {
        self.id = context.id
        self.path = redirectConfig.path
        self.params = mergedParams
        self.navigationType = redirectConfig.defaultNavigationType ?? context.navigationType
        self.timestamp = context.timestamp
        self.routeConfig = redirectConfig
    }
    
    // MARK: - 计算属性
    
    public var isPageRoute: Bool {
        return routeConfig.type == .page
    }
    
    public var isFunctionCall: Bool {
        return !isPageRoute
    }
    
    public var isSyncFunction: Bool {
        return routeConfig.type == .actionSync
    }
    
    public var isAsyncFunction: Bool {
        return routeConfig.type == .actionAsync
    }
    
    public var routeType: RouteType {
        return routeConfig.type
    }
    
    public var enableConcurrentControl: Bool {
        return routeConfig.enableConcurrentControl
    }
    
    public var enableCaching: Bool {
        return routeConfig.enableCaching
    }
    
    public var cacheTimeout: TimeInterval {
        return routeConfig.cacheTimeout
    }
    
    public var testTimeout: TimeInterval {
        return routeConfig.testTimeout
    }
    
    public var shouldSkipAutomatedTest: Bool {
        return routeConfig.skipAutomatedTest
    }
    
    public var description: String {
        return "RouteCallContext(path: \(path), type: \(routeType), navigation: \(navigationType))"
    }
}

// MARK: - 便捷方法扩展
extension RouteCallContext {
    
    public func getMergedParams() -> [String: Any] {
        var mergedParams: [String: Any] = [:]
        
        if let defaultParams = routeConfig.defaultParamsBuilder?() {
            mergedParams.merge(defaultParams) { current, _ in current }
        }
        
        mergedParams.merge(params) { _, new in new }
        
        return mergedParams
    }
    
    public func getCallKey() -> String {
        let mergedParams = getMergedParams()
        let paramsString = mergedParams.sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        return "\(path)?\(paramsString)".sha256()
    }
    
    public func getTestParams() -> [String: Any] {
        return routeConfig.getTestParams()
    }
    
    public func validateParams() throws {
        if isPageRoute {
            switch path {
            case "/detail":
                if params["id"] == nil {
                    throw RouteError.missingRequiredParameter("id")
                }
            case "/webview":
                guard params["url"] != nil else {
                    throw RouteError.missingRequiredParameter("url")
                }
            default:
                break
            }
        }
    }
    
    public var debugInfo: [String: Any] {
        return [
            "callID": id.id,
            "path": path,
            "params": params,
            "navigationType": navigationType.description,
            "routeType": routeType.description,
            "timestamp": timestamp,
            "isPageRoute": isPageRoute,
            "enableConcurrentControl": enableConcurrentControl,
            "enableCaching": enableCaching,
            "mergedParams": getMergedParams()
        ]
    }
}

// MARK: - String MD5 扩展
extension String {
    
    func sha256() -> String {
        guard let data = self.data(using: .utf8) else { return "" }
        
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
