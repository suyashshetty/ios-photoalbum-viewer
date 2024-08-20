import AppKit

class FolderNode {
    var url: URL
    var subfolders: [FolderNode] = []
    
    init(url: URL, subfolders: [FolderNode]) {
        self.url = url
        self.subfolders = subfolders
    }
    
    func addChild(_ node: FolderNode) {
        subfolders.append(node)
    }
    
    func displayValue() -> String {
            return url.lastPathComponent
    }
        
    func programmaticValue() -> String {
            return url.absoluteString
    }
    
    func toString(indent: String = "") -> String {
        var result = "\(indent)\(url.lastPathComponent)\n"
        for subfolder in subfolders {
            result += subfolder.toString(indent: indent + "  ")
        }
        return result
    }
}


class ImageFolderScanModule {
    
    public let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "heic", "webp", "ico", "svg"]
    private let maxDepth: Int = 50
    private let maxItemsInDirectory: Int = 10000
    private let exclusionList = ["/System", "/Library", "/Applications", "/Volumes", "/private", "/dev", "/usr", "/bin"]
    private var scanCache = [URL: [URL]]()
    private let trieCacheModule: TrieCacheModule
    
    init(trieCacheModule: TrieCacheModule) {
        self.trieCacheModule = trieCacheModule
    }
    
    // Scans the selected directory recursively for image folders
    func scanForImageFolders(at url: URL, currentDepth: Int = 0) -> [URL] {
        // Check cache first
        if let cachedResult = scanCache[url] {
            return cachedResult
        }
        
        // Check the Trie cache for this directory
        if trieCacheModule.search(directoryPath: url.path) {
            if let cachedResult = scanCache[url] {
                return cachedResult
            } else {
                // If found in Trie, try loading the subpaths from TrieCacheModule
                let subpaths = trieCacheModule.retrieveSubpaths(for: url.path)
                let cachedURLs = subpaths.map { URL(fileURLWithPath: $0) }
                scanCache[url] = cachedURLs
                return cachedURLs
            }
        }
        
        var imageFolders: [URL] = []
        let fileManager = FileManager.default
        
        // First, check if the current directory contains images and add it if so
        if containsImages(in: url) {
            imageFolders.append(url)
        }
        
        guard currentDepth <= maxDepth,
              let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return imageFolders
        }
        
        var batch = [URL]()
        let batchSize = 100
        
        for case let fileURL as URL in enumerator {
            autoreleasepool {
                if exclusionList.contains(fileURL.path) {
                    enumerator.skipDescendants()
                } else if containsImages(in: fileURL) {
                    batch.append(fileURL)
                    
                    if batch.count >= batchSize {
                        imageFolders.append(contentsOf: batch)
                        batch.removeAll()
                    }
                }
                
                if enumerator.level >= maxDepth {
                    enumerator.skipDescendants()
                }
            }
        }
        
        // Append any remaining items
        if !batch.isEmpty {
            imageFolders.append(contentsOf: batch)
        }
        
        // Cache the result
        scanCache[url] = imageFolders
        
        // Add the directory and its subpaths to the Trie cache
        trieCacheModule.insert(directoryPath: url.path)
        imageFolders.forEach { trieCacheModule.insert(directoryPath: $0.path) }
        
        return imageFolders
    }
    
    
    // Check if a directory contains images
    private func containsImages(in folderURL: URL) -> Bool {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            return files.contains(where: { imageExtensions.contains($0.pathExtension.lowercased()) })
        } catch {
            //print("Error checking folder for images: \(error)")
            return false
        }
    }
    
    // Scans the selected directory and returns a FolderNode tree structure
    func scanForFolderNodes(at url: URL, currentDepth: Int = 0) -> FolderNode? {
        // Check if the directory exists in the Trie cache
        guard let rootTrieNode = trieCacheModule.retrieveTrieNode(for: url.path) else {
            return nil
        }
        
        // Convert the TrieNode structure to a FolderNode structure
        return convertTrieNodeToFolderNode(trieNode: rootTrieNode, basePath: url.path)
    }
    
    func convertTrieNodeToFolderNode(trieNode: TrieNode, basePath: String) -> FolderNode {
        let folderNode = FolderNode(url: URL(fileURLWithPath: basePath), subfolders: [])
        
        for (childName, childTrieNode) in trieNode.children {
            let childPath = basePath + "/" + childName
            let childFolderNode = convertTrieNodeToFolderNode(trieNode: childTrieNode, basePath: childPath)
            folderNode.addChild(childFolderNode)
        }
        
        return folderNode
    }


    // Helper method to check if a URL is a directory
    private func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
}
