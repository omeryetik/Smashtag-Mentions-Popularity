//
//  MentionedImageTableViewCell.swift
//  Smashtag
//
//  Created by Ömer Yetik on 20/12/2017.
//  Copyright © 2017 Ömer Yetik. All rights reserved.
//

import UIKit

class MentionedImageTableViewCell: UITableViewCell {


    @IBOutlet weak var mentionedImageView: UIImageView!
    
    // MARK: - Cell content: Image URL for cell for mentioned image
    var imageURL: URL? { didSet { updateUI() } }
    
    // MARK: - Update UI when content is updated
    private func updateUI() {
        if let url = imageURL {
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async { [weak self] in
                        self?.mentionedImageView.image = UIImage(data: imageData)
                        self?.mentionedImageView.sizeToFit()
                    }
                }
            }
        }
        
    }

}
