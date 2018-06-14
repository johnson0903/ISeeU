//
//  DropDownButton.swift
//  ISeeYou
//
//  Created by 李嘉晟 on 2018/6/12.
//  Copyright © 2018 李嘉晟. All rights reserved.
//

import UIKit

class DropDownButton: UIButton {
    
    var title: String!
    var dropDownView = DropDownView()
    var height = NSLayoutConstraint()
    
    init(title: String = "button text", frame: CGRect = .zero) {
        super.init(frame: frame)
        if frame == .zero {
            self.translatesAutoresizingMaskIntoConstraints = false
        }
        self.title = title
        self.phaseTwo()
    }
    
    override func didMoveToSuperview() {
        self.superview?.addSubview(dropDownView)
        self.superview?.bringSubviewToFront(dropDownView)
        
        dropDownView.topAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        dropDownView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        dropDownView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        height = dropDownView.heightAnchor.constraint(equalToConstant: 0)
        
        dropDownView.options = [Mode.home, Mode.indoor, Mode.outdoor, Mode.dontDisturb]
    }
    
    func phaseTwo() {
        self.setTitle(self.title, for: .normal)
        self.setTitleColor(.greenZero, for: .normal)
        self.backgroundColor = .white
        self.layer.borderColor = UIColor.greenZero.cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 10
        if let titleLabel = self.titleLabel {
            titleLabel.font = UIFont.init(name: "Raleway-v4020-Regular", size: 16)
        }
        
        
        dropDownView = DropDownView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        dropDownView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    var isOpen = false
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isOpen == false {
            isOpen = true
            
            self.backgroundColor = .greenZero
            self.setTitleColor(.white, for: .normal)
            
            NSLayoutConstraint.deactivate([self.height])
            
            if self.dropDownView.tableview.contentSize.height > 160 {
                self.height.constant = 160
            } else {
                self.height.constant = self.dropDownView.tableview.contentSize.height
            }
            
            NSLayoutConstraint.activate([self.height])
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.dropDownView.layoutIfNeeded()
                self.dropDownView.center.y += self.dropDownView.frame.height / 2
            }, completion: nil)
        } else {
            dismissDropDown()
        }
    }
    
    func dismissDropDown() {
        isOpen = false
        self.backgroundColor = .white
        self.setTitleColor(.greenZero, for: .normal)
        NSLayoutConstraint.deactivate([self.height])
        self.height.constant = 0
        NSLayoutConstraint.activate([self.height])
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.dropDownView.center.y -= self.dropDownView.frame.height / 2
            self.dropDownView.layoutIfNeeded()
        }, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol dropDownProtocol {
    func dropDownPressed(mode: Mode)
}
