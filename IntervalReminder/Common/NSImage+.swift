import Cocoa
extension NSImage {
    enum Asset: String {
        case statusBarImg
        var image: NSImage {
            return NSImage(asset: self)
        }
    }
    convenience init!(asset: Asset) {
        self.init(named: asset.rawValue)
    }
}
