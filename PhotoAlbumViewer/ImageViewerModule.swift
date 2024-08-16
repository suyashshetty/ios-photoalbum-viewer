//
//  ImageViewerModule.swift
//  PhotoAlbumViewer
//
//  Created by Suyash Shetty on 8/16/24.
//

import Cocoa

/**
 A protocol that defines the interface for an image viewer module.

 The `ImageViewerModule` protocol provides methods for handling key events in
 an `NSImageView` and adding buttons to a view. Classes conforming to this
 protocol should implement these methods to support image viewing functionality.

 - Author: Suyash Shetty
 - Version: 1.0
 */
protocol ImageViewerModule {
    
    /**
     Handles key events for an image viewer.

     - Parameters:
       - event: The `NSEvent` representing the key event.
       - imageView: The `NSImageView` instance where the key event occurs.

     - Note: This method is used to process key events such as navigation or
       other actions related to the image viewing.
     */
    func handleKeyEvent(_ event: NSEvent, in imageView: NSImageView)
    
    /**
     Adds a button to a specified view.

     - Parameters:
       - view: The `NSView` to which the button will be added.
       - target: The object that receives the action message.
       - action: The selector to be sent to the target when the button is clicked.

     - Note: This method is used to configure and add buttons to the given view
       for user interaction.
     */
    func addButton(to view: NSView, target: Any, action: Selector)
}
