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
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Email")) {
                    TextField("email@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                }
                
                Section(header: Text("Password")) {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                    
                    if isCreatingAccount {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.password)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
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
                            errorMessage = nil
                        }
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(isCreatingAccount ? "Create Account" : "Sign In")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
            )
        }
    }
    
    private var isFormValid: Bool {
        if email.isEmpty || password.isEmpty {
            return false
        }
        
        if isCreatingAccount {
            return password == confirmPassword && password.count >= 6
        }
        
        return true
    }
    
    private func signIn() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                isPresented = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func createAccount() {
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        Task {
            do {
                try await authService.signUp(email: email, password: password)
                isPresented = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
