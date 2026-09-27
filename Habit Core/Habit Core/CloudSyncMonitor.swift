import CoreData
import Observation

/// Observes NSPersistentCloudKitContainer.eventChangedNotification to expose CloudKit
/// sync status in-app, without needing the CloudKit Console.
@Observable
final class CloudSyncMonitor {
    static let shared = CloudSyncMonitor()

    enum Status: Equatable {
        case idle
        case syncing(String)
        case success
        case failed(String)
    }

    private(set) var status: Status = .idle
    @ObservationIgnored private var observer: NSObjectProtocol?

    private init() {}

    func start() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let event = notification.userInfo?[
                NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            ] as? NSPersistentCloudKitContainer.Event else { return }

            let label: String
            switch event.type {
            case .setup:  label = "Setting up iCloud sync"
            case .import: label = "Downloading from iCloud"
            case .export: label = "Uploading to iCloud"
            @unknown default: label = "Syncing"
            }

            if event.endDate == nil {
                self?.status = .syncing(label)
                return
            }
            if let error = event.error {
                self?.status = .failed(error.localizedDescription)
                return
            }
            self?.status = event.succeeded ? .success : .idle
        }
    }
}
