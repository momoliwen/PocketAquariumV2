//
//  SelectTankTableViewController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 3/11/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

class SelectTankTableViewController: UITableViewController {
    //create users db reference
    var userId = Auth.auth().currentUser?.uid
    var userRef : DatabaseReference?
    var tankRef : DatabaseReference?

    var tankList = [FishTank]()
    private var tankRefHandle : DatabaseHandle?
   
    var selectTankDelegate : ChooseTimeDateDelegate? 

    required init?(coder aDecoder: NSCoder) {
        userRef = Database.database().reference().child("uid").child(userId!)
        tankRef = self.userRef!.child("tanks")
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observeFishTank(){ tank in
            self.tankList.append(tank)
            self.tableView.reloadData()
        }
    }
    
    //MARK - firebase observe tank
    func observeFishTank(completition: @escaping (FishTank)->Void){
        self.tankRefHandle = self.tankRef?.observe(.childAdded, with: {(snapshot) in
            print(snapshot)
            
            if let tank = FishTank(snapshot: snapshot){
                completition(tank)
            }
        })
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.tankList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tankCell", for: indexPath)
        let tankValue = self.tankList[indexPath.row]
        cell.textLabel!.text = tankValue.tankName
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectTank = self.tankList[indexPath.row]
        self.selectTankDelegate?.selectTankDelegate(selectTank: selectTank)
        self.navigationController?.popViewController(animated: true)
    }

   
}
