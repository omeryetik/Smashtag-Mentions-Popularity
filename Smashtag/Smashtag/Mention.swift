//
//  Mention.swift
//  Smashtag
//
//  Created by Ömer Yetik on 11/02/2018.
//  Copyright © 2018 Ömer Yetik. All rights reserved.
//

import UIKit
import CoreData
import Twitter

class Mention: NSManagedObject {

    class func findCreateMention(matching mentionInfo: MentionInfo, in context: NSManagedObjectContext) throws -> Mention {
        let request: NSFetchRequest<Mention> = Mention.fetchRequest()
        request.predicate = NSPredicate(format: "unique ==[c] %@", mentionInfo.identifier)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "findCreateMention - database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        return createNewMention(matching: mentionInfo, in: context)
    }
    
    class func createNewMention(matching mentionInfo: MentionInfo, in context: NSManagedObjectContext) -> Mention {
        
        // If we are here, we are provided with a Mention not existing in DB
        // Create new entity, set attributres
        let mention = Mention(context: context)
        mention.unique = mentionInfo.identifier
        mention.text = mentionInfo.keyword
        mention.type = mentionInfo.type
        mention.searchText = mentionInfo.searchText
        
        try? context.save()
        
        return mention
    }
    
    // Batch add a group of new mentions (hashtags or user mentions) to DB
    class func batchCreateMentions(matching infoArray: [MentionInfo], in context: NSManagedObjectContext) throws -> [Mention] {

        // Extract unique ID for all new mentions
        //      Unique ID for each mention is a String which is the searchText
        //      and mention keyword joined with a dot. The identifier is 
        //      lowercased to merge all different appearances of the same 
        //      keyword in one single Mention entity. Check definition of 
        //      MentionInfo struct in SmashtagCommons.swift file.
        let identifiers = infoArray.map { $0.identifier }
        
        // Filter duplicates and determine all identifiers to add to DB
        let identifiersToAdd = Array(Set(identifiers))
        
        // Hold IDs for tweets that already exist in DB
        var identifiersNotInDatabase = Array<String>()
        
        var mentionsInDatabase = Array<Mention>()
        var mentionsNotInDatabase = Array<Mention>()
        
        // Check if any of the mentions in infoArray already exists in DB
        //      1 - Set predicate to fetch tweets with IDs in identifersToAdd
        //      2 - If fetch returns any matches, filter them out from identifiersToAdd
        //      3 - Hold mentions already in DB
        //      4 - Add non-existing mentions to DB
        //      5 - Return all Mention entities at the end
        let request: NSFetchRequest<Mention> = Mention.fetchRequest()
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
                mentionsInDatabase = matches
            } else {
                // No matches found, so all new mentions should be added to DB
                identifiersNotInDatabase = identifiersToAdd
            }
        } catch {
            throw error
        }

        // 4
        infoArray.forEach { (mentionInfo) in
            identifiersNotInDatabase.forEach { (identifier) in
                // For each identifier not in DB check infoArray for corrspondng tweet
                if mentionInfo.identifier == identifier {
                    // Add corresponding mention to DB
                    mentionsNotInDatabase.append(Mention.createNewMention(matching: mentionInfo, in: context))
                    // Remove identifier from identifiersNotInDB since
                    // corresponding mention is already added to DB
                    identifiersNotInDatabase.remove(at: (identifiersNotInDatabase.index(of: identifier))!)
                }
            }
        }
        
        // 5
        return mentionsNotInDatabase + mentionsInDatabase
    }
    
    override func prepareForDeletion() {
        // When pruning database due to dismissed searchTexts from recents,
        // we are deleting Mention entities from DB.
        // For each deleted Mention entity
        //      1 - Remove deleted Mention from mentions set of all its unique 
        //          mentioner tweets
        //      2 - Check mentions count of each tweet in unique mentioners 
        //          after droping the deleted mention.
        //      3 - If mentions count for the tweet becomes 0, delete the Tweet 
        //          from the DB as well.
        
        if let uniqueMentioners = self.uniqueMentioners as? Set<Tweet> {
            for tweet in uniqueMentioners {
                // 1
                tweet.removeFromMentions(self)
                if let mentionCount = tweet.mentions?.count {
                    // 2
                    if mentionCount == 0 {
                        // 3
                        self.managedObjectContext?.delete(tweet)
                    }
                }
            }
        }
    }
}
