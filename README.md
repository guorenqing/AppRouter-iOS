# iOSAppRouter - iOS 路由框架

![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

一个功能强大、类型安全的 iOS 路由框架，支持页面导航、功能调用、拦截器、自动化测试等特性。

## 🌟 特性

- 🚀 **多类型路由** - 页面路由、同步功能、异步功能
- 🛡️ **类型安全** - 完整的 Swift 类型系统支持
- 🔒 **线程安全** - 内置并发控制和线程安全保护
- 🎯 **智能导航** - Push、Modal、Replace 等多种导航方式
- 🔄 **拦截器系统** - 支持重定向、替换、拒绝等操作
- 🧪 **自动化测试** - 内置完整的路由测试框架
- 📦 **模块化** - 支持模块化路由注册
- 💾 **缓存系统** - 智能缓存和并发控制
- 📊 **状态监控** - 实时路由状态追踪

## 📋 要求

- iOS 13.0+
- Swift 5.0+
- Xcode 14.0+

## 🚀 安装

### Swift Package Manager

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/guorenqing/iOSAppRouter.git", from: "0.1.0")
]
```

### CocoaPods

在 `Podfile` 中添加：

```ruby
pod 'iOSAppRouter', '~> 0.1.0'
```

## 🏗️ 快速开始

### 1. 基础配置

在 `AppDelegate` 中初始化路由系统：

```swift
import iOSAppRouter

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 初始化路由系统
        setupRouter()
        return true
    }
    
    private func setupRouter() {
        let routerConfig = AppRouterConfig()
        
        AppRouter.shared.initialize(
            configurator: routerConfig,
            navigationController: navigationController
        )
        
        // 设置模态展示样式
        AppRouter.shared.modalPresentationStyle = .pageSheet
        AppRouter.shared.modalTransitionStyle = .coverVertical
        
        print("✅ 路由系统初始化完成")
    }
}
```

### 2. 定义路由

创建路由配置：

```swift
// 页面路由
let detailRoute = RouteConfig(
    path: "/detail",
    handler: .page { params in
        let id = params["id"] as? String ?? ""
        let title = params["title"] as? String
        return DetailViewController(id: id, title: title)
    },
    defaultNavigationType: .push,
    testParamsBuilder: {
        return ["id": "test_123", "title": "测试详情页"]
    }
)

// 同步功能路由
let getUserInfoRoute = RouteConfig(
    path: "/getUserInfo",
    handler: .sync { params in
        return UserManager.shared.currentUser?.toDictionary() ?? ["status": "未登录"]
    }
)

// 异步功能路由
let apiDataRoute = RouteConfig(
    path: "/api/data",
    handler: .async { params in
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return ["data": ["item1", "item2"], "page": 1]
    },
    enableCaching: true,
    cacheTimeout: 60.0
)
```

### 3. 注册路由

#### 方式一：直接注册
```swift
AppRouter.shared.registerRoute(detailRoute)
AppRouter.shared.registerRoutes([getUserInfoRoute, apiDataRoute])
```

#### 方式二：模块化注册
```swift
// 创建模块注册器
class UserModuleRouteRegistrar: ModuleRouteRegistrar {
    func registerRoutes(to configurator: RouterConfigurator) {
        let routes = [
            RouteConfig(path: "/user/profile", handler: .page { _ in
                return UserProfileViewController()
            }),
            RouteConfig(path: "/user/settings", handler: .page { _ in
                return UserSettingsViewController()
            })
        ]
        configurator.registerRoutes(routes)
    }
}

// 注册模块
let userModule = UserModuleRouteRegistrar()
RouteRegistry.shared.registerModule(userModule, identifier: "user_module")
```

## 🎯 使用示例

### 基本导航

```swift
// Push 导航
Task {
    let result = await AppRouter.shared.push(
        path: "/detail",
        params: ["id": "123", "title": "详情页"]
    )
    
    if result.isSuccess {
        print("导航成功")
    } else {
        print("导航失败: \(result.message ?? "未知错误")")
    }
}

// Modal 展示
Task {
    let result = await AppRouter.shared.present(
        path: "/login",
        params: ["source": "home"]
    )
}

// 替换当前页
Task {
    let result = await AppRouter.shared.off(
        path: "/newPage",
        params: ["message": "替换当前页面"]
    )
}

// 关闭所有页面并跳转
Task {
    let result = await AppRouter.shared.offAll(
        path: "/home",
        params: [:]
    )
}
```

### 功能调用

```swift
// 同步功能调用
Task {
    let result = await AppRouter.shared.navigate(
        path: "/getUserInfo",
        params: [:]
    )
    
    if let userInfo = result.data as? [String: Any] {
        print("用户信息: \(userInfo)")
    }
}

// 异步功能调用
Task {
    let result = await AppRouter.shared.navigate(
        path: "/api/data",
        params: ["page": 1, "size": 10]
    )
    
    if let data = result.data {
        print("API数据: \(data)")
    }
}
```

### 页面返回数据

```swift
class DetailViewController: UIViewController {
    
    @objc private func closeWithData() {
        let result: [String: Any] = [
            "selectedItem": "item123",
            "action": "confirm",
            "timestamp": Date().timeIntervalSince1970
        ]
        popRoute(result: result)
    }
    
    @objc private func closeWithoutData() {
        popRoute() // 返回 nil
    }
}

// 在调用方接收返回数据
Task {
    let result = await AppRouter.shared.push(path: "/detail", params: [:])
    
    if let data = result.data {
        print("页面返回数据: \(data)")
    }
}
```

## 🔧 高级功能

### 拦截器使用

```swift
// 登录拦截器
public class LoginInterceptor: RouteInterceptor {
    public func intercept(path: String, params: [String: Any]?) async -> InterceptorResult {
        let needLoginRoutes = ["/user/profile", "/user/settings", "/payment"]
        
        if needLoginRoutes.contains(path) && !UserManager.shared.isLoggedIn {
            print("🔐 需要登录，重定向到登录页")
            return .redirect(RouteConfig(
                path: "/login",
                handler: { params in LoginViewController() },
                defaultNavigationType: .modal
            ))
        }
        return .continue
    }
}

// 日志拦截器
public class LogInterceptor: RouteInterceptor {
    public func intercept(path: String, params: [String: Any]?) async -> InterceptorResult {
        print("""
        🚀 路由跳转:
          路径: \(path)
          参数: \(params ?? [:])
          时间: \(Date())
        """)
        return .continue
    }
}

// 注册拦截器
routerConfig.addInterceptor(LogInterceptor())
routerConfig.addInterceptor(LoginInterceptor())
```

### 自动化测试

```swift
// 运行所有路由测试
Task {
    let results = await RouterAutomatedTest.shared.runAllTests()
    
    let stats = RouterAutomatedTest.shared.getTestStatistics()
    print("测试完成: \(stats.passed)/\(stats.total) 通过")
}

// 测试特定路由
Task {
    let route = RouteConfig(
        path: "/test",
        handler: .sync { params in
            return ["status": "success", "data": params]
        }
    )
    
    let result = await RouterAutomatedTest.shared.testRoute(route)
    print("测试结果: \(result.isSuccess ? "成功" : "失败")")
}
```

### 动态路由管理

```swift
// 动态添加路由
let dynamicRoute = RouteConfig(
    path: "/dynamic",
    handler: .page { params in
        return DynamicViewController()
    }
)
AppRouter.shared.registerRoute(dynamicRoute)

// 检查路由是否存在
if AppRouter.shared.containsRoute(for: "/detail") {
    print("路由已注册")
}

// 移除路由
AppRouter.shared.removeRoute(for: "/old-route")
```

### 状态监控

```swift
// 打印路由状态
AppRouter.shared.printRouteStatus()

// 获取活跃调用
let activeCalls = AppRouter.shared.getActiveCalls()
print("当前活跃调用: \(activeCalls.count)")

// 取消特定调用
if let firstCall = activeCalls.first {
    AppRouter.shared.cancelCall(firstCall.id)
}

// 取消所有调用
AppRouter.shared.cancelAllCalls()
```

## 📚 API 参考

### 路由类型

- `RouteType.page` - 页面路由
- `RouteType.actionSync` - 同步功能路由  
- `RouteType.actionAsync` - 异步功能路由

### 导航类型

- `NavigationType.push` - 推入导航栈
- `NavigationType.modal` - 模态展示
- `NavigationType.replaceCurrent` - 替换当前页面
- `NavigationType.replaceAll` - 替换所有页面
- `NavigationType.none` - 非页面导航

### 拦截器结果

- `.continue` - 继续执行原路由
- `.redirect(RouteConfig)` - 重定向到新路由
- `.replace(RouteConfig)` - 替换原路由
- `.reject(Error)` - 拒绝并终止

## 🔍 调试技巧

### 查看路由状态

```swift
// 在需要的地方调用
AppRouter.shared.printRouteStatus()

// 输出示例：
// === 路由状态 ===
// 活跃调用数量: 2
// 已注册路由数量: 15
// 调用ID: A1B2C3D4, 类型: 页面, 路径: /detail
// ===============
```

### 启用详细日志

```swift
// 添加日志拦截器
routerConfig.addInterceptor(LogInterceptor())
```

## 🐛 故障排除

### 常见问题

1. **路由未找到**
   - 检查路径是否正确（必须以 `/` 开头）
   - 确认路由已注册
   - 检查路径大小写

2. **导航控制器未设置**
   - 在初始化时设置导航控制器
   - 确认 `navigationController` 不为 nil

3. **拦截器循环重定向**
   - 检查重定向逻辑，避免无限循环
   - 设置最大重定向深度

4. **内存泄漏**
   - 使用弱引用避免循环引用
   - 及时取消不需要的路由调用

### 错误处理

```swift
do {
    let result = await AppRouter.shared.push(path: "/detail", params: [:])
    
    if !result.isSuccess {
        // 处理业务错误
        showErrorAlert(message: result.message ?? "未知错误")
    }
} catch {
    // 处理系统错误
    print("路由调用失败: \(error)")
}
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 📞 支持

如有问题，请通过以下方式联系：

- 提交 [Issue](https://github.com/guorenqing/iOSAppRouter/issues)
- 发送邮件：guorenqing@sina.com

---

**AppRouter** - 让 iOS 路由变得更简单！ 🚀
