//
//  HomeViewController.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit
import SnapKit
import AppRouter

class HomeViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var buttons: [UIButton] = []
    private let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        print("🏠 首页初始化完成")
    }
    
    private func setupNavigationBar() {
        title = "路由测试首页"
        
        let statusButton = UIBarButtonItem(
            title: "状态",
            style: .plain,
            target: self,
            action: #selector(showRouteStatus)
        )
        
        let userButton = UIBarButtonItem(
            title: "用户",
            style: .plain,
            target: self,
            action: #selector(toggleUserStatus)
        )
        
        navigationItem.rightBarButtonItems = [statusButton, userButton]
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 状态标签
        statusLabel.text = "当前用户: \(UserManager.shared.isLoggedIn ? UserManager.shared.currentUser!.name : "未登录")"
        statusLabel.textAlignment = .center
        statusLabel.textColor = .systemGray
        view.addSubview(statusLabel)
        
        // 设置滚动视图
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        
        // 创建测试按钮
        createTestButtons()
        setupButtonConstraints()
    }
    
    private func createTestButtons() {
        let testCases = [
            ("📱 推入详情页", #selector(testPushDetail)),
            ("🔐 模态登录页", #selector(testPresentLogin)),
            ("🔄 替换当前页", #selector(testReplaceCurrent)),
            ("⚡️ 并发路由测试", #selector(testConcurrentCalls)),
            ("🚫 拦截器测试(未登录)", #selector(testInterceptor)),
            ("🎯 动态路由测试", #selector(testDynamicRoute)),
            ("🌐 WebView测试", #selector(testWebView)),
            ("🔗 系统浏览器测试", #selector(testSystemBrowser)),
            ("💬 弹窗测试", #selector(testAlert)),
            ("👤 获取用户信息(同步)", #selector(testGetUserInfo)),
            ("⚙️ 获取应用配置(同步)", #selector(testGetAppConfig)),
            ("🧮 计算功能(同步)", #selector(testCalculate)),
            ("📊 异步API测试", #selector(testAsyncFunction)),
            ("👥 用户列表测试", #selector(testUserList)),
            ("🧪 自动化测试所有路由", #selector(runAutomatedTests)),
            ("🧹 关闭所有页面", #selector(testOffAll)),
            ("🎲 随机路由测试", #selector(testRandomRoutes))
        ]
        
        for (title, selector) in testCases {
            let button = createButton(title: title, selector: selector)
            contentView.addSubview(button)
            buttons.append(button)
        }
    }
    
    private func setupButtonConstraints() {
        var previousButton: UIButton?
        
        for button in buttons {
            button.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(20)
                make.trailing.equalToSuperview().offset(-20)
                make.height.equalTo(50)
                
                if let previous = previousButton {
                    make.top.equalTo(previous.snp.bottom).offset(12)
                } else {
                    make.top.equalToSuperview().offset(20)
                }
            }
            previousButton = button
        }
        
        if let lastButton = buttons.last {
            lastButton.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-20)
            }
        }
    }
    
    private func createButton(title: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }
    
    // MARK: - 测试方法
    
    @objc private func testPushDetail() {
        Task {
            print("=== 测试推入详情页 ===")
            let result = await AppRouter.shared.push(
                path: "/detail",
                params: ["id": "123", "title": "测试详情页", "source": "home"]
            )
            
            await handleRouteResult(result, operation: "推入详情页")
        }
    }
    
    @objc private func testPresentLogin() {
        Task {
            print("=== 测试模态登录页 ===")
            let result = await AppRouter.shared.present(
                path: "/login",
                params: ["source": "home", "autoLogin": false]
            )
            
            await handleRouteResult(result, operation: "模态登录页")
        }
    }
    
    @objc private func testReplaceCurrent() {
        Task {
            print("=== 测试替换当前页 ===")
            let result = await AppRouter.shared.off(
                path: "/detail",
                params: ["id": "replace_test", "message": "这个页面替换了首页"]
            )
            
            await handleRouteResult(result, operation: "替换当前页")
        }
    }
    
    @objc private func testConcurrentCalls() {
        Task {
            print("=== 测试并发路由调用 ===")
            
            async let call1 = AppRouter.shared.push(path: "/detail", params: ["id": "concurrent_1"])
            async let call2 = AppRouter.shared.push(path: "/detail", params: ["id": "concurrent_2"])
            async let call3 = AppRouter.shared.present(path: "/login", params: ["source": "concurrent"])
            
            let (result1, result2, result3) = await (call1, call2, call3)
            
            await MainActor.run {
                print("并发调用结果:")
                print("调用1: \(result1.isSuccess ? "成功" : "失败") - \(result1.message ?? "")")
                print("调用2: \(result2.isSuccess ? "成功" : "失败") - \(result2.message ?? "")")
                print("调用3: \(result3.isSuccess ? "成功" : "失败") - \(result3.message ?? "")")
                
                self.showAlert(title: "并发测试完成", message: "请查看控制台输出")
            }
        }
    }
    
    @objc private func testInterceptor() {
        Task {
            print("=== 测试拦截器 ===")
            UserManager.shared.currentUser = nil
            
            let result = await AppRouter.shared.push(
                path: "/user/profile",
                params: ["userId": "test_user"]
            )
            
            await handleRouteResult(result, operation: "拦截器测试")
        }
    }
    
    @objc private func testDynamicRoute() {
        Task {
            print("=== 测试动态路由 ===")
            
            let dynamicRoute = RouteConfig(
                path: "/dynamic_test",
                handler: { params in
                    let vc = DynamicTestViewController()
                    vc.message = params["message"] as? String ?? "默认消息"
                    return vc
                },
                testParamsBuilder: {
                    return ["message": "这是动态注册的路由！"]
                }
            )
            
            AppRouter.shared.registerRoute(dynamicRoute)
            
            let result = await AppRouter.shared.navigate(
                path: "/dynamic_test",
                params: ["message": "这是动态注册的路由！"]
            )
            
            await handleRouteResult(result, operation: "动态路由")
        }
    }
    
    @objc private func testWebView() {
        Task {
            print("=== 测试 WebView ===")
            let result = await AppRouter.shared.push(
                path: "/webview",
                params: [
                    "url": "https://www.apple.com",
                    "title": "Apple 官网"
                ]
            )
            
            await handleRouteResult(result, operation: "WebView")
        }
    }
    
    @objc private func testSystemBrowser() {
        Task {
            print("=== 测试系统浏览器 ===")
            let result = await AppRouter.shared.navigate(
                path: "/system_browser",
                params: ["url": "https://www.github.com"]
            )
            
            await handleRouteResult(result, operation: "系统浏览器")
        }
    }
    
    @objc private func testAlert() {
        Task {
            print("=== 测试弹窗 ===")
            let result = await AppRouter.shared.navigate(
                path: "/alert",
                params: [
                    "title": "确认操作",
                    "message": "您确定要执行此操作吗？",
                    "cancelTitle": "取消",
                    "confirmTitle": "确定"
                ]
            )
            
            if result.isSuccess, let choice = result.data as? [String: Any] {
                await MainActor.run {
                    let action = choice["action"] as? String ?? "unknown"
                    self.showAlert(
                        title: "用户选择",
                        message: "用户点击了: \(action)"
                    )
                }
            } else {
                await handleRouteResult(result, operation: "弹窗")
            }
        }
    }
    
    @objc private func testGetUserInfo() {
        Task {
            print("=== 测试同步获取用户信息 ===")
            let result = await AppRouter.shared.navigate(
                path: "/getUserInfo",
                params: [:]
            )
            
            await handleRouteResult(result, operation: "获取用户信息")
        }
    }
    
    @objc private func testGetAppConfig() {
        Task {
            print("=== 测试同步获取应用配置 ===")
            let result = await AppRouter.shared.navigate(
                path: "/getAppConfig",
                params: [:]
            )
            
            await handleRouteResult(result, operation: "获取应用配置")
        }
    }
    
    @objc private func testCalculate() {
        Task {
            print("=== 测试同步计算功能 ===")
            let result = await AppRouter.shared.navigate(
                path: "/calculate",
                params: [
                    "a": 10.5,
                    "b": 2.5,
                    "operation": "multiply"
                ]
            )
            
            if result.isSuccess, let data = result.data as? [String: Any] {
                await MainActor.run {
                    self.showAlert(
                        title: "计算结果",
                        message: "\(data["a"] ?? 0) \(data["operation"] ?? "") \(data["b"] ?? 0) = \(data["result"] ?? 0)"
                    )
                }
            } else {
                await handleRouteResult(result, operation: "计算功能")
            }
        }
    }
    
    @objc private func testAsyncFunction() {
        Task {
            print("=== 测试异步API调用 ===")
            let result = await AppRouter.shared.navigate(
                path: "/api/data",
                params: ["page": 1, "size": 5]
            )
            
            if result.isSuccess, let data = result.data {
                print("异步API调用成功: \(data)")
                await MainActor.run {
                    self.showAlert(
                        title: "异步调用成功",
                        message: "获取到数据，查看控制台"
                    )
                }
            } else {
                await handleRouteResult(result, operation: "异步功能调用")
            }
        }
    }
    
    @objc private func testUserList() {
        Task {
            print("=== 测试用户列表异步调用 ===")
            let result = await AppRouter.shared.navigate(
                path: "/user/list",
                params: ["page": 1, "query": "张"]
            )
            
            if result.isSuccess, let data = result.data {
                print("用户列表获取成功: \(data)")
                await MainActor.run {
                    self.showAlert(
                        title: "用户列表",
                        message: "获取到用户数据"
                    )
                }
            } else {
                await handleRouteResult(result, operation: "用户列表调用")
            }
        }
    }
    
    @objc private func runAutomatedTests() {
        Task {
            print("🚀 开始自动化测试所有路由...")
            
            let alert = UIAlertController(
                title: "自动化测试",
                message: "正在测试所有注册的路由...",
                preferredStyle: .alert
            )
            present(alert, animated: true)
            
            let results = await RouterAutomatedTest.shared.runAllTests()
            
            alert.dismiss(animated: true) {
                self.showTestResults(results)
            }
        }
    }
    
    @objc private func testOffAll() {
        Task {
            print("=== 测试offAll，push新页面关闭所有页面 ===")
            let result = await AppRouter.shared.offAll(
                path: "/detail",
                params: ["id": "clean_start", "message": "全新开始的页面"]
            )
            
            await handleRouteResult(result, operation: "关闭所有页面")
        }
    }
    
    @objc private func testRandomRoutes() {
        Task {
            print("=== 测试随机路由调用 ===")
            
            let routes = [
                ("/getUserInfo", [:]),
                ("/getAppConfig", [:]),
                ("/calculate", ["a": Double.random(in: 1...100), "b": Double.random(in: 1...100), "operation": ["add", "subtract", "multiply", "divide"].randomElement()!])
            ]
            
            let randomRoute = routes.randomElement()!
            
            let result = await AppRouter.shared.navigate(
                path: randomRoute.0,
                params: randomRoute.1
            )
            
            await handleRouteResult(result, operation: "随机路由: \(randomRoute.0)")
        }
    }
    
    @objc private func toggleUserStatus() {
        if UserManager.shared.isLoggedIn {
            UserManager.shared.logout()
        } else {
            let user = User(
                id: "user_\(Int.random(in: 1000...9999))",
                name: "测试用户",
                email: "test@example.com"
            )
            UserManager.shared.login(user: user)
        }
        
        statusLabel.text = "当前用户: \(UserManager.shared.isLoggedIn ? UserManager.shared.currentUser!.name : "未登录")"
        
        showAlert(
            title: "用户状态",
            message: UserManager.shared.isLoggedIn ?
                "已登录: \(UserManager.shared.currentUser!.name)" :
                "已登出"
        )
    }
    
    @objc private func showRouteStatus() {
        AppRouter.shared.printRouteStatus()
        
        let registeredModules = RouteRegistry.shared.getRegisteredModules()
        showAlert(
            title: "路由状态",
            message: """
            已注册模块: \(registeredModules.joined(separator: ", "))
            查看控制台获取详细信息
            """
        )
    }
    
    // MARK: - 辅助方法
    
    private func showTestResults(_ results: [RouterAutomatedTest.RouteTestResult]) {
        let stats = RouterAutomatedTest.shared.getTestStatistics()
        
        let alert = UIAlertController(
            title: "自动化测试完成",
            message: """
            总测试数: \(stats.total)
            通过: \(stats.passed) ✅
            失败: \(stats.failed) ❌
            成功率: \(String(format: "%.1f", stats.successRate))%
            
            \(stats.failed > 0 ? "查看控制台获取失败详情" : "所有测试通过！🎉")
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    @MainActor
    private func handleRouteResult(_ result: RouteResult, operation: String) async {
        if result.isSuccess {
            if let data = result.data {
                print("\(operation) 成功，返回数据: \(data)")
                if let dict = data as? [String: Any], dict.count <= 3 {
                    showAlert(
                        title: "\(operation) 成功",
                        message: "返回数据: \(data)"
                    )
                } else {
                    showAlert(
                        title: "\(operation) 成功",
                        message: "操作完成，查看控制台获取详细数据"
                    )
                }
            } else {
                print("\(operation) 成功")
                showAlert(title: "\(operation) 成功", message: "操作完成")
            }
        } else {
            print("\(operation) 失败: \(result.message ?? "未知错误")")
            showAlert(
                title: "\(operation) 失败",
                message: "错误: \(result.message ?? "未知错误")"
            )
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
