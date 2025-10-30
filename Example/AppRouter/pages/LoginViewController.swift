//
//  LoginViewController.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit
import SnapKit
import AppRouter

class LoginViewController: UIViewController {
    
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton()
    private let skipButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        print("🔐 登录页初始化，参数: \(routeParams ?? [:])")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "用户登录"
        
        // 容器视图
        let containerView = UIView()
        view.addSubview(containerView)
        
        // 邮箱输入框
        emailField.placeholder = "请输入邮箱"
        emailField.borderStyle = .roundedRect
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none
        containerView.addSubview(emailField)
        
        // 密码输入框
        passwordField.placeholder = "请输入密码"
        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true
        containerView.addSubview(passwordField)
        
        // 登录按钮
        loginButton.setTitle("登录", for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        containerView.addSubview(loginButton)
        
        // 跳过按钮
        skipButton.setTitle("跳过登录", for: .normal)
        skipButton.setTitleColor(.systemGray, for: .normal)
        skipButton.addTarget(self, action: #selector(skipLogin), for: .touchUpInside)
        containerView.addSubview(skipButton)
        
        // 自动填充测试数据
        emailField.text = "test@example.com"
        passwordField.text = "password123"
        
        // 布局
        containerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-40)
        }
        
        emailField.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        
        passwordField.snp.makeConstraints { make in
            make.top.equalTo(emailField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        skipButton.snp.makeConstraints { make in
            make.top.equalTo(loginButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    @objc private func login() {
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(title: "输入错误", message: "请填写邮箱和密码")
            return
        }
        
        // 模拟登录过程
        loginButton.isEnabled = false
        loginButton.setTitle("登录中...", for: .normal)
        loginButton.backgroundColor = .systemGray
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 模拟登录成功
            let user = User(id: "user_\(Int.random(in: 1000...9999))", name: "测试用户", email: email)
            UserManager.shared.login(user: user)
            
            self.showAlert(title: "登录成功", message: "欢迎回来，\(user.name)！") {
                let result: [String: Any] = [
                    "success": true,
                    "user": user.toDictionary(),
                    "loginTime": Date().timeIntervalSince1970
                ]
                self.popRoute(result: result)
            }
        }
    }
    
    @objc private func skipLogin() {
        let result: [String: Any] = [
            "success": false,
            "skipped": true,
            "message": "用户跳过了登录"
        ]
        popRoute(result: result)
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    deinit {
        print("登录页销毁")
    }
}
