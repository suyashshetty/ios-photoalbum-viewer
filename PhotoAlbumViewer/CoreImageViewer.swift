import Cocoa

class CoreImageViewer: NSViewController, NSWindowDelegate {
    
    var imageView: NSImageView!
    var imagePaths: [String] = []
    var currentIndex: Int = 0
    
    // Buttons
    var openFolderButton: NSButton!
    var nextButton: NSButton!
    var previousButton: NSButton!
    var closeButton: NSButton!
    
    // Variables for key press debounce
    private var lastKeyPressTime: TimeInterval = 0
    private let debounceDelay: TimeInterval = 0.2
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Set the window size to 400x200 pixels
        if let window = self.view.window {
            window.setContentSize(NSSize(width: 400, height: 200))
            window.center() // Center the window on the screen
            window.delegate = self // Set the delegate to handle window events
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
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.autoresizingMask = [.width, .height]
        self.view.addSubview(imageView)
        
        // Set the view to accept key events
        self.view.window?.makeFirstResponder(self)
        
        // Initialize the "Open Folder" button
        openFolderButton = NSButton(title: "Open Folder", target: self, action: #selector(openFolder))
        openFolderButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(openFolderButton)
        
        // Position the "Open Folder" button at the center of the view
        NSLayoutConstraint.activate([
            openFolderButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            openFolderButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
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
                imageView.image = resizeImage(image)
            }
        }
    }
    
    // Resize the image to fit the view's dimensions
    private func resizeImage(_ image: NSImage) -> NSImage? {
        let targetSize = self.view.bounds.size
        let newImage = NSImage(size: targetSize)
        
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: targetSize),
                   from: .zero,
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        
        return newImage
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
        if event.deltaY > 0 {
            moveToPreviousImage()
        } else if event.deltaY < 0 {
            moveToNextImage()
        }
    }
    
    // Move to the previous image in the folder
    @objc func moveToPreviousImage() {
        currentIndex = max(currentIndex - 1, 0)
        displayImage(at: currentIndex)
    }
    
    // Move to the next image in the folder
    @objc func moveToNextImage() {
        currentIndex = min(currentIndex + 1, imagePaths.count - 1)
        displayImage(at: currentIndex)
    }
}
