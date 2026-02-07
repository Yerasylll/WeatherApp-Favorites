//
//  CurrentWeatherView.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import SwiftUI

struct CurrentWeatherView: View {
    let weather: WeatherResponse
    let viewModel: WeatherViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            // Current Weather Card
            VStack(spacing: 10) {
                Image(systemName: viewModel.getWeatherIcon(code: weather.current.weatherCode))
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("\(Int(weather.current.temperature))\(viewModel.temperatureUnit.rawValue)")
                    .font(.system(size: 40, weight: .bold))
                
                HStack(spacing: 20) {
                    VStack {
                        Image(systemName: "humidity")
                            .font(.title2)
                        Text("\(weather.current.humidity)%")
                            .font(.caption)
                    }
                    
                    VStack {
                        Image(systemName: "wind")
                            .font(.title2)
                        Text("\(Int(weather.current.windSpeed)) km/h")
                            .font(.caption)
                    }
                }
                .foregroundColor(.gray)
                
                Text("Updated: \(formatTime(weather.current.time))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(20)
            .shadow(radius: 5)
        }
        .padding(.horizontal)
    }
    
    private func formatTime(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        
        guard let date = formatter.date(from: timeString) else {
            return timeString
        }
        
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
