//
//  NavigationDelegateMulticast.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//  导航代理多播器 - 解决代理冲突问题

import UIKit


public class NavigationDelegateMulticast: NSObject, UINavigationControllerDelegate {
    public static let shared = NavigationDelegateMulticast()
    private override init() {}
    
    // 代理集合（弱引用）
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
    /// 添加代理
    public func addDelegate(_ delegate: UINavigationControllerDelegate) {
        delegates.add(delegate)
    }
    
    /// 移除代理
    public func removeDelegate(_ delegate: UINavigationControllerDelegate) {
        delegates.remove(delegate)
    }
    
    /// 移除所有代理
    public func removeAllDelegates() {
        delegates.removeAllObjects()
    }
    
    // MARK: - UINavigationControllerDelegate
    
    public func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        for case let delegate as UINavigationControllerDelegate in delegates.allObjects {
            delegate.navigationController?(
                navigationController,
                willShow: viewController,
                animated: animated
            )
        }
    }
    
    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        for case let delegate as UINavigationControllerDelegate in delegates.allObjects {
            delegate.navigationController?(
                navigationController,
                didShow: viewController,
                animated: animated
            )
        }
    }
    
    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        for case let delegate as UINavigationControllerDelegate in delegates.allObjects {
            if let result = delegate.navigationController?(
                navigationController,
                animationControllerFor: operation,
                from: fromVC,
                to: toVC
            ) {
                return result
            }
        }
        return nil
    }
    
    public func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        for case let delegate as UINavigationControllerDelegate in delegates.allObjects {
            if let result = delegate.navigationController?(
                navigationController,
                interactionControllerFor: animationController
            ) {
                return result
            }
        }
        return nil
    }
    
    public func navigationControllerSupportedInterfaceOrientations(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientationMask {
        var result: UIInterfaceOrientationMask = .all
        
        for case let delegate as UINavigationControllerDelegate in delegates.allObjects {
            if let orientations = delegate.navigationControllerSupportedInterfaceOrientations?(
                navigationController
            ) {
                result = orientations
                break
            }
        }
        
        return result
    }
    
    public func navigationControllerPreferredInterfaceOrientationForPresentation(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientation {
        var result: UIInterfaceOrientation = .portrait
        
        for case let delegate as UINavigationControllerDelegate in delegates.allObjects {
            if let orientation = delegate.navigationControllerPreferredInterfaceOrientationForPresentation?(
                navigationController
            ) {
                result = orientation
                break
            }
        }
        
        return result
    }
}
