//
//  ImageViewerModule.swift
//  PhotoAlbumViewer
//
//  Created by Suyash Shetty on 8/16/24.
//

import Cocoa

protocol ImageViewerModule {
    func handleKeyEvent(_ event: NSEvent, in imageView: NSImageView)
}

