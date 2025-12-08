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
                DashboardView()
            }
            .tabItem {
                Label(NSLocalizedString("nav.dashboard", comment: "Dashboard tab"), systemImage: "chart.bar.fill")
            }
            
            NavigationStack {
                ExerciseListView()
            }
            .tabItem {
                Label(NSLocalizedString("nav.exercises", comment: "Exercises tab"), systemImage: "dumbbell")
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


