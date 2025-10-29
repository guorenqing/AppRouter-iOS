//
//  RouteConfig.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit

/// 路由处理器类型
public enum RouteHandler {
    /// 页面处理器 - 返回 UIViewController
    case page(([String: Any]) throws -> UIViewController)
    
    /// 同步功能处理器 - 同步返回结果
    case sync(([String: Any]) throws -> Any?)
    
    /// 异步功能处理器 - 异步返回结果
    case async(([String: Any]) async throws -> Any?)
    
    /// 获取处理器类型
    public var type: RouteType {
        switch self {
        case .page: return .page
        case .sync: return .actionSync
        case .async: return .actionAsync
        }
    }
    
    /// 检查是否是页面处理器
    public var isPageHandler: Bool {
        if case .page = self { return true }
        return false
    }
    
    /// 检查是否是异步处理器
    public var isAsyncHandler: Bool {
        if case .async = self { return true }
        return false
    }
    
    /// 统一的处理器调用方法
    public func callAsFunction(params: [String: Any]) async throws -> Any? {
        switch self {
        case .page(let handler):
            // 页面创建必须是同步的，在 MainActor 中执行
            return try await Task { @MainActor in
                return try handler(params)
            }.value
            
        case .sync(let handler):
            // 同步功能调用，直接执行
            return try handler(params)
            
        case .async(let handler):
            // 异步功能调用，await 执行
            return try await handler(params)
        }
    }
    
    /// 获取处理器描述
    public var description: String {
        switch self {
        case .page: return "PageHandler"
        case .sync: return "SyncHandler"
        case .async: return "AsyncHandler"
        }
    }
}

/// 路由配置项（使用枚举存储 Handler）
public class RouteConfig {
    // MARK: - 基本属性
    public let path: String
    public let handler: RouteHandler
    public let defaultParamsBuilder: (() -> [String: Any])?
    public let defaultNavigationType: NavigationType?
    
    // MARK: - 功能调用配置
    public let enableConcurrentControl: Bool
    public let enableCaching: Bool
    public let cacheTimeout: TimeInterval
    
    // MARK: - 自动化测试配置
    public let testParamsBuilder: (() -> [String: Any])?
    public let skipAutomatedTest: Bool
    public let testTimeout: TimeInterval
    
    // MARK: - 计算属性
    
    /// 路由类型
    public var type: RouteType {
        return handler.type
    }
    
    /// 检查是否是页面路由
    public var isPageRoute: Bool {
        return handler.isPageHandler
    }
    
    /// 检查是否是异步处理器
    public var isAsyncHandler: Bool {
        return handler.isAsyncHandler
    }
    
    /// 检查是否是同步处理器
    public var isSyncHandler: Bool {
        return type == .actionSync
    }
    
    // MARK: - 初始化方法
    
    /// 初始化页面路由
    public init(
        path: String,
        handler: @escaping ([String: Any]) throws -> UIViewController,
        defaultParamsBuilder: (() -> [String: Any])? = nil,
        defaultNavigationType: NavigationType? = nil,
        testParamsBuilder: (() -> [String: Any])? = nil,
        skipAutomatedTest: Bool = false,
        testTimeout: TimeInterval = 10.0,
        enableConcurrentControl: Bool = true,
        enableCaching: Bool = false,
        cacheTimeout: TimeInterval = 30.0
    ) {
        self.path = path
        self.handler = .page(handler)
        self.defaultParamsBuilder = defaultParamsBuilder
        self.defaultNavigationType = defaultNavigationType
        self.testParamsBuilder = testParamsBuilder
        self.skipAutomatedTest = skipAutomatedTest
        self.testTimeout = testTimeout
        self.enableConcurrentControl = enableConcurrentControl
        self.enableCaching = enableCaching
        self.cacheTimeout = cacheTimeout
    }
    
    /// 初始化同步功能路由
    public init(
        path: String,
        syncHandler: @escaping ([String: Any]) throws -> Any?,
        defaultParamsBuilder: (() -> [String: Any])? = nil,
        testParamsBuilder: (() -> [String: Any])? = nil,
        skipAutomatedTest: Bool = false,
        testTimeout: TimeInterval = 5.0,
        enableConcurrentControl: Bool = true,
        enableCaching: Bool = false,
        cacheTimeout: TimeInterval = 30.0
    ) {
        self.path = path
        self.handler = .sync(syncHandler)
        self.defaultParamsBuilder = defaultParamsBuilder
        self.defaultNavigationType = nil
        self.testParamsBuilder = testParamsBuilder
        self.skipAutomatedTest = skipAutomatedTest
        self.testTimeout = testTimeout
        self.enableConcurrentControl = enableConcurrentControl
        self.enableCaching = enableCaching
        self.cacheTimeout = cacheTimeout
    }
    
    /// 初始化异步功能路由
    public init(
        path: String,
        asyncHandler: @escaping ([String: Any]) async throws -> Any?,
        defaultParamsBuilder: (() -> [String: Any])? = nil,
        testParamsBuilder: (() -> [String: Any])? = nil,
        skipAutomatedTest: Bool = false,
        testTimeout: TimeInterval = 10.0,
        enableConcurrentControl: Bool = true,
        enableCaching: Bool = true, // 异步调用默认启用缓存
        cacheTimeout: TimeInterval = 30.0
    ) {
        self.path = path
        self.handler = .async(asyncHandler)
        self.defaultParamsBuilder = defaultParamsBuilder
        self.defaultNavigationType = nil
        self.testParamsBuilder = testParamsBuilder
        self.skipAutomatedTest = skipAutomatedTest
        self.testTimeout = testTimeout
        self.enableConcurrentControl = enableConcurrentControl
        self.enableCaching = enableCaching
        self.cacheTimeout = cacheTimeout
    }
    
    /// 使用 RouteHandler 直接初始化
    public init(
        path: String,
        handler: RouteHandler,
        defaultParamsBuilder: (() -> [String: Any])? = nil,
        defaultNavigationType: NavigationType? = nil,
        testParamsBuilder: (() -> [String: Any])? = nil,
        skipAutomatedTest: Bool = false,
        testTimeout: TimeInterval = 10.0,
        enableConcurrentControl: Bool = true,
        enableCaching: Bool = false,
        cacheTimeout: TimeInterval = 30.0
    ) {
        self.path = path
        self.handler = handler
        self.defaultParamsBuilder = defaultParamsBuilder
        
        // 根据 handler 类型设置默认导航类型
        if let navType = defaultNavigationType {
            self.defaultNavigationType = navType
        } else {
            self.defaultNavigationType = handler.isPageHandler ? .push : nil
        }
        
        self.testParamsBuilder = testParamsBuilder
        self.skipAutomatedTest = skipAutomatedTest
        self.testTimeout = testTimeout
        self.enableConcurrentControl = enableConcurrentControl
        self.enableCaching = enableCaching
        self.cacheTimeout = cacheTimeout
    }
    
    // MARK: - Handler 调用
    
    /// 统一的 handler 调用方法
    public func handler(params: [String: Any]) async throws -> Any? {
        return try await handler(params: params)
    }
    
    /// 便捷调用方法
    public func call(params: [String: Any]) async throws -> Any? {
        return try await handler(params: params)
    }
    
    // MARK: - 测试相关
    
    /// 获取测试参数（合并测试参数和默认参数）
    public func getTestParams() -> [String: Any] {
        var params: [String: Any] = [:]
        
        // 1. 先添加默认参数（如果有）
        if let defaultParams = defaultParamsBuilder?() {
            params.merge(defaultParams) { current, _ in current }
        }
        
        // 2. 添加测试参数（如果有），测试参数会覆盖默认参数
        if let testParams = testParamsBuilder?() {
            params.merge(testParams) { _, new in new }
        } else {
            // 3. 如果没有配置测试参数，使用通用测试参数
            let genericParams: [String: Any] = [
                "test": true,
                "source": "automated_test",
                "timestamp": Date().timeIntervalSince1970,
                "testId": UUID().uuidString
            ]
            params.merge(genericParams) { current, _ in current }
        }
        
        // 4. 根据路由类型添加类型特定的参数
        if isPageRoute {
            params["pageType"] = "test_page"
            params["navigationSource"] = "automated_test"
        } else {
            params["actionType"] = "test_action"
        }
        
        return params
    }
    
    /// 获取完整的参数合并逻辑（用于调试和日志）
    public func getParamMergeInfo() -> [String: Any] {
        let defaultParams = defaultParamsBuilder?() ?? [:]
        let testParams = testParamsBuilder?() ?? [:]
        let finalParams = getTestParams()
        
        return [
            "defaultParams": defaultParams,
            "testParams": testParams,
            "finalParams": finalParams,
            "hasDefaultParams": !defaultParams.isEmpty,
            "hasTestParams": !testParams.isEmpty,
            "usedGenericParams": testParamsBuilder == nil
        ]
    }
    
    // MARK: - 便捷属性
    
    /// 获取路由描述信息
    public var description: String {
        return "RouteConfig(path: \(path), type: \(type), handler: \(handler.description))"
    }
    
    /// 获取调试信息
    public var debugInfo: [String: Any] {
        return [
            "path": path,
            "type": type.description,
            "handlerType": handler.description,
            "isPageRoute": isPageRoute,
            "enableConcurrentControl": enableConcurrentControl,
            "enableCaching": enableCaching,
            "cacheTimeout": cacheTimeout,
            "skipAutomatedTest": skipAutomatedTest,
            "testTimeout": testTimeout,
            "hasDefaultParams": defaultParamsBuilder != nil,
            "hasTestParams": testParamsBuilder != nil,
            "paramMergeInfo": getParamMergeInfo()
        ]
    }
    
    // MARK: - 上下文创建
    
    /// 创建调用上下文
    public func createContext(
        params: [String: Any],
        navigationType: NavigationType? = nil
    ) -> RouteCallContext {
        let finalNavigationType: NavigationType
        if let navType = navigationType {
            finalNavigationType = navType
        } else if let defaultNavType = self.defaultNavigationType {
            finalNavigationType = defaultNavType
        } else {
            finalNavigationType = self.isPageRoute ? .push : .push
        }
        
        return RouteCallContext(
            path: self.path,
            params: params,
            navigationType: finalNavigationType,
            routeConfig: self
        )
    }
    
    // MARK: - 验证方法
    
    /// 验证路由配置是否有效
    public func validate() throws {
        // 检查路径格式
        guard !path.isEmpty else {
            throw RouteError.validationFailed("路由路径不能为空")
        }
        
        guard path.hasPrefix("/") else {
            throw RouteError.validationFailed("路由路径必须以 / 开头: \(path)")
        }
        
        // 检查超时设置
        guard testTimeout > 0 else {
            throw RouteError.validationFailed("测试超时时间必须大于0")
        }
        
        guard cacheTimeout >= 0 else {
            throw RouteError.validationFailed("缓存超时时间不能为负数")
        }
        
        // 检查导航类型是否与处理器类型匹配
        if let navType = defaultNavigationType, !isPageRoute {
            throw RouteError.validationFailed("功能路由不能设置导航类型")
        }
    }
    
    // MARK: - 便捷创建方法
    
    /// 快速创建测试页面路由
    public static func testPageRoute(
        path: String,
        handler: @escaping ([String: Any]) throws -> UIViewController,
        testParams: [String: Any]? = nil
    ) -> RouteConfig {
        return RouteConfig(
            path: path,
            handler: handler,
            testParamsBuilder: { testParams ?? [:] },
            skipAutomatedTest: false,
            testTimeout: 5.0
        )
    }
    
    /// 快速创建测试同步功能路由
    public static func testSyncRoute(
        path: String,
        handler: @escaping ([String: Any]) throws -> Any?,
        testParams: [String: Any]? = nil
    ) -> RouteConfig {
        return RouteConfig(
            path: path,
            syncHandler: handler,
            testParamsBuilder: { testParams ?? [:] },
            skipAutomatedTest: false,
            testTimeout: 3.0
        )
    }
    
    /// 快速创建测试异步功能路由
    public static func testAsyncRoute(
        path: String,
        handler: @escaping ([String: Any]) async throws -> Any?,
        testParams: [String: Any]? = nil
    ) -> RouteConfig {
        return RouteConfig(
            path: path,
            asyncHandler: handler,
            testParamsBuilder: { testParams ?? [:] },
            skipAutomatedTest: false,
            testTimeout: 8.0
        )
    }
    
    /// 使用 RouteHandler 创建路由
    public static func withHandler(
        path: String,
        handler: RouteHandler,
        defaultParams: [String: Any]? = nil,
        testParams: [String: Any]? = nil
    ) -> RouteConfig {
        return RouteConfig(
            path: path,
            handler: handler,
            defaultParamsBuilder: defaultParams.map { params in
                return { params }
            },
            testParamsBuilder: testParams.map { params in
                return { params }
            }
        )
    }
}

// MARK: - 便捷扩展
extension RouteConfig: CustomStringConvertible {
    // 已经在上面实现
}

extension RouteConfig: Equatable {
    public static func == (lhs: RouteConfig, rhs: RouteConfig) -> Bool {
        return lhs.path == rhs.path &&
               lhs.type == rhs.type &&
               lhs.handler.type == rhs.handler.type
    }
}

extension RouteConfig: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
        hasher.combine(type)
    }
}

// MARK: - RouteHandler 便捷扩展
extension RouteHandler: CustomStringConvertible {
    // 已经在上面实现
}

extension RouteHandler: Equatable {
    public static func == (lhs: RouteHandler, rhs: RouteHandler) -> Bool {
        switch (lhs, rhs) {
        case (.page, .page): return true
        case (.sync, .sync): return true
        case (.async, .async): return true
        default: return false
        }
    }
}
