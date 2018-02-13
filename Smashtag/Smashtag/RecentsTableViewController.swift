//
//  RecentsTableViewController.swift
//  Smashtag
//
//  Created by Ömer Yetik on 26/12/2017.
//  Copyright © 2017 Ömer Yetik. All rights reserved.
//

import UIKit

class RecentsTableViewController: RootPoppableTableViewController {

    // MARK: - No public API needed
    
    // MARK: - Private API
    
    // Internal data structure. Set before view appears on screen
    private var recentSearches: [String]? {
        didSet {
            if isDeletingARow == false {
                tableView.reloadData()
            } else {
                isDeletingARow = false
            }
        }
    }
    
    private var isDeletingARow: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recentSearches = UserDefaults.standard.stringArray(forKey: Keys.keyForRecentsArray) ?? []
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.standard.set(recentSearches, forKey: Keys.keyForRecentsArray)
    }

    // MARK: - Table view data source
    // -------------------------------

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentSearches!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.forRecents, for: indexPath)

        let recentSearchTerm = recentSearches?[indexPath.row]
        
        cell.textLabel?.text = recentSearchTerm

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        performSegue(withIdentifier: SegueIdentifiers.fromRecentToSearch, sender: cell)
    }
    
    // MARK: - Table View Delegate
    // ----------------------------
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if let searchTerm = recentSearches?[indexPath.row] {
            showPopularMentions(for: searchTerm)
        }
    }
    
    private func showPopularMentions(for searchTerm: String) {
        
    }
    
    // MARK: - Delete Rows
    // -------------------------
    // Extra Credit Task #5: Allow deletion of recent search terms.
    // Override to support conditional editing of the table view.
    @IBAction func startEditing(_ sender: UIBarButtonItem) {
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.allowsSelectionDuringEditing = false
        tableView.setEditing(true, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            isDeletingARow = true
            recentSearches?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .bottom)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    //------------------------------

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let identifier = segue.identifier
        let destination = segue.destination
        
        if identifier == SegueIdentifiers.fromRecentToSearch {
            if let tweetVC = destination as? TweetTableViewController {
                if let recentCell = sender as? UITableViewCell {
                    tweetVC.searchText = recentCell.textLabel?.text
                }
            }
        }
    }


}
