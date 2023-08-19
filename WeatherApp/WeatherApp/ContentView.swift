//
//  ContentView.swift
//  WeatherApp
//
//  Created by Rana MHD on 02/02/1445 AH.
//

import SwiftUI

struct Condition: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct Main: Codable {
    let temp: Double
    let feels_like: Double
    let temp_min: Double
    let temp_max: Double
    let pressure: Double
    let humidity: Double
}

struct Wind: Codable {
    let speed: Double
}

struct Weather: Codable {
    let id: Int
    let name: String
    let main: Main
    let wind: Wind
    let weather: [Condition]
}

struct ContentView: View {
    let session : URLSession = .shared
    let apiId: String = "092befd91dc2aedc1bd270fb2a3e0aa3"
    @State var weather: Weather = .init(id: 1, name: "Riyadh", main: .init(temp: 0, feels_like: 0, temp_min: 0, temp_max: 0, pressure: 0, humidity: 0), wind: .init(speed: 0), weather: [])
    @State var city: String = ""
    @State var unit: String = "metric"
    @State var waitOutput: Bool = false
    @State var readyOutput: Bool = false
    @State var errorOutput: Bool = false
    @State var errorText: String = ""
    @AppStorage("cachedData") private var cachedData:String = ""
    
    func loadData(city: String, unit: String) {
        let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiId)&units=\(unit)")
        let request = URLRequest(url: url! )
        let task = session.dataTask(with: request)
        {
            (data, response, error) in
            
            waitOutput = false
            if let error = error {
                print("Error \(error)")
                errorText = "Failed to get data from server!"
                errorOutput = true
                return
            }
            
            if let data = data {
                cachedData = String(decoding: data, as: UTF8.self)
                let decoder = JSONDecoder()
                do{
                    let weather = try decoder.decode(Weather.self, from: data)
                    self.weather = weather
                    readyOutput = true
                }
                catch{
                    errorText = "Failed to parse data from server"
                    cachedData = ""
                    errorOutput = true
                }
            }
        }
        task.resume()
    }
    
    var body: some View {
        NavigationStack {
            VStack (alignment: .leading) {
                Form {
                    if(!waitOutput && !readyOutput && !errorOutput) {
                        Section("Get weather information") {
                            TextField("City", text: $city)
                            Picker(selection: $unit, label: Text("Unit")) {
                                Text("Metric").tag("metric")
                                Text("Imperial").tag("imperial")
                            }
                            .pickerStyle(.automatic)
                            Button {
                                errorOutput = false
                                waitOutput = true
                                loadData(city: city, unit: unit)
                            } label: {
                                Text("Get information")
                            }
                        }
                    }
                    
                    if(readyOutput) {
                        Section("Weather Information") {
                            Text("City: \(weather.name)")
                            
                            if unit == "metric" {
                                Text("Temperature: \(weather.main.temp, specifier: "%.0f") °C")
                            } else {
                                Text("Temperature: \(weather.main.temp, specifier: "%.0f") °F")
                            }
                            
                            Text("Humidity: \(weather.main.humidity, specifier: "%.0f") %")
                            Text("Wind Speed: \(weather.wind.speed, specifier: "%.2f") km/h")
                            if(weather.weather.count > 0) {
                                Text("Weather: \(weather.weather[0].description)")
                                AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(weather.weather[0].icon)@2x.png"))
                                    .frame(maxWidth: .infinity)
                            }
                            Button {
                                city = ""
                                cachedData = ""
                                readyOutput = false
                            } label: {
                                Text("Reset")
                            }
                        }
                    }
                    
                    if(waitOutput) {
                        Text("Please wait for response")
                            .foregroundColor(.orange)
                    }
                    
                    if(errorOutput) {
                        Text("Error: \(errorText)")
                            .foregroundColor(.red)
                        Button {
                            city = ""
                            readyOutput = false
                            errorOutput = false
                        } label: {
                            Text("OK")
                        }
                    }
                }
                
            }
            .navigationTitle("Weather")
            .onAppear()
            {
                if cachedData.count > 1 {
                    print("Loading Cached Data")
                    let data = Data(cachedData.utf8)
                    let decoder = JSONDecoder()
                    do{
                        let weather = try decoder.decode(Weather.self, from: data)
                        self.weather = weather
                        readyOutput = true
                    }
                    catch{
                        errorText = "Failed to parse data from cache"
                        errorOutput = true
                    }
                }
            }
            
        }
       
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
