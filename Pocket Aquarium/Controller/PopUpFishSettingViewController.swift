//
//  PopUpFishSettingViewController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 26/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit

class PopUpFishSettingViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var maxiFishNumberTextField: UITextField!
    @IBOutlet weak var popupSettingFishView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    
    var newMaxFishNumber : Int?
    var currentFishNumber : Int?
    var receivedNumber : Int?
    var editMaxNumberDelegate : EditFishTankDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackgroundView()
        //customize pop up view
        popupSettingFishView.layer.cornerRadius = 20
        popupSettingFishView.layer.masksToBounds = true
        self.maxiFishNumberTextField.becomeFirstResponder()
        
        if let number = receivedNumber {
            maxiFishNumberTextField.text = "\(number)"
        }
    }
    
    func configureBackgroundView(){
        backgroundView.layer.shadowRadius = 5
        backgroundView.layer.shadowOpacity = 0.4
        backgroundView.layer.shadowOffset = CGSize(width: 2, height: 3)
    }
    
    @IBAction func cancelSetting(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: save the maximum fish category number for the tank
    @IBAction func saveSetting(_ sender: UIButton) {
        if let newMax = self.maxiFishNumberTextField.text {
            if let newNumber = Int (newMax), newNumber >= 0 {
                self.newMaxFishNumber = newNumber
                
                if let current = currentFishNumber {
                    if newMaxFishNumber! < current {
                        warningFishMaxNumber(newTitle: "Warning", newMessage: "Your current fish number is greater than the maximum capacity")
                    }
                }
                //update firebase
                self.editMaxNumberDelegate?.updateFishMaxNumber(newMaxNumber: newMaxFishNumber ?? receivedNumber!)
                print("update fish max number in firebase successfully...")
                self.dismiss(animated: true, completion: nil)
            }
            else{
                self.showAlert(withTitle: "Invalid input", message: "Please input a positive number")
            }
        
        }
    }
    
    //MARK: Alert of max number < current fish number
    func warningFishMaxNumber (newTitle:String , newMessage:String){
        let alertForFishNumber = UIAlertController(title: newTitle, message: newMessage, preferredStyle: UIAlertControllerStyle.alert)
        let confirm = UIAlertAction(title: "Continue", style: UIAlertActionStyle.cancel, handler: nil)
        alertForFishNumber.addAction(confirm)
        present(alertForFishNumber, animated : true,completion: nil)
    }

    
    
    // limit the input to number for max fish number text field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let numberSet = NSCharacterSet(charactersIn: "0123456789").inverted
        let compSep  = string.components(separatedBy: numberSet)
        let nubmerFiltered = compSep.joined(separator: "")
        return string == nubmerFiltered
        return true
    }
}
