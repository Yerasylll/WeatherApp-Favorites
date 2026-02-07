//
//  WeatherView.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import SwiftUI

struct WeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.3), .white], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Search
                    HStack {
                        TextField("Enter city name", text: $viewModel.city)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button(action: {
                            Task { await viewModel.fetchWeather() }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding()
                    
                    // Error/Offline message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    if viewModel.isOffline {
                        Label("Showing cached data", systemImage: "wifi.slash")
                            .foregroundColor(.orange)
                            .padding()
                    }
                    
                    // Weather Card
                    if let weather = viewModel.weather {
                        ScrollView {
                            VStack(spacing: 20) {
                                // Current Weather
                                VStack(spacing: 10) {
                                    Text(viewModel.city)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                    
                                    Image(systemName: viewModel.getWeatherIcon(code: weather.current.weatherCode))
                                        .font(.system(size: 60))
                                        .foregroundColor(.blue)
                                    
                                    Text("\(Int(weather.current.temperature))\(viewModel.temperatureUnit.rawValue)")
                                        .font(.system(size: 50, weight: .bold))
                                    
                                    Text("Humidity: \(weather.current.humidity)%")
                                    Text("Wind: \(Int(weather.current.windSpeed)) km/h")
                                    Text("Updated: \(weather.current.time)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(20)
                                .shadow(radius: 5)
                                
                                // Forecast (3-day)
                                if let daily = weather.daily {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("3-Day Forecast")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        ForEach(0..<min(3, daily.time.count), id: \.self) { index in
                                            HStack {
                                                Text(formatDate(daily.time[index]))
                                                    .frame(width: 100, alignment: .leading)
                                                
                                                Image(systemName: viewModel.getWeatherIcon(code: daily.weatherCode[index]))
                                                    .frame(width: 30)
                                                
                                                Text("H: \(Int(daily.temperatureMax[index]))°")
                                                Text("L: \(Int(daily.temperatureMin[index]))°")
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(20)
                                    .shadow(radius: 5)
                                }
                            }
                            .padding()
                        }
                    } else if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(2)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Weather App")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(selectedUnit: $viewModel.temperatureUnit)
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }
}
