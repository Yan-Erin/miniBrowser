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

@objc protocol PageForwardDelegate: AnyObject {
    func goForward()
}

@objc protocol PageBackwardDelegate: AnyObject {
    func goBack()
}
@objc protocol PageReloadDelegate: AnyObject {
    func reloadPage()
}

protocol GetCurrentTabTitle: AnyObject {
    func getCurrentTabTitle() -> String
}

enum BottomBarContext {
    case defaultState
    case browsingState
    case searchState
    case infoState
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
    weak var forwardDelegate:PageForwardDelegate?
    weak var backwardDelegate:PageBackwardDelegate?
    weak var reloadDelegate:PageReloadDelegate?
    weak var getCurrentTitleDelegate:GetCurrentTabTitle?
    
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
        backgroundColor = UIColor.quaternarySystemFill
        
        switch context {
        case .defaultState:
            setupBottomBarViewForDefaultState()
        case .browsingState:
            setupBottomBarViewForBrowsingState()
        case .searchState:
            setupBottomBarViewForSearchingState()
        case .infoState:
            setupBottomBarViewForInfoState()
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
        case .infoState:
            newHeight = 500
        case .hiddenState:
            newHeight = 10
        }
        
        heightConstraint = heightAnchor.constraint(equalToConstant: newHeight)
        heightConstraint?.isActive = true
        UIView.animate(withDuration: 0.1){
            self.superview?.layoutIfNeeded()
        }
    }
    
    private func setupBottomBarViewForDefaultState() {
        // Desktop Button
        let desktopButton = UIButton(type: .system)
        desktopButton.setImage(UIImage(systemName: "display",
                                       withConfiguration: UIImage.SymbolConfiguration(pointSize: 12)), for: .normal)
        desktopButton.tintColor = UIColor.gray
        desktopButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25)
        desktopButton.layer.borderColor = UIColor.gray.cgColor
        desktopButton.layer.cornerRadius = 16
        NSLayoutConstraint.activate([
            desktopButton.widthAnchor.constraint(equalToConstant: 32),
            desktopButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        desktopButton.layer.borderWidth = 0.1
        

        
        // Settings Button
        let settingsButton = UIButton(type: .system)
        settingsButton.setImage(UIImage(systemName: "gear",
                                        withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)),
                                for: .normal)
        settingsButton.tintColor = UIColor.darkGray
        settingsButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25)
        settingsButton.layer.borderColor = UIColor.gray.cgColor
        settingsButton.layer.cornerRadius = 16
        NSLayoutConstraint.activate([
            settingsButton.widthAnchor.constraint(equalToConstant: 32),
            settingsButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        settingsButton.layer.borderWidth = 0.1
        
        let plusButton = makePlusButton()
        
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

        tabsButton.setImage(UIImage(systemName: "square.on.square", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)), for: .normal)
        tabsButton.addTarget(self, action:#selector(handleTabsButtonPressed), for:.touchUpInside)
        
        let plusButton = makePlusButton()
        
        let moreInfoButton = UIButton(type: .system)
        moreInfoButton.setImage(UIImage(systemName: "chevron.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)), for: .normal)
        moreInfoButton.addTarget(self, action: #selector(setInfoState), for: .touchUpInside)
        moreInfoButton.tintColor = UIColor.darkGray
        moreInfoButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25)
        moreInfoButton.layer.borderColor = UIColor.gray.cgColor
        moreInfoButton.layer.cornerRadius = 16
        NSLayoutConstraint.activate([
            moreInfoButton.widthAnchor.constraint(equalToConstant: 32),
            moreInfoButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
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
        urlTextField.placeholder = "Search... "
        urlTextField.borderStyle = .none
        urlTextField.backgroundColor = UIColor.secondarySystemFill
        urlTextField.layer.cornerRadius = 20
        urlTextField.layer.borderColor =  UIColor.gray.cgColor
        urlTextField.layer.borderWidth = 0.45
        urlTextField.clipsToBounds = true
        urlTextField.keyboardType = .URL
        urlTextField.autocapitalizationType = .none
        urlTextField.returnKeyType = .go
        urlTextField.delegate = self
        urlTextField.layer.borderWidth = 0.1
        urlTextField.translatesAutoresizingMaskIntoConstraints = false
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        urlTextField.leftView = leftPaddingView
        urlTextField.leftViewMode = .always
        addSubview(urlTextField)
        
        NSLayoutConstraint.activate([
            urlTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant:10),
            urlTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant:-10),
            urlTextField.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            urlTextField.heightAnchor.constraint(equalToConstant: 42)
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
    
    private func setupBottomBarViewForInfoState() {
        let urlTextField = UITextField()
        urlTextField.placeholder = getCurrentTitleDelegate?.getCurrentTabTitle()
        urlTextField.textAlignment = .center
        urlTextField.borderStyle = .none
        urlTextField.backgroundColor = UIColor.secondarySystemFill
        urlTextField.layer.cornerRadius = 20
        urlTextField.layer.borderColor =  UIColor.gray.cgColor
        urlTextField.layer.borderWidth = 0.45
        urlTextField.clipsToBounds = true
        urlTextField.keyboardType = .URL
        urlTextField.autocapitalizationType = .none
        urlTextField.returnKeyType = .go
        urlTextField.delegate = self
        urlTextField.layer.borderWidth = 0.1
        urlTextField.translatesAutoresizingMaskIntoConstraints = false
        // make placeholder color black grey like in arc
        urlTextField.attributedPlaceholder = NSAttributedString(
            string: getCurrentTitleDelegate?.getCurrentTabTitle() ?? "",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.label,
                         NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11)]
        )
        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 30))
        let backButton = UIButton()
        backButton.setImage(UIImage(systemName:"chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13)), for: .normal)
        backButton.frame = CGRect(x: 0, y: 10, width: 30, height: 30)
        backButton.tintColor = .darkGray
        backButton.addTarget(self, action: #selector(handleBackButtonPressed), for: .touchUpInside)
    
        let forwardButton = UIButton()
        forwardButton.setImage(UIImage(systemName:"chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13)), for: .normal)
        forwardButton.frame = CGRect(x: 0, y: 10, width: 30, height: 30)
        forwardButton.tintColor = .darkGray
        forwardButton.addTarget(self, action: #selector(handleForwardButtonPressed), for: .touchUpInside)
        
        let leftStackView = UIStackView(arrangedSubviews: [leftPadding, backButton, forwardButton])
        leftStackView.axis = .horizontal
        leftStackView.alignment = .center
        leftStackView.spacing = 10
        leftStackView.distribution = .fillEqually

        urlTextField.leftView = leftStackView
        urlTextField.leftViewMode = .always
        
        let rightPadding = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 30))

        let linkButton = UIButton()
        linkButton.setImage(UIImage(systemName: "link", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13)), for:.normal)
        linkButton.frame = CGRect(x: 0, y: 10, width: 30, height: 30)
        linkButton.tintColor =  UIColor.label
        
        let reloadButton = UIButton()
        reloadButton.setImage(UIImage(systemName: "arrow.clockwise", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13)), for:.normal)
        reloadButton.tintColor = UIColor.label
        reloadButton.addTarget(self, action: #selector(handleReloadPage), for: .touchUpInside)
        
        let rightStackView = UIStackView(arrangedSubviews: [linkButton, reloadButton, rightPadding])
        rightStackView.axis = .horizontal
        rightStackView.alignment = .center
        rightStackView.spacing = 10
        rightStackView.distribution = .fillEqually

        urlTextField.rightView = rightStackView
        urlTextField.rightViewMode = .always

        addSubview(urlTextField)
        addSubview(rightStackView)
        addSubview(leftStackView)

        NSLayoutConstraint.activate([
            urlTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant:10),
            urlTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant:-10),
            urlTextField.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            urlTextField.heightAnchor.constraint(equalToConstant: 42)
        ])
    }
    
    private func setupBottomBarViewForHiddenState() {}
    
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
        makeStateRoundedCorner()
    }
    
    @objc func setInfoState() {
        self.context = .infoState
        updateHeight(for:.infoState)
        clearSubViews()
        setupBottomBarViewForInfoState()
        makeStateRoundedCorner()
    }
    
    @objc func handleTabsButtonPressed() {
        tabsDelegate?.showTabSelector()
    }
    @objc func handleReloadPage() {
        reloadDelegate?.reloadPage()
    }
    @objc func handleForwardButtonPressed() {
        forwardDelegate?.goForward()
    }
    @objc func handleBackButtonPressed() {
        backwardDelegate?.goBack()
    }
    @objc func setBrowseState() {
        self.context = .browsingState
        updateHeight(for:.browsingState)
        clearSubViews()
        setupBottomBarViewForBrowsingState()
        clearRoundedCorners()
    }
    @objc func setHiddenState() {
        self.context = .hiddenState
        updateHeight(for:.hiddenState)
        clearSubViews()
        setupBottomBarViewForHiddenState()
        clearRoundedCorners()
    }
    @objc func setDefaultState() {
        self.context = .defaultState
        updateHeight(for: .defaultState)
        clearSubViews()
        setupBottomBarViewForDefaultState()
        clearRoundedCorners() 
    }
    func getBottomBarState() -> BottomBarContext {
         return context
     }
    
    /* UI Helpers */
    func makePlusButton() -> UIButton{
        // Plus Button
        let plusButton = UIButton(type: .system)
        plusButton.setImage(UIImage(systemName: "plus",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 15,
                                                                                   weight: .semibold)),
                            for: .normal)
        plusButton.addTarget(self, action: #selector(setSearchState), for: .touchUpInside)
        plusButton.tintColor = UIColor.darkGray
        plusButton.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25)
        plusButton.layer.cornerRadius = 22
        plusButton.layer.borderWidth = 0.1
        plusButton.layer.borderColor = UIColor.gray.cgColor
        NSLayoutConstraint.activate([
               plusButton.widthAnchor.constraint(equalToConstant: 70),
               plusButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        return plusButton
    }
    // makes top 2 corners rounded
    func makeStateRoundedCorner() {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 35, height: 35)
        )
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
    //clears above func
    func clearRoundedCorners() {
        self.layer.mask = nil
    }
}
