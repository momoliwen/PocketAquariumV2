//
//  InitialTaskTableViewCell.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 29/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit

class InitialTaskTableViewCell: UITableViewCell {

    
    @IBOutlet weak var taskIconImage: UIImageView!
    
    @IBOutlet weak var taskNameLabel: UILabel!
    
    @IBOutlet weak var taskDescLabel: UILabel!
    
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
