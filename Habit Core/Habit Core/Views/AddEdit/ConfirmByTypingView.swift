import SwiftUI

struct ConfirmByTypingView: View {
    let title: String
    let message: String
    let keyword: String
    let buttonLabel: String
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input = ""

    private var confirmed: Bool { input == keyword }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(message)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text(String(
                        format: NSLocalizedString("confirm.type.prompt", comment: ""),
                        keyword
                    ))
                    .font(.subheadline)

                    TextField(keyword, text: $input)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(10)
                        .background(Color(.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 10))
                }

                Button(role: .destructive) {
                    onConfirm()
                    dismiss()
                } label: {
                    Text(buttonLabel)
                        .frame(maxWidth: .infinity)
                }
                .disabled(!confirmed)
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Spacer()
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "button.cancel")) { dismiss() }
                }
            }
        }
    }
}
