# AppRouter-iOS

[![CI Status](https://img.shields.io/travis/郭仁庆/AppRouter-iOS.svg?style=flat)](https://travis-ci.org/郭仁庆/AppRouter-iOS)
[![Version](https://img.shields.io/cocoapods/v/AppRouter-iOS.svg?style=flat)](https://cocoapods.org/pods/AppRouter-iOS)
[![License](https://img.shields.io/cocoapods/l/AppRouter-iOS.svg?style=flat)](https://cocoapods.org/pods/AppRouter-iOS)
[![Platform](https://img.shields.io/cocoapods/p/AppRouter-iOS.svg?style=flat)](https://cocoapods.org/pods/AppRouter-iOS)

# AppRouter 使用说明

AppRouter 是一个基于 Swift 语言的 iOS 路由系统，旨在简化应用内页面跳转和功能调用的管理，提高代码的模块化和可维护性。

## 目录
- [安装指南](#安装指南)
- [快速开始](#快速开始)
- [路由配置](#路由配置)
- [页面路由](#页面路由)
- [功能路由](#功能路由)
- [拦截器](#拦截器)
- [自动化测试](#自动化测试)
- [常见问题](#常见问题)
- [许可证](#许可证)

## 安装指南

### CocoaPods 安装
在你的 `Podfile` 中添加以下内容：
```ruby
pod 'AppRouter', '~> 0.1.0'
```
然后运行：
```bash
pod install
```

### 手动安装
克隆仓库并将 `AppRouter/Classes` 目录下的所有文件添加到你的项目中。

## 快速开始

1. **初始化路由系统**
```swift
// 在 AppDelegate 或 SceneDelegate 中
private func setupRouter(with navigationController: UINavigationController) {
    let routerConfig = AppRouterConfig()
    AppRouter.shared.initialize(
        configurator: routerConfig,
        navigationController: navigationController
    )
    // 设置模态展示样式
    AppRouter.shared.modalPresentationStyle = .pageSheet
    AppRouter.shared.modalTransitionStyle = .coverVertical
    // 注册模块路由
    registerModuleRoutes()
}
```

2. **注册路由**
```swift
// 在自定义的 RouterConfig 中
private func registerDefaultRoutes() {
    let defaultRoutes = [
        // 页面路由
        RouteConfig(
            path: "/home",
            handler: .page { params in
                return HomeViewController()
            }
        ),
        // 功能路由
        RouteConfig(
            path: "/getUserInfo",
            handler: .sync { params in
                return UserManager.shared.currentUser?.toDictionary() ?? ["status": "未登录"]
            }
        )
    ]
    registerRoutes(defaultRoutes)
}
```

3. **使用路由进行页面跳转**
```swift
// 推送页面
Task {
    let result = await AppRouter.shared.push(
        path: "/detail",
        params: ["id": "123", "title": "详情页"]
    )
}

// 模态展示页面
Task {
    let result = await AppRouter.shared.present(
        path: "/login",
        params: ["source": "home"]
    )
}
```

4. **调用功能路由**
```swift
// 调用同步功能
Task {
    let result = await AppRouter.shared.call(
        path: "/calculate",
        params: ["a": 10, "b": 20, "operation": "add"]
    )
}

// 调用异步功能
Task {
    let result = await AppRouter.shared.call(
        path: "/api/data",
        params: ["page": 1, "size": 10]
    )
}
```

## 路由配置

路由配置是通过 `RouteConfig` 类来完成的，每个路由配置包含以下主要属性：

- `path`: 路由路径（如 "/home"、"/user/profile"）
- `handler`: 路由处理方式（页面路由或功能路由）
- `defaultNavigationType`: 默认导航类型（推送或模态）
- `testParamsBuilder`: 测试参数构建器，用于自动化测试
- `skipAutomatedTest`: 是否跳过自动化测试
- `testTimeout`: 测试超时时间

示例：
```swift
RouteConfig(
    path: "/webview",
    handler: .page { params in
        guard let urlString = params["url"] as? String,
              let url = URL(string: urlString) else {
            throw RouteError.missingRequiredParameter("url")
        }
        let webViewController = WebViewController(url: url)
        webViewController.title = params["title"] as? String
        return webViewController
    },
    testParamsBuilder: {
        return [
            "url": "https://www.example.com",
            "title": "示例网页"
        ]
    },
    testTimeout: 15.0
)
```

## 页面路由

页面路由用于导航到应用内的视图控制器，支持两种导航方式：

1. **Push 导航**：将视图控制器推入导航栈
```swift
await AppRouter.shared.push(path: "/detail", params: ["id": "123"])
```

2. **Present 导航**：以模态方式展示视图控制器
```swift
await AppRouter.shared.present(path: "/login", params: ["source": "settings"])
```

## 功能路由

功能路由用于调用特定功能并返回结果，分为同步和异步两种类型：

1. **同步功能路由**：立即返回结果
```swift
RouteConfig(
    path: "/calculate",
    handler: .sync { params in
        let a = params["a"] as? Double ?? 0
        let b = params["b"] as? Double ?? 0
        return ["result": a + b]
    }
)
```

2. **异步功能路由**：用于需要异步处理的操作（如网络请求）
```swift
RouteConfig(
    path: "/api/data",
    handler: .async { params in
        try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟网络请求
        return ["data": "模拟数据"]
    }
)
```

## 拦截器

拦截器可以在路由处理前后执行自定义逻辑，如登录验证、日志记录等：

```swift
// 注册拦截器
private func registerDefaultInterceptors() {
    addInterceptor(LoginInterceptor())
    addInterceptor(LogInterceptor())
}

// 自定义拦截器示例
class LoginInterceptor: RouteInterceptor {
    func intercept(context: RouteCallContext) async -> RouteResult? {
        // 检查是否需要登录
        if context.path.starts(with: "/user") && !UserManager.shared.isLoggedIn {
            // 跳转到登录页
            let loginResult = await AppRouter.shared.present(path: "/login")
            if loginResult.isSuccess {
                return nil // 继续处理原路由
            } else {
                return .failure("需要登录才能访问该页面")
            }
        }
        return nil // 继续处理
    }
}
```

## 自动化测试

AppRouter-iOS 内置了路由自动化测试功能，可以测试所有已注册的路由：

```swift
// 运行所有路由测试
Task {
    let results = await RouterAutomatedTest.shared.runAllTests()
    showTestResults(results)
}

// 显示测试结果
private func showTestResults(_ results: [RouterAutomatedTest.RouteTestResult]) {
    let stats = RouterAutomatedTest.shared.getTestStatistics()
    // 显示测试统计信息...
}
```

测试结果会包含每个路由的测试状态、耗时、错误信息等详细内容，并在控制台输出测试报告。

## 常见问题

1. **如何处理路由参数验证？**

可以在路由处理函数中进行参数验证，使用 `throw RouteError.missingRequiredParameter` 抛出参数缺失错误：

```swift
RouteConfig(
    path: "/detail",
    handler: .page { params in
        guard let id = params["id"] as? String else {
            throw RouteError.missingRequiredParameter("id")
        }
        return DetailViewController(id: id)
    }
)
```

2. **如何获取当前顶层视图控制器？**

可以使用内置的工具方法：
```swift
if let topVC = getTopViewController() {
    // 处理顶层视图控制器
}
```

3. **如何处理路由跳转失败？**

路由操作会返回一个 `RouteResult` 对象，通过该对象可以判断操作是否成功：

```swift
let result = await AppRouter.shared.push(path: "/detail", params: ["id": "123"])
if result.isSuccess {
    print("跳转成功")
} else {
    print("跳转失败: \(result.message ?? "未知错误")")
}
```

## 许可证

AppRouter 基于 MIT 许可证开源，详情请参见 [LICENSE](LICENSE) 文件。
