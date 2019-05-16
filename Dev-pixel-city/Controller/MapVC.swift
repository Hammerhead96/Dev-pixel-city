//
//  ViewController.swift
//  Dev-pixel-city
//
//  Created by Mac User on 5/13/19.
//  Copyright © 2019 Hammerhead96. All rights reserved.
//
// API key  323ba3dfc5a8dad5c53109976a13a6ae
// Secret   ab45320da895a720

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    var screenSize = UIScreen.main.bounds
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pullUpView: UIView!
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    var imageURLArray = [String]()
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        pullUpView.addSubview(collectionView!)
    } // end view did load
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
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }   }
    @objc func animateViewDown() {
        cancelAllSessions()
        pullUpViewHeightConstraint.constant = 1
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }   }
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
//        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.style = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }   }
    func addProgressLbl() {
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (screenSize.width / 2) - 120, y: 175, width: 240, height: 40)
        progressLbl?.font = UIFont(name: "Avenir Next", size: 15)
        progressLbl?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLbl?.textAlignment = .center
        collectionView?.addSubview(progressLbl!)
    }
    func removeProgressLbl() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }
    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }   }
    
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
        //let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius * 2.0, regionRadius * 2.0)
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    @objc func dropPin(sender: UIGestureRecognizer) {
        removePin()
        removeSpinner()
        removeProgressLbl()
        cancelAllSessions()
        addSwipe()
        addSpinner()
        addProgressLbl()
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        animateViewUp()
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        retrieveURLs(forAnnotation: annotation) { (finished) in
            if finished {
                self.retrieveImages(handler: { (finished) in
                    if finished {
                        self.removeSpinner()
                        self.removeProgressLbl()
                        // reload collection
                    }
                })
            }
        }
        let coordinateRegion = MKCoordinateRegion(center: touchCoordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }   }
    func retrieveURLs(forAnnotation annotation: DroppablePin, handler: @escaping (_ status: Bool) -> ()) {
        imageURLArray = []
        Alamofire.request(flickrUrl(withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
//            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
//            let photosDict = json["photos"] as! Dictionary<String, AnyObject>
//            let photosDictArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]
            guard let json = response.result.value as? Dictionary<String, Any> else { return }
            let photosDict = json["photos"] as! Dictionary<String, Any>
            let photosDictArray = photosDict["photo"] as! [Dictionary<String, Any>]
            for photo in photosDictArray {
                let postURL = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_z_d.jpg"
                self.imageURLArray.append(postURL)
            }
            handler(true)
        }   }
    func retrieveImages(handler: @escaping (_ status: Bool) -> ()) {
        imageArray = []
        for url in imageURLArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
            guard let image = response.result.value else { return }
                self.imageArray.append(image)
                self.progressLbl?.text = "\(self.imageArray.count)/40 Images Downloaded"
                if self.imageArray.count == self.imageURLArray.count {
                    handler(true)
                }   })  }   }
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
        }
    }
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
            //locationManager.requestWhenInUseAuthorization()
        } else {
            return
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // number of items in array
        return 4
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell
        return cell!
    }
}
