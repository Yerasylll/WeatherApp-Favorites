//
//  FavoritesView.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import SwiftUI
import FirebaseDatabase

struct FavoritesView: View {
    @StateObject private var repository = FirebaseRepository.shared 
        @StateObject private var authService = AuthenticationService.shared
    
    @State private var showingAddFavorite = false
    @State private var showingAuthSheet = false
    
    var body: some View {
        NavigationView {
            Group {
                if !authService.isAuthenticated {
                    VStack(spacing: 25) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Sign In Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("You need to sign in to save favorite cities")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(spacing: 15) {
                            // Anonymous Auth Button
                            Button {
                                Task {
                                    await signInAnonymously()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "person.fill.questionmark")
                                    Text("Sign In Anonymously")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(authService.isLoading)
                            
                            // OR divider
                            HStack {
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("OR")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            .padding(.horizontal)
                            
                            // Email/Password Button
                            Button {
                                showingAuthSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                    Text("Sign In with Email")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 40)
                        
                        if authService.isLoading {
                            ProgressView()
                                .padding()
                        }
                        
                        if let error = authService.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                    .padding()
                } else {
                    // Authenticated view
                    List {
                        ForEach(repository.favoriteCities) { favorite in
                            NavigationLink(destination: FavoriteDetailView(favorite: favorite)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(favorite.name)
                                        .font(.headline)
                                    
                                    if let note = favorite.note, !note.isEmpty {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    
                                    Text("Added \(formatDate(favorite.createdAt))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteFavorite)
                    }
                    .overlay {
                        if repository.favoriteCities.isEmpty {
                            VStack {
                                Image(systemName: "star")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("No favorites yet")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                Text("Tap + to add a city")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                if authService.isAuthenticated {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button(action: {
                            print("Add button pressed")
                            showingAddFavorite = true
                        }) {
                            Image(systemName: "plus")
                        }
                        
                        Menu {
                            Button("Sign Out", role: .destructive) {
                                do {
                                    try authService.signOut()
                                } catch {
                                    print("Sign out error: \(error)")
                                }
                            }
                            
                            // Debug button
                            Button("Debug Info") {
                                print("=== DEBUG INFO ===")
                                print("User authenticated: \(authService.isAuthenticated)")
                                print("User ID: \(authService.getCurrentUserId() ?? "nil")")
                                print("Favorites count: \(repository.favoriteCities.count)")
                                print("Favorites: \(repository.favoriteCities.map { $0.name })")
                                print("=== END DEBUG ===")
                            }
                        } label: {
                            Image(systemName: "person.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddFavorite) {
                AddFavoriteView(isPresented: $showingAddFavorite)
                    .onDisappear {
                        print("AddFavoriteView dismissed")
                        print("Current favorites count: \(repository.favoriteCities.count)")
                    }
            }
            .sheet(isPresented: $showingAuthSheet) {
                EmailAuthView(isPresented: $showingAuthSheet)
            }
            .onAppear {
                print("FavoritesView appeared")
                if authService.isAuthenticated {
                    print("User is authenticated, starting listener")
                    repository.startListening()
                } else {
                    print("User not authenticated")
                }
            }
            .onDisappear {
                print("FavoritesView disappeared")
                repository.stopListening()
            }
            .onChange(of: authService.isAuthenticated) { oldValue, newValue in
                print("Auth state changed: \(oldValue) -> \(newValue)")
                if newValue {
                    print("Starting listener due to auth change")
                    repository.startListening()
                } else {
                    print("Stopping listener due to auth change")
                    repository.stopListening()
                }
            }
        }
    }
    
    private func signInAnonymously() async {
        do {
            try await authService.signInAnonymously()
            repository.startListening()
        } catch {
            print("Anonymous sign in failed: \(error)")
        }
    }
    
    private func deleteFavorite(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let favorite = repository.favoriteCities[index]
                do {
                    try await repository.deleteFavorite(id: favorite.id)
                } catch {
                    print("Failed to delete favorite: \(error)")
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // Add this AFTER the closing brace of FavoritesView struct
    // but BEFORE the closing brace of the file

    // MARK: - FavoriteDetailView
    struct FavoriteDetailView: View {
        let favorite: FavoriteCity
        @StateObject private var weatherViewModel = WeatherViewModel()
        @State private var showingEditNote = false
        @State private var editedNote: String
        
        init(favorite: FavoriteCity) {
            self.favorite = favorite
            self._editedNote = State(initialValue: favorite.note ?? "")
        }
        
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // City Info
                    VStack {
                        Text(favorite.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let note = favorite.note, !note.isEmpty {
                            Text(note)
                                .font(.body)
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    
                    // Weather for this city
                    Group {
                        if let weather = weatherViewModel.weather {
                            CurrentWeatherView(weather: weather, viewModel: weatherViewModel)
                        } else if weatherViewModel.isLoading {
                            ProgressView()
                        }
                    }
                    .onAppear {
                        weatherViewModel.city = favorite.name
                        Task {
                            await weatherViewModel.fetchWeather()
                        }
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Details")
                            .font(.headline)
                        
                        DetailRow(title: "Coordinates",
                                 value: "\(String(format: "%.4f", favorite.latitude)), \(String(format: "%.4f", favorite.longitude))")
                        
                        DetailRow(title: "Added by", value: favorite.createdBy)
                        
                        DetailRow(title: "Added on", value: formatDate(favorite.createdAt))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle(favorite.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit Note") {
                        showingEditNote = true
                    }
                }
            }
            .sheet(isPresented: $showingEditNote) {
                EditNoteView(favorite: favorite, note: $editedNote, isPresented: $showingEditNote)
            }
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

    // MARK: - DetailRow Helper View
    struct DetailRow: View {
        let title: String
        let value: String
        
        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(.gray)
                Spacer()
                Text(value)
                    .fontWeight(.medium)
            }
        }
    }
}
