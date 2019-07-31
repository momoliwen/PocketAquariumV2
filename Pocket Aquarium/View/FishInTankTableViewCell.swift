//
//  FishInTankTableViewCell.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 28/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit
import Cosmos

class FishInTankTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var fishIconImage: UIImageView!
    
    @IBOutlet weak var fishNameLabel: UILabel!
    @IBOutlet weak var fishPhRangeLabel: UILabel!
    @IBOutlet weak var fishTempRangeLabel: UILabel!
    @IBOutlet weak var fishNumberLabel: UILabel!
    @IBOutlet weak var aggressiveCosmosView: CosmosView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
