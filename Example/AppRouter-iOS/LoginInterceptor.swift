//
//  LoginInterceptor.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import Foundation
import AppRouter_iOS

/// 登录拦截器
public class LoginInterceptor: RouteInterceptor {
    public init() {}
    
    public func intercept(path: String, params: [String: Any]?) async -> InterceptorResult {
        let needLoginRoutes = ["/user/profile", "/user/settings","/detail"]
        
        if needLoginRoutes.contains(path) && !UserManager.shared.isLoggedIn {
            print("🔐 登录拦截: 跳转到登录页")
            return InterceptorResult.redirect(RouteConfig(
                path: "/login",
                handler: { params in
                    return LoginViewController()
                },
                defaultNavigationType:.modal,
                )
            )
        }
        
        return InterceptorResult.continue
    }
}
