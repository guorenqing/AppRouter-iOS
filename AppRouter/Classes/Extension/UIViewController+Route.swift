//
//  UIViewController+Route.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit

// MARK: - 关联对象键
private var routeParamsKey: Void?
private var routeResultKey: Void?

// MARK: - UIViewController 路由扩展
extension UIViewController: RouteResultProvider {
    
    // MARK: - 路由参数
    public var routeParams: [String: Any]? {
        get {
            return objc_getAssociatedObject(self, &routeParamsKey) as? [String: Any]
        }
        set {
            objc_setAssociatedObject(self, &routeParamsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - 路由返回结果
    public var routeResult: Any? {
        get {
            return objc_getAssociatedObject(self, &routeResultKey)
        }
        set {
            objc_setAssociatedObject(self, &routeResultKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - 页面关闭方法
    
    /// 关闭页面并返回结果（自动判断导航类型）
    public func popRoute(result: Any? = nil) {
        self.routeResult = result
        
        if let navigationController = self.navigationController,
           navigationController.viewControllers.count > 1 {
            // 在导航栈中，使用 pop
            navigationController.popViewController(animated: true)
        } else if self.presentingViewController != nil {
            // 是模态展示的，使用 dismiss
            self.dismiss(animated: true) {
                RouteCallManager.shared.handleViewControllerDidDismiss(viewController: self)
            }
        } else {
            // 其他情况，尝试 dismiss
            self.dismiss(animated: true)
        }
    }
    
    /// 安全关闭页面（避免重复关闭）
    public func safePopRoute(result: Any? = nil) {
        guard !isBeingDismissed else { return }
        guard !(navigationController?.isBeingDismissed ?? false) else { return }
        
        popRoute(result: result)
    }
    
    // MARK: - 路由工具方法
    
    /// 获取当前最顶层的视图控制器
    public static func topMostViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        
        return topMostViewController(of: rootViewController)
    }
    
    /// 递归获取最顶层的视图控制器
    private static func topMostViewController(of viewController: UIViewController) -> UIViewController {
        if let presentedViewController = viewController.presentedViewController {
            return topMostViewController(of: presentedViewController)
        }
        
        if let navigationController = viewController as? UINavigationController {
            if let visibleViewController = navigationController.visibleViewController {
                return topMostViewController(of: visibleViewController)
            }
            return navigationController
        }
        
        if let tabBarController = viewController as? UITabBarController {
            if let selectedViewController = tabBarController.selectedViewController {
                return topMostViewController(of: selectedViewController)
            }
            return tabBarController
        }
        
        return viewController
    }
    
    /// 显示路由相关的提示
    public func showRouteAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completion?()
        })
        
        // 确保在主线程显示
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
}
