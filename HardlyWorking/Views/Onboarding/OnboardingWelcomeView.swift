import AuthenticationServices
import SwiftUI

struct OnboardingWelcomeView: View {
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false

    @State private var isSigningIn = false
    @State private var signInError: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("mascot_welcome")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 220)

            Spacer().frame(height: 24)

            Text("Welcome to\nHardly Working Corp.")
                .font(.system(size: 24, weight: .light, design: .monospaced))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 8)

            Text("Your orientation will be conducted\nby John D., Employee Relations Officer.")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)

            Spacer().frame(height: 32)

            if isSignedIn {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.money)
                    Text("Identity on file.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Theme.textPrimary.opacity(0.5))
                }
            } else if isSigningIn {
                ProgressView()
                    .padding(.vertical, 12)
            } else {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = []
                } onCompletion: { result in
                    handleSignIn(result)
                }
                .signInWithAppleButtonStyle(.whiteOutline)
                .frame(height: 50)
                .padding(.horizontal, 40)

                Text("For your permanent record.")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.3))
                    .padding(.top, 8)
            }

            if let signInError {
                Text(signInError)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.timer)
                    .padding(.top, 8)
            }

            Spacer()

            Text("By order of J. Pemberton, CSO.\nAll new hires must complete orientation.")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

            isSigningIn = true
            signInError = nil

            Task {
                do {
                    try await SupabaseManager.shared.signInWithApple(credential: credential)
                    isSignedIn = true
                    Haptics.success()
                } catch {
                    signInError = "Verification failed. You may\nproceed as a guest employee."
                    print("[SIWA] Error: \(error)")
                }
                isSigningIn = false
            }

        case .failure:
            // User cancelled — not an error
            break
        }
    }
}
