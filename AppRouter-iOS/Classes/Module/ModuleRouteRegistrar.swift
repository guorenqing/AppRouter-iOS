//
//  ModuleRouteRegistrar.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import Foundation

/// 模块路由注册协议
public protocol ModuleRouteRegistrar {
    func registerRoutes(to configurator: RouterConfigurator)
}
