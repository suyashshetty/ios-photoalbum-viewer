//
//  CoreImageViewerWrapper.swift
//  PhotoAlbumViewer
//
//  Created by Suyash Shetty on 8/16/24.
//

import SwiftUI
import Cocoa

/**
 A SwiftUI wrapper for the `CoreImageViewer` view controller.

 This struct conforms to the `NSViewControllerRepresentable` protocol, allowing
 the `CoreImageViewer` to be used within a SwiftUI view hierarchy.

 - Author: Suyash Shetty
 - Version: 1.0
 */
struct CoreImageViewerWrapper: NSViewControllerRepresentable {
    
    /**
     Creates and returns a new `CoreImageViewer` view controller.

     - Parameter context: The context in which the view controller is created.
     
     - Returns: A new instance of `CoreImageViewer`.

     - Note: This method is used to instantiate the view controller for the
       SwiftUI view hierarchy.
     */
    func makeNSViewController(context: Context) -> CoreImageViewer {
        return CoreImageViewer()
    }
    
    /**
     Updates the `CoreImageViewer` view controller with new information.

     - Parameters:
       - nsViewController: The `CoreImageViewer` instance to update.
       - context: The context in which the update occurs.

     - Note: This method can be used to pass any updates or changes to the
       view controller if needed.
     */
    func updateNSViewController(_ nsViewController: CoreImageViewer, context: Context) {
        // Update the view controller if needed
    }
}

/**
 A SwiftUI view that embeds the `CoreImageViewerWrapper`.

 This view configures the size of the embedded `CoreImageViewer` to a minimum
 width of 800 points and a minimum height of 600 points.

 - Author: Suyash Shetty
 - Version: 1.0
 */
struct ContentView: View {
    var body: some View {
        CoreImageViewerWrapper()
            .frame(minWidth: 800, minHeight: 600)
    }
}
