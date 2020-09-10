//
//  Scrollable.swift
//  TestScrollingBehavior
//
//  Created by Oleksandr Danylenko on 09.09.2020.
//  Copyright © 2020 Oleksandr Danylenko. All rights reserved.
//

import UIKit

protocol Scrollable: UIViewController {
    var didScroll: ((UIScrollView, CGFloat) -> ())? { get set }
    var scrollView: UIScrollView? { get }
}

enum HeaderState {
    case hidden, inProgress, visible
}

protocol HeaderContainable {
    var headerState: HeaderState? { get }
}

class ScrollingViewController: UITableViewController, Scrollable {
    
    var didEndScrolling: ((UIScrollView, CGPoint) -> ())?
        
    var scrollView: UIScrollView? { tableView }
    
    let items: [String] = Array(0...100).map(String.init)
    
    var didScroll: ((UIScrollView, CGFloat) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView?.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 20 }
    
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 44 }
    
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll?(scrollView, scrollView.contentOffset.y)
    }

}

extension UIView {
    func pinHeader(to superview: UIView, height: CGFloat) {
        superview.addSubview(self)
        translatesAutoresizingMaskIntoConstraints = false
        let topAnchorConstraint = topAnchor.constraint(equalTo: superview.topAnchor)
        topAnchorConstraint.priority = UILayoutPriority(100)
        
        let heightAnchorConstraint = heightAnchor.constraint(equalToConstant: height)
        heightAnchorConstraint.priority = UILayoutPriority(1000)
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            topAnchorConstraint,
            heightAnchorConstraint,
            bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ])
        
        bringSubviewToFront(superview)
    }
}
