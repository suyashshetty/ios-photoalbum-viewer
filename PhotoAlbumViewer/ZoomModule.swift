//
//  ZoomModule.swift
//  PhotoAlbumViewer
//
//  Created by Suyash Shetty on 8/16/24.
//

import Cocoa

class ZoomModule {
    
    private var imageView: NSImageView
    
    init(imageView: NSImageView) {
        self.imageView = imageView
        addPanGestureRecognizer()
    }
    
    func handleZoom(by factor: CGFloat, mouseLocation: NSPoint) {
        guard let image = imageView.image else { return }

        let mouseLocationInImageView = imageView.convert(mouseLocation, from: nil)
        let currentSize = image.size
        let newSize = NSSize(width: currentSize.width * factor, height: currentSize.height * factor)

        imageView.image = resizeImage(image, to: newSize)
        imageView.frame.size = newSize

        let newMouseLocationInImageView = NSPoint(
            x: mouseLocationInImageView.x * factor,
            y: mouseLocationInImageView.y * factor
        )

        let deltaX = newMouseLocationInImageView.x - mouseLocationInImageView.x
        let deltaY = newMouseLocationInImageView.y - mouseLocationInImageView.y

        imageView.frame.origin.x -= deltaX
        imageView.frame.origin.y -= deltaY
    }
    
    @objc func handlePanGesture(_ gestureRecognizer: NSPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: imageView)
        imageView.frame.origin.x += translation.x
        imageView.frame.origin.y += translation.y
        gestureRecognizer.setTranslation(.zero, in: imageView)
        clampImageViewToBounds()
    }

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
    
    private func addPanGestureRecognizer() {
        let panGestureRecognizer = NSPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        imageView.addGestureRecognizer(panGestureRecognizer)
    }
    
    private func clampImageViewToBounds() {
        guard let superview = imageView.superview else { return }

        let minX = min(0, superview.bounds.width - imageView.frame.width)
        let minY = min(0, superview.bounds.height - imageView.frame.height)

        imageView.frame.origin.x = max(minX, min(imageView.frame.origin.x, 0))
        imageView.frame.origin.y = max(minY, min(imageView.frame.origin.y, 0))
    }
}



