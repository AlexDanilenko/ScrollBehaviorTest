//
//  ViewController.swift
//  TestScrollingBehavior
//
//  Created by Oleksandr Danylenko on 22.07.2020.
//  Copyright © 2020 Oleksandr Danylenko. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}
class TopController : UIViewController {
    override func loadView() {
        let label = UILabel()
        label.text = "Hello World!"
        label.textColor = .black
        label.backgroundColor = .red
        self.view = label
    }
}

// Present the view controller in the Live View window


