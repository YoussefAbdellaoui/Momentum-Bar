//
//  MomentumBarApp.swift
//  MomentumBar
//
//  Created by Youssef Abdellaoui on 01.01.26.
//

import SwiftUI

@main
struct MomentumBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
