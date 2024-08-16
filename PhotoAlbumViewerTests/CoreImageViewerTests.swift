//
//  CoreImageViewerTests.swift
//  PhotoAlbumViewerTests
//
//  Created by Suyash Shetty on 8/16/24.
//

import XCTest
@testable import PhotoAlbumViewer

class CoreImageViewerTests: XCTestCase {

    var coreImageViewer: CoreImageViewer!
    
    override func setUpWithError() throws {
        // Initialize the CoreImageViewer before each test
        coreImageViewer = CoreImageViewer()
        coreImageViewer.loadViewIfNeeded()
    }

    override func tearDownWithError() throws {
        // Clean up after each test
        coreImageViewer = nil
    }

    func testInitialWindowSetup() throws {
        // Create a window and set CoreImageViewer as its content view controller
        let window = NSWindow(contentRect: NSMakeRect(0, 0, 400, 200),
                              styleMask: [.titled, .closable, .resizable],
                              backing: .buffered, defer: false)
        window.contentViewController = coreImageViewer
        window.makeKeyAndOrderFront(nil)
        
        // Call viewWillAppear to simulate the view appearing
        coreImageViewer.viewWillAppear()
        
        XCTAssertNotNil(coreImageViewer.view.window, "Window should not be nil")
        XCTAssertEqual(coreImageViewer.view.window?.contentViewController, coreImageViewer, "Window's content view controller should be CoreImageViewer")
        
        // Adjusting the check to focus on the contentView's frame
        let expectedSize = NSSize(width: 400, height: 200)
        XCTAssertEqual(coreImageViewer.view.frame.size, expectedSize, "Content view size should be 400x200")
    }



    func testOpenFolderButtonExists() throws {
        // Test that the Open Folder button is present
        XCTAssertNotNil(coreImageViewer.openFolderButton, "Open Folder button should be initialized")
        XCTAssertEqual(coreImageViewer.openFolderButton.title, "Open Folder", "Open Folder button should have the correct title")
    }
    
    func testNavigationButtonsHiddenInitially() throws {
        // Test that navigation buttons are hidden initially
        XCTAssertTrue(coreImageViewer.previousButton.isHidden, "Previous button should be hidden initially")
        XCTAssertTrue(coreImageViewer.nextButton.isHidden, "Next button should be hidden initially")
        XCTAssertTrue(coreImageViewer.closeButton.isHidden, "Close Folder button should be hidden initially")
    }
    
    func testLoadImagesFromValidFolder() throws {
        // Create a temporary directory
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let testFolderURL = tempDirectory.appendingPathComponent("TestImages")
        try fileManager.createDirectory(at: testFolderURL, withIntermediateDirectories: true, attributes: nil)
        
        // Add a dummy image
        let dummyImagePath = testFolderURL.appendingPathComponent("test.jpg")
        let dummyImage = NSImage(size: NSSize(width: 10, height: 10))
        dummyImage.lockFocus()
        NSColor.red.setFill()
        NSBezierPath.fill(NSRect(x: 0, y: 0, width: 10, height: 10))
        dummyImage.unlockFocus()
        
        if let imageData = dummyImage.tiffRepresentation {
            try imageData.write(to: dummyImagePath)
        }
        
        // Load the images
        coreImageViewer.loadImages(from: testFolderURL)
        
        // Allow some time for the images to load
        let expectation = self.expectation(description: "Images loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0, handler: nil)
        
        // Verify the images are loaded
        XCTAssertEqual(coreImageViewer.imagePaths.count, 1, "There should be 1 image loaded")
        XCTAssertEqual(coreImageViewer.imagePaths.first, dummyImagePath.path, "The path of the loaded image should be correct")
    }


    
    func testMoveToNextImage() throws {
        // Setup a scenario where images are loaded
        let imagePaths = ["/path/to/image1.jpg", "/path/to/image2.jpg"]
        coreImageViewer.imagePaths = imagePaths
        coreImageViewer.currentIndex = 0
        
        // Move to next image
        coreImageViewer.moveToNextImage()
        XCTAssertEqual(coreImageViewer.currentIndex, 1, "Current index should be 1 after moving to next image")
    }
    
    func testMoveToPreviousImage() throws {
        // Setup a scenario where images are loaded
        let imagePaths = ["/path/to/image1.jpg", "/path/to/image2.jpg"]
        coreImageViewer.imagePaths = imagePaths
        coreImageViewer.currentIndex = 1
        
        // Move to previous image
        coreImageViewer.moveToPreviousImage()
        XCTAssertEqual(coreImageViewer.currentIndex, 0, "Current index should be 0 after moving to previous image")
    }
    
    func testLeftArrowKeyEvent() throws {
        // Setup a scenario where images are loaded
        let imagePaths = ["/path/to/image1.jpg", "/path/to/image2.jpg"]
        coreImageViewer.imagePaths = imagePaths
        coreImageViewer.currentIndex = 1  // Start at the second image
        
        // Simulate left arrow key press
        let leftArrowEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: TimeInterval(),
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: 123 // Left arrow key code
        )
        
        coreImageViewer.keyDown(with: leftArrowEvent!)
        
        // Verify that the index has moved to the previous image
        XCTAssertEqual(coreImageViewer.currentIndex, 0, "Current index should be 0 after pressing the left arrow key")
    }

    func testRightArrowKeyEvent() throws {
        // Setup a scenario where images are loaded
        let imagePaths = ["/path/to/image1.jpg", "/path/to/image2.jpg"]
        coreImageViewer.imagePaths = imagePaths
        coreImageViewer.currentIndex = 0  // Start at the first image
        
        // Simulate right arrow key press
        let rightArrowEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: TimeInterval(),
            windowNumber: 0,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: 124 // Right arrow key code
        )
        
        coreImageViewer.keyDown(with: rightArrowEvent!)
        
        // Verify that the index has moved to the next image
        XCTAssertEqual(coreImageViewer.currentIndex, 1, "Current index should be 1 after pressing the right arrow key")
    }

}

