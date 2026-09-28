import WidgetKit
import AppIntents
import SwiftData

/// A habit the widget can be configured to show, or the "All Habits" sentinel.
struct HabitEntity: AppEntity, Hashable {
    static let allHabitsID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    let id: UUID
    let name: String
    let colorHex: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Habit" }
    static var defaultQuery = HabitEntityQuery()

    static var allHabits: HabitEntity {
        HabitEntity(id: allHabitsID, name: "All Habits", colorHex: "#4A90D9")
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
    static var title: LocalizedStringResource { "Habit" }
    static var description: IntentDescription { "Choose a habit to show, or All Habits." }

    @Parameter(title: "Habit", default: HabitEntity.allHabits)
    var habit: HabitEntity
}
