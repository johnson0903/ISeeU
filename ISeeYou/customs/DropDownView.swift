//
//  DropDownView.swift
//  ISeeYou
//
//  Created by 李嘉晟 on 2018/6/12.
//  Copyright © 2018 李嘉晟. All rights reserved.
//

import UIKit

class DropDownView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    var options = [Mode]()
    var tableview = UITableView()
    var delegate: dropDownProtocol!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tableview.backgroundColor = UIColor.clear
        tableview.layer.cornerRadius = 10
        tableview.rowHeight = 40
        tableview.isScrollEnabled = false
        tableview.delegate = self
        tableview.dataSource = self
        tableview.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(tableview)
        tableview.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        tableview.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        tableview.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        tableview.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = options[indexPath.row].rawValue
        cell.textLabel?.textColor = .greenZero
        cell.textLabel?.textAlignment = .center
        cell.layer.borderColor = UIColor.greenZero.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 10
        cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate.dropDownPressed(mode: options[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
