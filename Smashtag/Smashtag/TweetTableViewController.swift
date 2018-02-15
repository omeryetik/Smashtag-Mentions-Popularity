//
//  TweetTableViewController.swift
//  Smashtag
//
//  Created by Ömer Yetik on 03/12/2017.
//  Copyright © 2017 Ömer Yetik. All rights reserved.
//

import UIKit
import Twitter

class TweetTableViewController: RootPoppableTableViewController, UITextFieldDelegate {

    // MARK: - Model

    private var tweets = [Array<Twitter.Tweet>]() 
    
    var searchText: String? {
        didSet {
            searchTextField?.text = searchText
            searchTextField?.resignFirstResponder()
            lastTwitterRequest = nil
            tweets.removeAll()
            tableView.reloadData()
            searchForTweets()
            title = searchText
            // Each time searchText is updated, a new search is initiated.
            // Add this to recent searches list
            addToRecentSearches(searchText)
        }
    }
    
    func insert(_ newTweets: [Twitter.Tweet]) {
        tweets.insert(newTweets, at: 0)
        tableView.insertSections([0], with: .fade)
    }
    
    private func twitterRequest() -> Twitter.Request? {
        if let query = searchText, !query.isEmpty {
            return Twitter.Request(search: "\(query) -filter:unsafe -filter:retweets", count: 5)
        }
        return nil
    }
    
    private var lastTwitterRequest: Twitter.Request?
    
    private func searchForTweets() {
        if let request = lastTwitterRequest?.newer ?? twitterRequest() {
            lastTwitterRequest = request
            request.fetchTweets { [weak self] newTweets in
                DispatchQueue.main.async {
                    if request == self?.lastTwitterRequest {
                        self?.insert(newTweets)
                    }
                    self?.refreshControl?.endRefreshing()
                }
            }
        } else {
            self.refreshControl?.endRefreshing()
        }
    }
    
    // Helper function to add each search to Recent searches
    private func addToRecentSearches(_ text: String?) {
        if let searchText = text {

            if var recentSearches = UserDefaults.standard.stringArray(forKey: Keys.keyForRecentsArray) {
                // Recent searches array exists in UserDefaults already. Fetch it,
                // add the new term and save defaults.
                
                // If the term exists in the list already, drop it to re-add again to
                recentSearches = recentSearches.filter({ (element) -> Bool in
                    element.caseInsensitiveCompare(searchText) != ComparisonResult.orderedSame
                })
                // Add the term now - either it existed before or never - and it will
                // be on top of the list
                recentSearches.insert(searchText, at: 0)
                UserDefaults.standard.set(recentSearches, forKey: Keys.keyForRecentsArray)

            } else {
                // No search term is saved yet. Create the array and add the term in.
                // Then save it to UserDefaults
                let recentSearches = [searchText]
                UserDefaults.standard.set(recentSearches, forKey: Keys.keyForRecentsArray)
            }
        }
    }
    
    @IBAction func refresh(_ sender: UIRefreshControl) {
        searchForTweets()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField.delegate = self
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == searchTextField {
            searchText = searchTextField.text
        }
        return true
    }
    
    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tweets.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets[section].count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.forTweets, for: indexPath)

        let tweet: Twitter.Tweet = tweets[indexPath.section][indexPath.row]
        if let tweetCell = cell as? TweetTableViewCell {
            tweetCell.tweet = tweet
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(tweets.count - section)"
    }

    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == SegueIdentifiers.fromTweetsToImageCollection {
            return searchText == nil ? false : true
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let identifier = segue.identifier
        let destination = segue.destination
        
        if identifier == SegueIdentifiers.fromTweetsToMentions {
            if let mTVC = destination.contents as? MentionTableViewController {
                if let tweetCell = sender as? TweetTableViewCell {
                    mTVC.tweet = tweetCell.tweet
                }
            }
        } else if identifier == SegueIdentifiers.fromTweetsToImageCollection {
            if let tiCVC = destination.contents as? TweetImagesCollectionViewController {
                tiCVC.tweets = tweets.flatMap { $0 }
                tiCVC.title = "Images: \(searchText!)"
            }
        }
    }

}
