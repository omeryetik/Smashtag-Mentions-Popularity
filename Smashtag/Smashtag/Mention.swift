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
        let mention = Mention(context: context)
        mention.unique = mentionInfo.identifier
        mention.text = mentionInfo.keyword
        mention.type = mentionInfo.type
        mention.searchText = mentionInfo.searchText
        
        return mention
    }
    
    class func batchCreateMentions(matching infoArray: [MentionInfo], in context: NSManagedObjectContext) throws -> [Mention] {
        
        let identifiersToAdd = infoArray.map { $0.identifier }
        var identifiersNotInDatabase = ArraySlice<String>()
        
        var mentionsInDatabase = Array<Mention>()
        var mentionsNotInDatabase = Array<Mention>()
        
        let request: NSFetchRequest<Mention> = Mention.fetchRequest()
        request.predicate = NSPredicate(format: "unique IN %@", identifiersToAdd)
        
        do {
            let matches = try context.fetch(request)
            let identifiersInDatabase = matches.map { $0.unique }
            identifiersNotInDatabase = identifiersToAdd.drop(while: { (identifier) -> Bool in
                identifiersInDatabase.contains(where: { $0 == identifier } )
            })
            mentionsInDatabase = matches
        } catch {
            throw error
        }
        
        for index in identifiersNotInDatabase.indices {
            mentionsNotInDatabase.append(createNewMention(matching: infoArray[index], in: context))
        }
        
        return mentionsNotInDatabase + mentionsInDatabase
    }
}
