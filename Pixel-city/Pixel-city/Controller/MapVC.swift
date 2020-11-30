//
//  MapVC.swift
//  Pixel-city
//
//  Created by Jacob Duell on 11/22/20.
//

import UIKit
import CoreLocation
import MapKit

class MapVC: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    let regionRadius: Double = 1000
    //let authorizationStatus = CLLocationManager.authorizationStatus()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManagerDidChangeAuthorization(locationManager)
    }
    @IBAction func centerMapButtonWasPressed(_ sender: Any) {
        if (locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse) {
            centerMapOnUserLocation()
        }
    }
    

}

extension MapVC: MKMapViewDelegate {
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

extension MapVC: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            switch manager.authorizationStatus {
            case .authorizedAlways , .authorizedWhenInUse:
                centerMapOnUserLocation()
                break
            case .denied, .restricted:
                break
            case .notDetermined:
                locationManager.requestAlwaysAuthorization()
                break
            default:
                break
            }
        }
    }
}

