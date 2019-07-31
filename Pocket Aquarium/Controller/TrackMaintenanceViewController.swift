//
//  TrackMaintenanceViewController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 29/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

protocol EditReminderForTask{
    func resetReminderForTask(newDate : String)
  
}

class TrackMaintenanceViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, EditTaskStateDelegate, EditReminderForTask {
    
    var appDelegate = UIApplication.shared.delegate as? AppDelegate
    var historyCell = "historyTaskCell"

    @IBOutlet var taskTypeSegementControl: UISegmentedControl!
    @IBOutlet weak var tasksTableView: UITableView!
    
    //Firebase reference
    //received tank ref
    var thisTank : FishTank?{
        didSet{
            if let tank = thisTank {
                self.thisTankHistoryListRef = taskListRef.child("\(tank.tankId)")
                print("tank history task reference : \(thisTankHistoryListRef)")
            }
        }
    }
    var userID = Auth.auth().currentUser?.uid
    lazy var userRef = Database.database().reference().child("uid").child(self.userID!)
    //initial tasks reference
    var taskRef = Database.database().reference().child("tasks")
    //user history task list reference
    var taskListRef = Database.database().reference().child("historyTaskList")
    var thisTankHistoryListRef : DatabaseReference?
    
    //initial task List
    var initialTaskList = [Task]()
    var taskList = [Task]()
    
    //table view data source
    var historyList = [Task]()
    
    //segment select index
    var selectedSegmentIndex : Int = 0
    
    //edit task
    var editTask : Task?
    
    var activityIndicatorView : UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        return activityIndicator
    }()
    
    lazy var refresher : UIRefreshControl = {
        let refresherControl = UIRefreshControl()
        refresherControl.tintColor = #colorLiteral(red: 0.1920000017, green: 0.6669999957, blue: 1, alpha: 1)
        refresherControl.addTarget(self, action: #selector(initialData), for: .valueChanged)
        return refresherControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tasksTableView.refreshControl = refresher
        self.tasksTableView.addSubview(activityIndicatorView)

        taskTypeSegementControl.selectedSegmentIndex = -1
        taskTypeSegementControl.layer.cornerRadius = 5
        
        tasksTableView.delegate = self
        tasksTableView.dataSource = self
        
        //taskList.removeAll()
        InitialTaskManager.observeTasks(){ thisTaskList in
            self.taskList = thisTaskList
            self.tasksTableView.reloadData()
            self.customizeSegment(taskItems: self.taskList)
        }
       
        print("load task list ok  length = \(taskList.count)")
        
        //observeInitialTasks()
    }
    
    @objc func initialData(){
         print("refreshing data....")
         taskTypeSegementControl.selectedSegmentIndex = -1
         observeEachTaskAdded()
         let deadline = DispatchTime.now() + .milliseconds(700)
         DispatchQueue.main.asyncAfter(deadline: deadline){
            self.refresher.endRefreshing()
        }
        print("ending refreshing data....")
    }
    
    override func viewDidAppear(_ animated: Bool) {
       taskTypeSegementControl.selectedSegmentIndex = -1
       observeEachTaskAdded()
    }
    
    func customizeSegment(taskItems: [Task]){
        if taskItems.count > 0 {
            for (index,task) in taskItems.enumerated() {
                 self.taskTypeSegementControl.setImage(UIImage(named: task.taskIconName!), forSegmentAt: index)
                print("configure segment index \(index)")
            }
        }
    }
    
    //MARK: segment control filter the task by type
    @IBAction func segmentControl(_ sender: UISegmentedControl) {
        print("start segment control action...")
    
        switch sender.selectedSegmentIndex {
        case 0:
            observeSingleTypeTasks(index: 0)
        case 1:
             observeSingleTypeTasks(index: 1)
        case 2:
             observeSingleTypeTasks(index: 2)
        case 3:
             observeSingleTypeTasks(index: 3)
        default:
             observeEachTaskAdded()
        }
    }
    

    @IBAction func addNewTasks(_ sender: Any) {
       
    }
    
    //MARK - table view data source and delegate 
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("history list length count :  \(historyList.count)")
        if historyList.count > 0 {
            return self.historyList.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("start configure history task cell...")
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyTaskCell", for: indexPath) as! HistoryTaskTableViewCell
        cell.taskDelegate = self
        cell.indexPath = indexPath
        
        let thisTask = self.historyList[indexPath.row]
        var initialTask : Task?
        for item in self.taskList{
            if item.taskId! == thisTask.taskId! {
                initialTask = item
                break
            }
        }
        
        if initialTask != nil{
            cell.taskName.text = initialTask!.taskName
            cell.taskIconImage.image = UIImage(named: initialTask!.taskIconName!)
            //if task has been done, show finished time
            if thisTask.isDone == true{
                cell.taskStateDescLabel.text = "Finished on: \(thisTask.finishDateTime!)"
                cell.taskStateLabel.textColor = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
                cell.operationButton.isEnabled = false
                cell.operationButton.tintColor = #colorLiteral(red: 0.5741485357, green: 0.5741624236, blue: 0.574154973, alpha: 1)
            }
            else{
                //otherwise, show reminder time
                cell.taskStateDescLabel.text = "Remind on:  \(thisTask.reminderDateTime!)"
                cell.taskStateLabel.textColor = #colorLiteral(red: 0.9764705882, green: 0.8392156863, blue: 0.2862745098, alpha: 1)
                cell.operationButton.isEnabled = true
                 cell.operationButton.tintColor = #colorLiteral(red: 0.1920000017, green: 0.6669999957, blue: 1, alpha: 1)
            }
            cell.taskStateLabel.text = thisTask.taskState
            return cell
        }
        return cell
    }
    
    //MARK: observe history task node --> observe child added
    func observeEachTaskAdded(){
        self.historyList.removeAll()
        print("start load history list , taskList length = \(taskList.count)")
        
        self.activityIndicatorView.startAnimating()
        
        for item in self.taskList{
            if let taskRef =  self.thisTankHistoryListRef?.child(item.taskId!){
                let taskOrderedQuery = taskRef.queryOrdered(byChild: "taskState")
                taskOrderedQuery.observe(.childAdded, with: { (snapshot) in
                    print(snapshot)
                    
                    if let historyTask = Task(snapshot: snapshot){
                        self.historyList.append(historyTask)
                        print("history add a new history task success")
                        self.tasksTableView.reloadData()
                    }
                    else{
                        print("obser error")
                    }
                })
            }
        }
        self.activityIndicatorView.stopAnimating()
        print("after observe each task added, history list count : \(self.historyList.count)")
    }
    
    func observeSingleTypeTasks(index : Int){
        self.historyList.removeAll()
        if let theTaskId = self.taskList[index].taskId {
            if let thisTaskRef =  self.thisTankHistoryListRef?.child(theTaskId){
                let taskOrderedQuery = thisTaskRef.queryOrdered(byChild: "taskState")
                taskOrderedQuery.observeSingleEvent(of: .value, with: ({ (snapshot) in
                    print(snapshot)
                    
                    for child in snapshot.children {
                        let thisSnapshot = child as! DataSnapshot
                        if let thisTask = Task(snapshot: thisSnapshot){
                            self.historyList.append(thisTask)
                        
                            print("reload the task by the type on \(index) ok")
                        }
                    }
                    self.tasksTableView.reloadData()
                }))
            }
        }
    }
    
    //MARK: edit task state delegate
    func editTaskState(index: Int) {
        self.showTaskOperationAlert(index: index)
    }
    
    //MARK: show action sheet for users to edit the state of the task
    func showTaskOperationAlert(index: Int){
        let editTaskStateAlert = UIAlertController(title: "Have you done this Task?", message: nil, preferredStyle: .actionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let doneAction = UIAlertAction(title: "I have done it", style: UIAlertActionStyle.default, handler: { action in
            self.haveDoneTheTask(index: index)
            self.autoDismissSuccessEditAlert(message: "You have completed this task!", title: "Success")
        })
        let setReminderAction = UIAlertAction(title: "Remind me on another date time", style: UIAlertActionStyle.default, handler: { action in
            //go to set date picker
            self.editTask = self.historyList[index]
            self.performSegue(withIdentifier: "resetReminder", sender: self)
        })
        editTaskStateAlert.addAction(doneAction)
        editTaskStateAlert.addAction(setReminderAction)
        editTaskStateAlert.addAction(cancel)
        present(editTaskStateAlert, animated: true, completion: nil)
    }
    
    //MARK: create today in string format
    func defineCreateDate() -> String {
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy h:mm a"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return  dateFormatter.string(from: today)
    }
    
    //MARK: audo dismiss alert controller
    func autoDismissSuccessEditAlert(message:String, title:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alert,animated: true, completion: nil)
        //change to desired number of seconds
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK: reset reminder for task
    func resetReminderForTask(newDate: String) {
        //update table view
        self.editTask?.reminderDateTime = newDate
        self.tasksTableView.reloadData()
        //update firebase
        if let thisRef = editTask?.ref {
            thisRef.updateChildValues([
                "remindDateTime" : newDate
            ])
        }
        //create notification
        appDelegate?.createRemindDateNotification(selectTask: editTask!, thisTank: self.thisTank!, selectRemindDateTime: newDate)
        
    }
    
    func haveDoneTheTask(index : Int) {
        let thisTask = self.historyList[index]
        print("\(thisTask.ref!)")
        
        //update table view data source
        let today = self.defineCreateDate()
        thisTask.finishDateTime = today
        thisTask.isDone = true
        self.tasksTableView.reloadData()
        
        //update firebase
        if let thisTaskRef = thisTask.ref {
            thisTaskRef.updateChildValues([
                "finishDateTime" : today,
                "taskState" : true
                ])
            print("success update finished time and task state for \(thisTask.taskId!)")
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addCompletedTask"{
            let navigationVc = segue.destination as! UINavigationController
            let destinationVc = navigationVc.viewControllers.first as! AddFinishedTableViewController
            destinationVc.thisTankId = self.thisTank?.tankId
        }
        
        if segue.identifier == "addPendingTask" {
            let navigationVc = segue.destination as! UINavigationController
            let destinationVc = navigationVc.viewControllers.first as! AddPendingTaskCollectionViewController
            destinationVc.thisTank = self.thisTank!
        }
        
        if segue.identifier == "resetReminder" {
            let destinationVc = segue.destination as! DatePickerViewController
            destinationVc.editedTask = self.editTask
            destinationVc.resetReminderDelegate = self
            
        }
    }
}
