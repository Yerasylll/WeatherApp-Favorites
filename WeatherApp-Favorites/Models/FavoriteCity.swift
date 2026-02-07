//
//  FavoriteCity.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import Foundation

struct FavoriteCity: Codable, Identifiable {
    let id: String
    let name: String
    let note: String?
    let createdAt: Date
    let createdBy: String
    let latitude: Double
    let longitude: Double
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "cityName": name,
            "note": note ?? "",
            "createdAt": createdAt.timeIntervalSince1970,
            "createdBy": createdBy,
            "latitude": latitude,
            "longitude": longitude
        ]
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         note: String? = nil,
         createdAt: Date = Date(),
         createdBy: String,
         latitude: Double,
         longitude: Double) {
        self.id = id
        self.name = name
        self.note = note
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init?(dictionary: [String: Any]) {
        print("🔍 Creating FavoriteCity from dictionary")
        print("🔍 Dictionary keys: \(dictionary.keys)")
        
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let createdBy = dictionary["createdBy"] as? String,
              let latitude = dictionary["latitude"] as? Double,
              let longitude = dictionary["longitude"] as? Double,
              let createdAt = dictionary["createdAt"] as? Double else {
            print("Failed to parse required fields")
            print("   id: \(String(describing: dictionary["id"]))")
            print("   name: \(String(describing: dictionary["name"]))")
            print("   createdBy: \(String(describing: dictionary["createdBy"]))")
            print("   latitude: \(String(describing: dictionary["latitude"]))")
            print("   longitude: \(String(describing: dictionary["longitude"]))")
            print("   createdAt: \(String(describing: dictionary["createdAt"]))")
            return nil
        }
        
        self.id = id
        self.name = name
        self.note = dictionary["note"] as? String
        self.createdAt = Date(timeIntervalSince1970: createdAt)
        self.createdBy = createdBy
        self.latitude = latitude
        self.longitude = longitude
        
        print("Successfully created FavoriteCity: \(name)")
    }
}
