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
    
    func fetchWeather(for city: String, units: TemperatureUnit = .celsius) async throws -> WeatherResponse {
        // Simplified geocoding - in real app use separate geocoding API
        let coordinates = getCoordinates(for: city)
        
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
    
    func getCoordinates(for city: String) -> (lat: Double, lon: Double) {
        // Simplified - map major cities
        let cities = [
            "Almaty": (43.2389, 76.8897),
            "Astana": (51.1694, 71.4491),
            "Shymkent": (42.3417, 69.5901),
            "Karaganda": (49.8333, 73.1652),
            "Aktobe": (50.2833, 57.1667),
            "Taraz": (42.9000, 71.3667),
            "Pavlodar": (52.3000, 76.9500),
            "Semey": (50.4112, 80.2273),
            "Atyrau": (47.1167, 51.8833),
            "London": (51.5074, -0.1278),
            // Major World Cities
            "New York": (40.7128, -74.0060),
            "Paris": (48.8566, 2.3522),
            "Tokyo": (35.6762, 139.6503),
            "Dubai": (25.2048, 55.2708),
            "Singapore": (1.3521, 103.8198),
            "Sydney": (-33.8688, 151.2093),
            "Toronto": (43.6532, -79.3832),
            "Berlin": (52.5200, 13.4050),
            "Moscow": (55.7558, 37.6173),
                        
            // European Cities
            "Rome": (41.9028, 12.4964),
            "Madrid": (40.4168, -3.7038),
            "Amsterdam": (52.3676, 4.9041),
            "Vienna": (48.2082, 16.3738),
            "Prague": (50.0755, 14.4378),
            "Warsaw": (52.2297, 21.0122),
            "Istanbul": (41.0082, 28.9784),
            "Athens": (37.9838, 23.7275),
            
            // Asian Cities
            "Beijing": (39.9042, 116.4074),
            "Shanghai": (31.2304, 121.4737),
            "Seoul": (37.5665, 126.9780),
            "Bangkok": (13.7563, 100.5018),
            "Mumbai": (19.0760, 72.8777),
            "Delhi": (28.7041, 77.1025),
            "Jakarta": (-6.2088, 106.8456),
            "Manila": (14.5995, 120.9842),
            
            // American Cities
            "Los Angeles": (34.0522, -118.2437),
            "Chicago": (41.8781, -87.6298),
            "Miami": (25.7617, -80.1918),
            "Vancouver": (49.2827, -123.1207),
            "Mexico City": (19.4326, -99.1332),
            "São Paulo": (-23.5505, -46.6333),
            "Buenos Aires": (-34.6037, -58.3816),
            "Lima": (-12.0464, -77.0428),
            // Middle East/Africa
            "Cairo": (30.0444, 31.2357),
            "Riyadh": (24.7136, 46.6753),
            "Tel Aviv": (32.0853, 34.7818),
            "Nairobi": (-1.2921, 36.8219),
            "Cape Town": (-33.9249, 18.4241),
            "Johannesburg": (-26.2041, 28.0473),
            "Casablanca": (33.5731, -7.5898),
            "Doha": (25.2854, 51.5310)
        ]
        return cities[city] ?? (51.1694, 71.4491) // Default to Astana
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
