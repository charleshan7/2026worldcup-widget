import Foundation

struct VenueInfo {
    let stadium: String
    let city: String
    let country: String
}

enum Venues {
    /// 优先用球场名命中（信息最全）；命中不到时用 strCity 兜底解析城市与国家。
    static func info(venue: String?, rawCity: String?) -> VenueInfo {
        if let v = venue, let hit = map[v] { return hit }

        let comps = (rawCity ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let cityName = comps.first ?? ""
        let region = comps.count > 1 ? comps[1] : ""
        return VenueInfo(stadium: venue ?? "", city: cityName, country: country(forRegion: region))
    }

    private static func country(forRegion code: String) -> String {
        let canada: Set<String> = ["BC", "ON", "AB", "QC", "MB", "NS", "SK"]
        let mexico: Set<String> = ["MX", "JA", "NL", "CMX", "MEX", "DF", "CDMX"]
        if canada.contains(code) { return "加拿大" }
        if mexico.contains(code) { return "墨西哥" }
        if !code.isEmpty { return "美国" }   // 其余视为美国州缩写
        return ""
    }

    // 2026 世界杯 16 座承办球场
    static let map: [String: VenueInfo] = [
        "Estadio Azteca": VenueInfo(stadium: "阿兹特克体育场", city: "墨西哥城", country: "墨西哥"),
        "Estadio Banorte": VenueInfo(stadium: "阿兹特克体育场", city: "墨西哥城", country: "墨西哥"),
        "Estadio Akron": VenueInfo(stadium: "阿克隆体育场", city: "瓜达拉哈拉", country: "墨西哥"),
        "Estadio BBVA": VenueInfo(stadium: "BBVA体育场", city: "蒙特雷", country: "墨西哥"),
        "Estadio BBVA Bancomer": VenueInfo(stadium: "BBVA体育场", city: "蒙特雷", country: "墨西哥"),
        "BC Place": VenueInfo(stadium: "BC体育场", city: "温哥华", country: "加拿大"),
        "BMO Field": VenueInfo(stadium: "BMO球场", city: "多伦多", country: "加拿大"),
        "Mercedes-Benz Stadium": VenueInfo(stadium: "梅赛德斯-奔驰体育场", city: "亚特兰大", country: "美国"),
        "AT&T Stadium": VenueInfo(stadium: "AT&T体育场", city: "阿灵顿", country: "美国"),
        "Levi's Stadium": VenueInfo(stadium: "李维斯体育场", city: "圣克拉拉", country: "美国"),
        "GEHA Field at Arrowhead Stadium": VenueInfo(stadium: "箭头体育场", city: "堪萨斯城", country: "美国"),
        "Arrowhead Stadium": VenueInfo(stadium: "箭头体育场", city: "堪萨斯城", country: "美国"),
        "Lumen Field": VenueInfo(stadium: "流明球场", city: "西雅图", country: "美国"),
        "Gillette Stadium": VenueInfo(stadium: "吉列体育场", city: "福克斯堡", country: "美国"),
        "Lincoln Financial Field": VenueInfo(stadium: "林肯金融球场", city: "费城", country: "美国"),
        "SoFi Stadium": VenueInfo(stadium: "SoFi体育场", city: "洛杉矶", country: "美国"),
        "Hard Rock Stadium": VenueInfo(stadium: "硬石体育场", city: "迈阿密", country: "美国"),
        "MetLife Stadium": VenueInfo(stadium: "大都会人寿体育场", city: "纽约", country: "美国"),
        "NRG Stadium": VenueInfo(stadium: "NRG体育场", city: "休斯顿", country: "美国"),
        "Reliant Stadium": VenueInfo(stadium: "NRG体育场", city: "休斯顿", country: "美国"),
    ]
}
