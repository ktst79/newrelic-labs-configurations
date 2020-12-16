//
//  WebViewController.swift
//  VariousPattern
//
//  Created by Kota Saito on 2020/03/22.
//  Copyright © 2020 ktst79. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        initView()
        updateView()
    }
    
    func initView() {
        let settings = UserDefaults.standard
        settings.register(defaults: ["siteUrl": "http://www.google.com"])
    }
    
    func getUrl() -> String? {
        let settings = UserDefaults.standard
        let urlStr = settings.string( forKey: "siteUrl")
        
        return urlStr
    }
    
    func updateView() {
        let urlStr = getUrl()
        let weburl = URL(string: urlStr!)
        if weburl != nil {
            let request = URLRequest(url: weburl!)
            
            print("Loading page: " + urlStr!)

            urlLabel.text = urlStr
            webContent.load(request)
        }
    }
    
    @IBOutlet weak var webContent: WKWebView!
    @IBOutlet weak var urlLabel: UILabel!
    @IBAction func settingButtonAction(_ sender: Any) {
        performSegue(withIdentifier: "goSetting", sender: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    override func viewWillAppear(_ animated: Bool) {
        updateView()
    }

}
