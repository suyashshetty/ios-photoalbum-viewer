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


    // Update the dropdown with scanned folders
    func updateDropdown(with folders: [URL], in view: NSView) {
        // Attempt to find the dropdown in the view hierarchy
        guard let dropdown = view.subviews.compactMap({ $0 as? NSPopUpButton }).first else {
            print("Dropdown not found in view hierarchy")
            return
        }

        // Update the dropdown items
        dropdown.removeAllItems()
        dropdown.addItem(withTitle: "Select a folder")
        folders.forEach { folder in
            dropdown.addItem(withTitle: folder.path)
        }
        
        // Set visibility based on the number of items in the dropdown
        dropdown.isHidden = dropdown.numberOfItems <= 1
    }

    // Retrieve the selected folder URL
    func selectedFolderURL() -> URL? {
        guard let dropdown = dropdown, dropdown.indexOfSelectedItem > 0 else { return nil }
        let selectedPath = dropdown.titleOfSelectedItem ?? ""
        return URL(fileURLWithPath: selectedPath)
    }
    
    public func hideDropDown(in view: NSView){
        guard let dropdown = view.subviews.compactMap({ $0 as? NSPopUpButton }).first else {
            print("hide : Dropdown not found in view hierarchy")
            return
        }
        dropdown.isHidden = true
    }
    
    public func showDropDown(in view: NSView){
        guard let dropdown = view.subviews.compactMap({ $0 as? NSPopUpButton }).first else {
            print("show : Dropdown not found in view hierarchy")
            return
        }
        dropdown.isHidden = dropdown.numberOfItems <= 1
    }
    

}

