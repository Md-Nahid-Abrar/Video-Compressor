import SwiftUI

/// The navigation stack that hosts Home and everything pushed from it.
struct MainFlowView: View {
    let services: AppServices
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(services: services, router: router)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .settings:
                        SettingsView()
                    case .profile:
                        ProfileView(defaults: services.defaults)
                    case .export(let request):
                        ExportView(request: request, services: services, router: router)
                    }
                }
        }
    }
}

#Preview {
    MainFlowView(services: .live())
}
