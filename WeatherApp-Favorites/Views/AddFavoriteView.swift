//
//  AddFavoriteView.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import SwiftUI

struct AddFavoriteView: View {
    @Binding var isPresented: Bool
    @StateObject private var repository = FirebaseRepository.shared 
    @StateObject private var weatherViewModel = WeatherViewModel()
    
    @State private var cityName = ""
    @State private var note = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("City Information")) {
                    TextField("City Name", text: $cityName)
                        .autocapitalization(.words)
                        .submitLabel(.done)
                    
                    TextField("Note (optional)", text: $note)
                        .submitLabel(.done)
                }
                
                if !cityName.isEmpty {
                    Section(header: Text("Preview")) {
                        if let weather = weatherViewModel.weather {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(cityName)
                                    .font(.headline)
                                
                                HStack {
                                    Image(systemName: weatherViewModel.getWeatherIcon(code: weather.current.weatherCode))
                                    Text("\(Int(weather.current.temperature))\(weatherViewModel.temperatureUnit.rawValue)")
                                }
                                
                                if !note.isEmpty {
                                    Text("Note: \(note)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        } else if weatherViewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    }
                    .onChange(of: cityName) { oldValue, newValue in
                        fetchWeatherPreview()
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Favorite")
            .navigationBarItems(
                leading: Button("Cancel") {
                    print("Cancel button pressed")
                    isPresented = false
                },
                trailing: Button("Save") {
                    print("Save button pressed")
                    saveFavorite()
                }
                    .disabled(cityName.isEmpty || isLoading)
            )
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    isPresented = false
                }
            } message: {
                Text("Favorite city added successfully!")
            }
        }
        .onAppear {
            print("AddFavoriteView appeared")
            fetchWeatherPreview()
        }
    }
    
    private func fetchWeatherPreview() {
        guard !cityName.isEmpty else { return }
        
        print("Fetching weather for: \(cityName)")
        Task {
            weatherViewModel.city = cityName
            await weatherViewModel.fetchWeather()
        }
    }
    
    private func saveFavorite() {
        print("Attempting to save favorite: \(cityName)")
        
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                // Get coordinates
                let weatherService = WeatherService()
                let coordinates = weatherService.getCoordinates(for: cityName)
                print("Coordinates: \(coordinates)")
                
                // Save to Firebase
                print("Calling repository.addFavorite...")
                try await repository.addFavorite(
                    city: cityName,
                    note: note.isEmpty ? nil : note,
                    coordinates: coordinates
                )
                
                print("Favorite saved successfully")
                
                // Small delay to ensure Firebase propagates
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Show success and dismiss
                await MainActor.run {
                    showSuccess = true
                    print("Success flag set to true")
                }
                
            } catch {
                print("Error saving favorite: \(error)")
                errorMessage = "Failed to save: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
