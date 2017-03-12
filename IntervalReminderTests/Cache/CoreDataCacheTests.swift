import XCTest
@testable import IntervalReminder
class CoreDataCacheTests: XCTestCase {
    // MARK: - Parameters & Constants
    private let timerInterval: Double = 23.342
    private let timerText = "TestString3123213123"
    private let timerText2 = "asd22222"
    
    // MARK: - Test variables
    private var sut: CoreDataCache!
    
    lazy var container: NSPersistentContainer = {
        return NSPersistentContainer(name: CoreDataCache.coreDataName)
    }()
    
    // MARK: - Set up and tear down
    override func setUp() {
        super.setUp()
        
        loadStore()
        sut = CoreDataCache()
        sut.persistentContainer = container
    }
    private func loadStore() {
        weak var expectation = self.expectation(description: "callback")
        
        let configuration = NSPersistentStoreDescription()
        configuration.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [configuration]
        
        container.loadPersistentStores() { _, error in
            if let error = error as? NSError {
                XCTFail("Unresolved error \(error), \(error.userInfo)")
            }
            expectation?.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testCanCreateInterval() {
        XCTAssertNotNil(sut, "SUT must not be nil")
    }
    func testPersistentContainerNameIsValid() {
        XCTAssertEqual(sut.persistentContainer.name, CoreDataCache.coreDataName)
    }
    func testGetIntervalsMustReturnSavedIntervals() {
        createCacheInterval(interval: timerInterval, text: timerText, index: 0)
        save()
        XCTAssertEqual(sut.getIntervals()[0].text, timerText)
        XCTAssertEqual(sut.getIntervals().count, 1)
    }
    func testGetIntervalsOrder() {
        createCacheInterval(interval: timerInterval, text: timerText, index: 1)
        createCacheInterval(interval: timerInterval, text: timerText2, index: 0)
        save()
        XCTAssertEqual(sut.getIntervals()[0].text, timerText2)
    }
    private func save() {
        try! container.viewContext.save()
    }
    private func createCacheInterval(interval: Double, text: String, index: Int) {
        let cacheInterval = CacheInterval(context: container.viewContext)
        cacheInterval.interval = interval
        cacheInterval.text = text
        cacheInterval.index = Int64(index)
    }
    func testSaveIntervalsMustCacheProdidedIntervals() {
        let intervals = [Interval(timerInterval, timerText)]
        sut.saveIntervals(intervals)
        XCTAssertEqual(sut.getIntervals()[0].text, timerText)
    }
    func testSaveMustRemoveOldIntervals() {
        createCacheInterval(interval: timerInterval, text: timerText2, index: 0)
        let intervals = [Interval(timerInterval, timerText)]
        sut.saveIntervals(intervals)
        XCTAssertEqual(sut.getIntervals().count, 1)
    }
}
