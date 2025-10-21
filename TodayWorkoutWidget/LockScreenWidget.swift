//
//  LockScreenWidget.swift
//  TodayWorkoutWidget
//
//  Created by Pablo Fernandez Gonzalez on 20/10/25.
//

import WidgetKit
import SwiftUI
import Foundation

struct LockScreenProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenEntry {
        LockScreenEntry(date: Date(), snapshot: placeholderSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenEntry) -> ()) {
        let today = Date()
        let snapshot = readSnapshot() ?? placeholderSnapshot()
        // Always use today's date, not the stored date
        let todaySnapshot = WidgetRoutineSnapshot(
            date: today,
            weekday: snapshot.weekday,
            routineName: snapshot.routineName,
            items: snapshot.items
        )
        let entry = LockScreenEntry(date: today, snapshot: todaySnapshot)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenEntry>) -> ()) {
        var entries: [LockScreenEntry] = []
        let today = Date()
        let snapshot = readSnapshot() ?? placeholderSnapshot()
        // Always use today's date, not the stored date
        let todaySnapshot = WidgetRoutineSnapshot(
            date: today,
            weekday: snapshot.weekday,
            routineName: snapshot.routineName,
            items: snapshot.items
        )
        let entry = LockScreenEntry(date: today, snapshot: todaySnapshot)
        entries.append(entry)
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func readSnapshot() -> WidgetRoutineSnapshot? {
        guard let userDefaults = UserDefaults(suiteName: "group.com.pafego.TonyGym"),
              let data = userDefaults.data(forKey: "todayRoutineSnapshot") else {
            return nil
        }
        
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
                WidgetRoutineItem(title: "Press banca", categoryRaw: 2, weightKg: 40),
                WidgetRoutineItem(title: "Peso muerto", categoryRaw: 3, weightKg: 80)
            ]
        )
    }
}

struct LockScreenEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetRoutineSnapshot
}

struct LockScreenWidgetView: View {
    var entry: LockScreenProvider.Entry
    
    var body: some View {
        VStack(spacing: 4) {
            // Day name instead of routine name
            Text(dayName(entry.snapshot.weekday))
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundStyle(.primary)
            
            if entry.snapshot.items.isEmpty {
                // Rest day - modern style
                HStack(spacing: 6) {
                    Image(systemName: "bed.double.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Descanso")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary.opacity(0.3))
                .clipShape(Capsule())
            } else {
                // Most frequent categories - multi-line layout with modern styling
                let categoryCounts = Dictionary(grouping: entry.snapshot.items, by: { $0.categoryRaw })
                    .mapValues { $0.count }
                    .sorted { $0.value > $1.value }
                
                // Show more categories with multi-line layout
                let maxCategories = min(categoryCounts.count, 4) // Show up to 4 categories
                let mostFrequentCategories = Array(categoryCounts.prefix(maxCategories))
                
                VStack(spacing: 3) {
                    // First line - up to 2 categories
                    HStack(spacing: 3) {
                        ForEach(Array(mostFrequentCategories.prefix(2).enumerated()), id: \.offset) { index, category in
                            let categoryName = categoryName(category.key)
                            let count = category.value
                            
                            HStack(spacing: 2) {
                                Text(categoryName)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                
                                // Show count if there are multiple exercises in this category
                                if count > 1 {
                                    Text("\(count)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary.opacity(0.2))
                            .clipShape(Capsule())
                        }
                    }
                    
                    // Second line - remaining categories (if any)
                    if mostFrequentCategories.count > 2 {
                        HStack(spacing: 3) {
                            ForEach(Array(mostFrequentCategories.dropFirst(2).enumerated()), id: \.offset) { index, category in
                                let categoryName = categoryName(category.key)
                                let count = category.value
                                
                                HStack(spacing: 2) {
                                    Text(categoryName)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                    
                                    // Show count if there are multiple exercises in this category
                                    if count > 1 {
                                        Text("\(count)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)
                                    }
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary.opacity(0.2))
                                .clipShape(Capsule())
                            }
                            
                            // Show total count if there are more categories than we can display
                            if categoryCounts.count > 4 {
                                Text("+\(categoryCounts.count - 4)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.quaternary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }
    
    private func dayName(_ raw: Int) -> String {
        switch raw {
        case 1: return "Rutina de Lunes"
        case 2: return "Rutina de Martes"
        case 3: return "Rutina de Miércoles"
        case 4: return "Rutina de Jueves"
        case 5: return "Rutina de Viernes"
        case 6: return "Rutina de Sábado"
        case 7: return "Rutina de Domingo"
        default: return "Rutina"
        }
    }
    
    private func categoryName(_ raw: Int) -> String {
        switch raw {
        case 1: return "Pierna"
        case 2: return "Pecho"
        case 3: return "Espalda"
        case 4: return "Hombro"
        case 5: return "Brazos"
        case 6: return "Core"
        case 7: return "Otros"
        default: return "Otros"
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
}

struct LockScreenWidget: Widget {
    let kind: String = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenProvider()) { entry in
            if #available(iOS 17.0, *) {
                LockScreenWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                LockScreenWidgetView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Rutina")
        .description("Rutina del día con categorías")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

#Preview(as: .accessoryRectangular, widget: {
    LockScreenWidget()
}, timeline: {
    LockScreenEntry(date: .now, snapshot: WidgetRoutineSnapshot(
        date: Date(),
        weekday: 2,
        routineName: "Rutina de Martes",
        items: [
            WidgetRoutineItem(title: "Sentadilla", categoryRaw: 1, weightKg: 60),
            WidgetRoutineItem(title: "Zancadas", categoryRaw: 1, weightKg: 40),
            WidgetRoutineItem(title: "Press banca", categoryRaw: 2, weightKg: 40),
            WidgetRoutineItem(title: "Press inclinado", categoryRaw: 2, weightKg: 35),
            WidgetRoutineItem(title: "Peso muerto", categoryRaw: 3, weightKg: 80),
            WidgetRoutineItem(title: "Remo con barra", categoryRaw: 3, weightKg: 50),
            WidgetRoutineItem(title: "Press militar", categoryRaw: 4, weightKg: 30),
            WidgetRoutineItem(title: "Elevaciones laterales", categoryRaw: 4, weightKg: 15)
        ]
    ))
})
