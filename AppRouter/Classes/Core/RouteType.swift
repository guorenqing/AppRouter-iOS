//
//  RouteType.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import Foundation

/// 路由类型枚举
public enum RouteType: CustomStringConvertible {
    case page                  // 页面跳转（UIViewController）- 同步
    case actionSync            // 同步功能调用
    case actionAsync           // 异步功能调用
    
    public var description: String {
        switch self {
        case .page: return "Page"
        case .actionSync: return "SyncAction"
        case .actionAsync: return "AsyncAction"
        }
    }
}

/// 导航类型枚举
public enum NavigationType: CustomStringConvertible {
    case none                // 非页面导航模式
    case push                // 推入导航栈
    case modal               // 模态展示
    case replaceCurrent      // 替换当前页面
    case replaceAll          // 替换所有页面
    
    public var description: String {
        switch self {
        case .push: return "Push"
        case .modal: return "Modal"
        case .replaceCurrent: return "ReplaceCurrent"
        case .replaceAll: return "ReplaceAll"
        case .none:
            return "None"
        }
    }
}
