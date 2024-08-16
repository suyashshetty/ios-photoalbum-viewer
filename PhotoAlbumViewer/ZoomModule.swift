//
//  ZoomModule.swift
//  PhotoAlbumViewer
//
//  Created by Suyash Shetty on 8/16/24.
//

import Cocoa

/**
 A module that handles zooming and panning of an `NSImageView`.
 
 This class provides functionality to zoom an image in the `NSImageView` by a
 specified factor and handle panning gestures to move the image around. It
 ensures that the image view remains within the bounds of its superview.
 
 - Author: Suyash Shetty
 - Version: 1.0
 */
class ZoomModule {
    
    /// The `NSImageView` instance that this module operates on.
    private var imageView: NSImageView
    
    /**
     Initializes a `ZoomModule` with the specified `NSImageView`.
     
     - Parameter imageView: The `NSImageView` instance that will be zoomed and
     panned.
     */
    init(imageView: NSImageView) {
        self.imageView = imageView
        addPanGestureRecognizer()
    }
    
    /**
     Zooms the image in the `NSImageView` by a specified factor.
     
     - Parameters:
     - factor: The zoom factor. Values greater than 1.0 will zoom in, and
     values less than 1.0 will zoom out.
     - mouseLocation: The location of the mouse pointer during the zoom
     operation, used to adjust the zoom origin.
     
     - Note: The zoom operation scales the image and adjusts the image view's
     frame to maintain the zoom effect centered around the mouse location.
     */
    func handleZoom(by factor: CGFloat, mouseLocation: NSPoint) {
        guard let image = imageView.image else { return }
        guard let superview = imageView.superview else { return }
        
        var maxZoom : CGFloat = 3.0
        
        let mouseLocationInImageView = imageView.convert(mouseLocation, from: nil)
        let currentSize = image.size
        
        // Calculate the new size with bounds checking
        var newSize: CGSize
        
        if factor == 0.9 {
            // Zooming out
            newSize = NSSize(width: max(currentSize.width * factor, superview.bounds.width / maxZoom),
                             height: max(currentSize.height * factor, superview.bounds.height / maxZoom))
        } else {
            // Zooming in
            let maxAllowedWidth = superview.bounds.width * maxZoom
            let maxAllowedHeight = superview.bounds.height * maxZoom
            
            newSize = NSSize(width: min(currentSize.width * factor, maxAllowedWidth),
                             height: min(currentSize.height * factor, maxAllowedHeight))
        }
        
        if(factor == 1.1 && newSize.width < currentSize.width * factor && newSize.height < currentSize.height * factor){
            return
        }
        else if(newSize.width > currentSize.width * factor && newSize.height > currentSize.height * factor){
            return
        }
        
        imageView.image = resizeImage(image, to: newSize)
        imageView.frame.size = newSize
        
        let newMouseLocationInImageView = NSPoint(
            x: mouseLocationInImageView.x * factor,
            y: mouseLocationInImageView.y * factor
        )
        
        var deltaX = newMouseLocationInImageView.x - mouseLocationInImageView.x
        var deltaY = newMouseLocationInImageView.y - mouseLocationInImageView.y
        
        imageView.frame.origin.x -= deltaX
        imageView.frame.origin.y -= deltaY
    }
    
    
    
    /**
     Handles the pan gesture to move the image within the `NSImageView`.
     
     - Parameter gestureRecognizer: The `NSPanGestureRecognizer` instance
     responsible for the gesture event.
     
     - Note: The method updates the image view's frame origin based on the
     translation from the pan gesture and ensures the image view stays
     within its superview's bounds.
     */
    @objc func handlePanGesture(_ gestureRecognizer: NSPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: imageView)
        imageView.frame.origin.x += translation.x
        imageView.frame.origin.y += translation.y
        gestureRecognizer.setTranslation(.zero, in: imageView)
        clampImageViewToBounds()
    }
    
    /**
     Resizes an image to the specified target size.
     
     - Parameters:
     - image: The `NSImage` instance to resize.
     - targetSize: The desired size for the image.
     
     - Returns: A new `NSImage` instance resized to the target size.
     
     - Note: This method creates a new image with the given size and draws the
     original image into it.
     */
    private func resizeImage(_ image: NSImage, to targetSize: NSSize) -> NSImage? {
        let newImage = NSImage(size: targetSize)
        
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: targetSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        
        return newImage
    }
    
    /**
     Adds a pan gesture recognizer to the `NSImageView` for handling drag
     operations.
     
     - Note: This method configures the image view to recognize and respond to
     pan gestures, allowing for image panning.
     */
    private func addPanGestureRecognizer() {
        let panGestureRecognizer = NSPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        imageView.addGestureRecognizer(panGestureRecognizer)
    }
    
    /**
     Clamps the image view's position to ensure it stays within the bounds of
     its superview.
     
     - Note: This method adjusts the image view's frame origin if it exceeds the
     boundaries of its superview to prevent it from being dragged out of view.
     */
    private func clampImageViewToBounds() {
        guard let superview = imageView.superview else { return }
        
        let minX = min(0, superview.bounds.width - imageView.frame.width)
        let minY = min(0, superview.bounds.height - imageView.frame.height)
        
        imageView.frame.origin.x = max(minX, min(imageView.frame.origin.x, 0))
        imageView.frame.origin.y = max(minY, min(imageView.frame.origin.y, 0))
    }
}
