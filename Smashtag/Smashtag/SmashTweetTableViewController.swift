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
        updateDatabase(with: newTweets)
    }
    
    private func updateDatabase(with tweets: [Twitter.Tweet]) {
        print("starting database load")
        container?.performBackgroundTask { [weak self] (context) in
            for twitterInfo in tweets {
                // add new tweet to DB
                _ = try? Tweet.findCreateTweet(matching: twitterInfo, forSearch: (self?.searchText)!, in: context)
            }
            try? context.save()
            print("done loading database")
            self?.printDatabaseStatistics()
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
                        print("popularity :: \(item.popoularity)")
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
