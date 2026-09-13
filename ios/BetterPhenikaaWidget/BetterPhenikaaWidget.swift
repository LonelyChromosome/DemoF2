import SwiftUI
import WidgetKit

private let appGroupID = "group.vn.edu.phenikaa.betterphenikaa"
private let widgetKind = "BetterPhenikaaWidget"
private let snapshotKey = "better_phenikaa_snapshot_v1"

private struct StoredSnapshot: Decodable {
  let records: [StoredRecord]
}

private struct StoredRecord: Decodable {
  let isExam: Bool
  let subjectName: String
  let room: String
  let startAt: String
  let endAt: String
}

private struct WidgetClass {
  let subject: String
  let room: String
  let start: Date
  let end: Date
}

private struct BetterPhenikaaEntry: TimelineEntry {
  let date: Date
  let subject: String
  let room: String
  let time: String
  let status: String
  let themeKey: String
  let hasSchedule: Bool
}

private enum WidgetStore {
  private static let fallbackRefresh: TimeInterval = 30 * 60

  private static let localDateFormatters: [DateFormatter] = {
    [
      "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
      "yyyy-MM-dd'T'HH:mm:ss.SSS",
      "yyyy-MM-dd'T'HH:mm:ss",
    ].map { format in
      let formatter = DateFormatter()
      formatter.calendar = Calendar(identifier: .gregorian)
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.timeZone = .current
      formatter.dateFormat = format
      return formatter
    }
  }()

  static func entry(at date: Date) -> BetterPhenikaaEntry {
    let defaults = UserDefaults(suiteName: appGroupID)
    let classes = readClasses(from: defaults)
    let nextClass = classes.first { $0.end >= date }
    let themeKey = defaults?.string(forKey: "appTheme") ?? "classic"

    guard let item = nextClass else {
      let fallbackSubject = defaults?.string(forKey: "subjectName") ?? ""
      let hasFallback = !fallbackSubject.isEmpty
        && fallbackSubject != "Không có lịch học sắp tới"
      return BetterPhenikaaEntry(
        date: date,
        subject: fallbackSubject.isEmpty
          ? "Không có lịch học sắp tới"
          : fallbackSubject,
        room: defaults?.string(forKey: "room") ?? "",
        time: defaults?.string(forKey: "time") ?? "",
        status: "Đã cập nhật",
        themeKey: themeKey,
        hasSchedule: hasFallback
      )
    }

    return BetterPhenikaaEntry(
      date: date,
      subject: item.subject,
      room: item.room,
      time: "\(formatTime(item.start)) – \(formatTime(item.end))",
      status: item.start <= date ? "Đang học" : "Sắp tới",
      themeKey: themeKey,
      hasSchedule: true
    )
  }

  static func timelineDates(from date: Date) -> [Date] {
    let defaults = UserDefaults(suiteName: appGroupID)
    let classes = readClasses(from: defaults)
    let horizon = date.addingTimeInterval(24 * 60 * 60)
    let boundaries = classes.flatMap { [$0.start, $0.end] }
      .filter { $0 > date && $0 <= horizon }
      .sorted()
      .prefix(15)
      .map { $0.addingTimeInterval(1) }
    return [date] + boundaries
  }

  static func refreshDate(after date: Date) -> Date {
    let dates = timelineDates(from: date)
    return dates.count > 1
      ? dates[dates.count - 1].addingTimeInterval(60)
      : date.addingTimeInterval(fallbackRefresh)
  }

  private static func readClasses(
    from defaults: UserDefaults?
  ) -> [WidgetClass] {
    guard
      let raw = defaults?.string(forKey: snapshotKey),
      let data = raw.data(using: .utf8),
      let snapshot = try? JSONDecoder().decode(StoredSnapshot.self, from: data)
    else {
      return []
    }

    return snapshot.records.compactMap { record in
      guard
        !record.isExam,
        let start = parseDate(record.startAt),
        let end = parseDate(record.endAt)
      else {
        return nil
      }
      return WidgetClass(
        subject: record.subjectName,
        room: record.room,
        start: start,
        end: end
      )
    }.sorted { $0.start < $1.start }
  }

  private static func parseDate(_ value: String) -> Date? {
    let internetDate = ISO8601DateFormatter().date(from: value)
    return internetDate
      ?? localDateFormatters.lazy.compactMap { $0.date(from: value) }.first
  }

  private static func formatTime(_ value: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "vi_VN")
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: value)
  }
}

private struct BetterPhenikaaProvider: TimelineProvider {
  func placeholder(in context: Context) -> BetterPhenikaaEntry {
    BetterPhenikaaEntry(
      date: Date(),
      subject: "Lập trình ứng dụng di động",
      room: "A6-205",
      time: "09:30 – 12:10",
      status: "Sắp tới",
      themeKey: "classic",
      hasSchedule: true
    )
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (BetterPhenikaaEntry) -> Void
  ) {
    completion(
      context.isPreview ? placeholder(in: context) : WidgetStore.entry(at: Date())
    )
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<BetterPhenikaaEntry>) -> Void
  ) {
    let now = Date()
    let entries = WidgetStore.timelineDates(from: now).map {
      WidgetStore.entry(at: $0)
    }
    completion(
      Timeline(
        entries: entries,
        policy: .after(WidgetStore.refreshDate(after: now))
      )
    )
  }
}

private struct ThemePalette {
  let start: Color
  let end: Color
  let text: Color
  let subtext: Color

  static func resolve(_ key: String) -> ThemePalette {
    switch key {
    case "lol":
      return .init(
        start: .hex(0x06131A),
        end: .hex(0x0B343A),
        text: .hex(0xF0E6D2),
        subtext: .hex(0xC8AA6E)
      )
    case "valorant":
      return .init(
        start: .hex(0x0F1923),
        end: .hex(0x24313B),
        text: .hex(0xECE8E1),
        subtext: .hex(0xFF7B86)
      )
    case "minecraft":
      return .init(
        start: .hex(0x3A2B20),
        end: .hex(0x6B4A2F),
        text: .white,
        subtext: .hex(0xD8D1C9)
      )
    case "facebook":
      return .init(
        start: .white,
        end: .hex(0xE7F3FF),
        text: .hex(0x050505),
        subtext: .hex(0x65676B)
      )
    case "shopee":
      return .init(
        start: .hex(0xEE4D2D),
        end: .hex(0xFF6A3D),
        text: .white,
        subtext: .hex(0xFFE9E1)
      )
    case "tiktok":
      return .init(
        start: .hex(0x111111),
        end: .hex(0x2A1520),
        text: .white,
        subtext: .hex(0x25F4EE)
      )
    case "ben10":
      return .init(
        start: .hex(0x101510),
        end: .hex(0x1D5F22),
        text: .white,
        subtext: .hex(0x7CFF00)
      )
    case "youtube":
      return .init(
        start: .hex(0x181818),
        end: .hex(0x2B0E14),
        text: .white,
        subtext: .hex(0xFF8A9F)
      )
    case "steam":
      return .init(
        start: .hex(0x171D25),
        end: .hex(0x1B3D55),
        text: .hex(0xD6E9F8),
        subtext: .hex(0x66C0F4)
      )
    default:
      return .init(
        start: .hex(0x173A8E),
        end: .hex(0x315AB5),
        text: .white,
        subtext: .hex(0xDDE8FF)
      )
    }
  }
}

private extension Color {
  static func hex(_ value: UInt32) -> Color {
    Color(
      red: Double((value >> 16) & 0xFF) / 255,
      green: Double((value >> 8) & 0xFF) / 255,
      blue: Double(value & 0xFF) / 255
    )
  }
}

private struct BetterPhenikaaWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: BetterPhenikaaEntry

  private var palette: ThemePalette { .resolve(entry.themeKey) }

  private var background: some View {
    LinearGradient(
      colors: [palette.start, palette.end],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: family == .systemSmall ? 7 : 9) {
      HStack(spacing: 6) {
        Image(systemName: "calendar.badge.clock")
          .font(.system(size: 13, weight: .bold))
        Text("BETTER PHENIKAA")
          .font(.system(size: 10, weight: .black, design: .rounded))
          .lineLimit(1)
        Spacer(minLength: 4)
        Text(entry.status.uppercased())
          .font(.system(size: 9, weight: .bold, design: .rounded))
          .lineLimit(1)
      }
      .foregroundColor(palette.subtext)

      Text(entry.subject)
        .font(
          .system(
            size: family == .systemSmall ? 17 : 20,
            weight: .black,
            design: .rounded
          )
        )
        .foregroundColor(palette.text)
        .lineLimit(family == .systemSmall ? 3 : 2)
        .minimumScaleFactor(0.72)

      Spacer(minLength: 2)

      if entry.hasSchedule {
        if family == .systemSmall {
          detailLine(icon: "clock.fill", text: entry.time)
          detailLine(icon: "location.fill", text: entry.room)
        } else {
          HStack(spacing: 18) {
            detailLine(icon: "location.fill", text: entry.room)
            detailLine(icon: "clock.fill", text: entry.time)
          }
        }
      }
    }
  }

  var body: some View {
    Group {
      if #available(iOSApplicationExtension 17.0, *) {
        content.containerBackground(for: .widget) { background }
      } else {
        ZStack {
          background
          content.padding(16)
        }
      }
    }
    .widgetURL(URL(string: "betterphenikaa://schedule"))
  }

  private func detailLine(icon: String, text: String) -> some View {
    HStack(spacing: 5) {
      Image(systemName: icon)
        .font(.system(size: 11, weight: .semibold))
      Text(text.isEmpty ? "Chưa có thông tin" : text)
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .foregroundColor(palette.subtext)
  }
}

@main
struct BetterPhenikaaWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: widgetKind,
      provider: BetterPhenikaaProvider()
    ) { entry in
      BetterPhenikaaWidgetView(entry: entry)
    }
    .configurationDisplayName("Lịch học Better Phenikaa")
    .description("Xem nhanh môn học sắp tới ngay trên màn hình chính.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
