//
//  WebViewController.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit
import WebKit
import SnapKit
import AppRouter_iOS

class WebViewController: UIViewController {
    
    private let url: URL
    private let webView = WKWebView()
    private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .large)
    
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadWebPage()
        print("WebView 初始化，URL: \(url)")
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        webView.navigationDelegate = self
        view.addSubview(webView)
        
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        webView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func loadWebPage() {
        activityIndicator.startAnimating()
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        title = webView.title ?? "WebView"
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showAlert(title: "加载失败", message: error.localizedDescription)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
