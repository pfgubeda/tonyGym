import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(NSLocalizedString("nav.today", comment: "Today tab"), systemImage: "calendar")
            }

            NavigationStack {
                ExerciseListView()
            }
            .tabItem {
                Label(NSLocalizedString("nav.exercises", comment: "Exercises tab"), systemImage: "dumbbell")
            }
            
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label(NSLocalizedString("nav.progress", comment: "Progress tab"), systemImage: "chart.line.uptrend.xyaxis")
            }
            
            NavigationStack {
                BilboView()
            }
            .tabItem {
                Label(NSLocalizedString("nav.bilbo", comment: "BILBO tab"), systemImage: "figure.strengthtraining.traditional")
            }
        }
    }
}


