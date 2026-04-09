import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "=VLOOKUP(\"soul\", self, FALSE)",
                systemImage: "person.fill",
                description: Text("#N/A")
            )
            .navigationTitle("Rap Sheet")
        }
    }
}

#Preview {
    ProfileView()
}
