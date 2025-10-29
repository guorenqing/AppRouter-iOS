//
//  RouterConfigurator.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import Foundation

/// 路由配置抽象协议
public protocol RouterConfigurator {
    var scheme: String { get }
    var routes: [RouteConfig] { get }
    var interceptors: [RouteInterceptor] { get }
    
    func registerRoute(_ route: RouteConfig)
    func registerRoutes(_ routes: [RouteConfig])
    func removeRoute(for path: String)
    func containsRoute(for path: String) -> Bool
}

/// 默认路由配置器实现
open class BaseRouterConfigurator: RouterConfigurator {
    public let scheme: String
    
    private var _routes: [RouteConfig] = []
    private var _interceptors: [RouteInterceptor] = []
    private let queue = DispatchQueue(label: "com.router.configurator", attributes: .concurrent)
    
    public init(scheme: String) {
        self.scheme = scheme
    }
    
    open var routes: [RouteConfig] {
        queue.sync { _routes }
    }
    
    open var interceptors: [RouteInterceptor] {
        queue.sync { _interceptors }
    }
    
    public func registerRoute(_ route: RouteConfig) {
        queue.async(flags: .barrier) {
            self._routes.removeAll { $0.path.lowercased() == route.path.lowercased() }
            self._routes.append(route)
        }
    }
    
    public func registerRoutes(_ routes: [RouteConfig]) {
        queue.async(flags: .barrier) {
            for route in routes {
                self._routes.removeAll { $0.path.lowercased() == route.path.lowercased() }
                self._routes.append(route)
            }
        }
    }
    
    public func removeRoute(for path: String) {
        queue.async(flags: .barrier) {
            self._routes.removeAll { $0.path.lowercased() == path.lowercased() }
        }
    }
    
    public func containsRoute(for path: String) -> Bool {
        queue.sync {
            _routes.contains { $0.path.lowercased() == path.lowercased() }
        }
    }
    
    public func addInterceptor(_ interceptor: RouteInterceptor) {
        queue.async(flags: .barrier) {
            self._interceptors.append(interceptor)
        }
    }
    
    public func removeInterceptor(_ interceptor: RouteInterceptor) {
        queue.async(flags: .barrier) {
            self._interceptors.removeAll { $0 === interceptor }
        }
    }
    
    public func removeAllInterceptors() {
        queue.async(flags: .barrier) {
            self._interceptors.removeAll()
        }
    }
}
