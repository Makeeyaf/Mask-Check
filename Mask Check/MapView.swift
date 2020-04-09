//  Copyright © 2020 Makeeyaf. All rights reserved

import SwiftUI
import MapKit
import Combine

class MCMapViewController: ObservableObject {
    @Published public private(set) var mapView = MKMapView(frame: .zero)
    
}

struct MCMapControl: UIViewRepresentable {
    @Binding var userTrackingMode: MKUserTrackingMode
    @EnvironmentObject var mapViewController: MCMapViewController
    
    func makeUIView(context: Context) -> MKMapView {
        mapViewController.mapView.delegate = context.coordinator
        
        let coordinate = CLLocationCoordinate2D(latitude: 36.378218, longitude: 127.834492)
        let span = MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapViewController.mapView.setRegion(region, animated: false)
        mapViewController.mapView.showsScale = true
        
//        context.coordinator.followUserIfPossible()
        
        return mapViewController.mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if uiView.userTrackingMode != userTrackingMode {
            uiView.setUserTrackingMode(userTrackingMode, animated: true)
        }
    }
    
    func makeCoordinator() -> MCMapViewCoordinator {
        return MCMapViewCoordinator(self)
    }
    
    // MARK: - Coordinator
    
    class MCMapViewCoordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var control: MCMapControl
        var lastUpdatedRegion: MKCoordinateRegion = .init(center: CLLocationCoordinate2D(latitude: 36.378218, longitude: 127.834492), span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4))
        var lastUpdatedRadius: Double = 1000
        var lastUpdateTime: Date = Date()
        let locationManager: CLLocationManager = .init()
        let mcheck = MCCheck()
        var cancellable: Cancellable?
        
        let updateInterval: Int = 5*60
        
        init(_ control: MCMapControl) {
            self.control = control
            super.init()
            
            setupLocationManager()
            
        }
        
        deinit {
            self.cancellable?.cancel()
        }
        
        
        private func setupLocationManager() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.pausesLocationUpdatesAutomatically = true
        }
        
        
        private func getNewRadius(_ radius: Double) -> Double {
            switch radius {
            case _ where radius > 2500:
                return 5000
            case _ where radius < 400:
                return 800
            default:
                return radius*2
            }
        }
        
        private func startTimer() {
            #if DEBUG
            print("\(type(of: self)).\(#function)")
            #endif
            cancellable?.cancel()
            cancellable = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
                .sink { _ in
                    let duration = Int(DateInterval(start: self.lastUpdateTime, end: Date()).duration)
                    print("Time remaining: \(self.updateInterval - duration) sec")
                    
                    if duration >= self.updateInterval {
                        let currentRadius = self.control.mapViewController.mapView.currentRadius()
                        self.updateMapView(mapView: self.control.mapViewController.mapView, radius: self.getNewRadius(currentRadius))
                    }
            }
        }
        
        
        private func getDistance(currentRegion: MKCoordinateRegion, previousRegion: MKCoordinateRegion) -> CLLocationDistance {
            
            let previousLocation = CLLocation(latitude: previousRegion.center.latitude, longitude: previousRegion.center.longitude)
            let currentLocation = CLLocation(latitude: currentRegion.center.latitude, longitude: currentRegion.center.longitude)

            return previousLocation.distance(from: currentLocation)
        }

        
        private func updateMapView(mapView: MKMapView, radius: Double) {
            self.startTimer()
            
            mapView.removeAnnotations(mapView.annotations)
            
            mcheck.getStore(at: mapView.region.center, in: Int(radius)) { response in
                for store in response.stores {
                    guard let status = store.remain_stat, status != MCRemainStat.none.status, status != MCRemainStat.empty.status else {
                        continue
                    }
                    
                    #if DEBUG
                    print("Add \(store.name) \(store.remain_stat ?? "nil")")
                    #endif
                    DispatchQueue.main.async {
                        let pin = MCMapPin(store)
                        mapView.addAnnotation(pin)
                    }
                }
                
            }
            
            self.lastUpdatedRegion = mapView.region
            self.lastUpdatedRadius = radius
            self.lastUpdateTime = Date()

        }
        
        // MARK: MKMapViewDelegate
        func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
            #if DEBUG
            print("\(type(of: self)).\(#function): userTrackingMode=", terminator: "")
            switch mode {
            case .follow:            print(".follow")
            case .followWithHeading: print(".followWithHeading")
            case .none:              print(".none")
            @unknown default:        print("@unknown")
            }
            #endif
            if CLLocationManager.locationServicesEnabled() {
                switch mode {
                case .follow, .followWithHeading:
                    switch CLLocationManager.authorizationStatus() {
                    case .notDetermined:
                        locationManager.requestWhenInUseAuthorization()
                    case .restricted:
                        //                    // Possibly due to active restrictions such as parental controls being in place
                        //                    let alert = UIAlertController(title: "Location Permission Restricted", message: "The app cannot access your location. This is possibly due to active restrictions such as parental controls being in place. Please disable or remove them and enable location permissions in settings.", preferredStyle: .alert)
                        //                    alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                        //                        // Redirect to Settings app
                        //                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        //                    })
                        //                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        
                        //                    present(alert)
                        
                        DispatchQueue.main.async {
                            self.control.userTrackingMode = .none
                        }
                    case .denied:
                        //                    let alert = UIAlertController(title: "Location Permission Denied", message: "Please enable location permissions in settings.", preferredStyle: .alert)
                        //                    alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                        //                        // Redirect to Settings app
                        //                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        //                    })
                        //                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        //                    present(alert)
                        
                        DispatchQueue.main.async {
                            self.control.userTrackingMode = .none
                        }
                    default:
                        DispatchQueue.main.async {
                            self.control.userTrackingMode = mode
                        }
                    }
                default:
                    DispatchQueue.main.async {
                        self.control.userTrackingMode = mode
                    }
                }
            } else {
                //            let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services in settings.", preferredStyle: .alert)
                //            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                //                // Redirect to Settings app
                //                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                //            })
                //            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                //            present(alert)
                
                DispatchQueue.main.async {
                    self.control.userTrackingMode = mode
                }
            }
        }
        
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            #if DEBUG
            print("\(type(of: self)).\(#function)")
            #endif
            let currentRadius = mapView.currentRadius()
            let distance = self.getDistance(currentRegion: mapView.region, previousRegion: self.lastUpdatedRegion)
            
            if distance + currentRadius > self.lastUpdatedRadius {
                self.updateMapView(mapView: mapView, radius: self.getNewRadius(currentRadius))
            }
            print("distance: \(Int(distance)), radius: \(currentRadius)")
            print("Position: \(mapView.region.center.latitude), \(mapView.region.center.longitude)")
        }
        
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let store = annotation as? MCMapPin else { return nil }
            
            let identifier = "Pin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.canShowCallout = true
            annotationView?.markerTintColor = store.remain_stat.color
            annotationView?.displayPriority = .required
            let calloutViewController = UIHostingController(rootView: CalloutAccessoryView(status: store.remain_stat, stock_at: store.stock_at, created_at: store.created_at))
            calloutViewController.view.backgroundColor = UIColor.clear
            annotationView?.detailCalloutAccessoryView = calloutViewController.view
            
            return annotationView
        }
        
        // MARK: CLLocationManagerDelegate
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            #if DEBUG
            print("\(type(of: self)).\(#function): status=", terminator: "")
            switch status {
            case .notDetermined:       print(".notDetermined")
            case .restricted:          print(".restricted")
            case .denied:              print(".denied")
            case .authorizedAlways:    print(".authorizedAlways")
            case .authorizedWhenInUse: print(".authorizedWhenInUse")
            @unknown default:          print("@unknown")
            }
            #endif
            
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.startUpdatingLocation()
                control.mapViewController.mapView.setUserTrackingMode(control.userTrackingMode, animated: true)

                guard let coordinate = manager.location?.coordinate else { break }
                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                let region = MKCoordinateRegion(center: coordinate, span: span)
                control.mapViewController.mapView.setRegion(region, animated: true)
            default:
                control.mapViewController.mapView.setUserTrackingMode(.none, animated: true)
            }
        }
        
    }
}


//class MCUserTrackingButtonController: ObservableObject {
//    @Published var MCUserTrackingButton: MKUserTrackingButton
//
//    init(mapView: MKMapView) {
//        _MCUserTrackingButton = .init(initialValue: MKUserTrackingButton(mapView: mapView))
//    }
//
//}
//
//struct MCUserTrackingButton: UIViewRepresentable {
//    @EnvironmentObject var userTrackingButtonController: MCUserTrackingButtonController
//
//    func makeUIView(context: Context) -> MKUserTrackingButton {
//        userTrackingButtonController.MCUserTrackingButton.tintColor = UIColor.label
//        userTrackingButtonController.MCUserTrackingButton.backgroundColor = UIColor.clear
//        return userTrackingButtonController.MCUserTrackingButton
//    }
//
//    func updateUIView(_ uiView: MKUserTrackingButton, context: Context) {
//        return
//    }
//}
extension MKMapView {
    func currentRadius() -> Double {
        let centerLocation = CLLocation(latitude: self.centerCoordinate.latitude, longitude: self.centerCoordinate.longitude)
        let topLeadingCoordinate = self.convert(CGPoint(x: 0, y: 0), toCoordinateFrom: self)
        let topLeadingLocation = CLLocation(latitude: topLeadingCoordinate.latitude, longitude: topLeadingCoordinate.longitude)
        return centerLocation.distance(from: topLeadingLocation)
    }
    
}
