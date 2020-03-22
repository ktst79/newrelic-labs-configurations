//
//  SettingViewController.swift
//  VariousPattern
//
//  Created by Kota Saito on 2020/03/22.
//  Copyright © 2020 ktst79. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settings = UserDefaults.standard
        siteUrl.text = settings.string(forKey: "siteUrl")

        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var siteUrl: UITextField!
    
    @IBAction func saveAction(_ sender: Any) {
        let settings = UserDefaults.standard
        settings.set(siteUrl.text, forKey: "siteUrl")

        self.backToMainView(sender)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.backToMainView(sender)
    }
    
    func backToMainView(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
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
