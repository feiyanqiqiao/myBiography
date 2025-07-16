//
//  myBiographyApp.swift
//  myBiography
//
//  Created by zhangqiao on 2025/7/16.
//

import SwiftUI

@main
struct myBiographyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
