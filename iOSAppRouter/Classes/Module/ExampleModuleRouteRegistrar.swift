//
//  ExampleModuleRouteRegistrar.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//  这是一个示例类

import Foundation

/// 示例模块路由注册器
public class ExampleModuleRouteRegistrar: ModuleRouteRegistrar {
    public init() {}
    
    public func registerRoutes(to configurator: RouterConfigurator) {
        let userRoutes = [
            RouteConfig(
                path: "/user/profile",
                handler: .page { params in
                    return UIViewController()
                },
                testParamsBuilder: {
                    return ["userId": "test_user_001"]
                }
            ),
            
            RouteConfig(
                path: "/user/settings",
                handler: .page { params in
                    return UIViewController()
                },
                defaultNavigationType: .modal,
                testParamsBuilder: {
                    return ["source": "automated_test"]
                }
            ),
            
            RouteConfig(
                path: "/user/list",
                handler: .async { params in
                    try await Task.sleep(nanoseconds: 500_000_000)
                    
                    let page = params["page"] as? Int ?? 1
                    let query = params["query"] as? String
                    
                    var users = [
                        ["id": "1", "name": "张三", "email": "zhangsan@example.com"],
                        ["id": "2", "name": "李四", "email": "lisi@example.com"]
                    ]
                    
                    if let query = query, !query.isEmpty {
                        users = users.filter { user in
                            (user["name"])?.contains(query) == true
                        }
                    }
                    
                    return [
                        "users": users,
                        "page": page,
                        "hasMore": page < 3
                    ]
                },
                testParamsBuilder: {
                    return [
                        "page": 1,
                        "query": "张"
                    ]
                },
                enableCaching: true
            )
        ]
        
        configurator.registerRoutes(userRoutes)
    }
}
