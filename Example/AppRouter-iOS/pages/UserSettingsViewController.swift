//
//  UserSettingsViewController.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit
import SnapKit
import AppRouter_iOS

class UserSettingsViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    // Header
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.text = "John Appleseed"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "john.appleseed@example.com"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    // Settings Sections
    private let accountSectionView: SettingsSectionView = {
        let view = SettingsSectionView()
        view.title = "账户设置"
        return view
    }()
    
    private let notificationSectionView: SettingsSectionView = {
        let view = SettingsSectionView()
        view.title = "通知设置"
        return view
    }()
    
    private let privacySectionView: SettingsSectionView = {
        let view = SettingsSectionView()
        view.title = "隐私与安全"
        return view
    }()
    
    private let aboutSectionView: SettingsSectionView = {
        let view = SettingsSectionView()
        view.title = "关于"
        return view
    }()
    
    // Buttons
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("退出登录", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = .systemRed.withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "设置"
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Header
        contentView.addSubview(headerView)
        headerView.addSubview(avatarImageView)
        headerView.addSubview(userNameLabel)
        headerView.addSubview(emailLabel)
        
        // Settings sections
        contentView.addSubview(accountSectionView)
        contentView.addSubview(notificationSectionView)
        contentView.addSubview(privacySectionView)
        contentView.addSubview(aboutSectionView)
        
        // Buttons
        contentView.addSubview(logoutButton)
        
        // Add some sample items to sections
        setupSampleData()
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        
        // Header constraints
        headerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(180)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.width.height.equalTo(80)
        }
        
        userNameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        emailLabel.snp.makeConstraints { make in
            make.top.equalTo(userNameLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // Settings sections constraints
        accountSectionView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        notificationSectionView.snp.makeConstraints { make in
            make.top.equalTo(accountSectionView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        privacySectionView.snp.makeConstraints { make in
            make.top.equalTo(notificationSectionView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        aboutSectionView.snp.makeConstraints { make in
            make.top.equalTo(privacySectionView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        logoutButton.snp.makeConstraints { make in
            make.top.equalTo(aboutSectionView.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-30)
        }
    }
    
    private func setupActions() {
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        
        // Add tap gestures to sections
        let accountTap = UITapGestureRecognizer(target: self, action: #selector(accountSectionTapped))
        accountSectionView.addGestureRecognizer(accountTap)
        
        let notificationTap = UITapGestureRecognizer(target: self, action: #selector(notificationSectionTapped))
        notificationSectionView.addGestureRecognizer(notificationTap)
        
        let privacyTap = UITapGestureRecognizer(target: self, action: #selector(privacySectionTapped))
        privacySectionView.addGestureRecognizer(privacyTap)
        
        let aboutTap = UITapGestureRecognizer(target: self, action: #selector(aboutSectionTapped))
        aboutSectionView.addGestureRecognizer(aboutTap)
    }
    
    private func setupSampleData() {
        accountSectionView.addItem(title: "编辑资料", subtitle: "修改个人信息")
        accountSectionView.addItem(title: "修改密码", subtitle: "更新登录密码")
        accountSectionView.addItem(title: "绑定手机", subtitle: "已绑定 +86 138****1234")
        
        notificationSectionView.addItem(title: "推送通知", subtitle: "开启", hasSwitch: true, isSwitchOn: true)
        notificationSectionView.addItem(title: "声音提醒", subtitle: "关闭", hasSwitch: true, isSwitchOn: false)
        notificationSectionView.addItem(title: "振动提醒", subtitle: "开启", hasSwitch: true, isSwitchOn: true)
        
        privacySectionView.addItem(title: "隐私设置", subtitle: "管理隐私选项")
        privacySectionView.addItem(title: "位置服务", subtitle: "仅使用时允许")
        privacySectionView.addItem(title: "数据同步", subtitle: "WiFi下自动同步")
        
        aboutSectionView.addItem(title: "版本信息", subtitle: "v1.0.0")
        aboutSectionView.addItem(title: "用户协议", subtitle: "")
        aboutSectionView.addItem(title: "隐私政策", subtitle: "")
    }
    
    // MARK: - Actions
    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "退出登录",
                                    message: "确定要退出登录吗？",
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { _ in
            print("用户退出登录")
            // 处理退出登录逻辑
        }))
        present(alert, animated: true)
    }
    
    @objc private func accountSectionTapped() {
        print("账户设置被点击")
    }
    
    @objc private func notificationSectionTapped() {
        print("通知设置被点击")
    }
    
    @objc private func privacySectionTapped() {
        print("隐私与安全被点击")
    }
    
    @objc private func aboutSectionTapped() {
        print("关于被点击")
    }
}

// MARK: - Settings Section View
class SettingsSectionView: UIView {
    
    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemGray
        return label
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowRadius = 2
        view.layer.shadowOpacity = 0.05
        return view
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(containerView)
        containerView.addSubview(stackView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(8)
        }
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func addItem(title: String, subtitle: String = "", hasSwitch: Bool = false, isSwitchOn: Bool = false) {
        let itemView = SettingsItemView()
        itemView.configure(title: title, subtitle: subtitle, hasSwitch: hasSwitch, isSwitchOn: isSwitchOn)
        stackView.addArrangedSubview(itemView)
        
        // Add separator for all but last item
        if stackView.arrangedSubviews.count > 1 {
            let previousItem = stackView.arrangedSubviews[stackView.arrangedSubviews.count - 2]
            if let previousSettingsItem = previousItem as? SettingsItemView {
                previousSettingsItem.showSeparator()
            }
        }
    }
}

// MARK: - Settings Item View
class SettingsItemView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .systemGray
        return label
    }()
    
    private let accessoryImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let switchControl: UISwitch = {
        let switchControl = UISwitch()
        return switchControl
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        view.isHidden = true
        return view
    }()
    
    private var labelsStackView: UIStackView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        labelsStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 2
        
        addSubview(labelsStackView)
        addSubview(accessoryImageView)
        addSubview(switchControl)
        addSubview(separatorView)
        
        labelsStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(accessoryImageView.snp.leading).offset(-8)
        }
        
        accessoryImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        switchControl.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        separatorView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        // Set fixed height
        snp.makeConstraints { make in
            make.height.equalTo(60)
        }
    }
    
    func configure(title: String, subtitle: String, hasSwitch: Bool = false, isSwitchOn: Bool = false) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle.isEmpty
        
        accessoryImageView.isHidden = hasSwitch
        switchControl.isHidden = !hasSwitch
        switchControl.isOn = isSwitchOn
    }
    
    func showSeparator() {
        separatorView.isHidden = false
    }
}

// MARK: - Usage Example
// 在你的 AppDelegate 或 SceneDelegate 中使用：
/*
let settingsVC = UserSettingsViewController()
let navigationController = UINavigationController(rootViewController: settingsVC)
window?.rootViewController = navigationController
*/
