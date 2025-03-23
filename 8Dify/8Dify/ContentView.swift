//
//  ContentView.swift
//  8Dify
//
//  Created by Shashwath Dinesh on 3/22/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor.clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.9)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                
                TabView {
                    UploadView()
                        .tabItem {
                            Label("Process", systemImage: "waveform")
                        }
                    
                    FilesView()
                        .tabItem {
                            Label("Files", systemImage: "list.bullet")
                        }
                }
                .accentColor(.purple) 
                
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
