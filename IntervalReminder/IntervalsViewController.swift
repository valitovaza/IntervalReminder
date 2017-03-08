import Cocoa
protocol MainWindowContainer {
    var mainWindow: NSWindow? { get }
}
extension NSApplication: MainWindowContainer {}

class IntervalsViewController: NSViewController, IntervalsViewProtocol {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var intervalButton: NSButton!
    @IBOutlet weak var stopButton: NSButton!
    @IBOutlet weak var createButton: NSButton!
    @IBOutlet weak var checkButton: NSButton!
    
    var presenter: IntervalPresenterProtocol?
    var interactor: IntervalInteractorProtocol?
    var mainWindowContainer: MainWindowContainer = NSApp
    
    override func awakeFromNib() {
        let intervalPresenter = IntervalPresenter(self)
        let intervalInteractor = IntervalInteractor(intervalPresenter)
        intervalPresenter.dataProvider = intervalInteractor
        set(interactor: intervalInteractor, andPresenter: intervalPresenter)
    }
    private func set(interactor intervalInteractor: IntervalInteractorProtocol,
                     andPresenter intervalPresenter: IntervalPresenterProtocol) {
        presenter = intervalPresenter
        interactor = intervalInteractor
    }
    
    // MARK: - Actions
    private(set) var createController: ModalController?
    @IBAction func create(_ sender: NSButton) {
        if let modalWindow = modalController() {
            mainWindowContainer.mainWindow?.beginSheet(modalWindow,
                                                       completionHandler: sheetHandler(_:))
        }
    }
    func sheetHandler(_ code: NSModalResponse) {
        createController = nil
    }
    private func modalController() -> NSWindow? {
        createController = ModalController.fromNib()
        createController?.intervalInteractor = self.interactor
        return createController?.window
    }
    @IBAction func intervalAction(_ sender: NSButton) {
        interactor?.intervalAction()
    }
    @IBAction func stop(_ sender: NSButton) {
        interactor?.stop()
    }
    @IBAction func changeRepeat(_ sender: NSButton) {
        interactor?.changeRepeat()
    }
    
    // MARK: - IntervalsViewProtocol
    func addRow(at index: Int) {
        tableView.reloadData()
    }
    func removeRow(at index: Int) {
        tableView.reloadData()
    }
    func updateRow(at index: Int) {
        tableView.reloadData()
    }
}
extension IntervalsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return presenter?.count() ?? 0
    }
}
extension IntervalsViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeCell() as NSTableCellView
        presenter?.present(cell: cell, at: row)
        return cell
    }
}
