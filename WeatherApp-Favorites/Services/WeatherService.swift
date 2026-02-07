//
//  WeatherService.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import Foundation

class WeatherService {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private let session = URLSession.shared
    private let cityService = CityService()  
    
    func fetchWeather(for city: String, units: TemperatureUnit = .celsius) async throws -> WeatherResponse {
        // Use CityService for coordinates
        guard let coordinates = cityService.getCoordinates(for: city) else {
            throw WeatherError.cityNotFound
        }
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = [
            URLQueryItem(name: "latitude", value: "\(coordinates.lat)"),
            URLQueryItem(name: "longitude", value: "\(coordinates.lon)"),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        
        if units == .fahrenheit {
            urlComponents.queryItems?.append(URLQueryItem(name: "temperature_unit", value: "fahrenheit"))
        }
        
        guard let url = urlComponents.url else {
            throw WeatherError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(WeatherResponse.self, from: data)
    }
    
}

enum WeatherError: Error {
    case invalidURL
    case networkError
    case cityNotFound
}

enum TemperatureUnit: String, CaseIterable {
    case celsius = "°C"
    case fahrenheit = "°F"
}
