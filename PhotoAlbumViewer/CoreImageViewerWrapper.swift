//
//  CoreImageViewerWrapper.swift
//  PhotoAlbumViewer
//
//  Created by Suyash Shetty on 8/16/24.
//

import SwiftUI
import Cocoa

struct CoreImageViewerWrapper: NSViewControllerRepresentable {
    
    func makeNSViewController(context: Context) -> CoreImageViewer {
        return CoreImageViewer()
    }
    
    func updateNSViewController(_ nsViewController: CoreImageViewer, context: Context) {
        // Update the view controller if needed
    }
}

struct ContentView: View {
    var body: some View {
            CoreImageViewerWrapper()
                .frame(minWidth: 800, minHeight: 600)
        }
}

