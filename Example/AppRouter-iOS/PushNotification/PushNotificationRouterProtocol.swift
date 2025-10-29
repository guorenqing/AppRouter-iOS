//
//  PushNotificationRouterProtocol.swift
//  Runner
//
//  Created by edy on 2025/10/20.
//

import Foundation


/// 推送通知路由协议
public protocol PushNotificationRouterProtocol: AnyObject {
    func handleRouterUrl(_ routerUrl: String) async -> Bool
}
