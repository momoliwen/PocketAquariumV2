//
//  AddFish2ViewController.swift
//  Pocket Aquarium
//
//  Created by Sze Yan Kwok on 12/10/18. Revised by Liwen Liang on 27/10/2018
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Cosmos
import Firebase

class AddFish2ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {


    @IBOutlet weak var minpHSlider: UISlider!
    @IBOutlet weak var minpHLabel: UILabel!
    @IBOutlet weak var maxpHSlider: UISlider!
    @IBOutlet weak var maxpHLabel: UILabel!
    @IBOutlet weak var numberTextField: UITextField!
    @IBOutlet weak var ratingStar: CosmosView!
    @IBOutlet weak var fishImage: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var chooseTankTextField: UITextField!
    
    var currentFish: Fish?
    
    let fishes = ["Clownfish","Crab","Flounder","Flying Fish","Gnathanodon","Goldfish","Hermit Crab","Jellyfish","Lobster","Octopus","Paracanthurus","Puffer Fish","Seahorse","Seasnake","Seaweed","Shell","Shrimp","Siganus Vulpinus","Starfish","Swordfish","Turtle","Urchin","Yellow Tang"]
    
    //create array to store image
    var imageArray:  [UIImage] = {
        var manyImages = [UIImage]()
        return manyImages
    }()
    
    //user tank list, picker view data source 
    var tankList = [FishTank]()
    var selectTank : FishTank?
    
    var addNewFishToTankDelegate : EditFishTankDelegate?
    
    //add photos for fish
    @IBAction func importImage(_ sender: Any) {
        if (imageArray.count < 4){
            let alert = UIAlertController(title: "Upload Fish's Photo", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Import a Photo", style: .default, handler: {(importPhoto) in
                let controller = UIImagePickerController()
                controller.sourceType = UIImagePickerControllerSourceType.photoLibrary
                
                controller.allowsEditing = false
                controller.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
                
                self.present(controller, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Take a Photo", style: .default, handler: {(takePhoto) in
                let controller = UIImagePickerController()
                
                if UIImagePickerController.isSourceTypeAvailable(.camera){
                    controller.sourceType = UIImagePickerControllerSourceType.camera
                    controller.allowsEditing = false
                    controller.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
                    self.present(controller, animated: true, completion: nil)
                }
                else {
                    print("camera not available")
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            displayErrorMessage(message: "You only can upload at most 4 pictures", title: "Error")
        }
    }
    
    func imagePickerController(_ picker:UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
            if let pickedImage = info [UIImagePickerControllerOriginalImage] as? UIImage {
                imageArray.append(pickedImage)
                collectionView.reloadData()
            }
            dismiss(animated: true, completion: nil)
    }

    //DB user Ref
    var userID = Auth.auth().currentUser?.uid
    lazy var userRef = Database.database().reference().child("uid").child(userID!)
    
    //DB user fish ref
    lazy var fishRef = userRef.child("fishes")
    //DB user tank ref
    lazy var tankRef = userRef.child("tanks")
    var tankRefHandler: DatabaseHandle?
    
    
    //create new fish
    var newFish : Fish?
    
    //Observe the value changes of the min. pH value
    @IBAction func minpHValueChanged(_ sender: UISlider) {
        let currentValue = Double(sender.value)
        let roundedValue = String(format:"%.1f", currentValue)
        minpHLabel.text = "\(roundedValue)"
    }
    
    //Observe the value changes of the max. pH value
    @IBAction func maxpHValueChanged(_ sender: UISlider) {
        let currentValue = Double(sender.value)
        let roundedValue = String(format:"%.1f", currentValue)
        maxpHLabel.text = "\(roundedValue)"
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK:  - create new fish
    @IBAction func saveButton(_ sender: Any) {
        if isValidInput(){
            let name = currentFish!.fishName
            let icon = currentFish!.fishIcon.image
            let type = currentFish!.fishType
            let iconName = currentFish!.fishIconName
            let minTemp = currentFish!.fishMinTemp
            let maxTemp = currentFish!.fishMaxTemp
            let minpH = Double(minpHLabel.text!)
            let maxpH = Double(maxpHLabel.text!)
            let number = Int(numberTextField.text!)
            //get the rating value of the rating star
            let rating = Int(ratingStar.rating)
            let newFishRef = self.fishRef.childByAutoId()
            
            let fishItem = [
                "fishId" : newFishRef.key!,
                "fishIconName" : iconName,
                "fishName" : name,
                "fishType" : type,
                "fishMinTemp" : minTemp,
                "fishMaxTemp" : maxTemp,
                "fishMinpH" : minpH!,
                "fishMaxpH" : maxpH!,
                "fishRating" : rating,
            "fishNumber" : number] as [String : Any]
            
            if imageArray.count == 0 && currentFish?.fishIconName != "fish" {
                newFishRef.setValue(fishItem)
                //if user choose the tank, add the fish to tank ref
                if self.selectTank != nil{
                    let fishInTankRef = self.userRef.child("tanks").child("\(selectTank!.tankId)").child("fishMembers").child(newFishRef.key!)
                    fishInTankRef.setValue(fishItem)
                }
                /*
                //from add fish to tank screen
                if addNewFishToTankDelegate != nil{
                    let newFish = Fish(id: newFishRef.key!, icon: currentFish!.fishIcon, iconName: iconName, name: name, type: type, minTemp: minTemp, maxTemp: maxTemp, minpH: minpH!, maxpH: maxpH!, photo: [""], rating:rating, number: number ?? 0)
                    self.addNewFishToTankDelegate?.addFishToTank(newFish: newFish, setFishNumber: number ?? 0)
                }*/
            }
            else if imageArray.count != 0 && currentFish?.fishIconName != "fish"{
                 let photoList = ImageManager.saveFishAndPhotos(images: imageArray, thisFishRef: newFishRef, values: fishItem, uid: userID!)
                
                if self.selectTank != nil{
                    let fishInTankRef = self.userRef.child("tanks").child("\(selectTank!.tankId)").child("fishMembers").child(newFishRef.key!)
                    fishInTankRef.setValue(fishItem)
                }
                /*
                //from add fish to tank screen
                 if addNewFishToTankDelegate != nil{
                    let newFish = Fish(id: newFishRef.key!, icon: currentFish!.fishIcon, iconName: iconName, name: name, type: type, minTemp: minTemp, maxTemp: maxTemp, minpH: minpH!, maxpH: maxpH!, photo: photoList ?? [""], rating:rating, number: number ?? 0)
                    self.addNewFishToTankDelegate?.addFishToTank(newFish: newFish, setFishNumber: number ?? 0)
                }*/
            }
            else{
                if  selectTank == nil {
                    ImageManager.saveFishIcon(image: icon, thisFishRef: newFishRef, values: fishItem, uid: userID!)
                    ImageManager.saveFishAndPhotos(images: imageArray, thisFishRef: newFishRef, values: fishItem, uid: userID!)
                }
                else{
                    let fishInTankRef = self.userRef.child("tanks").child("\(selectTank!.tankId)").child("fishMembers").child(newFishRef.key!)
                    ImageManager.saveFishIconBoth(image: icon, thisFishRef: newFishRef, thisFishInTankRef: fishInTankRef, values: fishItem, uid: userID!)
                    ImageManager.saveFishAndPhotos(images: imageArray, thisFishRef: newFishRef, values: fishItem, uid: userID!)
                }
              
                /*
                //from add fish to tank screen
                if addNewFishToTankDelegate != nil{
                 let newFish = Fish(id: newFishRef.key!, icon: currentFish!.fishIcon, iconName: iconName, name: name, type: type, minTemp: minTemp, maxTemp: maxTemp, minpH: minpH!, maxpH: maxpH!, photo: photoList ?? [""], rating:rating, number: number ?? 0)
                  
                    self.addNewFishToTankDelegate?.addFishToTank(newFish: newFish, setFishNumber: number ?? 0)
                }*/
            }
            
    
          //  ImageManager.saveFishAndPhotos(images: imageArray, thisFishRef: newFishRef, values: fishItem, uid: userID!)
            /*
            for image in imageArray{
                ImageManager.savePhoto(image: image, thisTankRef: newFishRef)
                //print(image)
                print("Save photo successfully")
            }
            if (iconName == "fish"){
                ImageManager.saveIcon(image: icon, thisFishRef: newFishRef)
            }
            */
            displayFinishMessage(message: "Fish created!", title: "")
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // if from tank screen
        if let thisTank = selectTank{
            self.chooseTankTextField.text = thisTank.tankName
            self.chooseTankTextField.isUserInteractionEnabled = false
        }else{
            self.chooseTankTextField.isUserInteractionEnabled = true
        }
        //limit the input to number
        self.numberTextField.delegate = self
        createSensorPicker()
        createToolBar()
        observeTankList()
        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    //firebase observe existing fishtank
    func observeTankList() {
        self.tankRefHandler = self.tankRef.observe(.childAdded, with: {(snapshot)-> Void in
                print(snapshot)
                if let thisTank = FishTank(snapshot: snapshot){
                    self.tankList.append(thisTank)
                    print("observe tank child added success")
                }
        })
    }
    
    //limit the text input be the number ]
    // limit the input to number for max fish number text field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.numberTextField {
            let numberSet = NSCharacterSet(charactersIn: "0123456789").inverted
            let compSep  = string.components(separatedBy: numberSet)
            let nubmerFiltered = compSep.joined(separator: "")
            return string == nubmerFiltered
        }
        return true
    }
    
    func isValidInput() -> Bool{
        var errorMessage : String = "Not all fields were filled out!"
        
        if let fishNumber = self.numberTextField.text?.trimmingCharacters( in: .whitespaces){
            if fishNumber.isEmpty == true {
                displayErrorMessage(message: errorMessage, title: "Error")
                return false
            }
            if Int(fishNumber)! >= 40 {
                errorMessage = "Fish Number should be less than 40"
                displayErrorMessage(message: errorMessage, title: "Number error")
                return false
            }
        }
        return true
    }
    //MARK:finish adding the fish dimiss the controller
    func displayFinishMessage(message:String,title:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: {action in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - error handler
    func displayErrorMessage(message:String,title:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
 
    // MARK: - Collection View Data source and delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCollectionCell", for: indexPath) as! AddFishImageCollectionViewCell
        cell.imageView.image = imageArray[indexPath.row]
        
        return cell
    }

    // tab the image then show up action sheet to allow user to delete the photo
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selected = imageArray[indexPath.row]
        let alert = UIAlertController(title: "Edit Photo", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Delete the Photo", style: .default, handler: {(importPhoto) in
            if let index = self.imageArray.index(of: selected){
                self.imageArray.remove(at: index)
                collectionView.reloadData()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: Make sensor selection view
    func createSensorPicker(){
        let sensorPicker = UIPickerView()
        sensorPicker.dataSource = self
        sensorPicker.delegate = self
        //keyboard view pop up with sensor picker
        self.chooseTankTextField.inputView = sensorPicker
        sensorPicker.backgroundColor = .white
    }
    
    //MARK: show the existing sensor
    func createToolBar(){
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action:  #selector(AddFish2ViewController.dismissKeyboard))
        
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        self.chooseTankTextField.inputAccessoryView = toolBar
    }
    
    //MARK: keyboard selector used in createToolBar
    @objc func dismissKeyboard(){
        view.endEditing(true)
    }
    
    
    //MARK: Picker view data source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.tankList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectTank = self.tankList[row]
        if tankList.count > 0  {
            self.chooseTankTextField.text = selectTank?.tankName
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return tankList[row].tankName
    }

}
