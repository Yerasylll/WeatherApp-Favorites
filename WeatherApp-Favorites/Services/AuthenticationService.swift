//
//  AuthenticationService.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import Foundation
import FirebaseAuth
import Combine

class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    static let shared = AuthenticationService()
    
    private init() {
        print("AuthenticationService initialized")
        
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
                print("Auth state changed: \(user?.uid ?? "nil")")
            }
        }
        
        if let currentUser = Auth.auth().currentUser {
            self.user = currentUser
            self.isAuthenticated = true
            print("User already signed in: \(currentUser.uid)")
            print("   - Is anonymous: \(currentUser.isAnonymous)")
        }
    }
    
    // MARK: - Anonymous Auth
    func signInAnonymously() async throws {
        print("Starting anonymous sign in...")
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
                self.errorMessage = nil
                print("Signed in anonymously with UID: \(result.user.uid)")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to sign in anonymously. Please try again."
                print("Anonymous auth error: \(error.localizedDescription)")
            }
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Email/Password Auth
    func signIn(email: String, password: String) async throws {
        print("Signing in with email: \(email)")
        isLoading = true
        errorMessage = nil
        
        // Validate email format
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid email"])
        }
        
        // Validate password
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            isLoading = false
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Password required"])
        }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
                self.errorMessage = nil
                print("Signed in with email: \(result.user.email ?? "N/A")")
            }
        } catch let error as NSError {
            DispatchQueue.main.async {
                switch error.code {
                case AuthErrorCode.wrongPassword.rawValue:
                    self.errorMessage = "Incorrect password. Please try again."
                case AuthErrorCode.userNotFound.rawValue:
                    self.errorMessage = "No account found with this email. Please sign up."
                case AuthErrorCode.invalidEmail.rawValue:
                    self.errorMessage = "Invalid email format. Please check your email."
                case AuthErrorCode.networkError.rawValue:
                    self.errorMessage = "Network error. Please check your connection."
                case AuthErrorCode.tooManyRequests.rawValue:
                    self.errorMessage = "Too many attempts. Please try again later."
                case AuthErrorCode.userDisabled.rawValue:
                    self.errorMessage = "This account has been disabled."
                default:
                    self.errorMessage = "Sign in failed. Please check your credentials."
                }
                print("Email auth error: \(error.localizedDescription)")
            }
            throw error
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String) async throws {
        print("Creating account for: \(email)")
        isLoading = true
        errorMessage = nil
        
        // Validate email format
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid email"])
        }
        
        // Validate password strength
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Password too short"])
        }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
                self.errorMessage = nil
                print("Account created: \(result.user.email ?? "N/A")")
            }
        } catch let error as NSError {
            DispatchQueue.main.async {
                switch error.code {
                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    self.errorMessage = "This email is already registered. Please sign in."
                case AuthErrorCode.invalidEmail.rawValue:
                    self.errorMessage = "Invalid email format. Please check your email."
                case AuthErrorCode.weakPassword.rawValue:
                    self.errorMessage = "Password is too weak. Please use a stronger password."
                case AuthErrorCode.networkError.rawValue:
                    self.errorMessage = "Network error. Please check your connection."
                case AuthErrorCode.operationNotAllowed.rawValue:
                    self.errorMessage = "Email/password accounts are not enabled."
                default:
                    self.errorMessage = "Failed to create account. Please try again."
                }
                print("Sign up error: \(error.localizedDescription)")
            }
            throw error
        }
        
        isLoading = false
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            
            DispatchQueue.main.async {
                self.user = nil
                self.isAuthenticated = false
                self.errorMessage = nil
                print("Signed out successfully")
            }
        } catch {
            print("Sign out error: \(error)")
            throw error
        }
    }
    
    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    // Helper function to validate email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
