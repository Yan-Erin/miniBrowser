//
//  ViewController.swift
//  MiniArcApp
//
//  Created by Erin Yan on 11/5/24.
//

import UIKit
import WebKit

struct BrowserTab {
    var webView: WKWebView
    var title: String
    var url: URL?
}

class BrowserViewController: UIViewController, BottomBarViewDelegate, WKNavigationDelegate, UIGestureRecognizerDelegate, ShowTabsViewDelegate {

    private var tabs: [BrowserTab] = []
    private var currentTabIndex: Int = 0
    private var webView: WKWebView!
    private var urlTextField: UITextField!
    private var goButton: UIButton!
    private var backButton:UIButton!
    private var forwardButton:UIButton!
    private var bottomBar: BottomBarView!
    private var currentTitle: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        webView.navigationDelegate = self
        setupGestures()
    }

    
    deinit {
        webView.removeObserver(self, forKeyPath: "title")
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOutsideBottomBar))
        self.view.addGestureRecognizer(tapGesture)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRight.direction = .right
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
            self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeLeft.direction = .left
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
            self.view.addGestureRecognizer(swipeLeft)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeUp.direction = .up
        swipeUp.delegate = self
        swipeUp.direction = UISwipeGestureRecognizer.Direction.up
            self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeDown.direction = .down
        swipeDown.delegate = self
        swipeDown.direction = UISwipeGestureRecognizer.Direction.down
            self.view.addGestureRecognizer(swipeDown)
    }
    
    private func setupUI() {
        webView = WKWebView(frame: .zero)
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        bottomBar = BottomBarView(context: .defaultState)
        bottomBar.delegate = self
        bottomBar.tabsDelegate = self
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)
        
        setupConstraints()
    }
    
    private func setupBottomBarConstraints() {
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
    }
    private func setupWebView() {
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
        ])
    }
    
    private func setupConstraints() {
        setupWebView()
        setupBottomBarConstraints()
    }
    
    private func createUrlFromInput(_ urlString: String) -> URL? {
        if urlString.lowercased().hasPrefix("http://") || urlString.lowercased().hasPrefix("https://") {
            return URL(string: urlString)
        }
        let domainRegex = "^[A-Za-z0-9._%+-]+\\.[A-Za-z]{2,}$"
        if let _ = urlString.range(of: domainRegex, options: .regularExpression) {
            // Add "https://" if it's a valid domain
            return URL(string: "https://\(urlString)")
        }
        let searchQuery = urlString
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString
            return URL(string: "https://www.google.com/search?q=\(searchQuery)")
    }
    
    @objc private func loadUrl(_ urlString: String) {
        guard let url = createUrlFromInput(urlString) else {
                print("Invalid URL")
                return
            }
        createNewTab(with:url)
    }
      
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        currentTitle = webView.title

        if let index = tabs.firstIndex(where: { $0.webView == webView }) {
            tabs[index].title = webView.title ?? "Untitled"
            tabs[index].url = webView.url
            let browsedPage = BrowserPage(url: webView.url!, urlString: webView.url?.absoluteString ?? "", title: currentTitle)
            bottomBar.addToPrevSearches(browsedPage)
        }
    }
    
    func didRequestURLLoad(_ urlString: String) {
        loadUrl(urlString)
    }
    
    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @objc private func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @objc func didTapOutsideBottomBar(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        print("Tapped at location: \(location) \(bottomBar.getBottomBarState())")
        if !bottomBar.frame.contains(location) && bottomBar.getBottomBarState() == .searchState {
            print("hit this")
            view.endEditing(true)  // Dismiss keyboard if it's open
            bottomBar.setBrowseState()
        }
    }
    @objc func respondToSwipeGesture(gesture:UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case .right:
                print("Swiped right")
                goBack()
            case .left:
                print("Swiped left")
                goForward()
            case .down:
                print("Swiped down")
                bottomBar.setHiddenState()
            case .up:
                print("Swiped up")
                if bottomBar.getBottomBarState() == .hiddenState {
                    bottomBar.setBrowseState()
                }
            default :
                break
            }
        }
    }
    private func createNewTab(with url: URL? = nil) {
        let newWebView = WKWebView()
        newWebView.navigationDelegate = self
        if let url = url {
            newWebView.load(URLRequest(url:url))
        }
        let newTab = BrowserTab(webView: newWebView, title: newWebView.title ?? "Untitled", url: url)
        tabs.append(newTab)
        currentTabIndex = tabs.count - 1
        switchToTab(at:currentTabIndex)
    }
    
    private func switchToTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        webView.removeFromSuperview()
        webView = tabs[index].webView
        view.insertSubview(webView, belowSubview: bottomBar)
        webView.translatesAutoresizingMaskIntoConstraints = false
        setupWebView()
    }
    
    @objc func showTabSelector() {
        let tabSelector = UIAlertController(title: "Tabs", message: nil, preferredStyle: .actionSheet)
        
        for (index, tab) in tabs.enumerated() {
            tabSelector.addAction(UIAlertAction(title: tab.title, style: .default, handler: { _ in
                self.switchToTab(at: index)
            }))
        }
        
        tabSelector.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(tabSelector, animated: true, completion: nil)
    }
}

