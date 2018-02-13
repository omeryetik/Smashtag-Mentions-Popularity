//
//  Tweet.swift
//  Smashtag
//
//  Created by Ömer Yetik on 11/02/2018.
//  Copyright © 2018 Ömer Yetik. All rights reserved.
//

import UIKit
import CoreData
import Twitter

class Tweet: NSManagedObject {
    
    class func findCreateTweet(matching twitterInfo: Twitter.Tweet, forSearch query: String, in context: NSManagedObjectContext) throws -> Tweet {
        let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
        request.predicate = NSPredicate(format: "unique = %@", twitterInfo.identifier)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "findCreateTweet - database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let tweet = Tweet(context: context)
        tweet.unique = twitterInfo.identifier
        
        for hashtag in twitterInfo.hashtags {
            // add each item as a mention
            let identifier = "\(query).\(hashtag.keyword)"
            let mentionInfo = MentionInfo(type: MentionTypes.hashtag, keyword: hashtag.keyword, identifier: identifier, searchText: query)
            let hashtag = try? Mention.findCreateMention(matching: mentionInfo, in: context)
            hashtag?.addToUniqueMentioners(tweet)
            hashtag?.popoularity = Int32(hashtag?.uniqueMentioners?.count ?? 0)
        }
        
        for userMention in twitterInfo.userMentions {
            // add each item as a mention
            let identifier = "\(query).\(userMention.keyword)"
            let mentionInfo = MentionInfo(type: MentionTypes.userMention, keyword: userMention.keyword, identifier: identifier, searchText: query)
            let userMention = try? Mention.findCreateMention(matching: mentionInfo, in: context)
            userMention?.addToUniqueMentioners(tweet)
            userMention?.popoularity = Int32(userMention?.uniqueMentioners?.count ?? 0)
        }
        
        return tweet
    }
}
