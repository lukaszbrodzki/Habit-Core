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
    @State private var hasEndDate      = false
    @State private var endDate         = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()

    private var isEditing: Bool   { editing != nil }
    private var canSave:   Bool   { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                colorSection
                if !isEditing { frequencySection }
                endDateSection
            }
            .navigationTitle(isEditing
                ? String(localized: "addhabit.title.edit")
                : String(localized: "addhabit.title.add"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "button.save"), action: save)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadExisting)
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

    private var endDateSection: some View {
        Section {
            Toggle(String(localized: "addhabit.enddate.toggle"), isOn: $hasEndDate)
            if hasEndDate {
                DatePicker(
                    String(localized: "addhabit.enddate"),
                    selection: $endDate,
                    in: Date()...,
                    displayedComponents: .date
                )
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
        hasEndDate  = h.hasEndDate
        endDate     = h.endDate ?? Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
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
        habit.hasEndDate      = hasEndDate
        habit.endDate         = hasEndDate ? endDate : nil

        try? modelContext.save()
        dismiss()
    }

    private func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
