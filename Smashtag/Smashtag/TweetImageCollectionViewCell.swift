//
//  TweetImageCollectionViewCell.swift
//  Smashtag
//
//  Created by Ömer Yetik on 14/01/2018.
//  Copyright © 2018 Ömer Yetik. All rights reserved.
//

import UIKit

class TweetImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    
    // MARK: - Public API
    
    var tweetImage: UniqueTweetImage? {
        didSet {
            updateUI()
        }
    }
    
    // MARK: - Private API
    
    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            spinner.stopAnimating()
        }
    }
    
    private func updateUI() {
        
        if let url = tweetImage?.image.url {
            spinner.startAnimating()
            
            // If image is already in the cache, call it from there and finish
            if let cacheId = tweetImage?.imageId,
                let imageData = cache.object(forKey: cacheId as NSString) {
                image = UIImage(data: imageData as Data)
                return
            }
            
            // Image not found in the cache. Downloat it!
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let urlContents = try? Data(contentsOf: url)
                if let imageData = urlContents,
                    let cacheId = self?.tweetImage?.imageId,
                    url == self?.tweetImage?.image.url {
                    cache.setObject(imageData as NSData, forKey: cacheId as NSString, cost: imageData.count/1024)
                    DispatchQueue.main.async {
                        self?.image = UIImage(data: imageData)
                    }
                }
            }
            
        }
        
    }
}
