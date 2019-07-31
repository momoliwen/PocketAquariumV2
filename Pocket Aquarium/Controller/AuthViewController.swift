//
//  AuthViewController.swift
//  Pocket Aquarium
//
//  Created by Liwen Liang on 15/10/18. Sze Yan Kwok on 3/11/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Firebase

class AuthViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    var handle : AuthStateDidChangeListenerHandle?
    
    lazy var userRef = Database.database().reference().child("User")
    private var userRefHandler : DatabaseHandle?
    var userList = NSMutableArray()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: add listner check wheter user account exist . if new user, set value to firebase users node
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        handle = Auth.auth().addStateDidChangeListener({(auth, user) in
            if user != nil {
                self.userRef.observe(.childAdded, with: {(snapshot)-> Void in
                    let value = snapshot.value as! Dictionary<String,AnyObject>
                    print(value)
                    if let userEmail = value["UserEmail"] as! String?{
                        print(userEmail)
                        self.userList.add(userEmail)
                        print(self.userList.count)
                        
                        var userID = Auth.auth().currentUser?.uid
                        var userEmail = Auth.auth().currentUser?.email
                        var userItem = ["UserEmail" : userEmail]
                        if (!self.userList.contains(userEmail)) {
                            let newUserRef = self.userRef.child(userID!)
                            newUserRef.setValue(userItem)
                        }
                    }
                })
                self.performSegue(withIdentifier: "logInSegue", sender: nil)
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK : Allow firebase authorize user account and ready to log in
    @IBAction func logInAction(_ sender: Any) {
        guard let email = self.emailTextField.text?.trimmingCharacters(in: .whitespaces) else{
            return
        }
        guard let password = self.passwordTextField.text?.trimmingCharacters(in: .whitespaces) else{
            return
        }
        Auth.auth().signIn(withEmail: email, password: password, completion:{(user,error) in
            if error != nil {
                self.displayErrorMessage(message: error!.localizedDescription, title: "Login Error")
            }
        })
    }
    
    //MARK: sign up action
    @IBAction func signUpAction(_ sender: Any) {
        let alert = UIAlertController(title: "Register",
                                      message: "Register",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            
            let emailField = alert.textFields![0]
            let passwordField = alert.textFields![1]
            
            guard let email = emailField.text,
                let password = passwordField.text else {
                    self.displayErrorMessage(message: "Sign up Error", title: "Sign up Error")
                    return
            }
            
            Auth.auth().createUser(withEmail: email, password: password, completion:{(user, error) in
                if error != nil {
                    self.displayErrorMessage(message: error!.localizedDescription, title: "Sign up Error")
                }
                else{
                    Auth.auth().signIn(withEmail: email, password: password, completion: {(user,error) in
                        if error != nil {
                            self.displayErrorMessage(message: error!.localizedDescription, title: "Login Error")
                        }
                    })
                }
            })
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel)
        alert.addTextField { textEmail in
            textEmail.placeholder = "Enter your email"
        }
        alert.addTextField { textPassword in
            textPassword.isSecureTextEntry = true
            textPassword.placeholder = "Enter your password"
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.emailTextField{
            self.emailTextField.becomeFirstResponder()
        }
        if textField == self.passwordTextField{
            textField.resignFirstResponder()
        }
        return true
    }
    
    func displayErrorMessage(message:String,title:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
