//
//  AddFinishedTableViewController.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 29/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

protocol EditCompletedDateDelegate {
    func selectCompletedDateTime (selectDateTime : String)
}

class AddFinishedTableViewController: UITableViewController, EditCompletedDateDelegate{
    
    var activityIndicator = UIActivityIndicatorView()
    //initial data source
    var taskList = [Task]()
    var completedTaskList = [Task]()
   
    var thisTankId : String? {
        didSet {
            if let tankId = thisTankId{
                self.thisTankHistoryListRef = self.historyTaskListRef.child("\(tankId)")
                print("tank history task reference: \(thisTankHistoryListRef)")
            }
        }
    }
    
    var selectedTime :String?
    //Firebase reference
    var tankRef : DatabaseReference?
    var isSelected : Bool?
    var userID = Auth.auth().currentUser?.uid
    lazy var userRef = Database.database().reference().child("uid").child(userID!)
    //initial tasks reference
    lazy var taskRef = Database.database().reference().child("tasks")
    lazy var historyTaskListRef = Database.database().reference().child("historyTaskList")
    var thisTankHistoryListRef : DatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        view.addSubview(activityIndicator)
        initialTask()
    }
    
    func initialTask(){
        activityIndicator.startAnimating()
        InitialTaskManager.observeTasks(){ thisTaskList in
            self.activityIndicator.stopAnimating()
            self.taskList = thisTaskList
            self.tableView.reloadData()
            print("load task list ok  length = \(self.taskList.count)")
        }
    }
    
    //MARK: table view delegate - if select, show checkmark and add the task into the completed list
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("\(indexPath.row)")
        if indexPath.section == 0 {
            let cell = tableView.cellForRow(at: indexPath) as! InitialTaskTableViewCell
            let taskItem = self.taskList[indexPath.row]
            let toggledCompletion = !taskItem.isDone
            //add or remove check mark of table view cell
            self.toggleCellCheckbox(cell, isCompleted: toggledCompletion)
            taskItem.isDone = toggledCompletion
            print("\(String(describing: taskItem.taskName)): \(taskItem.isDone)")
            //add the chosen tasks to the completed task list
            if toggledCompletion {
                self.completedTaskList.append(taskItem)
                print("add \(taskItem.taskId) into completed task list, task list lentght = \(completedTaskList.count)")
            }
            else{
                if let index = self.completedTaskList.index(where: {
                    $0.taskId == taskItem.taskId
                }).flatMap({
                    IndexPath(row: $0, section: 0)
                }){
                    self.completedTaskList.remove(at: index.row)
                    print("remove \(index) in completed task list, task list length = \(completedTaskList.count)")
                }
            }
        }
        else{
            let cell = tableView.cellForRow(at: indexPath) as! SelectTimeTableViewCell
            performSegue(withIdentifier: "showDatePicker", sender: self)
        }
    }
    
    //MARK: validate either choose the tasks or the completed date
    func inputValidate() -> Bool {
        if self.selectedTime == nil{
            displayFinishMessage(message: "You have not chosen the completed date", title: "Oops")
            return false
        }
        if self.completedTaskList.count == 0 {
            displayFinishMessage(message: "You have not chosen the completed tasks", title: "Oops")
            return false
        }
        return true
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.taskList.count
        }
        return 1
    }
    
    //configure cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "initialTaskCell", for: indexPath) as! InitialTaskTableViewCell
            
                let task = self.taskList[indexPath.row]
                cell.taskIconImage.image = UIImage(named: task.taskIconName!)
                cell.taskNameLabel.text = task.taskName
                cell.taskDescLabel.text = task.taskDescription
                self.toggleCellCheckbox(cell, isCompleted: task.isDone)
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "selectTimeCell", for: indexPath) as! SelectTimeTableViewCell
            cell.selectTimeLabel.text = "Select the completed date and time"
             return cell
        }
    }

    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0{
            return 80
        }
        else{
            return 40
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "CHOOSE COMPLETED TASKS"
        }
        else{
            return "COMPLETED TIME"
        }
    }
    
    //MARK: customize checbox in the table view cell -  reference
    func toggleCellCheckbox(_ cell: InitialTaskTableViewCell , isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = .none
            cell.taskNameLabel.textColor = .black
           
        } else {
            cell.accessoryType = .checkmark
            cell.taskNameLabel.textColor = .gray
        }
    }
    
    func selectCompletedDateTime(selectDateTime: String) {
        self.selectedTime = selectDateTime
        let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as! SelectTimeTableViewCell
        cell.selectTimeLabel.text = selectedTime
    }
    
    //MARK: Action of tasks
    @IBAction func cancelComplete(_ sender: UIButton) {
        self.dismiss(animated: true , completion: nil)
    }
    
    //MARK: create new completed task to the firebase
    @IBAction func doneAction(_ sender: Any) {
        if inputValidate(){
            let today = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy h:mm a"
            
            for task in completedTaskList {
                task.createDateTime = dateFormatter.string(from: today)
                task.finishDateTime = self.selectedTime
                task.reminderDateTime = ""
                
                if let newTaskRef = self.thisTankHistoryListRef?.child("\(task.taskId!)").childByAutoId() {
                    newTaskRef.setValue(task.toCreatedTankTaskObject())
                }
            }
            autoDismissSuccessEditAlert(message: "You have completed \(completedTaskList.count) tasks today", title: "Success")
            
        }
        
    }
    
    //MARK: audo dismiss alert controller
    func autoDismissSuccessEditAlert(message:String, title:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alert,animated: true, completion: nil)
        //change to desired number of seconds
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    //MARK: display feedback message
    func displayFinishMessage(message:String,title:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDatePicker" {
            let destinationVc = segue.destination as! DatePickerViewController
            destinationVc.selectDateTimeDelegate = self
        }
    }
    
    
}
