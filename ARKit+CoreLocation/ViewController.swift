//
//  ViewController.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import UIKit
import SceneKit
import MapKit
import ARCL



@available(iOS 11.0, *)
class ViewController: UIViewController {
    
    let sceneLocationView = SceneLocationView()

    let mapView = MKMapView()
    var userAnnotation: MKPointAnnotation?
    var locationEstimateAnnotation: MKPointAnnotation?

    var updateUserLocationTimer: Timer?

    ///Whether to show a map view
    ///The initial value is respected
    var showMapView: Bool = false

    var centerMapOnUserLocation: Bool = true

    ///Whether to display some debugging data
    ///This currently displays the coordinate of the best location estimate
    ///The initial value is respected
    var displayDebugging = false

    var infoLabel = UILabel()

    var positionLabel = UILabel()
    
    var countFlats = UILabel()
    
    var radiusInput = UISearchBar()
    
    var globalPositionLat: Double?
    
    var globalPositionLon: Double?
    
    var updateInfoLabelTimer: Timer?

    var adjustNorthByTappingSidesOfScreen = false
    
    var itemsGlobal: [ItemStruct?] = []
    
    var flatsCount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        infoLabel.font = UIFont.systemFont(ofSize: 10)
        infoLabel.textAlignment = .left
        infoLabel.textColor = UIColor.white
        infoLabel.numberOfLines = 0
        sceneLocationView.addSubview(infoLabel)
        
        positionLabel.font = UIFont.systemFont(ofSize: 10)
        positionLabel.textAlignment = .left
        positionLabel.textColor = UIColor.white
        positionLabel.numberOfLines = 0
        sceneLocationView.addSubview(positionLabel)
        
        countFlats.font = UIFont.systemFont(ofSize: 10)
        countFlats.textAlignment = .left
        countFlats.textColor = UIColor.white
        countFlats.numberOfLines = 0
        sceneLocationView.addSubview(countFlats)
        
        radiusInput.delegate = self
        sceneLocationView.addSubview(radiusInput)
        
        updateInfoLabelTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(ViewController.updateInfoLabel),
            userInfo: nil,
            repeats: true)

        // Set to true to display an arrow which points north.
        //Checkout the comments in the property description and on the readme on this.
//        sceneLocationView.orientToTrueNorth = false

//        sceneLocationView.locationEstimateMethod = .coreLocationDataOnly
        sceneLocationView.showAxesNode = true
        sceneLocationView.locationDelegate = self

        if displayDebugging {
            sceneLocationView.showFeaturePoints = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute:
        {
            //self.StartLoad()
        })
        
        //buildDemoData().forEach { sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: $0) }
        
        view.addSubview(sceneLocationView)

        if showMapView {
            mapView.delegate = self
            mapView.showsUserLocation = true
            mapView.alpha = 0.8
            view.addSubview(mapView)

            updateUserLocationTimer = Timer.scheduledTimer(
                timeInterval: 0.5,
                target: self,
                selector: #selector(ViewController.updateUserLocation),
                userInfo: nil,
                repeats: true)
        }
        
    }
 
 
    //***************************
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        print("run")
        sceneLocationView.run()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        print("pause")
        // Pause the view's session
        sceneLocationView.pause()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sceneLocationView.frame = view.bounds

        infoLabel.frame = CGRect(x: 6, y: 0, width: self.view.frame.size.width - 12, height: 14 * 4)
        
        positionLabel.frame = CGRect(x:6, y: 10, width: self.view.frame.size.width - 12, height: 14 * 4)
        
        countFlats.frame = CGRect(x:6, y: 90, width: self.view.frame.size.width - 12, height: 14 * 4)
        
        radiusInput.frame = CGRect(x:6, y: 50, width: self.view.frame.size.width - 12, height: 14 * 4)
        
        if showMapView {
            infoLabel.frame.origin.y = (self.view.frame.size.height / 2) - infoLabel.frame.size.height
        } else {
            infoLabel.frame.origin.y = self.view.frame.size.height - infoLabel.frame.size.height
        }

        mapView.frame = CGRect(
            x: 0,
            y: self.view.frame.size.height / 2,
            width: self.view.frame.size.width,
            height: self.view.frame.size.height / 2)
    }

    @objc func updateUserLocation() {
        guard let currentLocation = sceneLocationView.currentLocation() else {
            return
        }

        DispatchQueue.main.async {
            if let bestEstimate = self.sceneLocationView.bestLocationEstimate(),
                let position = self.sceneLocationView.currentScenePosition() {
                print("")
                print("Fetch current location")
                print("best location estimate, position: \(bestEstimate.position), location: \(bestEstimate.location.coordinate), accuracy: \(bestEstimate.location.horizontalAccuracy), date: \(bestEstimate.location.timestamp)")
                print("current position: \(position)")
                let translation = bestEstimate.translatedLocation(to: position)
                print("translation: \(translation)")
                print("translated location: \(currentLocation)")
                print("")
            }
            if self.userAnnotation == nil {
                self.userAnnotation = MKPointAnnotation()
                self.mapView.addAnnotation(self.userAnnotation!)
            }
            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                self.userAnnotation?.coordinate = currentLocation.coordinate
            }, completion: nil)
            if self.centerMapOnUserLocation {
                UIView.animate(withDuration: 0.45, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                    self.mapView.setCenter(self.userAnnotation!.coordinate, animated: false)
                }, completion: { _ in
                    self.mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
                })
            }
            if self.displayDebugging {
                let bestLocationEstimate = self.sceneLocationView.bestLocationEstimate()

                if bestLocationEstimate != nil {
                    if self.locationEstimateAnnotation == nil {
                        self.locationEstimateAnnotation = MKPointAnnotation()
                        self.mapView.addAnnotation(self.locationEstimateAnnotation!)
                    }
                    self.locationEstimateAnnotation!.coordinate = bestLocationEstimate!.location.coordinate
                } else {
                    if self.locationEstimateAnnotation != nil {
                        self.mapView.removeAnnotation(self.locationEstimateAnnotation!)
                        self.locationEstimateAnnotation = nil
                    }
                }
            }
        }
    }

    @objc func updateInfoLabel() {
        
        if sceneLocationView.currentLocation() != nil
        {
            let pos = sceneLocationView.currentLocation()
            let corLat: Double = (pos?.coordinate.latitude)!
            let corLon: Double = (pos?.coordinate.longitude)!
            let positionLat: String = String(format:"%f", corLat)
            let positionLon: String = String(format:"%f", corLon)
            let finally:String = "Position - " + positionLat + " x " + positionLon
            let count:String = String(flatsCount)
            
            positionLabel.text = finally
            countFlats.text = "Count - "+count
        }
        
        if let position = sceneLocationView.currentScenePosition() {
            infoLabel.text = "x: \(String(format: "%.2f", position.x)), y: \(String(format: "%.2f", position.y)), z: \(String(format: "%.2f", position.z))\n"
        }

        if let eulerAngles = sceneLocationView.currentEulerAngles() {
            infoLabel.text!.append("Euler x: \(String(format: "%.2f", eulerAngles.x)), y: \(String(format: "%.2f", eulerAngles.y)), z: \(String(format: "%.2f", eulerAngles.z))\n")
        }

        if let heading = sceneLocationView.locationManager.heading,
            let accuracy = sceneLocationView.locationManager.headingAccuracy {
            
            infoLabel.text!.append("Heading: \(heading)º, accuracy: \(Int(round(accuracy)))º\n")
        }

        let date = Date()
        let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)

        if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
            infoLabel.text!.append("\(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second)):\(String(format: "%03d", nanosecond / 1000000))")
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        
        /*sceneLocationView
         1. Get The Current Touch Location
         2. Check That We Have Touched A Valid Node
         3. Check If The Node Has A Name
         4. Handle The Touch
         */
        
        guard let touchLocation = touches.first?.location(in: sceneLocationView),
            let hitNode = sceneLocationView.hitTest(touchLocation, options: nil).first?.node,
            let nodeName = hitNode.name
            else
            {
                //No Node Has Been Tapped
                return
            }
        //Handle Event Here e.g. PerformSegue
        print(nodeName)
        //https://domclick.ru/card/sale__house__5507881
        if let url = URL(string: "https://domclick.ru/card/sale__flat__"+nodeName)
        {
            UIApplication.shared.open(url, options: [:])
        }
 
        /*
        super.touchesBegan(touches, with: event)

        guard
            let touch = touches.first,
            let touchView = touch.view
        else {
            return
        }

        if mapView == touchView || mapView.recursiveSubviews().contains(touchView) {
            centerMapOnUserLocation = false
            print("First")
        } else {
            let location = touch.location(in: self.view)

            if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
                print("left side of the screen")
                sceneLocationView.moveSceneHeadingAntiClockwise()
            } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
                print("right side of the screen")
                sceneLocationView.moveSceneHeadingClockwise()
            } else {
                print("Create")
                let image = UIImage(named: "pin")!
                let annotationNode = LocationAnnotationNode(location: nil, image: image)
                annotationNode.scaleRelativeToDistance = true
                sceneLocationView.addLocationNodeForCurrentPosition(locationNode: annotationNode)
            }
        }
        */
    }
}

@available(iOS 11.0, *)
extension ViewController: UISearchBarDelegate{
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        print("This is - "+searchBar.text!)
        self.radiusInput.endEditing(true)
        self.StartLoad(radius: searchBar.text!)
    }
    
}

// MARK: - MKMapViewDelegate
@available(iOS 11.0, *)
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        guard let pointAnnotation = annotation as? MKPointAnnotation else {
            return nil
        }

        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        marker.displayPriority = .required

        if pointAnnotation == self.userAnnotation {
            marker.glyphImage = UIImage(named: "user")
        } else {
            marker.markerTintColor = UIColor(hue: 0.267, saturation: 0.67, brightness: 0.77, alpha: 1.0)
            marker.glyphImage = UIImage(named: "compass")
        }

        return marker
    }
}

// MARK: - SceneLocationViewDelegate
@available(iOS 11.0, *)
extension ViewController: SceneLocationViewDelegate {
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        //print("add scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }

    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        //print("remove scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }

    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
    }

    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {

    }

    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {

    }
}

// MARK: - Data Helpers
@available(iOS 11.0, *)
private extension ViewController {
    func buildDemoData() -> [LocationAnnotationNode] {
        
        var nodes: [LocationAnnotationNode] = []
        
        print("Json Count - ",itemsGlobal.count)
        
        for i in 0..<itemsGlobal.count
        {
            //print("lat - ",itemsGlobal[i]?.location?.lat!," lon - ",itemsGlobal[i]?.location?.lon!)
            let latitudeLocal: CLLocationDegrees = (itemsGlobal[i]?.location?.lat)!
            let longitudeLocal: CLLocationDegrees = (itemsGlobal[i]?.location?.lon)!
            let flatId: Int = (itemsGlobal[i]?.id)!
            //let imageNameFromWeb: String = (itemsGlobal[i]?.photo[0])!
            let imageNameFromWeb: String = ""
            let imageNameConst: String = "https://img09.domclick.ru/s1280x-q80"
            let imageNameLocal:String = imageNameConst+imageNameFromWeb
            let target = buildNode(latitude: latitudeLocal, longitude: longitudeLocal, altitude: 165, imageName: imageNameLocal, id: flatId)
            target.scaleRelativeToDistance = true
            nodes.append(target)
        }
        
        flatsCount = nodes.count
        
        print("Nods Count - ",flatsCount)
        
        return nodes
    }

    func buildNode(latitude: CLLocationDegrees, longitude: CLLocationDegrees, altitude: CLLocationDistance, imageName: String, id: Int) -> LocationAnnotationNode {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let location = CLLocation(coordinate: coordinate, altitude: altitude)
        var image = UIImage(named: "pin3")!
        
        //let singleTap = UITapGestureRecognizer(target: self, action: Selector("tapDetected"))
        //image.isUserInteractionEnabled = true
        //image.addGestureRecognizer(funcName)
        
        //if let urlImage = NSURL(string: imageName)
        //{
        //    if let data = NSData(contentsOf: urlImage as URL)
        //    {
        //        image = UIImage(data: data as Data, scale: 1)!
        //       image = image.resizedImage(newSize: CGSize(width: 100, height: 100))
        //   }
        //}
        //let Lan = LocationAnnotationNode(location: location, image: image)
        let flatID:String = String(id)
        let Lan = LocationAnnotationNode(location: location, image: image, flatID: flatID)
        
        return Lan
    }
    
    func StartLoad(radius: String)
    {
        let pos = sceneLocationView.currentLocation()
        let corLat: Double = (pos?.coordinate.latitude)!
        let corLon: Double = (pos?.coordinate.longitude)!
        let positionLat: String = String(format:"%f", corLat)
        let positionLon: String = String(format:"%f", corLon)
        let finally:String = "Position - " + positionLat + " x " + positionLon
        let urlString: String = "https://offers-service.domclick.ru/api/v1/offers/?counts=false&nearby_location="+positionLat+","+positionLon+"&nearby_radius="+radius+"&aggregate_by=with_photo"
        //let urlString = "https://offers-service.domclick.ru/api/v1/offers/?counts=false&nearby_location=55.7436,37.7671&nearby_radius="+radius+"&aggregate_by=with_photo"
        print("URL - "+urlString)
        guard let url = URL(string: urlString) else {return}
        URLSession.shared.dataTask(with: url) { (data, respone, error) in
            guard let data = data else {return}
            guard error == nil else {return}
            do
            {
                let flatsW = try JSONDecoder().decode(FirstLevel.self, from: data)
                self.itemsGlobal = (flatsW.result?.items)!
                self.sceneLocationView.removeAllNodes()
                self.buildDemoData().forEach
                    {
                        self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: $0)
                    }
            }
            catch let error
            {
                print(error)
            }
            
            }.resume()
    }
    
}

extension DispatchQueue {
    func asyncAfter(timeInterval: TimeInterval, execute: @escaping () -> Void) {
        self.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(timeInterval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: execute)
    }
}

extension UIView {
    func recursiveSubviews() -> [UIView] {
        var recursiveSubviews = self.subviews

        for subview in subviews {
            recursiveSubviews.append(contentsOf: subview.recursiveSubviews())
        }

        return recursiveSubviews
    }
}
