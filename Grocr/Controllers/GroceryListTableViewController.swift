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
    
//    ref.observe(.value, with: { snapshot in
//        print(snapshot.value as Any)
//    })
    
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
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    // Deletes an item from the tableview and firebase
    if editingStyle == .delete {
        let groceryItem = items[indexPath.row]
        groceryItem.ref?.removeValue()
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) else { return }
    let groceryItem = items[indexPath.row]
    let toggledCompletion = !groceryItem.completed
    
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
