import SwiftUI

struct RootView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label(NSLocalizedString("nav.today", comment: "Today tab"), systemImage: "calendar")
            }
            .tag(0)

            NavigationStack {
                BilboView()
            }
            .tabItem {
                Label(NSLocalizedString("nav.bilbo", comment: "BILBO tab"), systemImage: "figure.strengthtraining.traditional")
            }
            .tag(1)

            NavigationStack {
                NutritionView()
            }
            .tabItem {
                Label(NSLocalizedString("nav.nutrition", comment: "Nutrition tab"), systemImage: "fork.knife")
            }
            .tag(2)
        }
    }
}


