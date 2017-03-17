//
//  LoginController.swift
//  CeriosDriver-Driver
//
//  Created by Rey Cerio on 2017-03-15.
//  Copyright © 2017 CeriOS. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase

class LoginController: UIViewController, FBSDKLoginButtonDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let loginButton = FBSDKLoginButton()
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(loginButton)
        
        //x, y, w, h
        loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        loginButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        loginButton.delegate = self
        loginButton.readPermissions = ["email", "public_profile"]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        view.backgroundColor = .white
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print(error)
            return
        }
        fbGraphRequestThenAuthenticateAndStore()
        print("Successfully logged in with facebook!!!!!")
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Did log out of facebook!!!!")
    }
    
    func fbGraphRequestThenAuthenticateAndStore() {
        FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email"]).start { (connection, result, error) in
            if error != nil {
                print(error ?? "unknown error")
                return
            }
            let dictionary = result as? [String: AnyObject]
            let newUser = User()
            newUser.email = dictionary?["email"] as? String
            newUser.name = dictionary?["name"] as? String
            newUser.fbId = dictionary?["id"] as? String
            
            let accessToken = FBSDKAccessToken.current()
            guard let accessTokenString = accessToken?.tokenString else {return}
            let credentials = FIRFacebookAuthProvider.credential(withAccessToken: accessTokenString)
            FIRAuth.auth()?.signIn(with: credentials, completion: { (user, error) in
                if error != nil {
                    print("Could not log into Firebase", error ?? "unknown error")
                    return
                }
                print("Successfully logged into Firebase", user ?? "unknown user")
                
                //need to store user into database but question is, how can we make it so only the first time they pressed the FB button will be stored into the database.
                guard let email = newUser.email, let name = newUser.name, let fbId = newUser.fbId else {return}
                guard let uid = FIRAuth.auth()?.currentUser?.uid else {return}
                let values = ["userId": uid, "name": name, "email": user?.email, "fbId": fbId, "trackerId": "None" ]
                
                let checkTrackerRef = FIRDatabase.database().reference().child("user").child(uid)
                checkTrackerRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    let dictionary = snapshot.value as? [String: AnyObject]
                    let user = User()
                    user.trackerId = dictionary?["trackerId"] as? String
                    
                    print(snapshot.key)
                    
                    if user.trackerId == nil || user.trackerId == "None" {
                        let databaseRef = FIRDatabase.database().reference().child("user").child(uid)
                        databaseRef.updateChildValues(values, withCompletionBlock: { (error, reference) in
                            if error != nil {
                                print(error ?? "Something went wrong with the Database input...")
                                return
                            }
                            let fanRef = FIRDatabase.database().reference().child("pending_users").child("\(uid)")
                            let fanValues = ["email": email, "fbId": fbId]
                            fanRef.updateChildValues(fanValues)
                            let mapViewController = MapViewController()
                            let navController = UINavigationController(rootViewController: mapViewController)
                            self.present(navController, animated: true, completion: nil)
                        })

                    } else {
                        let mapViewController = MapViewController()
                        guard let trackerId = user.trackerId else {return}
                        mapViewController.trackerId = trackerId
                        let navController = UINavigationController(rootViewController: mapViewController)
                        self.present(navController, animated: true, completion: nil)
                    }
                    
                }, withCancel: nil)
            })
        }
    }
}
