//
//  MentionTableViewController.swift
//  Smashtag
//
//  Created by Ömer Yetik on 12/12/2017.
//  Copyright © 2017 Ömer Yetik. All rights reserved.
//

import UIKit
import Twitter
import SafariServices

class MentionTableViewController: RootPoppableTableViewController {

    // MARK: - Public API
    
    var tweet: Twitter.Tweet? {
        didSet {
            mentionsInSections = prepareDataForTableView()
            tableView.reloadData()
            title = tweet!.user.name
        }
    }
    
    
    // MARK: - Private API
    
    // Internal data structure as array of arrays. Mentions divided into 4 sections:
    // - hashtags
    // - urls
    // - user mentions
    // - images
    // Each index in the array encloses another array. 
    // The sub-arrays contain a list of either of the 4 mention types above
    
    private var mentionsInSections: [MentionPack] = [MentionPack]()
    
    private struct MentionPack {
        let type: String
        let items: [MentionType]
    }
    
    private enum MentionType {
        case hashtag(String) // hashtag as String
        case url(String) // url as String
        case userMention(String) // mentioned user as String
        case image(URL, Double) // image url as String, aspect ratio as Double
    }

    
    private func prepareDataForTableView() -> [MentionPack] {
        guard let currentTweet = tweet else { return [] }
        
        var mentionsInTweet = [MentionPack]()
        
        if currentTweet.media.isEmpty {} else {
            mentionsInTweet.append( MentionPack( type: TableProperties.headerForImages,
                                                items: currentTweet.media.map { MentionType.image( $0.url, $0.aspectRatio ) } ) )
        }
        
        if currentTweet.hashtags.isEmpty {} else {
            mentionsInTweet.append( MentionPack( type: TableProperties.headerForHashtags,
                                                 items: currentTweet.hashtags.map { MentionType.hashtag( $0.keyword ) } ) )
        }
        
        if currentTweet.urls.isEmpty {} else {
            mentionsInTweet.append( MentionPack( type: TableProperties.headerForUrls,
                                                 items: currentTweet.urls.map { MentionType.url( $0.keyword ) } ) )
        }
        
        // Extra Credit Task 1: Add tweet owner as a user mention
        // - In such a case, the userMentions section of the table/data structure will never be empty. 
        // - No need for isEmpty check
        
        // Add owner to the list of users first
        var userCollection: [MentionType] = [MentionType.userMention("@\(currentTweet.user.screenName)")]

        // If userMentions is not empty, append them next
        if currentTweet.userMentions.isEmpty {} else {
            userCollection.append( contentsOf: currentTweet.userMentions.map
                { MentionType.userMention( $0.keyword ) } )
        }
        
        // Now append the final array as a new section tot the table/data structure
        mentionsInTweet.append( MentionPack( type: TableProperties.headerForUserMentions,
                                             items: userCollection) )
                
        return mentionsInTweet
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return mentionsInSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return mentionsInSections[section].items.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let mention = mentionsInSections[indexPath.section].items[indexPath.row]
        
        // Get the mention, according to the type choose of of the 2 prototypes:
        // 1 - Image cell, 2 - Text mention cell
        switch mention {
        case .image(let imageURL, _):
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.forImageMentions, for: indexPath)
            if let imageCell = cell as? MentionedImageTableViewCell {
                imageCell.imageURL = imageURL
            }
            return cell
        case .hashtag(let keyword), .url(let keyword), .userMention(let keyword):
            let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.forTextMentions, for: indexPath)
            if let textCell = cell as? MentionedTextTableViewCell {
                textCell.mentionedText = keyword
            }
            return cell
        }
        
    }


    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return mentionsInSections[section].type
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let mention = mentionsInSections[indexPath.section].items[indexPath.row]
        let rowWidth = tableView.frame.width
        switch mention {
        case .image(_, let aspectRatio):
            return rowWidth / CGFloat(aspectRatio)
        default:
            return UITableViewAutomaticDimension
        }
    }
    
    // Initiate segues by using didSelectRowAt method
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let mention = mentionsInSections[indexPath.section].items[indexPath.row]
        let identifier = cell?.reuseIdentifier
        if identifier == CellIdentifiers.forTextMentions {
            // Mention is text, not image
            switch mention {
            case .url(let urlString):
                // Selected mention is a URL. Open in Safari
                if let url = URL(string: urlString) {
                    // Extra Credit #4: Use not Safari but an internal controller to show
                    // web content in app
                    let safariVC = SFSafariViewController(url: url, entersReaderIfAvailable: true)
                    safariVC.modalPresentationStyle = .popover
                    safariVC.modalTransitionStyle = .flipHorizontal
                    present(safariVC, animated: true, completion: nil)
//                    if #available(iOS 10.0, *) {
//                        UIApplication.shared.open(url)
//                    } else {
//                        UIApplication.shared.openURL(url)
//                    }
                }
            default:
                // Other text mentions, perform segue to TweetTableViewController 
                // to initiate a new search
                performSegue(withIdentifier: SegueIdentifiers.fromMentionToSearch, sender: cell)
            }
        } else if identifier == CellIdentifiers.forImageMentions {
            // Mention is an image. Segue to the image VC
            performSegue(withIdentifier: SegueIdentifiers.fromMentionToImage, sender: cell)
        }
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let identifier = segue.identifier
        let destination = segue.destination

        if identifier == SegueIdentifiers.fromMentionToSearch {
            if let tweetTVC = destination.contents as? TweetTableViewController,
                let mentionCell = sender as? MentionedTextTableViewCell {
                // Extra Credit Task 2:
                // If selected mention is a userMention, search not only for tweets mentioning
                // this user but also for tweets by this user
                var searchText = mentionCell.mentionedText ?? ""
                searchText = searchText.hasPrefix("@") ? "\(searchText) OR from:\(searchText)" : searchText
                tweetTVC.searchText = searchText
            }
        } else if identifier == SegueIdentifiers.fromMentionToImage {
            if let imageVC = destination.contents as? ImageViewController,
                let imageCell = sender as? MentionedImageTableViewCell {
                imageVC.imageURL = imageCell.imageURL
                imageVC.title = title
            }
        }
    }


}
