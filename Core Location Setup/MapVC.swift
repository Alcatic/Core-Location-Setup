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
    
    @IBAction func goButton(_ sender: UIBarButtonItem) {
        getDirections()
    }
    
    //Properties
    let locationManager = CLLocationManager()
    var previousLocation: CLLocation?
    var directionsArray: [MKDirections] = []

    
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
    
    func getDirections(){
        guard let location = locationManager.location?.coordinate else{
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        
        directions.calculate { (response, error) in
            guard let response = response else {return}
            for route in response.routes{
                self.mapkitView.addOverlay(route.polyline)
                self.mapkitView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request{
        
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destinationCoordinate = getCenterLocation(for: mapkitView).coordinate
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        return request
    }
    
    func resetMapView(withNew directions: MKDirections){
        guard let maps = mapkitView else{return}
        maps.removeOverlays(maps.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map{ $0.cancel()}
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
        geoCoder.cancelGeocode()
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
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .red
        return renderer
    }
}
