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

class HeaderContainerViewController: UIViewController, Scrollable, HeaderContainable, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    private enum State {
        case `default`
        case dragging(initialOffset: CGPoint)
    }
    
    var scrollView: UIScrollView? {
        didSet {
            scrollView?.delegate = self
        }
    }
    
    var topHeight: CGFloat = 0
    var headerHeightAnchor: NSLayoutConstraint!
    var headerView: UIView! = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private let panRecognizer = UIPanGestureRecognizer()
    
    private func setup() {
        panRecognizer.addTarget(self, action: #selector(handlePanRecognizer))
        panRecognizer.delegate = self
        view.addGestureRecognizer(panRecognizer)
    }
    
    var headerState: HeaderState? {
        switch headerHeightAnchor.constant {
        case ...0:
            return .hidden
        case 1..<topHeight:
            return .inProgress
        case topHeight:
            return .visible
        default:
            return nil
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
    
    func addHeaderContainer() {
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerHeightAnchor = headerView.heightAnchor.constraint(equalToConstant: topHeight)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerHeightAnchor
        ])
    }
    
    func addHeader(_ vc: UIViewController, height: CGFloat) {
        addHeaderContainer()
        
        topHeight = height
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerHeightAnchor.constant = height
        let headerContentView = vc.view
        headerContentView?.pinHeader(to: headerView, height: height)
        
        addChild(vc)
        
        vc.didMove(toParent: self)
    }
    
    func addScrollable(_ vc: Scrollable) {
        let scrollable = vc.view
        self.scrollView = vc.scrollView
        view.addSubview(scrollable!)
        scrollable!.translatesAutoresizingMaskIntoConstraints = false
        
        addChild(vc)
        
        NSLayoutConstraint.activate([
            scrollable!.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollable!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollable!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollable!.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        vc.didMove(toParent: self)
    }
    
    private var contentOffset: CGPoint {
        .init(x: 0, y: self.topHeight - self.headerHeightAnchor.constant )
    }
    
    private var lastPan: Date?
    private var state: State = .default
    private var contentOffsetAnimation: TimerAnimation?
    
    private func stopOffsetAnimation() {
        contentOffsetAnimation?.invalidate()
        contentOffsetAnimation = nil
    }
    
    var lastTranslation: CGPoint? = nil
    @objc private func handlePanRecognizer(_ sender: UIPanGestureRecognizer) {
        let newPan = Date()
        switch sender.state {
        case .began:
            stopOffsetAnimation()
            state = .dragging(initialOffset: contentOffset)
            lastTranslation = nil
        case .changed:
            let translation = sender.translation(in: self.view)
            if case .dragging = state {
                if lastTranslation == nil {
                    handle(scrollView: scrollView!, with: -translation.y)
                } else {
                    handle(scrollView: scrollView!, with: lastTranslation!.y - translation.y)
                }
                lastTranslation = translation
            }
            
        case .ended:
            lastTranslation = nil
            state = .default
            
            // Pan gesture recognizers report a non-zero terminal velocity even
            // when the user had stopped dragging:
            // https://stackoverflow.com/questions/19092375/how-to-determine-true-end-velocity-of-pan-gesture
            // In virtually all cases, the pan recognizer seems to call this
            // handler at intervals of less than 100ms while the user is
            // dragging, so if this call occurs outside that window, we can
            // assume that the user had stopped, and finish scrolling without
            // deceleration.
            let userHadStoppedDragging = newPan.timeIntervalSince(lastPan ?? newPan) >= 0.1
            let velocity: CGPoint = userHadStoppedDragging ? .zero : sender.velocity(in: self.view)
            completeGesture(withVelocity: -velocity)
            
        case .cancelled:
            lastTranslation = nil
            state = .default
            
        case .possible:
            break
            
        @unknown default:
            fatalError()
        }
        lastPan = newPan
    }
    
    private func completeGesture(withVelocity velocity: CGPoint) {
        startDeceleration(withVelocity: velocity)
    }
    
    var lastDecelerationOffset: CGFloat? = nil
    private func startDeceleration(withVelocity velocity: CGPoint) {
        let d = UIScrollView.DecelerationRate.normal.rawValue
        let parameters = DecelerationTimingParameters(initialValue: .zero, initialVelocity: velocity,
                                                      decelerationRate: d, threshold: 0.1)
        let duration = parameters.duration
        
        lastDecelerationOffset = nil
        contentOffsetAnimation = TimerAnimation(
            duration: duration,
            animations: { [weak self] _, time in
                let offset = parameters.value(at: time).y
                if self!.lastDecelerationOffset == nil {
                    self!.handle(scrollView:self!.scrollView!, with: offset)
                } else {
                    self?.handle(scrollView:self!.scrollView!, with: offset - self!.lastDecelerationOffset!)
                }
                self?.lastDecelerationOffset = offset
            },
            completion: { _ in } )
    }
    
    func handle(scrollView: UIScrollView, with offset: CGFloat) {
        if
            let parent = parent as? Scrollable & HeaderContainable
        {
            switch (parent.headerState, headerState) {
            case (.hidden, .inProgress):
                break
            case (.visible, .visible), (.hidden, .hidden), (.inProgress, _):
                return
            case (_, .visible) where offset < 0:
                return
            case (_, .inProgress), (.visible, _):
                break
            default:
                break
            }
        }
        handleScroll(scrollView, with: offset)
    }
    
    func handleScroll(_ scrollView: UIScrollView, with offset: CGFloat) {
        let newHeight: CGFloat = self.headerHeightAnchor.constant - offset
        if newHeight <= 0 {
            self.headerHeightAnchor.constant = 0
        } else if newHeight > self.topHeight {
            self.headerHeightAnchor.constant = self.topHeight
        } else if !(offset < 0 && scrollView.contentOffset.y > 0 ) {
            self.headerHeightAnchor.constant = newHeight
            scrollView.contentOffset.y = 0
        }
    }
}
