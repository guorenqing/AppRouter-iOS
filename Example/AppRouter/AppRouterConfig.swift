//
//  AppRouterConfig.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit
import AppRouter

/// 应用路由配置
public class AppRouterConfig: BaseRouterConfigurator {
    
    public init() {
        super.init(scheme: "myapp")
        registerDefaultRoutes()
        registerDefaultInterceptors()
    }
    
    // MARK: - 默认路由注册
    
    private func registerDefaultRoutes() {
        let defaultRoutes = [
            // 页面路由
            RouteConfig(
                path: "/home",
                handler: .page { params in
                    return HomeViewController()
                },
                testParamsBuilder: {
                    return [
                        "welcome": "自动化测试首页",
                        "testScenario": "home_page"
                    ]
                }
            ),
            
            RouteConfig(
                path: "/login",
                handler: .page { params in
                    return LoginViewController()
                },
                defaultNavigationType: .modal,
                testParamsBuilder: {
                    return [
                        "source": "automated_test",
                        "autoLogin": false,
                        "testUser": "test@example.com"
                    ]
                }
            ),
            
            RouteConfig(
                path: "/detail",
                handler: .page { params in
                    let id = params["id"] as? String ?? ""
                    let title = params["title"] as? String
                    return DetailViewController(id: id, title: title)
                },
                testParamsBuilder: {
                    return [
                        "id": "auto_test_\(Int.random(in: 1000...9999))",
                        "title": "自动化测试详情页",
                        "description": "这是自动化测试生成的详情页"
                    ]
                }
            ),
            
            RouteConfig(
                path: "/webview",
                handler: .page { params in
                    guard let urlString = params["url"] as? String,
                          let url = URL(string: urlString) else {
                        throw RouteError.missingRequiredParameter("url")
                    }
                    
                    let webViewController = WebViewController(url: url)
                    webViewController.title = params["title"] as? String
                    return webViewController
                },
                testParamsBuilder: {
                    return [
                        "url": "https://www.example.com",
                        "title": "自动化测试网页"
                    ]
                },
                testTimeout: 15.0
            ),
            
            // 同步功能路由
            RouteConfig(
                path: "/getUserInfo",
                handler: .sync { params in
                    return UserManager.shared.currentUser?.toDictionary() ?? ["status": "未登录"]
                },
                testParamsBuilder: {
                    return ["includeDetails": true]
                }
            ),
            
            RouteConfig(
                path: "/getAppConfig",
                handler: .sync { params in
                    return [
                        "version": "1.0.0",
                        "build": "100",
                        "environment": "debug"
                    ]
                },
                testParamsBuilder: {
                    return ["includeAll": true]
                }
            ),
            
            RouteConfig(
                path: "/showToast",
                handler: .sync { params in
                    guard let message = params["message"] as? String else {
                        throw RouteError.missingRequiredParameter("message")
                    }
                    
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                            rootVC.present(alert, animated: true, completion: nil)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                alert.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                    return true
                },
                testParamsBuilder: {
                    return ["message": "测试Toast消息"]
                }
            ),
            
            RouteConfig(
                path: "/calculate",
                handler: .sync { params in
                    let a = params["a"] as? Double ?? 0
                    let b = params["b"] as? Double ?? 0
                    let operation = params["operation"] as? String ?? "add"
                    
                    let result: Double
                    switch operation {
                    case "add": result = a + b
                    case "subtract": result = a - b
                    case "multiply": result = a * b
                    case "divide": result = b != 0 ? a / b : 0
                    default: result = a + b
                    }
                    
                    return [
                        "a": a,
                        "b": b,
                        "operation": operation,
                        "result": result
                    ]
                },
                testParamsBuilder: {
                    let operations = ["add", "subtract", "multiply", "divide"]
                    return [
                        "a": Double.random(in: 1...100),
                        "b": Double.random(in: 1...100),
                        "operation": operations.randomElement()!
                    ]
                }
            ),
            
            // 异步功能路由
            RouteConfig(
                path: "/system_browser",
                handler: .async { params in
                    guard let urlString = params["url"] as? String,
                          let url = URL(string: urlString) else {
                        throw RouteError.missingRequiredParameter("url")
                    }
                    
                    if params["testMode"] as? Bool == true {
                        print("🔗 模拟打开系统浏览器: \(urlString)")
                        try await Task.sleep(nanoseconds: 500_000_000)
                        return ["status": "success", "url": urlString, "simulated": true]
                    } else {
                        await UIApplication.shared.open(url)
                        return ["status": "success", "url": urlString]
                    }
                },
                testParamsBuilder: {
                    return [
                        "url": "https://www.example.com",
                        "testMode": true
                    ]
                }
            ),
            
            RouteConfig(
                path: "/alert",
                handler: .async { params in
                    return await withCheckedContinuation { continuation in
                        DispatchQueue.main.async {
                            let alert = UIAlertController(
                                title: params["title"] as? String,
                                message: params["message"] as? String,
                                preferredStyle: .alert
                            )
                            
                            if let cancelTitle = params["cancelTitle"] as? String {
                                alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in
                                    continuation.resume(returning: ["action": "cancel"])
                                })
                            }
                            
                            if let confirmTitle = params["confirmTitle"] as? String {
                                alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
                                    continuation.resume(returning: ["action": "confirm"])
                                })
                            }
                            
                            if params["autoConfirm"] as? Bool == true {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    alert.dismiss(animated: true) {
                                        continuation.resume(returning: ["action": "auto_confirm"])
                                    }
                                }
                            }
                            
                            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                                rootVC.present(alert, animated: true)
                            } else {
                                continuation.resume(returning: ["action": "dismissed"])
                            }
                        }
                    }
                },
                testParamsBuilder: {
                    return [
                        "title": "自动化测试弹窗",
                        "message": "这是自动化测试生成的弹窗",
                        "cancelTitle": "取消",
                        "confirmTitle": "确定",
                        "autoConfirm": true
                    ]
                }
            ),
            
            RouteConfig(
                path: "/api/data",
                handler: .async { params in
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    
                    let page = params["page"] as? Int ?? 1
                    let size = params["size"] as? Int ?? 10
                    
                    return [
                        "data": Array(1...size).map { index in
                            [
                                "id": (page - 1) * size + index,
                                "name": "测试项目 \(index)"
                            ]
                        },
                        "page": page,
                        "total": 100
                    ]
                },
                testParamsBuilder: {
                    return [
                        "page": 1,
                        "size": 5
                    ]
                },
                enableCaching: true,
                cacheTimeout: 60.0
            )
        ]
        
        registerRoutes(defaultRoutes)
    }
    
    // MARK: - 默认拦截器注册
    
    private func registerDefaultInterceptors() {
        addInterceptor(LogInterceptor())
        addInterceptor(LoginInterceptor())
    }
}

// MARK: - 辅助类
public class UserManager {
    public static let shared = UserManager()
    public var currentUser: User?
    public var isLoggedIn: Bool { currentUser != nil }
    
    public func login(user: User) {
        currentUser = user
        print("✅ 用户登录成功: \(user.name)")
    }
    
    public func logout() {
        currentUser = nil
        print("✅ 用户已登出")
    }
}

public struct User {
    public let id: String
    public let name: String
    public let email: String
    
    public init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
    
    public func toDictionary() -> [String: Any] {
        return ["id": id, "name": name, "email": email]
    }
}
