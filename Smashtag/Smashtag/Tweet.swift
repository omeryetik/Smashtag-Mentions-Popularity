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

        return createNewTweet(matching: twitterInfo, forSearch: query, in: context)
    }
    
    class func createNewTweet(matching twitterInfo: Twitter.Tweet, forSearch query: String, in context: NSManagedObjectContext) -> Tweet {
        
        let tweet = Tweet(context: context)
        tweet.unique = twitterInfo.identifier
        
        let hashtagInfo = twitterInfo.hashtags.map { (mention) -> MentionInfo in
            return MentionInfo(type: MentionTypes.hashtag, keyword: mention.keyword, searchText: query)
        }
        
        let userInfo = twitterInfo.userMentions.map { (mention) -> MentionInfo in
            return MentionInfo(type: MentionTypes.userMention, keyword: mention.keyword, searchText: query)
        }
        
        let hashtags = try? Mention.batchCreateMentions(matching: hashtagInfo, in: context)
        let userMentions = try? Mention.batchCreateMentions(matching: userInfo, in: context)
        
        hashtags?.forEach({ (mention) in
            mention.addToUniqueMentioners(tweet)
            mention.popularity = Int32(mention.uniqueMentioners?.count ?? 0)
        })
        
        userMentions?.forEach({ (mention) in
            mention.addToUniqueMentioners(tweet)
            mention.popularity = Int32(mention.uniqueMentioners?.count ?? 0)
        })
        
        return tweet
    }
    
    class func batchCreateTweets(matching infoArray: [Twitter.Tweet], forSearch query: String, in context: NSManagedObjectContext) throws -> [Tweet] {
        
        let identifiersToAdd = infoArray.map { $0.identifier }
        var identifiersNotInDatabase = ArraySlice<String>()
        
        var tweetsInDatabase = Array<Tweet>()
        var tweetsNotInDatabase = Array<Tweet>()
        
        let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
        request.predicate = NSPredicate(format: "unique IN %@", identifiersToAdd)
        
        do {
            let matches = try context.fetch(request)
            let identifiersInDatabase = matches.map { $0.unique }
            identifiersNotInDatabase = identifiersToAdd.drop(while: { (identifier) -> Bool in
                identifiersInDatabase.contains(where: { $0 == identifier } )
            })
            tweetsInDatabase = matches
        } catch {
            throw error
        }
        
        for index in identifiersNotInDatabase.indices {
            tweetsNotInDatabase.append(createNewTweet(matching: infoArray[index], forSearch: query, in: context))
        }
        
        return tweetsNotInDatabase + tweetsInDatabase
    }
}
