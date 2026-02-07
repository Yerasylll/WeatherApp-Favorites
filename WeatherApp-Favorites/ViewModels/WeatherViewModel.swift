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
    @Published var city = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOffline = false
    @Published var temperatureUnit: TemperatureUnit = .celsius {
        didSet {
            UserDefaults.standard.set(temperatureUnit.rawValue, forKey: "temperatureUnit")
            if !city.isEmpty {
                Task { await fetchWeather() }
            }
        }
    }
    
    private let service = WeatherService()
    private let cache = CacheManager.shared
    
    init() {
        if let savedUnit = UserDefaults.standard.string(forKey: "temperatureUnit"),
           let unit = TemperatureUnit(rawValue: savedUnit) {
            temperatureUnit = unit
        }
        loadCachedWeather()
    }
    
    func fetchWeather() async {
        guard !city.isEmpty else {
            errorMessage = "Please enter a city name"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
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
