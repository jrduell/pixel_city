//
//  MapVC.swift
//  Pixel-city
//
//  Created by Jacob Duell on 11/22/20.
//

import UIKit
import Alamofire
import AlamofireImage
import MapKit

class MapVC: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    }
    @IBAction func centerMapButtonWasPressed(_ sender: Any) {
    }
    

}

extension MapVC: MKMapViewDelegate {
    
}

