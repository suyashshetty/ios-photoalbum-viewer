import Cocoa


/**
 * `CoreImageViewer` is a view controller for displaying and navigating through
 * images in a macOS application. It provides functionality to open folders,
 * navigate through images, handle zooming, and respond to key and mouse events.
 */
class CoreImageViewer: NSViewController, NSWindowDelegate {
    
    var imageView: NSImageView!
    var imagePaths: [String] = []
    var currentIndex: Int = 0
    var modules: [ImageViewerModule] = []
    var navButtons: [NSButton] = []
    
    var noImagesLabel: NSTextField!
    
    // Buttons
    var openFolderButton: NSButton!
    var nextButton: NSButton!
    var previousButton: NSButton!
    var closeButton: NSButton!
    var trashButton: NSButton!
    var chooseButton: NSButton!
    
    
    // Variables for key press debounce
    private var lastKeyPressTime: TimeInterval = 0
    private let debounceDelay: TimeInterval = 0.2
    private var resizeTimer: Timer?
    private var zoomModule: ZoomModule?
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let screenSize = NSScreen.main?.frame.size {
            let windowWidth = screenSize.width * 0.8
            let windowHeight = screenSize.height * 0.8
            let newSize = NSSize(width: windowWidth, height: windowHeight)
            
            if let window = self.view.window {
                window.setContentSize(newSize)
                window.center() // Center the window on the screen
                window.delegate = self
            }
        }
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.makeFirstResponder(self)
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
        
        //Initialize error message label when no images are found
        initializeNoImageLabel()
        
        // Initialize the "Open Folder" button
        initializeOpenFolderButton()
        
        // Initialize the navigation buttons
        initializeNavigationButtons()
        
        // Add a double-click gesture recognizer to reload the image
        let doubleClickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(reloadImageOriginal))
        doubleClickRecognizer.numberOfClicksRequired = 2
        imageView.addGestureRecognizer(doubleClickRecognizer)
        
        // Initialize the ZoomModule
        zoomModule = ZoomModule(imageView: imageView)
    }
    
    private func initializeNoImageLabel(){
        // Initialize the "No Images Found" label
        noImagesLabel = NSTextField(labelWithString: "No image files found")
        noImagesLabel.font = NSFont.systemFont(ofSize: 24)
        noImagesLabel.alignment = .center
        noImagesLabel.isHidden = true
        noImagesLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(noImagesLabel)
        
        // Center the label in the view
        NSLayoutConstraint.activate([
            noImagesLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            noImagesLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }
    
    private func initializeOpenFolderButton(){
        openFolderButton = NSButton(title: "Open Folder", target: self, action: #selector(openFolder))
        openFolderButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(openFolderButton)
        
        // Position the "Open Folder" button at the center of the view
        NSLayoutConstraint.activate([
            openFolderButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            openFolderButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }
    
    private func initializeNavigationButtons(){
        previousButton = NSButton(title: "Previous", target: self, action: #selector(moveToPreviousImage))
        nextButton = NSButton(title: "Next", target: self, action: #selector(moveToNextImage))
        closeButton = NSButton(title: "Close Folder", target: self, action: #selector(closeFolder))
        trashButton = NSButton(title: "Trash", target: self, action: #selector(moveToTrash))
        chooseButton = NSButton(title: "Choose Another", target: self, action: #selector(openFolder))
        
        // Store navigation buttons in an array
        navButtons = [previousButton, nextButton, closeButton, chooseButton, trashButton]
        
        // Initialize and position buttons with default visibility
        configureNavButtons(buttons: navButtons)
        
        // Position the navigation buttons
        positionButtons(buttons: navButtons)
    }
    
    private func configureNavButtons(buttons: [NSButton], isHidden: Bool = true) {
        for button in buttons {
            // Customize button appearance
            customizeButtonAppearance(button: button)
            
            // Add the button to the view
            button.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(button)
            
            // Set initial visibility for the button
            button.isHidden = isHidden
        }
    }
    
    
    private func positionButtons(buttons: [NSButton]) {
        let buttonCount = buttons.count
        guard buttonCount > 0 else { return }
        
        // Create a horizontal stack view to hold the buttons and space them evenly
        let stackView = NSStackView(views: buttons)
        stackView.orientation = .horizontal
        //stackView.distribution = .equalSpacing
        stackView.distribution = .fillEqually // Ensures buttons are of equal width
        stackView.alignment = .centerY
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the stack view to the view
        self.view.addSubview(stackView)
        
        // Position the stack view at the bottom center of the view
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20)
        ])
        
        // Make sure the buttons have equal widths
        NSLayoutConstraint.activate(
            buttons.map { button in
                button.widthAnchor.constraint(equalTo: buttons.first!.widthAnchor)
            }
        )
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
    
    private func setNavigationVisible(isHidden: Bool, buttons: [NSButton]) {
        for button in buttons {
            button.isHidden = isHidden
        }
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
                openFolderButton?.isHidden = true
                setNavigationVisible(isHidden: false, buttons: navButtons)
            }
        }
    }
    
    @objc func closeFolder() {
        // Clear the images and show the "Open Folder" button again
        imagePaths = []
        imageView.image = nil
        openFolderButton?.isHidden = false
        setNavigationVisible(isHidden: true, buttons: navButtons)
        noImagesLabel?.isHidden = true
    }
    
    // Load image files from the selected folder in a background thread
    func loadImages(from folder: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            do {
                let files = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                let filteredPaths = files.filter { ["jpg", "jpeg", "png", "gif"].contains($0.pathExtension.lowercased()) }.map { $0.path }
                
                DispatchQueue.main.async {
                    if filteredPaths.isEmpty {
                        // No images found, show the label
                        self.noImagesLabel.isHidden = false
                        self.imagePaths = []
                        self.imageView.image = nil
                    } else {
                        // Images found, hide the label
                        self.noImagesLabel.isHidden = true
                        self.imagePaths = filteredPaths.sorted() // Sort files alphabetically
                        self.currentIndex = 0
                        self.displayImage(at: self.currentIndex)
                    }
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
    
    // Handle key events with debounce to prevent multiple rapid presses
    override func keyDown(with event: NSEvent) {
        let currentTime = Date().timeIntervalSince1970
        guard currentTime - lastKeyPressTime > debounceDelay else { return }
        lastKeyPressTime = currentTime
        
        if event.modifierFlags.contains(.command) {
            handleCommandKeyCombination(with: event)
        } else {
            switch event.keyCode {
            case 123: // Left arrow key code
                moveToPreviousImage()
            case 124: // Right arrow key code
                moveToNextImage()
            case 117: // Delete key code
                moveToTrash()
            default:
                super.keyDown(with: event)
            }
        }
    }
    
    //Adding short cut keys
    private func handleCommandKeyCombination(with event: NSEvent) {
        guard let key = event.charactersIgnoringModifiers?.lowercased() else { return }
        
        switch key {
        case "c":
            closeFolder()
        case "o":
            openFolder()
            // Add more cases here as needed
        default:
            break
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
        resetImageView();// Reset zoom and position
        displayImage(at: currentIndex)
    }
    
    
    @objc func moveToTrash() {
        guard !imagePaths.isEmpty, currentIndex >= 0, currentIndex < imagePaths.count else {
            return
        }
        
        // Create the confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Are you sure you want to move this image to the trash?"
        alert.informativeText = "This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")
        
        // Show the alert and handle the user's response
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // The user confirmed, proceed with moving the image to the trash
            let filePath = imagePaths[currentIndex]
            let fileURL = URL(fileURLWithPath: filePath)
            
            let trash = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first!
            var trashURL = trash.appendingPathComponent(fileURL.lastPathComponent)
            
            // Check if the file already exists in the trash
            if FileManager.default.fileExists(atPath: trashURL.path) {
                // If it exists, append a timestamp to the file name
                let timestamp = Date().timeIntervalSince1970
                let newFileName = "\(fileURL.deletingPathExtension().lastPathComponent)-\(timestamp).\(fileURL.pathExtension)"
                trashURL = trash.appendingPathComponent(newFileName)
            }
            
            do {
                try FileManager.default.moveItem(at: fileURL, to: trashURL)
                print("Moved \(filePath) to trash.")
                
                // Update the image list after trashing
                updateImageListAfterTrash()
                
                // Check if there are no more images left
                if imagePaths.isEmpty {
                    noImagesLabel.isHidden = false
                    hideNavigationButtons()
                }
            } catch {
                print("Error moving file to trash: \(error.localizedDescription)")
            }
        } else {
            // The user canceled, do nothing
            print("Move to trash canceled.")
        }
    }
    
    
    private func updateImageListAfterTrash() {
        // Remove the current image from the list
        imagePaths.remove(at: currentIndex)
        
        // Adjust the currentIndex
        if currentIndex >= imagePaths.count {
            currentIndex = imagePaths.count - 1
        }
        
        // Check if there are images left to display
        if !imagePaths.isEmpty {
            displayImage(at: currentIndex)
        } else {
            // Hide the image view and show the "No Images" label
            imageView.image = nil
            noImagesLabel.isHidden = false
            hideNavigationButtons()
        }
    }
    
    //Handle when all images in folder are deleted
    private func hideNavigationButtons() {
        setNavigationVisible(isHidden: true, buttons: navButtons)
        chooseButton.isHidden = false
    }
    
}


