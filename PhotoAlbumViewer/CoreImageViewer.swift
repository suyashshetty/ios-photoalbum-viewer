import Cocoa


/**
 * `CoreImageViewer` is a view controller for displaying and navigating through
 * images in a macOS application. It provides functionality to open folders,
 * navigate through images, handle zooming, and respond to key and mouse events.
 */
class CoreImageViewer: NSViewController, NSWindowDelegate {
    
    var splitView: NSSplitView!
    var leftPanel: NSView!
    var rightPanel: NSView!
    
    var imageView: NSImageView!
    var imagePaths: [String] = []
    var currentIndex: Int = 0
    var modules: [ImageViewerModule] = []
    var navButtons: [NSButton] = []
    
    var noImagesLabel: NSTextField!
    var scanDirectoryLabel: NSTextField!

    var folderIcon:NSImage!
    
    // Buttons
    var openFolderButton: NSButton!
    var scanDirectoryButton: NSButton!
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
    private var imageFolderScanner: ImageFolderScanModule?
    private var dropdownModule: DropdownDisplayModule!
    private var treeViewModule: TreeViewModule!
    
    private var cache: TrieCacheModule!

    
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

        // Set up the main layout with left and right panels
        setupMainLayout()

        // Add a double-click gesture recognizer to reload the image
        let doubleClickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(reloadImageOriginal))
        doubleClickRecognizer.numberOfClicksRequired = 2
        imageView.addGestureRecognizer(doubleClickRecognizer)

        // Initialize the TrieCacheModule
        cache = TrieCacheModule.loadFromDisk() ?? TrieCacheModule()
        cache.invalidateCache() // Invalidate any outdated cache entries

        // Initialize the ZoomModule
        zoomModule = ZoomModule(imageView: imageView)
        imageFolderScanner = ImageFolderScanModule(trieCacheModule: cache)
        dropdownModule = DropdownDisplayModule()
    }

    
    private func initUIComponents(){
        print("Initializing components in leftPanel")

        // Initialize error message label when no images are found
        initializeNoImageLabel(in: rightPanel)
        
        // Initialize the "Open Folder" button
        initializeOpenFolderButton(in: rightPanel)
        
        // Initialize the "Scan Directory" UI
        initializeScanDirectoryButton(in: leftPanel)

        // Initialize dropdown view
        initializeDropDown(in: leftPanel)
        
        // Initialize scan directory label
        initializeScanDirectoryLabel(in: leftPanel) // maintain this init order to avoid null pointer exception
        
        // Initialize the tree view
        initializeTreeView(in: leftPanel)
        
        //Initialize image view
        initializeImageView(in: rightPanel)

        // Initialize the navigation buttons
        initializeNavigationButtons()
    }


    
    private func initializeSplitView() {
        splitView = NSSplitView(frame: self.view.bounds)
        splitView.dividerStyle = .thin
        splitView.isVertical = true
        splitView.autoresizingMask = [.width, .height]
        
        // Initialize left and right panels
        leftPanel = NSView()
        rightPanel = NSView()
        
        splitView.addSubview(leftPanel)
        splitView.addSubview(rightPanel)
        
        self.view.addSubview(splitView)
        
        // Adjust the initial width of the left panel
        leftPanel.frame.size.width = self.view.bounds.width * 0.3
        rightPanel.frame.size.width = self.view.bounds.width * 0.7
    }
    
    
    private func setupMainLayout() {
        // Create a horizontal split view
        let splitView = NSSplitView(frame: self.view.bounds)
        splitView.dividerStyle = .thin
        splitView.isVertical = true
        splitView.autoresizingMask = [.width, .height]
        self.view.addSubview(splitView)

        // Create the left panel
        leftPanel = NSView(frame: NSRect(x: 0, y: 0, width: splitView.frame.width * 0.3, height: splitView.frame.height))
        leftPanel.autoresizingMask = [.width, .height]
        splitView.addSubview(leftPanel)

        // Create the right panel
        rightPanel = NSView(frame: NSRect(x: splitView.frame.width * 0.3, y: 0, width: splitView.frame.width * 0.7, height: splitView.frame.height))
        rightPanel.autoresizingMask = [.width, .height]
        splitView.addSubview(rightPanel)

        // Initialize UI components in the left panel
        initUIComponents()
    }
    
    private func initializeImageView(in parentView: NSView) {
        imageView = NSImageView(frame: parentView.bounds)
        imageView.imageScaling = .scaleNone
        imageView.autoresizingMask = [.width, .height]
        parentView.addSubview(imageView)
    }

    private func initializeNoImageLabel(in parentView: NSView){
        // Initialize the "No Images Found" label
        noImagesLabel = NSTextField(labelWithString: "No image files found")
        noImagesLabel.font = NSFont.systemFont(ofSize: 24)
        noImagesLabel.alignment = .center
        noImagesLabel.isHidden = true
        noImagesLabel.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(noImagesLabel)
        
        // Center the label in the view
        NSLayoutConstraint.activate([
            noImagesLabel.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            noImagesLabel.centerYAnchor.constraint(equalTo: parentView.centerYAnchor)
        ])
    }
    
    private func initializeOpenFolderButton(in parentView: NSView){
        openFolderButton = NSButton(title: "Open Folder", target: self, action: #selector(openFolder))
        openFolderButton.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(openFolderButton)
        
        // Position the "Open Folder" button at the center of the chosen panel
        NSLayoutConstraint.activate([
            openFolderButton.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            openFolderButton.centerYAnchor.constraint(equalTo: parentView.topAnchor, constant: 50)
        ])
    }

    
    private func initializeScanDirectoryButton(in parentView: NSView){
        // Initialize the "Scan Directory" button
        scanDirectoryButton = NSButton(title: "Scan Directory", target: self, action: #selector(scanDirectory))
        scanDirectoryButton.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(scanDirectoryButton)
        
        // Position the "Open Folder" button at the center of the view
        NSLayoutConstraint.activate([
            scanDirectoryButton.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            scanDirectoryButton.centerYAnchor.constraint(equalTo: parentView.topAnchor, constant: 50)
        ])
    }
    
    private func initializeScanDirectoryLabel(in parentView: NSView) {
        scanDirectoryLabel = NSTextField(wrappingLabelWithString: "Current Scan: ")
        scanDirectoryLabel.font = NSFont.systemFont(ofSize: 14)
        scanDirectoryLabel.alignment = .left
        scanDirectoryLabel.translatesAutoresizingMaskIntoConstraints = false
        scanDirectoryLabel.isHidden = true
        parentView.addSubview(scanDirectoryLabel)

        if let dropdown = dropdownModule?.dropdown {
            NSLayoutConstraint.activate([
                scanDirectoryLabel.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
                scanDirectoryLabel.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -40),
                //scanDirectoryLabel.widthAnchor.constraint(equalToConstant: 300) // Set width to 300 points
            ])
        } else {
            print("Dropdown is not initialized")
        }
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
        configureNavButtons(buttons: navButtons, in: rightPanel)
        
        // Position the navigation buttons
        positionButtons(buttons: navButtons, in: rightPanel)
    }
    
    private func configureNavButtons(buttons: [NSButton], isHidden: Bool = true, in parentView: NSView) {
        for button in buttons {
            // Customize button appearance
            customizeButtonAppearance(button: button)
            
            // Add the button to the view
            button.translatesAutoresizingMaskIntoConstraints = false
            //parentView.addSubview(button)
            
            // Set initial visibility for the button
            button.isHidden = isHidden
        }
    }
    
    private func positionButtons(buttons: [NSButton], in parentView: NSView) {
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
        parentView.addSubview(stackView)
        
        // Position the stack view at the bottom center of the view
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -20)
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
        // Increase the corner radius slightly to maintain a balanced look
        button.layer?.cornerRadius = 6.0
        button.attributedTitle = NSAttributedString(
            string: button.title,
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ]
        )
    }
    
    private func setVisibility(isHidden: Bool, buttons: [NSButton]) {
        for button in buttons {
            button.isHidden = isHidden
        }
    }
    
    private func initializeDropDown(in parentView: NSView){
        // Initialize the dropdown module and add it to the view
        dropdownModule = DropdownDisplayModule()
        dropdownModule.initializeDropdown(in: parentView)

        // Set constraints for dropdown below the buttons
        dropdownModule?.dropdown.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dropdownModule.dropdown.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            dropdownModule.dropdown.topAnchor.constraint(equalTo: scanDirectoryButton.bottomAnchor, constant: 20),
            dropdownModule.dropdown.widthAnchor.constraint(equalToConstant: 300)
        ])
        
        // Set visibility based on the number of items in the dropdown
        dropdownModule.dropdown.isHidden = dropdownModule.dropdown.numberOfItems <= 1
        dropdownModule.dropdown.action = #selector(dropdownSelectionChanged(_:))
    }
    
    private func initializeTreeView(in parentView: NSView){
        // Initialize the TreeViewModule
        treeViewModule = TreeViewModule()
        treeViewModule.initializeTreeView(in: parentView, target: self)
        
        // Set up constraints for the tree view below the dropdown
        treeViewModule.treeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            treeViewModule.treeView.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            treeViewModule.treeView.topAnchor.constraint(equalTo: dropdownModule.dropdown.bottomAnchor, constant: 20),
            treeViewModule.treeView.widthAnchor.constraint(equalToConstant: 400),
            treeViewModule.treeView.heightAnchor.constraint(equalToConstant: 600)
        ])
        
        treeViewModule.treeView.action = #selector(self.treeViewItemDidDoubleClick(_:))
        treeViewModule.treeView.isHidden = true
    }

    
    @objc func dropdownSelectionChanged(_ sender: NSPopUpButton) {
        if let selectedItem = sender.selectedItem, let url = selectedItem.representedObject as? URL {
            // Print the selected folder's URL for debugging
            print("Selected folder URL: \(url)")
            
            // Open the folder at the selected URL
            openFolderPath(at: url)
        } else {
            print("Invalid selection or no URL associated with the selection")
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
                loadImages(from: url)
                
                // Hide the "Open Folder" button and show navigation buttons
                setVisibility(isHidden: false, buttons: navButtons)
                dropdownModule.hideDropDown(in: leftPanel)
                
                // Safely check the number of items in the dropdown
                if let dropdown = dropdownModule.dropdown {
                    scanDirectoryLabel.isHidden = dropdown.numberOfItems <= 1
                } else {
                    scanDirectoryLabel.isHidden = true
                }
            }
        }
        
        // Set rightPanel as the first responder
        DispatchQueue.main.async {
            self.rightPanel.window?.makeFirstResponder(self.rightPanel)
        }
    }
    
    @objc func closeFolder() {
        // Clear the images and show the "Open Folder" button again
        imagePaths = []
        imageView.image = nil
        
        openFolderButton.isHidden = false
        setVisibility(isHidden: true, buttons: navButtons)
        noImagesLabel?.isHidden = true
        dropdownModule.showDropDown(in : leftPanel)
        
        // Safely check the number of items in the dropdown
        if let dropdown = dropdownModule.dropdown {
            scanDirectoryLabel.isHidden = dropdown.numberOfItems <= 1
        } else {
            scanDirectoryLabel.isHidden = true
        }

        
        // Set rightPanel as the first responder
        DispatchQueue.main.async {
            self.rightPanel.window?.makeFirstResponder(nil)
        }
    }
    
    // Load image files from the selected folder in a background thread
    func loadImages(from folder: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            do {
                let files = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                let filteredPaths = files.filter { self.imageFolderScanner?.imageExtensions.contains($0.pathExtension.lowercased()) ?? false }.map { $0.path }

                
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
        case "x":
            closeFolder()
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
        
        // Check if the currentIndex has reached the last image
        if currentIndex == imagePaths.count - 1 {
                showLastFileAlert()
        }
    }
    
    // Move to the previous image in the folder
    @objc func moveToPreviousImage() {
        resetImageView(in: rightPanel) // Reset zoom and position
        currentIndex = max(currentIndex - 1, 0)
        displayImage(at: currentIndex)
    }
    
    // Move to the next image in the folder
    @objc func moveToNextImage() {
        resetImageView(in: rightPanel) // Reset zoom and position
        currentIndex = min(currentIndex + 1, imagePaths.count - 1)
        displayImage(at: currentIndex)
    }
    
    private func resetImageView(in parentView : NSView) {
        // Reset the image view's frame size to match the window bounds
        imageView.frame = parentView.bounds
        
        // Reset the image view's position to the top-left corner of the view
        imageView.frame.origin = NSPoint(x: 0, y: 0)
        
        // Remove any existing image from the image view
        imageView.image = nil
    }
    
    @objc func reloadImageOriginal() {
        resetImageView(in: rightPanel);// Reset zoom and position
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
        setVisibility(isHidden: true, buttons: navButtons)
        chooseButton.isHidden = false
        closeButton.isHidden = false
    }
    
    
    @objc func scanDirectory() {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a directory to scan"
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false
        dialog.allowsMultipleSelection = false
        

        if dialog.runModal() == .OK {
            if let url = dialog.url {
                scanDirectoryLabel.stringValue = "Current Scan: \(url.path)"
                let scanner = ImageFolderScanModule(trieCacheModule: cache)
                let foldersWithImages = scanner.scanForImageFolders(at: url)

                if foldersWithImages.isEmpty {
                    showNoFoldersFoundMessage()
                    treeViewModule.treeView.isHidden = true
                } else {
                    dropdownModule.updateDropdown(with: foldersWithImages, baseURL: url, in: leftPanel)
                    scanDirectoryLabel.isHidden = false
                    // Update the TreeViewModule with the folder structure
                    if let folderNodes = scanner.scanForFolderNodes(at: url) {
                        treeViewModule.treeView.isHidden = false
                        treeViewModule.updateTreeView(with: folderNodes, in: leftPanel)
                    }
                }
            }
        }
    }

    
    // Method to open the folder and load images
    func openFolderPath(at folderURL: URL) {
        // Clear the existing images
        imagePaths.removeAll()
        currentIndex = 0
            
        // Load image files from the selected folder
        loadImages(from: folderURL)
        displayImage(at: currentIndex)
                       
        setVisibility(isHidden: false, buttons: navButtons)
        openFolderButton.isHidden = true

        // Set rightPanel as the first responder
        DispatchQueue.main.async {
            self.rightPanel.window?.makeFirstResponder(self.rightPanel)
        }
        
    }
    
    private func showNoFoldersFoundMessage() {
        let alert = NSAlert()
        alert.messageText = "No folders with images found.\nOR\nScope too large.Choose smaller directory."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc func openSelectedFolder() {
        if let selectedFolder = dropdownModule.selectedFolderURL() {
            print("Selected : ", selectedFolder)

            openFolderPath(at: selectedFolder)
        } else {
            print("No folder selected.")
        }
    }
    
    private func showLastFileAlert() {
        let alert = NSAlert()
        alert.messageText = "End of Directory"
        alert.informativeText = "You have reached the last file in the directory."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        //alert.runModal()
    }
    
    @objc func treeViewItemDidDoubleClick(_ sender: NSOutlineView) {
        let clickedRow = sender.clickedRow
        guard clickedRow >= 0, let clickedItem = sender.item(atRow: clickedRow) as? FolderNode else {
            return
        }

        print("Double-clicked on: \(clickedItem.displayValue())")
        print("Programmatic value of double-clicked item: \(clickedItem.programmaticValue())")

        openFolderPath(at: clickedItem.url)
    }

}


