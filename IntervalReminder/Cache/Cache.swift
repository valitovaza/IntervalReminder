import CoreData
protocol Cache {
    func saveIntervals(_ intervals: [Interval])
    func getIntervals() -> [Interval]
}
struct CoreDataCache: Cache {
    static let coreDataName = "Intervals"
    static let sortField = "index"
    var persistentContainer = NSPersistentContainer(name: CoreDataCache.coreDataName)
    init() {
        load()
    }
    private func load() {
        persistentContainer.loadPersistentStores() { _, error in
            self.crash(error)
        }
    }
    private func crash(_ error: Error?) {
        if let error = error as? NSError {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }
    func saveIntervals(_ intervals: [Interval]) {
        deleteAll()
        createCacheIntervals(intervals)
        save()
    }
    private func save() {
        if persistentContainer.viewContext.hasChanges {
            try? persistentContainer.viewContext.save()
        }
    }
    private func deleteAll() {
        (try? persistentContainer.viewContext.fetch(request()))?.forEach({ (interval) in
            persistentContainer.viewContext.delete(interval)
        })
    }
    private func createCacheIntervals(_ intervals: [Interval]) {
        for index in 0..<intervals.count {
            let interval = intervals[index]
            createCacheInterval(interval, at: index)
        }
    }
    private func createCacheInterval(_ interval: Interval, at index: Int) {
        let cacheInterval = CacheInterval(context: persistentContainer.viewContext)
        cacheInterval.interval = interval.timeInterval
        cacheInterval.text = interval.text
        cacheInterval.index = Int64(index)
    }
    func getIntervals() -> [Interval] {
        if let intervals = try? persistentContainer.viewContext.fetch(request()) {
            return intervals.map(convertCacheToInterval)
        }
        return []
    }
    private func convertCacheToInterval(cacheInterval: CacheInterval) -> Interval {
        return Interval(cacheInterval.interval, cacheInterval.text ?? "")
    }
    private func request() -> NSFetchRequest<CacheInterval> {
        let fetchRequest = NSFetchRequest<CacheInterval>()
        fetchRequest.entity = CacheInterval.entity()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: CoreDataCache.sortField, ascending: true)]
        return fetchRequest
    }
}
