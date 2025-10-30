//
//  PushNotificationHandler.swift
//  Runner
//
//  Created by edy on 2025/10/20.
//


import UIKit

public class PushNotificationHandler {
    public static let shared = PushNotificationHandler()
    
    private weak var router: PushNotificationRouterProtocol?
    
    private init() {}
    
    /// 设置路由处理器
    public func setRouter(_ router: PushNotificationRouterProtocol) {
        self.router = router
    }
    
    /// 处理推送通知
    public func handleNotification(_ userInfo: [AnyHashable: Any]) {
        guard let pushData = PushNotificationData(userInfo: userInfo) else {
            print("❌ 推送数据解析失败")
            return
        }
        
        print("""
        📱 处理推送:
          标题: \(pushData.title)
          内容: \(pushData.message)
          显示弹窗: \(pushData.isShowAlert)
          路由: \(pushData.routeUrl ?? "无")
        """)
        
        if pushData.isShowAlert {
            // 显示弹窗，用户确认后执行路由
            showAlert(pushData)
        } else if let routeUrl = pushData.routeUrl {
            // 直接执行路由
            executeRouteUrl(routeUrl)
        } else {
            // 既不需要弹窗也没有路由，只记录日志
            print("📱 推送已接收，无需特殊处理")
        }
    }
    
    // MARK: - 弹窗处理
    
    private func showAlert(_ pushData: PushNotificationData) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: pushData.title,
                message: pushData.message,
                preferredStyle: .alert
            )
            
            if let routeUrl = pushData.routeUrl {
                // 有路由：显示"查看"和"忽略"按钮
                alert.addAction(UIAlertAction(title: "查看", style: .default) { _ in
                    self.executeRouteUrl(routeUrl)
                })
                
                alert.addAction(UIAlertAction(title: "忽略", style: .cancel))
            } else {
                // 无路由：只显示"确定"按钮
                alert.addAction(UIAlertAction(title: "确定", style: .default))
            }
            
            if let rootVC = self.getTopViewController() {
                rootVC.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - Scheme 执行
    
    private func executeRouteUrl(_ routerUrl: String) {
        guard let router = router else {
            print("❌ 路由处理器未设置")
            return
        }
        
        Task {
            let success = await router.handleRouterUrl(routerUrl)
            if success {
                print("✅ 推送路由执行成功: \(routerUrl)")
            } else {
                print("❌ 推送路由执行失败: \(routerUrl)")
            }
        }
    }
    
    // MARK: - 工具方法
    
    private func getTopViewController() -> UIViewController? {
        if #available(iOS 13.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                return nil
            }
            return findTopViewController(from: rootViewController)
        } else {
            // iOS 13 以下版本
            guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
                return nil
            }
            return findTopViewController(from: rootViewController)
        }
    }
    
    private func findTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presentedViewController = viewController.presentedViewController {
            return findTopViewController(from: presentedViewController)
        }
        
        if let navigationController = viewController as? UINavigationController {
            if let visibleViewController = navigationController.visibleViewController {
                return findTopViewController(from: visibleViewController)
            }
            return navigationController
        }
        
        if let tabBarController = viewController as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                return findTopViewController(from: selectedViewController)
            }
            return tabBarController
        }
        
        return viewController
    }
}
