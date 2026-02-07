//
//  WeatherData.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import Foundation

struct WeatherResponse: Codable {
    let current: CurrentWeather
    let daily: DailyForecast?
    let hourly: HourlyForecast?
}

struct CurrentWeather: Codable {
    let temperature: Double
    let weatherCode: Int
    let humidity: Int
    let windSpeed: Double
    let time: String
    
    private enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
        case humidity = "relative_humidity_2m"
        case windSpeed = "wind_speed_10m"
        case time
    }
}

struct DailyForecast: Codable {
    let time: [String]
    let temperatureMax: [Double]
    let temperatureMin: [Double]
    let weatherCode: [Int]
    
    private enum CodingKeys: String, CodingKey {
        case time
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case weatherCode = "weather_code"
    }
}

struct HourlyForecast: Codable {
    let time: [String]
    let temperature: [Double]
    let weatherCode: [Int]
    
    private enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
    }
}
