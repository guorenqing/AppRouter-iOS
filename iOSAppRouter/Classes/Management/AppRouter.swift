//
//  AppRouter.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit

/// 路由管理主类
@MainActor
public class AppRouter {
    public static let shared = AppRouter()
    private init() {}
    
    public var configurator: RouterConfigurator?
    private let routeCallManager = RouteCallManager.shared
    
    private var redirectDepth = 0
    private let maxRedirectDepth = 5
    
    private var currentNavigationController :UINavigationController!
    
    // 正在进行的路由调用
    private var activeCalls: [RouteCallID: RouteCallContext] = [:]
    
    // 模态页面展示配置
    public var modalPresentationStyle: UIModalPresentationStyle = .fullScreen
    public var modalTransitionStyle: UIModalTransitionStyle = .coverVertical
    
    /// 初始化配置
    public func initialize(configurator: RouterConfigurator, navigationController: UINavigationController? = nil) {
        self.configurator = configurator
        if let navigationController = navigationController {
            self.setNavigationController(navigationController)
            self.currentNavigationController = navigationController
        }
    }
    
    /// 设置当前导航控制器
    public func setNavigationController(_ navigationController: UINavigationController) {
        routeCallManager.setupNavigationDelegate(navigationController)
        self.currentNavigationController = navigationController
    }
    
    // MARK: - 公共方法
    
    /// 处理外部 Scheme 调用
    public func handleScheme(_ url: String) async -> RouteResult {
        guard let configurator = configurator else {
            return .failure("路由未初始化")
        }
        
        if url.hasPrefix("\(configurator.scheme)://") {
            guard let urlComponents = URLComponents(string: url) else {
                return .failure("非法的路由 URL")
            }
            
            let path = "/\(urlComponents.host ?? "")\(urlComponents.path)"
            var params: [String: Any] = [:]
            
            // 提取查询参数
            urlComponents.queryItems?.forEach { item in
                let value = item.value ?? ""
                if value.lowercased() == "true" {
                    params[item.name] = true
                } else if value.lowercased() == "false" {
                    params[item.name] = false
                } else {
                    params[item.name] = value
                }
            }
            
            return await navigate(path: path, params: params)
        }
        
        return .failure("非法的 Scheme")
    }
    
    // MARK: - 路由跳转方法
    
    /// 路由执行
    @MainActor
    public func navigate(path: String, params: [String: Any]? = nil) async -> RouteResult {
        guard let routeConfig = _findRoute(path: path) else {
            return .failure("未找到路由: \(path)")
        }
        
        let navigationType: NavigationType
        if let defaultNavType = routeConfig.defaultNavigationType {
            navigationType = defaultNavType
        } else {
            navigationType = routeConfig.isPageRoute ? .push : .none
        }
        
        let context = RouteCallContext(
            path: path,
            params: params ?? [:],
            navigationType: navigationType,
            routeConfig: routeConfig
        )
        
        return await _processRoute(context: context)
    }
    
    /// 推入导航栈
    public func push(path: String, params: [String: Any]? = nil) async -> RouteResult {
        guard let routeConfig = _findRoute(path: path) else {
            return .failure("未找到路由: \(path)")
        }
        
        let context = RouteCallContext(
            path: path,
            params: params ?? [:],
            navigationType: .push,
            routeConfig: routeConfig
        )
        return await _processRoute(context: context)
    }
    
    /// 模态展示
    public func present(path: String, params: [String: Any]? = nil) async -> RouteResult {
        guard let routeConfig = _findRoute(path: path) else {
            return .failure("未找到路由: \(path)")
        }
        
        let context = RouteCallContext(
            path: path,
            params: params ?? [:],
            navigationType: .modal,
            routeConfig: routeConfig
        )
        return await _processRoute(context: context)
    }
    
    /// 关闭当前页面并跳转到新页面
    public func off(path: String, params: [String: Any]? = nil) async -> RouteResult {
        guard let routeConfig = _findRoute(path: path) else {
            return .failure("未找到路由: \(path)")
        }
        
        let context = RouteCallContext(
            path: path,
            params: params ?? [:],
            navigationType: .replaceCurrent,
            routeConfig: routeConfig
        )
        return await _processRoute(context: context)
    }
    
    /// 关闭所有页面并跳转到指定页面
    public func offAll(path: String, params: [String: Any]? = nil) async -> RouteResult {
        guard let routeConfig = _findRoute(path: path) else {
            return .failure("未找到路由: \(path)")
        }
        
        let context = RouteCallContext(
            path: path,
            params: params ?? [:],
            navigationType: .replaceAll,
            routeConfig: routeConfig
        )
        return await _processRoute(context: context)
    }
    
    /// 关闭当前页面并返回结果
    public func pop(result: Any? = nil) {
        DispatchQueue.main.async {
            if let topViewController = self._getCurrentNavigationController()?.topViewController {
                topViewController.routeResult = result
            }
            self._getCurrentNavigationController()?.popViewController(animated: true)
        }
    }
    
    /// 关闭模态页面并返回结果
    public func dismiss(result: Any? = nil) {
        DispatchQueue.main.async {
            if let presentedVC = self._getCurrentNavigationController()?.presentedViewController {
                presentedVC.routeResult = result
            }
            self._getCurrentNavigationController()?.dismiss(animated: true)
        }
    }
    
    /// 取消特定的路由调用
    public func cancelCall(_ callID: RouteCallID) {
        routeCallManager.cancelCall(callID)
        activeCalls.removeValue(forKey: callID)
    }
    
    /// 取消所有路由调用
    public func cancelAllCalls() {
        routeCallManager.cancelAllCalls()
        activeCalls.removeAll()
    }
    
    // MARK: - 动态路由管理
    
    /// 动态注册路由
    public func registerRoute(_ route: RouteConfig) {
        configurator?.registerRoute(route)
    }
    
    /// 动态注册多个路由
    public func registerRoutes(_ routes: [RouteConfig]) {
        configurator?.registerRoutes(routes)
    }
    
    /// 移除路由
    public func removeRoute(for path: String) {
        configurator?.removeRoute(for: path)
    }
    
    /// 检查路由是否存在
    public func containsRoute(for path: String) -> Bool {
        return configurator?.containsRoute(for: path) ?? false
    }
    
    // MARK: - 私有方法
    
    @MainActor
    private func _processRoute(context: RouteCallContext) async -> RouteResult {
        guard let configurator = configurator else {
            return .failure("路由未初始化")
        }
        
        // 记录活跃调用
        activeCalls[context.id] = context
        
        defer {
            // 清理活跃调用
            activeCalls.removeValue(forKey: context.id)
        }
        
        // 执行拦截器
        let interceptResult = await _processInterceptors(
            context: context,
            interceptors: configurator.interceptors
        )
        
        if let result = interceptResult {
            return result
        }
        
        // 根据路由类型处理 - 使用枚举的 type 属性
        switch context.routeConfig.handler.type {
        case .page:
            return await _handlePageRoute(context: context)
            
        case .actionSync, .actionAsync:
            return await _handleFunctionRoute(context: context)
        }
    }
    
    private func _handlePageRoute(context: RouteCallContext) async -> RouteResult {
        do {
            let mergedParams = context.getMergedParams()
            let result = try await context.routeConfig.handler(params: mergedParams)
            
            guard let viewController = result as? UIViewController else {
                return .failure("页面路由必须返回 UIViewController")
            }
            
            // 设置参数
            viewController.routeParams = mergedParams
            
            // 使用统一管理器注册页面调用
            return await withCheckedContinuation { continuation in
                routeCallManager.registerCall(context) { result in
                    continuation.resume(returning: .success(data: result))
                }
                
                // 关联视图控制器
                routeCallManager.associateViewController(viewController, with: context)
                
                // 执行导航
                _performNavigation(viewController: viewController, context: context)
            }
        } catch let error as RouteError {
            return .failure(error.errorDescription ?? "页面路由处理失败")
        } catch {
            return .failure("页面路由处理失败: \(error.localizedDescription)")
        }
    }
    
    private func _handleFunctionRoute(context: RouteCallContext) async -> RouteResult {
        return await withCheckedContinuation { continuation in
            routeCallManager.registerCall(context) { result in
                continuation.resume(returning: .success(data: result))
            }
        }
    }
    
    /// 执行导航
    @MainActor
    private func _performNavigation(viewController: UIViewController, context: RouteCallContext) {
        DispatchQueue.main.async {
            guard let navigationController = self._getCurrentNavigationController() else {
                print("❌ 未设置导航控制器")
                return
            }
            
            // 根据导航类型执行不同的导航逻辑
            switch context.navigationType {
            case .push:
                navigationController.pushViewController(viewController, animated: true)
                
            case .modal:
                viewController.modalPresentationStyle = self.modalPresentationStyle
                viewController.modalTransitionStyle = self.modalTransitionStyle
                navigationController.present(viewController, animated: true)
                
            case .replaceCurrent:
                var viewControllers = navigationController.viewControllers
                if !viewControllers.isEmpty {
                    viewControllers.removeLast()
                }
                viewControllers.append(viewController)
                navigationController.setViewControllers(viewControllers, animated: true)
                
            case .replaceAll:
                navigationController.setViewControllers([viewController], animated: true)
            case .none:
                break
            }
        }
    }
    
    private func _processInterceptors(
        context: RouteCallContext,
        interceptors: [RouteInterceptor]
    ) async -> RouteResult? {
        for interceptor in interceptors {
            
            let interceptorResult = await interceptor.intercept(path: context.path, params: context.params)
            switch interceptorResult {
                case .continue:
                    // 继续执行原路由
                    continue
                    
                case .redirect(let redirectConfig):
                    // 执行重定向路由，成功后继续原路由
                    let redirectResult = await _handleRedirect(
                        originalContext: context,
                        redirectConfig: redirectConfig
                    )
                    
                    if redirectResult.isSuccess {
                        //再次判断还需要重定向不
                        let interceptorResult2 = await interceptor.intercept(path: context.path, params: context.params)
                        switch interceptorResult2 {
                            case .continue:
                            // 重定向成功，继续执行其他拦截器
                                continue
                            default: return .failure("用户已取消: \(context.path)")
                        }
                        
                    } else {
                        return redirectResult
                    }
                    
                case .replace(let replaceConfig):
                    // 替换原路由，执行新路由
                    let replaceContext = RouteCallContext(
                        path: replaceConfig.path,
                        params: context.params,
                        navigationType: context.navigationType,
                        routeConfig: replaceConfig
                    )
                    return await _processRoute(context: replaceContext)
                    
                case .reject(let error):
                    return .failure(error.localizedDescription)
                }
        }
        return nil
    }
    
    private func _handleRedirect(
        originalContext: RouteCallContext,
        redirectConfig: RouteConfig
    ) async -> RouteResult {
        // 检查重定向深度
        guard redirectDepth < maxRedirectDepth else {
            return .failure("重定向次数过多")
        }
        
        redirectDepth += 1
        defer { redirectDepth -= 1 }
        
        // 合并参数
        let redirectDefaultParams = redirectConfig.defaultParamsBuilder?() ?? [:]
        let mergedRedirectParams = redirectDefaultParams.merging(originalContext.params) { (_, new) in new }
        
        // 创建重定向上下文
        let redirectContext = RouteCallContext(
            forRedirectFrom: originalContext,
            redirectConfig: redirectConfig,
            mergedParams: mergedRedirectParams
        )
        
        // 执行重定向
        let result = await _processRoute(context: redirectContext)
        
        return result
    }
    
    
    private func _findRoute(path: String) -> RouteConfig? {
        return configurator?.routes.first { $0.path.lowercased() == path.lowercased() }
    }
    
    private func _getCurrentNavigationController() -> UINavigationController? {
        return currentNavigationController
    }
    
    // MARK: - 调试方法
    
    /// 获取当前活跃的路由调用
    public func getActiveCalls() -> [RouteCallContext] {
        return Array(activeCalls.values)
    }
    
    /// 打印路由调用状态
    public func printRouteStatus() {
        print("=== 路由状态 ===")
        print("活跃调用数量: \(activeCalls.count)")
        routeCallManager.printRouteCallStatus()
        print("已注册路由数量: \(configurator?.routes.count ?? 0)")
        activeCalls.forEach { callID, context in
            let type = context.isPageRoute ? "页面" : "功能"
            print("调用ID: \(callID.id), 类型: \(type), 路径: \(context.path)")
        }
        print("===============")
    }
}
