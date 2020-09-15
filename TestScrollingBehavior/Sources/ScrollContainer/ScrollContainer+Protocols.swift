//
//  ScrollContainer+Protocols.swift
//  TestScrollingBehavior
//
//  Created by Oleksandr Danylenko on 15.09.2020.
//  Copyright © 2020 Oleksandr Danylenko. All rights reserved.
//

import UIKit

protocol Scrollable: UIViewController {
    var scrollView: UIScrollView? { get }
}

enum HeaderState {
    case hidden, inProgress, visible
}

protocol HeaderContainable {
    var headerState: HeaderState? { get }
    var shouldCollapse: Bool { get }
}
