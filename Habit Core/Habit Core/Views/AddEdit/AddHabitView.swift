import SwiftUI
import SwiftData

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    /// Non-nil when editing an existing habit.
    var editing: Habit? = nil

    // MARK: - Form state

    @State private var name            = ""
    @State private var description     = ""
    @State private var colorHex        = Color.habitColorHexes[0]
    @State private var frequency       = FrequencyType.daily
    @State private var customDays      = 7
    @State private var weekDay         = 2   // Monday
    @State private var monthDay        = 1
    @State private var hasStartDate    = false
    @State private var startDate       = Date()
    @State private var hasEndDate      = false
    @State private var endDate         = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

    @State private var showResetConfirm  = false
    @State private var showDeleteConfirm = false

    private var isEditing: Bool   { editing != nil }
    private var canSave:   Bool   { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                colorSection
                if !isEditing { frequencySection }
                datesSection
                if isEditing { dangerSection }
            }
            .navigationTitle(isEditing
                ? String(localized: "addhabit.title.edit")
                : String(localized: "addhabit.title.add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        Image(systemName: "checkmark")
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: loadExisting)
            .sheet(isPresented: $showResetConfirm) {
                ConfirmByTypingView(
                    title:       String(localized: "habit.reset.title"),
                    message:     String(localized: "habit.reset.message"),
                    keyword:     String(localized: "confirm.keyword.reset"),
                    buttonLabel: String(localized: "habit.reset.title"),
                    onConfirm:   resetHabit
                )
            }
            .sheet(isPresented: $showDeleteConfirm) {
                ConfirmByTypingView(
                    title:       String(localized: "habit.delete.title"),
                    message:     String(localized: "habit.delete.message"),
                    keyword:     String(localized: "confirm.keyword.delete"),
                    buttonLabel: String(localized: "habit.delete.title"),
                    onConfirm:   deleteHabit
                )
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section {
            TextField(String(localized: "addhabit.name.placeholder"), text: $name)
            TextField(
                String(localized: "addhabit.description.placeholder"),
                text: $description,
                axis: .vertical
            )
            .lineLimit(1...4)
        }
    }

    private var colorSection: some View {
        Section(String(localized: "addhabit.section.color")) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                ForEach(Color.habitColorHexes, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex) ?? .blue)
                        .frame(width: 40, height: 40)
                        .overlay {
                            if hex == colorHex {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .onTapGesture { colorHex = hex }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var frequencySection: some View {
        Section(String(localized: "addhabit.section.frequency")) {
            Picker(String(localized: "addhabit.frequency"), selection: $frequency) {
                ForEach(FrequencyType.allCases, id: \.self) {
                    Text($0.localizedName).tag($0)
                }
            }

            switch frequency {
            case .daily:
                EmptyView()

            case .weekly:
                Picker(String(localized: "addhabit.weekday"), selection: $weekDay) {
                    ForEach(1...7, id: \.self) { day in
                        Text(Calendar.current.weekdaySymbols[day - 1]).tag(day)
                    }
                }

            case .monthly:
                Picker(String(localized: "addhabit.monthday"), selection: $monthDay) {
                    ForEach(1...31, id: \.self) { day in
                        Text(ordinal(day)).tag(day)
                    }
                }

            case .custom:
                VStack(alignment: .leading) {
                    Text(String(
                        format: NSLocalizedString("addhabit.custom.days.format", comment: ""),
                        customDays
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Picker("", selection: $customDays) {
                        ForEach(2...90, id: \.self) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
            }
        }
    }

    private var startDateLocked: Bool {
        guard let h = editing else { return false }
        return h.effectiveStart < Calendar.current.startOfDay(for: Date())
    }

    private var datesSection: some View {
        Section {
            Toggle(String(localized: "addhabit.startdate.toggle"), isOn: $hasStartDate)
                .disabled(startDateLocked)
            if hasStartDate {
                DatePicker(
                    String(localized: "addhabit.startdate"),
                    selection: $startDate,
                    displayedComponents: .date
                )
                .disabled(startDateLocked)
            }
            Toggle(String(localized: "addhabit.enddate.toggle"), isOn: $hasEndDate)
            if hasEndDate {
                DatePicker(
                    String(localized: "addhabit.enddate"),
                    selection: $endDate,
                    in: startDate...,
                    displayedComponents: .date
                )
            }
        }
    }

    private var dangerSection: some View {
        Section {
            Button(String(localized: "habit.reset.button"), role: .destructive) {
                showResetConfirm = true
            }
            Button(String(localized: "habit.delete.button"), role: .destructive) {
                showDeleteConfirm = true
            }
        }
    }

    // MARK: - Logic

    private func loadExisting() {
        guard let h = editing else { return }
        name        = h.name
        description = h.habitDescription
        colorHex    = h.colorHex
        frequency   = h.frequency
        customDays  = h.customDays
        weekDay     = h.weekDay
        monthDay    = h.monthDay
        hasStartDate = h.hasStartDate
        startDate    = h.startDate ?? Date()
        hasEndDate   = h.hasEndDate
        endDate      = h.endDate ?? Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    }

    private func save() {
        let habit = editing ?? {
            let h = Habit()
            modelContext.insert(h)
            return h
        }()

        habit.name            = name.trimmingCharacters(in: .whitespaces)
        habit.habitDescription = description
        habit.colorHex        = colorHex
        habit.frequency       = frequency
        habit.customDays      = customDays
        habit.weekDay         = weekDay
        habit.monthDay        = monthDay
        habit.hasStartDate    = hasStartDate
        habit.startDate       = hasStartDate ? startDate : nil
        habit.hasEndDate      = hasEndDate
        habit.endDate         = hasEndDate ? endDate : nil

        try? modelContext.save()
        dismiss()
    }

    private func resetHabit() {
        guard let habit = editing else { return }
        habit.entries.forEach { modelContext.delete($0) }
        habit.entries.removeAll()
        habit.createdAt = Date()
        habit.hasStartDate = false
        habit.startDate = nil
        try? modelContext.save()
        dismiss()
    }

    private func deleteHabit() {
        guard let habit = editing else { return }
        modelContext.delete(habit)
        try? modelContext.save()
        dismiss()
    }

    private func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
