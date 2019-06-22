//
//  ViewController.swift
//  Core Location Setup
//
//  Created by Di_Nerd on 6/21/19.
//  Copyright © 2019 Di_Nerd. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
    }
    
    @IBOutlet weak var mapkitView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    
    //Properties
    let locationManager = CLLocationManager()
    var previousLocation: CLLocation?

    
    func checkLocationServices(){
        if CLLocationManager.locationServicesEnabled(){
            setupLocationManager()
            checkLocationAuthorization()
        }else{
            
        }
    }
    
    
    func setupLocationManager(){
        locationManager.delegate = self
        mapkitView.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    
    func checkLocationAuthorization(){
        
        switch CLLocationManager.authorizationStatus(){
            
        case .authorizedWhenInUse:
            startTrackingUserLocation()
            //break
        case .denied:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .authorizedAlways:
            break
        }
    }
    
    
     func startTrackingUserLocation() {
        mapkitView.showsUserLocation = true
        //mapkitView.showsBuildings = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapkitView)
    }
    
    
    func centerViewOnUserLocation(){
        if let location = locationManager.location?.coordinate{
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 10000, longitudinalMeters: 10000)
            mapkitView.setRegion(region, animated: true)
        }
    }
    
    
    func getCenterLocation(for mapkitView:MKMapView) -> CLLocation{
        let latitude = mapkitView.centerCoordinate.latitude
        let longitude = mapkitView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}

extension MapVC: CLLocationManagerDelegate{
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
//        guard let location = locations.last else{return}
//        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
//        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: 500, longitudinalMeters: 500)
//        mapkitView.setRegion(region, animated: true)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
}

extension MapVC: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("region changed")
        let center = getCenterLocation(for: mapView)
        let geoCoder = CLGeocoder()
        guard let previousLocation = self.previousLocation else{return}
        guard center.distance(from: previousLocation) > 50 else {return}
        self.previousLocation = center
        
        geoCoder.reverseGeocodeLocation(center) { [weak self] (placemarks, error) in
            guard let self = self else {return}
            
            if let _ = error{
                return
            }
            
            guard let placemark = placemarks?.first else{
                return
            }
            
            let streetNum = placemark.subThoroughfare ?? "Error!"
            let streetName = placemark.thoroughfare ?? "error"
            
            DispatchQueue.main.async {
                
                self.addressLabel.text = "\(streetNum) \(streetName)"
            }
        }
    }
}
