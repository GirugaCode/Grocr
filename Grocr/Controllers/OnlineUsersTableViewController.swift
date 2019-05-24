/// Copyright (c) 2018 Razeware LLC


import UIKit
import Firebase

class OnlineUsersTableViewController: UITableViewController {
    
    // MARK: Constants
    let userCell = "UserCell"
    
    // MARK: Properties
    var currentUsers: [String] = []
    let usersRef = Database.database().reference(withPath: "online")
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: UIViewController Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayOnlineUsers()
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
    
    // MARK: Function
    func displayOnlineUsers() {
        // Observer that listens for children added to the location managed by usersRef
        usersRef.observe(.childAdded, with: { snap in
            // Take the value from the snapshot, and then append it to the local array
            guard let email = snap.value as? String else { return }
            self.currentUsers.append(email)
            // The current row is always the count of the local array minus one. The length of the array
            let row = self.currentUsers.count - 1
            // Create an instance NSIndexPath using the calculated row index
            let indexPath = IndexPath(row: row, section: 0)
            // Insert the row using an animation that causes the cell to be inserted from the top
            self.tableView.insertRows(at: [indexPath], with: .top)
        })
        
        // Observer that listens for children that are signed out of the app
        usersRef.observe(.childRemoved, with: { snap in
            guard let emailToFind = snap.value as? String else { return }
            for (index, email) in self.currentUsers.enumerated() {
                if email == emailToFind {
                    let indexPath = IndexPath(row: index, section: 0)
                    self.currentUsers.remove(at: index)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        })

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
