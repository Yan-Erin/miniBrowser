//
//  BottomBarView.swift
//  MiniArcApp
//
//  Created by Erin Yan on 11/8/24.
//

import UIKit

enum BottomBarContext {
    case defaultState
    case browsingState
    case hiddenState
}

class BottomBarView: UIView {
    private var context: BottomBarContext
    init(context: BottomBarContext) {
        self.context = context
        super.init(frame: .zero)
        setupBottomBarView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupBottomBarView() {
        backgroundColor = .lightGray
        
        switch context {
        case .defaultState:
            setupBottomBarViewForDefaultState()
        case .browsingState:
            setupBottomBarViewForBrowsingState()
        case .hiddenState:
            setupBottomBarViewForHiddenState()
        }
    }
    
    private func setupBottomBarViewForDefaultState() {
        let desktopButton = UIButton(type: .system)
        let plusButton = UIButton(type: .system)
        let settingsButton = UIButton(tyoe: .system)
    }
    private func setupBottomBarViewForBrowsingState() {
        let tabsButton = UIButton(type: .system)
        let plusButton = UIButton(type: .system)
        let moreInfoButton = UIButton(type: .system)
    }
    private func setupBottomBarViewForHiddenState() {
        
    }
}
