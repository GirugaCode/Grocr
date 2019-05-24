/// Copyright (c) 2018 Razeware LLC

import UIKit
import Firebase

class GroceryListTableViewController: UITableViewController {
    
    // MARK: Constants
    let listToUsers = "ListToUsers"
    let ref = Database.database().reference(withPath: "grocery-items")
    
    // MARK: Properties
    var items: [GroceryItem] = []
    var user: User!
    var userCountBarButtonItem: UIBarButtonItem!
    let usersRef = Database.database().reference(withPath: "online")
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelectionDuringEditing = false
        
        userCountBarButtonItem = UIBarButtonItem(title: "1",
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(userCountButtonDidTouch))
        userCountBarButtonItem.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = userCountBarButtonItem
        
        user = User(uid: "FakeId", email: "hungry@person.food")
        
        sortCheckedItems()
        
        synchronizeData()
        
        // An authentication observer to the Firebase auth object, which in turn assigns the user property when a user successfully signs in.
        Auth.auth().addStateDidChangeListener { auth, user in
            guard let user = user else { return }
            self.user = User(authData: user)
            
            // Create a child reference using a user’s uid
            let currentUserRef = self.usersRef.child(self.user.uid)
            // Uses the current reference to save the current user's email
            currentUserRef.setValue(self.user.email)
            // Removes the value at the reference’s location after the connection to Firebase closes
            currentUserRef.onDisconnectRemoveValue()

        }
    }
    
    // MARK: UITableView Delegate methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        let groceryItem = items[indexPath.row]
        
        cell.textLabel?.text = groceryItem.name
        cell.detailTextLabel?.text = groceryItem.addedByUser
        
        toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Deletes an item from the tableview and firebase
        if editingStyle == .delete {
            let groceryItem = items[indexPath.row]
            groceryItem.ref?.removeValue()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Find the cell the user tapped using cellForRow(at:)
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        // Get the corresponding GroceryItem by using the index path’s row
        let groceryItem = items[indexPath.row]
        // Negate completed on the grocery item to toggle the status
        let toggledCompletion = !groceryItem.completed
        
        // Call toggleCellCheckbox(_:isCompleted:) to update the visual properties of the cell.
        toggleCellCheckbox(cell, isCompleted: toggledCompletion)
        // Updates Firebase with a checked item
        groceryItem.ref?.updateChildValues([
            "completed": toggledCompletion
            ])
    }
    
    func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .black
            cell.detailTextLabel?.textColor = .black
        } else {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .gray
            cell.detailTextLabel?.textColor = .gray
        }
    }
    
    func sortCheckedItems() {
        // Use queryOrdered to sort the items by child in this case "completed"
        ref.queryOrdered(byChild: "completed").observe(.value, with: { snapshot in
            // Stores the data in a local var
            var newItems: [GroceryItem] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                    let groceryItem = GroceryItem(snapshot: snapshot) {
                    newItems.append(groceryItem)
                }
            }
            
            self.items = newItems
            self.tableView.reloadData()
        })
    }
    
    func synchronizeData() {
        // Attached a listener to recieve updates whenever the "grocery-items" is modified
        ref.observe(.value, with: { snapshot in
            // Stores the latest version of the data in the local variable inside the listener's closure
            var newItems: [GroceryItem] = []
            
            // Returns a snapshot of the lastest set of data. Using children, we loop through the grocery items
            for child in snapshot.children {
                // Creates an instance of GroceryItem and adds it into the newItems array
                if let snapshot = child as? DataSnapshot,
                    let groceryItem = GroceryItem(snapshot: snapshot) {
                    newItems.append(groceryItem)
                }
            }
            // Replace items with new data to display
            self.items = newItems
            self.tableView.reloadData()
        })
    }
    
    
    // MARK: Add Item
    
    @IBAction func addButtonDidTouch(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Grocery Item",
                                      message: "Add an Item",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            // Gets the text field and text from alert controller
            guard let textField = alert.textFields?.first,
                let text = textField.text else { return }
            
            // Uses the current user's data, creates a new uncompleted GroceryItem
            let groceryItem = GroceryItem(name: text,
                                          addedByUser: self.user.email,
                                          completed: false)
            
            // Creates a child reference for the database
            let groceryItemRef = self.ref.child(text.lowercased())
            
            // Saves data to the database
            groceryItemRef.setValue(groceryItem.toAnyObject())
            
            self.items.append(groceryItem)
            self.tableView.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel)
        
        alert.addTextField()
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func userCountButtonDidTouch() {
        performSegue(withIdentifier: listToUsers, sender: nil)
    }
}
