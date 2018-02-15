//
//  SearchTerm.swift
//  Smashtag
//
//  Created by Ömer Yetik on 15/02/2018.
//  Copyright © 2018 Ömer Yetik. All rights reserved.
//

import UIKit
import CoreData
import Twitter

class SearchTerm: NSManagedObject {
    
    class func findCreateSearchTerm(matching text: String,
                                    in context: NSManagedObjectContext) throws -> SearchTerm
    {
        let request: NSFetchRequest<SearchTerm> = SearchTerm.fetchRequest()
        request.predicate = NSPredicate(format: "text ==[c] %@", text)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "-- findCreateSearchTerm :: database inconsistency --")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let searchTerm = SearchTerm(context: context)
        searchTerm.text = text
        searchTerm.created = Date() as NSDate
        
        return searchTerm
    }
    
    class func createSearchTerm(matching text: String, fetching tweets: [Twitter.Tweet], in context: NSManagedObjectContext) throws -> SearchTerm {
        let searchTerm = try! findCreateSearchTerm(matching: text, in: context)

        let createdTweets = try! Tweet.batchCreateTweets(matching: tweets, forSearch: text, in: context)
        
        createdTweets.forEach { (tweet) in
            tweet.addToSearchTerms(searchTerm)
            if let mentions = tweet.mentions {
                searchTerm.addToMentions(mentions)
            }
        }
        
        return searchTerm
    }
}
