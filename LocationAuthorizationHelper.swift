//
//  LocationAuthorizationHelper.swift
//  ios-swift-app-bridgingExample
//
//  Created by fsvilas on 22/10/2020.
//  Copyright © 2020 Adrián Rodríguez. All rights reserved.
//

import Foundation

class LocationAuthorizationHelper:NSObject, CLLocationManagerDelegate{
    var coreLocationManager:CLLocationManager = CLLocationManager()
    var delegate:UIViewController?
    // Request user permission strings
    let PermissionDeniedAlertTitle: String = "Location Authorization Needed"
    let PermissionDeniedAlertBody: String = "This app needs location authorization to work properly. Please go to settings and enable it.";

    let PermissionRestrictedAlertTitle: String = "Location Authorization Needed";
    let PermissionRestrictedAlertBody: String = "This app needs location authorization to work properly. You have restricted authorization so it wont work properly on your device";

    let UnknonwLocationAuthorizationAlertTitle: String = "Location Authorization Needed";
    let UnknonwLocationAuthorizationAlertBody: String = "There has been an unknown error when checking your location authorization. Please go to settings and enable it.";

    let PermissionReducedAccuracyAlertTitle: String = "Location Full Accuracy Needed";
    let PermissionReducedAccuracyAlertBody: String = "This app needs full accuracy location authorization to work properly. Please go to settings and enable it.";

    let UnknonwLocationAccuracyAuthorizationAlertTitle: String = "Location Full Accuracy Needed";
    let UnknonwLocationAccuracyAuthorizationAlertBody: String = "There has been an unknown error when checking your location accuracy authorization. Please go to settings and enable it.";

    let okButtonText: String = "Ok";

    override init() {
        super.init()
        self.coreLocationManager.delegate = self
    }
    
    func requestLocationAuth(){
        self.coreLocationManager.requestAlwaysAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.alertUserIfIncorrectCoreLocationAuthorization(manager)
    }
    
    func alertUserIfIncorrectCoreLocationAuthorization(_ manager:CLLocationManager){
        let properAuthStatus:Bool = self.alertUserIfIncorrectLocationAuthorizationStatus(manager)
        if (properAuthStatus){
            self.alertUserIfIncorrectLocationAccuracyAuthorizationStatus(manager);
        }
    }


    func alertUserIfIncorrectLocationAuthorizationStatus(_ manager:CLLocationManager ) ->Bool
    {
        var authStatus:CLAuthorizationStatus;
        if #available(iOS 14.0, *) {
            //If iOS 14
            authStatus = manager.authorizationStatus
        } else {
            //If iOS <14
            authStatus = CLLocationManager.authorizationStatus();
        };
        switch (authStatus) {
            case .denied:
                self.showAlert(title: PermissionDeniedAlertTitle, message: PermissionDeniedAlertBody)
                return false
            case .restricted:
                self.showAlert(title: PermissionRestrictedAlertTitle, message: PermissionRestrictedAlertBody)
                return false
            case .notDetermined:
                return true
            case .authorizedAlways:
                return true
            case .authorizedWhenInUse:
                return true
            default:
                self.showAlert(title: UnknonwLocationAuthorizationAlertTitle, message: UnknonwLocationAuthorizationAlertBody)
                return false
        }
    }

    func alertUserIfIncorrectLocationAccuracyAuthorizationStatus(_ manager:CLLocationManager ) ->Bool{
        if #available(iOS 14.0, *) {
            //Only in iOS 14
            switch (manager.accuracyAuthorization) {
            case .reducedAccuracy:
                self.showAlert(title: PermissionReducedAccuracyAlertTitle, message: PermissionReducedAccuracyAlertBody)
                    return false;
            case .fullAccuracy:
                    return true;
            default:
                self.showAlert(title: UnknonwLocationAccuracyAuthorizationAlertTitle, message: UnknonwLocationAccuracyAuthorizationAlertBody)
                    return true;
                }
        }
        return true;
    }

    func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message,         preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: okButtonText, style: .default, handler: { _ in
        }))

        delegate?.present(alert, animated: true, completion: nil)
    }
    
    
}
