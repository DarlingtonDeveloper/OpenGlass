import SwiftUI

struct ModePickerView: View {
    @EnvironmentObject var modeRouter: ModeRouter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(modeRouter.availableModes, id: \.id) { mode in
                    let isActive = mode.id == modeRouter.currentMode.id
                    Button {
                        modeRouter.switchTo(mode)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.subheadline)
                            Text(mode.name)
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundColor(isActive ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            isActive ? Color.blue : Color.white.opacity(0.1),
                            in: Capsule()
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ModePickerView()
        .environmentObject(ModeRouter())
        .background(Color.black)
}
