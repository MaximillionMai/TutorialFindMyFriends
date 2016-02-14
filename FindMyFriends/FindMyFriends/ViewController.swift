//
//  ViewController.swift
//  FindMyFriends
//
//  Created by Max Mai on 2/13/16.
//  Copyright © 2016 Max Mai. All rights reserved.
//

import UIKit

import MapKit
import CoreLocation

import Firebase
let URL_TO_DATA = "https://YourFireBaseApp.firebaseio.com/map-example-app/user-locations"


class UserLocationAnnotation : NSObject, MKAnnotation {
    @objc var coordinate: CLLocationCoordinate2D
    @objc var title: String?
    @objc var subtitle: String?

    override init() {
        coordinate = CLLocationCoordinate2DMake(0, 0)
        title = nil;
        subtitle = nil;
    }
}



class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    let locationManager = CLLocationManager()
    var userName = "Max"

    let firebaseRootRef = Firebase(url: URL_TO_DATA)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.locationManager.delegate = self

        if CLLocationManager.locationServicesEnabled() {
            if CLLocationManager.authorizationStatus() == .NotDetermined {
                if self.locationManager.respondsToSelector("requestWhenInUseAuthorization") {
                    self.locationManager.requestWhenInUseAuthorization()
                }
            }
        }

        self.addObserversForAllUserLocations()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        self.onLocationAllowed()
    }

    func onLocationAllowed() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse || CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            self.mapView.showsUserLocation = true
            self.onLocationUpdated()
        }
    }

    func onLocationUpdated() {
        self.zoomToUser()
        if self.locationManager.location != nil {
            self.uploadUserCoordinate(self.locationManager.location!.coordinate, deviceUuid: self.getDeviceUuid(), userName: self.userName)
        }
    }


    func zoomToUser() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), { () -> Void in
            let userLocation = self.locationManager.location
            if userLocation != nil {
                let userCoordinate = userLocation!.coordinate
                let mapRegion = MKCoordinateRegion(center: userCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta:0.01))

                self.mapView.setRegion(mapRegion, animated: true)
            }
        })
    }

    func getDeviceUuid() -> String {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if (userDefaults.stringForKey("mapExampleDeviceUUID") == nil) {
            userDefaults.setObject(NSUUID.init().UUIDString, forKey: "mapExampleDeviceUUID")
        }
        return userDefaults.stringForKey("mapExampleDeviceUUID")!
    }

    func uploadUserCoordinate(userCoordinate: CLLocationCoordinate2D, deviceUuid: String, userName: String) {

        let newChildRef = self.firebaseRootRef.childByAppendingPath(deviceUuid)

        let userLocationDictionary: NSDictionary = ["latitude":(userCoordinate.latitude), "longitude":(userCoordinate.longitude)]
        let userInfoDictionary: NSDictionary = ["name":userName, "location":userLocationDictionary]

        // now it is appended at the end of data at the server
        newChildRef.setValue(userInfoDictionary)
    }

    // parse dictionary to UserLocationAnnotation
    func userLocationAnnotationFromDictionary(valueDictionary: NSDictionary) -> UserLocationAnnotation {
        let userLocationAnnotation : UserLocationAnnotation = UserLocationAnnotation()
        userLocationAnnotation.title = valueDictionary.objectForKey("name") as? String
        let locationDict = valueDictionary.objectForKey("location") as? NSDictionary
        if (locationDict != nil && locationDict?.objectForKey("latitude") != nil && locationDict?.objectForKey("longitude") != nil) {
            let latitude = locationDict?.objectForKey("latitude") as? Double
            let longitude = locationDict?.objectForKey("longitude") as? Double
            userLocationAnnotation.coordinate.latitude = latitude!
            userLocationAnnotation.coordinate.longitude = longitude!
        }

        return userLocationAnnotation
    }

    // add Firebase observers
    func addObserversForAllUserLocations() {
        // Retrieve new posts as they are added to the database
        self.firebaseRootRef.observeEventType(.ChildAdded, withBlock: { snapshot in
            var userLocationAnnotation : UserLocationAnnotation = UserLocationAnnotation()

            userLocationAnnotation = self.userLocationAnnotationFromDictionary(snapshot.value as! NSDictionary)

            self.mapView.addAnnotation(userLocationAnnotation)
        })
    }

}

