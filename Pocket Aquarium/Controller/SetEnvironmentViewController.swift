//
//  SetEnvironmentViewController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 16/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase


class SetEnvironmentViewController: UIViewController {
    
    @IBOutlet weak var minTempStepper: UIStepper!
    @IBOutlet weak var maxTempStepper: UIStepper!
    @IBOutlet weak var minTempLabel: UILabel!
    @IBOutlet weak var maxpHSlider: UISlider!
    @IBOutlet weak var minpHSlider: UISlider!
    @IBOutlet weak var maxTempLabel: UILabel!
    @IBOutlet weak var minpHLabel: UILabel!
    @IBOutlet weak var maxpHLabel: UILabel!
    var defaultMinNum = 20
    var defaultMaxNum = 30
    var roundedMinpH : Double = 5.0
    var roundedMaxpH : Double = 9.0
    
    //from add new tank vc delegate
    var addNewTankEnvironmentDelegate : AddNewTankSettingDelegate?
    var editTankEnvironmentDelegate :  EditFishTankDelegate?
    var selectedFish : Fish?
    
    //edit tank
    var selectedTank : FishTank?
    
    //db reference
    //get the userId
    let userID = Auth.auth().currentUser?.uid
    lazy var userRef = Database.database().reference().child("uid").child(userID!)
    lazy var fishRef = userRef.child("fishes")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        minpHSlider.minimumValue = 5.0
        minpHSlider.maximumValue = 7.0
        maxpHSlider.minimumValue = 7.0
        maxpHSlider.maximumValue = 9.0
        
        //set the default value of minTemp and maxTemp and show it in stepper
        minTempLabel.text = "\(String(defaultMinNum)) ℃"
        minTempStepper.value = Double(defaultMinNum)
        maxTempStepper.value = Double(defaultMaxNum)
        maxTempLabel.text = "\(String(defaultMaxNum)) ℃"
        
        print(selectedFish)
        if (selectedFish != nil){
            minTempStepper.value = Double((selectedFish?.fishMinTemp)!)
            maxTempStepper.value = Double((selectedFish?.fishMaxTemp)!)
            minTempLabel.text = "\(String((selectedFish?.fishMinTemp)!)) ℃"
            defaultMinNum = (selectedFish?.fishMinTemp)!
            maxTempLabel.text = "\(String((selectedFish?.fishMaxTemp)!)) ℃"
            defaultMaxNum = (selectedFish?.fishMaxTemp)!
            minpHLabel.text = String((selectedFish?.fishMinpH)!)
            maxpHLabel.text = String((selectedFish?.fishMaxpH)!)
            minpHSlider.value = Float((selectedFish?.fishMinpH)!)
            maxpHSlider.value = Float((selectedFish?.fishMaxpH)!)
        }
        
        if let thisTank = selectedTank {
            minTempStepper.value = Double(thisTank.desiredMinTemp)
            maxTempStepper.value = Double(thisTank.desiredMaxTemp)
            minTempLabel.text = "\(String(thisTank.desiredMinTemp)) ℃"
            maxTempLabel.text = "\(String(thisTank.desiredMaxTemp)) ℃"
            defaultMinNum = thisTank.desiredMinTemp
            defaultMaxNum = thisTank.desiredMaxTemp
            minpHLabel.text = String(thisTank.desiredMinpH)
            maxpHLabel.text = String(thisTank.desiredMaxpH)
            minpHSlider.value = Float(thisTank.desiredMinpH)
            maxpHSlider.value = Float(thisTank.desiredMaxpH)
        }
    }
    
    
    
    @IBAction func minpHSlider(_ sender: UISlider) {
        roundedMinpH = Double(sender.value)
        let roundedValue = String(format:"%.1f", roundedMinpH)
        minpHLabel.text = "\(roundedValue)"
    }
    
    @IBAction func maxpHSlider(_ sender: UISlider) {
        roundedMaxpH  = Double(sender.value)
        let roundedValue = String(format:"%.1f", roundedMaxpH)
        maxpHLabel.text = "\(roundedValue)"
    }
    
    
    @IBAction func minTempStepper(_ sender: UIStepper) {
        
        self.defaultMinNum = Int(sender.value)
        self.minTempLabel.text = "\(defaultMinNum)℃"
    }
    
    
    @IBAction func maxTempStepper(_ sender: UIStepper) {
        self.defaultMaxNum = Int(sender.value)
        self.maxTempLabel.text = "\(defaultMaxNum)℃"
    }
    
    
    //MARK: Navigation : dismiss the present VC
    @IBAction func cancelBtn(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Navigation : pass the value to the source VC
    @IBAction func saveBtn(_ sender: Any) {
        if addNewTankEnvironmentDelegate != nil {
            self.addNewTankEnvironmentDelegate!.addNewEnvironment(minTemp: defaultMinNum, maxTemp: defaultMaxNum, minpH: roundedMinpH, maxpH: roundedMaxpH)
            self.dismiss(animated: true, completion: nil)
        }
        if (selectedFish != nil){
        
            self.selectedFish?.fishMinTemp = (Int(minTempStepper.value))
            self.selectedFish?.fishMaxTemp = (Int(maxTempStepper.value))
            self.selectedFish?.fishMinpH = Double(self.minpHLabel.text!)!
            self.selectedFish?.fishMaxpH = Double(self.maxpHLabel.text!)!
            print (self.selectedFish as Any)

            self.fishRef.child(selectedFish!.fishId).updateChildValues(["fishMinTemp" : selectedFish?.fishMinTemp,"fishMaxTemp" : selectedFish?.fishMaxTemp,"fishMinpH" : selectedFish?.fishMinpH,"fishMaxpH" : selectedFish?.fishMaxpH])
            if let thisFishRef = selectedFish!.ref {
                thisFishRef.ref.updateChildValues(["fishMinTemp" : selectedFish!.fishMinTemp,"fishMaxTemp" : selectedFish!.fishMaxTemp,"fishMinpH" : selectedFish!.fishMinpH,"fishMaxpH" : selectedFish!.fishMaxpH])
                
            }
            displayFinishMessage(message: "Fish Updated!", title: "")
        }
        
        if  selectedTank != nil, editTankEnvironmentDelegate != nil {
            self.selectedTank?.desiredMinTemp = defaultMinNum
            self.selectedTank?.desiredMaxTemp = defaultMaxNum
            self.selectedTank?.desiredMinpH = roundedMinpH.roundTo(places: 1)
            self.selectedTank?.desiredMaxpH = roundedMaxpH.roundTo(places: 1)
            
         
            editTankEnvironmentDelegate?.updateTankEnvironmentDelegate(thisTank: selectedTank)
            displayFinishMessage(message: "FishTank Water Environment Updated!", title: "Fish Tank Update")
            
        }
        
    }
    
    //MARK:finish adding the fish dimiss the controller
    func displayFinishMessage(message:String,title:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: {action in
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
}
