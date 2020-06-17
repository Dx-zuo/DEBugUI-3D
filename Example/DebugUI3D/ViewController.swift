//
//  ViewController.swift
//  DebugUI3D
//
//  Created by Dx-zuo on 06/17/2020.
//  Copyright (c) 2020 Dx-zuo. All rights reserved.
//

import UIKit
import DebugUI3D

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "DebugUI", style: .done, target: self, action: #selector(showDebugUI))
//        Debug3DView.show()
        // Do any additional setup after loading the view, typically from a nib.
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        Debug3DView.show()
    }
    @objc
    func showDebugUI() {
        DebugUI3D.Debug3DView.show()
        
    }
    @IBAction func didtap(_ sender: Any) {
        self.navigationController?.pushViewController(UITableViewController(), animated: true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

