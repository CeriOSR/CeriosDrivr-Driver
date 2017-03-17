//
//  Extensions.swift
//  CeriosDriver-Driver
//
//  Created by Rey Cerio on 2017-03-16.
//  Copyright © 2017 CeriOS. All rights reserved.
//

import UIKit

extension UIView {
    func addConstraintsWithVisualFormat(format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary))
    }
}
