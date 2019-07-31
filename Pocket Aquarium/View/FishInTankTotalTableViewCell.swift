//
//  FishInTankTotalTableViewCell.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 28/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit

class FishInTankTotalTableViewCell: UITableViewCell {

    
    @IBOutlet weak var fishTotalLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    //MARK: customize the collection cell view
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundView?.setGradientBackground(colorMain: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), colorSecond: #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1))
    }

}
