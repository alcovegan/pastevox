import SwiftUI

struct PromptModePicker: View {
    @Binding var selection: PromptMode

    var body: some View {
        Picker(T("Prompt mode"), selection: $selection) {
            ForEach(PromptMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
    }
}
