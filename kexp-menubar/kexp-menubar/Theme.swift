import AppKit
import SwiftUI

extension NSColor {
    static let kexpOrange = NSColor(
        red: 0xfb / 255.0, green: 0xad / 255.0, blue: 0x18 / 255.0, alpha: 1.0)
    static let kexpBackground = NSColor(
        red: 0x23 / 255.0, green: 0x1f / 255.0, blue: 0x20 / 255.0, alpha: 1.0)
}

extension Color {
    static let kexpOrange = Color(nsColor: .kexpOrange)
    static let kexpBackground = Color(nsColor: .kexpBackground)
}

enum StatusBarIcon {
    static func menuBarImage(isLive: Bool) -> NSImage? {
        if isLive {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            return NSImage(systemSymbolName: "dot.radiowaves.left.and.right", accessibilityDescription: "KEXP")?
                .withSymbolConfiguration(config)
        } else {
            return NSImage(named: "MenuBarIcon")
        }
    }
}

enum AppDefaults {
    static let playLocation = 1
    static let autoReconnectSeconds = 3600
}
