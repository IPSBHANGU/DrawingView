//
//  DrawingView.swift
//
//  Created by Inderpreet Singh on 23/07/24.
//

/**
 A customizable view that allows users to draw lines, fill shapes, and manage drawing actions with undo/redo functionality.

 - Properties:
   - `lineWidth`: The width of the lines drawn. Default is 5.0.
   - `lineColor`: The color of the lines drawn. Default is black.
   - `isErasing`: A boolean that, when true, sets the drawing color to the background color (effectively erasing). Default is false.
   - `fillColor`: The color used to fill closed shapes. Default is nil.
   - `isFilling`: A boolean that, when true, enables shape filling mode. Default is false.
   - `onUndoAvailabilityChanged`: A closure that is called when undo availability changes, passing a boolean indicating whether undo is available.
   - `onRedoAvailabilityChanged`: A closure that is called when redo availability changes, passing a boolean indicating whether redo is available.
   - `onSaveAndShare`: A closure that is called with the URL of the saved drawing file when the drawing is saved and shared.
   - `onError`: A closure that is called with an error if an operation fails.

 - Methods:
   - `undo()`: Undoes the last drawing action (line or filled shape). Updates the display and the availability of undo/redo actions.
   - `redo()`: Redoes the last undone action (line or filled shape). Updates the display and the availability of undo/redo actions.
   - `saveDrawing()`: Saves the current drawing as a PNG file and invokes the `onSaveAndShare` closure with the file URL. If saving fails, invokes the `onError` closure with the encountered error.

 - Overrides:
   - `touchesBegan(_:with:)`: Handles the beginning of a touch event. Initializes a new line or handles filling a shape if `isFilling` is true.
   - `touchesMoved(_:with:)`: Updates the current line with the new touch points and triggers a redraw.
   - `touchesEnded(_:with:)`: Finalizes the current line and adds it to the list of lines. Updates the availability of undo/redo actions.
   - `touchesCancelled(_:with:)`: Handles cancelled touch events by treating them as ended touches.
   - `draw(_:)`: Draws the lines, filled shapes, and the current line onto the view's context.

 - Example Usage:
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

 drawingView.onSaveAndShare = { fileURL in
     // Handle file URL for saved drawing (e.g., share via UIActivityViewController)
 }

 drawingView.onError = { error in
     // Handle error (e.g., show alert to user)
 }
 
 - Author: Inderpreet Singh
 - Version: 1.0
 */

import UIKit

struct Line {
    var points: [CGPoint]
    var color: UIColor
    var width: CGFloat
    var isClosed: Bool
}

struct FilledShape {
    let path: UIBezierPath
    let color: UIColor
}

enum Action {
    case line(Line)
    case filledShape(FilledShape)
}

class DrawingView: UIView {

    private var lines: [Line] = []
    private var undoneLines: [Line] = []
    private var currentLine: Line?
    var lineWidth: CGFloat = 5.0
    var lineColor: UIColor = .black
    var isErasing: Bool = false
    var fillColor: UIColor? // fill color
    var isFilling: Bool = false // draw mode
    private var filledShapes: [FilledShape] = []

    private var actions: [Action] = []
    private var undoneActions: [Action] = []
    
    // Undo and redo buttons states
    var onUndoAvailabilityChanged: ((Bool) -> Void)?
    var onRedoAvailabilityChanged: ((Bool) -> Void)?
    
    // Closure to handle saving and sharing the drawing
    var onSaveAndShare: ((URL) -> Void)?
    
    // Closure to handle error
    var onError: ((Error) -> Void)?
    
    // Generally, all responders which do custom touch handling should override all four of these methods.
    // Your responder will receive either touchesEnded:withEvent: or touchesCancelled:withEvent: for each
    // touch it is handling (those touches it received in touchesBegan:withEvent:).
    // *** You must handle cancelled touches to ensure correct behavior in your application.  Failure to
    // do so is very likely to lead to incorrect behavior or crashes.
//    - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
//    - (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
//    - (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
//    - (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.location(in: self)
            if isFilling {
                fillColorIfClosedShape(at: point)
            } else {
                currentLine = Line(points: [point], color: isErasing ? self.backgroundColor ?? .white : lineColor, width: lineWidth, isClosed: false)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, var line = currentLine {
            let point = touch.location(in: self)
            line.points.append(point)
            currentLine = line
            setNeedsDisplay()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if var line = currentLine {
            line.isClosed = true // Mark the line as closed
            lines.append(line)
            actions.append(.line(line))
            currentLine = nil
            setNeedsDisplay()
            onUndoAvailabilityChanged?(true)
            onRedoAvailabilityChanged?(false)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setLineCap(.round)
        
        // Draw filled shapes first
        for filledShape in filledShapes {
            context.setFillColor(filledShape.color.cgColor)
            context.addPath(filledShape.path.cgPath)
            context.fillPath()
        }
        
        // Draw lines
        for line in lines {
            let path = UIBezierPath()
            path.move(to: line.points.first ?? .zero)
            for point in line.points.dropFirst() {
                path.addLine(to: point)
            }
            
            if line.isClosed {
                path.close()
            }
            context.setStrokeColor(line.color.cgColor)
            context.setLineWidth(line.width)
            context.addPath(path.cgPath)
            context.strokePath()
        }
        
        // Draw current line
        if let line = currentLine {
            let path = UIBezierPath()
            path.move(to: line.points.first ?? .zero)
            for point in line.points.dropFirst() {
                path.addLine(to: point)
            }
            context.setStrokeColor(line.color.cgColor)
            context.setLineWidth(line.width)
            context.addPath(path.cgPath)
            context.strokePath()
        }
    }

    func undo() {
        guard let lastAction = actions.popLast() else { return }

        switch lastAction {
        case .line(let line):
            lines.removeLast()
            undoneLines.append(line)
        case .filledShape(let filledShape):
            filledShapes.removeLast()
        }

        undoneActions.append(lastAction)
        setNeedsDisplay()
        onUndoAvailabilityChanged?(actions.count > 0)
        onRedoAvailabilityChanged?(true)
    }

    func redo() {
        guard let lastUndoneAction = undoneActions.popLast() else { return }

        switch lastUndoneAction {
        case .line(let line):
            lines.append(line)
        case .filledShape(let filledShape):
            filledShapes.append(filledShape)
        }

        actions.append(lastUndoneAction)
        setNeedsDisplay()
        onUndoAvailabilityChanged?(true)
        onRedoAvailabilityChanged?(undoneActions.count > 0)
    }
    
    private func fillColorIfClosedShape(at point: CGPoint) {
        guard let fillColor = fillColor else { return }
        
        // Identify closed paths
        let closedPaths = lines.filter { $0.isClosed }
        
        // Check if the touch point is inside any closed path
        for line in closedPaths {
            let path = UIBezierPath()
            path.move(to: line.points.first ?? .zero)
            for pt in line.points.dropFirst() {
                path.addLine(to: pt)
            }
            path.close()
            
            if path.contains(point) {
                let filledShape = FilledShape(path: path, color: fillColor)
                filledShapes.append(filledShape)
                actions.append(.filledShape(filledShape))
                
                // Redraw the view to show the filled shape
                setNeedsDisplay()
                return
            }
        }
    }

    func saveDrawing() {
        // Check if there are any lines to save
        guard !lines.isEmpty || currentLine != nil else {
            let error = NSError(domain: "DrawingViewErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "No drawing to save."])
            onError?(error)
            return
        }
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let drawingImage = image else { return }
        if let data = drawingImage.pngData() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let dateString = dateFormatter.string(from: Date())
            let filename = getDocumentsDirectory().appendingPathComponent("mandala_\(dateString).png")
            
            do {
                try data.write(to: filename)
                onSaveAndShare?(filename)
            } catch {
                onError?(error)
            }
        }
    }

    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
