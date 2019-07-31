//
//  FishTableViewCell.swift
//  Pocket Aquarium
//
//  Created by Sze Yan Kwok on 17/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit

class FishTableViewCell: UITableViewCell {

    @IBOutlet weak var fishIcon: UIImageView!
    @IBOutlet weak var fishName: UILabel!
    @IBOutlet weak var fishDescription: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
