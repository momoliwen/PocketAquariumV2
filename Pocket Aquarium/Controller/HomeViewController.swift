//
//  HomeViewController.swift
//  Pocket Aquarium
//
//  Created by Liwen Liang on 15/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import MapKit
import UserNotifications


protocol EditHomeTankDelegate{
    func addNewTank(newTank : FishTank?)
    func deleteFishTank (index : IndexPath)
}

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, EditHomeTankDelegate, CLLocationManagerDelegate, UITextFieldDelegate {
   
    @IBOutlet weak var tankCollectionView: UICollectionView!
    @IBOutlet weak var showCurrentLocation: UIButton!
    @IBOutlet weak var addressTextfield: UITextField!
    
    
    var tankList : [FishTank]
    let dateFormatter = DateFormatter()
    let locationManager = CLLocationManager()
    var currentLocation : CLLocation?
    var currentAddress : String = String()
    var latitude : Double?
    var longitude : Double?
    var isShow : Bool = true
    var fishMemberList = [Fish]()
    
    //DB handler
    private var tankRefHandle : DatabaseHandle?
    private var realtimeRefHandle: DatabaseHandle?
    
    //create users db reference
    var userId = Auth.auth().currentUser?.uid
    
    var userRef : DatabaseReference
    var tankRef : DatabaseReference
    var realTimeRef : DatabaseReference
    lazy var historyTaskRef = Database.database().reference().child("historyTaskList")
    var sensorRef = Database.database().reference().child("Sensors")
    
  
    //prepare select tank
    var selectTank : FishTank?
    var selectedTankIndex : Int?
    var sensorList = [SensorDevice]()
    var selectSensorName = "Unknown"
    
    var appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    required init?(coder aDecoder: NSCoder) {
        userRef = Database.database().reference().child("uid").child(userId!)
        tankRef = userRef.child("tanks")
        realTimeRef = Database.database().reference().child("Realtime").child("\(self.userId!)")
        tankList = []
        super.init(coder: aDecoder)
    }
    
    //MARK: - Release the observe handler on tank and realtime references
    deinit {
        if let tankreHandle = tankRefHandle {
            tankRef.removeObserver(withHandle: tankreHandle)
        }
        if let sensorReHandle = realtimeRefHandle {
            realTimeRef.removeObserver(withHandle: sensorReHandle)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //configure location
        configureLocationManager()
        observeSavedGeoLocation()
        print("observe geo address ok , \(self.latitude) , \(self.longitude)")
        configureLocationButton()
        configureTextFieldUI()
        
        self.tankCollectionView.delegate = self
        self.tankCollectionView.dataSource = self
        self.addressTextfield.delegate = self
        
        //download data from firebsae
        observeTanksAdded(){ (fishTank) in
           self.tankList.append(fishTank)
           self.observeRealTimeValueV2(thisTank: fishTank)
           self.tankCollectionView.reloadData()
        }
        observeRealTimeValue()
        
        //download sensor value
        InitialSensorManager.observeSensors(completion: { sensor in
            self.sensorList.append(sensor)
        })
        print("sensor list count :  \(sensorList.count)")
        
        //add tank collection view long press gesture show delete button
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressOnTankCell(gestureReconizer:)))
        longPressGesture.minimumPressDuration = 0.3
        longPressGesture.delaysTouchesBegan = true
        self.tankCollectionView.addGestureRecognizer(longPressGesture)
        
        self.showWaterAlertAndNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.selectTank != nil {
            self.observeTanksValueChanges(thisTank: self.selectTank!)
        }
        // self.showWaterAlertAndNotification()
    }
    
    //MARK: show delete button by long press gesture
    @objc func longPressOnTankCell(gestureReconizer : UILongPressGestureRecognizer){
        if gestureReconizer.state != UIGestureRecognizerState.ended{
            return
        }
        
        let pressPoint = gestureReconizer.location(in: self.tankCollectionView)
        let selectIndexPath = self.tankCollectionView.indexPathForItem(at: pressPoint)
        if let indexPath = selectIndexPath {
            var cell = self.tankCollectionView.cellForItem(at: indexPath) as! TankCollectionViewCell
            print(indexPath.row)
            
            //cell.delegate = self
            self.isShow = !isShow
            print("\(isShow)")
            self.tankCollectionView.reloadData()
        }else{
            print("could not find index path")
        }
    }
    
    //MARK: find fish members of the tank
    func fndFishMembers(thisTank: FishTank, completion: @escaping ([Fish])->Void) {
        let ref = self.tankRef.child("\(thisTank.tankId)").child("fishMembers")
        ref.observeSingleEvent(of: .value, with: {(snapshot) in
            print(snapshot)
            var fishList = [Fish]()
            
            for child in snapshot.children.allObjects as! [DataSnapshot]{
                if let thisFish = Fish(snapshot: child, uid: self.userId!){
                    fishList.append(thisFish)
                }
            }
            completion(fishList)
        })
    }
    
    //MARK: delete fish tank delegate
    func deleteFishTank (index indexPath : IndexPath) {
        let alertController = UIAlertController(title: "Attention", message: "If you confirm to delete, this tank and all history realtime data and maintenance records will be deleted as well", preferredStyle: .alert)
        let confirm = UIAlertAction(title: "Confirm", style: .default) { (action:UIAlertAction) in
            
            // Get the deleted tank
            let deleteTank = self.tankList[indexPath.row]
            
            self.fndFishMembers(thisTank:deleteTank){fishList in
                self.fishMemberList = fishList
            }
        
            //1. tnak fishmembers delet
            print("1. edit fish members' number to 0  ...")
            let fishMembersRef = self.tankRef.child("\(deleteTank.tankId)").child("fishMembers")
            fishMembersRef.removeValue()

            //2. remove maintenance records of the tank
            print("2. delete task data  ...")
            let taskRef = self.historyTaskRef.child("\(deleteTank.tankId)")
            taskRef.removeValue()
            
            //3. delete this tank's sensor data
            print("3. delete sensor data  ...")
            let sensorId = deleteTank.sensorId
            self.realTimeRef.observeSingleEvent(of: .value, with: {(snapshot) in
                print(snapshot)
                for child in snapshot.children.allObjects as! [DataSnapshot] {
                    print("\(child.ref)")
                    let query = child.ref.queryOrdered(byChild: "sensorId").queryEqual(toValue: sensorId!)
                    query.observeSingleEvent(of: .value, with: {(snapshot) in
                        print(snapshot)
                        for child in snapshot.children {
                            let data = child as! DataSnapshot
                            print(data.ref)
                            data.ref.removeValue()
                        }
                    })
                }
            })
            //4. delete this tank reference
            print("4. delete tank ref ...")
            self.tankRef.child(deleteTank.tankId).removeValue(completionBlock: {
                error,tankRef  in
                if error != nil {
                    print(error?.localizedDescription)
                }
            })
            //3. remove collection view data source
            self.tankList.remove(at: indexPath.row)
            
            //4. display finish alert
            self.autoDismissSuccessAlert(message: "Delete Success", title: "You have deleted the tank and related realtime data and maintance records")
            self.tankCollectionView.reloadData()
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            print("you have canceled")
        }
        
        alertController.addAction(cancel)
        alertController.addAction(confirm)
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: if water state is bad, it will show the alert and notification in background
    func showWaterAlertAndNotification(){
        for tank in self.tankList{
            if tank.state == "Bad" {
                showAlert(withTitle: "Water Warning", message: "Current temperature or pH was be out of range")
                self.appDelegate?.createWaterNotification(tank: tank)
                print("create noti in view will appear..")
            }
        }
    }

    //MARK: - Firebase observation: rßetrieve and observe all tanks
    private func observeTanksAdded(completion: @escaping (FishTank) -> Void) {
        print("start to download fish tank data .. ")
        tankRefHandle = tankRef.observe(.childAdded, with: {(snapshot)-> Void in
            print(snapshot)
            
            if let thisTank = FishTank(snapshot: snapshot){
                //self.tankList.append(thisTank)
                print("new tank append success")
                //self.tankCollectionView.reloadData()
                //DispatchQueue.main.async {
                 completion(thisTank)
               // }
            }
            else {
                print("obser tank child added error")
            }
        })
    }
    
    //MARK: - Firebase observation: rßetrieve and observe all tanks
    private func observeTanksAdded(){
        print("start to download tank ... ")
        tankRefHandle = tankRef.observe(.childAdded, with: {(snapshot)-> Void in
            print(snapshot)
            if let thisTank = FishTank(snapshot: snapshot){
                self.tankList.append(thisTank)
                print("new tank append success")
                self.tankCollectionView.reloadData()
            }
            else {
                print("obser tank child added error")
            }
        })
    }
    
    //MARK: Firebase observation : view will appear retrieve once
    func observeTanksValueChanges(thisTank : FishTank){
        //self.tankList.removeAll()
        let thisRef = tankRef.child("\(thisTank.tankId)")
        thisRef.observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot)
            
            if  let updatedTank = FishTank(snapshot: snapshot){
                thisTank.desiredMinpH = updatedTank.desiredMinpH
                thisTank.desiredMaxpH = updatedTank.desiredMaxpH
                thisTank.desiredMinTemp = updatedTank.desiredMinTemp
                thisTank.desiredMaxTemp = updatedTank.desiredMaxTemp
                thisTank.sensorId = updatedTank.sensorId
                self.tankCollectionView.reloadData()
            }else{
                print("obser tank value change error")
            }
        })
    }
    
    //MARK: - Firebase observation: Retrieve current sensor vlaue,assume only one device
    private func observeRealTimeValue(){
        //retrieve the last 2 children --> last date
        let today = Date()
        let queryDate = today.toMatchRealTimeDate(date: today)
        let realTimeQuery = realTimeRef.child("\(queryDate)").queryLimited(toLast: 10)
        print("start to download realtime data ..  reference: \(realTimeQuery)")
        
        self.realtimeRefHandle = realTimeQuery.observe(.childAdded, with: {(snapshot) in
            print(snapshot)
            if let realTimeItem = RealTimeValues(snapshot: snapshot){
                 print("success convert to Realtime values")
                    for tank in self.tankList {
                        if realTimeItem.sensorId == tank.sensorId {
                            tank.currentpH = realTimeItem.currentPh
                            tank.currentTemp = realTimeItem.currentTemp
                            tank.currentColor = UIColor(red: CGFloat(realTimeItem.currentRed/256)/255, green: CGFloat(realTimeItem.currentGreen/256)/255, blue: CGFloat(realTimeItem.currentBlue/256)/255, alpha: 0.8 )
                            self.calculateCurrentState(thisTank: tank, currentTemp:  tank.currentTemp!, currentPh: tank.currentpH!)
                            
                            print("\(tank.state)")
                            if tank.state == "Bad" {
                                print("water bad create notification")
                                self.appDelegate?.createWaterNotification(tank: tank)
                                print("create water notirication water bad")
                            }
                            
                            self.tankCollectionView.reloadSections([0])
                            print("success to add realtime to tank")
                    }
                }
            }
        })
    }

    //MARK: firebase observe  for initial viewdid load , retrieve the last value of today
    func observeRealTimeValueV2(thisTank : FishTank){
        //retrieve the last 2 children --> last date
        let today = Date()
        let queryDate = today.toMatchRealTimeDate(date: today)
        let realTimeQuery = realTimeRef.child("\(queryDate)").queryOrdered(byChild: "sensorId").queryEqual(toValue: "\(thisTank.sensorId!)").queryLimited(toLast: 1)
        print("start to download realtime data ..  reference: \(realTimeQuery)")
        realTimeQuery.observeSingleEvent(of: .childAdded, with: {(snapshot) in
            print(snapshot.value)
            print(thisTank.sensorId!)
            
            if let realtimeItem = RealTimeValues(snapshot: snapshot){
                print("success convert to realtime object")
                thisTank.currentpH = realtimeItem.currentPh
                thisTank.currentTemp = realtimeItem.currentTemp
                thisTank.currentColor = UIColor(red: CGFloat(realtimeItem.currentRed/256)/255, green: CGFloat(realtimeItem.currentGreen/256)/255, blue: CGFloat(realtimeItem.currentBlue/256)/255, alpha: 0.8 )
                self.calculateCurrentState(thisTank: thisTank, currentTemp: thisTank.currentTemp!, currentPh: thisTank.currentpH!)
                
                self.showWaterAlertAndNotification()
               
                self.tankCollectionView.reloadData()
            }
        })
    }


    //MARK: editTankDelegate
    func addNewTank(newTank: FishTank?) {
        if let thisNewTank = newTank{
            self.tankList.append(newTank!)
            self.tankCollectionView.reloadSections([0])
        }
    }

    //MARK: - Collection View data source
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.tankList.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //Collection view cell configure
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tankCell", for: indexPath) as! TankCollectionViewCell
        //give cell view the index and self delegate
        cell.indexPath = indexPath
        cell.delegate = self
        //set cell view with values
        let thisTank : FishTank = self.tankList[indexPath.row] as! FishTank
        cell.backgroundImg.image = UIImage(named: "fishTankPhoto")
        cell.backgroundColorView.backgroundColor = thisTank.currentColor
        cell.currentTempLabel.text = "\(thisTank.currentTemp!) ℃"
        cell.temRangeLabel.text = "\(thisTank.desiredMinTemp)℃/\(thisTank.desiredMaxTemp)℃"
        cell.currentpHLabel.text = "\(thisTank.currentpH!)"
        cell.pHRangeLabel.text = "\(thisTank.desiredMinpH)/\(thisTank.desiredMaxpH)"
        cell.tankNameLabel.text = thisTank.tankName
        cell.tankAgeLabel.text = "\(computeProtectedDates(thisTank: thisTank)) Day"
        
        if isShow {
            cell.deleteButton.isHidden = true
        }
        else {
            cell.deleteButton.isHidden = false
        }
    
        print("\(thisTank.createdDate)")
        print("cell configure success")
        
        cell.stateLabel.text = thisTank.state
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectTank = tankList[indexPath.row] as? FishTank
        self.selectSensorName =  self.findSensorName(thisTank: selectTank!)
        print("\(selectSensorName)")
        performSegue(withIdentifier: "seeTankDetail", sender: self)
    }
    

    //compute the protected date
    func computeProtectedDates(thisTank:FishTank) -> Int {
        if thisTank != nil {
            let today: Date = Date()
            let createDate = self.convertStringToDate(thisDate: thisTank.createdDate)
            let days = self.daysBetweenDates(startDate: createDate, endDate: today)
            return days + 1
        }
        return 0
    }
    
    //convert stringDate to date
    func convertStringToDate(thisDate:String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd"
        let date = dateFormatter.date(from: thisDate)
        let today: Date = Date()
        return date ?? today
    }
    
    //compute the number of days between dates
    func daysBetweenDates(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([Calendar.Component.day], from: startDate, to: endDate)
        return components.day!
    }
    
    //MARK: Compute the state
    //MARK : calculate current water state
    func calculateCurrentState(thisTank : FishTank, currentTemp : Int, currentPh : Double){
        if currentTemp < thisTank.desiredMinTemp ||
            currentTemp > thisTank.desiredMaxTemp {
            thisTank.state = "Bad"
        }
        if currentTemp == thisTank.desiredMinTemp ||
            currentTemp == thisTank.desiredMaxTemp {
            thisTank.state = "Warning"
        }
        if currentTemp < thisTank.desiredMaxTemp &&
            currentTemp > thisTank.desiredMinTemp {
            thisTank.state = "Good"
        }
        if currentPh < thisTank.desiredMinpH ||
            currentPh > thisTank.desiredMaxpH {
            thisTank.state = "Bad"
        }
        if currentPh == thisTank.desiredMaxpH ||
            currentPh == thisTank.desiredMinpH {
            thisTank.state = "Warning"
        }
        if currentPh < thisTank.desiredMaxpH &&
            currentPh > thisTank.desiredMinpH {
            thisTank.state = "Good"
        }
    }
    
    //MARK: retrieve the sensor name by tank sensor id
    func findSensorName(thisTank : FishTank) -> String {
        for sensor in sensorList {
            if sensor.sensorId == thisTank.sensorId{
                return sensor.name
            }
        }
        return ""
    }
    
    
    
/*
    //MARK: configure collection view
    func configureCollectionView () {
        let screenSize = UIScreen.main.bounds.size
        let cellWidth = floor(screenSize.width) * 0.6
        let cellHeight = floor(screenSize.height) * 0.4
        //each padding
        let insetX = (view.bounds.width - cellWidth) / 2
        let insetY = (view.bounds.height - cellHeight) / 2
        
        let layout = tankCollectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        tankCollectionView?.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }*/
    
    
    //MARK: Location manager delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status{
        case .notDetermined:
             print("user do not choose to use location manager")
             self.showCurrentLocation.tintColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
        case .denied:
             print("user deined")
             self.showCurrentLocation.tintColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
        case .restricted:
            print("user do not want to use")
            self.showCurrentLocation.tintColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
        case .authorizedAlways:
            print("permission state: always allow")
            //locationManager.startUpdatingLocation()
            configureLocationButton()
        case .authorizedWhenInUse:
            print("permission state: when in use")
            //locationManager.stopUpdatingLocation()
            configureLocationButton()
        }
    }
    
    //Firebase observation  saved location cordination
    func observeSavedGeoLocation(){
        self.userRef.child("geoAddress").observeSingleEvent(of: .value, with: {(snapshot)-> Void in
            print(snapshot)
            if let locationData = snapshot.value as? [String : Any],
                let lati = locationData["latitude"] as! Double?,
                let longi = locationData["longitude"] as! Double?{
                    self.latitude = lati
                    self.longitude = longi
                print("download location value success: \(lati), \(longi)")
                
                //1. create new location
                let nowLocation = CLLocation(latitude: self.latitude!, longitude: self.longitude!)
               
                //2. convert to address show in text field
                self.initialAddress(location: nowLocation){ address in
                    self.currentAddress = address
                    print("\(self.currentAddress)")
                    self.addressTextfield.text = self.currentAddress
                    self.addressTextfield.isEnabled = false
                }
                //3. configure button color
                self.configureLocationButton()
                
                //4.create new location notification
                self.appDelegate?.createLocationBasedTrigger(currentLatitude: self.latitude!, currentLongitude: self.longitude!)
                
                //5. create new location geofencing
                self.addNewLocationGeoFencing(newLocation: CLLocation(latitude: self.latitude!, longitude: self.longitude!))
            }
        })
    }
    
    func configureLocationButton(){
        if self.latitude != nil, self.longitude != nil {
              self.showCurrentLocation.tintColor = #colorLiteral(red: 0.1920000017, green: 0.6669999957, blue: 1, alpha: 1)
        }
        else {
              self.showCurrentLocation.tintColor = #colorLiteral(red: 0.9764705882, green: 0.8392156863, blue: 0.2862745098, alpha: 1)
        }
    }
    
    func configureTextFieldUI(){
        self.addressTextfield.addBottomBorder(backgroundColor: #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1))
    }

    //MARK: create or edit the saved monitoring location. if get the current location, convert to address string
    @IBAction func showLocationAddress(_ sender: UIButton) {
        //delete previous geo fencing
        if let lati = self.latitude, let longi = self.longitude {
            let previousLocation = CLLocation(latitude: lati, longitude: longi)
            
            print("delete previous saved location success")
        }
        
        //get current location
        guard let theLocation = currentLocation  else {
            self.showAlert(withTitle: "Oops", message: "No current location available")
            return
        }
        //1.  get new latitude and longitude
        convertLocationToAddress(location: theLocation)
        print("current address is \(currentAddress)")
    
        if self.currentAddress != nil || self.currentAddress.trimmingCharacters(in: .whitespaces).count > 0 {
            //2. confirm to saved the address and create the location notification
            initialAddress(location: theLocation){ address in
                self.currentAddress = address
            }
            //3. show confirm alert
            saveMonitoringLocationAlert(address: self.currentAddress)
            //4. configure button
            configureLocationButton()
        }
        else{
            self.showAlert(withTitle: "Oops", message: "Cannot locate your location")
        }
    }
    
    //MARK: edit monitoring address value locally and on firebase and add new geofencing and create new location notification
    func saveMonitoringLocationAlert(address : String){
        let saveLocation = UIAlertController(title: "Location", message: "Your current location is \(address)", preferredStyle: UIAlertControllerStyle.alert)
        
        let saveAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: { action in
            //1. update firebase
            self.userRef.updateChildValues([
                "geoAddress" : ["latitude" : self.latitude!,
                                "longitude" : self.longitude!]
                ])
           
            //2. update text field
            self.addressTextfield.text?.append(address)
            self.addressTextfield.textColor = #colorLiteral(red: 0.1920000017, green: 0.6669999957, blue: 1, alpha: 1)
            //3. create geofencing
            self.addNewLocationGeoFencing(newLocation: CLLocation(latitude: self.latitude!, longitude: self.longitude!))
            print("create new geo fencing on location \(address) done")
            //4. create notification center
            self.appDelegate?.createLocationBasedTrigger(currentLatitude: self.latitude!, currentLongitude: self.longitude!)
            
            print("create new geo fencing on location \(address) done")
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        saveLocation.addAction(saveAction)
        saveLocation.addAction(cancelAction)
        present(saveLocation, animated: true, completion: nil)
    }
    
    //Before the focus actually changes, Asks the delegate if editing should stop in the specified text field.
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    @IBAction func checkCurrentLocation(_ sender: UITextField) {
        if let latestAddress = addressTextfield.text?.trimmingCharacters(in: .whitespaces) {
            addressToCoordinate(address: latestAddress)
        }
    }

    //MARK: Get current location coordinate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc : CLLocation = locations.last!
        print("\(loc)")
        self.currentLocation = loc
        initialAddress(location: currentLocation){ address in
            self.currentAddress = address
        }
        print("location manager has updated location \(currentAddress)")
    }
    
    
    //MARK: - add geofencing for saved location
    func addNewLocationGeoFencing(newLocation : CLLocation) {
        let thisGeo = GeoLocation(coordinate: newLocation.coordinate, radius: 200, identifier: "home")
        let geoLocation = CLCircularRegion(center: thisGeo.coordinate, radius: thisGeo.radius, identifier: thisGeo.identifier)
        geoLocation.notifyOnExit = true
        geoLocation.notifyOnEntry = false
        
        locationManager.startMonitoring(for: geoLocation)
        print("location manager Start to monitor the \(newLocation)")
    }
    
    //MARK: - delete geofencing for previous saved location
    func deleteGeofencing(newLocation : CLLocation){
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == "home" else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("left \(region.identifier)")
        
        if UIApplication.shared.applicationState == .active{
            
            self.showAlert(withTitle: "Remember!", message: "You have left your fish tanks. Please check whether your fishtank lightings are switched off")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("enter \(region.identifier)")
    }
    
    //MARK: current location and display in the text field for the first time
    func convertLocationToAddress(location: CLLocation?) {
        let geocoder = CLGeocoder()
        if let thisLocation = location {
            geocoder.reverseGeocodeLocation(thisLocation, completionHandler: {(placemarks, error)-> Void in
                if error != nil{
                    print("Reverse geocoder failed" + (error?.localizedDescription)!)
                    return
                }
        
                if (placemarks?.count)! > 0 {
                    let firstPlaceMark = placemarks?[0] as! CLPlacemark
                    if let locationName = firstPlaceMark.name {
                        self.currentAddress.append(locationName)
                    }
                    if let street = firstPlaceMark.subThoroughfare {
                        self.currentAddress.append(", \(street)")
                    }
                    if let city = firstPlaceMark.locality{
                        self.currentAddress.append(", \(city)")
                    }
                    if let country = firstPlaceMark.country {
                        self.currentAddress.append(", \(country)")
                    }
                    
                    self.latitude = location?.coordinate.latitude
                    self.longitude = location?.coordinate.longitude
                    
                    print("current location convert to lati and longi successfully")
                }
                else{
                    self.addressTextfield.text = "Unable to find the location"
                    self.addressTextfield.textColor = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)
                    self.addressTextfield.isEnabled = true
                }
            })
        }
    }
    
    //MARK: used for downloaded latitude and longidute
    func initialAddress(location: CLLocation?, completeion: @escaping (String) -> Void){
        let geocoder = CLGeocoder()
        if let thisLocation = location {
            geocoder.reverseGeocodeLocation(thisLocation, completionHandler: {(placemarks, error)-> Void in
                if error != nil{
                    print("Reverse geocoder failed" + (error?.localizedDescription)!)
                    return
                }
            
                var currentAddress = ""
                if (placemarks?.count)! > 0 {
                    let firstPlaceMark = placemarks?[0] as! CLPlacemark
                    if let locationName = firstPlaceMark.name {
                        currentAddress.append(locationName)
                    }
                    if let street = firstPlaceMark.subThoroughfare {
                        currentAddress.append(", \(street)")
                    }
                    if let city = firstPlaceMark.locality{
                        currentAddress.append(", \(city)")
                    }
                    if let country = firstPlaceMark.country {
                       currentAddress.append(", \(country)")
                    }
                }
                completeion(currentAddress)
            })
        }
    }
    
    //convert string address to latitude and longitude
    func addressToCoordinate(address : String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address, completionHandler: { (placermks,error)->Void in
            if  error != nil {
                self.showAlert(withTitle: "Oops", message: "Unable to find the address")
                print("Unable to find the address! (\(String(describing: error))")
                return
            }
            else  if  (placermks?.count)! > 0 {
                if let thisLocation = placermks?.first?.location {
                    self.longitude = thisLocation.coordinate.longitude
                    print("\(self.longitude!)")
                    self.latitude = thisLocation.coordinate.latitude
                    print("\(self.latitude!)")
                }
            }
        })
    }
    
    //MARK: location trigger notification
    func createLocationBasedTrigger(currentLatitude : Double, currentLongitude : Double ){
        //1. create and configure contification content object
        print("step 1 ..create content.")
        let content = UNMutableNotificationContent()
        content.title = "Location Notification!"
        content.body = "You have left your baby fish and fish tanks. Do not forget to close the lighting for the sake of their health"
        content.sound = UNNotificationSound.default()
        content.launchImageName = "attention"
        
        print("step 2 ..create monitoring location.")
        //create monitoring location
        let homeLocation = CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude)
        let region = CLCircularRegion(center: homeLocation, radius: 200, identifier: "homeLocation")
        region.notifyOnExit = true
        region.notifyOnEntry = false
        
        print("step 3 ..create location trigger.")
        //create trigger
        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
        
        
        print("step 4 ..create request.")
        //create request
        let request = UNNotificationRequest(identifier: "locationNotification", content: content, trigger: trigger)
        
        //add to center
        print("step 5 ..remove all pending and add to center.")
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["locationNotification"])
        center.removeAllDeliveredNotifications()
        center.add(request){ (error) in
            print("\(error)")
        }
        print("add location notification success")
    }
    
    func configureLocationManager(){
            locationManager.requestAlwaysAuthorization()
            locationManager.delegate = self
            locationManager.distanceFilter = 20
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            print("location manager start updating location ok ")
    }
    //create device list for sending to show in the detail screen
    func createDeviceList(thisTank : FishTank) -> [Device]{
        let deviceList  = [
            Device(name: "Lighting", icon: thisTank.lightingState == "On" ? #imageLiteral(resourceName: "lighting_white") : #imageLiteral(resourceName: "lighting"), state: thisTank.lightingState),
            Device(name: "Pumping", icon: thisTank.pumpingState == "On" ? #imageLiteral(resourceName: "pumpingWhite") : #imageLiteral(resourceName: "pumping"), state: thisTank.pumpingState),
            Device(name: self.selectSensorName == "" ? "Unknown" : self.selectSensorName, icon: selectTank!.sensorId != "Unknown" ?  #imageLiteral(resourceName: "sensorWhite") : #imageLiteral(resourceName: "sensor"), state: thisTank.sensorId != "Unknown" ? "OK" : "NO")
        ]
        return deviceList
    }
    
    // MARK: - Navigation : give self delegate for destination
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "seeTankDetail"{
            let destination = segue.destination as! TankDetailTableViewController
                destination.thisFishTank = selectTank
                destination.deviceList = self.createDeviceList(thisTank: selectTank!)
                print("send tank success")
        }
    }
 }
