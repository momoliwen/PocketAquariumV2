//
//  InitialTaskManager.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 31/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

//initial task list
class InitialTaskManager  {
    
    static var taskRef = Database.database().reference().child("tasks")
    static var taskList = [Task]()
    static var initialTaskList = [Task]()
    
    //MARK: this method is used for retrieve task id
    static func observeTaskIdList(completion : @escaping((String) -> Void)) {
        self.taskRef.observeSingleEvent(of: .value, with: {(snapshot) in
            print(snapshot)
            for child in snapshot.children{
                let childSnapshot = child as! DataSnapshot
                let thisId = childSnapshot.key
                print(thisId)
                completion(thisId)
            }
        })
    }
    
    //MARK: download built in tasks
    static func observeTasks(completion: @escaping([Task]) -> Void) {
        print("start download ata ..")
        taskList.removeAll()
        self.taskRef.observe(.childAdded, with: { (snapshot) in
            print(snapshot)
                if snapshot.exists(){
                    let taskId = snapshot.key
                    guard let taskData = snapshot.value as? [String : AnyObject],
                        let taskName = taskData["taskName"] as! String?,
                        let taskDesc = taskData["taskDescription"] as! String?,
                        let taskIconName = taskData["taskIconName"] as! String?
                        else{
                            return
                    }
                    let initialTask = Task(taskName: taskName, taskIconName: taskIconName, taskDesc: taskDesc)
                    initialTask.taskId = taskId
                    self.taskList.append(initialTask)
                    print("\(self.taskList.count)")
                    completion(self.taskList)
                }
                else{
                    self.initialTask()
                    for task in self.initialTaskList{
                        let newTaskRef = self.taskRef.childByAutoId()
                        let taskKey = newTaskRef.key
                        task.taskId = taskKey
                        newTaskRef.setValue(task.toInitialTaskObject())
                    }
                    self.taskList = self.initialTaskList
                }
            })
    }
        
    
    //MARK: initial build in tasks
    static func initialTask(){
        let feedingTask = Task(taskName: "Feeding", taskIconName: "feeding", taskDesc: "Recommend every 24 hours")
        let waterChangingTask = Task(taskName: "Water Changing", taskIconName: "waterChange", taskDesc: "Recommend every 2 weeks")
        let waterTestingTask = Task(taskName: "Water Testing", taskIconName: "testing", taskDesc: "Recommend before water changing")
        let cleaningTask = Task(taskName: "Cleaning", taskIconName: "cleaning", taskDesc: "Recommend once a month")
        self.initialTaskList.append(feedingTask)
        self.initialTaskList.append(waterChangingTask)
        self.initialTaskList.append(waterTestingTask)
        self.initialTaskList.append(cleaningTask)
        print("\(self.initialTaskList.count)")
    }
}

