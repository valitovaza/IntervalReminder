import Cocoa
protocol SheetChildWindow {
    var sheetParent: NSWindow? { get }
}
extension NSWindow: SheetChildWindow {}
class ModalController: NSWindowController {
    @IBOutlet weak var createButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var notificationTextField: NSTextField!
    @IBOutlet weak var intervalPicker: NSDatePicker!
    
    var selectedDate: Date! {
        didSet {
            selectedIntervals = intervals(selectedDate, Calendar.current)
        }
    }
    var selectedIntervals: Double = 0 {
        didSet {
            if selectedIntervals == 0 {
                setValue("", forKey: trimmedTextName)
            }else{
                updateTrimmedText()
            }
        }
    }
    private let trimmedTextName = "trimmedText"
    var text: NSString = "" {
        didSet {
            if selectedIntervals > 0 {
                updateTrimmedText()
            }
        }
    }
    private func updateTrimmedText() {
        setValue(text.trimmingCharacters(in: .whitespaces) as NSString, forKey: trimmedTextName)
    }
    var trimmedText: NSString = ""
    
    var sheetChild: SheetChildWindow!
    var intervalInteractor: IntervalInteractorProtocol!
    
    override func windowDidLoad() {
        sheetChild = window
        selectedDate = intervalPicker.dateValue
    }
    @IBAction func cancel(_ sender: NSButton) {
        close(NSModalResponseCancel)
    }
    @IBAction func create(_ sender: NSButton) {
        intervalInteractor.create(interval: intervals(), withText: text as String)
        close(NSModalResponseOK)
    }
    private func close(_ code: Int) {
        sheetChild.sheetParent?.endSheet(window!, returnCode: code)
    }
    private func intervals() -> Double {
        return intervals(intervalPicker.dateValue, Calendar.current)
    }
    private func intervals(_ date: Date, _ calendar: Calendar) -> Double {
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        return intervals(hour, minutes, seconds)
    }
    private func intervals(_ hour: Int, _ minutes: Int, _ seconds: Int) -> Double {
        return Double(hour * 3600  + minutes * 60 + seconds)
    }
}
