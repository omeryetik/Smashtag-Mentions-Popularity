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
        request.predicate = NSPredicate(format: "unique == %@", twitterInfo.identifier)
        
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
        
        // If we are here, we are provided with a tweet not existing in DB
        // Create new entity, set attributres
        let tweet = Tweet(context: context)
        tweet.unique = twitterInfo.identifier
        
        // Check for hashtags in the new tweet and create info structs for each
        let hashtagInfo = twitterInfo.hashtags.map { (mention) -> MentionInfo in
            return MentionInfo(type: MentionTypes.hashtag, keyword: mention.keyword, searchText: query)
        }
        
        // Check for user mentions in the new tweet and create info structs for each
        let userInfo = twitterInfo.userMentions.map { (mention) -> MentionInfo in
            return MentionInfo(type: MentionTypes.userMention, keyword: mention.keyword, searchText: query)
        }
        
        // If there are hashtags, add them to DB
        if hashtagInfo.count > 0 {
            // add all hashtags to DB in batch
            let hashtags = try? Mention.batchCreateMentions(matching: hashtagInfo, in: context)
            
            // for each Mention entity added to DB, 
            //      1 - add referring tweet to uniqueMentioners relationship NSSet
            //      2 - update popularity count
            hashtags?.forEach({ (mention) in
                mention.addToUniqueMentioners(tweet)
                mention.popularity = Int32(mention.uniqueMentioners?.count ?? 0)
            })
        }
        
        // If there are user mentions, add them to DB
        if userInfo.count > 0 {
            // add all user mentions to DB in batch
            let userMentions = try? Mention.batchCreateMentions(matching: userInfo, in: context)
            
            // for each Mention entity added to DB,
            //      1 - add referring tweet to uniqueMentioners relationship NSSet
            //      2 - update popularity count
            userMentions?.forEach({ (mention) in
                mention.addToUniqueMentioners(tweet)
                mention.popularity = Int32(mention.uniqueMentioners?.count ?? 0)
            })
        }

        try? context.save()
        
        return tweet
    }
    
    // Batch add a group of new tweets to DB
    class func batchCreateTweets(matching infoArray: [Twitter.Tweet], forSearch query: String, in context: NSManagedObjectContext) throws -> [Tweet] {
        
        // Extract unique ID for all new tweets
        let identifiers = infoArray.map { $0.identifier }
        
        // Filter duplicates and determine all identifiers to add to DB
        let identifiersToAdd = Array(Set(identifiers))
        
        // Hold IDs for tweets that already exist in DB
        var identifiersNotInDatabase = Array<String>()
        
        var tweetsInDatabase = Array<Tweet>()
        var tweetsNotInDatabase = Array<Tweet>()
        
        // Check if any of the tweets in infoArray already exists in DB
        //      1 - Set predicate to fetch tweets with IDs in identifersToAdd
        //      2 - If fetch returns any matches, filter them out from identifiersToAdd
        //      3 - Hold tweets already in DB
        //      4 - Add non-existing tweets to DB 
        //      5 - Return all Tweet entities at the end
        let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
        // 1
        request.predicate = NSPredicate(format: "unique IN %@", identifiersToAdd)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                // 2
                let identifiersInDatabase = matches.map { ($0.unique)! }
                identifiersNotInDatabase = identifiersToAdd.filter { (element) -> Bool in
                    !(identifiersInDatabase.contains(element))
                }
                // 3
                tweetsInDatabase = matches
            } else {
                // No matches found, so all new tweets should be added to DB
                identifiersNotInDatabase = identifiersToAdd
            }
        } catch {
            throw error
        }

        // 4
        infoArray.forEach { (tweetInfo) in
            identifiersNotInDatabase.forEach { (identifier) in
                // For each identifier not in DB check infoArray for corrspondng tweet
                if tweetInfo.identifier == identifier {
                    // Add corresponding tweet to DB
                    tweetsNotInDatabase.append(Tweet.createNewTweet(matching: tweetInfo, forSearch: query, in: context))
                    // Remove identifier from identifiersNotInDB since 
                    // corresponding tweet is already added to DB
                    identifiersNotInDatabase.remove(at: (identifiersNotInDatabase.index(of: identifier))!)
                }
            }
        }
        
        // 5
        return tweetsNotInDatabase + tweetsInDatabase
    }
}
