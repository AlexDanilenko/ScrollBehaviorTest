//
//  CollapsableHeaderContainer.swift
//  TestScrollingBehavior
//
//  Created by Oleksandr Danylenko on 15.09.2020.
//  Copyright © 2020 Oleksandr Danylenko. All rights reserved.
//

import UIKit

class CollapsableHeaderContainer: UIViewController, Scrollable, HeaderContainable {
    
    private enum State {
        case `default`
        case dragging(initialOffset: CGPoint)
    }
    
    var scrollView: UIScrollView?
    
    private var headerView: UIView = UIView()
    private let panRecognizer = UIPanGestureRecognizer()
    
    open var maxHeaderHeight: CGFloat = 0
    var headerHeightAnchor: NSLayoutConstraint!
    
    public var headerState: HeaderState? {
        switch headerHeightAnchor.constant {
        case ...0:
            return .hidden
        case 0..<maxHeaderHeight:
            return .inProgress
        case maxHeaderHeight...:
            return .visible
        default:
            return nil
        }
    }
    
    private var contentOffset: CGPoint {
        .init(x: 0, y: maxHeaderHeight - headerHeightAnchor.constant )
    }
    
    private var lastPan: Date?
    private var lastTranslation: CGPoint? = nil
    private var lastDecelerationOffset: CGFloat? = nil
    
    private var state: State = .default
    internal var shouldCollapse = true
    private var contentOffsetAnimation: TimerAnimation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        panRecognizer.addTarget(self, action: #selector(handlePanRecognizer))
        panRecognizer.delegate = self
        view.addGestureRecognizer(panRecognizer)
    }
    
    func addHeaderContainer() {
        view.addSubview(headerView)
        headerView.clipsToBounds = true
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerHeightAnchor = headerView.heightAnchor.constraint(equalToConstant: maxHeaderHeight)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerHeightAnchor
        ])
    }
    
    
    public func addHeader(_ vc: UIViewController, maxHeight: CGFloat, shouldCollapse: Bool) {
        addHeaderContainer()
        
        self.shouldCollapse = shouldCollapse
        
        maxHeaderHeight = maxHeight
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerHeightAnchor.constant = maxHeight
        let headerContentView = vc.view
        headerContentView?.pinHeader(to: headerView, height: maxHeight)
        
        addChild(vc)
        
        vc.didMove(toParent: self)
    }
    
    public func addScrollable(_ vc: Scrollable) {
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
    
    public func addHeader(view: UIView, from child: UIViewController?, maxHeight: CGFloat, minHeight: CGFloat) {
        addHeaderContainer()
        
        maxHeaderHeight = maxHeight
        headerHeightAnchor.constant = maxHeight
        view.pinHeader(to: headerView, height: maxHeight)
        
        if let child = child {
            addChild(child)
            child.didMove(toParent: self)
        }
    }
    
    public func addContent(
        _ contentView: UIView,
        childScrollView: UIScrollView
    ) {
        self.scrollView = childScrollView
        self.view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
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
            startDeceleration(withVelocity: -velocity)
            
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
    
    private func startDeceleration(withVelocity velocity: CGPoint) {
        lastDecelerationOffset = nil
        
        let parameters = DecelerationTimingParameters(
            initialValue: .zero,
            initialVelocity: velocity,
            decelerationRate: UIScrollView.DecelerationRate.normal.rawValue,
            threshold: 0.1
        )
        
        contentOffsetAnimation = TimerAnimation(
            duration: parameters.duration,
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
    
    private func handle(scrollView: UIScrollView, with offset: CGFloat) {

        if
            let parent = parent as? Scrollable & HeaderContainable,
            parent.shouldCollapse
        {
            switch (parent.headerState, headerState) {
            
            case (.hidden, .inProgress):
                break
            case (.visible, .visible), (.inProgress, _):
                return
            case (_, .visible) where offset < 0:
                return
            
            case (.visible, _), (_, .inProgress), (_, .hidden):
                break
            default:
                break
            }
        }
        guard shouldCollapse else { return }

        render(offset: offset, with: scrollView)
    }
    
    private func render(offset: CGFloat, with scrollView: UIScrollView) {
        let newHeight: CGFloat = headerHeightAnchor.constant - offset
       if newHeight <= 0 {
            self.headerHeightAnchor.constant = 0
        } else if newHeight > self.maxHeaderHeight {
            self.headerHeightAnchor.constant = self.maxHeaderHeight
        } else if !(offset <= 0 && scrollView.contentOffset.y > 0 ) {
            headerHeightAnchor.constant = newHeight
            scrollView.contentOffset.y = 0
        }
    }
    
    private func stopOffsetAnimation() {
        contentOffsetAnimation?.invalidate()
        contentOffsetAnimation = nil
    }
}

extension CollapsableHeaderContainer:  UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
