//
//  RealtimeTableViewCell.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 3/11/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit

class RealtimeTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var tankNameLabel: UILabel!
    @IBOutlet weak var pHlabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
