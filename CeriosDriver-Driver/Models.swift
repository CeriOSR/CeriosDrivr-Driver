//
//  Models.swift
//  CeriosDriver-Driver
//
//  Created by Rey Cerio on 2017-03-15.
//  Copyright © 2017 CeriOS. All rights reserved.
//

import UIKit

class User: NSObject {
    var userId: String?
    var name: String?
    var email: String?
    var fbId: String?
    var trackerId: String?
}

class DriverLocation: NSObject {
    var date: String?
    var latitude: String?
    var longitude: String?
    var uid: String?
}
