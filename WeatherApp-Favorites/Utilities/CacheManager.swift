//
//  CacheManager.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import Foundation

class CacheManager {
    static let shared = CacheManager()
    private let defaults = UserDefaults.standard
    private let cacheKey = "lastWeatherData"
    private let cacheTimeKey = "cacheTimestamp"
    
    func saveWeather(_ weather: WeatherResponse, for city: String) {
        let cache = CachedWeather(city: city, data: weather, timestamp: Date())
        if let encoded = try? JSONEncoder().encode(cache) {
            defaults.set(encoded, forKey: cacheKey)
            defaults.set(Date(), forKey: cacheTimeKey)
        }
    }
    
    func loadWeather() -> CachedWeather? {
        guard let data = defaults.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(CachedWeather.self, from: data) else {
            return nil
        }
        return cached
    }
    
    func isCacheValid() -> Bool {
        guard let timestamp = defaults.object(forKey: cacheTimeKey) as? Date else {
            return false
        }
        return Date().timeIntervalSince(timestamp) < 3600 // 1 hour cache validity
    }
}

struct CachedWeather: Codable {
    let city: String
    let data: WeatherResponse
    let timestamp: Date
}
