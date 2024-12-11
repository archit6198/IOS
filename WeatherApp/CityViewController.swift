import UIKit
import CoreData

class CitySearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

 
    @IBOutlet weak var citySearchTextField: UITextField!
    
    @IBOutlet weak var cityTableView: UITableView!
    
    
    var cities: [NSManagedObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Search Cities"
        
        cityTableView.delegate = self
        cityTableView.dataSource = self
        
        cityTableView.layer.borderColor = UIColor.gray.cgColor
        cityTableView.layer.borderWidth = 1.0
        cityTableView.layer.cornerRadius = 8.0
        
        fetchSavedCities()
        
    }
    
    
    @IBAction func addCityTapped(_ sender: Any) {
        guard let city = citySearchTextField.text, !city.isEmpty else {
                   showAlert(title: "Error", message: "Please enter a city name.")
                   return
               }
               saveCity(city)
    }
    
    // Save city name to Core Data
    private func saveCity(_ city: String) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.persistentContainer.viewContext
            
            let entity = NSEntityDescription.entity(forEntityName: "WeatherEntity", in: managedContext)!
            let newCity = NSManagedObject(entity: entity, insertInto: managedContext)
            
            newCity.setValue(city, forKey: "city")
            
            do {
                try managedContext.save()
                cities.append(newCity)  // Append new city to the list
                cityTableView.reloadData()  // Reload table view to show the new city
            } catch let error as NSError {
                showAlert(title: "Error", message: "Could not save city. \(error), \(error.userInfo)")
            }
        }

    // Fetch saved cities from Core Data
    private func fetchSavedCities() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "WeatherEntity")
        
        do {
            cities = try managedContext.fetch(fetchRequest)
            cityTableView.reloadData()  // Reload the table view with saved cities
        } catch let error as NSError {
            showAlert(title: "Error", message: "Could not fetch cities. \(error), \(error.userInfo)")
        }
    }
    
    // Delete the cities

    private func deleteCityFromCoreData(city: NSManagedObject) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        
        managedContext.delete(city)
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            showAlert(title: "Error", message: "Could not delete city. \(error), \(error.userInfo)")
        }
    }
    
        // TableView data source methods
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return cities.count  // Return the number of cities in the list
        }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let city = cities[indexPath.row]
        let cityName = city.value(forKey: "city") as? String ?? "Unknown"
        
        print("Selected city: \(cityName)")  // Debugging

        if let weatherVC = storyboard?.instantiateViewController(withIdentifier: "WeatherDetailsViewController") as? WeatherDetailsViewController {
            weatherVC.cityName = cityName
            print("Navigating to WeatherDetailsViewController with city: \(cityName)")
            navigationController?.pushViewController(weatherVC, animated: true)
        } else {
            print("Failed to instantiate WeatherDetailsViewController.")
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let city = cities[indexPath.row]
            deleteCityFromCoreData(city: city)
            cities.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }



        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)
            let city = cities[indexPath.row]
            cell.textLabel?.text = city.value(forKey: "city") as? String
            return cell
        }

        // Show alert messages
        private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
