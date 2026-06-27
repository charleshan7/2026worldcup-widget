import SwiftUI
import WidgetKit
import AppIntents

// 配色按"生效深浅"解析成一张调色板:浅色(白天)/深色(夜间) 各一套。
// 由 ThemedContainer 据 entry.theme + 系统外观算出 → 背景直接用、内容经环境(\.wcPalette)下发。
// 不用全局可变量:WidgetKit 会同时预渲染浅/深两套,共用全局会串台,导致"深底配浅字看不清"。
private func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color {
    Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
}

struct WCPalette {
    let text, muted, dim, green, amber, red, gold, bgTop, bgBottom: Color
    static func make(dark: Bool) -> WCPalette {
        dark
        ? WCPalette(text: rgb(0.91, 0.92, 0.95), muted: rgb(0.58, 0.60, 0.66), dim: rgb(0.44, 0.46, 0.52),
                    green: rgb(0.24, 0.86, 0.59), amber: rgb(1.0, 0.82, 0.40), red: rgb(1.0, 0.33, 0.44),
                    gold: rgb(0.93, 0.76, 0.38), bgTop: rgb(0.10, 0.11, 0.16), bgBottom: rgb(0.05, 0.06, 0.09))
        : WCPalette(text: rgb(0.11, 0.12, 0.15), muted: rgb(0.40, 0.42, 0.47), dim: rgb(0.55, 0.57, 0.62),
                    green: rgb(0.09, 0.60, 0.39), amber: rgb(0.82, 0.52, 0.06), red: rgb(0.84, 0.16, 0.27),
                    gold: rgb(0.70, 0.53, 0.18), bgTop: rgb(1.0, 1.0, 1.0), bgBottom: rgb(0.94, 0.95, 0.97))
    }
}

private struct WCPaletteKey: EnvironmentKey {
    static let defaultValue = WCPalette.make(dark: true)
}
extension EnvironmentValues {
    var wcPalette: WCPalette {
        get { self[WCPaletteKey.self] }
        set { self[WCPaletteKey.self] = newValue }
    }
}

// MARK: - 区块标题

struct SectionTitle: View {
    @Environment(\.wcPalette) private var wc
    let text: String
    let color: Color
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(color)
                .frame(width: 3, height: 12)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(wc.muted)
        }
    }
}

// MARK: - 一队（国旗 + 名字）

struct TeamLabel: View {
    @Environment(\.wcPalette) private var wc
    let name: String
    let trailing: Bool   // true = 靠右贴近比分（主队）
    let nameSize: CGFloat

    var body: some View {
        let info = Teams.info(name)
        HStack(spacing: 5) {
            if trailing { Spacer(minLength: 0) }
            if !trailing { Text(info.flag).font(.system(size: nameSize + 2)) }
            Text(info.zh)
                .font(.system(size: nameSize))
                .foregroundStyle(wc.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if trailing { Text(info.flag).font(.system(size: nameSize + 2)) }
            if !trailing { Spacer(minLength: 0) }
        }
    }
}

private func scoreText(_ m: Match) -> String { "\(m.homeScore ?? 0) : \(m.awayScore ?? 0)" }

// MARK: - 排布 B：居中对阵式（小/中号用）

struct CenteredMatchRow: View {
    @Environment(\.wcPalette) private var wc
    let m: Match
    let upcoming: Bool
    var nameSize: CGFloat = 12.5

    var body: some View {
        VStack(spacing: 2) {
            Text(WCFormat.metaTime(m, withCity: true))   // 时间 · 组别 · 球场（城市）
                .font(.system(size: 11))
                .foregroundStyle(wc.muted)
                .lineLimit(1).minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 6) {
                TeamLabel(name: m.home, trailing: true, nameSize: nameSize)
                Text(upcoming ? "VS" : scoreText(m))
                    .font(.system(size: upcoming ? 12 : 16, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(upcoming ? wc.amber : wc.text)
                    .frame(width: 52)
                TeamLabel(name: m.away, trailing: false, nameSize: nameSize)
            }
        }
    }
}

// MARK: - 比赛预告（组别/球场在上，醒目开球时间在中间）

struct UpcomingMatchRow: View {
    @Environment(\.wcPalette) private var wc
    let m: Match
    var nameSize: CGFloat = 12.5

    var body: some View {
        let home = Teams.info(m.home), away = Teams.info(m.away)
        VStack(spacing: 2) {
            Text(WCFormat.metaVenue(m))
                .font(.system(size: 11))
                .foregroundStyle(wc.muted)
                .lineLimit(1).minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 6) {
                HStack(spacing: 3) {
                    Spacer(minLength: 0)
                    Text(home.zh).lineLimit(1).minimumScaleFactor(0.7)
                    Text(home.flag).font(.system(size: nameSize + 2))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                Text(WCFormat.clock(m.date))
                    .font(.system(size: 14)).monospacedDigit()
                    .foregroundStyle(wc.text)
                    .frame(width: 50)

                HStack(spacing: 3) {
                    Text(away.flag).font(.system(size: nameSize + 2))
                    Text(away.zh).lineLimit(1).minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: nameSize))
            .foregroundStyle(wc.text)
        }
    }
}

// MARK: - 排布 C：左对齐紧凑式（大号用）

// MARK: - 顶部标题（大力神杯图标）

struct WidgetHeader: View {
    @Environment(\.wcPalette) private var wc
    let updated: Date
    var compact: Bool = false
    var body: some View {
        HStack(spacing: 6) {
            Image("WC26Mark")
                .resizable()
                .scaledToFit()
                .frame(height: compact ? 17 : 20)
            Text("2026 美加墨世界杯")
                .font(.system(size: compact ? 13 : 14.5, weight: .semibold))
                .foregroundStyle(wc.text)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            Button(intent: RefreshIntent()) {   // 中/大号：手动刷新
                HStack(spacing: 3) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 9))
                    Text(WCFormat.clock(updated)).font(.system(size: 10))
                }
                .foregroundStyle(wc.muted)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Large（排布 C）

struct LargeView: View {
    @Environment(\.wcPalette) private var wc
    let snapshot: WorldCupSnapshot

    @ViewBuilder
    private func rows(_ arr: [Match], upcoming: Bool) -> some View {
        if upcoming {
            ForEach(arr) { UpcomingMatchRow(m: $0, nameSize: 11.5) }
        } else {
            ForEach(arr) { CenteredMatchRow(m: $0, upcoming: false, nameSize: 11.5) }
        }
    }

    // 无正在进行时:优先展示全部已完赛,预告塞得下几条塞几条,塞不下的从尾部截断。
    private func noLive(upcomingCount: Int) -> some View {
        let upcoming = Array(snapshot.upcoming.prefix(upcomingCount))
        return VStack(alignment: .leading, spacing: 3) {
            if snapshot.results.isEmpty {
                SectionTitle(text: "即将开赛", color: wc.amber)
                if upcoming.isEmpty {
                    Text("暂无比赛").font(.system(size: 11)).foregroundStyle(wc.muted)
                } else {
                    rows(upcoming, upcoming: true)
                }
            } else {
                SectionTitle(text: "已完赛", color: wc.green)
                rows(snapshot.results, upcoming: false)
                if !upcoming.isEmpty {
                    SectionTitle(text: "即将开赛", color: wc.amber)
                    rows(upcoming, upcoming: true)
                }
            }
        }
    }

    private func liveSections(finishedCount: Int, upcomingCount: Int) -> some View {
        let finished = Array(snapshot.results.suffix(finishedCount))
        let upcoming = Array(snapshot.upcoming.prefix(upcomingCount))

        return VStack(alignment: .leading, spacing: 3) {
            SectionTitle(text: "正在进行", color: wc.red)
            ForEach(snapshot.live.prefix(1)) {
                CenteredMatchRow(m: $0, upcoming: false, nameSize: 11.5)
            }

            if !finished.isEmpty {
                SectionTitle(text: "已完赛", color: wc.green)
                rows(finished, upcoming: false)
            }

            if !upcoming.isEmpty {
                SectionTitle(text: "即将开赛", color: wc.amber)
                rows(upcoming, upcoming: true)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            WidgetHeader(updated: snapshot.updated)

            if !snapshot.live.isEmpty {
                // 优先展示全部「已完赛」；空间不够时先减预告，再减已完赛。
                let rc = snapshot.results.count
                let uc = snapshot.upcoming.count
                ViewThatFits(in: .vertical) {
                    liveSections(finishedCount: rc, upcomingCount: uc)
                    liveSections(finishedCount: rc, upcomingCount: 3)
                    liveSections(finishedCount: rc, upcomingCount: 2)
                    liveSections(finishedCount: rc, upcomingCount: 1)
                    liveSections(finishedCount: rc, upcomingCount: 0)
                    liveSections(finishedCount: 4, upcomingCount: 0)
                    liveSections(finishedCount: 3, upcomingCount: 0)
                    liveSections(finishedCount: 2, upcomingCount: 0)
                    liveSections(finishedCount: 1, upcomingCount: 0)
                }
            } else {
                // 无正在进行:优先全展示已完赛,预告自适应——塞不下就从尾部截断。
                let uc = snapshot.upcoming.count
                ViewThatFits(in: .vertical) {
                    noLive(upcomingCount: uc)
                    noLive(upcomingCount: 6)
                    noLive(upcomingCount: 5)
                    noLive(upcomingCount: 4)
                    noLive(upcomingCount: 3)
                    noLive(upcomingCount: 2)
                    noLive(upcomingCount: 1)
                    noLive(upcomingCount: 0)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Medium（排布 B）

struct MediumView: View {
    @Environment(\.wcPalette) private var wc
    let snapshot: WorldCupSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            WidgetHeader(updated: snapshot.updated, compact: true)

            if !snapshot.live.isEmpty {
                SectionTitle(text: "正在进行", color: wc.red)
                if let liveMatch = snapshot.live.first {
                    CenteredMatchRow(m: liveMatch, upcoming: false, nameSize: 11)
                }

                let upcoming = Array(snapshot.upcoming.prefix(2))
                if !upcoming.isEmpty {
                    SectionTitle(text: "即将开赛", color: wc.amber)
                    ForEach(upcoming) {
                        UpcomingMatchRow(m: $0, nameSize: 11)
                    }
                }
            } else {
                let finished = Array(snapshot.results.suffix(2))
                let upcoming = Array(snapshot.upcoming.prefix(finished.isEmpty ? 3 : 1))
                if !finished.isEmpty {
                    SectionTitle(text: "已完赛", color: wc.green)
                    ForEach(finished) { CenteredMatchRow(m: $0, upcoming: false, nameSize: 11) }
                }
                if !upcoming.isEmpty {
                    SectionTitle(text: "即将开赛", color: wc.amber)
                    ForEach(upcoming) { UpcomingMatchRow(m: $0, nameSize: 11) }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Small（排布 B，队伍竖排居中以适应窄宽度）

struct SmallView: View {
    @Environment(\.wcPalette) private var wc
    let snapshot: WorldCupSnapshot
    var rotation: Int = 0

    var body: some View {
        // 有进行中 → 只显示进行中那场（不轮播）；否则 → 轮播 smallFeatured（每约15秒一张）
        if let live = snapshot.live.first {
            card(live)
        } else {
            let items = snapshot.smallFeatured
            if items.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Text("暂无比赛").font(.system(size: 12)).foregroundStyle(wc.muted)
                    Spacer()
                }
            } else {
                card(items[rotation % items.count])
            }
        }
    }

    @ViewBuilder
    private func card(_ m: Match) -> some View {
        let upcoming = (m.homeScore == nil && m.awayScore == nil)
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image("WC26Mark").resizable().scaledToFit().frame(height: 15)
                Text(label(m)).font(.system(size: 10, weight: .semibold)).foregroundStyle(labelColor(m))
                Spacer(minLength: 0)
                Text(WCFormat.clock(snapshot.updated))
                    .font(.system(size: 9))
                    .monospacedDigit()
                    .foregroundStyle(wc.muted)
                Button(intent: RefreshIntent()) {   // 时间独立显示，按钮只负责刷新
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 8.5))
                        .foregroundStyle(wc.muted)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
            teamLine(m.home, m.homeScore, showScore: !upcoming)
            if upcoming {
                Text(WCFormat.clock(m.date))
                    .font(.system(size: 16)).monospacedDigit()
                    .foregroundStyle(wc.text)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            teamLine(m.away, m.awayScore, showScore: !upcoming)
            Spacer(minLength: 0)
            Text(WCFormat.metaTime(m))
                .font(.system(size: 9.5)).foregroundStyle(wc.dim)
                .lineLimit(1).minimumScaleFactor(0.55)
        }
    }

    private func teamLine(_ name: String, _ score: Int?, showScore: Bool) -> some View {
        let info = Teams.info(name)
        return HStack(spacing: 5) {
            Text(info.flag).font(.system(size: 15))
            Text(info.zh).font(.system(size: 13)).foregroundStyle(wc.text)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 2)
            if showScore {
                Text("\(score ?? 0)").font(.system(size: 16, weight: .bold)).monospacedDigit()
                    .foregroundStyle(wc.text)
            }
        }
    }

    private func isLive(_ m: Match) -> Bool {
        ["IN_PLAY", "PAUSED", "SUSPENDED"].contains(m.status)
    }
    private func label(_ m: Match) -> String {
        if isLive(m) { return "进行中" }
        return (m.homeScore == nil) ? "即将开赛" : "已完赛"
    }
    private func labelColor(_ m: Match) -> Color {
        if isLive(m) { return wc.red }
        return (m.homeScore == nil) ? wc.amber : wc.green
    }
}
