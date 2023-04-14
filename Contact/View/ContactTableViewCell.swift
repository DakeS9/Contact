//
//  ContactTableViewCell.swift
//  Contact
//
//  Created by Dauren Sunnatulla on 30.11.2022.
//

import UIKit

class ContactTableViewCell: UITableViewCell {

    static let identifier: String = "ContactTableViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
    }
}
