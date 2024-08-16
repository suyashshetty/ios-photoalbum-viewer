# Photo Album Viewer

A macOS photo viewer app developed in Swift using Cocoa. This app allows users to open a folder of images, view them in sequence, and navigate through the images using keyboard or mouse scroll events.

## Features

- Open and view images from a selected folder.
- Navigate between images using arrow keys or mouse scroll.
- Resize images to fit the view.
- Close the folder and reset the view.

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
    - Click the "Open Folder" button to choose a folder containing images.
    - Only images with the extensions `jpg`, `jpeg`, `png`, and `gif` are supported.

2. **Navigate Images:**
    - Use the "Previous" and "Next" buttons or arrow keys to navigate through the images.
    - Scroll the mouse wheel to navigate as well.

3. **Close Folder:**
    - Click the "Close Folder" button to clear the images and return to the initial state.

## Implementation Details

- **CoreImageViewer Class:** Manages the main functionalities, including image loading, displaying, and navigation.
- **NSWindowDelegate:** Handles window close events to terminate the application.
- **Image Resizing:** Ensures images are resized to fit the view efficiently.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes.

## Contact

For questions or feedback, please open an issue on the [GitHub repository](https://github.com/yourusername/PhotoAlbumViewer/issues).
