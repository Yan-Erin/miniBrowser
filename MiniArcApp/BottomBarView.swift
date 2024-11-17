//
//  BottomBarView.swift
//  MiniArcApp
//
//  Created by Erin Yan on 11/8/24.
//

import UIKit

protocol BottomBarViewDelegate: AnyObject {
    func didRequestURLLoad(_ urlString: String)
}

@objc protocol ShowTabsViewDelegate: AnyObject {
    func showTabSelector()
}

enum BottomBarContext {
    case defaultState
    case browsingState
    case searchState
    case hiddenState
}

struct BrowserPage {
    var url: URL
    var urlString: String
    var title: String
}

class BottomBarView: UIView, UITextFieldDelegate, UITableViewDelegate,UITableViewDataSource {
    weak var delegate: BottomBarViewDelegate?
    weak var tabsDelegate: ShowTabsViewDelegate?

    private var context: BottomBarContext
    private var heightConstraint: NSLayoutConstraint?
    private var previousSearches: [BrowserPage] = []
    private var searchesTableView: UITableView!

    init(context: BottomBarContext) {
        self.context = context
        super.init(frame: .zero)
        setupBottomBarView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBottomBarView() {
        backgroundColor = .systemGray6
        
        switch context {
        case .defaultState:
            setupBottomBarViewForDefaultState()
        case .browsingState:
            setupBottomBarViewForBrowsingState()
        case .searchState:
            setupBottomBarViewForSearchingState()
        case .hiddenState:
            setupBottomBarViewForHiddenState()
        }
        updateHeight(for: self.context)
    }
    
    private func updateHeight(for context: BottomBarContext) {
        heightConstraint?.isActive = false
        let newHeight: CGFloat
        switch context {
        case .defaultState:
            newHeight = 75
        case .browsingState:
            newHeight = 75
        case .searchState:
            newHeight = 500
        case .hiddenState:
            newHeight = 10
        }
        
        heightConstraint = heightAnchor.constraint(equalToConstant: newHeight)
        heightConstraint?.isActive = true
        superview?.layoutIfNeeded()
    }
    
    private func setupBottomBarViewForDefaultState() {
        let desktopButton = UIButton(type: .system)
        desktopButton.setImage(UIImage(systemName: "display"), for: .normal)

        let plusButton = UIButton(type: .system)
        plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
        plusButton.addTarget(self, action: #selector(setSearchState), for: .touchUpInside)
        
        let settingsButton = UIButton(type: .system)
        settingsButton.setImage(UIImage(systemName: "gear"), for: .normal)

        
        let stackView = UIStackView(arrangedSubviews: [desktopButton, plusButton, settingsButton])
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant:-5),
        ])

    }

    private func setupBottomBarViewForBrowsingState() {
        let tabsButton = UIButton(type: .system)

        tabsButton.setImage(UIImage(systemName: "square.on.square"), for: .normal)
        tabsButton.addTarget(self, action:#selector(handleTabsButtonPressed), for:.touchUpInside)
        
        let plusButton = UIButton(type: .system)
        plusButton.setImage(UIImage(systemName: "plus"), for: .normal)
        plusButton.addTarget(self, action: #selector(setSearchState), for: .touchUpInside)
        
        let moreInfoButton = UIButton(type: .system)
        moreInfoButton.setImage(UIImage(systemName: "chevron.up"), for: .normal)
        
        let stackView = UIStackView(arrangedSubviews: [tabsButton, plusButton, moreInfoButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant:-5),
        ])
    }
    
    private func setupBottomBarViewForSearchingState() {
        let urlTextField = UITextField()
        urlTextField.placeholder = "Enter URL"
        urlTextField.borderStyle = .roundedRect
        urlTextField.keyboardType = .URL
        urlTextField.autocapitalizationType = .none
        urlTextField.returnKeyType = .go
        urlTextField.delegate = self
        addSubview(urlTextField)
        urlTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            urlTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant:10),
            urlTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant:-10),
            urlTextField.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            urlTextField.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        searchesTableView = UITableView()
        searchesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchCell")
        searchesTableView.delegate = self
        searchesTableView.dataSource = self
        searchesTableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(searchesTableView)
        
        NSLayoutConstraint.activate([
            searchesTableView.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 10),
            searchesTableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            searchesTableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            searchesTableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])
        
        
    }
    
    private func setupBottomBarViewForHiddenState() {
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  // Dismiss keyboard
        if let text = textField.text, !text.isEmpty {
            delegate?.didRequestURLLoad(text)  // Call delegate method
            setBrowseState()
        }
        return true
    }
    
    func addToPrevSearches(_ browsedPage: BrowserPage) {
        previousSearches.insert(browsedPage, at:0)
        searchesTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return previousSearches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath)
            let search = previousSearches[indexPath.row]
            cell.textLabel?.text = search.title.isEmpty ? search.urlString : search.title
            cell.textLabel?.textColor = .systemBlue
            return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPage = previousSearches[indexPath.row]
        print("Selected row \(indexPath.row) \(previousSearches.count)")
        print("\(selectedPage)")
        delegate?.didRequestURLLoad(selectedPage.urlString)
        setBrowseState()
    }

    /* Handle State Changes here*/
    private func clearSubViews() {
        subviews.forEach { $0.removeFromSuperview() }
    }
    @objc func setSearchState() {
        self.context = .searchState
        updateHeight(for:.searchState)
        clearSubViews()
        setupBottomBarViewForSearchingState()
    }
    @objc func handleTabsButtonPressed() {
        tabsDelegate?.showTabSelector()
    }
    @objc func setBrowseState() {
        self.context = .browsingState
        updateHeight(for:.browsingState)
        clearSubViews()
        setupBottomBarViewForBrowsingState()
    }
    @objc func setHiddenState() {
        self.context = .hiddenState
        updateHeight(for:.hiddenState)
        clearSubViews()
        setupBottomBarViewForHiddenState()
    }
    @objc func setDefaultState() {
        self.context = .defaultState
        updateHeight(for: .defaultState)
        clearSubViews()
        setupBottomBarViewForDefaultState()
    }
    func getBottomBarState() -> BottomBarContext {
         return context
     }
}
