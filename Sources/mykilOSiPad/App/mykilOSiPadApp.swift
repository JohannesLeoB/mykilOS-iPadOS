import SwiftUI

@main
struct mykilOSiPadApp: App {
    @State private var stores = AppStores()

    var body: some Scene {
        WindowGroup {
            AppShell(stores: stores)
        }
    }
}
