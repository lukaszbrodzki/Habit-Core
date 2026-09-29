import WidgetKit
import AppIntents
import SwiftData

/// A habit the widget can be configured to show, or the "All Habits" sentinel.
struct HabitEntity: AppEntity, Hashable {
    static let allHabitsID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    let id: UUID
    let name: String
    let colorHex: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { TypeDisplayRepresentation(name: "intent.habit.title") }
    static let defaultQuery = HabitEntityQuery()

    static var allHabits: HabitEntity {
        HabitEntity(id: allHabitsID, name: String(localized: "tracker.combined.title"), colorHex: SharedDefaults.defaultColorHex)
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct HabitEntityQuery: EntityQuery {
    func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
        try await allEntities().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        try await allEntities()
    }

    func defaultResult() async -> HabitEntity? {
        HabitEntity.allHabits
    }

    private func allEntities() async throws -> [HabitEntity] {
        guard let container = WidgetModelStore.container else { return [.allHabits] }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let habits = (try? context.fetch(descriptor)) ?? []
        return [.allHabits] + habits.map { HabitEntity(id: $0.id, name: $0.name, colorHex: $0.colorHex) }
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "intent.habit.title" }
    static var description: IntentDescription { IntentDescription("intent.description") }

    @Parameter(title: "intent.habit.title", default: HabitEntity.allHabits)
    var habit: HabitEntity
}
