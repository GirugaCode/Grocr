/// Copyright (c) 2018 Razeware LLC

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        // Enable the app to work offline and reconnect data once wifi is found
        Database.database().isPersistenceEnabled = true
        return true
    }
}
