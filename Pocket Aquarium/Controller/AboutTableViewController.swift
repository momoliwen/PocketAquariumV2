//
//  AboutTableViewController.swift
//  Pocket Aquarium
//
//  Created by Sze Yan Kwok on 3/11/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

class AboutTableViewController: UITableViewController {
    
    @IBOutlet weak var emailLabel: UILabel!
    
    @IBOutlet weak var tankNoLabel: UILabel!
    
    @IBOutlet weak var fishNoLabel: UILabel!
    
    @IBOutlet weak var sensorNoLabel: UILabel!
    
    @IBOutlet weak var signOutBtnOutLet: UIButton!
    @IBOutlet weak var backgroundView: UIView!
    
    
    //userId
    let userID = Auth.auth().currentUser?.uid
    //Database Ref
    var userRef = Database.database().reference().child("uid")
    //list
    var fishNumber = 0
    var tankList = NSMutableArray()
    var sensorList = NSMutableArray()
    var fishIdList = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailLabel.text = Auth.auth().currentUser?.email
        observeFish()
        observeTank()
        observeSensor()
    
        self.signOutBtnOutLet.layer.cornerRadius = 10
        view.setGradientBackground(colorMain: #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1), colorSecond: #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1))
    }
    
    @IBAction func signOut(_ sender: Any) {
        do{
            try Auth.auth().signOut()
        }catch let logoutError{
            print(logoutError)
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let signVC = storyboard.instantiateViewController(withIdentifier: "AuthViewController")
        self.present(signVC, animated: true, completion: nil)
    }
    
    //MARK: calculate the number of fish types in fish repository
    private func observeFish() {
        let fishRef = userRef.child(userID! + "/fishes")
        fishRef.observe(.childAdded, with: {(snapshot)-> Void in
            //let fishData = snapshot.value as! Dictionary<String,AnyObject>
            let fishId = snapshot.key
            self.fishIdList.add(fishId)
            self.fishNoLabel.text = String(self.fishIdList.count)
        })
    }
    
    private func observeTank(){
        let tankRef = userRef.child(userID! + "/tanks")
        tankRef.observe(.childAdded, with: {(snapshot)-> Void in
            let tankId = snapshot.key
            self.tankList.add(tankId)
            self.tankNoLabel.text = String(self.tankList.count)
        })
    }
    
    private func observeSensor(){
        let tankRef = userRef.child(userID! + "/tanks")
        tankRef.observe(.childAdded, with: {(snapshot)-> Void in
            let tankData = snapshot.value as! Dictionary<String,AnyObject>
            let sensorId = tankData["sensorId"] as! String?
            if (sensorId != "Unknown") {
                self.sensorList.add(sensorId)
            }
            self.sensorNoLabel.text = String(self.sensorList.count)
        })
    }
    
    // only allow "Contact Support" is able to be selected
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row != 2 {
            cell.selectionStyle = .none
        }
    }
    
    
}
