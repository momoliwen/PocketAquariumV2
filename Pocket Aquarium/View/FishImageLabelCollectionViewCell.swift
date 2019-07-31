//
//  FishImageLabelCollectionViewCell.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 16/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit

class FishImageLabelCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var fishImage: UIImageView!{
        didSet{
            fishImage.roundedImageView()
        }
    }
    @IBOutlet weak var fishNameLabel: UILabel!
    
    
    
}
