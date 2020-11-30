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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
    }
    @IBAction func centerMapButtonWasPressed(_ sender: Any) {
    }
    

}

extension MapVC: MKMapViewDelegate {
    
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationServices() {
        
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let accuracyAuthorization = manager.accuracyAuthorization
    }
}
