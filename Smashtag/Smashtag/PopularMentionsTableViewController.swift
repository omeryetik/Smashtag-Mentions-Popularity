//
//  PopularMentionsTableViewController.swift
//  Smashtag
//
//  Created by Ömer Yetik on 13/02/2018.
//  Copyright © 2018 Ömer Yetik. All rights reserved.
//

import UIKit
import CoreData
import Twitter

class PopularMentionsTableViewController: FetchedResultsTableViewController {
    
    // MARK: - Public API
    
    var container: NSPersistentContainer? = ((UIApplication.shared.delegate as? AppDelegate)?.persistentContainer)! { didSet { updateUI() } }
    
    var searchTerm: String? {
        didSet {
            title = searchTerm
            updateUI()
        }
    }
    
    // MARK: Private API
    fileprivate var fetchedResultsController: NSFetchedResultsController<Mention>?

    private func updateUI() {
        if let context = container?.viewContext {
            context.perform { [weak self] in
                // Fetch mentions with the chosen searchText
                let request: NSFetchRequest<Mention> = Mention.fetchRequest()
                request.predicate = NSPredicate(format: "searchText ==[c] %@", (self?.searchTerm)!)
                
                // 3-level sorting
                // - 1. According to type (hashtag or user) - Will corrspond to tableView sections
                // - 2. According to popularity count
                // - 3. If popularity counts are equal, sort alphabetically
                let sortA = NSSortDescriptor(key: "type", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
                let sortB = NSSortDescriptor(key: "popularity", ascending: false)
                let sortC = NSSortDescriptor(key: "text", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
                 request.sortDescriptors = [sortA, sortB, sortC]
                
                self?.fetchedResultsController = NSFetchedResultsController(
                    fetchRequest: request,
                    managedObjectContext: context,
                    sectionNameKeyPath: "type",
                    cacheName: nil
                )
                
                self?.fetchedResultsController?.delegate = self
                try? self?.fetchedResultsController?.performFetch()
                self?.tableView.reloadData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.forPopularMentions, for: indexPath)
        if let mention = fetchedResultsController?.object(at: indexPath) {
            cell.textLabel?.text = mention.text
            cell.detailTextLabel?.text = "\(mention.popularity) unique tweets"
        }
        return cell
    }
    
    // If any of the mentions are selected, segue to initial tweets table view controller
    // to show a list of 100 recent tweets corresponding to selected mention
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let mention = fetchedResultsController?.object(at: indexPath) {
            performSegue(withIdentifier: SegueIdentifiers.fromPopularMentionToTweets, sender: mention)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination
        let identifier = segue.identifier
        
        if identifier == SegueIdentifiers.fromPopularMentionToTweets {
            if let tweetsTVC = destination.contents as? SmashTweetTableViewController {
                if let mention = sender as? Mention {
                    tweetsTVC.searchText = mention.text
                }
            }
        }
    }
}

extension PopularMentionsTableViewController
{
    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[section].name
        } else {
            return nil
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController?.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultsController?.section(forSectionIndexTitle: title, at: index) ?? 0
    }
}
