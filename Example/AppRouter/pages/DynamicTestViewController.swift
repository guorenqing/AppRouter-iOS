//
//  DynamicTestViewController.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit
import SnapKit
import AppRouter

class DynamicTestViewController: UIViewController {
    
    var message: String = "默认消息"
    
    private let messageLabel = UILabel()
    private let closeButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        print("动态测试页初始化，消息: \(message)")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGreen
        
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.text = "动态路由测试\n\n\(message)"
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 18, weight: .medium)
        view.addSubview(messageLabel)
        
        closeButton.setTitle("关闭", for: .normal)
        closeButton.backgroundColor = .white
        closeButton.setTitleColor(.systemGreen, for: .normal)
        closeButton.layer.cornerRadius = 8
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(closeButton)
        
        messageLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-50)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(44)
        }
    }
    
    @objc private func close() {
        let result: [String: Any] = [
            "from": "dynamic_test",
            "message": message,
            "closedAt": Date().timeIntervalSince1970
        ]
        popRoute(result: result)
    }
}
