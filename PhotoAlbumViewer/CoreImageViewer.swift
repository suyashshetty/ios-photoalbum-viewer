import Cocoa

class CoreImageViewer: NSViewController, NSWindowDelegate {
    
    var imageView: NSImageView!
    var imagePaths: [String] = []
    var currentIndex: Int = 0
    var modules: [ImageViewerModule] = []
    
    // Buttons
    var openFolderButton: NSButton!
    var nextButton: NSButton!
    var previousButton: NSButton!
    var closeButton: NSButton!
    
    // Variables for key press debounce
    private var lastKeyPressTime: TimeInterval = 0
    private let debounceDelay: TimeInterval = 0.2
    private var resizeTimer: Timer?
    private var zoomModule: ZoomModule?
    
    override func viewWillAppear() {
        super.viewWillAppear()

        if let window = self.view.window {
            window.setContentSize(NSSize(width: 400, height: 200))
            window.center()
            window.delegate = self
        }
    }

    
    // Handle window close event
    func windowWillClose(_ notification: Notification) {
        NSApplication.shared.terminate(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the image view to cover the entire view
        imageView = NSImageView(frame: self.view.bounds)
        imageView.imageScaling = .scaleNone
        imageView.autoresizingMask = [.width, .height]
        self.view.addSubview(imageView)

        // Initialize the "Open Folder" button
        openFolderButton = NSButton(title: "Open Folder", target: self, action: #selector(openFolder))
        openFolderButton.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(openFolderButton)
        
        // Log to confirm button creation
        print("Open Folder button created and added to view.")

        // Position the "Open Folder" button at the center of the view
        NSLayoutConstraint.activate([
            openFolderButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            openFolderButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])

        // Set the view to accept key events
        DispatchQueue.main.async {
            self.view.window?.makeFirstResponder(self)
        }

        // Initialize and add the navigation buttons
        initializeNavigationButtons()
        
        // Add a double-click gesture recognizer to reload the image
        let doubleClickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(reloadImageOriginal))
        doubleClickRecognizer.numberOfClicksRequired = 2
        imageView.addGestureRecognizer(doubleClickRecognizer)
        
        // Initialize the ZoomModule
        zoomModule = ZoomModule(imageView: imageView)

    }

    
    private func initializeNavigationButtons() {
        // Initialize the navigation buttons
        previousButton = NSButton(title: "Previous", target: self, action: #selector(moveToPreviousImage))
        nextButton = NSButton(title: "Next", target: self, action: #selector(moveToNextImage))
        closeButton = NSButton(title: "Close Folder", target: self, action: #selector(closeFolder))
        
        // Customize button appearance
        customizeButtonAppearance(button: previousButton)
        customizeButtonAppearance(button: nextButton)
        customizeButtonAppearance(button: closeButton)
        
        // Disable autoresizing mask translation for the navigation buttons
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the buttons to the view
        self.view.addSubview(previousButton)
        self.view.addSubview(nextButton)
        self.view.addSubview(closeButton)
        
        // Position the navigation buttons horizontally next to each other at the bottom
        NSLayoutConstraint.activate([
            previousButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            previousButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20),
            
            nextButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20),
            
            closeButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            closeButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20)
        ])
        
        // Hide the navigation buttons initially
        previousButton.isHidden = true
        nextButton.isHidden = true
        closeButton.isHidden = true
    }
    
    func customizeButtonAppearance(button: NSButton) {
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.darkGray.cgColor
        button.layer?.cornerRadius = 5.0
        button.attributedTitle = NSAttributedString(
            string: button.title,
            attributes: [
                .foregroundColor: NSColor.white,
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ]
        )
    }

    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        // Invalidate any existing timer
        resizeTimer?.invalidate()

        // Set a timer to reload the image after the user stops resizing
        resizeTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            self.displayImage(at: self.currentIndex)
        }
    }
    
    private func calculateOptimalSize(for image: NSImage, in availableSize: NSSize) -> NSSize {
        let imageSize = image.size
        
        // Calculate the aspect ratios
        let imageAspectRatio = imageSize.width / imageSize.height
        let viewAspectRatio = availableSize.width / availableSize.height
        
        // Determine if the image should scale based on width or height
        var targetSize: NSSize
        if imageAspectRatio > viewAspectRatio {
            // Image is wider than the view, scale by width
            let scaledHeight = availableSize.width / imageAspectRatio
            targetSize = NSSize(width: availableSize.width, height: scaledHeight)
        } else {
            // Image is taller than the view, scale by height
            let scaledWidth = availableSize.height * imageAspectRatio
            targetSize = NSSize(width: scaledWidth, height: availableSize.height)
        }
        
        return targetSize
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

    
    @objc func openFolder() {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a folder containing images"
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false
        dialog.allowsMultipleSelection = false
        
        if dialog.runModal() == .OK {
            if let url = dialog.url {
                print("Folder selected: \(url)")
                loadImages(from: url)
                
                // Hide the "Open Folder" button and show navigation buttons
                openFolderButton.isHidden = true
                previousButton.isHidden = false
                nextButton.isHidden = false
                closeButton.isHidden = false
            }
        }
    }
    
    @objc func closeFolder() {
        // Clear the images and show the "Open Folder" button again
        imagePaths = []
        imageView.image = nil
        openFolderButton.isHidden = false
        previousButton.isHidden = true
        nextButton.isHidden = true
        closeButton.isHidden = true
    }
    
    // Load image files from the selected folder in a background thread
    func loadImages(from folder: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            do {
                let files = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                let filteredPaths = files.filter { ["jpg", "jpeg", "png", "gif"].contains($0.pathExtension.lowercased()) }.map { $0.path }
                
                DispatchQueue.main.async {
                    self.imagePaths = filteredPaths.sorted() // Sort files alphabetically
                    self.currentIndex = 0
                    self.displayImage(at: self.currentIndex)
                }
            } catch {
                print("Error loading images: \(error)")
            }
        }
    }
    
    // Display the current image with resizing for efficiency
    func displayImage(at index: Int) {
        guard index >= 0 && index < imagePaths.count else { return }
        let imagePath = imagePaths[index]
        
        autoreleasepool {
            if let image = NSImage(contentsOfFile: imagePath) {
                // Calculate the optimal size for the image, ensuring it's not scaled up
                let optimalSize = calculateOptimalSize(for: image, in: imageView.bounds.size)
                
                // Resize the image to the optimal size and set it to the image view
                imageView.image = resizeImage(image, to: optimalSize)
            }
        }
    }
    
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    // Handle key events with debounce to prevent multiple rapid presses
    override func keyDown(with event: NSEvent) {
        let currentTime = Date().timeIntervalSince1970
        guard currentTime - lastKeyPressTime > debounceDelay else { return }
        lastKeyPressTime = currentTime
        
        switch event.keyCode {
        case 123: // Left arrow key code
            moveToPreviousImage()
        case 124: // Right arrow key code
            moveToNextImage()
        default:
            super.keyDown(with: event)
        }
    }
    
    // Handle scroll events for navigation
    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            let zoomFactor: CGFloat = event.deltaY > 0 ? 1.1 : 0.9
            zoomModule?.handleZoom(by: zoomFactor, mouseLocation: event.locationInWindow)
        } else {
            super.scrollWheel(with: event)
            if event.deltaY > 0 {
                moveToPreviousImage()
            } else if event.deltaY < 0 {
                moveToNextImage()
            }
        }
    }
    
    // Move to the previous image in the folder
    @objc func moveToPreviousImage() {
        resetImageView() // Reset zoom and position
        currentIndex = max(currentIndex - 1, 0)
        displayImage(at: currentIndex)
    }
    
    // Move to the next image in the folder
    @objc func moveToNextImage() {
        resetImageView() // Reset zoom and position
        currentIndex = min(currentIndex + 1, imagePaths.count - 1)
        displayImage(at: currentIndex)
    }
    
    private func resetImageView() {
        // Reset the image view's frame size to match the window bounds
        imageView.frame = self.view.bounds
        
        // Reset the image view's position to the top-left corner of the view
        imageView.frame.origin = NSPoint(x: 0, y: 0)
        
        // Remove any existing image from the image view
        imageView.image = nil
    }

    @objc func reloadImageOriginal() {
        resetImageView();
        displayImage(at: currentIndex)
    }
}
