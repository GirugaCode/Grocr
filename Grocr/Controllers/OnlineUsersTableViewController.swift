/// Copyright (c) 2018 Razeware LLC


import UIKit
import Firebase

class OnlineUsersTableViewController: UITableViewController {
    
    // MARK: Constants
    let userCell = "UserCell"
    
    // MARK: Properties
    var currentUsers: [String] = []
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        currentUsers.append("hungry@person.food")
    }
    
    // MARK: UITableView Delegate methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentUsers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: userCell, for: indexPath)
        let onlineUserEmail = currentUsers[indexPath.row]
        cell.textLabel?.text = onlineUserEmail
        return cell
    }
    
    // MARK: Actions
    
    @IBAction func signoutButtonPressed(_ sender: AnyObject) {
        // Get the current user and the online ref attached to it
        let user = Auth.auth().currentUser!
        let onlineRef = Database.database().reference(withPath: "online/\(user.uid)")
        
        // You call removeValue to delete the value for onlineRef. Manually removes the user from being online
        onlineRef.removeValue { (error, _) in
            
            // Checking for error if logging out failed
            if let error = error {
                print("Removing online failed: \(error)")
                return
            }
            
            // Remove the user’s credentials from the keychain
            do {
                try Auth.auth().signOut()
                self.dismiss(animated: true, completion: nil)
            } catch (let error) {
                print("Auth sign out failed: \(error)")
            }
        }
    }
}
