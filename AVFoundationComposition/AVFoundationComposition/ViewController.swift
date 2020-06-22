////  ViewController.swift
//  AVFoundationComposition
//
//  Created by Su Jinjin on 2020/6/22.
//  Copyright © 2020 苏金劲. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private let data: [Dictionary<String, String>] = [
        ["1. 组合视频，重复自身": "DuplicateSelfViewController"]
    ]
    
    private let kCellId = "CellId"
    private let kProjName = "AVFoundationComposition"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.table)
    }

    private lazy var table: UITableView = {
        let v = UITableView(frame: self.view.bounds, style: .plain)
        v.delegate = self
        v.dataSource = self
        v.register(UITableViewCell.self, forCellReuseIdentifier: self.kCellId)
        return v
    }()

}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: self.kCellId)
        
        if (cell == nil) {
            cell = UITableViewCell(style: .default, reuseIdentifier: self.kCellId)
        }
        if let title = self.data[indexPath.item].keys.first {
            cell?.textLabel?.text = title
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if
            let title = self.data[indexPath.item].keys.first,
            let name = self.data[indexPath.item].values.first,
            let vcClasss = NSClassFromString(kProjName + "." + name) as? UIViewController.Type {
            
            let vc = vcClasss.init()
            vc.view.backgroundColor = .white
            vc.title = title
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

