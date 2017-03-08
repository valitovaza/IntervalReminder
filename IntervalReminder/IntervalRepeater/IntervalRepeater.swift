protocol RepeaterDelegate: class {
    func intervalDidStart(at index: Int)
    func intervalDidEnd(text: String, at index: Int)
    func progressChanged(_ progress: Bool)
}
protocol IntervalRepeaterProtocol {
    var intervalContainer: IntervalContainer! {get}
    var inProgress: Bool {get}
    var currentIndex: Int {get}
    var currentStartTime: Double {get}
    var repeatIntervals: Bool {get set}
    func start()
    func resume()
    func stop()
    func pause()
}
class IntervalRepeater: ContainerListener, IntervalRepeaterProtocol {
    var repeatIntervals = false
    
    private(set) var currentIndex = 0
    private(set) var inProgress = false {
        didSet {
            delegate?.progressChanged(inProgress)
        }
    }
    var currentStartTime: Double {
        return scheduler.startTime
    }
    private weak var delegate: RepeaterDelegate?
    private var scheduler: ResumableTimer!
    private(set) var intervalContainer: IntervalContainer!
    
    private var currentIndexCanChange = false
    
    init(_ delegate: RepeaterDelegate,
         _ scheduler: ResumableTimer) {
        self.delegate = delegate
        self.scheduler = scheduler
        intervalContainer = IntervalContainer(self)
    }
    func setCurrentIndex(_ index: Int) {
        currentIndexCanChange = true
        if isValidIndex(index) {
            currentIndex = index
        }
    }
    private func isValidIndex(_ index: Int) -> Bool {
        return index >= 0 && index < intervalContainer.intervalsCount
    }
    func start() {
        currentIndexCanChange = true
        guard let currentInterval = intervalContainer.interval(at: currentIndex)
            else {return}
        delegate?.intervalDidStart(at: currentIndex)
        schedule(interval: currentInterval)
    }
    private func schedule(interval: Interval) {
        changeProgressState(true)
        scheduler.scheduleInterval(interval.timeInterval)
        {[unowned self] (_) in
            self.intervalDidEnd(interval.text)
        }
    }
    func pause() {
        scheduler.stop()
    }
    func resume() {
        if inProgress {
            scheduler.resume()
        }
    }
    func stop() {
        scheduler.stop()
        setCurrentIndex(0)
        changeProgressState(false)
    }
    private func intervalDidEnd(_ text: String) {
        delegate?.intervalDidEnd(text: text, at: currentIndex)
        changeCurrentIndex()
        checkNextInterval()
    }
    private let incrementStep = 1
    private func changeCurrentIndex() {
        if currentIndex + incrementStep < intervalContainer.intervalsCount {
            currentIndex += incrementStep
        }else{
            currentIndex = 0
        }
    }
    private func checkNextInterval() {
        if shouldStartNext() {
            start()
        }else{
            changeProgressState(false)
        }
    }
    private func shouldStartNext() -> Bool {
        return currentIndex > 0 || repeatIntervals
    }
    private func changeProgressState(_ newState: Bool) {
        if newState != inProgress {
            inProgress = newState
        }
    }
    
    // MARK: - ContainerListener
    func itemAdded() {
        if currentIndexCanChange &&
            currentIndex < intervalContainer.intervalsCount - 1 {
            currentIndex += 1
        }
    }
    func itemRemoved(at index: Int) {
        if index <= currentIndex {
            stopSchedulerIfCurrent(index)
            decrementCurrentIndex()
        }
    }
    func itemMoved(from fromIndex: Int, to toIndex: Int) {
        if currentIndex == fromIndex {
            setCurrentIndex(toIndex)
        }
    }
    
    // MARK: - Auxiliary methods
    private func stopSchedulerIfCurrent(_ index: Int) {
        if index == currentIndex {
            scheduler.stop()
            changeProgressState(false)
        }
    }
    private func decrementCurrentIndex() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
}
