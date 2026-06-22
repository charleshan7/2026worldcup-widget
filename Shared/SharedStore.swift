import Foundation

// 小组件外观偏好：跟随系统 / 强制白底 / 强制黑底
enum WidgetTheme: String, CaseIterable {
    case system, light, dark
}

// 菜单栏 App 本地服务的地址（App 与组件共用）：一次返回「外观 + 最新比分」。
enum ThemeServerInfo {
    static let port: UInt16 = 47633
    static var endpoint: String { "http://127.0.0.1:\(port)/data" }
}

// 本地服务的载荷：菜单栏 App 把当前外观与最新赛况一起供给桌面组件，
// 组件本地取数既快又新（App 每 30 秒刷新），免去每次远程拉取的延迟。
struct LocalPayload: Codable {
    let theme: String
    let snapshot: WorldCupSnapshot
}

// 菜单栏面板的外观偏好（仅 App 进程使用，控制下拉面板 NSApp.appearance）。
// 用 App 自己的 UserDefaults.standard 持久化即可——组件被沙盒隔离读不到，故不走共享容器。
enum ThemePref {
    private static let key = "panelAppearance"
    static func get() -> WidgetTheme {
        WidgetTheme(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .system
    }
    static func set(_ theme: WidgetTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: key)
    }
}

// 本地缓存：保存上次成功取到的赛况快照。
// 用途：① 网络/配置失败时回退展示上次数据（避免误显示空）；
//       ② 小组件手动刷新后短暂复用，避免紧接着重复请求。
// 说明：进程内缓存（App 与小组件各存各的）。要做「菜单栏 App ↔ 小组件」跨进程共享，
//       需 App Group 权限——而它需要 Apple ID 开发者团队/描述文件，当前 ad-hoc 签名用不了。
enum SharedStore {
    private static let key = "lastSnapshot"
    private static let defaults = UserDefaults.standard

    static func write(_ snapshot: WorldCupSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    static func read() -> WorldCupSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WorldCupSnapshot.self, from: data)
    }

    /// 读取且未过期（默认 5 秒内）才返回。
    static func readFresh(maxAge: TimeInterval = 5) -> WorldCupSnapshot? {
        guard let s = read() else { return nil }
        return Date().timeIntervalSince(s.updated) <= maxAge ? s : nil
    }
}
