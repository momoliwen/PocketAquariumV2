//
//  AddPendingTaskCollectionViewController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 31/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications

protocol EditReminderDateDelegate {
    func selectRemindDateTime (selectDateTime : String)
}

class AddPendingTaskCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout,EditReminderDateDelegate , UNUserNotificationCenterDelegate {
    
    var appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    @IBOutlet weak var savePendingTasksButton: UIBarButtonItem!
    
    lazy var taskRef = Database.database().reference().child("tasks")
    private let pendingTaskCell = "pendingTaskCollectionCell"
    //collection view
    private let itemsPerRow : CGFloat = 2
    private let sectionInsets = UIEdgeInsets(top: 80, left: 10, bottom: 100, right: 10)
    
    var thisTank : FishTank? {
        didSet {
            if let tankId = thisTank?.tankId {
                self.thisTankHistoryListRef = self.historyTaskListRef.child("\(tankId)")
                print("tank history task reference: \(thisTankHistoryListRef)")
            }
        }
    }
    
    lazy var historyTaskListRef = Database.database().reference().child("historyTaskList")
    var thisTankHistoryListRef : DatabaseReference?
    //initial task list
    var taskList = [Task]()
    //reminder task list
    var pendingTaskList = [Task]()

    
    var selectRemindDateTime : String? = ""
    var nextTriggerDate : Date?
    var selectedIndex : IndexPath?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        InitialTaskManager.observeTasks(){ thisTaskList in
            self.taskList = thisTaskList
            self.collectionView!.reloadData()
        }
         print("load task list ok  length = \(taskList.count)")
        
         self.savePendingTasksButton.isEnabled = false
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.taskList.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: pendingTaskCell, for: indexPath) as! PendingTaskCollectionViewCell
        print("start configure task collection view cell.. ")
        if self.taskList.count > 0{
            let initialTask = self.taskList[indexPath.row]
            cell.taskIconImageView.image = UIImage(named: initialTask.taskIconName!)
            cell.taskNameLabel.text  = initialTask.taskName
            if initialTask.reminderDateTime != "" {
                cell.reminderTimeLabel.text = initialTask.reminderDateTime!
            }else{
                cell.reminderTimeLabel.text = "Set the reminder time"
            }
            return cell
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedIndex = indexPath
        performSegue(withIdentifier: "selectRemindTime", sender: self)
    }
    
    //MARK: UIcollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * ( self.itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true , completion: nil)
    }
    
    
    //MARK: create pending tasks and create notifications
    @IBAction func saveAction(_ sender: UIBarButtonItem) {
        let today = self.defineCreateDate()
        
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        for pendingTask in self.pendingTaskList {
            print("pending task list length = \(pendingTaskList.count)")
            pendingTask.createDateTime = today
            pendingTask.reminderDateTime = self.selectRemindDateTime
            //1. uploade to firebase
            if let newTaskRef = self.thisTankHistoryListRef?.child("\(pendingTask.taskId!)").childByAutoId() {
                newTaskRef.setValue(pendingTask.toCreatedTankTaskObject())
                print("set value for new pending task success")
            }
            //2. create notifications
            if self.thisTank != nil{
                //self.createRemindDateNotification(selectTask: pendingTask)
                appDelegate?.createRemindDateNotification(selectTask: pendingTask, thisTank: thisTank!, selectRemindDateTime: self.selectRemindDateTime)
            }
            else{
                print("tank is nil")
            }
        }
        //2. create notifications
        self.dismiss(animated: true , completion: nil)
    }
    
    //MARK : - set remind time delegate
   func selectRemindDateTime (selectDateTime : String){
        self.selectRemindDateTime = selectDateTime
        //configure cell display
        if let index = self.selectedIndex?.row {
            let thisTask = self.taskList[index]
            thisTask.reminderDateTime = selectDateTime
            pendingTaskList.append(thisTask)
            print("add  pending task ok , list length  \(pendingTaskList.count)")
            //thisTask.createDateTime = defineCreateDate()
            self.collectionView?.reloadData()
            self.savePendingTasksButton.isEnabled = true
        }
    }
    
    //MARK: create today in string format
    func defineCreateDate() -> String {
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy h:mm a"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return  dateFormatter.string(from: today)
    }
    
    //MARK: create notifications -- using application version 
    func createRemindDateNotification(selectTask : Task){
        defineNotificationAction(taskType: "\(selectTask.taskId!)")
        //1. cerate and configure notification object content
        print("step 1: create noti content...")
        let content = UNMutableNotificationContent()
        content.title = "Have you done \(selectTask.taskName!) for \(self.thisTank!.tankName)? "
        content.body = "Do you want to record your tasks now?"
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = "\(selectTask.taskId!)"
     
        //2. create and configure notification trigger
        print("step 2: create noti trigger...")
        guard let reminderDate = self.selectRemindDateTime else {
            return
        }
        
        guard let dateTrigger = createNotificationTrigger(date: reminderDate) else{
            return
        }
        
        //3. create notification request
        print("step 3: create noti request...")
       let request = UNNotificationRequest(identifier: "\(selectTask.taskName!)", content: content, trigger: dateTrigger)
        
        //4. add request to notification center
        print("step 3: add request into noti center...")
        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: { (error) in
            if error != nil{
                print("error : \(error!)")
            }
        })
        print("success add notification")
    }
    
    
    //MARK: define notification action
    func defineNotificationAction(taskType : String){
        //1. define action
        let doneAction = UNNotificationAction(identifier: "HaveDone", title: "I have Done it", options: [])
        let notDoneAction = UNNotificationAction(identifier: "NotDone", title: "Later do", options: [])
        
        //2. define category
        let category = UNNotificationCategory(identifier: taskType, actions: [doneAction, notDoneAction], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func createNotificationTrigger(date : String?) ->  UNCalendarNotificationTrigger? {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "dd-MM-yyyy h:mm a"
        dateformatter.locale = Locale(identifier: "en_US_POXIS")
        
        if let remindTime = date {
            let dateFromString = dateformatter.date(from: remindTime)
            let fireDateOfNotification: Date = dateFromString!
            print("\(fireDateOfNotification)")
            
            let triggerDate = Calendar.current.dateComponents([.day,.month,.year,.hour,.minute,], from: fireDateOfNotification)
            print("\(triggerDate)")
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                                                        repeats: false)
            return trigger
        }
        return nil
    }
    
    //MARK: validate user choose, if use did not choose anything, disable the button, true means disabled button, false means available button
    func isDisabledSaveButton() -> Bool {
        for taskItem in taskList {
            if taskItem.reminderDateTime != ""{
                return false
            }
        }
        return true
    }
    
     // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectRemindTime"{
            let destinationVc =  segue.destination as! DatePickerViewController
                 destinationVc.selectRemindDateTimeDelegate = self
        }
    }


}
