//
//  MapVC.swift
//  Pixel-city
//
//  Created by Jacob Duell on 11/22/20.
//

import UIKit
import CoreLocation
import MapKit
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullUpViewHeight: NSLayoutConstraint!
    @IBOutlet weak var centerLocationBtn: UIButton!
    
    
    var locationManager = CLLocationManager()
    let regionRadius: Double = 1000
    
    var screenSize = UIScreen.main.bounds
    
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManagerDidChangeAuthorization(locationManager)
        addDoubleTap()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        pullUpView.addSubview(collectionView!)
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
    func animateViewUp() {
        pullUpViewHeight.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func animateViewDown() {
        cancelAllSessions()
        pullUpViewHeight.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
        spinner?.style = .large
        spinner?.color = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLbl() {
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (screenSize.width / 2) - 120, y: 175, width: 240, height: 40)
        progressLbl?.font = UIFont(name: "Avenir Next", size: 18)
        progressLbl?.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        progressLbl?.textAlignment = .center
        collectionView?.addSubview(progressLbl!)
    }
    
    func removeProgressLbl() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }
    
    @IBAction func centerMapButtonWasPressed(_ sender: Any) {
        if (locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse) {
            centerMapOnUserLocation()
        }
    }
    

}

extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        removePin()
        removeSpinner()
        removeProgressLbl()
        cancelAllSessions()
        
        imageUrlArray = []
        imageArray = []
        
        collectionView?.reloadData()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLbl()
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegion.init(center: touchCoordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
       
        retrieveUrls(forAnnotation: annotation) { (finished) in
            if finished == true {
                self.retrieveImages { (finished) in
                    if finished {
                        // hide spinner
                        self.removeSpinner()
                        // hide label
                        self.removeProgressLbl()
                        // reload collectionView
                        self.collectionView?.reloadData()
                    }
                }
            }
        }
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, handler: @escaping (_ status: Bool) -> ()) {
        AF.request(flickrUrl(forApiKey: apiKey, withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                guard let JSON = value as? Dictionary<String, AnyObject> else { return }
                
                let photosDict = JSON["photos"] as! Dictionary<String, AnyObject>
                let photosDictArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]
                
                for photo in photosDictArray {
                    let postUrl = "https://live.staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_c_d.jpg"
                    self.imageUrlArray.append(postUrl)
                }
                handler(true)
                print("JSON value success")
                break
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    func retrieveImages(handler: @escaping (_ status: Bool) -> ()) {
        for url in imageUrlArray {
            AF.request(url).responseImage { (response) in
                switch response.result {
                case .success(let value):
                    guard let image = value as UIImage? else { return }
                    self.imageArray.append(image)
                    self.progressLbl?.text = "\(self.imageArray.count)/40 Images Downloaded..."
                    
                    if self.imageArray.count == self.imageUrlArray.count {
                        handler(true)
                    }
                case .failure(let error):
                    print(error)
                    break
                }
            }
        }
    }
    
    func cancelAllSessions() {
        AF.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
        }
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

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        return cell
    }
}

