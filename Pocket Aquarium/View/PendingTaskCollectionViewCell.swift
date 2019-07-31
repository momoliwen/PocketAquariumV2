//
//  PendingTaskCollectionViewCell.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 31/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit

class PendingTaskCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var taskNameLabel: UILabel!
    @IBOutlet weak var reminderTimeLabel: UILabel!
    
    @IBOutlet weak var taskIconImageView: UIImageView!
    
    
    
    //MARK: customize the collection cell view
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setGradientBackground(colorMain: #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1), colorSecond: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        self.layer.shadowOffset = CGSize(width: 2, height: 3)
        self.layer.shadowOpacity = 0.3
        self.clipsToBounds = false

    }
}
