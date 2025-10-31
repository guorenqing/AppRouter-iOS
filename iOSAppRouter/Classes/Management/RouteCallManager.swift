//
//  RouteCallManager.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit

/// 统一路由调用管理器
@MainActor
public class RouteCallManager: NSObject {
    public static let shared = RouteCallManager()
    private override init() {}
    
    // MARK: - 页面导航管理
    private var navigationCompletions: [UIViewController: (RouteCallID, Any?) -> Void] = [:]
    private var viewControllerCallIDs: [UIViewController: RouteCallID] = [:]
    
    // MARK: - 功能调用管理
    private var activeAsyncCalls: [RouteCallID: Task<Any?, Error>] = [:]
    private var callCache: [String: (result: Any?, timestamp: TimeInterval)] = [:]
    private let defaultCacheTimeout: TimeInterval = 30
    
    // MARK: - 统一调用上下文管理
    private var callContexts: [RouteCallID: RouteCallContext] = [:]
    private let cleanupInterval: TimeInterval = 300
    
    // MARK: - 初始化
    public func setupNavigationDelegate(_ navigationController: UINavigationController) {
        // 使用多播代理解决冲突
        NavigationDelegateMulticast.shared.addDelegate(self)
        navigationController.delegate = NavigationDelegateMulticast.shared
        
        startCleanupTimer()
    }
    
    /// 处理导航显示完成事件
    public func handleNavigationDidShow(
        navigationController: UINavigationController,
        viewController: UIViewController
    ) {
        // 检查是否有页面被关闭
        guard let fromViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
              !navigationController.viewControllers.contains(fromViewController) else {
            return
        }
        
        // 页面被关闭，调用完成回调
        if let completion = navigationCompletions.removeValue(forKey: fromViewController),
           let callID = viewControllerCallIDs.removeValue(forKey: fromViewController) {
            let result = fromViewController.routeResult
            completion(callID, result)
            
            // 清理上下文
            callContexts.removeValue(forKey: callID)
        }
    }
    
    /// 处理导页面Dismiss完成事件
    public func handleViewControllerDidDismiss(
        viewController: UIViewController
    ) {
        
        // 页面被关闭，调用完成回调
        if let completion = navigationCompletions.removeValue(forKey: viewController),
           let callID = viewControllerCallIDs.removeValue(forKey: viewController) {
            let result = viewController.routeResult
            completion(callID, result)
            
            // 清理上下文
            callContexts.removeValue(forKey: callID)
        }
    }
    
    // MARK: - 统一调用注册
    public func registerCall(
        _ context: RouteCallContext,
        completion: @escaping (Any?) -> Void
    ) {
        // 存储调用上下文
        callContexts[context.id] = context
        
        if context.isPageRoute {
            registerPageCall(context, completion: completion)
        } else {
            registerFunctionCall(context, completion: completion)
        }
    }
    
    // MARK: - 页面调用管理
    private func registerPageCall(
        _ context: RouteCallContext,
        completion: @escaping (Any?) -> Void
    ) {
        // 页面调用的视图控制器会在导航时设置
        let placeholderVC = UIViewController()
        
        navigationCompletions[placeholderVC] = { [weak self] completedCallID, result in
            if completedCallID == context.id {
                completion(result)
                self?.callContexts.removeValue(forKey: context.id)
            }
        }
        
        viewControllerCallIDs[placeholderVC] = context.id
    }
    
    // MARK: - 功能调用管理
    private func registerFunctionCall(
        _ context: RouteCallContext,
        completion: @escaping (Any?) -> Void
    ) {
        Task {
            do {
                let result: Any?
                
                switch context.routeType {
                case .actionSync:
                    result = try executeSyncCall(context: context)
                    completion(result)
                    
                case .actionAsync:
                    result = try await executeAsyncCall(context: context)
                    completion(result)
                    
                case .page:
                    // 页面调用不应该走到这里
                    completion(nil)
                    return
                }
                
                // 调用完成后清理上下文
                callContexts.removeValue(forKey: context.id)
                
            } catch {
                completion(nil)
                callContexts.removeValue(forKey: context.id)
            }
        }
    }
    
    // MARK: - 同步功能调用
    private func executeSyncCall(context: RouteCallContext) throws -> Any? {
        
        let callKey = context.getCallKey()
        let mergedParams = context.getMergedParams()
        
        // 检查缓存
        if context.enableCaching, let cached = getCachedResult(for: callKey) {
            print("🔄 使用缓存结果: \(context.path)")
            return cached
        }
        
        // 检查并发控制
        if context.enableConcurrentControl, isDuplicateCallInProgress(callKey: callKey, currentCallID: context.id) {
            throw RouteError.concurrentCallInProgress
        }
        
        let result: Any?
            
        // 使用模式匹配来安全地处理枚举
        switch context.routeConfig.handler {
        case .sync(let syncHandler):
            // 这是同步调用
            result = try syncHandler(mergedParams)
        case .async:
            // 如果在同步函数中遇到异步handler，抛出错误
            throw RouteError.inValidHandlerInSyncContext(context.path)
        case .page:
            throw RouteError.inValidHandlerInSyncContext(context.path)
        }
        
        // 缓存结果
        if context.enableCaching {
            cacheResult(result, for: callKey, timeout: context.cacheTimeout)
        }
        
        return result
    }
    
    // MARK: - 异步功能调用
    private func executeAsyncCall(context: RouteCallContext) async throws -> Any? {
        
        let callKey = context.getCallKey()
        let mergedParams = context.getMergedParams()
        
        // 检查缓存
        if context.enableCaching, let cached = getCachedResult(for: callKey) {
            print("🔄 使用缓存结果: \(context.path)")
            return cached
        }
        
        // 检查是否已有相同调用在进行中
        if context.enableConcurrentControl,
           let existingTask = activeAsyncCalls.first(where: {
               $0.key != context.id && generateCallKey(path: context.path, params: mergedParams) == callKey
           })?.value {
            print("🔄 等待现有调用完成: \(context.path)")
            return try await existingTask.value
        }
        
        // 创建新的异步任务
        let task = Task<Any?, Error> {
            do {
                let result = try await context.routeConfig.handler(params: mergedParams)
                
                // 缓存成功结果
                if context.enableCaching {
                    await MainActor.run {
                        self.cacheResult(result, for: callKey, timeout: context.cacheTimeout)
                    }
                }
                
                return result
            } catch {
                self.activeAsyncCalls.removeValue(forKey: context.id)
                throw error
            }
        }
        
        // 存储任务引用
        activeAsyncCalls[context.id] = task
        
        defer {
            Task { @MainActor in
                self.activeAsyncCalls.removeValue(forKey: context.id)
            }
        }
        
        return try await task.value
    }
    
    // MARK: - 页面导航关联
    public func associateViewController(_ viewController: UIViewController, with context: RouteCallContext) {
        // 找到对应的占位符并替换为实际的视图控制器
        if let placeholder = viewControllerCallIDs.first(where: { $0.value == context.id })?.key {
            navigationCompletions[viewController] = navigationCompletions[placeholder]
            navigationCompletions.removeValue(forKey: placeholder)
            
            viewControllerCallIDs[viewController] = context.id
            viewControllerCallIDs.removeValue(forKey: placeholder)
        }
    }
    
    // MARK: - 调用取消
    public func cancelCall(_ callID: RouteCallID) {
        // 取消页面调用
        if let (viewController, _) = viewControllerCallIDs.first(where: { $0.value == callID }) {
            navigationCompletions.removeValue(forKey: viewController)
            viewControllerCallIDs.removeValue(forKey: viewController)
        }
        
        // 取消功能调用
        if let task = activeAsyncCalls[callID] {
            task.cancel()
            activeAsyncCalls.removeValue(forKey: callID)
        }
        
        // 清理上下文
        callContexts.removeValue(forKey: callID)
        
        print("❌ 取消路由调用: \(callID.id)")
    }
    
    public func cancelAllCalls() {
        // 取消所有功能调用
        for (_, task) in activeAsyncCalls {
            task.cancel()
        }
        activeAsyncCalls.removeAll()
        
        // 清理所有页面调用
        navigationCompletions.removeAll()
        viewControllerCallIDs.removeAll()
        
        // 清理上下文（保留缓存）
        callContexts.removeAll()
        
        print("❌ 取消所有路由调用")
    }
    
    // MARK: - 缓存管理
    private func generateCallKey(path: String, params: [String: Any]) -> String {
        let paramsString = params.sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        return "\(path)?\(paramsString)".sha256()
    }
    
    private func getCachedResult(for callKey: String) -> Any? {
        guard let cached = callCache[callKey] else { return nil }
        
        if Date().timeIntervalSince1970 - cached.timestamp > defaultCacheTimeout {
            callCache.removeValue(forKey: callKey)
            return nil
        }
        
        return cached.result
    }
    
    private func cacheResult(_ result: Any?, for callKey: String, timeout: TimeInterval) {
        callCache[callKey] = (result: result, timestamp: Date().timeIntervalSince1970)
    }
    
    private func isDuplicateCallInProgress(callKey: String, currentCallID: RouteCallID) -> Bool {
        return activeAsyncCalls.contains { callID, task in
            callID != currentCallID && !task.isCancelled
        }
    }
    
    // MARK: - 清理管理
    private func startCleanupTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + cleanupInterval) { [weak self] in
            self?.cleanupExpiredContexts()
            self?.startCleanupTimer()
        }
    }
    
    private func cleanupExpiredContexts() {
        let now = Date().timeIntervalSince1970
        
        // 清理过期上下文
        let expiredCallIDs = callContexts.filter { (_, context) in
            now - context.timestamp > cleanupInterval
        }.map { $0.key }
        
        for callID in expiredCallIDs {
            cancelCall(callID)
        }
        
        // 清理过期缓存
        let expiredCacheKeys = callCache.filter { (_, cached) in
            now - cached.timestamp > defaultCacheTimeout
        }.map { $0.key }
        
        for key in expiredCacheKeys {
            callCache.removeValue(forKey: key)
        }
        
        if !expiredCallIDs.isEmpty || !expiredCacheKeys.isEmpty {
            print("🧹 清理了 \(expiredCallIDs.count) 个过期上下文和 \(expiredCacheKeys.count) 个过期缓存")
        }
    }
    
    // MARK: - 调试方法
    public func getActiveCallCount() -> Int {
        return callContexts.count
    }
    
    public func getActivePageCallCount() -> Int {
        return navigationCompletions.count
    }
    
    public func getActiveFunctionCallCount() -> Int {
        return activeAsyncCalls.count
    }
    
    public func getCachedCallCount() -> Int {
        return callCache.count
    }
    
    public func printRouteCallStatus() {
        print("=== 统一路由调用状态 ===")
        print("总活跃调用: \(callContexts.count)")
        print("页面调用: \(navigationCompletions.count)")
        print("异步功能调用: \(activeAsyncCalls.count)")
        print("缓存调用结果: \(callCache.count)")
        
        callContexts.forEach { callID, context in
            let type = context.isPageRoute ? "📱 页面" : "⚡ 功能"
            let status = activeAsyncCalls[callID] != nil ? "进行中" : "等待中"
            print("\(type) 调用ID: \(callID.id), 路径: \(context.path), 状态: \(status)")
        }
        print("=====================")
    }
}

// MARK: - UINavigationControllerDelegate
extension RouteCallManager: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        handleNavigationDidShow(navigationController: navigationController, viewController: viewController)
    }
}
