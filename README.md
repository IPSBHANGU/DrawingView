# DrawingView

`DrawingView` is a customizable `UIView` subclass for drawing lines, filling shapes, and managing drawing actions with undo/redo functionality.

## Overview

`DrawingView` provides an interactive drawing experience with support for various features such as adjustable line width, color selection, shape filling, and undo/redo operations. The view also includes functionality to save the drawing as a PNG file.

## Properties

- `lineWidth: CGFloat`
  - The width of the lines drawn. Default is 5.0.
  
- `lineColor: UIColor`
  - The color of the lines drawn. Default is black.
  
- `isErasing: Bool`
  - When true, sets the drawing color to the background color for erasing. Default is false.
  
- `fillColor: UIColor?`
  - The color used to fill closed shapes. Default is nil.
  
- `isFilling: Bool`
  - When true, enables shape filling mode. Default is false.
  
- `onUndoAvailabilityChanged: ((Bool) -> Void)?`
  - Closure called when undo availability changes, passing a boolean indicating whether undo is available.
  
- `onRedoAvailabilityChanged: ((Bool) -> Void)?`
  - Closure called when redo availability changes, passing a boolean indicating whether redo is available.
  
- `onSaveAndShare: ((URL) -> Void)?`
  - Closure called with the URL of the saved drawing file when the drawing is saved and shared.
  
- `onError: ((Error) -> Void)?`
  - Closure called with an error if an operation fails.

## Methods

- `func undo()`
  - Undoes the last drawing action (line or filled shape). Updates the display and the availability of undo/redo actions.
  
- `func redo()`
  - Redoes the last undone action (line or filled shape). Updates the display and the availability of undo/redo actions.
  
- `func saveDrawing()`
  - Saves the current drawing as a PNG file and invokes the `onSaveAndShare` closure with the file URL. If saving fails, invokes the `onError` closure with the encountered error.

## Overrides

- `override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)`
  - Handles the beginning of a touch event. Initializes a new line or handles filling a shape if `isFilling` is true.
  
- `override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)`
  - Updates the current line with the new touch points and triggers a redraw.
  
- `override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)`
  - Finalizes the current line and adds it to the list of lines. Updates the availability of undo/redo actions.
  
- `override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)`
  - Handles cancelled touch events by treating them as ended touches.
  
- `override func draw(_ rect: CGRect)`
  - Draws the lines, filled shapes, and the current line onto the view's context.

## Example Usage

```swift
let drawingView = DrawingView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
drawingView.lineWidth = 10.0
drawingView.lineColor = .blue
drawingView.isFilling = true
drawingView.fillColor = .red

drawingView.onUndoAvailabilityChanged = { isAvailable in
    // Update UI to reflect undo availability
}

drawingView.onRedoAvailabilityChanged = { isAvailable in
    // Update UI to reflect redo availability
}

drawingView.saveDrawing()
drawingView.onSaveAndShare = { fileURL in
    // Handle file URL for saved drawing (e.g., share via UIActivityViewController)
}

drawingView.onError = { error in
    // Handle error (e.g., show alert to user)
}

drawingView.undo()

drawingView.redo()

// Erase Mode
drawingView.isErasing = true
drawingView.isFilling = false

// Fill Mode
drawingView.isErasing = false
drawingView.isFilling = true

// Draw Mode
drawingView.isErasing = false
drawingView.isFilling = false
