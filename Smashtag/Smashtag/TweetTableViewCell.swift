//
//  TweetTableViewCell.swift
//  Smashtag
//
//  Created by Ömer Yetik on 04/12/2017.
//  Copyright © 2017 Ömer Yetik. All rights reserved.
//

import UIKit
import Twitter

class TweetTableViewCell: UITableViewCell {

    @IBOutlet weak var tweetProfileImageView: UIImageView!
    @IBOutlet weak var tweetUserLabel: UILabel!
    @IBOutlet weak var tweetTextLabel: UILabel!
    @IBOutlet weak var tweetCreatedLabel: UILabel!

    // MARK: - Cell content: Tweet to be displayed
    var tweet: Twitter.Tweet? { didSet { updateUI() } }
    
    // Highlight mentions in tweet body accordingly.
    private func highlightedText(for tweet: Twitter.Tweet?) -> NSMutableAttributedString? {
        if let currentTweet = tweet {
            let highlightedTweetText = NSMutableAttributedString(string:currentTweet.text)
            
            func highlightWordsInCollection(_ collection: Array<Twitter.Mention>, withColor color: UIColor) {
                for item in collection {
                    highlightedTweetText.addAttribute(NSForegroundColorAttributeName, value: color, range: item.nsrange)
                }
            }
            
            highlightWordsInCollection(currentTweet.hashtags, withColor: MentionColors.hashtagColor)
            highlightWordsInCollection(currentTweet.urls, withColor: MentionColors.urlColor)
            highlightWordsInCollection(currentTweet.userMentions, withColor: MentionColors.userMentionColor)
            
            return highlightedTweetText
        } else {
            return nil
        }
    }
    

    
    private func updateUI() {
        tweetTextLabel?.attributedText = highlightedText(for: tweet)
        tweetUserLabel?.text = tweet?.user.description
        
        if let profileImageURL = tweet?.user.profileImageURL {
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: profileImageURL) {
                    DispatchQueue.main.async { [weak self] in
                        self?.tweetProfileImageView?.image = UIImage(data: imageData)
                    }
                }
            }
        } else {
            tweetProfileImageView?.image = nil
        }
        
        if let created = tweet?.created {
            let formatter = DateFormatter()
            if Date().timeIntervalSince(created) > 24*60*60 {
                formatter.dateStyle = .short
            } else {
                formatter.timeStyle = .short
            }
            tweetCreatedLabel?.text = formatter.string(from: created)
        } else {
            tweetCreatedLabel?.text = nil
        }
    }
}
