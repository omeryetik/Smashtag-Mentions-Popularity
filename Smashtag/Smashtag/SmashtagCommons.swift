//
//  SmashtagCommons.swift
//  Smashtag
//
//  Created by Ömer Yetik on 26/12/2017.
//  Copyright © 2017 Ömer Yetik. All rights reserved.
//

import Foundation
import UIKit
import Twitter

struct MentionInfo {
    let type: String
    let keyword: String
    let identifier: String
    let searchText: String
}

struct MentionTypes {
    static let hashtag = "Hashtags"
    static let userMention = "User Mentions"
}

struct MentionColors {
    static let hashtagColor:     UIColor = .brown
    static let urlColor:         UIColor = .blue
    static let userMentionColor: UIColor = .orange
}

struct TableProperties {
    static let headerForImages = "Images"
    static let headerForHashtags = "Hashtags"
    static let headerForUrls = "URLs"
    static let headerForUserMentions = "Users"
}

struct Keys {
    static let keyForRecentsArray = "Default.recent.searches"
}

struct SegueIdentifiers {
    static let fromMentionToImage = "Segue.show.image"
    static let fromMentionToSearch = "Segue.show.tweets.from.mention"
    static let fromRecentToSearch = "Segue.show.tweets.from.recent"
    static let fromTweetsToMentions = "Segue.show.mentions.from.tweets"
    static let fromTweetsToImageCollection = "Segue.show.image.collection.from.tweets"
    static let fromImageCollectionToTweets = "Segue.show.tweet.from.collection.to.tweets"
    static let fromRecentToPopularMentions = "Segue.show.popular.mentions.from.recents"
}

struct CellIdentifiers {
    static let forTextMentions = "Cell.mention.text"
    static let forImageMentions = "Cell.mention.image"
    static let forTweets = "Cell.tweet"
    static let forRecents = "Cell.recent"
    static let forImagesInTweetCollection = "Cell.tweet.collection.image"
}

struct UniqueTweetImage {
    let image: MediaItem
    let imageId: String
    let tweet: Twitter.Tweet
}

var cache = NSCache<NSString, NSData>()

extension UIViewController {
    var contents: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? self
        } else {
            return self
        }
    }
}
