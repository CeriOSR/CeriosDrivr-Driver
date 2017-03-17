//
//  ViewController.swift
//  CeriosDriver-Driver
//
//  Created by Rey Cerio on 2017-03-15.
//  Copyright © 2017 CeriOS. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import CoreLocation
import FBSDKLoginKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var trackerId = String()
    var locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D!
    var userLocationActive = false
    var values = [String: AnyObject]()
    let uid = FIRAuth.auth()?.currentUser?.uid
    let location = CLLocationManager().location?.coordinate
    
    
    let mapView: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    lazy var pingLocButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Ping Location", for: .normal)
        button.addTarget(self, action: #selector(handlePingLocation), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLocationManager()
        mapView.delegate = self
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        guard let lat = location?.latitude, let long = location?.longitude else {return}
        userLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
        setupView()
        
        //hide ping location button, check database for a running ping, show button with appropriate title (ONLY FOR UBER BECAUSE YOU DONT WANT MULTIPLE ENTRY AND ALSO YOU CANT TO DELETE WHEN CANCEL CALL)
    }
    
    func setupView() {
        view.addSubview(mapView)
        view.addSubview(pingLocButton)
        
        view.addConstraintsWithVisualFormat(format: "H:|-10-[v0]-10-|", views: mapView)
        view.addConstraintsWithVisualFormat(format: "H:|-130-[v0(100)]", views: pingLocButton)
        view.addConstraintsWithVisualFormat(format: "V:|-100-[v0(344)]-10-[v1(40)]", views: mapView, pingLocButton)
    }
    
    func createAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            //self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func handlePingLocation() {
        guard let userId = FIRAuth.auth()?.currentUser?.uid else {return}
        if userLocationActive == true {
            userLocationActive = false
            self.pingLocButton.setTitle("Ping Location", for: .normal)
            handleRemoveLocEntry()
        } else  {
            if trackerId == "None" {
                createAlert(title: "Not Authorized By Tracker", message: "Please ask dispatcher to add user.")
            } else {
                pingLocButton.setTitle("Stop Ping", for: .normal)
                userLocationActive = true
                handlePingAndSaveToDatabase(uid: userId)
                handleSaveWithUniqueId()
                handleDriverOnline()
            }
            
            
        }
    }
    
    func handleRemoveLocEntry() {
        guard let userId = uid else {return}
        let removeRef = FIRDatabase.database().reference().child("CER_user_location").child(trackerId).child(userId)
        removeRef.removeValue(completionBlock: { (error, reference) in
            if error != nil {
                self.userLocationActive = false
                self.pingLocButton.setTitle("Stop Ping", for: .normal)
                self.createAlert(title: "Cancel Ping Failed", message: "Please try again.")
            }
            
            let removeOnlineRef = FIRDatabase.database().reference().child("CER_driver_online").child("\(self.trackerId)").child(userId)
            removeOnlineRef.removeValue()
            
        })
    }
    
    func handleDriverOnline() {  //checks if user is online
        
        guard let userId = FIRAuth.auth()?.currentUser?.uid else {return}
        let date = String(describing: Date())
        
        values = ["uid": userId as AnyObject, "date": date as AnyObject, "user_online": "Yes" as AnyObject]
        
        let databaseRef = FIRDatabase.database().reference().child("CER_driver_online").child(trackerId).child(userId)
        databaseRef.updateChildValues(values) { (error, reference) in
            
            if error != nil{
                print("Could not update Database!")
                return
            }
            print("Pinged Location!!!!!!!!!!!!!")
        }
        
    }
    
    func handlePingAndSaveToDatabase(uid: String) { //updates every time location changes
        
        guard let latitude = userLocation?.latitude else {return}
        let latString = String(describing: latitude)
        guard let longitude = userLocation?.longitude else {return}
        let longString = String(describing: longitude)
        let date = String(describing: Date())
        
        values = ["uid": uid as AnyObject, "date": date as AnyObject, "latitude": latString as AnyObject, "longitude": longString as AnyObject]
        
        let databaseRef = FIRDatabase.database().reference().child("CER_user_location").child(trackerId).child(uid)
        databaseRef.updateChildValues(values) { (error, reference) in
            
            if error != nil{
                self.pingLocButton.setTitle("Ping Location", for: .normal)
                self.createAlert(title: "Pinging Failed!", message: "Please try again.")
            }
            print("Pinged Location!!!!!!!!!!!!!")
        }
    }
    
    func handleSaveWithUniqueId(){ //save to database for admin records
        
        guard let userId = uid else {return}
        guard let latitude = userLocation?.latitude else {return}
        let latString = String(describing: latitude)
        guard let longitude = userLocation?.longitude else {return}
        let longString = String(describing: longitude)
        let date = String(describing: Date())
        let id = NSUUID().uuidString
        
        values = ["uid": userId as AnyObject, "date": date as AnyObject, "latitude": latString as AnyObject, "longitude": longString as AnyObject]
        
        let databaseRef = FIRDatabase.database().reference().child("CER_saved_user_location").child(trackerId).child(userId).child(id)
        databaseRef.updateChildValues(values) { (error, reference) in
            
            if error != nil{
                self.pingLocButton.setTitle("Ping Location", for: .normal)
                print(error ?? "unknown error")
            }
            print("Saved To Database")
        }
    }
    
    func handleLogout() {
        do {
            try FIRAuth.auth()?.signOut()
        } catch let err {
            print(err)
            return
        }
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        locationManager.stopUpdatingLocation()
        let loginController = LoginController()
        present(loginController, animated: true, completion: nil)
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = manager.location?.coordinate {
            
            let userLocation2 = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let region = MKCoordinateRegion(center: userLocation2, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            
            self.mapView.setRegion(region, animated: true)
            self.mapView.removeAnnotations(self.mapView.annotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = userLocation2
            annotation.title = "Driver Location"
            
            self.mapView.addAnnotation(annotation)
            
            let point1 = MKMapPointForCoordinate(userLocation)
            let point2 = MKMapPointForCoordinate(userLocation2)
            let distance = MKMetersBetweenMapPoints(point1, point2)
            
            if userLocationActive == true && distance > 50{
                handlePingAndSaveToDatabase(uid: uid!)
                handleSaveWithUniqueId()
                userLocation = userLocation2
            }
        }
    }
}
