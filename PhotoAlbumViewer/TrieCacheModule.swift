import Foundation

// TrieNode class
class TrieNode: Codable {
    var value: String
    var children: [String: TrieNode] = [:]
    var isEndOfPath: Bool = false
    
    init(value: String) {
        self.value = value
    }
}

// TrieCacheModule class
class TrieCacheModule: Codable {
    private let root: TrieNode
    
    init() {
        self.root = TrieNode(value: "")
    }
    
    func insert(directoryPath: String) {
        var currentNode = root
        let components = directoryPath.split(separator: "/").map { String($0) }
        
        for component in components {
            if currentNode.children[component] == nil {
                currentNode.children[component] = TrieNode(value: component)
            }
            currentNode = currentNode.children[component]!
        }
        
        currentNode.isEndOfPath = true
    }
    
    func search(directoryPath: String) -> Bool {
        var currentNode = root
        let components = directoryPath.split(separator: "/").map { String($0) }
        
        for component in components {
            if let node = currentNode.children[component] {
                currentNode = node
            } else {
                return false
            }
        }
        
        return currentNode.isEndOfPath
    }
    
    func retrieveSubpaths(for directoryPath: String) -> [String] {
        var currentNode = root
        let components = directoryPath.split(separator: "/").map { String($0) }
        
        for component in components {
            if let node = currentNode.children[component] {
                currentNode = node
            } else {
                return []
            }
        }
        
        return collectPaths(from: currentNode, prefix: directoryPath)
    }
    
    private func collectPaths(from node: TrieNode, prefix: String) -> [String] {
        var paths: [String] = []
        
        if node.isEndOfPath {
            paths.append(prefix)
        }
        
        for (childValue, childNode) in node.children {
            let childPath = prefix + "/" + childValue
            paths.append(contentsOf: collectPaths(from: childNode, prefix: childPath))
        }
        
        return paths
    }
    
    // MARK: - Cache Invalidation

    /// Check if the cached paths are still valid by verifying the existence of the directories.
    func invalidateCache() {
        var invalidPaths: [String] = []
        validateNode(node: root, currentPath: "", invalidPaths: &invalidPaths)
        
        // Remove invalid paths from the cache
        for path in invalidPaths {
            remove(path)
        }
        
        if !invalidPaths.isEmpty {
            saveToDisk() // Save the updated cache if there were changes
        }
    }
    
    /// Recursively validate each node in the trie.
    private func validateNode(node: TrieNode, currentPath: String, invalidPaths: inout [String]) {
        let fileManager = FileManager.default
        let fullPath = currentPath.isEmpty ? node.value : currentPath + "/" + node.value
        
        // If the node represents a directory path, check its validity
        if node.isEndOfPath {
            if !fileManager.fileExists(atPath: fullPath) {
                invalidPaths.append(fullPath)
            }
        }
        
        // Recursively check children nodes
        for (_, childNode) in node.children {
            validateNode(node: childNode, currentPath: fullPath, invalidPaths: &invalidPaths)
        }
    }
    
    /// Remove a path from the Trie
    private func remove(_ directoryPath: String) {
        var currentNode = root
        let components = directoryPath.split(separator: "/").map { String($0) }
        var nodesStack: [(TrieNode, String)] = []
        
        // Traverse the Trie to find the node corresponding to the directory path
        for component in components {
            if let node = currentNode.children[component] {
                nodesStack.append((currentNode, component))
                currentNode = node
            } else {
                return // Path not found, nothing to remove
            }
        }
        
        // Mark the node as not an end of path
        currentNode.isEndOfPath = false
        
        // Clean up any empty branches in the Trie
        while let (parent, key) = nodesStack.popLast(), currentNode.children.isEmpty {
            parent.children.removeValue(forKey: key)
            currentNode = parent
        }
    }
    
    func retrieveTrieNode(for directoryPath: String) -> TrieNode? {
        var currentNode = root
        let components = directoryPath.split(separator: "/").map { String($0) }
        
        for component in components {
            if let node = currentNode.children[component] {
                currentNode = node
            } else {
                return nil
            }
        }
        
        return currentNode
    }

    
    // MARK: - Persistence

    func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(self)
            let fileURL = TrieCacheModule.getFileURL()
            try data.write(to: fileURL)
            print("Cache saved to \(fileURL.path)")
        } catch {
            print("Failed to save Trie: \(error.localizedDescription)")
        }
    }

    static func loadFromDisk() -> TrieCacheModule? {
        let fileURL = getFileURL()
        print(fileURL)
        do {
            let data = try Data(contentsOf: fileURL)
            let trie = try JSONDecoder().decode(TrieCacheModule.self, from: data)
            return trie
        } catch {
            print("Failed to load Trie: \(error.localizedDescription)")
            return nil
        }
    }

    private static func getFileURL() -> URL {
        let fileManager = FileManager.default
        let directoryURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = directoryURL.appendingPathComponent("PhotoAlbumViewer")
            
        // Create the app directory if it doesn't exist
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
            
        return appDirectory.appendingPathComponent("TrieCache.json")
    }
}
