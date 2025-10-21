//
//  TodayWorkoutWidget.swift
//  TodayWorkoutWidget
//
//  Created by Pablo Fernandez Gonzalez on 20/10/25.
//

import WidgetKit
import SwiftUI
import Foundation

private let appGroupId = "group.com.pafego.TonyGym"

// Simple data structures for widget (no conflicts with app models)
struct WidgetRoutineItem: Codable {
    let title: String
    let categoryRaw: Int
    let weightKg: Double
}

struct WidgetRoutineSnapshot: Codable {
    let date: Date
    let weekday: Int
    let routineName: String
    let items: [WidgetRoutineItem]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), snapshot: placeholderSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let today = Date()
        let snapshot = readSnapshot() ?? placeholderSnapshot()
        // Always use today's date, not the stored date
        let todaySnapshot = WidgetRoutineSnapshot(
            date: today,
            weekday: snapshot.weekday,
            routineName: snapshot.routineName,
            items: snapshot.items
        )
        let entry = SimpleEntry(date: today, snapshot: todaySnapshot)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let today = Date()
        let snapshot = readSnapshot() ?? placeholderSnapshot()
        // Always use today's date, not the stored date
        let todaySnapshot = WidgetRoutineSnapshot(
            date: today,
            weekday: snapshot.weekday,
            routineName: snapshot.routineName,
            items: snapshot.items
        )
        let entry = SimpleEntry(date: today, snapshot: todaySnapshot)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }

    private func readSnapshot() -> WidgetRoutineSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: "todayRoutineSnapshot") else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetRoutineSnapshot.self, from: data)
    }

    private func placeholderSnapshot() -> WidgetRoutineSnapshot {
        WidgetRoutineSnapshot(
            date: Date(),
            weekday: 2,
            routineName: "Rutina",
            items: [
                WidgetRoutineItem(title: "Sentadilla", categoryRaw: 1, weightKg: 60),
                WidgetRoutineItem(title: "Press banca", categoryRaw: 2, weightKg: 40)
            ]
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetRoutineSnapshot
}

struct TodayWorkoutWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        GeometryReader { geometry in
            let maxExercises = calculateMaxExercises(for: geometry.size)
            
            VStack(alignment: .leading, spacing: 2) {
                // Compact header - all in one line
                HStack {
                    Text(entry.snapshot.routineName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Spacer()
                    Text(weekdayShort(entry.snapshot.weekday))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if entry.snapshot.items.isEmpty {
                    // Rest day - compact
                    HStack(spacing: 4) {
                        Image(systemName: "bed.double.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("Descanso")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                } else {
                    // Show exercises with dynamic count based on widget size
                    VStack(spacing: 2) {
                        ForEach(Array(entry.snapshot.items.prefix(maxExercises).enumerated()), id: \.offset) { index, item in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(categoryColor(item.categoryRaw))
                                    .frame(width: 4, height: 4)
                                Text(item.title)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Spacer()
                                Text(formatWeight(item.weightKg))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .frame(height: 16) // Fixed height for maximum density
                        }
                        
                        // Show indicator if there are more exercises
                        if entry.snapshot.items.count > maxExercises {
                            HStack {
                                Spacer()
                                Text("+\(entry.snapshot.items.count - maxExercises) más")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                            }
                            .frame(height: 16)
                        }
                    }
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    private func calculateMaxExercises(for size: CGSize) -> Int {
        // Calculate available height after header and padding
        let headerHeight: CGFloat = 20 // Approximate header height
        let padding: CGFloat = 12 // Top and bottom padding
        let availableHeight = size.height - headerHeight - padding
        
        // Calculate how many exercises can fit (each exercise is 16pt + 2pt spacing = 18pt)
        let exerciseHeight: CGFloat = 18
        let maxFit = Int(availableHeight / exerciseHeight)
        
        // Ensure we don't exceed reasonable limits
        return min(maxFit, 12) // Cap at 12 exercises maximum
    }

    private func weekdayShort(_ raw: Int) -> String {
        switch raw {
        case 1: return "L"
        case 2: return "M"
        case 3: return "X"
        case 4: return "J"
        case 5: return "V"
        case 6: return "S"
        case 7: return "D"
        default: return ""
        }
    }
    
    private func categoryColor(_ raw: Int) -> Color {
        switch raw {
        case 1: return .green  // pierna
        case 2: return .red    // pecho
        case 3: return .blue   // espalda
        case 4: return .orange // hombro
        case 5: return .purple // brazos
        case 6: return .yellow // core
        case 7: return .gray   // otros
        default: return .gray
        }
    }
    
    private func formatWeight(_ kg: Double) -> String {
        let locale = Locale.current
        let usesMetric = locale.usesMetricSystem
        
        if usesMetric {
            return String(format: "%.1f kg", kg)
        } else {
            let lb = kg * 2.20462
            return String(format: "%.1f lb", lb)
        }
    }
}

struct TodayWorkoutWidget: Widget {
    let kind: String = "TodayWorkoutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                TodayWorkoutWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TodayWorkoutWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Hoy")
        .description("Rutina del día")
    }
}
