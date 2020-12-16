//
//  ListSettingsViewController.swift
//  VariousPattern
//
//  Created by Kota Saito on 2020/03/22.
//  Copyright © 2020 ktst79. All rights reserved.
//

import UIKit

class ListSettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settings = UserDefaults.standard
        requestURL.text = settings.string(forKey: "requestUrl")
        // Do any additional setup after loading the view.
    }
    
    @IBAction func handleSave(_ sender: Any) {
        let settings = UserDefaults.standard
        settings.set(requestURL.text, forKey: "requestUrl")

        self.backToMainView(sender)
    }
    
    @IBAction func handleCancel(_ sender: Any) {
        self.backToMainView(sender)
        
    }
    
    func backToMainView(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var requestURL: UITextField!
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
