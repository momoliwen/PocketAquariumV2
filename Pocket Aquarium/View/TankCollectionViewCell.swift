//
//  TankCollectionViewCell.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 15/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit


class TankCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var tankNameLabel: UILabel!
    @IBOutlet weak var currentTempLabel: UILabel!
    @IBOutlet weak var temRangeLabel: UILabel!
    @IBOutlet weak var currentpHLabel: UILabel!
    @IBOutlet weak var pHRangeLabel: UILabel!
    @IBOutlet weak var tankAgeLabel: UILabel!
    @IBOutlet weak var backgroundImg: UIImageView!
    @IBOutlet weak var backgroundColorView: UIView!
    
    @IBOutlet weak var stateLabel: UILabel!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    
    
    //delegate to delete or show
    var delegate: EditHomeTankDelegate?
    var indexPath : IndexPath?
    
    

    //MARK: customize the collection cell view
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 20
        self.clipsToBounds = false
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 0.4
        self.layer.shadowOffset = CGSize(width: 2, height: 3)
    }
    
    //MARK: delete tank delegate 
    @IBAction func deleteTank(_ sender: Any) {
         self.delegate?.deleteFishTank(index: self.indexPath!)
    }
}
