//
//  AddNewTankController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 16/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

protocol AddNewTankSettingDelegate{
    func addNewEnvironment(minTemp:Int, maxTemp:Int, minpH:Double, maxpH:Double)
    func selectSensor(newSensor : SensorDevice)
   
}

class AddNewTankController: UITableViewController,UINavigationControllerDelegate,UITextFieldDelegate, AddNewTankSettingDelegate {
 

    //bind UI element
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var desiredEnvironmentLabel: UILabel!
    @IBOutlet weak var maxFishNumTextField: UITextField!
    @IBOutlet weak var selectedSensorLabel: UILabel!
    
    @IBOutlet weak var lightingSwitch: UISwitch!
    @IBOutlet weak var pumpingSwitch: UISwitch!
    //new fish tank object
    var newTank : FishTank?
    
    //store user default setting
    let defaults = UserDefaults.standard
    let lightingFixedState = "lightingFixedState"
    let pumpingFixedState = "pumpingFixedState"
    
    //devices setting
    var lightingState : String?
    var pumpingState : String?
    var selecteSensor = SensorDevice(id: "Unknown", name:"Unknown",pin : 0000)
    
    //environment setting
    var minTemp : Int = 0
    var maxTemp : Int = 0
    var minpH : Double = 5.0 {
        didSet{
            let roundedValue = minpH.roundTo(places: 1)
            minpH = roundedValue
        }
    }
    var maxpH : Double = 9.0{
        didSet{
            let roundedValue = maxpH.roundTo(places: 1)
            maxpH = roundedValue
        }
    }
    
    @IBOutlet weak var sensorInputTextField: UITextField!
    
    //environment feedback
    var desiredEnvironment : String? = "Select Desired pH and Temperature Range"
    
    //add fish max number
    var maxFishNumber : Int = 0{
        didSet{
            self.maxFishNumTextField.text = String(maxFishNumber)
        }
    }

    //firebase tankRef
    var userId = Auth.auth().currentUser?.uid
    lazy var userRef = Database.database().reference().child("uid").child(userId!)
    lazy var tankRef = userRef.child("tanks")
    
    var sensorsRef = Database.database().reference().child("Sensors")
    
    //hard code
   // var existingSensorList = [SensorDevice]()
    

    //initial view
    override func viewDidLoad() {
        super.viewDidLoad()
        //sensor picker configure
      //  self.createSensorPicker()
       // self.createToolBar()
        
        //observe sensor device value
        //observeSensorDevice()

        //set default value for switch
        if let lightingFixedState = defaults.value(forKey: lightingFixedState),
            let pumpingFixedState = defaults.value(forKey: pumpingFixedState){
            self.lightingSwitch.isOn = lightingFixedState as! Bool
            if  lightingSwitch.isOn == false{
                self.lightingState = "Off"
                print("lighting set off")
            }else if lightingSwitch.isOn == true{
                self.lightingState = "On"
                print("lighting set on")
            }
            
            self.pumpingSwitch.isOn = pumpingFixedState as! Bool
            if  pumpingSwitch.isOn == false{
                self.pumpingState = "Off"
                print("pumping set off")
            }
            else if pumpingSwitch.isOn == true{
                self.pumpingState = "On"
                print("pumping set On")
            }
            
        }
        print("set user defaults")
        self.nameTextField.delegate = self
        self.maxFishNumTextField.delegate = self
        self.maxFishNumTextField.text = "0"
    }
    
    //view will appear
    override func viewWillAppear(_ animated: Bool) {
       // show selected sensor name
        if self.selecteSensor != nil {
            self.selectedSensorLabel.text = selecteSensor.name
        }
        else{
             self.selectedSensorLabel.text = "Unknown"
        }
    }
    
    /*
    func observeSensorDevice(){
        InitialSensorManager.observeSensors(completion: { (sensor) in
            self.existingSensorList.append(sensor)
        })
    }*/
    
    //MARK: - TextField delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.nameTextField {
            self.nameTextField.becomeFirstResponder()
            return true
        }
        
        if textField == self.maxFishNumTextField {
            self.maxFishNumTextField.becomeFirstResponder()
            return true
        }
        return false
    }
    
    // limit the input to number for max fish number text field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.maxFishNumTextField {
            let numberSet = NSCharacterSet(charactersIn: "0123456789").inverted
            let compSep  = string.components(separatedBy: numberSet)
            let nubmerFiltered = compSep.joined(separator: "")
            return string == nubmerFiltered
        }
        return true
    }
    
    
    //MARK: Table View delegate
    //set cell height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0{
            return true
        }
        return false
    }
    
    

    //MARK: - validate input : tank name should less than 10
    func isValidInput() -> Bool{
        var errorMessage : String = "Name should be filled out"
        
        if let tankName = self.nameTextField.text?.trimmingCharacters(in: .whitespaces){
            if tankName.isEmpty == true {
                displayErrorMessage(message: errorMessage, title: "Error")
                return false
            }
            if tankName.count >= 10 {
                errorMessage = "Tank Name should be less than 10"
                displayErrorMessage(message: errorMessage, title: "Name error")
                return false
            }
        }
        return true
    }
    
    //MARK Switch lighting and air pumping
    @IBAction func lightingSwitch(_ sender: UISwitch) {
        
        defaults.set(sender.isOn, forKey:lightingFixedState)
        print("lighting state set Off")

        if sender.isOn{
            self.lightingState = "On"
            print("lighting state set On")
        }
        else {
            self.lightingState = "Off"
            print("lighting state set Off")
        }
       
    }
    
    @IBAction func pumpingSwitch(_ sender: UISwitch) {
    
        defaults.set(sender.isOn, forKey:pumpingFixedState)
        if sender.isOn{
            self.pumpingState = "On"
            print("pumping state set On")
        }
        else {
             self.pumpingState = "Off"
             print("pumping state set Off")
        }
    }
    
    //MARK: AddNewTankSettingDelegate
    func addNewEnvironment(minTemp: Int, maxTemp: Int, minpH: Double, maxpH: Double) {
        self.minTemp = minTemp
        self.maxTemp = maxTemp
        self.minpH = minpH
        self.maxpH = maxpH
        let roundedMinPh = String(format:"%.1f", minpH)
        let roundedMaxPh = String(format:"%.1f", maxpH)
        self.desiredEnvironment = "Temperature Range: \(minTemp)℃ ~ \(maxTemp)℃  pH Range: \(roundedMinPh)~\(roundedMaxPh)"
        self.desiredEnvironmentLabel.text = desiredEnvironment
    }
    
    func selectSensor(newSensor: SensorDevice) {
        self.selecteSensor = newSensor
    }
    
    //set max fish number
    @IBAction func setMaxFishNumber(_ sender: UIStepper) {
        let defaultMaxNum = Int(sender.value)
        self.maxFishNumTextField.text = "\(defaultMaxNum)"
    }
    
    //MARK: create the new fish tank
    @IBAction func createNewFishTank(_ sender: UIButton) {
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let stringToday = dateFormatter.string(from: today)
        if isValidInput(){
            let tankName = self.nameTextField.text!
            let currentFishNumber = Int (self.maxFishNumTextField.text!)
            
            //new tank node
            let newTankRef = self.tankRef.childByAutoId()
            let tankItem = [
                "tankId" : newTankRef.key!,
                 "createDate" : stringToday,
                "tankName" : tankName,
                "minTemp" : self.minTemp,
                "maxTemp" : self.maxTemp,
                "minpH" : self.minpH,
                "maxpH" : self.maxpH,
                "maxFishNum" : currentFishNumber!,
                "lightingState": self.lightingState!,
                "pumpingState" : self.pumpingState!,
                "sensorId" : selecteSensor.sensorId
                ] as [String : Any]
            
            //new tank value under the node
            newTankRef.setValue(tankItem)
            
            print("add tank  to firebase \(newTankRef.key) success")
            self.navigationController?.popViewController(animated: true)
        }
        else{
            print(" fail to add new tank  to firebase")
        }
    }
  
    //MARK: - error handler
    func displayErrorMessage(message:String,title:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    /*
    
    //MARK: Make sensor selection view
    func createSensorPicker(){
        let sensorPicker = UIPickerView()
        sensorPicker.dataSource = self
        sensorPicker.delegate = self
        //keyboard view pop up with sensor picker
        self.sensorInputTextField.inputView = sensorPicker
        sensorPicker.backgroundColor = .white
    }
    
    //MARK: show the existing sensor
    func createToolBar(){
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action:  #selector(AddNewTankController.dismissKeyboard))
        
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        self.sensorInputTextField.inputAccessoryView = toolBar
    }
    
    //MARK: keyboard selector used in createToolBar
    @objc func dismissKeyboard(){
        view.endEditing(true)
    }
    

    //MARK : Picker view data source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return existingSensorList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if existingSensorList.count > 0 {
            self.selecteSensor = existingSensorList[row]
            self.sensorInputTextField.text = selecteSensor.name
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return existingSensorList[row].name
    }*/
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //send self add new environment delegate to the destination vc
        if segue.identifier == "addNewEnvironment" {
            let addEnvironmentNaviVc = segue.destination as! UINavigationController
            let addEnvironmentVc = addEnvironmentNaviVc.viewControllers.first as! SetEnvironmentViewController
            addEnvironmentVc.addNewTankEnvironmentDelegate = self
        }
        
        if segue.identifier == "selectSensorWhenAddTank" {
            let destinationVc = segue.destination as! SensorListTableViewController
                destinationVc.selectSensorFromAddTankDelegate = self
        }
    }
    
    
    
    /*
    //MARK: Navigation unwind relationship: send selected sensor back from SensorListTableViewController
    @IBAction func unwindWithSelectSensor (segue : UIStoryboardSegue){
        if let sensorListController = segue.source as? SensorListTableViewController,
            let sensorFromList = sensorListController.selectSensor{
            self.selecteSensor = sensorFromList
        }
    }*/
    
    
  
}
