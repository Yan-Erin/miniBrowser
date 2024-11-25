//
//  TabViewController.swift
//  MiniArcApp
//
//  Created by Erin Yan on 11/16/24.
//

import UIKit
import WebKit

protocol TabsViewControllerDelegate: AnyObject {
    func didSelectTab(at index: Int)
}

class TabsViewController: UIViewController {
    let scrollView = UIScrollView()
    var tabContainers: [UIView] = []
    let stackView = UIStackView()
    let tabLen = 0
    
    weak var delegate: TabsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupScrollView()
        setupStackView()
        addTabs()
    }

    func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.clipsToBounds = false
        
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.9)
        ])
    }
    
    func setupStackView() {
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = -100
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        scrollView.addSubview(stackView)
        
        // Constraints for the stack view
        NSLayoutConstraint.activate([
             stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
             stackView.trailingAnchor.constraint(greaterThanOrEqualTo: scrollView.trailingAnchor),
             stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
             stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
             stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
         ])
    }
    
    func addTabs() {
        for i in 0..<BrowserData.shared.tabs.count {
            let container = UIView()
            container.backgroundColor = .white
            container.layer.cornerRadius = 10
            container.layer.borderWidth = 0.5
            container.layer.borderColor = UIColor.lightGray.cgColor
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOpacity = 0.2
            container.layer.shadowOffset = CGSize(width: 0, height: 2)
            container.layer.shadowRadius = 4
            container.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(container)
            stackView.bringSubviewToFront(container)
        

            let webView = BrowserData.shared.tabs[i].webView
            container.addSubview(webView)
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.layer.cornerRadius = 8
            webView.clipsToBounds = true
            webView.isUserInteractionEnabled = false

            // Apply constraints to the WKWebView inside its container
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: container.topAnchor),
                webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            NSLayoutConstraint.activate([
                container.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.9),
                container.widthAnchor.constraint(equalToConstant: 400),
            ])

            // Add a tap gesture to handle tab selection
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tabTapped(_:)))
            let swipedUpGesture = UISwipeGestureRecognizer(target:self, action:#selector(swipedUp(_:)))
            swipedUpGesture.direction = .up
            container.tag = i  // Use the tag to identify the tab index
            container.addGestureRecognizer(tapGesture)
            container.addGestureRecognizer(swipedUpGesture)

            tabContainers.append(container)
        }
    }
    
    @objc func tabTapped(_ sender: UITapGestureRecognizer) {
        if let index = sender.view?.tag {
            delegate?.didSelectTab(at: index)
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func swipedUp(_ sender: UISwipeGestureRecognizer) {
        if let index = sender.view?.tag {
            BrowserData.shared.tabs.remove(at: index)
            UIView.animate(withDuration: 0.3, animations: {
                sender.view?.alpha = 0
                sender.view?.transform = CGAffineTransform(translationX: 0, y: -75)
                }, completion: { _ in
                    sender.view?.removeFromSuperview()
                    self.updateTabIndexes()
                })
        }
        if BrowserData.shared.tabs.count == 0 {
            dismiss(animated: true, completion: nil)
        }
    }
    /* reset indexes after removal */
    private func updateTabIndexes() {
        for (newIndex, tabCont) in tabContainers.enumerated() {
            tabCont.tag = newIndex
        }
        
    }
}
