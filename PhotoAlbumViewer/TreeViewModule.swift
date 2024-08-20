//
//  TreeViewModule.swift
//  PhotoAlbumViewer
//
//  Created by Suyash Shetty on 8/20/24.
//

import Cocoa

class TreeViewModule: NSObject, NSOutlineViewDelegate, NSOutlineViewDataSource {

    var treeView: NSOutlineView!
    private var rootFolderNode: FolderNode?

    // Initialize the tree view
    func initializeTreeView(in view: NSView, target: AnyObject) {
        treeView = NSOutlineView()
        treeView.frame = NSRect(x: 0, y: 0, width: 100, height: 200)
        treeView.delegate = self
        treeView.dataSource = self
        
        // Set the double-click action
        treeView.target = target
        treeView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "Folders"))
        column.title = "Folders"
        column.resizingMask = .autoresizingMask
        treeView.addTableColumn(column)
        treeView.outlineTableColumn = column
        
        // Set font color to white for all cells in the treeView
        if let column = treeView.tableColumns.first {
            column.dataCell = NSTextFieldCell()
            if let textFieldCell = column.dataCell as? NSTextFieldCell {
                textFieldCell.textColor = NSColor.white
            }
        }

        treeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(treeView)
        
        
        treeView.wantsLayer = true
        treeView.layer?.borderWidth = 1.0
        treeView.layer?.borderColor = NSColor.red.cgColor // Set the border color to light gray

        // Apply background color to treeView and not the entire panel
        treeView.layer?.backgroundColor = NSColor.black.cgColor

        // Set font color to white for all cells in the treeView
        if let column = treeView.tableColumns.first {
            column.dataCell = NSTextFieldCell()
            if let textFieldCell = column.dataCell as? NSTextFieldCell {
                textFieldCell.textColor = NSColor.white
            }
        }
    }

    // Update the tree view with the folder node structure
    func updateTreeView(with rootFolderNode: FolderNode, in view: NSView) {
        self.rootFolderNode = rootFolderNode

        if let treeView = view.subviews.compactMap({ $0 as? NSOutlineView }).first {
            treeView.delegate = self
            treeView.dataSource = self
            treeView.reloadData()
        } else {
            print("Error: TreeView not found in the provided view.")
        }
    }


    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? FolderNode {
            return node.subfolders.count
        }
        // Include root node if item is nil
        return item == nil ? 1 : (rootFolderNode?.subfolders.count ?? 0)
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        print("isItemExpandable")
        if let node = item as? FolderNode {
            let isExpandable = !node.subfolders.isEmpty
            return isExpandable
        }
        // Root node is expandable if item is nil
        return item == nil
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? FolderNode {
            return node.subfolders[index]
        }
        // Return root node if item is nil
        return rootFolderNode!
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if let node = item as? FolderNode {
            // Format the display value to include the image count
            let displayValue: String
            if node.imageCount == 0 {
                displayValue = "\(node.url.lastPathComponent) (+)"
            } else {
                displayValue = "\(node.url.lastPathComponent) (\(node.imageCount))"
            }
            return displayValue
        }
        // Return the root node's display value if item is nil
        return rootFolderNode?.url.lastPathComponent
    }

}

