//
//  RouterAutomatedTest.swift
//  Runner
//
//  Created by edy on 2025/10/16.
//

import UIKit

/// 路由自动化测试类
public class RouterAutomatedTest {
    
    public static let shared = RouterAutomatedTest()
    private init() {}
    
    private var testResults: [RouteTestResult] = []
    
    /// 路由测试结果
    public struct RouteTestResult {
        public let path: String
        public let type: RouteType
        public let isSuccess: Bool
        public let duration: TimeInterval
        public let errorMessage: String?
        public let testData: Any?
        public let paramSource: ParamSource
        public let timeout: TimeInterval
        
        public var statusEmoji: String {
            return isSuccess ? "✅" : "❌"
        }
    }
    
    /// 参数来源
    public enum ParamSource {
        case customTestAndDefault
        case customTestOnly
        case defaultOnly
        case genericOnly
        
        var description: String {
            switch self {
            case .customTestAndDefault: return "测试+默认参数"
            case .customTestOnly: return "测试参数"
            case .defaultOnly: return "默认+通用参数"
            case .genericOnly: return "通用参数"
            }
        }
        
        var emoji: String {
            switch self {
            case .customTestAndDefault: return "📋🔧"
            case .customTestOnly: return "📋"
            case .defaultOnly: return "🔧"
            case .genericOnly: return "⚙️"
            }
        }
    }
    
    /// 启动自动化测试
    public func runAllTests() async -> [RouteTestResult] {
        print("""
        🧪 ===================================
        🧪 开始路由自动化测试
        🧪 ===================================
        """)
        
        testResults.removeAll()
        
        guard let configurator = await AppRouter.shared.configurator else {
            print("❌ 路由未初始化，无法进行测试")
            return []
        }
        
        let routes = configurator.routes
        print("🧪 发现 \(routes.count) 个路由需要测试")
        
        let testableRoutes = routes.filter { !$0.skipAutomatedTest }
        let skippedRoutes = routes.filter { $0.skipAutomatedTest }
        
        if !skippedRoutes.isEmpty {
            print("🧪 跳过测试的路由: \(skippedRoutes.count) 个")
            for route in skippedRoutes {
                print("   ⏭️ \(route.path)")
            }
        }
        
        print("🧪 实际测试路由: \(testableRoutes.count) 个")
        
        for route in testableRoutes {
            await testRoute(route)
        }
        
        await generateTestReport()
        
        return testResults
    }
    
    /// 测试特定路由
    private func testRoute(_ route: RouteConfig) async -> RouteTestResult {
        let startTime = Date()
        var errorMessage: String?
        var isSuccess = false
        var testData: Any?
        let paramSource = getParamSource(for: route)
        
        print("🧪 测试路由: \(route.path) (\(route.type))")
        print("   \(paramSource.emoji) 参数来源: \(paramSource.description)")
        
        do {
            let testParams = route.getTestParams()
            let timeout = route.testTimeout
            
            let result = await withTimeout(seconds: timeout) {
                return await AppRouter.shared.navigate(path: route.path, params: testParams)
            }
            
            if let routeResult = result {
                isSuccess = routeResult.isSuccess
                testData = routeResult.data
                if !routeResult.isSuccess {
                    errorMessage = routeResult.message
                }
                
                if isSuccess && route.isPageRoute {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    await MainActor.run {
                        AppRouter.shared.pop()
                    }
                }
            } else {
                errorMessage = "测试超时 (超过 \(timeout) 秒)"
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let testResult = RouteTestResult(
            path: route.path,
            type: route.type,
            isSuccess: isSuccess,
            duration: duration,
            errorMessage: errorMessage,
            testData: testData,
            paramSource: paramSource,
            timeout: route.testTimeout
        )
        
        testResults.append(testResult)
        
        let timeoutInfo = route.testTimeout != 10.0 ? " (超时: \(route.testTimeout)s)" : ""
        print("   \(testResult.statusEmoji) \(route.path) - \(duration.formattedSeconds)\(timeoutInfo)")
        
        return testResult
    }
    
    /// 带超时的异步操作
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T?) async -> T? {
        return await withTaskGroup(of: T?.self) { group in
            group.addTask {
                return await operation()
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            
            let result = await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    /// 获取参数来源
    private func getParamSource(for route: RouteConfig) -> ParamSource {
        let hasDefault = route.defaultParamsBuilder != nil
        let hasTest = route.testParamsBuilder != nil
        
        if hasTest && hasDefault {
            return .customTestAndDefault
        } else if hasTest {
            return .customTestOnly
        } else if hasDefault {
            return .defaultOnly
        } else {
            return .genericOnly
        }
    }
    
    /// 生成测试报告
    private func generateTestReport() async {
        let totalTests = testResults.count
        let passedTests = testResults.filter { $0.isSuccess }.count
        let failedTests = totalTests - passedTests
        let successRate = totalTests > 0 ? Double(passedTests) / Double(totalTests) * 100 : 0
        
        let totalDuration = testResults.reduce(0) { $0 + $1.duration }
        let avgDuration = totalTests > 0 ? totalDuration / Double(totalTests) : 0
        
        var sourceStats: [ParamSource: (total: Int, passed: Int)] = [:]
        for result in testResults {
            var stat = sourceStats[result.paramSource] ?? (0, 0)
            stat.total += 1
            if result.isSuccess {
                stat.passed += 1
            }
            sourceStats[result.paramSource] = stat
        }
        
        print("""
        
        📊 ===================================
        📊 路由自动化测试报告
        📊 ===================================
        📊 总测试数: \(totalTests)
        📊 通过: \(passedTests) ✅
        📊 失败: \(failedTests) ❌
        📊 成功率: \(String(format: "%.1f", successRate))%
        📊 总耗时: \(totalDuration.formattedSeconds)
        📊 平均耗时: \(avgDuration.formattedSeconds)
        """)
        
        print("📊 参数来源成功率:")
        for (source, stat) in sourceStats.sorted(by: { $0.key.description < $1.key.description }) {
            let rate = stat.total > 0 ? Double(stat.passed) / Double(stat.total) * 100 : 0
            print("   \(source.emoji) \(source.description): \(stat.passed)/\(stat.total) (\(String(format: "%.1f", rate))%)")
        }
        
        let failedResults = testResults.filter { !$0.isSuccess }
        if !failedResults.isEmpty {
            print("""
            📋 ===================================
            📋 失败详情
            📋 ===================================
            """)
            for result in failedResults {
                print("""
                ❌ \(result.path)
                   类型: \(result.type)
                   错误: \(result.errorMessage ?? "未知错误")
                   耗时: \(result.duration.formattedSeconds)
                """)
            }
        }
        
        let slowResults = testResults.filter { $0.duration > 1.0 }
        if !slowResults.isEmpty {
            print("""
            ⚡️ ===================================
            ⚡️ 性能警告 (耗时 > 1秒)
            ⚡️ ===================================
            """)
            for result in slowResults.sorted(by: { $0.duration > $1.duration }) {
                print("   ⚠️ \(result.path) - \(result.duration.formattedSeconds)")
            }
        }
        
        print("""
        🎯 ===================================
        🎯 测试完成
        🎯 ===================================
        """)
    }
    
    /// 获取测试统计信息
    public func getTestStatistics() -> (total: Int, passed: Int, failed: Int, successRate: Double) {
        let total = testResults.count
        let passed = testResults.filter { $0.isSuccess }.count
        let failed = total - passed
        let successRate = total > 0 ? Double(passed) / Double(total) * 100 : 0
        
        return (total, passed, failed, successRate)
    }
}

// MARK: - 扩展
extension TimeInterval {
    var formattedSeconds: String {
        return String(format: "%.2fs", self)
    }
}
