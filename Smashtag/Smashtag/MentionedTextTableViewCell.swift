//
//  MentionedTextTableViewCell.swift
//  Smashtag
//
//  Created by Ömer Yetik on 21/12/2017.
//  Copyright © 2017 Ömer Yetik. All rights reserved.
//

import UIKit

class MentionedTextTableViewCell: UITableViewCell {

    @IBOutlet weak var mentionedTextLabel: UILabel!

    // MARK: - Contents of the cell
    var mentionedText: String? { didSet { updateUI() } }
    
    private func updateUI() {
        if let text = mentionedText {
            mentionedTextLabel?.text = text
        }
    }
}
