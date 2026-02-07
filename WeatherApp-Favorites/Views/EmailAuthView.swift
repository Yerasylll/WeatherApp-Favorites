//
//  EmailAuthView.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import SwiftUI

struct EmailAuthView: View {
    @Binding var isPresented: Bool
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isCreatingAccount = false
    @State private var validationErrors: [String] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Email")) {
                    TextField("email@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .onChange(of: email) { _ in
                            validateForm()
                        }
                    
                    if validationErrors.contains("email") {
                        Text("Please enter a valid email")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Password")) {
                    SecureField("Password", text: $password)
                        .textContentType(isCreatingAccount ? .newPassword : .password)
                        .onChange(of: password) { _ in
                            validateForm()
                        }
                    
                    if isCreatingAccount {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .onChange(of: confirmPassword) { _ in
                                validateForm()
                            }
                    }
                    
                    if validationErrors.contains("password") {
                        Text("Password must be at least 6 characters")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if validationErrors.contains("password_match") {
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Show Firebase errors
                if let error = authService.errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Section {
                    Button(isCreatingAccount ? "Create Account" : "Sign In") {
                        if isCreatingAccount {
                            createAccount()
                        } else {
                            signIn()
                        }
                    }
                    .disabled(!isFormValid || authService.isLoading)
                    .frame(maxWidth: .infinity)
                    
                    if authService.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
                
                Section {
                    Button(isCreatingAccount ? "Already have an account? Sign In" : "Need an account? Create One") {
                        withAnimation {
                            isCreatingAccount.toggle()
                            authService.errorMessage = nil
                            validationErrors.removeAll()
                        }
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(isCreatingAccount ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
            )
        }
    }
    
    private var isFormValid: Bool {
        let emailValid = isValidEmail(email)
        let passwordValid = password.count >= 6
        
        if isCreatingAccount {
            return emailValid && passwordValid && password == confirmPassword
        }
        
        return emailValid && passwordValid
    }
    
    private func validateForm() {
        validationErrors.removeAll()
        
        if !isValidEmail(email) && !email.isEmpty {
            validationErrors.append("email")
        }
        
        if password.count < 6 && !password.isEmpty {
            validationErrors.append("password")
        }
        
        if isCreatingAccount && password != confirmPassword && !confirmPassword.isEmpty {
            validationErrors.append("password_match")
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func signIn() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                isPresented = false
            } catch {
                // Error is already handled in AuthenticationService
                print("Sign in error: \(error)")
            }
        }
    }
    
    private func createAccount() {
        guard password == confirmPassword else {
            authService.errorMessage = "Passwords don't match"
            return
        }
        
        guard password.count >= 6 else {
            authService.errorMessage = "Password must be at least 6 characters"
            return
        }
        
        Task {
            do {
                try await authService.signUp(email: email, password: password)
                isPresented = false
            } catch {
                // Error is already handled in AuthenticationService
                print("Sign up error: \(error)")
            }
        }
    }
}
