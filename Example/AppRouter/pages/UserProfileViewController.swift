//
//  UserProfileViewController.swift.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit
import SnapKit
import iOSAppRouter

class UserProfileViewController: UIViewController {
    
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        print("用户详情页初始化，用户ID: \(userId)")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemPurple
        
        let titleLabel = UILabel()
        titleLabel.text = "用户详情页"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        let userLabel = UILabel()
        userLabel.text = "用户ID: \(userId)"
        userLabel.textColor = .white
        userLabel.font = .systemFont(ofSize: 18)
        userLabel.textAlignment = .center
        view.addSubview(userLabel)
        
        let closeButton = UIButton()
        closeButton.setTitle("关闭", for: .normal)
        closeButton.backgroundColor = .white
        closeButton.setTitleColor(.systemPurple, for: .normal)
        closeButton.layer.cornerRadius = 8
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(closeButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(50)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        userLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(userLabel.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(44)
        }
    }
    
    @objc private func close() {
        let result: [String: Any] = [
            "userId": userId,
            "action": "view_profile",
            "timestamp": Date().timeIntervalSince1970
        ]
        popRoute(result: result)
    }
}
