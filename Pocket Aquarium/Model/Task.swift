//
//  Task.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 24/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase


class Task: NSObject {
    
    var ref : DatabaseReference?
    var key : String?
    var taskId : String?
    var taskName : String? = ""
    var taskIconName: String? = ""
    var taskDescription : String? = ""
    
    //user define
    var createDateTime : String? = ""
    var isDone : Bool = false
    
    var taskState : String?{
        get {
            if isDone == true{
                return "Completed"
            }else{
                return "Pending"
            }
        }
    }
    
    var finishDateTime : String? = ""
    var reminderDateTime : String? = ""

    // built-in task object
    init(taskName : String, taskIconName : String , taskDesc: String){
        self.taskDescription = taskDesc
        self.taskName = taskName
        self.taskIconName = taskIconName
    }
    
    //created task object from firebase
    init?(snapshot : DataSnapshot){
        guard let taskData = snapshot.value as? [String : AnyObject],
            let taskName = taskData["taskName"] as! String?,
            let taskCompletedTime = taskData["finishDateTime"] as! String?,
            let taskCreatedTime = taskData["createDateTime"] as! String?,
            let currentState = taskData["taskState"] as! Bool?,
            let taskReminderTime = taskData["remindDateTime"] as! String? else{
                print( "fail to convert to object ")
                return nil
        }
        self.key = snapshot.key
        self.taskId = snapshot.ref.parent!.key!
        self.ref = snapshot.ref
        self.createDateTime = taskCreatedTime
        self.finishDateTime = taskCompletedTime
        self.isDone = currentState
        self.reminderDateTime = taskReminderTime
        self.taskName = taskName
    }
    //upload to firebase
    func toCreatedTankTaskObject() -> Any {
        return [
            "taskName" : self.taskName!,
            "createDateTime" : self.createDateTime!,
            "finishDateTime" : self.finishDateTime!,
            "remindDateTime" : self.reminderDateTime!,
            "taskState" : self.isDone
            ]  as  [String : Any]
    }
    
    func toInitialTaskObject() -> Any {
        return [
            "taskId" : self.taskId!,
            "taskName" : self.taskName!,
            "taskDescription" : self.taskDescription!,
            "taskIconName" : self.taskIconName!
            ]  as  [String : Any]
    }
}
    
    
    
    

