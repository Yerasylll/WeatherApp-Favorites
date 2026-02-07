//
//  FirebaseRepository.swift
//  WeatherApp-Favorites
//

import Foundation
import FirebaseDatabase
import Combine

class FirebaseRepository: ObservableObject {
    static let shared = FirebaseRepository()
    
    @Published var favoriteCities: [FavoriteCity] = []
    
    private let database = Database.database().reference()
    private let authService = AuthenticationService.shared
    private var handle: DatabaseHandle?
    
    private init() {}
    
    private var userId: String? {
        return authService.getCurrentUserId()
    }
    
    private func userFavoritesPath() -> DatabaseReference? {
        guard let userId = userId else { return nil }
        return database.child("users").child(userId).child("favorites")
    }
    
    // Real-time listener for favorites
    func startListening() {
        guard let favoritesRef = userFavoritesPath() else {
            print("Cannot start listening - no user path")
            return
        }
        
        print("Starting Firebase listener on: \(favoritesRef)")
        
        // Remove any existing listener first
        if let existingHandle = handle {
            favoritesRef.removeObserver(withHandle: existingHandle)
        }
        
        handle = favoritesRef.observe(.value) { [weak self] snapshot in
            print("Firebase listener triggered")
            
            var cities: [FavoriteCity] = []
            
            // Check if snapshot exists
            if snapshot.exists() {
                print("Snapshot exists, processing children...")
                
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let dict = snapshot.value as? [String: Any],
                       let city = FavoriteCity(dictionary: dict) {
                        cities.append(city)
                        print("Added: \(city.name)")
                    }
                }
                
                print("Total favorites found: \(cities.count)")
            } else {
                print("Snapshot is empty (no favorites yet)")
            }
            
            DispatchQueue.main.async {
                self?.favoriteCities = cities.sorted { $0.createdAt > $1.createdAt }
                print("UI updated with \(self?.favoriteCities.count ?? 0) favorites")
            }
        }
    }
    
    func stopListening() {
        if let handle = handle {
            userFavoritesPath()?.removeObserver(withHandle: handle)
        }
        handle = nil
    }
    
    // CRUD Operations
    
    func addFavorite(city: String, note: String? = nil, coordinates: (lat: Double, lon: Double)) async throws {
        guard let userId = userId else {
            throw FirebaseError.unauthenticated
        }
        
        guard let favoritesRef = userFavoritesPath() else {
            throw FirebaseError.invalidReference
        }
        
        let favorite = FavoriteCity(
            name: city,
            note: note,
            createdBy: userId,
            latitude: coordinates.lat,
            longitude: coordinates.lon
        )
        
        do {
            try await favoritesRef.child(favorite.id).setValue(favorite.dictionary)
            
            // Immediately update local state
            await MainActor.run {
                if !self.favoriteCities.contains(where: { $0.id == favorite.id }) {
                    self.favoriteCities.append(favorite)
                    self.favoriteCities.sort { $0.createdAt > $1.createdAt }
                }
            }
        } catch {
            throw error
        }
    }
    
    func updateFavorite(id: String, note: String?) async throws {
        guard let favoritesRef = userFavoritesPath() else {
            throw FirebaseError.invalidReference
        }
        
        let updates: [String: Any] = [
            "note": note ?? ""
        ]
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            favoritesRef.child(id).updateChildValues(updates) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func deleteFavorite(id: String) async throws {
        guard let favoritesRef = userFavoritesPath() else {
            throw FirebaseError.invalidReference
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            favoritesRef.child(id).removeValue { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func getFavorite(for city: String) -> FavoriteCity? {
        return favoriteCities.first { $0.name.lowercased() == city.lowercased() }
    }
    
    func isCityFavorite(_ city: String) -> Bool {
        return getFavorite(for: city) != nil
    }
    
    deinit {
        stopListening()
    }
}

enum FirebaseError: Error {
    case unauthenticated
    case invalidReference
    case operationFailed
}
