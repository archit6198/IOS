import UIKit

class WeatherDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var weatherDetailsLabel: UILabel!
    @IBOutlet weak var forecastTableView: UITableView!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var visibilityLabel: UILabel!
    
    var cityName: String?
       var forecastData: [(date: String, temperature: Double)] = []

       override func viewDidLoad() {
           super.viewDidLoad()
           
           navigationItem.title = "City Weather"
           cityNameLabel.text = cityName
           
           forecastTableView.delegate = self
           forecastTableView.dataSource = self
           
           if let city = cityName {
               fetchWeather(for: city)
           }
       }

       private func fetchWeather(for city: String) {
           let cityEncoded = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
           let apiKey = "50a3f267103dfaca676f86dce385949e"
           
           // Weather and forecast URL
           let weatherUrlString = "https://api.openweathermap.org/data/2.5/weather?q=\(cityEncoded)&units=metric&appid=\(apiKey)"
           let forecastUrlString = "https://api.openweathermap.org/data/2.5/forecast?q=\(cityEncoded)&units=metric&appid=\(apiKey)"
           
           fetchData(urlString: weatherUrlString) { data in
               guard let weatherData = data else { return }
               self.processWeatherData(weatherData)
           }

           fetchData(urlString: forecastUrlString) { data in
               guard let forecastData = data else { return }
               self.processForecastData(forecastData)
           }
       }

       private func fetchData(urlString: String, completion: @escaping (Data?) -> Void) {
           guard let url = URL(string: urlString) else { return }
           
           let task = URLSession.shared.dataTask(with: url) { data, response, error in
               if let error = error {
                   DispatchQueue.main.async {
                       self.showAlert(title: "Error", message: error.localizedDescription)
                   }
                   return
               }
               completion(data)
           }
           task.resume()
       }

       private func processWeatherData(_ data: Data) {
           do {
               if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let main = json["main"] as? [String: Any],
                  let temperature = main["temp"] as? Double,
                  let humidity = main["humidity"] as? Double,
                  let weatherArray = json["weather"] as? [[String: Any]],
                  let weatherDescription = weatherArray.first?["description"] as? String,
                  let visibility = json["visibility"] as? Double {

                   DispatchQueue.main.async {
                       self.weatherDetailsLabel.text = "Temperature: \(temperature)°C\nDescription: \(weatherDescription)"
                       
                       // Show humidity and visibility in separate labels
                       self.humidityLabel.text = "Humidity: \(humidity)%"
                       self.visibilityLabel.text = "Visibility: \(visibility / 1000) km"  // Convert visibility from meters to kilometers
                   }
               }
           } catch {
               DispatchQueue.main.async {
                   self.showAlert(title: "Error", message: "Failed to parse weather data.")
               }
           }
       }

       private func processForecastData(_ data: Data) {
           do {
               if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let list = json["list"] as? [[String: Any]] {
                   var forecastArray: [(String, Double)] = []
                   
                   for item in list.prefix(5) {  // Show forecast for the next 5 periods
                       if let main = item["main"] as? [String: Any],
                          let temperature = main["temp"] as? Double,
                          let date = item["dt_txt"] as? String {
                           forecastArray.append((date: date, temperature: temperature))
                       }
                   }
                   
                   DispatchQueue.main.async {
                       self.forecastData = forecastArray
                       self.forecastTableView.reloadData()
                   }
               }
           } catch {
               DispatchQueue.main.async {
                   self.showAlert(title: "Error", message: "Failed to parse forecast data.")
               }
           }
       }

       // UITableView Data Source and Delegate methods
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return forecastData.count
       }

       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           let cell = tableView.dequeueReusableCell(withIdentifier: "ForecastCell", for: indexPath)
           
           let forecast = forecastData[indexPath.row]
           cell.textLabel?.text = forecast.date
           cell.detailTextLabel?.text = "\(forecast.temperature)°C"
           
           return cell
       }

       // Show alert messages
       private func showAlert(title: String, message: String) {
           let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
           present(alert, animated: true, completion: nil)
       }
   }
