//
//  DetailViewController.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit
import SnapKit
import AppRouter_iOS

class DetailViewController: UIViewController {
    
    private let id: String
    private let titleText: String?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let infoLabel = UILabel()
    private let resultLabel = UILabel()
    private let buttonStack = UIStackView()
    
    init(id: String, title: String? = nil) {
        self.id = id
        self.titleText = title
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        print("📄 详情页初始化，ID: \(id), 参数: \(routeParams ?? [:])")
    }
    
    private func setupNavigationBar() {
        self.title = titleText ?? "详情页 - \(id)"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "返回测试",
            style: .plain,
            target: self,
            action: #selector(testReturnData)
        )
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 设置滚动视图
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        
        // 信息标签
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        infoLabel.text = """
        详情页信息:
        ID: \(id)
        标题: \(titleText ?? "无")
        路由参数: \(routeParams?.description ?? "无")
        """
        contentView.addSubview(infoLabel)
        
        // 返回结果标签
        resultLabel.numberOfLines = 0
        resultLabel.textAlignment = .center
        resultLabel.text = "返回结果将显示在这里"
        resultLabel.textColor = .systemGray
        contentView.addSubview(resultLabel)
        
        // 按钮容器
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        contentView.addSubview(buttonStack)
        
        // 创建测试按钮
        let buttons = [
            ("返回空数据", #selector(returnEmpty)),
            ("返回字符串", #selector(returnString)),
            ("返回字典", #selector(returnDictionary)),
            ("返回复杂对象", #selector(returnComplexObject)),
            ("推入新详情页", #selector(pushNewDetail)),
            ("模态展示页面", #selector(presentModal)),
            ("关闭所有回首页", #selector(offAllToHome))
        ]
        
        for (title, selector) in buttons {
            let button = createActionButton(title: title, selector: selector)
            buttonStack.addArrangedSubview(button)
        }
        
        // 布局
        infoLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        resultLabel.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        buttonStack.snp.makeConstraints { make in
            make.top.equalTo(resultLabel.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func createActionButton(title: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 6
        button.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }
    
    // MARK: - 返回数据测试
    
    @objc private func testReturnData() {
        let alert = UIAlertController(title: "选择返回数据", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "成功数据", style: .default) { _ in
            self.returnSuccessData()
        })
        
        alert.addAction(UIAlertAction(title: "失败数据", style: .default) { _ in
            self.returnErrorData()
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func returnEmpty() {
        popRoute()
        updateResultLabel("返回了: nil")
    }
    
    @objc private func returnString() {
        let result = "这是返回的字符串数据 - \(Date())"
        popRoute(result: result)
        updateResultLabel("返回了字符串: \(result)")
    }
    
    @objc private func returnDictionary() {
        let result: [String: Any] = [
            "id": id,
            "timestamp": Date().timeIntervalSince1970,
            "action": "user_click",
            "data": ["key1": "value1", "key2": 123]
        ]
        popRoute(result: result)
        updateResultLabel("返回了字典: \(result)")
    }
    
    @objc private func returnComplexObject() {
        struct ComplexResult: CustomStringConvertible {
            let message: String
            let code: Int
            let data: [String: Any]
            
            var description: String {
                return "ComplexResult(message: \(message), code: \(code), data: \(data))"
            }
        }
        
        let result = ComplexResult(
            message: "操作成功",
            code: 200,
            data: ["items": [1, 2, 3], "total": 3]
        )
        
        popRoute(result: ["complex": result])
        updateResultLabel("返回了复杂对象: \(result)")
    }
    
    private func returnSuccessData() {
        let successData: [String: Any] = [
            "status": "success",
            "message": "操作成功完成",
            "timestamp": Date().timeIntervalSince1970
        ]
        popRoute(result: successData)
        updateResultLabel("返回成功数据: \(successData)")
    }
    
    private func returnErrorData() {
        let errorData: [String: Any] = [
            "status": "error",
            "message": "操作失败",
            "errorCode": 500,
            "timestamp": Date().timeIntervalSince1970
        ]
        popRoute(result: errorData)
        updateResultLabel("返回错误数据: \(errorData)")
    }
    
    // MARK: - 导航测试
    
    @objc private func pushNewDetail() {
        Task {
            let result = await AppRouter.shared.push(
                path: "/detail",
                params: ["id": "nested_\(Int.random(in: 1000...9999))", "title": "嵌套详情页"]
            )
            
            if result.isSuccess {
                updateResultLabel("成功推入新详情页")
            } else {
                updateResultLabel("推入失败: \(result.message ?? "未知错误")")
            }
        }
    }
    
    @objc private func presentModal() {
        Task {
            let result = await AppRouter.shared.present(
                path: "/login",
                params: ["source": "detail"]
            )
            
            if let data = result.data {
                updateResultLabel("模态页面返回: \(data)")
            } else {
                updateResultLabel("模态展示完成")
            }
        }
    }
    
    @objc private func offAllToHome() {
        Task {
            let result = await AppRouter.shared.offAll(path: "/")
            
            if result.isSuccess {
                print("成功关闭所有页面回到首页")
            }
        }
    }
    
    private func updateResultLabel(_ text: String) {
        resultLabel.text = text
        resultLabel.textColor = .systemBlue
    }
    
    deinit {
        print("详情页销毁，ID: \(id)")
    }
}
