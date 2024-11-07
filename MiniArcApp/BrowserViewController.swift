//
//  ViewController.swift
//  MiniArcApp
//
//  Created by Erin Yan on 11/5/24.
//

import UIKit
import WebKit

class BrowserViewController: UIViewController {
    private var webView: WKWebView!
    private var urlTextField: UITextField!
    private var goButton: UIButton!
    private var backButton:UIButton!
    private var forwardButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()

    }
    private func setupUI() {
        webView = WKWebView(frame: .zero)
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        urlTextField = UITextField()
        urlTextField.placeholder = "Enter URL"
        urlTextField.borderStyle = .roundedRect
        urlTextField.keyboardType = .URL
        urlTextField.autocapitalizationType = .none
        view.addSubview(urlTextField)
        urlTextField.translatesAutoresizingMaskIntoConstraints = false
        
        goButton = UIButton(type: .system)
        goButton.setTitle("Go", for: .normal)
        goButton.addTarget(self, action: #selector(loadUrl), for: .touchUpInside)
        view.addSubview(goButton)
        goButton.translatesAutoresizingMaskIntoConstraints = false
        
        backButton = UIButton(type: .system)
        backButton.setTitle("<", for: .normal)
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            urlTextField.trailingAnchor.constraint(equalTo: goButton.leadingAnchor, constant: -10),
            urlTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            urlTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            goButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            goButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            goButton.widthAnchor.constraint(equalToConstant: 40),
            goButton.heightAnchor.constraint(equalToConstant: 40),
            
        ])
        
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: urlTextField.bottomAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

        ])
    }
    private func createUrlFromInput() -> URL? {
        let urlDetectorRegex = "^[A-Z0-9a-z._%+-]+\\.+[A-Za-z]{2,}$"
        let httpDetectorRegex = "^https?://"
        guard let urlTextField = urlTextField.text else {return nil}
        do {
            let urlregex = try NSRegularExpression(pattern: urlDetectorRegex)
            let range = NSRange(location: 0, length: urlTextField.utf16.count)
            if urlregex.firstMatch(in: urlDetectorRegex, options: [], range:range) != nil {
                let httpregex = try NSRegularExpression(pattern: httpDetectorRegex)
                /* found http or https */
                if httpregex.firstMatch(in: urlDetectorRegex, options: [], range:range) != nil {
                    return URL(string: urlTextField)
                }
                /* Need to add  protocol prefix  */
                let urlString = "https://\(urlTextField)"
                return URL(string: urlString)
            } else {
                var googleSearch = "https://www.google.com/search?q="
                urlTextField.components(separatedBy: " ").forEach {word in
                    googleSearch += "\(word)%20"
                }
                return URL(string: googleSearch)
            }
        } catch {
            return nil
        }
        return nil
    }

    
    @objc private func loadUrl() {
        guard let url = createUrlFromInput() else {
                print("Invalid URL")
                return
            }
            
            let request = URLRequest(url: url)
            webView.load(request)
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
}

