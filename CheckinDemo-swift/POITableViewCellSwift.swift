//
//  POITableViewCellSwift.swift
//  CheckinDemo
//
//  Created by eidan on 2017/3/30.
//  Copyright © 2017年 Amap. All rights reserved.
//

import UIKit

class POITableViewCellSwift: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var selectedImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
