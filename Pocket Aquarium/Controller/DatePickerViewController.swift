//
//  DatePickerViewController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 30/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit

class DatePickerViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var selectedDate : String?
    var selectDateTimeDelegate : EditCompletedDateDelegate?
    var selectRemindDateTimeDelegate : EditReminderDateDelegate?
    var resetReminderDelegate : EditReminderForTask?
    var dataStaticDelegate : ChooseTimeDateDelegate?
    
    var editedTask : Task?
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addShadowEffect()

        self.datePicker.datePickerMode = .dateAndTime
        self.datePicker.date = Date()
        self.datePicker.locale = Locale(identifier: "en_US_POSIX")
        print("\(Date())")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat =  "dd-MM-yyyy h:mm a"
        let date  = dateFormatter.string(from: Date())
        print("\(date)")
        self.selectedDate = date
        print("initial date picker select date : \(selectedDate!)")
        
        if self.selectDateTimeDelegate != nil{
             datePicker.maximumDate = NSDate() as Date
        }
        
        if self.selectRemindDateTimeDelegate != nil {
            datePicker.minimumDate = NSDate() as Date
        }
        
        datePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
    }
    
    func addShadowEffect(){
        backgroundView.layer.shadowRadius = 5
        backgroundView.layer.shadowOpacity = 0.4
        backgroundView.layer.shadowOffset = CGSize(width: 2, height: 3)
    }
    
    //MARK: date picker changed
    @objc func datePickerChanged(datePicker: UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy h:mm a"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        //convert date to string
        let thisDate = dateFormatter.string(from: datePicker.date)
        print("\(datePicker.date)")
        self.selectedDate = thisDate
    }
    //MARK: save date action with delegate action 
    @IBAction func saveDate(_ sender: UIButton) {
        if selectDateTimeDelegate != nil, let thisDate = self.selectedDate {
            self.selectDateTimeDelegate!.selectCompletedDateTime(selectDateTime: thisDate)
            print("select completed date is : \(selectedDate!)")
        }
        
        if self.selectRemindDateTimeDelegate != nil, let thisDate = self.selectedDate {
            self.selectRemindDateTimeDelegate?.selectRemindDateTime(selectDateTime: thisDate)
            print("selected reminder date is:  \(selectedDate!)")
        }
        if self.editedTask != nil, self.resetReminderDelegate != nil{
            if let newDateTime = self.selectedDate {
                resetReminderDelegate?.resetReminderForTask(newDate: newDateTime)
                print("selected reminder date is:  \(newDateTime)")
            }
        }
        
        if dataStaticDelegate != nil, let thisDate = self.selectedDate {
            let date = thisDate.toDate(stringDate: thisDate)
            self.dataStaticDelegate?.selectFilterDateTime(selectDateTime: date)
            print("selected reminder date is:  \(thisDate)")
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
