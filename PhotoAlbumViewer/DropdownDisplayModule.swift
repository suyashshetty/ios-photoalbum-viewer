//
//  DropdownDisplayModule.swift
//  PhotoAlbumViewer
//
//  Created by Suyash Shetty on 8/19/24.
//

import Cocoa

class DropdownDisplayModule {

    var dropdown: NSPopUpButton!

    // Initialize the dropdown
    func initializeDropdown(in view: NSView) {
        // Initialize the dropdown
        dropdown = NSPopUpButton(frame: NSRect(x: 20, y: 20, width: 300, height: 30), pullsDown: true)
        dropdown.target = self
        
        // Add a placeholder item to the dropdown
        dropdown.addItem(withTitle: "Select a folder")
        
        // Safely add the dropdown to the view
        view.addSubview(dropdown)
    }

    // Update the dropdown with scanned folders and calculate display values
    func updateDropdown(with folders: [URL], baseURL: URL, in view: NSView) {
        // Attempt to find the dropdown in the view hierarchy
        guard let dropdown = view.subviews.compactMap({ $0 as? NSPopUpButton }).first else {
            print("Dropdown not found in view hierarchy")
            return
        }

        // Update the dropdown items
        dropdown.removeAllItems()
        dropdown.addItem(withTitle: "Select a folder")
        
        folders.forEach { folder in
            // Calculate the display value relative to the baseURL
            var displayValue = folder.path.replacingOccurrences(of: baseURL.path, with: "")
            
            // If displayValue is blank, set it to "(Current Folder)"
            if displayValue.isEmpty {
                displayValue = "(Current Folder)"
            }
            
            let menuItem = NSMenuItem(title: displayValue, action: nil, keyEquivalent: "")
            menuItem.representedObject = folder
            dropdown.menu?.addItem(menuItem)
        }
        
        // Set visibility based on the number of items in the dropdown
        dropdown.isHidden = dropdown.numberOfItems <= 1
    }

    // Retrieve the selected folder URL
    func selectedFolderURL() -> URL? {
        guard let dropdown = dropdown, dropdown.indexOfSelectedItem > 0 else { return nil }
        if let selectedItem = dropdown.selectedItem, let url = selectedItem.representedObject as? URL {
            return url
        }
        return nil
    }

    
    public func hideDropDown(in view: NSView){
        guard let dropdown = view.subviews.compactMap({ $0 as? NSPopUpButton }).first else {
            return
        }
        dropdown.isHidden = true
    }
    
    public func showDropDown(in view: NSView){
        guard let dropdown = view.subviews.compactMap({ $0 as? NSPopUpButton }).first else {
            return
        }
        dropdown.isHidden = dropdown.numberOfItems <= 1
    }
}
