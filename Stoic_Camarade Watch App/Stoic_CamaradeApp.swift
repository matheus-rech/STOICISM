//
//  Stoic_CamaradeApp.swift
//  Stoic_Camarade Watch App
//
//  Created by Matheus Rech on 1/14/26.
//

import SwiftUI
import UserNotifications

@main
struct Stoic_Camarade_Watch_AppApp: App {
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationManager)
                .task {
                    // Request notification authorization on launch
                    _ = await NotificationManager.shared.requestAuthorization()
                    await NotificationManager.shared.scheduleAllNotifications()
                }
        }
    }
}
