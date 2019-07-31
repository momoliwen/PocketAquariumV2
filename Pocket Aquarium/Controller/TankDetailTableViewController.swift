//
//  TankDetailTableViewController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 23/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

protocol EditFishTankDelegate {
    func updateFishMaxNumber(newMaxNumber : Int)
    func updateTankEnvironmentDelegate(thisTank : FishTank?)
    func addFishToTank(newFish : Fish, setFishNumber : Int)
    func editFishNumberInList(thisFish : Fish)
    func selectNewSensor(newSensor : SensorDevice)
}

class TankDetailTableViewController: UITableViewController,UICollectionViewDelegate, UICollectionViewDataSource,EditFishTankDelegate, UIGestureRecognizerDelegate {

    //Section0: fish tank name label and  water current environment
    @IBOutlet weak var tankNameLabel: UILabel!
    @IBOutlet weak var currentPhLabel: UILabel!
    @IBOutlet weak var currentTempLabel: UILabel!
    @IBOutlet weak var currentState: UILabel!
    @IBOutlet weak var desiredTempLabel: UILabel!
    @IBOutlet weak var desiredPhLabel: UILabel!
    @IBOutlet weak var addFishButton: UIButton!
    @IBOutlet weak var tankBgView: UIView!
    @IBOutlet weak var currentStateLabel: UILabel!
    
    //notification handler
    var appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    //realtime db ref
    var realTimeRef : DatabaseReference?
    var realtimeRefHandle: DatabaseHandle?
    var thisFishTank : FishTank?{
        didSet{
            if let thisTank = thisFishTank{
                self.tankRef = userRef.child("tanks").child("\(thisTank.tankId)")
                self.tankTaskRef = Database.database().reference().child("historyTaskList").child("\(thisTank.tankId)")
                print("\(tankTaskRef)")
            }
        }
    }
    
    //Section1: fish member group
    @IBOutlet weak var currentFishNumberLabel: UILabel!
    @IBOutlet weak var fishCollectionView: UICollectionView!
    
    var fishList = [Fish]() {
        didSet {
           self.currentFishNumberLabel.text = "Fish Members (\(self.fishList.count) / max: \(self.thisFishTank!.fishMaxNumber!))"
        }
        willSet{
            self.currentFishNumberLabel.text = "Fish Members (\(self.fishList.count) / max: \(self.thisFishTank!.fishMaxNumber!))"
        }
    }
    
    //Section2:
    @IBOutlet weak var deviceCollectionView: UICollectionView!
    var deviceList = [Device]()
    var selecteSensor : SensorDevice?
    var selectCellIndex : IndexPath?
    
    //Section3: task pending number
    @IBOutlet weak var taskPendingLabel: UILabel!
    var pendingNumber = 0

    //firebase reference
    var userId = Auth.auth().currentUser?.uid
    lazy var userRef = Database.database().reference().child("uid").child(userId!)
    lazy var userFishRef = self.userRef.child("fishes")
    var tankRef : DatabaseReference?
    var fishsRef : DatabaseReference?
    var fishRefHandler : DatabaseHandle?
    var tankTaskRef : DatabaseReference?
    var taskRef = Database.database().reference().child("tasks")
    var taskIdList : [String]?
    

    //calss initializer
    required init?(coder aDecoder: NSCoder) {
        realTimeRef = Database.database().reference().child("Realtime").child("\(self.userId!)")
        super.init(coder: aDecoder)
    }
    
    //class deinitializer
    deinit{
        if let thisFishRefHandler = fishRefHandler{
            self.fishsRef?.removeObserver(withHandle: thisFishRefHandler)
        }
        
        if let thisRealTimeHandle = self.realtimeRefHandle {
             self.realTimeRef?.removeObserver(withHandle: thisRealTimeHandle)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fishCollectionView.dataSource = self
        self.fishCollectionView.delegate = self
        self.deviceCollectionView.delegate = self
        self.deviceCollectionView.dataSource = self
      
        //configure UI
        addFishButton.addShadow()
        
        //add fish collection view long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressOnFishCell(gestureReconizer:)))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delaysTouchesBegan = true
        self.fishCollectionView.addGestureRecognizer(longPressGesture)
        
        //fishes node add fishid
        if let thisTankRef = tankRef{
            self.fishsRef = thisTankRef.child("fishMembers")
            print("tank's fishmembers  node is \(fishsRef!)")
        }
    
        if let thisTank = self.thisFishTank{
            showSelectTankDetail(selectTank: thisTank)
            //observe realtime value
            observeRealTimeValue()
        }
  
        print("start observe tank fish member in view did load")
        observeTankFishMembers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.selecteSensor != nil, let index = self.selectCellIndex {
            let cell = self.deviceCollectionView.cellForItem(at: index) as! DeviceCollectionViewCell
                cell.deviceStateLabel.text = "OK"
                cell.deviceNameLabel.text = "\(selecteSensor!.name)"
                configureDeviceCellView(cell: cell, state: selecteSensor!.sensorId)
        }
        
        self.pendingNumber = 0
        //update pending  task number
        self.observePendingTaskNumber(completion: { number in
            self.pendingNumber += number
            self.taskPendingLabel.text = "Pending task number: \(self.pendingNumber)"
            self.taskPendingLabel.textColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        })
        //observe fish removed if table view delete =
        observeTankFishRemoved()
    }
    //update the current fish type number after load all fish
    override  func viewDidAppear(_ animated: Bool) {
        self.currentFishNumberLabel.text = "Fish Members (\(self.fishList.count) / max: \(self.thisFishTank!.fishMaxNumber!))"
    }
    
    //MARK: - Firebase observation for fish list in the tank
    func observeTankFishMembers(){
        if self.fishsRef != nil{
            fishRefHandler = self.fishsRef!.observe(.childAdded, with: {(snapshot) -> Void in
                print(snapshot)
                if let thisFish = Fish(snapshot: snapshot, uid: self.userId!){
                    self.fishList.append(thisFish)
                    print("after observe fish member ref childadded, fish list count: \(self.fishList.count)")
                    self.fishCollectionView.reloadData()
                }
            })
        }
    }
    
    //MARK: - Firebase observation for fish remove
    func observeTankFishRemoved(){
       if self.fishsRef != nil{
            self.fishsRef!.observeSingleEvent(of: .childRemoved, with:  {(snapshot) -> Void in
                print(snapshot)
                if let thisFish = Fish(snapshot: snapshot, uid: self.userId!){
                    if let index = self.fishList.index(where:{
                        $0.fishId == thisFish.fishId
                    }).flatMap({
                        IndexPath(row: $0, section: 0)
                    }){
                        self.fishList.remove(at: index.row)
                    }
                    print("after observe fish member ref child removed, fish list count: \(self.fishList.count)")
                    self.fishCollectionView.reloadData()
                }
            })
        }
    }
    
    //MARK: updated fish number in table view delegate
    func editFishNumberInList(thisFish : Fish){
        if let index = self.fishList.index(where:{
            $0.fishId == thisFish.fishId
        }).flatMap({
            IndexPath(row: $0, section: 0)
        }){
            let targetFishCell = self.fishCollectionView.cellForItem(at: index) as! FishCollectionViewCell
            targetFishCell.fishNumberLabel.text = "Number:\(thisFish.fishNumber)"
        }
    }
    
    //MARK : show the realtime value
    func showRealTimeDetail(selectTank : FishTank){
        self.currentPhLabel.text = "\(selectTank.currentpH!)"
        self.currentTempLabel.text = "\(selectTank.currentTemp!)"
        self.tankBgView.backgroundColor = selectTank.currentColor!
        self.currentStateLabel.text = selectTank.state
    }
    
    //MARK: show the select tank
    func showSelectTankDetail(selectTank : FishTank){
        //show fish tank name
       self.tankNameLabel.text = selectTank.tankName
        //show tank water environment
       self.desiredPhLabel.text = "min/max \(selectTank.desiredMinpH)/\(selectTank.desiredMaxpH)"
       self.desiredTempLabel.text = "min/max \(selectTank.desiredMinTemp)℃/\(selectTank.desiredMaxTemp)℃"
       self.showRealTimeDetail(selectTank: selectTank)
    }

    //MARK: Compute the pending task number
    func observePendingTaskNumber(completion: @escaping(Int)-> Void){
        InitialTaskManager.observeTaskIdList(completion: { id in
            if self.tankTaskRef != nil {
                let taskQuery = self.tankTaskRef!.child(id).queryOrdered(byChild: "taskState").queryEqual(toValue: false)
                taskQuery.observeSingleEvent(of: .value, with: {(snapshot) in
                    let number = snapshot.childrenCount
                    completion (Int(number))
                })
            }
        })
    }
    
    //MARK: - Firebase observation: Retrieve current sensor vlaue,assume only one device
    private func observeRealTimeValue(){
        let today = Date()
        let queryDate = today.toMatchRealTimeDate(date: today)
        let realTimeQuery = self.realTimeRef!.child("\(queryDate)").queryLimited(toLast: 10)
        print("start to download realtime data ..  reference: \(realTimeQuery)")
        
        self.realtimeRefHandle = realTimeQuery.observe(.childAdded, with: {(snapshot) in
            print(snapshot)
            if let realTimeItem = RealTimeValues(snapshot: snapshot){
                print("success convert to Realtime values")
                if let tank = self.thisFishTank {
                    if realTimeItem.sensorId == tank.sensorId{
                        tank.currentpH = realTimeItem.currentPh
                        tank.currentTemp = realTimeItem.currentTemp
                        tank.currentColor = UIColor(red: CGFloat(realTimeItem.currentRed/256)/255, green: CGFloat(realTimeItem.currentGreen/256)/255, blue: CGFloat(realTimeItem.currentBlue/256)/255, alpha: 0.8 )
                        self.calculateCurrentState(thisTank: tank, currentTemp: tank.currentTemp!, currentPh:  tank.currentpH!)
                        self.showRealTimeDetail(selectTank: tank)
                        print("success to add realtime to tank")
                    }
                }
            }
        })
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

    //MARK: - Edit fish tank components
    //1. update fish max number delegate
    func updateFishMaxNumber(newMaxNumber: Int) {
        //calculate valid number
        if let thisTankRef = self.tankRef {
            thisTankRef.updateChildValues(["maxFishNum" : newMaxNumber])
            self.thisFishTank?.fishMaxNumber = newMaxNumber
            //show fish list
            self.currentFishNumberLabel.text = "Fish Members (\(fishList.count)/max: \(newMaxNumber))"
        }
    }
    
    //2.update water environment delegate
    func updateTankEnvironmentDelegate(thisTank : FishTank?){
        if let thisTankRef = self.tankRef, let updatedTank = thisTank{
            self.thisFishTank  =  updatedTank
            thisTankRef.updateChildValues(
                ["minTemp" : thisFishTank!.desiredMinTemp,
                 "maxTemp" : thisFishTank!.desiredMaxTemp,
                 "minpH" : thisFishTank!.desiredMinpH,
                 "maxpH" : thisFishTank!.desiredMaxpH
                  ])
            print("update 4 desired valeus in firebase complete... ")
            //update label
            self.desiredPhLabel.text = "min/max \(self.thisFishTank!.desiredMinpH)/\(thisFishTank!.desiredMaxpH)"
            self.desiredTempLabel.text = "min/max \(thisFishTank!.desiredMinTemp)℃/\(thisFishTank!.desiredMaxTemp)℃"
        }
    }
    
    //3. add fish to tank delegate
    func addFishToTank(newFish: Fish, setFishNumber : Int) {
        if let thisTankRef = self.tankRef {
            let newFishMemberRef = thisTankRef.child("fishMembers").child(newFish.fishId)
            newFishMemberRef.setValue(newFish.toFishMemberObject())
            newFishMemberRef.updateChildValues(
                ["fishInTankNumber": setFishNumber]
            )
           // self.fishList.append(newFish)
            //print("after add new fish, fishlist.count == (\(fishList.count))")
            self.currentFishNumberLabel.text = "Fish Members (\(fishList.count) / max: \(self.thisFishTank!.fishMaxNumber!))"
            //self.fishCollectionView.reloadData()
        }
    }
    
    //MARK : Add fish to the tank
    @IBAction func addFishToTank(_ sender: UIButton) {
        //check button can be use or not
        if self.fishList.count >= self.thisFishTank!.fishMaxNumber! {
            showAlertForMaxiMumFish()
        }
        showAddFishChoice()
    }
    
    //MARK: edit sensor delegate
    func selectNewSensor(newSensor: SensorDevice) {
        self.selecteSensor = newSensor
        //update firebase of sensorId child
        self.updateDeviceState(updateKey: "sensorId", updateValue: selecteSensor?.sensorId ?? "Unknown")
    }
    
    //MARK: show add fish choices action sheet
    func showAddFishChoice(){
        let addFishActionFish = UIAlertController(title: "Add Fish to this Fishtank", message: nil, preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let addNewFish = UIAlertAction(title: "Add New Fish", style: UIAlertActionStyle.default, handler: { action in
            // go to add new fish screen
            self.performSegue(withIdentifier: "addNewFishToTank", sender: self)
        })
        let addNewFishFromRepository = UIAlertAction(title: "Add from your Fish Repository", style: UIAlertActionStyle.default, handler: { action in
            // go to add fish repository
            self.performSegue(withIdentifier: "chooseFromFishMembers", sender: self)
        })
        addFishActionFish.addAction(addNewFish)
        addFishActionFish.addAction(addNewFishFromRepository)
        addFishActionFish.addAction(cancel)
        present(addFishActionFish, animated: true, completion: nil)
    }
    
    //MARK: warning if current fish number is greater than or equal to the maximum number
    func showAlertForMaxiMumFish(){
        let alert = UIAlertController(title: "Warning", message: "Your existing fish number have been achieved the maximum", preferredStyle: UIAlertControllerStyle.alert)
        let cancel = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: { action in
            self.showAddFishChoice()
        })
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    
    
    //MARK: - Fish and device  Collection view data source
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == fishCollectionView{
            print("fish list count == (\(self.fishList.count))")
            return self.fishList.count
        }
        else if collectionView == deviceCollectionView {
            if deviceList.count != 0 {
                return self.deviceList.count
            }
        }
        return 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // Configure  2 groups of collection view cell content
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //configure fish cell
        if collectionView == fishCollectionView {
            print("Attempting fish cell...")
            let fishCell = collectionView.dequeueReusableCell(withReuseIdentifier: "fishCollectionCell", for: indexPath) as! FishCollectionViewCell
            fishCell.fishIconImage.roundedImageView()
            if fishList.count != 0 {
                let thisFish : Fish? = self.fishList[indexPath.row]
                let fishIconName = thisFish!.fishIconName
                    //if icon name is fish, get the image from the object. else get the image from local
                if fishIconName == "fish"{
                    fishCell.fishIconImage.image = thisFish!.fishIcon.image
                }else{
                    fishCell.fishIconImage.image = UIImage(named: fishIconName)
                }
                fishCell.fishNameLabel.text = thisFish!.fishName
                fishCell.fishNumberLabel.text = "Number:\(thisFish!.fishNumber)"
                return fishCell
            }
             return fishCell
        }
            
        //configure device cell
        else {
            print("Attempting device cell...")
            let deviceCell = collectionView.dequeueReusableCell(withReuseIdentifier: "devicesCollectionCell", for: indexPath) as! DeviceCollectionViewCell
           
            if deviceList.count > 0 {
                var selectDevice = deviceList[indexPath.row]
                let theState = selectDevice.state
                print(theState)
             
                deviceCell.deviceIcon.image = selectDevice.icon
                //label configure
                deviceCell.deviceStateLabel.text = theState
                deviceCell.deviceNameLabel.text = selectDevice.name
                
                self.configureDeviceCellView(cell: deviceCell, state: theState)
                return deviceCell
            }
            return deviceCell
        }
        
    }

    //MARK: - Collection view delegate for device collection view
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == deviceCollectionView{
            print("did select device cell, Attempt chaging device state ... ")
            
            let cell = collectionView.cellForItem(at: indexPath) as! DeviceCollectionViewCell
            var selectDevice = deviceList[indexPath.row]
            if let currentState = cell.deviceStateLabel.text  {
                if currentState == "On" {
                    cell.deviceStateLabel.text = "Off"
                    configureDeviceCellView(cell: cell, state: "Off")
                    self.updateDeviceState(updateKey: selectDevice.name, updateValue: "Off")
                }
                else if currentState == "Off"{
                    cell.deviceStateLabel.text = "On"
                    configureDeviceCellView(cell: cell, state: "On")
                     self.updateDeviceState(updateKey: selectDevice.name, updateValue: "On")
                }
                else{
                    if self.thisFishTank!.sensorId != "Unknown" {
                        showAlertForChangingSensor(cell: cell)
                    }
                    else{
                        showActionSheet(cell: cell)
                    }
                    //showAlertForChangingSensor(cell: cell)
                   self.selectCellIndex = indexPath
                }
            }
        }
    }
    
    //MARK: Query for a specific sensor data that the tank use now
    func deleteTankSensorData(thisTank:  FishTank){
        let sensorId = thisTank.sensorId
        self.realTimeRef!.observeSingleEvent(of: .value, with: {(snapshot) in
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

    }
    
    //MARK: alert if user already have sensors, and want to change the sensor, app will delete the sensor data
    func showAlertForChangingSensor(cell: DeviceCollectionViewCell){
        let actionSheet = UIAlertController(title: "Attention!!", message: "If you choose continue, all the previous sensor data will be gone! ", preferredStyle: .alert)
        
        let continueAction = UIAlertAction(title: "Continue", style: .default, handler: { action in
            // delete sensor data related to the tank
            self.deleteTankSensorData(thisTank: self.thisFishTank!)
            //update ui view for none state
            cell.deviceStateLabel.text = "No"
            cell.deviceNameLabel.text = "Unknown"
            self.thisFishTank?.sensorId = "Unknown"
            //update firebase sensorId to Unknown
            self.updateDeviceState(updateKey: "sensorId", updateValue: "Unknown")
            self.configureDeviceCellView(cell: cell, state: "Off")
            
            //show select new sensor
            self.showActionSheet(cell: cell)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(continueAction)
        actionSheet.addAction(cancel)
        present(actionSheet, animated: true, completion: nil)
    }
    
    //MARK: - Show sensor operation action sheet
    func showActionSheet(cell : DeviceCollectionViewCell){
        let actionSheet = UIAlertController(title: "Sensors Operation", message: nil, preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let select = UIAlertAction(title: "Select sensor", style: .default, handler: {action in

            //navigation to select a sensor
            self.performSegue(withIdentifier: "selectSensor", sender: self)
        })
        
        actionSheet.addAction(select)
       // actionSheet.addAction(switchOff)
        actionSheet.addAction(cancel)
        present(actionSheet, animated: true, completion: nil)
    }
    

    //MARK: update firebase on device state
    func updateDeviceState (updateKey : String , updateValue : String){
        if let thisTankRef = self.tankRef {
            switch updateKey{
            case "Lighting":
                 thisTankRef.child("lightingState").setValue(updateValue)
                 print("update firebase lightingState to \(updateValue) ")
            case "Pumping":
                thisTankRef.child("pumpingState").setValue(updateValue)
                print("update firebase pumpingState to \(updateValue) ")
            default:
                thisTankRef.child("sensorId").setValue(updateValue)
                print("update firebase sensorId to \(updateValue) ")
            }
        }
    }
    
    //configure device collcetion view cell based on the device state
    func configureDeviceCellView(cell : DeviceCollectionViewCell, state: String) {
        if state == "On" {
            //background
            cell.backgroundColor = #colorLiteral(red: 0.1921568627, green: 0.6666666667, blue: 1, alpha: 1)
            cell.layer.borderColor = #colorLiteral(red: 0.1921568627, green: 0.6666666667, blue: 1, alpha: 1)
            cell.layer.borderWidth = 2
            // image tint
            cell.deviceIcon.tintColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
            //label
            cell.deviceNameLabel.textColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
            cell.deviceStateLabel.textColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
            
        }else if state == "Off" || state == "NO" {
            cell.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            cell.layer.borderColor = #colorLiteral(red: 0.1921568627, green: 0.6666666667, blue: 1, alpha: 1)
            cell.layer.borderWidth = 2
            //image tint
            cell.deviceIcon.tintColor = #colorLiteral(red: 0.1921568627, green: 0.6666666667, blue: 1, alpha: 1)
            //label
            cell.deviceNameLabel.textColor = #colorLiteral(red: 0.1921568627, green: 0.6666666667, blue: 1, alpha: 1)
            cell.deviceStateLabel.textColor = #colorLiteral(red: 0.1921568627, green: 0.6666666667, blue: 1, alpha: 1)
        }else {
            //background
            cell.backgroundColor = #colorLiteral(red: 0.1921568627, green: 0.6666666667, blue: 1, alpha: 1)
            cell.layer.borderColor = #colorLiteral(red: 0.1921568627, green: 0.6666666667, blue: 1, alpha: 1)
            cell.layer.borderWidth = 2
            // image tint
            cell.deviceIcon.tintColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
            //label
            cell.deviceNameLabel.textColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
            cell.deviceStateLabel.textColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        }
    }
    
    //MARK: edit fish number or delete fish from the tank
    //long press on cell --> Reference
    @objc func longPressOnFishCell(gestureReconizer : UILongPressGestureRecognizer){
        if gestureReconizer.state != UIGestureRecognizerState.ended{
            return
        }
        let pressPoint = gestureReconizer.location(in: self.fishCollectionView)
        let selectIndexPath = self.fishCollectionView.indexPathForItem(at: pressPoint)
        if let indexPath = selectIndexPath {
            var cell = self.fishCollectionView.cellForItem(at: indexPath) as! FishCollectionViewCell
            print(indexPath.row)
            let fish = self.fishList[indexPath.item]
            self.editOrDeleteFishAction(theIndexPath : indexPath)
        }else{
            print("could not find index path")
        }
    }
    
    //MARK: Edit or delete fish from the tank
    func editOrDeleteFishAction(theIndexPath : IndexPath){
        let alert = UIAlertController(title: "Edit Fish number",
                                      message: "Enter the fish number you want edit",
                                      preferredStyle: .alert)
        alert.addTextField { textFishNumber in
            textFishNumber.placeholder =
            "if 0, fish will be removed"
            let editAction = UIAlertAction(title: "Edit", style: .default) { _ in
                let fishNumberField = alert.textFields![0]
                guard let fishNumber = fishNumberField.text else{
                    self.displayErrorMessage(message: "Input Error", title: "Input Error")
                    return
                }
                
                if let number = Int(fishNumber) {
                    let fish = self.fishList[theIndexPath.item]
                    if number > 0 {
                        fish.fishNumber = number
                        
                        print("save to the fishmembers node...")
                        
                        //update tank fish value
                        fish.ref!.updateChildValues([
                                    "fishNumber" : number
                            ])
                        
                        //update  fish repository value
                        self.userFishRef.child("\(fish.fishId)").updateChildValues([
                            "fishNumber" : number
                            ])

                        //update fish repository value
                        /*
                        var existingNum = 0
                        self.userFishRef.child("\(fish.fishId)").observeSingleEvent(of: .value, with: {(snpashot )in
                            if let value  = snpashot.value as? [String:Any]{
                                existingNum = value["fishNumber"] as! Int
                                
                                if number > existingNum {
                                    self.userFishRef.child("\(fish.fishId)").updateChildValues([
                                        "fishNumber" : number
                                        ])
                                }
                            }
                        })*/

                        var cell = self.fishCollectionView.cellForItem(at: theIndexPath) as! FishCollectionViewCell
                        cell.fishNumberLabel.text = "Number:\(fish.fishNumber)"

                        self.autoDismissSuccessEditAlert(message: "Completed to edit the number of \(fish.fishName) to \(number)", title: "Success")
                    }
                    else if number == 0{
                        self.alertDeleteFishFromTank(index: theIndexPath, fish: fish)
                    }
                    else{
                        self.displayErrorMessage(message: "Input number should greater than or equal to 0", title: "Error")
                    }
                }else{
                    self.displayErrorMessage(message: "Input error", title: "Input should be a positive number")
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(editAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: delete firsh from the tank
    func alertDeleteFishFromTank(index : IndexPath, fish: Fish){
        let alertController = UIAlertController(title: "Warning", message: "Do you really want to delete this fish from the tank? ", preferredStyle: .alert)
        
        let confirm = UIAlertAction(title: "YES", style: .default) { (action:UIAlertAction) in
            let thisFishRef = fish.ref!
            print(thisFishRef)
            thisFishRef.removeValue()
            
            //update fish repository number to 0
            
            //update fish repository value
            self.userFishRef.child("\(fish.fishId)").updateChildValues([
                "fishNumber" :  0
            ])
            
            print("firebase remove this fish from the tank and change the fish number to 0 ok")
            self.fishList.remove(at: index.item)
            self.fishCollectionView.reloadData()
        }
        let cancel = UIAlertAction(title: "NO", style: .cancel) { (action:UIAlertAction) in
            print("you have cancled this fish node")
        }
        alertController.addAction(cancel)
        alertController.addAction(confirm)
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: error handler
    func displayErrorMessage(message:String,title:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    

    //MARK: feedback handler
    func autoDismissSuccessEditAlert(message:String, title:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alert,animated: true, completion: nil)
        //change to desired number of seconds
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            alert.dismiss(animated: true, completion: nil)
        }
    }

    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        //go to Fish Setting
        if segue.identifier == "saveFishSetting"{
            let destinationVc = segue.destination as! PopUpFishSettingViewController
            destinationVc.editMaxNumberDelegate = self
            destinationVc.receivedNumber = thisFishTank?.fishMaxNumber
            destinationVc.currentFishNumber = self.fishList.count
        }
        // go to Water setting
        if segue.identifier == "editTankWater"{
            let destiNaviVc = segue.destination as! UINavigationController
            let destinationVc  = destiNaviVc.viewControllers.first as! SetEnvironmentViewController
            destinationVc.selectedTank = self.thisFishTank
            destinationVc.editTankEnvironmentDelegate = self
        }
        
        if segue.identifier == "addNewFishToTank"{
            let destiNaviVc = segue.destination as! UINavigationController
            let destinationVc  = destiNaviVc.viewControllers.first as! AddFishViewController
            destinationVc.addNewFishToTankDelegate = self
            destinationVc.receivedFishTank = self.thisFishTank
        }
        
        if segue.identifier == "chooseFromFishMembers"{
            let destinationVc = segue.destination as! FishMembersCollectionViewController
            destinationVc.thisTank = self.thisFishTank
        }
        
        if segue.identifier == "seeListOfFish" {
            let destinationVc = segue.destination as!  CurrentFishListViewController
            destinationVc.fishList = self.fishList
            destinationVc.editFishNubmerDelegate = self
        }
        
        if segue.identifier == "viewMaintenance" {
            let destinationVc = segue.destination as!  TrackMaintenanceViewController
            destinationVc.thisTank = self.thisFishTank
        }
        
        if segue.identifier == "selectSensor"{
            let destinationVc = segue.destination as!  SensorListTableViewController
            destinationVc.selectSensorDelegate = self
        }
    }
    
    //Mark: configure table view footer format
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let footer = view as! UITableViewHeaderFooterView
        footer.textLabel?.textColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
        footer.textLabel?.font = UIFont(name: "Helvetica", size: 13)
        footer.textLabel?.text = "Tips: Long press on the fish member can edit number"
        footer.backgroundColor = .white
    }
}
