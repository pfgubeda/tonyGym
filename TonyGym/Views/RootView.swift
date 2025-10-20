import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Hoy", systemImage: "calendar")
            }

            NavigationStack {
                ExerciseListView()
            }
            .tabItem {
                Label("Ejercicios", systemImage: "dumbbell")
            }
            
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("Progreso", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
    }
}


