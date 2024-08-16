//
//  PhotoAlbumViewerApp.swift
//  PhotoAlbumViewer
//
//  Created by Suyash Shetty on 8/16/24.
//

import SwiftUI

@main
struct PhotoAlbumViewerApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        window.title = "Photo Viewer"
                    }
                }
        }
    }
}


