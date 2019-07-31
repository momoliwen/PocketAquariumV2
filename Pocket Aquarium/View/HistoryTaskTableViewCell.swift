//
//  HistoryTaskTableViewCell.swift
//  Pocket Aquarium
//
//  Created by Liangliwen on 30/10/18.
//  Copyright © 2018 Monash University. All rights reserved.
//

import UIKit

protocol EditTaskStateDelegate {
    func editTaskState(index : Int)
}

class HistoryTaskTableViewCell: UITableViewCell {

    @IBOutlet weak var taskIconImage: UIImageView!
    @IBOutlet weak var taskName: UILabel!
    @IBOutlet weak var taskStateDescLabel: UILabel!
    @IBOutlet weak var taskStateLabel: UILabel!
    @IBOutlet weak var operationButton: UIButton!
    
    var indexPath : IndexPath?
    var taskDelegate : EditTaskStateDelegate?
    
    @IBAction func taskOperation(_ sender: UIButton) {
        taskDelegate?.editTaskState(index: (indexPath?.row)!)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
