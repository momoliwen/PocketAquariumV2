//
//  DataStatisticViewController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 3/11/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

protocol ChooseTimeDateDelegate {
    func selectFilterDateTime (selectDateTime : Date)
    func selectTankDelegate (selectTank : FishTank)
}

class DataStatisticViewController: UIViewController,UITableViewDataSource, UITableViewDelegate , ChooseTimeDateDelegate {

    @IBOutlet weak var chooseDateBtn: UIButton!
    @IBOutlet weak var chooseFishTankBtn: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    
    var selectDate : String = "Choose a Date"
    var realTimeList : NSMutableArray
    var selectTank : FishTank?
    var defaultTank : FishTank?
    var defaultDate = { () -> String in
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let queryDate = yesterday!.toMatchRealTimeDate(date: yesterday!)
        return queryDate
    }()
    
    //db reference
    var userId = Auth.auth().currentUser?.uid
    var userRef : DatabaseReference
    var tankRef : DatabaseReference
    var realTimeRef : DatabaseReference
    var sensorRef = Database.database().reference().child("Sensors")
    var tankRefHandle : DatabaseHandle?
    var realtimeRefHandle : DatabaseHandle?
 
    required init?(coder aDecoder: NSCoder) {
        userRef = Database.database().reference().child("uid").child(userId!)
        tankRef = userRef.child("tanks")
        realTimeRef = Database.database().reference().child("Realtime").child("\(self.userId!)")
        self.realTimeList =  NSMutableArray()
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataTableView.dataSource = self
        self.dataTableView.delegate = self
        self.resultLabel.text = "data retrieved on \(self.defaultDate)"
        
        //configure button UI
        self.chooseDateBtn.bottonBorderSide(color: #colorLiteral(red: 0.1920000017, green: 0.6669999957, blue: 1, alpha: 1), width: 1.5)
        self.chooseFishTankBtn.bottonBorderSide(color: #colorLiteral(red: 0.1920000017, green: 0.6669999957, blue: 1, alpha: 1), width: 1.5)
        
        //initial default data view
        if self.chooseDateBtn.titleLabel!.text == "Choose a date" &&
            self.chooseFishTankBtn.titleLabel!.text == "Choose FishTank"{
            fetchDefaultValue()
        }
    }
    
    func fetchDefaultValue(){
        self.observeDefaultTank(){ tank in
            if tank != nil {
                self.defaultTank = tank
                self.chooseFishTankBtn.titleLabel!.text = tank.tankName
                self.chooseDateBtn.titleLabel!.text = self.defaultDate
                self.observeRealTimeValueV2(defaultTank: self.defaultTank!){ realtime in
                    self.realTimeList.add(realtime)
                    self.dataTableView.reloadData()
                }
            }
           
        }
        
        print("realtime list count: \(realTimeList.count)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    //MARK: ChooseTimeDateDelegate
    func selectFilterDateTime(selectDateTime: Date) {
        self.realTimeList.removeAllObjects()
        self.dataTableView.reloadData()

        let queryDate = selectDateTime.toMatchRealTimeDate(date: selectDateTime)
        self.selectDate = queryDate
        self.chooseDateBtn.titleLabel!.text = queryDate
        self.resultLabel.text = "data retrieved on \(queryDate)"
        
        observeByDateTank(selectDate: self.selectDate, fishTank: self.defaultTank!)
      
    }
    
    //MARK: selectTank delegate
    func selectTankDelegate(selectTank: FishTank) {
        self.realTimeList.removeAllObjects()
        self.dataTableView.reloadData()
        self.defaultTank = selectTank
        self.chooseFishTankBtn.titleLabel!.text = self.defaultTank!.tankName
     
        observeByDateTank(selectDate: self.selectDate, fishTank: self.defaultTank!)
     
    }
    
    //MARK: firebase observation : search realtime value based on the 
    private func observeByDateTank(selectDate : String, fishTank : FishTank){
        self.realTimeList.removeAllObjects()
        let realTimeQuery = realTimeRef.child("\(selectDate)").queryOrdered(byChild: "sensorId").queryEqual(toValue: "\(fishTank.sensorId!)")
        
        if fishTank.sensorId == "Unknown" || selectDate == ""{
            self.realTimeList.removeAllObjects()
            self.dataTableView.reloadData()
        }else{
        realTimeQuery.observe(.childAdded, with: { (snapshot) in
            print(snapshot)
            print(fishTank.sensorId!)
            if let realtimeItem = RealTimeValues(snapshot: snapshot){
                self.realTimeList.add(realtimeItem)
                self.dataTableView.reloadData()
                }
            })
            
        }
        
    }
    
    //MARK observe for the first tank 's sensor realtime value
    func observeRealTimeValueV2(defaultTank : FishTank, completion: @escaping (RealTimeValues)->Void) {
        self.realTimeList.removeAllObjects()
        let realTimeQuery = realTimeRef.child("\(self.defaultDate)").queryOrdered(byChild: "sensorId").queryEqual(toValue: "\(defaultTank.sensorId!)")
        print("start to download realtime data ..  reference: \(realTimeQuery)")
        realTimeQuery.observe(.childAdded, with: { (snapshot) in
            print(snapshot)
            print(defaultTank.sensorId!)
            if let realtimeItem = RealTimeValues(snapshot: snapshot){
                completion(realtimeItem)
            }
        })
    }
    
    //MARK: query the first tank
    func observeDefaultTank(completion: @escaping (FishTank)->Void){
        let defaultTankQuery = self.tankRef.queryLimited(toFirst: 1)
        defaultTankQuery.observeSingleEvent(of: .value, with:{ (snapshot) in
            print(snapshot)
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if let tank = FishTank(snapshot: child){
                    completion(tank)
                }
            }
        })
    }
    
    //MARK: perform segue to select time
    @IBAction func selectDateAction(_ sender: UIButton) {
        performSegue(withIdentifier: "selectTimeForRealtime", sender: self)
    }
    
    //MARK: perform segue to select tank
    @IBAction func selectTankAction(_ sender: Any) {
        performSegue(withIdentifier: "selectTank", sender: self)
    }
    
    @IBOutlet weak var dataTableView: UITableView!
    
    //MARK: table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.realTimeList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "realtimeTableViewCell", for: indexPath) as! RealtimeTableViewCell
        
        let realtime = self.realTimeList[indexPath.row] as! RealTimeValues
        
        cell.colorLabel.backgroundColor = UIColor(red: CGFloat(realtime.currentRed/256)/255, green: CGFloat(realtime.currentGreen/256)/255, blue: CGFloat(realtime.currentBlue/256)/255, alpha: 0.8 )
        cell.colorLabel.layer.cornerRadius =  cell.colorLabel.frame.width/2
        cell.colorLabel.layer.masksToBounds = true
        cell.pHlabel.text = "\(realtime.currentPh)"
        cell.tempLabel.text = "\(realtime.currentTemp)℃"
        cell.timeLabel.text = "\(realtime.currentDate)"
        cell.tankNameLabel.text = "FishTank:  \(self.defaultTank!.tankName)"
        return cell
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectTimeForRealtime" {
            let destinationVc = segue.destination as! DatePickerViewController
            destinationVc.dataStaticDelegate = self
        }
        if segue.identifier == "selectTank" {
            let destinationVc = segue.destination as! SelectTankTableViewController
            destinationVc.selectTankDelegate = self
        }
        
    }
    

}
