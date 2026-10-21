import SwiftUI
import WidgetKit

// Alathar widgets for the Lock Screen and Home Screen.
// The app writes one JSON string into the shared App Group
// (lib/data/widget_sync.dart → AppDelegate «alathar/widget»).

private let appGroup = "group.com.hadeeth.alathar"
private let green = Color(red: 0.118, green: 0.290, blue: 0.239)
private let sand = Color(red: 0.910, green: 0.851, blue: 0.710)

// MARK: - Shared data

struct WidgetData: Decodable {
  struct PrayerTime: Decodable {
    let n: String
    let t: Double
  }

  var lang: String?
  var day: String?
  var city: String?
  var prayers: [PrayerTime]?
  var hadith: String?
  var hadithDone: Bool?
  var quranRead: Int?
  var quranGoal: Int?
  var labels: [String: String]?

  init() {}

  static func load() -> WidgetData {
    guard let defaults = UserDefaults(suiteName: appGroup),
      let json = defaults.string(forKey: "alathar_widget"),
      let data = json.data(using: .utf8),
      let value = try? JSONDecoder().decode(WidgetData.self, from: data)
    else { return WidgetData() }
    return value
  }

  var isEnglish: Bool { (lang ?? "ar") == "en" }
  var direction: LayoutDirection { isEnglish ? .leftToRight : .rightToLeft }

  var locale: Locale {
    switch lang ?? "ar" {
    case "en": return Locale(identifier: "en_US")
    case "ur": return Locale(identifier: "ur_PK")
    default: return Locale(identifier: "ar")
    }
  }

  func label(_ key: String, _ fallback: String) -> String {
    labels?[key] ?? fallback
  }

  func time(_ date: Date) -> String {
    let f = DateFormatter()
    f.locale = locale
    f.dateFormat = "h:mm"
    return f.string(from: date)
  }

  func num(_ n: Int) -> String {
    let f = NumberFormatter()
    f.locale = locale
    return f.string(from: NSNumber(value: n)) ?? "\(n)"
  }

  /// True when the saved progress is for [date]'s day.
  func isSameDay(_ date: Date) -> Bool {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return day == f.string(from: date)
  }

  /// The next prayer after [date].
  func nextPrayer(after date: Date) -> (name: String, at: Date)? {
    let sorted = (prayers ?? []).sorted { $0.t < $1.t }
    for p in sorted {
      let at = Date(timeIntervalSince1970: p.t)
      if at > date { return (p.n, at) }
    }
    return nil
  }
}

extension WidgetFamily {
  var isAccessory: Bool {
    switch self {
    case .accessoryCircular, .accessoryRectangular, .accessoryInline: return true
    default: return false
    }
  }
}

extension View {
  /// Home Screen widgets get the green card; Lock Screen ones stay clear.
  @ViewBuilder
  func alatharBackground(_ family: WidgetFamily) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      self.containerBackground(for: .widget) {
        if family.isAccessory { Color.clear } else { green }
      }
    } else {
      self.background(family.isAccessory ? Color.clear : green)
    }
  }
}

// MARK: - Next prayer

struct PrayerEntry: TimelineEntry {
  let date: Date
  let data: WidgetData
}

struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry {
    PrayerEntry(date: Date(), data: WidgetData())
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(PrayerEntry(date: Date(), data: WidgetData.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let data = WidgetData.load()
    let now = Date()
    var entries = [PrayerEntry(date: now, data: data)]
    // A new entry at every prayer time, so the widget moves on by itself.
    for p in data.prayers ?? [] {
      let at = Date(timeIntervalSince1970: p.t)
      if at > now { entries.append(PrayerEntry(date: at, data: data)) }
    }
    entries.sort { $0.date < $1.date }
    let last = entries.last?.date ?? now
    let refresh = max(last, now.addingTimeInterval(3600))
    completion(Timeline(entries: entries, policy: .after(refresh)))
  }
}

struct PrayerView: View {
  @Environment(\.widgetFamily) var family
  let entry: PrayerEntry

  var body: some View {
    content
      .environment(\.layoutDirection, entry.data.direction)
      .alatharBackground(family)
  }

  @ViewBuilder
  var content: some View {
    let d = entry.data
    if let next = d.nextPrayer(after: entry.date) {
      switch family {
      case .accessoryInline:
        Text("\(next.name) \(d.time(next.at))")
      case .accessoryCircular:
        ZStack {
          AccessoryWidgetBackground()
          VStack(spacing: 0) {
            Text(next.name)
              .font(.system(size: 12, weight: .semibold))
              .lineLimit(1)
              .minimumScaleFactor(0.6)
            Text(d.time(next.at))
              .font(.system(size: 16, weight: .bold))
              .lineLimit(1)
              .minimumScaleFactor(0.6)
          }
          .padding(4)
        }
      case .accessoryRectangular:
        VStack(alignment: .leading, spacing: 1) {
          Text(d.label("next", "الصلاة القادمة"))
            .font(.caption2)
            .widgetAccentable()
          HStack(spacing: 6) {
            Text(next.name).font(.headline)
            Text(d.time(next.at)).font(.headline)
          }
          HStack(spacing: 4) {
            Text(d.label("in", "بعد")).font(.caption)
            Text(timerInterval: entry.date...next.at, countsDown: true)
              .font(.caption)
              .monospacedDigit()
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      default:
        VStack(alignment: .leading, spacing: 4) {
          if let city = d.city {
            Text(city).font(.caption2).foregroundColor(sand).lineLimit(1)
          }
          Text(d.label("next", "الصلاة القادمة"))
            .font(.caption)
            .foregroundColor(.white.opacity(0.75))
          Text(next.name)
            .font(.system(size: 26, weight: .bold))
            .foregroundColor(.white)
          Text(d.time(next.at))
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(sand)
          Spacer(minLength: 0)
          Text(timerInterval: entry.date...next.at, countsDown: true)
            .font(.system(size: 15, weight: .semibold))
            .monospacedDigit()
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(family.isAccessory ? 0 : 4)
      }
    } else {
      Text(d.label("open", "افتح الأثر لتحديث المواقيت"))
        .font(.caption)
        .foregroundColor(family.isAccessory ? Color.primary : Color.white)
        .multilineTextAlignment(.center)
    }
  }
}

struct PrayerWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "AlatharPrayer", provider: PrayerProvider()) { entry in
      PrayerView(entry: entry)
    }
    .configurationDisplayName("الصلاة القادمة")
    .description("الصلاة القادمة ووقتها والعدّ التنازلي — Next prayer")
    .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline, .systemSmall])
  }
}

// MARK: - Today's wird (Qur'an pages + hadith)

struct WirdEntry: TimelineEntry {
  let date: Date
  let data: WidgetData
}

struct WirdProvider: TimelineProvider {
  func placeholder(in context: Context) -> WirdEntry {
    WirdEntry(date: Date(), data: WidgetData())
  }

  func getSnapshot(in context: Context, completion: @escaping (WirdEntry) -> Void) {
    completion(WirdEntry(date: Date(), data: WidgetData.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<WirdEntry>) -> Void) {
    let data = WidgetData.load()
    let now = Date()
    // Start again at midnight: a new day's wird.
    let midnight = Calendar.current.nextDate(
      after: now, matching: DateComponents(hour: 0, minute: 0, second: 5),
      matchingPolicy: .nextTime) ?? now.addingTimeInterval(3600)
    let entries = [WirdEntry(date: now, data: data), WirdEntry(date: midnight, data: data)]
    completion(Timeline(entries: entries, policy: .after(midnight.addingTimeInterval(60))))
  }
}

struct WirdView: View {
  @Environment(\.widgetFamily) var family
  let entry: WirdEntry

  var body: some View {
    content
      .environment(\.layoutDirection, entry.data.direction)
      .alatharBackground(family)
  }

  @ViewBuilder
  var content: some View {
    let d = entry.data
    let today = d.isSameDay(entry.date)
    let goal = max(d.quranGoal ?? 2, 1)
    let read = today ? min(d.quranRead ?? 0, goal) : 0
    let hadithDone = today && (d.hadithDone ?? false)
    let quranText = "\(d.label("quran", "التلاوة")) \(d.num(read))/\(d.num(goal))"

    switch family {
    case .accessoryInline:
      Text("\(quranText) · \(d.label("hadith", "الحديث")) \(hadithDone ? "✓" : "—")")
    case .accessoryCircular:
      Gauge(value: Double(read), in: 0...Double(goal)) {
        Image(systemName: "book")
      } currentValueLabel: {
        Text("\(d.num(read))/\(d.num(goal))")
      }
      .gaugeStyle(.accessoryCircularCapacity)
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 2) {
        Text(d.label("wird", "ورد اليوم"))
          .font(.headline)
          .widgetAccentable()
        HStack(spacing: 4) {
          Image(systemName: read >= goal ? "checkmark.circle.fill" : "book")
          Text(quranText)
        }
        .font(.caption)
        HStack(spacing: 4) {
          Image(systemName: hadithDone ? "checkmark.circle.fill" : "circle")
          Text(d.label("hadith", "الحديث"))
        }
        .font(.caption)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    default:
      VStack(alignment: .leading, spacing: 6) {
        Text(d.label("wird", "ورد اليوم"))
          .font(.system(size: 15, weight: .bold))
          .foregroundColor(sand)
        HStack(spacing: 6) {
          Image(systemName: read >= goal ? "checkmark.circle.fill" : "book")
          Text(quranText)
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(.white)
        ProgressView(value: Double(read), total: Double(goal))
          .tint(sand)
        HStack(spacing: 6) {
          Image(systemName: hadithDone ? "checkmark.circle.fill" : "circle")
          Text(d.label("hadith", "الحديث"))
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(.white)
        if family == .systemMedium, let h = d.hadith, !h.isEmpty {
          Text(h)
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.85))
            .lineLimit(3)
        }
        Spacer(minLength: 0)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .padding(4)
    }
  }
}

struct WirdWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "AlatharWird", provider: WirdProvider()) { entry in
      WirdView(entry: entry)
    }
    .configurationDisplayName("ورد اليوم")
    .description("صفحات التلاوة وحديث اليوم — Today's wird")
    .supportedFamilies([
      .accessoryRectangular, .accessoryCircular, .accessoryInline, .systemSmall, .systemMedium,
    ])
  }
}

// MARK: - Bundle

@main
struct AlatharWidgets: WidgetBundle {
  var body: some Widget {
    PrayerWidget()
    WirdWidget()
  }
}
