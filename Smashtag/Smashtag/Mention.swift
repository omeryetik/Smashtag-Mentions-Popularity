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
        
        let mention = Mention(context: context)
        mention.unique = mentionInfo.identifier
        mention.text = mentionInfo.keyword
        mention.type = mentionInfo.type
        mention.searchText = mentionInfo.searchText
        
        return mention
    }
}
