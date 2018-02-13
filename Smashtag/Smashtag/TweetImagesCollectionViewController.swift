//
//  ImagesCollectionViewController.swift
//  Smashtag
//
//  Created by Ömer Yetik on 13/01/2018.
//  Copyright © 2018 Ömer Yetik. All rights reserved.
//

import UIKit
import Twitter

class TweetImagesCollectionViewController: UICollectionViewController {

    // MARK: - Public API
    var tweets = Array<Twitter.Tweet>() {
        didSet {
            tweetImageCollection = prepareTweetImageCollection()
            collectionView?.reloadData()
        }
    }
    
    // MARK: - Private API
    fileprivate var tweetImageCollection = [UniqueTweetImage]()
    
    private func prepareTweetImageCollection() -> [UniqueTweetImage] {
        var tweetCollection = [UniqueTweetImage]()
        
        tweetCollection = tweets.flatMap { tweet -> [UniqueTweetImage] in
            if tweet.media.isEmpty { return [] } else {
                let imageCollection = tweet.media.enumerated().map { index, item in
                    UniqueTweetImage(image: item,
                                     imageId: "\(tweet.identifier).\(index)", tweet: tweet)
                }
                return imageCollection
            }
        }
        
        return tweetCollection
    }
    
    // MARK: - Private Properties
    
    fileprivate let reuseIdentifier = CellIdentifiers.forImagesInTweetCollection
    fileprivate let itemsPerRow: CGFloat = 3
    fileprivate let itemsPerColumn: CGFloat = 3
    fileprivate let sectionInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        let handler = #selector(changeScale(byReactingTo:))
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: handler)
        collectionView?.addGestureRecognizer(pinchRecognizer)
    }


    // MARK: - Gesture Recognizers
    
    var scale: CGFloat = 1.0 {
        didSet {
            collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    
    func changeScale(byReactingTo pinchRecognizer: UIPinchGestureRecognizer) {
        switch pinchRecognizer.state {
        case .changed, .ended:
            scale *= pinchRecognizer.scale
            pinchRecognizer.scale = 1.0
        default:
            break
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination
        let identifier = segue.identifier

        if identifier == SegueIdentifiers.fromImageCollectionToTweets {
            if let cell = sender as? TweetImageCollectionViewCell {
                if let tweetsTVC = destination.contents as? TweetTableViewController {
                    if let indexPath = collectionView?.indexPath(for: cell) {
                        let tweet = tweetImageCollection[indexPath.row].tweet
                        tweetsTVC.insert([tweet])
                    }
                }
            }
        }
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return tweetImageCollection.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        let uniqueImage = tweetImageCollection[indexPath.row]
    
        // Configure the cell
        cell.backgroundColor = UIColor.white
        if let imageCell = cell as? TweetImageCollectionViewCell {
            imageCell.tweetImage = uniqueImage
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? TweetImageCollectionViewCell {
            performSegue(withIdentifier: SegueIdentifiers.fromImageCollectionToTweets, sender: cell)
        }
    }
    
}

// MARK: - UICollectionViewDelegateFlowLayout
extension TweetImagesCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // paddingSpace = 1*leading + 1*trailing + 2*interItem
        let paddingWidth = sectionInsets.left * (itemsPerRow + 1)
        let paddingHeight = sectionInsets.top * (itemsPerColumn + 1)
        
        let availableWidth = view.frame.width - paddingWidth
        let availableHeight = view.frame.height - paddingHeight
        
        let availableArea = (availableWidth * availableHeight) * scale
        let areaPerItem = availableArea / (itemsPerRow * itemsPerColumn)
        
        let aspectRatio = CGFloat(tweetImageCollection[indexPath.row].image.aspectRatio)
        let witdhForItem = sqrt(areaPerItem * aspectRatio)
        let heightForItem = witdhForItem / aspectRatio
        
        return CGSize(width: witdhForItem, height: heightForItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
}
