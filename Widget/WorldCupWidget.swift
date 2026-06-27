import WidgetKit
import SwiftUI
import AppIntents

// 手动刷新按钮的 AppIntent：拉取最新数据并写入缓存，系统随后重载小组件。
struct RefreshIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新比分"
    func perform() async throws -> some IntentResult {
        _ = await WorldCupAPI.fetchSnapshot()   // 拉最新并写入缓存
        WidgetCenter.shared.reloadAllTimelines() // 强制重绘小组件
        return .result()
    }
}

struct WCEntry: TimelineEntry {
    let date: Date
    let snapshot: WorldCupSnapshot
    var rotation: Int = 0   // 小卡无进行中时的轮播索引
    var theme: String = "system"   // 来自菜单栏 App 的本地服务：system/light/dark
}

// 优先从菜单栏 App 的本地服务取「外观 + 最新比分」（快、且数据更新）。
// App 没开 / 端口不通 → nil，调用方回退缓存或远程。
func fetchLocalData() async -> (WorldCupSnapshot, String)? {
    guard let url = URL(string: ThemeServerInfo.endpoint) else { return nil }
    var req = URLRequest(url: url)
    req.timeoutInterval = 2
    req.cachePolicy = .reloadIgnoringLocalCacheData
    guard let (data, _) = try? await URLSession.shared.data(for: req),
          let p = try? JSONDecoder().decode(LocalPayload.self, from: data) else { return nil }
    return (p.snapshot, p.theme)
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WCEntry {
        WCEntry(date: Date(), snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (WCEntry) -> Void) {
        if context.isPreview {
            completion(WCEntry(date: Date(), snapshot: .sample))
            return
        }
        Task {
            if let (s, t) = await fetchLocalData() {
                completion(WCEntry(date: Date(), snapshot: s, theme: t))
            } else {
                let snapshot = await WorldCupAPI.fetchSnapshot()
                completion(WCEntry(date: Date(), snapshot: snapshot, theme: "system"))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WCEntry>) -> Void) {
        Task {
            // 菜单栏刷新后会要求 WidgetKit 重载时间线。这里只复用 5 秒内的缓存
            // （供小组件自身的刷新按钮衔接），其余情况重新联网，避免卡片停留在旧比分。
            let snapshot: WorldCupSnapshot
            let theme: String
            if let (s, t) = await fetchLocalData() {            // 本地优先：快 + 新 + 带外观
                snapshot = s
                theme = t
            } else if let cached = SharedStore.readFresh(maxAge: 5) {
                snapshot = cached
                theme = "system"
            } else {
                snapshot = await WorldCupAPI.fetchSnapshot()
                theme = "system"
            }
            let now = Date()

            // 自适应刷新：进行中→1分钟（菜单栏也会在取到新数据后主动触发重载）；
            // 否则→30分钟，
            // 但若有即将开赛的比赛更早开球，则在其开球后约30秒刷新（待赛→进行中）。
            let hasLive = !snapshot.live.isEmpty
            var span: TimeInterval = hasLive ? 60 : 30 * 60
            if !hasLive, let kickoff = snapshot.upcoming.first?.date {
                let untilKickoff = kickoff.timeIntervalSince(now)
                if untilKickoff > 60, untilKickoff + 30 < span {
                    span = untilKickoff + 30
                }
            }

            // 中/大卡不轮播 → 单帧，最省、重载最快（避免一次性塞入上百帧拖慢外观切换）。
            if context.family != .systemSmall || !snapshot.live.isEmpty {
                completion(Timeline(entries: [WCEntry(date: now, snapshot: snapshot, theme: theme)],
                                    policy: .after(now.addingTimeInterval(span))))
                return
            }

            // 小卡且无进行中 → 轮播（每 15 秒一张），帧数封顶以减小载荷、加快重载。
            let count = max(1, snapshot.smallFeatured.count)
            let step: TimeInterval = 15
            let maxEntries = min(Int(span / step), 20)   // 封顶 20 帧（约 5 分钟），到点再重载
            var entries: [WCEntry] = []
            for i in 0..<max(1, maxEntries) {
                entries.append(WCEntry(date: now.addingTimeInterval(Double(i) * step),
                                       snapshot: snapshot, rotation: i % count, theme: theme))
            }
            let carouselSpan = Double(entries.count) * step
            completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(carouselSpan))))
        }
    }
}

struct WorldCupWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WCEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallView(snapshot: entry.snapshot, rotation: entry.rotation)
        case .systemLarge, .systemExtraLarge:
            LargeView(snapshot: entry.snapshot)
        default:
            MediumView(snapshot: entry.snapshot)
        }
    }
}

// 渲染前据 entry.theme + 系统外观算出"生效深浅",解析成调色板:
// 背景渐变直接用,内容经 \.wcPalette 环境下发。每套外观各算各的,不共享可变状态 → 不会串台。
// 外观来自菜单栏 App 的本地服务（entry.theme）：light/dark 强制,否则跟随系统 @Environment(\.colorScheme)。
struct ThemedContainer: View {
    let entry: WCEntry
    @Environment(\.colorScheme) private var systemScheme

    var body: some View {
        let dark: Bool
        switch entry.theme {
        case "light": dark = false
        case "dark":  dark = true
        default:      dark = (systemScheme == .dark)   // system / 取不到 → 跟随系统
        }
        let pal = WCPalette.make(dark: dark)
        return WorldCupWidgetEntryView(entry: entry)
            .environment(\.wcPalette, pal)
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [pal.bgTop, pal.bgBottom],
                    startPoint: .top, endPoint: .bottom
                )
            }
    }
}

struct WorldCupWidget: Widget {
    let kind = "WorldCupWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ThemedContainer(entry: entry)
        }
        .configurationDisplayName("2026世界杯摸鱼看球小组件")
        .description("在 Mac 桌面悄悄查看 2026 世界杯实时比分、已完赛和即将开赛的比赛。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
