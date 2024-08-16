import Cocoa

class RecentFoldersModule {
    
    // Properties
    private var recentFolders: [String] = []
    private let maxRecentFolders = 5
    private let folderIcon: NSImage
    private let picturesFolderPath: String
    
    // Key for storing recent folders in UserDefaults
    private let recentFoldersKey = "recentFolders"
    
    init(folderIcon: NSImage) {
        // Get the path to the "Pictures" folder
        if let picturesPath = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first?.path {
            self.picturesFolderPath = picturesPath
        } else {
            self.picturesFolderPath = "" // Handle the case where the path is not found
        }
        
        // Resize the folder icon to 64x64
        self.folderIcon = Self.resizeImage(icon: folderIcon, to: NSSize(width: 64, height: 64))
        
        loadRecentFolders()
        ensurePicturesFolderInRecents()
    }
    
    // Load recent folders from UserDefaults
    private func loadRecentFolders() {
        let defaults = UserDefaults.standard
        recentFolders = defaults.stringArray(forKey: recentFoldersKey) ?? []
    }
    
    // Save recent folders to UserDefaults
    private func saveRecentFolders() {
        let defaults = UserDefaults.standard
        defaults.set(recentFolders, forKey: recentFoldersKey)
    }
    
    // Ensure the "Pictures" folder is always in recents
    private func ensurePicturesFolderInRecents() {
        if !recentFolders.contains(picturesFolderPath) {
            recentFolders.insert(picturesFolderPath, at: 0)
            saveRecentFolders()
        }
    }
    
    // Add a new folder to the recent list
    func addRecentFolder(_ folder: String) {
        if let index = recentFolders.firstIndex(of: folder) {
            // Move folder to the front if it already exists
            recentFolders.remove(at: index)
        } else if recentFolders.count >= maxRecentFolders {
            // Remove the oldest if the list is full
            recentFolders.removeLast()
        }
        recentFolders.insert(folder, at: 0)
        saveRecentFolders()
    }
    
    // Create a stack view with clickable folder icons
    func createRecentFoldersStackView(target: Any, action: Selector) -> NSStackView {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 10
        
        for folder in recentFolders.prefix(maxRecentFolders) {
            let folderButton = NSButton(image: folderIcon, target: target, action: action)
            folderButton.title = ""
            folderButton.setButtonType(.momentaryChange)
            folderButton.tag = recentFolders.firstIndex(of: folder) ?? 0
            stackView.addArrangedSubview(folderButton)
        }
        
        return stackView
    }
    
    // Get the folder path for a given tag (used for button clicks)
    func folderPath(forTag tag: Int) -> String? {
        guard tag >= 0 && tag < recentFolders.count else {
            return nil
        }
        return recentFolders[tag]
    }
    
    // Static method for resizing image
    private static func resizeImage(icon: NSImage, to size: NSSize) -> NSImage {
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        icon.draw(in: NSRect(origin: .zero, size: size))
        resizedImage.unlockFocus()
        return resizedImage
    }
}
