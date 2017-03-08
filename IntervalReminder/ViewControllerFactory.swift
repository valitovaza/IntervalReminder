import Cocoa

protocol StoryboardIdentifiable {
    static var storyboardIdentifier: String { get }
}

enum ViewControllersFactoryStoryboardType: String {
    case main = "Main"
}

extension NSViewController: StoryboardIdentifiable {}

extension StoryboardIdentifiable where Self: NSViewController {
    static var storyboardIdentifier: String {
        return String(describing: self)
    }
}

final class ViewControllersFactory {
    
    static func instantiateViewController<T: NSViewController>(inStoryboard type: ViewControllersFactoryStoryboardType) -> T where T: StoryboardIdentifiable {
        
        let storyboard = NSStoryboard(name: type.rawValue, bundle: nil)
        guard let viewController = storyboard.instantiateController(withIdentifier: T.storyboardIdentifier) as? T else {
            fatalError("Couldn't instantiate view controller with identifier \(T.storyboardIdentifier)")
        }
        
        return viewController
    }
}
