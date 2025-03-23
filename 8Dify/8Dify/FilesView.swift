//
//  FilesView.swift
//  8Dify
//
//  Created by Shashwath Dinesh on 3/22/25.
//

import SwiftUI
//import AVFoundation
//import UniformTypeIdentifiers
import UIKit

struct FilesView: View {
    var body: some View {
        NavigationView {
            VStack {
                AudioPlayerView()
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 4)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Audio Player")
        }
    }
}
