import Foundation
import ServiceManagement

protocol LoginItemManaging {
    func setLaunchAtLogin(_ enabled: Bool)
}

final class LoginItemManager: LoginItemManaging {
    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Failed to update login item: \(error.localizedDescription)")
        }
    }
}
