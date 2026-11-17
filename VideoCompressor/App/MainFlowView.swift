import SwiftUI

/// The navigation stack that hosts Home and everything pushed from it.
struct MainFlowView: View {
    @Environment(AppServices.self) private var services
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            HomeView()
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
