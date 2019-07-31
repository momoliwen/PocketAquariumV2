//
//  SensorListTableViewController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 16/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

class SensorListTableViewController: UITableViewController,UITextFieldDelegate {
  
    var existingSensorList = [SensorDevice]()
    var selectSensor : SensorDevice?
    var selectSensorDelegate : EditFishTankDelegate?
    var selectSensorFromAddTankDelegate : AddNewTankSettingDelegate?
    
    //firebase reference
    private var sensorsRef = Database.database().reference().child("sensors")
    private var sensorsHandler : DatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observeSensors()
    }
    
    //MARK: firebase observe the sensor node
    private func observeSensors(){
        InitialSensorManager.observeSensors(completion: { (sensor) in
            self.existingSensorList.append(sensor)
            self.tableView.reloadData()
        })
    }
    
    deinit {
        if let refHandle = sensorsHandler {
            sensorsRef.removeObserver(withHandle: refHandle)
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.existingSensorList.count
    }

    //show the sensor name for each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sensorCell", for: indexPath)
        let theSensor = existingSensorList[indexPath.row]
        
        cell.detailTextLabel?.text = theSensor.sensorId
        cell.textLabel?.text = theSensor.name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectSensor = self.existingSensorList[indexPath.row]
        self.alertEnterSensorPin()
    }
    
    //MARK: alert user to enter the pin to activate the sensor.
    func alertEnterSensorPin(){
        let alert = UIAlertController(title: "Pin Enter",
                                      message: "Enter 4 digit pin of the matching sensor",
                                      preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
            
            let pinTextField = alert.textFields![0]
            
            guard let pinInput = Int(pinTextField.text!)  else{
                self.showAlert(withTitle: "Error", message: "Please enter the pin")
                return
            }
            //if input correct pin, go back
            if pinInput == self.selectSensor!.pin {
                
                if self.selectSensorDelegate != nil {
                   self.selectSensorDelegate!.selectNewSensor(newSensor: self.selectSensor!)
                   self.navigationController?.popViewController(animated: true)
                }
                
                if self.selectSensorFromAddTankDelegate != nil {
                   self.selectSensorFromAddTankDelegate!.selectSensor(newSensor: self.selectSensor!)
                   self.navigationController?.popViewController(animated: true)
                }
            }
            else{
                self.showAlert(withTitle: "Error", message: "Pin is not right")
                return
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel)
        alert.addTextField { pinTextField in
            pinTextField.placeholder = "Enter your sensor pin"
        }
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
