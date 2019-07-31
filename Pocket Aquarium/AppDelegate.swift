//
//  AppDelegate.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 3/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate{

    var window: UIWindow?
    let locationManager = CLLocationManager()

    
    let userNotificationDelegate : LocalNotificationDelegate = LocalNotificationDelegate()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        //set default value for the first launch 
        UserDefaults.standard.set(true, forKey: "lightingFixedState")
        UserDefaults.standard.set(true, forKey: "pumpingFixedState")
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]){(granted : Bool,error : Error?) in
            if !granted{
                 print("Permission granted:\(!granted)")
            }else{
                print("Permission granted:\(granted)")
            }
        }
        center.delegate = userNotificationDelegate
        //check all pending notifications
        listPendingNotifications()
        //center.removeAllPendingNotificationRequests()
        UIApplication.shared.applicationIconBadgeNumber  = 0
        center.removeAllDeliveredNotifications()
        
        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
    
        return true
    }
    
    func listPendingNotifications(){
        let notiCenter = UNUserNotificationCenter.current()
        notiCenter.getPendingNotificationRequests(completionHandler: {requests in
            for request in requests{
                print(request)
            }
        })
    }
    
    //MARK: create calendar notifications for reminder
    func createRemindDateNotification(selectTask : Task, thisTank : FishTank , selectRemindDateTime : String?){
        defineNotificationAction(taskType: "\(selectTask.taskId!)")
        //1. cerate and configure notification object content
        print("step 1: create noti content...")
        let content = UNMutableNotificationContent()
        content.title = "Fish tank Maintenance Reminder"
        content.subtitle = "Have you done \(selectTask.taskName!) for \(thisTank.tankName)? "
        content.body = "Do not forget to do this task! Open application to see more records"
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = "\(selectTask.taskId!)"
        content.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
        
        /*
        guard let path = Bundle.main.path(forResource: selectTask.taskIconName!, ofType: "png") else{
            print("\(selectTask.taskIconName!)")
            print("bundle main path error ")
            return
        }
      
        let url = URL(fileURLWithPath: path)
        do{
            let attachment = try UNNotificationAttachment(identifier: selectTask.taskName!, url: url, options: nil)
         content.attachments = [attachment]
        }catch{
         print("the attachment could not be loaded")
        }*/
        
        //2. create and configure notification trigger
        print("step 2: create noti trigger...")
        guard let reminderDate = selectRemindDateTime else {
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
    
    //MARK: define calendar notification action
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
    
    
    //MARK: location trigger notification
    func createLocationBasedTrigger(currentLatitude : Double, currentLongitude : Double ){
        //1. create and configure contification content object
        print("step 1 ..create content.")
        let content = UNMutableNotificationContent()
        content.title = "Location Notification!"
        content.body = "You have left your baby fish and fish tanks. Do not forget to close the lighting for the sake of their health"
        content.sound = UNNotificationSound.default()
        content.launchImageName = "attention"
        
        print("step 2 ..create monitoring location.")
        //create monitoring location
        
        let homeLocation = CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude)
        let region = CLCircularRegion(center: homeLocation, radius: 2000, identifier: "home")
        region.notifyOnExit = true
        region.notifyOnEntry = false
        
        print("step 3 ..create location trigger.")
        //create trigger
        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
        
        
        print("step 4 ..create request.")
        //create request
        let request = UNNotificationRequest(identifier: "locationNotification", content: content, trigger: trigger)
        
        //add to center
        print("step 5 ..remove all pending and add to center.")
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["locationNotification"])
        center.removeAllDeliveredNotifications()
        center.add(request){ (error) in
            print("\(error)")
        }
        print("add location notification success")
    }
    
    //MARK: Create the time interval notification
    func createWaterNotification(tank : FishTank){
         if UIApplication.shared.applicationState != .active {
            let content = UNMutableNotificationContent()
            content.title  = "Water Environment Warning"
            content.subtitle = "From Fish Tank: \(tank.tankName) "
            content.body = "Water in \(tank.tankName):  temperature is \(tank.currentTemp!) ℃.  pH is \(tank.currentpH!). Environment state is \(tank.state)"
            content.sound = UNNotificationSound.default()
            print("create content success")
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            let request = UNNotificationRequest(identifier: "waterWarning", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["waterWarning"])
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["waterWarning"])
            UNUserNotificationCenter.current().add(request, withCompletionHandler: {(error) in
                if error != nil{
                    print("\(error)")
                }
                else {
                    print("water warning notification add sucess")
                }
            })
        }
        
    }
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

