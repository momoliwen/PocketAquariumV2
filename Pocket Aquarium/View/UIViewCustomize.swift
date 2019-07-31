//
//  UIViewCustomize.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 16/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import Foundation
import UIKit

extension UIView{
    //gradient background for ui view
    func setGradientBackground(colorMain:UIColor, colorSecond:UIColor){
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorMain.cgColor,colorSecond.cgColor]
        layer.insertSublayer(gradientLayer, at: 0)
    }
}

//MARK: add bottom border for text field
extension UITextField {
        
    func addBottomBorder(backgroundColor: UIColor){
        let bottomLine = CALayer()
        bottomLine.frame = CGRect.init(x: 0, y: self.frame.size.height - 1, width: self.frame.size.width, height: 1)
        bottomLine.backgroundColor = backgroundColor.cgColor
        self.borderStyle = UITextBorderStyle.none
        self.layer.addSublayer(bottomLine)
    }
}

extension UIImageView{
    
    func roundedImageView(){
        self.layer.cornerRadius = self.frame.size.width/2
        self.clipsToBounds = true
    }
}

//limit double digit
extension Double{
    func roundTo(places : Int)-> Double {
        let divisor = pow(10.0, Double(places))
            return (self * divisor).rounded() / divisor
    }
}

//MARK: add shadow border for UIButton
extension UIButton{
    func addShadow(){
        self.layer.shadowColor = UIColor.lightGray.cgColor
        self.layer.shadowOffset = CGSize(width: 3, height: 3)
        self.layer.shadowRadius = 4
        self.layer.shadowOpacity = 0.6
    }
    
    //reference - add bottom border side of the button
    func bottonBorderSide(color:UIColor, width : CGFloat){
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
    }
}

//date formatter for String to date
extension String {
    func toDate(stringDate : String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "dd-MM-yyyy h:mm a"
        guard let date = dateFormatter.date(from: self) else{
            preconditionFailure("take a look at your format")
        }
        return date
    }
}

//date formatter for date to String
extension Date {
    func toMatchRealTimeDate (date : Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat =  "dd-MM-yyyy"
        let dateString = dateFormatter.string(from: self)
        return dateString
    }

}


// MARK: Normal Helper Extensions
extension UIViewController {
    func showAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: auto dismiss alert controller for successfully add to tank - Reference
    func autoDismissSuccessAlert(message:String, title:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alert,animated: true, completion: nil)
        //change to desired number of seconds
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
}

extension UICollectionViewController {
    //MARK: auto dismiss alert controller for successfully add to tank -- Reference
    func autoDismissAlert(message:String, title:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alert,animated: true, completion: nil)
        //change to desired number of seconds
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
}



extension UITableViewController{
    func showAlertForTableView(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}


    
