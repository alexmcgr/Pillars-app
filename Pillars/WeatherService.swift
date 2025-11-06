//
//  WeatherService.swift
//  Pillars
//
//  Created by Alex McGregor on 11/6/25.
//

import Foundation
import CoreLocation

class WeatherService {
    static let shared = WeatherService()
    
    // Seattle, WA coordinates (98109)
    private let latitude = 47.6370
    private let longitude = -122.3493
    
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "weatherCache"
    
    private struct CachedWeather: Codable {
        let data: WeatherData
        let timestamp: Date
    }
    
    func fetchWeather() async throws -> WeatherData {
        // Check cache first
        if let cached = getCachedWeather() {
            return cached.data
        }
        
        // Fetch fresh data
        let baseURL = "https://api.open-meteo.com/v1/forecast"
        let params = "latitude=\(latitude)&longitude=\(longitude)&" +
                     "daily=temperature_2m_max,temperature_2m_min," +
                     "precipitation_probability_max,weather_code&" +
                     "temperature_unit=fahrenheit&timezone=America/Los_Angeles&forecast_days=1"
        let urlString = "\(baseURL)?\(params)"

        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WeatherAPIResponse.self, from: data)

        guard let daily = response.daily,
              let maxTemp = daily.temperature_2m_max.first,
              let minTemp = daily.temperature_2m_min.first,
              let precipChance = daily.precipitation_probability_max.first,
              let weatherCode = daily.weather_code.first else {
            throw WeatherError.missingData
        }

        let weatherData = WeatherData(
            highTemp: Int(maxTemp.rounded()),
            lowTemp: Int(minTemp.rounded()),
            precipitationChance: precipChance,
            weatherCode: weatherCode
        )
        
        // Cache the result
        cacheWeather(weatherData)
        
        return weatherData
    }
    
    private func getCachedWeather() -> CachedWeather? {
        guard let data = userDefaults.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode(CachedWeather.self, from: data) else {
            return nil
        }
        
        // Check if cache is still valid (within the same hour)
        let calendar = Calendar.current
        let now = Date()
        let cacheHour = calendar.component(.hour, from: cached.timestamp)
        let currentHour = calendar.component(.hour, from: now)
        let cacheDay = calendar.component(.day, from: cached.timestamp)
        let currentDay = calendar.component(.day, from: now)
        
        // Cache is valid if it's from the same hour and same day
        if cacheDay == currentDay && cacheHour == currentHour {
            return cached
        }
        
        return nil
    }
    
    private func cacheWeather(_ weather: WeatherData) {
        let cached = CachedWeather(data: weather, timestamp: Date())
        if let encoded = try? JSONEncoder().encode(cached) {
            userDefaults.set(encoded, forKey: cacheKey)
        }
    }
}

enum WeatherError: Error {
    case invalidURL
    case missingData
}

struct WeatherAPIResponse: Codable {
    let daily: DailyWeather?
}

struct DailyWeather: Codable {
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
    let precipitation_probability_max: [Int]
    let weather_code: [Int]
}

struct WeatherData: Codable {
    let highTemp: Int
    let lowTemp: Int
    let precipitationChance: Int
    let weatherCode: Int

    func weatherIcon() -> String {
        // WMO Weather interpretation codes
        // https://open-meteo.com/en/docs
        switch weatherCode {
        case 0: // Clear sky
            return "sun.max.fill"
        case 1, 2, 3: // Mainly clear, partly cloudy, overcast
            return weatherCode == 1 ? "cloud.sun.fill" : "cloud.fill"
        case 45, 48: // Fog
            return "cloud.fog.fill"
        case 51, 53, 55: // Drizzle
            return "cloud.drizzle.fill"
        case 61, 63, 65: // Rain
            return "cloud.rain.fill"
        case 71, 73, 75: // Snow
            return "cloud.snow.fill"
        case 77: // Snow grains
            return "cloud.snow.fill"
        case 80, 81, 82: // Rain showers
            return "cloud.rain.fill"
        case 85, 86: // Snow showers
            return "cloud.snow.fill"
        case 95: // Thunderstorm
            return "cloud.bolt.rain.fill"
        case 96, 99: // Thunderstorm with hail
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }
}
