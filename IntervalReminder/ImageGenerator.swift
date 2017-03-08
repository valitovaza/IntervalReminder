import Cocoa
protocol ImageGeneratable {
    func generate() -> NSImage
    func setInterval(_ timeInterval: Double)
    func setPastInterval(_ timeInterval: Double)
    func incrementInterval()
    var delegate: ImageChangeListener? {get set}
}
protocol ImageChangeListener: class {
    func imageChanged(image: NSImage)
}
class ImageGenerator: ImageGeneratable {
    let imageSize = 16.0
    weak var delegate: ImageChangeListener?
    
    private(set) var currentPercent: Double = 0.0 {
        didSet {
            updateImage()
        }
    }
    private(set) var interval: Double = 0.0 {
        didSet {
            countPercent()
        }
    }
    private(set) var pastInterval: Double = 0.0 {
        didSet {
            countPercent()
        }
    }
    
    func generate() -> NSImage {
        let image = DrawImageInNSGraphicsContext(size: rectForImage().size) { () -> () in
            drawImage(rectForImage(), currentPercent)
        }
        return imageForStatus(image)
    }
    func setInterval(_ timeInterval: Double) {
        interval = timeInterval
    }
    func setPastInterval(_ timeInterval: Double) {
        pastInterval = timeInterval
    }
    func incrementInterval() {
        pastInterval += 1.0
        updateImage()
    }
    private func updateImage() {
        delegate?.imageChanged(image: generate())
    }
    private func countPercent() {
        currentPercent = interval == 0 ? 0.0 : pastInterval / interval
    }
    private func rectForImage() -> NSRect {
        let doubledSize = CGFloat(2.0 * imageSize)
        return NSRect(origin: NSZeroPoint, size: NSMakeSize(doubledSize, doubledSize))
    }
    private func imageForStatus(_ image: NSImage) -> NSImage {
        let resizedImage = image.resizeImage(width: imageSize, imageSize)
        resizedImage.isTemplate = true
        return resizedImage
    }
    private func drawImage(_ rect: NSRect, _ percent: Double) {
        NSColor.black.set()
        drawCircle(innerRectFrom(rect))
        drawArc(rect, percent: percent)
    }
    private func innerRectFrom(_ rect: NSRect, margin: CGFloat = 1.0) -> NSRect {
        let doubledMargin = 2 * margin
        return NSRect(origin: NSMakePoint(margin, margin),
                      size: NSMakeSize(rect.size.width - doubledMargin, rect.size.height - doubledMargin))
    }
    private func drawCircle(_ rect: NSRect) {
        let circlePath = NSBezierPath()
        circlePath.appendOval(in: rect)
        circlePath.lineWidth = 1.0
        circlePath.stroke()
    }
    private func drawArc(_ rect: NSRect, percent: Double) {
        let path = NSBezierPath()
        moveToCenter(path, rect)
        arcWith(rect: rect, percent: percent, in: path)
        moveToCenter(path, rect)
        path.fill()
    }
    private func moveToCenter(_ path: NSBezierPath, _ rect: NSRect) {
        let center = rectCenter(rect)
        path.move(to: center)
    }
    private func rectCenter(_ rect: NSRect) -> NSPoint {
        return NSMakePoint(rect.size.width/2.0, rect.size.height/2.0)
    }
    private func arcWith(rect: NSRect, percent: Double, in path: NSBezierPath) {
        let radius = innerRectFrom(rect).size.width/2.0
        let angles = arcAngles(percent)
        path.appendArc(withCenter: rectCenter(rect),
                       radius: radius,
                       startAngle: angles.startAngle,
                       endAngle: angles.endAngle,
                       clockwise: true)
    }
    private let topPosition: CGFloat = 90.0
    private let fullCircleAngle: CGFloat = 360.0
    private func arcAngles(_ percent: Double) -> (startAngle: CGFloat, endAngle: CGFloat) {
        let diffAngle: CGFloat = fullCircleAngle * validPercent(percent)
        let endAngle: CGFloat = topPosition - diffAngle
        return (startAngle: topPosition, endAngle: endAngle)
    }
    private func validPercent(_ percent: Double) -> CGFloat {
        var floatPercent = CGFloat(min(1.0, percent))
        floatPercent = max(0.0, floatPercent)
        return floatPercent
    }
    
    // MARK: - Graphics stuff
    private func DrawImageInCGContext(size: CGSize, drawFunc: (_ context: CGContext) -> ()) -> NSImage? {
        guard let context = getCGContext(size) else { return nil }
        drawFunc(context)
        return imageFrom(context: context, size: size)
    }
    private func getCGContext(_ size: CGSize) -> CGContext? {
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        return CGContext.init(data: nil,
                              width: Int(size.width),
                              height: Int(size.height),
                              bitsPerComponent: Int(8),
                              bytesPerRow: Int(0),
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: UInt32(bitmapInfo.rawValue))
    }
    private func imageFrom(context: CGContext, size: CGSize) -> NSImage? {
        if let image = context.makeImage() {
            return NSImage(cgImage: image, size: size)
        }
        return nil
    }
    private func DrawImageInNSGraphicsContext(size: CGSize, drawFunc: ()->()) -> NSImage {
        let rep = bitmapImageRep(size)
        let context = NSGraphicsContext(bitmapImageRep: rep)!
        drawInGraphics(context: context, drawFunc: drawFunc)
        return imageFromRepresentation(rep, size)
    }
    private func bitmapImageRep(_ size: CGSize) -> NSBitmapImageRep {
        return NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: NSCalibratedRGBColorSpace,
            bytesPerRow: 0,
            bitsPerPixel: 0)!
    }
    private func drawInGraphics(context: NSGraphicsContext, drawFunc: ()->()) {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.setCurrent(context)
        drawFunc()
        NSGraphicsContext.restoreGraphicsState()
    }
    private func imageFromRepresentation(_ rep: NSBitmapImageRep, _ size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        image.addRepresentation(rep)
        return image
    }
}
extension NSImage {
    func resizeImage(width: Double, _ height: Double) -> NSImage {
        let img = NSImage(size: CGSize(width: width, height: height))
        img.lockFocus()
        let ctx = NSGraphicsContext.current()
        ctx?.imageInterpolation = .high
        self.draw(in: NSMakeRect(0, 0, CGFloat(width), CGFloat(height)),
                  from: NSMakeRect(0, 0, size.width, size.height),
                  operation: .copy,
                  fraction: 1.0)
        img.unlockFocus()
        return img
    }
}
extension NSBezierPath {
    var CGPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveToBezierPathElement:
                path.move(to: CGPoint(x: points[0].x, y: points[0].y))
            case .lineToBezierPathElement:
                path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
            case .curveToBezierPathElement:
                path.addCurve(to: CGPoint(x: points[2].x, y: points[2].y),
                              control1: CGPoint(x: points[0].x, y: points[0].y),
                              control2: CGPoint(x: points[1].x, y: points[1].y))
            case .closePathBezierPathElement: path.closeSubpath()
            }
        }
        return path
    }
}
