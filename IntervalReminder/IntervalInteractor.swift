import Foundation
protocol IntervalKeeperProtocol {
    func stop()
}
protocol IntervalInteractorProtocol: IntervalKeeperProtocol {
    func create(interval: Double, withText text: String)
    func changeRepeat()
    func intervalAction()
}
protocol IntervalsChangePresenter: class {
    func newInterval(at index: Int)
    func enableIntervalButton()
    func disableIntervalButton()
    func configureIntervalButton(title: String)
    func configureStopButton(inProgress: Bool)
    func updateProgress()
    func intervalStarted(_ interval: Double)
    func intervalStopped()
    func intervalEnded()
    func intervalResumed(elapsed: Double, interval: Double)
}
class IntervalInteractor: IntervalInteractorProtocol, IntervalDataProvider {
    fileprivate weak var presenter: IntervalsChangePresenter?
    var repeater: IntervalRepeaterProtocol!
    
    private(set) var paused = false
    fileprivate var pastInterval: Double = 0.0
    
    var timer: TimeScheduler!
    private(set) var currentProgressTimer: Timer?
    var timeProvider: CurrentTimeProvider = CATimeProvider()
    var currentIndex: Int {
        return repeater.currentIndex
    }
    var notificationPresenter: NotificationPresenterProtocol = NotificationPresenter()
    init(_ presenter: IntervalsChangePresenter) {
        self.presenter = presenter
        timer = Timer()
        repeater = IntervalRepeater(self, IntervalTimer())
    }
    
    // MARK: - IntervalInteractorProtocol
    func create(interval: Double, withText text: String) {
        repeater.intervalContainer.add(Interval(interval, text))
        presenter?.newInterval(at: 0)
        presenter?.enableIntervalButton()
    }
    func changeRepeat() {
        repeater.repeatIntervals = !repeater.repeatIntervals
    }
    func intervalAction() {
        if repeater.inProgress {
            inProgressAction()
        }else{
            start()
        }
    }
    private func inProgressAction() {
        if paused {
            resume()
        }else{
            pause()
        }
    }
    
    // MARK: - IntervalDataProvider
    func count() -> Int {
        return repeater.intervalContainer.intervalsCount
    }
    func title(forRow row: Int) -> String {
        return repeater.intervalContainer.interval(at: row)!.text
    }
    func interval(forRow row: Int) -> Double {
        return repeater.intervalContainer.interval(at: row)!.timeInterval
    }
    func elapsedInterval(forRow row: Int) -> Double {
        return repeater.inProgress ? elapsedTime() : 0.0
    }
    private func elapsedTime() -> Double {
        return paused ? pastInterval : timeProvider.currentTime() - repeater.currentStartTime + pastInterval
    }
    func delete(at index: Int) {
        repeater.intervalContainer.remove(at: index)
        if isEmptyContainer() {
            presenter?.disableIntervalButton()
        }
    }
    private func isEmptyContainer() -> Bool {
        return repeater.intervalContainer.intervalsCount == 0
    }
    func start() {
        if !isEmptyContainer() {
            paused = false
            repeater.start()
            presenter?.configureIntervalButton(title: ButtonTitles.Pause.rawValue)
        }
    }
    func pause() {
        pastInterval += timeProvider.currentTime() - repeater.currentStartTime
        paused = true
        repeater.pause()
        pausePresenter()
    }
    private func pausePresenter() {
        presenter?.configureIntervalButton(title: ButtonTitles.Resume.rawValue)
        presenter?.intervalStopped()
    }
    func resume() {
        paused = false
        repeater.resume()
        resumePresenter()
    }
    private func resumePresenter() {
        presenter?.configureIntervalButton(title: ButtonTitles.Pause.rawValue)
        if let interval = repeater.intervalContainer.interval(at: currentIndex) {
            presenter?.intervalResumed(elapsed: pastInterval,interval: interval.timeInterval)
        }
    }
    
    // MARK: - IntervalKeeperProtocol
    func stop() {
        pastInterval = 0.0
        paused = false
        repeater.stop()
        stopPresenter()
    }
    private func stopPresenter() {
        presenter?.configureIntervalButton(title: ButtonTitles.Start.rawValue)
        presenter?.intervalEnded()
    }
    
    // MARK: - Auxiliary methods
    fileprivate func configureTimer(_ progress: Bool) {
        if progress {
            startTimer()
        }else{
            stopTimer()
        }
    }
    fileprivate func startTimer() {
        currentProgressTimer = timer.scheduledTimer(withTimeInterval: 0.5,
                                                    repeats: true)
        {[weak self] (_) in
            self?.presenter?.updateProgress()
        }
    }
    fileprivate func stopTimer() {
        currentProgressTimer?.invalidate()
        currentProgressTimer = nil
    }
}
extension IntervalInteractor: RepeaterDelegate {
    func intervalDidStart(at index: Int) {
        if let interval = repeater.intervalContainer.interval(at: index) {
            presenter?.intervalStarted(interval.timeInterval)
        }
    }
    func intervalDidEnd(text: String, at index: Int) {
        pastInterval = 0.0
        presenter?.intervalEnded()
        notificationPresenter.presentNotification(text)
    }
    func progressChanged(_ progress: Bool) {
        pastInterval = 0.0
        configureTimer(progress)
        updatePresenter(progress)
    }
    private func updatePresenter(_ progress: Bool) {
        presenter?.updateProgress()
        presenter?.configureStopButton(inProgress: progress)
        if !progress {
            presenter?.configureIntervalButton(title: ButtonTitles.Start.rawValue)
            presenter?.intervalEnded()
        }
    }
}
