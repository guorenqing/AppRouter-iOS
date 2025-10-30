//
//  RouteRegistry.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import Foundation

/// 路由注册管理器
public class RouteRegistry {
    public static let shared = RouteRegistry()
    private var registeredModules: Set<String> = []
    
    private init() {}
    
    /// 注册模块路由
    @MainActor
    public func registerModule(_ module: ModuleRouteRegistrar, identifier: String) {
        guard !self.registeredModules.contains(identifier) else {
            print("模块 \(identifier) 已注册，跳过重复注册")
            return
        }
        
        if let configurator = AppRouter.shared.configurator {
            module.registerRoutes(to: configurator)
            self.registeredModules.insert(identifier)
            print("✅ 模块 \(identifier) 路由注册完成")
        } else {
            print("❌ 错误: 路由未初始化，无法注册模块 \(identifier)")
        }
    }
    
    /// 检查模块是否已注册
    public func isModuleRegistered(_ identifier: String) -> Bool {
        registeredModules.contains(identifier)
    }
    
    /// 获取已注册的模块列表
    public func getRegisteredModules() -> [String] {
        Array(registeredModules)
    }
    
    /// 清除所有模块注册
    public func clearAllModules() {
        self.registeredModules.removeAll()
        print("🧹 清除所有模块注册")
    }
}
