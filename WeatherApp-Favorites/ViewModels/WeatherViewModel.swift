//
//  WeatherViewModel.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherResponse?
    @Published var city = "Astana"  // Set default to Astana
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOffline = false
    @Published var temperatureUnit: TemperatureUnit = .celsius
    @Published var suggestions: [String] = [] 
    @Published var isShowingSuggestions = false  
    
    private let service = WeatherService()
    private let cache = CacheManager.shared
    private let cityService = CityService()  
    
    init() {
        if let savedUnit = UserDefaults.standard.string(forKey: "temperatureUnit"),
           let unit = TemperatureUnit(rawValue: savedUnit) {
            temperatureUnit = unit
        }
        loadCachedWeather()
        
        // Load weather for default city on init
        Task {
            await fetchWeather()
        }
    }
    
    func fetchWeather() async {
        guard !city.isEmpty else {
            errorMessage = "Please enter a city name"
            return
        }
        
        isLoading = true
        errorMessage = nil
        isShowingSuggestions = false  // Hide suggestions when fetching
        
        do {
            let weather = try await service.fetchWeather(for: city, units: temperatureUnit)
            self.weather = weather
            cache.saveWeather(weather, for: city)
            isOffline = false
        } catch {
            errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
            loadCachedWeather()
        }
        
        isLoading = false
    }
    
    // New function: Update suggestions as user types
    func updateSuggestions(for input: String) {
        if input.isEmpty {
            // Show popular cities when empty
            suggestions = ["Astana", "Almaty", "London", "New York", "Tokyo", "Paris"]
            isShowingSuggestions = true
        } else {
            suggestions = cityService.getSuggestions(for: input)
            isShowingSuggestions = !suggestions.isEmpty
        }
    }
    
    // New function: Select a suggestion
    func selectSuggestion(_ suggestion: String) {
        city = suggestion
        isShowingSuggestions = false
        Task {
            await fetchWeather()
        }
    }
    
    func loadCachedWeather() {
        if let cached = cache.loadWeather(), cache.isCacheValid() {
            weather = cached.data
            city = cached.city
            isOffline = true
        }
    }
    
    func getWeatherIcon(code: Int) -> String {
        switch code {
        case 0: return "sun.max"
        case 1, 2: return "cloud.sun"
        case 3: return "cloud"
        case 45, 48: return "cloud.fog"
        case 51...67, 80...82: return "cloud.rain"
        case 71...77: return "snow"
        case 95...99: return "cloud.bolt.rain"
        default: return "questionmark"
        }
    }
}
