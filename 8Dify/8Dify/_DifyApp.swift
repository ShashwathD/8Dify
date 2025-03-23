//
//  _DifyApp.swift
//  8Dify
//
//  Created by Shashwath Dinesh on 3/22/25.
//

import SwiftUI

@main
struct _DifyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
