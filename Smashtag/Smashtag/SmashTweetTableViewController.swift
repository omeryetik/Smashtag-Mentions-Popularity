//
//  SmashTweetTableViewController.swift
//  Smashtag
//
//  Created by Ömer Yetik on 06/02/2018.
//  Copyright © 2018 Ömer Yetik. All rights reserved.
//

import UIKit
import Twitter
import CoreData

class SmashTweetTableViewController: TweetTableViewController {
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer

    override func insert(_ newTweets: [Twitter.Tweet]) {
        super.insert(newTweets)
        if searchText != nil { updateDatabase(with: newTweets) }
    }
    
    private func updateDatabase(with tweets: [Twitter.Tweet]) {
        container?.performBackgroundTask { [weak self] (context) in
            
            // Batch add new tweets to database, which means:
            // 1 - Check if any of the new tweets exists already in database
            // 2 - Add non-existing tweets to databsae
            _ = try? Tweet.batchCreateTweets(matching: tweets, forSearch: (self?.searchText)!, in: context)

            try? context.save()
            
            // Recent searches list is limited to 100. Check if there exists any 
            // entities in DB that belongs to searches which no longer exists in
            // recent searches table. Prune those entities from DB
            self?.pruneDatabase(context: context)
            
            try? context.save()
        }
    }
    
    private func pruneDatabase(context: NSManagedObjectContext) {
        if let recentSearches = UserDefaults.standard.stringArray(forKey: Keys.keyForRecentsArray) {
            
            // Fetch mentions with searchText that no longer exists in recents
            let request: NSFetchRequest<Mention> = Mention.fetchRequest()
            request.predicate = NSPredicate(format: "NOT (searchText IN %@)", recentSearches)
            
            if let matches = try? context.fetch(request) {
                if matches.count > 0 {
                    // Delete fetched mentions from DB since 
                    // they are no longer accessible through UI
                    for mention in matches { context.delete(mention) }
                }
            }
            try? context.save()
        }
    }
    
    private func printDatabaseStatistics() {
        if let context = container?.viewContext {
            context.perform {
        
                if Thread.isMainThread {
                    print("on main thread")
                } else {
                    print("off main thread")
                }
                
                let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
                
                if let tweetCount = try? context.fetch(request).count {
                    print("\(tweetCount) tweets")
                }
                
                if let mentionCount = try? context.count(for: Mention.fetchRequest()) {
                    print("\(mentionCount) unique mentions")
                }
                
                let mentionFetchRequest: NSFetchRequest<Mention> = Mention.fetchRequest()
                if let matches = try? context.fetch(mentionFetchRequest) {
                    for item in matches {
                        print("==================================================")
                        print("identifier :: \((item.unique!))")
                        print("popularity :: \(item.popularity)")
                        print("keyword :: \((item.text)!)")
                        print("searchText :: \((item.searchText)!)")
                        print("type :: \((item.type)!)")
                        print("==================================================")
                        print("")
                    }
                }
            }
        }
    }
    

}
