import AuthenticationServices
import SwiftUI

struct OnboardingCommitmentView: View {
    @Binding var hasCommitted: Bool
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false

    @State private var isSigningIn = false
    @State private var signInError: String?
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showPledge = false
    @State private var showCheckbox = false
    @State private var showSIWA = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 32)

                Text("Final clearance\nrequired!")
                    .font(.system(size: 24, weight: .light, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 10)

                Spacer().frame(height: 12)

                Text("To complete your enrollment at\nHardly Working Corp., acknowledge\nthe following:")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .opacity(showSubtitle ? 1 : 0)

                Spacer().frame(height: 24)

                pledgeCard
                    .opacity(showPledge ? 1 : 0)
                    .offset(y: showPledge ? 0 : 15)

                Spacer().frame(height: 20)

                checkboxRow
                    .opacity(showCheckbox ? 1 : 0)

                Spacer().frame(height: 12)

                Text("This pledge is non-binding, non-enforceable,\nand carries no weight of any kind.")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .opacity(showCheckbox ? 1 : 0)

                Spacer().frame(height: 28)

                // MARK: - Sign in with Apple

                Group {
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
                        VStack(spacing: 0) {
                            Text("EMPLOYEE VERIFICATION")
                                .font(.system(.caption2, design: .monospaced, weight: .bold))
                                .foregroundStyle(Theme.textPrimary.opacity(0.3))
                                .tracking(1.5)
                                .padding(.bottom, 12)

                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = []
                            } onCompletion: { result in
                                handleSignIn(result)
                            }
                            .signInWithAppleButtonStyle(.whiteOutline)
                            .frame(height: 50)
                            .padding(.horizontal, 16)

                            Text("Required to finalize your employee dossier.\nAnonymous by design. HR can't find you.")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(Theme.textPrimary.opacity(0.45))
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                    }
                }
                .opacity(showSIWA ? 1 : 0)
                .offset(y: showSIWA ? 0 : 10)

                if let signInError {
                    Text(signInError)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Theme.timer)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.hidden)
        .onAppear { startSequence() }
    }

    private func startSequence() {
        withAnimation(.easeOut(duration: 0.4)) { showTitle = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.3)) { showSubtitle = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showPledge = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.3)) { showCheckbox = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.4)) { showSIWA = true }
        }
    }

    // MARK: - Pledge Card

    private var pledgeCard: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.textPrimary.opacity(0.06))
                .frame(height: 2)

            Text("I, the undersigned, hereby commit\nto the accurate and ongoing\nreclamation of non-productive time\nas defined by Hardly Working Corp.\n(Ref: MEMO-2026-001)")
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 24)
                .padding(.horizontal, 20)

            Rectangle()
                .fill(Theme.textPrimary.opacity(0.06))
                .frame(height: 2)
        }
        .background(Theme.cardBackground.opacity(0.5))
    }

    // MARK: - Checkbox

    private var checkboxRow: some View {
        Button {
            Haptics.medium()
            hasCommitted.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: hasCommitted ? "checkmark.square.fill" : "square")
                    .font(.system(.title3, weight: .medium))
                    .foregroundStyle(hasCommitted ? Theme.accent : Theme.textPrimary.opacity(0.2))

                Text("I have read and accept this pledge.")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sign In

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

                    // Cache the server-assigned Employee ID so the Personnel
                    // File on the Dossier tab can show it immediately. The
                    // `handle_new_user` trigger runs synchronously with the
                    // auth.users insert, so the row is guaranteed to exist.
                    if let empId = try? await SupabaseManager.shared.fetchMyEmployeeId() {
                        UserDefaults.standard.set(empId, forKey: "employeeId")
                    }
                } catch {
                    signInError = "Verification failed. Please try again."
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
