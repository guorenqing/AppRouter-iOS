//
//  AppDelegate.swift
//  AppRouter-iOS
//
//  Created by 郭仁庆 on 10/30/2025.
//  Copyright (c) 2025 郭仁庆. All rights reserved.
//

import UIKit
import iOSAppRouter

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 1. 获取 FlutterViewController
        guard let navigationController = window?.rootViewController as? UINavigationController else {
            fatalError("navigationController not found")
        }
        
        // 2. 配置路由系统
        setupRouter(with: navigationController)
        
        
        return true
    }
    
    // MARK: - 路由系统配置
    private func setupRouter(with navigationController: UINavigationController) {
        // 1. 创建路由配置
        let routerConfig = AppRouterConfig()
        
        // 2. 初始化路由系统
        AppRouter.shared.initialize(
            configurator: routerConfig,
            navigationController: navigationController
        )
        
        // 3. 设置模态展示样式
        AppRouter.shared.modalPresentationStyle = .pageSheet
        AppRouter.shared.modalTransitionStyle = .coverVertical
        
        // 4. 注册模块路由
        registerModuleRoutes()
        
        print("✅ 路由系统初始化完成")
        print("   已注册路由数量: \(routerConfig.routes.count)")
        print("   已注册拦截器: \(routerConfig.interceptors.count)")
    }
    
    // MARK: - 模块路由注册
    private func registerModuleRoutes() {
        // 注册示例模块
        let exampleModule = ExampleModuleRouteRegistrar()
        RouteRegistry.shared.registerModule(exampleModule, identifier: "example_module")
        print("✅ 模块路由注册完成")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

