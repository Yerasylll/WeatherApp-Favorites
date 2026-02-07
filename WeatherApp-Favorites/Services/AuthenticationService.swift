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
    
    private var authStateHandle: AuthStateDidChangeListenerHandle? // Add this
    
    static let shared = AuthenticationService()
    
    private init() {
        print("AuthenticationService initialized")
        
        // Store the handle to avoid warning
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
                print("Auth state changed: \(user?.uid ?? "nil")")
            }
        }
        
        // Check initial state
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
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
                self.errorMessage = nil
                print("Signed in anonymously with UID: \(result.user.uid)")
                print("   - Is anonymous: \(result.user.isAnonymous)")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Anonymous sign in failed: \(error.localizedDescription)"
                print("Anonymous auth error: \(error)")
            }
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Email/Password Auth
    func signIn(email: String, password: String) async throws {
        print("Signing in with email: \(email)")
        isLoading = true
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
                self.errorMessage = nil
                print("Signed in with email: \(result.user.email ?? "N/A")")
                print("   - UID: \(result.user.uid)")
            }
        } catch let error as NSError {
            DispatchQueue.main.async {
                self.errorMessage = "Sign in failed: \(error.localizedDescription)"
                print("Email auth error: \(error)")
            }
            throw error
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String) async throws {
        print("Creating account for: \(email)")
        isLoading = true
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
                self.errorMessage = nil
                print("Account created: \(result.user.email ?? "N/A")")
                print("   - UID: \(result.user.uid)")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Sign up failed: \(error.localizedDescription)"
                print("Sign up error: \(error)")
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
    
    deinit {
        // Clean up the listener when object is destroyed
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
