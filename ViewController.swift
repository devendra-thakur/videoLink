//
//  ViewController.swift
//  swift_definitive
//
//  Created by Adrián Rodríguez on 18/5/18.
//  Copyright © 2018 Adrián Rodríguez. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SITLocationDelegate {
    
    var sharedManager: SITCommunicationManager = SITCommunicationManager.shared()
    var sharedLocManager: SITLocationManager = SITLocationManager.sharedInstance()
    var buildings: NSArray = NSArray()
    var building: SITBuilding = SITBuilding()
    var buildingInfo: SITBuildingInfo = SITBuildingInfo()
    var locationAuthorizationHelper:LocationAuthorizationHelper = LocationAuthorizationHelper()

//    First button initializes vars, second gets building info and third starts positioning
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
//    This label serves as output for the user
    @IBOutlet weak var appConsole: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        Enable only the first button
        button1.isEnabled = true
        button2.isEnabled = false
        button3.isEnabled = false
        locationAuthorizationHelper.delegate = self
    }
    
//    Button 1 function (yellow)
    @IBAction func initializeButton(_ sender: UIButton) {
//        The managers must be created via shared(), otherwise it doesn't initialize correctly
            self.sharedManager = SITCommunicationManager.shared()
            self.sharedLocManager = SITLocationManager.sharedInstance()
        
//        Set the delegate so the update functions receive the messages
            self.sharedLocManager.delegate = self
        
        //See LocationAuthorizationHelper for an example of how to handle location authorization changes from the user
        self.locationAuthorizationHelper.requestLocationAuth()
        
//        Initialize all the vars we are going to use
            self.buildings = NSArray()
            self.building = SITBuilding()
            self.buildingInfo = SITBuildingInfo()
        
        self.logAppConsole(message: "Vars are initialized. You can now obtain the building information.", clearConsole: false)
        
//        Allow the second button to be clicked
            self.button1.isEnabled = false
            self.button2.isEnabled = true
    }
    
//    Button 2 function (green)
    @IBAction func downloadBuildingsButton(_ sender: UIButton) {
        
        sharedManager.fetchBuildings(options: nil, success: { (mapping: [AnyHashable : Any]?) -> Void in
//            Obtain the buildings and get the info of the first one
            self.buildings = mapping!["results"] as! NSArray
            
            if (self.buildings.count > 0) {
                self.logAppConsole(message: "The call to retrieve the buildings was successful. Now the information for the first building will be obtained.", clearConsole: false)
                
                // To obtain different buildings from your account, you should browse this array
                self.building = self.buildings[0] as! SITBuilding
                
                self.sharedManager.fetchBuildingInfo(self.building.identifier, withOptions: nil, success: { (mapping: [AnyHashable: Any]?) -> Void in
//                    Obtein the building info
                    self.buildingInfo = mapping!["results"] as! SITBuildingInfo
                    
                    self.logAppConsole(message: "The call to retrieve the building info was successful. You can now start your request for positioning updates.", clearConsole: false)
                    
//                    Allow the third button to be clicked
                    self.button2.isEnabled = false
                    self.button3.isEnabled = true
                    
                }, failure: { (error: Error?) in
                    self.logAppConsole(message: "The call to retrieve the building info was successful but no data was retrieved. Is there at least one building correctly configured in the Situm Dashboard? (https://dashboard.situm.es/)", clearConsole: false)
                })
            } else {
                self.logAppConsole(message: "The call to retrieve the buildings was successful but no buildings were retrieved. Is there at least one building correctly configured in the Situm Dashboard? (https://dashboard.situm.es/)", clearConsole: false)
            }
            
        }, failure: { (error: Error?) in
            self.logAppConsole(message: "The call to retrieve the buildings has failed. Do you have your APIKEY correctly set? Is there at least one building correctly configured in the Situm Dashboard? (https://dashboard.situm.es/)", clearConsole: false)
        })
    }

//    Button 3 function (blue)
    @IBAction func startRequestButton(_ sender: UIButton) {
        
//        Create the request to activate positioning
        let request: SITLocationRequest = SITLocationRequest.init(buildingId: self.building.identifier)
        
//        Send the created request
        sharedLocManager.requestLocationUpdates(request)
        
        self.logAppConsole(message: "*STARTING POSITIONING REQUEST*", clearConsole: true)
        
//        Disable the third button also
        self.button3.isEnabled = false
        
    }
    
//    Auxiliar function to print to user console
    func logAppConsole(message: String, clearConsole: Bool) {
        if let text = self.appConsole.text, !text.isEmpty && !clearConsole {
            self.appConsole.text! += "\n\n" + message
        } else {
            self.appConsole.text! = message
        }
    }
    
//    Delegate functions to receive notifications
    func locationManager(_ locationManager: SITLocationInterface, didUpdate location: SITLocation) {
        self.logAppConsole(message: "*POSITIONING REQUEST UPDATED*\nPosition was updated to:\n\n Latitude: \(location.position.coordinate().latitude)\n Longitude: \(location.position.coordinate().longitude).", clearConsole: true)
    }
    
    func locationManager(_ locationManager: SITLocationInterface, didFailWithError error: Error?) {
        self.logAppConsole(message: "*POSITIONING REQUEST UPDATED*\nThere was an error with the request: \(error?.localizedDescription ?? "")", clearConsole: true)
    }
    
    func locationManager(_ locationManager: SITLocationInterface, didUpdate state: SITLocationState) {
        self.logAppConsole(message: "*POSITIONING REQUEST UPDATED*\nState was updated to \(state.rawValue)", clearConsole: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

