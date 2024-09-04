# Photo Album Viewer

A macOS photo viewer app developed in Swift using Cocoa. This app allows users to open a folder of images, view them in sequence, zoom in/out, and navigate through the images using keyboard or mouse scroll events.

## Features

- **Open and View Images:** Select a folder containing images and view them in sequence.
- **Scan Directory:** Recursively scan a directory for folders containing images and choose one to view.
- **Navigation:**
  - Navigate between images using arrow keys or mouse scroll.
  - Use "Previous" and "Next" buttons for navigation.
- **Image Resizing:** Images are automatically resized to fit the window while maintaining their aspect ratio.
- **Zoom Functionality:**
  - Use `Ctrl + Mouse Wheel` to zoom in and out.
  - Zoom centered around the mouse pointer.
  - Double-click to reset the image to its original size.
- **Pan Functionality:** Move the image within the zoomed view by clicking and dragging.
- **Move to Trash:** Move the current image to the trash with confirmation.
- **Keyboard Shortcuts:**
  - `Delete` to move the current image to the trash.
  - `Command + C` to close the current folder.
  - `Command + O` to open a new folder.
  - Future functionality with `Command` key.
- **Dynamic Window Resizing:** The window size is set to 80% of the current display's size when opening a folder.
- **Empty Folder Handling:** Displays a "No images found" message if the selected folder contains no images.

## Requirements

- macOS 10.15 (Catalina) or later
- Xcode 11 or later

## Installation

1. **Clone the repository:**

    ```bash
    git clone https://github.com/yourusername/PhotoAlbumViewer.git
    ```

2. **Open the project in Xcode:**

    ```bash
    open PhotoAlbumViewer.xcodeproj
    ```

3. **Build and run the project:**

    Select the target device and click the Run button in Xcode.

## Usage

1. **Open Folder:**
    - Click the "Open Folder" button or press `Command + O` to choose a folder containing images.
    - Only images with the extensions `jpg`, `jpeg`, `png`, and `gif` are supported.

2. **Scan Directory:**
    - Click the "Scan Directory" button to scan a directory recursively for folders containing images.
    - A dropdown menu will appear with the list of folders found. Select one to load the images.

3. **Navigate Images:**
    - Use the "Previous" and "Next" buttons or arrow keys to navigate through the images.
    - Scroll the mouse wheel to navigate as well.

4. **Zoom and Pan:**
    - Hold `Ctrl` and scroll the mouse wheel to zoom in and out of images.
    - Click and drag to pan across the zoomed image.
    - Double-click to reset the image to its original size.

5. **Move to Trash:**
    - Use the "Trash" button or press `Delete` to move the current image to the trash with confirmation.
  
6. **Close Folder:**
    - Click the "Close Folder" button to clear the images and return to the initial state.

## Implementation Details

- **CoreImageViewer Class:** Manages the main functionalities, including image loading, displaying, navigation, zooming, and panning.
- **ImageFolderScanModule Class:** Handles the directory scanning functionality to find folders containing images.
- **DropdownDisplayModule Class:** Manages the dropdown menu displaying the results of the directory scan.
- **ZoomModule Class:** Handles zooming and panning functionality.
- **Keyboard Shortcuts:** Manages key press events for navigation and other actions.
- **Dynamic Window Resizing:** Adjusts window size based on the current display's size.
- **Image Resizing:** Ensures images are resized to fit the view efficiently while maintaining aspect ratio.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes.

## Contact

For questions or feedback, please open an issue on the [GitHub repository](https://github.com/yourusername/PhotoAlbumViewer/issues).
