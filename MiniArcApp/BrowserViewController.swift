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

class BrowserData {
    static let shared = BrowserData()
    var tabs: [BrowserTab] = []
    var currentTabIndex: Int = 0
    var currentTabTitle: String = ""
    private init() {}
}

class BrowserViewController: UIViewController, BottomBarViewDelegate, WKNavigationDelegate, UIGestureRecognizerDelegate, ShowTabsViewDelegate, GetCurrentTabTitle, GetCurrentURL, TabsViewControllerDelegate, BrowserViewDelegate{

    private var webView: WKWebView!
    private var urlTextField: UITextField!
    private var goButton: UIButton!
    private var backButton:UIButton!
    private var forwardButton:UIButton!
    private var bottomBar: BottomBarView!
    private var currentView: UIView!

    
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
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow your gesture recognizers to work alongside WKWebView scrolling
        return true
    }
    
    private func setupUI() {
        webView = WKWebView(frame: .zero)
        currentView = webView  
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        bottomBar = BottomBarView(context: .defaultState)
        bottomBar.delegate = self
        bottomBar.tabsDelegate = self
        bottomBar.browserViewDelegate = self
        bottomBar.getCurrentTitleDelegate = self
        bottomBar.getCurrentURLDelegate = self
        
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)
        
        setupConstraints()
    }
    
    private func replaceCurrentView(with newView: UIView) {
        currentView.removeFromSuperview()

        currentView = newView
        view.insertSubview(currentView, belowSubview: bottomBar)
        currentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            currentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            currentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            currentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            currentView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor)
        ])
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
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
        BrowserData.shared.currentTabTitle = webView.title  ?? "Untitled"

        if let index = BrowserData.shared.tabs.firstIndex(where: { $0.webView == webView }) {
            BrowserData.shared.tabs[index].title = webView.title ?? "Untitled"
            BrowserData.shared.tabs[index].url = webView.url
            let browsedPage = BrowserPage(url: webView.url!, urlString: webView.url?.absoluteString ?? "", title: BrowserData.shared.currentTabTitle)
            bottomBar.addToPrevSearches(browsedPage)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse {
            let statusCode = httpResponse.statusCode
            
            if statusCode == 404 {
                print("Page not found (404)")
            }
        }
        decisionHandler(.allow)
    }

    func didRequestURLLoad(_ urlString: String) {
        loadUrl(urlString)
    }
    
    @objc internal func goBack() {
        print("called Go back")
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @objc internal func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @objc internal func reloadPage() {
        webView.reload()
    }
    
    func respondToBottomBarRequests(_ requestEnum: RequestEnum) {
        switch requestEnum {
        case .reload:
            reloadPage()
        case .goBack:
            goBack()
        case .goForward:
            goForward()
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
                if bottomBar.getBottomBarState() == .hiddenState {
                    bottomBar.setBrowseState()
                }
            case .up:
                print("Swiped up")
                bottomBar.setHiddenState()
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
        BrowserData.shared.tabs.append(newTab)
        BrowserData.shared.currentTabIndex = BrowserData.shared.tabs.count - 1
        switchToTab(at:BrowserData.shared.currentTabIndex)
        bottomBar.setBrowseState()
    }
    
    private func switchToTab(at index: Int) {
        guard index >= 0 && index < BrowserData.shared.tabs.count else { return }
        webView.removeFromSuperview()
        webView = BrowserData.shared.tabs[index].webView
        BrowserData.shared.currentTabTitle = webView.title  ?? "Untitled"
        view.insertSubview(webView, belowSubview: bottomBar)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isUserInteractionEnabled = true
        setupWebView()
        replaceCurrentView(with: webView)
        bottomBar.setBrowseState()

    }
    
    func didSelectTab(at index: Int) {
        switchToTab(at: index)
    }
    
    @objc func showTabSelector() {
        let tabsVC = TabsViewController()
        tabsVC.delegate = self  // Set delegate for tab selection
        addChild(tabsVC)  // Add as a child view controller
        replaceCurrentView(with: tabsVC.view)
        tabsVC.didMove(toParent: self)  // Notify it has been added
        bottomBar.setDefaultState()
    }
    
    func getCurrentTabTitle() -> String {
        return BrowserData.shared.currentTabTitle
    }
    func getCurrURL() -> String {
        return webView.url?.absoluteString ?? ""
    }
}

