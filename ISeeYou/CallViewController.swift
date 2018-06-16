//
//  CallViewController.swift
//  ISeeYou
//
//  Created by 李嘉晟 on 2018/6/13.
//  Copyright © 2018 李嘉晟. All rights reserved.
//

import UIKit
import MapKit

class CallViewController: UIViewController {

    @IBOutlet weak var ringButton: UIButton!
    @IBOutlet weak var landMarkImageView: UIImageView!
    
    @IBAction func Ring(_ sender: Any) {
        isRinging = !isRinging
        if isRinging {
            ringButton.setImage(UIImage(named: "unring"), for: .normal)
        } else {
            ringButton.setImage(UIImage(named: "ring"), for: .normal)
        }
    }
    
    var isRinging = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        landMarkImageView.layer.cornerRadius = 10
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
