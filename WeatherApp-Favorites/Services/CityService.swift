//
//  CityService.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 07.02.2026.
//

import Foundation

class CityService {
    // Major cities database with their coordinates
    static let cities: [(name: String, lat: Double, lon: Double)] = [
        ("Astana", 51.1694, 71.4491),
        ("Almaty", 43.2389, 76.8897),
        ("Shymkent", 42.3417, 69.5901),
        ("Karaganda", 49.8333, 73.1652),
        ("Aktobe", 50.2833, 57.1667),
        ("Taraz", 42.9000, 71.3667),
        ("Pavlodar", 52.3000, 76.9500),
        ("Semey", 50.4112, 80.2273),
        ("Atyrau", 47.1167, 51.8833),
        ("London", 51.5074, -0.1278),
        ("New York", 40.7128, -74.0060),
        ("Paris", 48.8566, 2.3522),
        ("Tokyo", 35.6762, 139.6503),
        ("Dubai", 25.2048, 55.2708),
        ("Singapore", 1.3521, 103.8198),
        ("Sydney", -33.8688, 151.2093),
        ("Toronto", 43.6532, -79.3832),
        ("Berlin", 52.5200, 13.4050),
        ("Moscow", 55.7558, 37.6173),
        ("Rome", 41.9028, 12.4964),
        ("Madrid", 40.4168, -3.7038),
        ("Amsterdam", 52.3676, 4.9041),
        ("Vienna", 48.2082, 16.3738),
        ("Prague", 50.0755, 14.4378),
        ("Warsaw", 52.2297, 21.0122),
        ("Istanbul", 41.0082, 28.9784),
        ("Athens", 37.9838, 23.7275),
        ("Beijing", 39.9042, 116.4074),
        ("Shanghai", 31.2304, 121.4737),
        ("Seoul", 37.5665, 126.9780),
        ("Bangkok", 13.7563, 100.5018),
        ("Mumbai", 19.0760, 72.8777),
        ("Delhi", 28.7041, 77.1025),
        ("Jakarta", -6.2088, 106.8456),
        ("Manila", 14.5995, 120.9842),
        ("Los Angeles", 34.0522, -118.2437),
        ("Chicago", 41.8781, -87.6298),
        ("Miami", 25.7617, -80.1918),
        ("Vancouver", 49.2827, -123.1207),
        ("Mexico City", 19.4326, -99.1332),
        ("São Paulo", -23.5505, -46.6333),
        ("Buenos Aires", -34.6037, -58.3816),
        ("Lima", -12.0464, -77.0428),
        ("Cairo", 30.0444, 31.2357),
        ("Riyadh", 24.7136, 46.6753),
        ("Tel Aviv", 32.0853, 34.7818),
        ("Nairobi", -1.2921, 36.8219),
        ("Cape Town", -33.9249, 18.4241),
        ("Johannesburg", -26.2041, 28.0473),
        ("Casablanca", 33.5731, -7.5898),
        ("Doha", 25.2854, 51.5310)
    ]
    
    // Get suggestions based on input
    func getSuggestions(for input: String) -> [String] {
        let searchText = input.lowercased().trimmingCharacters(in: .whitespaces)
        
        if searchText.isEmpty {
            // Return top cities when empty
            return ["Astana", "Almaty", "London", "New York", "Tokyo", "Paris"]
        }
        
        // Filter cities that start with the search text
        let suggestions = CityService.cities
            .filter { $0.name.lowercased().hasPrefix(searchText) }
            .map { $0.name }
        
        // If no prefix matches, try contains
        if suggestions.isEmpty {
            return CityService.cities
                .filter { $0.name.lowercased().contains(searchText) }
                .map { $0.name }
        }
        
        return suggestions
    }
    
    // Get coordinates for a city
    func getCoordinates(for city: String) -> (lat: Double, lon: Double)? {
        return CityService.cities.first { $0.name.lowercased() == city.lowercased() }
            .map { ($0.lat, $0.lon) }
    }
    
    // Check if city exists in our database
    func isValidCity(_ city: String) -> Bool {
        return CityService.cities.contains { $0.name.lowercased() == city.lowercased() }
    }
}
