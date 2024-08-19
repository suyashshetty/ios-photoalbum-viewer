import AppKit

class ImageFolderScanModule {

    //private let imageExtensions = ["jpg", "jpeg", "png", "gif"] //debug
    public let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "heic", "webp", "ico", "svg"]
    private let maxDepth: Int = 50
    private let maxItemsInDirectory: Int = 10000
    private let exclusionList = ["/System", "/Library", "/Applications", "/Volumes", "/private", "/dev", "/usr", "/bin"]
    private var scanCache = [URL: [URL]]()

    // Scans the selected directory recursively for image folders
    func scanForImageFolders(at url: URL, currentDepth: Int = 0) -> [URL] {
        // Check cache first
        if let cachedResult = scanCache[url] {
            return cachedResult
        }

        var imageFolders: [URL] = []
        let fileManager = FileManager.default

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
                } else if isSystemOrLargeDirectory(fileURL) {
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
        return imageFolders
    }

    // Check if a directory contains images
    private func containsImages(in folderURL: URL) -> Bool {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            return files.contains(where: { imageExtensions.contains($0.pathExtension.lowercased()) })
        } catch {
            print("Error checking folder for images: \(error)")
            return false
        }
    }

    // Check if a directory is a system or large directory
    private func isSystemOrLargeDirectory(_ url: URL) -> Bool {
        let fileManager = FileManager.default

        if exclusionList.contains(url.path) {
            return true
        }

        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            let imageFiles = contents.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
            return imageFiles.isEmpty || imageFiles.count > maxItemsInDirectory
        } catch {
            return false
        }
    }
}
