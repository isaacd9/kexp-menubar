//
//  kexp_menubarApp.swift
//  kexp-menubar
//
//  Created by Isaac Diamond on 2/16/26.
//

import SwiftUI

@main
struct kexp_menubarApp: App {
    var body: some Scene {
        MenuBarExtra("KEXP", image: "MenuBarIcon") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
