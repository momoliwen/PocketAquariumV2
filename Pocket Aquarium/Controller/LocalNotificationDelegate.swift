//
//  LocalNotificationDelegate.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 1/11/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit

class LocalNotificationDelegate : NSObject, UNUserNotificationCenterDelegate{

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
       // showSpecificVc()
        UIApplication.shared.applicationIconBadgeNumber  = 0
        completionHandler()
        
    }
    
    //show the notification in app
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
    
    func showSpecificVc(){
         let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewController : UIViewController  = mainStoryboard.instantiateViewController(withIdentifier: "trackTasks") as UIViewController
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = initialViewController
        window.makeKeyAndVisible()
    }
}


