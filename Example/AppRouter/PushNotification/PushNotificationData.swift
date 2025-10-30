//
//  PushNotificationData.swift
//  Runner
//
//  Created by edy on 2025/10/20.
//

import Foundation

public struct PushNotificationData {
    public let title: String
    public let message: String
    public let isShowAlert: Bool
    public let routeUrl: String?
    
    public init?(userInfo: [AnyHashable: Any]) {
        // 解析推送内容
        if let aps = userInfo["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? [String: Any] {
                self.title = alert["title"] as? String ?? "新消息"
                self.message = alert["body"] as? String ?? "您有一条新通知"
            } else if let alert = aps["alert"] as? String {
                self.title = "新消息"
                self.message = alert
            } else {
                self.title = "新消息"
                self.message = "您有一条新通知"
            }
        } else {
            self.title = "新消息"
            self.message = "您有一条新通知"
        }
        
        // 解析是否显示弹窗
        self.isShowAlert = userInfo["isShowAlert"] as? Bool ?? false
        
        // 解析路由信息
        if let routeUrl = userInfo["routeUrl"] as? String {
            self.routeUrl = routeUrl
        } else {
            self.routeUrl = nil
        }
    }
}
