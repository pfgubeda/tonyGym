//
//  StreakWidget.swift
//  TodayWorkoutWidget
//
//  Created for TonyGym
//

import WidgetKit
import SwiftUI
import Foundation

private let appGroupId = "group.com.pafego.TonyGym"

// Snapshot para el widget (debe coincidir con WidgetSync.StreakSnapshot)
struct StreakSnapshot: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let lastWorkoutDate: Date?
    let isActive: Bool
    let totalWorkoutDays: Int
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), snapshot: StreakSnapshot(
            currentStreak: 7,
            longestStreak: 15,
            lastWorkoutDate: Date(),
            isActive: true,
            totalWorkoutDays: 45
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> ()) {
        let snapshot = readStreakSnapshot() ?? placeholder(in: context).snapshot
        let entry = StreakEntry(date: Date(), snapshot: snapshot)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let now = Date()
        let snapshot = readStreakSnapshot() ?? placeholder(in: context).snapshot
        let entry = StreakEntry(date: now, snapshot: snapshot)
        
        // Actualizar a medianoche
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight(from: now)))
        completion(timeline)
    }
    
    private func readStreakSnapshot() -> StreakSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: "streakSnapshot") else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(StreakSnapshot.self, from: data)
    }
    
    private func nextMidnight(from date: Date) -> Date {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: date)
        return cal.date(byAdding: .day, value: 1, to: startOfToday) ?? date.addingTimeInterval(24 * 60 * 60)
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let snapshot: StreakSnapshot
}

struct StreakWidgetEntryView: View {
    var entry: StreakProvider.Entry
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text("Racha")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.bottom, 6)
                
                // Streak number (grande, estilo Duolingo/GitHub)
                VStack(spacing: 2) {
                    Text("\(entry.snapshot.currentStreak)")
                        .font(.system(size: min(geometry.size.width * 0.4, 36), weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    
                    Text("días")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                
                Spacer(minLength: 4)
                
                // Visualización de días (estilo GitHub contributions)
                streakGrid
                    .frame(height: min(geometry.size.height * 0.2, 18))
                    .padding(.vertical, 4)
                
                Spacer(minLength: 2)
                
                // Footer con mejor racha
                HStack(spacing: 3) {
                    Text("Mejor")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 7))
                            .foregroundStyle(.orange.opacity(0.7))
                        Text("\(entry.snapshot.longestStreak)")
                            .font(.system(size: 9, weight: .semibold))
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    private var streakGrid: some View {
        // Mostrar últimos 7 días como cuadrados (estilo GitHub)
        HStack(spacing: 2) {
            ForEach(0..<7) { index in
                let dayIndex = 6 - index
                let isActive = dayIndex < entry.snapshot.currentStreak
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(streakColor(for: dayIndex, isActive: isActive))
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(minHeight: 12)
            }
        }
    }
    
    private func streakColor(for dayIndex: Int, isActive: Bool) -> Color {
        if !isActive {
            return Color.gray.opacity(0.2)
        }
        
        // Intensidad basada en qué tan reciente es el día
        let intensity = Double(dayIndex) / 7.0
        return Color.orange.opacity(0.3 + (intensity * 0.7))
    }
}

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            if #available(iOS 17.0, *) {
                StreakWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                StreakWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Racha de Entrenamiento")
        .description("Rastrea tus días consecutivos de entrenamiento")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
