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
    @FocusState private var isCityFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("City Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("City Name", text: $cityName)
                            .autocapitalization(.words)
                            .submitLabel(.done)
                            .focused($isCityFieldFocused)
                            .onChange(of: cityName) { oldValue, newValue in
                                // Show suggestions as user types
                                weatherViewModel.updateSuggestions(for: newValue)
                                // Fetch weather preview after a small delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    fetchWeatherPreview()
                                }
                            }
                            .onSubmit {
                                // Fetch weather when user presses return
                                fetchWeatherPreview()
                                weatherViewModel.isShowingSuggestions = false
                            }
                        
                        // Suggestions dropdown
                        if weatherViewModel.isShowingSuggestions && isCityFieldFocused {
                            VStack(spacing: 0) {
                                ForEach(weatherViewModel.suggestions.prefix(5), id: \.self) { suggestion in
                                    Button(action: {
                                        cityName = suggestion
                                        weatherViewModel.isShowingSuggestions = false
                                        isCityFieldFocused = false
                                        fetchWeatherPreview()
                                    }) {
                                        HStack {
                                            Image(systemName: "location")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                            Text(suggestion)
                                                .font(.callout)
                                                .foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 4)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if suggestion != weatherViewModel.suggestions.prefix(5).last {
                                        Divider()
                                            .padding(.horizontal, 4)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    TextField("Note (optional)", text: $note)
                        .submitLabel(.done)
                }
                
                if !cityName.isEmpty {
                    Section(header: Text("Weather Preview")) {
                        if let weather = weatherViewModel.weather {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(cityName)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                        
                                        HStack(spacing: 12) {
                                            Image(systemName: weatherViewModel.getWeatherIcon(code: weather.current.weatherCode))
                                                .font(.title2)
                                                .foregroundColor(.blue)
                                            
                                            Text("\(Int(weather.current.temperature))\(weatherViewModel.temperatureUnit.rawValue)")
                                                .font(.title2)
                                                .fontWeight(.medium)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        HStack {
                                            Image(systemName: "humidity")
                                                .font(.caption)
                                            Text("\(weather.current.humidity)%")
                                                .font(.caption)
                                        }
                                        
                                        HStack {
                                            Image(systemName: "wind")
                                                .font(.caption)
                                            Text("\(Int(weather.current.windSpeed)) km/h")
                                                .font(.caption)
                                        }
                                    }
                                    .foregroundColor(.gray)
                                }
                                
                                if !note.isEmpty {
                                    Divider()
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Note")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(note)
                                            .font(.body)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        } else if weatherViewModel.isLoading {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    ProgressView()
                                    Text("Loading weather...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 20)
                        } else if weatherViewModel.errorMessage != nil {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("City not found or weather unavailable")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .multilineTextAlignment(.center)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 20)
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Add Favorite")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    print("Cancel button pressed")
                    isPresented = false
                }
                .foregroundColor(.red),
                
                trailing: Button("Save") {
                    print("Save button pressed")
                    saveFavorite()
                }
                .disabled(cityName.isEmpty || isLoading || weatherViewModel.weather == nil)
                .foregroundColor(cityName.isEmpty || isLoading || weatherViewModel.weather == nil ? .gray : .blue)
            )
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    isPresented = false
                }
            } message: {
                Text("\(cityName) has been added to your favorites!")
            }
            .onAppear {
                print("AddFavoriteView appeared")
                // Show default suggestions when view appears
                weatherViewModel.updateSuggestions(for: "")
                // Set focus to city field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isCityFieldFocused = true
                }
            }
            .onDisappear {
                print("AddFavoriteView disappeared")
                weatherViewModel.isShowingSuggestions = false
            }
            .onTapGesture {
                // Dismiss keyboard and suggestions when tapping outside
                isCityFieldFocused = false
                weatherViewModel.isShowingSuggestions = false
            }
        }
    }
    
    private func fetchWeatherPreview() {
        guard !cityName.isEmpty else { return }
        
        print("Fetching weather for: \(cityName)")
        
        // Check if it's a valid city first
        let cityService = CityService()
        guard cityService.isValidCity(cityName) else {
            print("Invalid city name: \(cityName)")
            weatherViewModel.weather = nil
            weatherViewModel.errorMessage = "City not found in database"
            return
        }
        
        Task {
            weatherViewModel.city = cityName
            await weatherViewModel.fetchWeather()
        }
    }
    
    private func saveFavorite() {
        print("Attempting to save favorite: \(cityName)")
        
        // Validate city exists in our database
        let cityService = CityService()
        guard cityService.isValidCity(cityName) else {
            errorMessage = "Please select a valid city from the suggestions"
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                // Get coordinates from CityService
                guard let coordinates = cityService.getCoordinates(for: cityName) else {
                    throw WeatherError.cityNotFound
                }
                
                print("Coordinates for \(cityName): \(coordinates)")
                
                // Check if city is already in favorites
                if repository.isCityFavorite(cityName) {
                    errorMessage = "\(cityName) is already in your favorites!"
                    isLoading = false
                    return
                }
                
                // Save to Firebase
                print("Calling repository.addFavorite...")
                try await repository.addFavorite(
                    city: cityName,
                    note: note.isEmpty ? nil : note,
                    coordinates: coordinates
                )
                
                print("Favorite saved successfully to Firebase")
                
                // Wait a moment for Firebase to sync
                try? await Task.sleep(nanoseconds: 300_000_000) 
                
                // Verify it was added locally
                print("Checking local favorites count: \(repository.favoriteCities.count)")
                print("Favorites: \(repository.favoriteCities.map { $0.name })")
                
                // Show success and dismiss
                await MainActor.run {
                    showSuccess = true
                    print("Success alert shown")
                }
                
            } catch WeatherError.cityNotFound {
                print("City not found error")
                errorMessage = "City not found. Please select a city from the suggestions."
            } catch FirebaseError.unauthenticated {
                print("User not authenticated")
                errorMessage = "You need to be signed in to save favorites."
            } catch {
                print("Error saving favorite: \(error)")
                errorMessage = "Failed to save: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
}
