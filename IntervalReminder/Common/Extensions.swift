import Cocoa
protocol ReusableView: class {}
extension ReusableView where Self: NSView {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
extension NSTableCellView: ReusableView {}

protocol NibLoadableView: class { }
extension NibLoadableView where Self: NSView {
    static var NibName: String {
        return String(describing: self)
    }
}
extension NSTableCellView: NibLoadableView {}
extension NSTableView {
    func makeCell<T: NSTableCellView>() -> T where T: ReusableView {
        guard let cell = make(withIdentifier: T.reuseIdentifier, owner: nil) as? T else {
            fatalError("Could not make cell with identifier: \(T.reuseIdentifier)")
        }
        return cell
    }
    func register<T: NSTableCellView>(_: T.Type) where T: ReusableView, T: NibLoadableView {
        let Nib = NSNib(nibNamed: T.NibName, bundle: nil)
        register(Nib, forIdentifier: T.reuseIdentifier)
    }
}
extension NibLoadableView where Self: NSWindowController {
    static var NibName: String {
        return String(describing: self)
    }
    static func fromNib() -> Self {
        return Self(windowNibName: NibName)
    }
}
extension NSWindowController: NibLoadableView {}
