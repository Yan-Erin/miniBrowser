//
//  ViewController.swift
//  MiniArcApp
//
//  Created by Erin Yan on 11/5/24.
//

import UIKit
import WebKit

class BrowserViewController: UIViewController, BottomBarViewDelegate, WKNavigationDelegate, UIGestureRecognizerDelegate {

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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOutsideBottomBar))
        tapGesture.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tapGesture)
        webView.addGestureRecognizer(tapGesture)
    }

    
    deinit {
        webView.removeObserver(self, forKeyPath: "title")
    }
    
    private func setupUI() {
        webView = WKWebView(frame: .zero)
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        bottomBar = BottomBarView(context: .defaultState)
        bottomBar.delegate = self

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
        let urlDetectorRegex = "^[A-Z0-9a-z._%+-]+\\.+[A-Za-z]{2,}$"
        let httpDetectorRegex = "^https?://"
        do {
            let urlregex = try NSRegularExpression(pattern: urlDetectorRegex)
            let range = NSRange(location: 0, length: urlString.utf16.count)
            if urlregex.firstMatch(in: urlDetectorRegex, options: [], range:range) != nil {
                let httpregex = try NSRegularExpression(pattern: httpDetectorRegex)
                /* found http or https */
                if httpregex.firstMatch(in: urlDetectorRegex, options: [], range:range) != nil {
                    return URL(string: urlString)
                }
                /* Need to add  protocol prefix  */
                let urlString = "https://\(urlString)"
                return URL(string: urlString)
            } else {
                var googleSearch = "https://www.google.com/search?q="
                urlString.components(separatedBy: " ").forEach {word in
                    googleSearch += "\(word)%20"
                }
                return URL(string: googleSearch)
            }
        } catch {
            return nil
        }
    }
    
    @objc private func loadUrl(_ urlString: String) {
        guard let url = createUrlFromInput(urlString) else {
                print("Invalid URL")
                return
            }
            
            let request = URLRequest(url: url)
            webView.load(request)
    }
    
    // WKNavigationDelegate method called when the page finishes loading
      func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
          currentTitle = webView.title
          
          if let urlString = webView.url?.absoluteString {
              let browsedPage = BrowserPage(url: webView.url!, urlString: urlString, title: currentTitle)
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
    
    @objc private func didTapOutsideBottomBar(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        print("Tapped at location: \(location) \(bottomBar.getBottomBarState())")
        if !bottomBar.frame.contains(location) && bottomBar.getBottomBarState() == .searchState {
            print("hit this")
            view.endEditing(true)  // Dismiss keyboard if it's open
            bottomBar.setBrowseState()
        }
    }
}

