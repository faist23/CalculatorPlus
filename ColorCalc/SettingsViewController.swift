//
//  SettingsViewController.swift
//  ColorCalc
//
//  Created by Craig Faist on 3/17/17.
//  Copyright © 2017 Spectrum Image, LLC. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    var x:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // Color Settings
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let newView = segue.destination as! ViewController
// print(segue.identifier)
        if (segue.identifier == "redGray") {
            if #available(iOS 10.3, *) {
                UIApplication.shared.setAlternateIconName(nil)
            } else {
                // Fallback on earlier versions
            }
            newView.stringPassed = "1"
        }
        else if (segue.identifier == "redGold") {
            if #available(iOS 10.3, *) {
                UIApplication.shared.setAlternateIconName("AppIcon-2")
            } else {
                // Fallback on earlier versions
            }
            newView.stringPassed = "2"
        }
        else if (segue.identifier == "redWhite") {
            if #available(iOS 10.3, *) {
                UIApplication.shared.setAlternateIconName("AppIcon-3")
            } else {
                // Fallback on earlier versions
            }
            newView.stringPassed = "3"
        }
        else if (segue.identifier == "blueGray") {
            if #available(iOS 10.3, *) {
                UIApplication.shared.setAlternateIconName("AppIcon-4")
            } else {
                // Fallback on earlier versions
            }
            newView.stringPassed = "4"
        }
        else if (segue.identifier == "blueGold") {
            if #available(iOS 10.3, *) {
                UIApplication.shared.setAlternateIconName("AppIcon-5")
            } else {
                // Fallback on earlier versions
            }
            newView.stringPassed = "5"
        }
        else if (segue.identifier == "blueWhite") {
            if #available(iOS 10.3, *) {
                UIApplication.shared.setAlternateIconName("AppIcon-6")
            } else {
                // Fallback on earlier versions
            }
            newView.stringPassed = "6"
        }
        else if (segue.identifier == "greenGold") {
            if #available(iOS 10.3, *) {
                UIApplication.shared.setAlternateIconName("AppIcon-7")
            } else {
                // Fallback on earlier versions
            }
            newView.stringPassed = "7"
        }
        else if (segue.identifier == "greenWhite") {
            if #available(iOS 10.3, *) {
                UIApplication.shared.setAlternateIconName("AppIcon-8")
            } else {
                // Fallback on earlier versions
            }
            newView.stringPassed = "8"
        }
        else if (segue.identifier == "purpleWhite") {
            if #available(iOS 10.3, *) {
                UIApplication.shared.setAlternateIconName("AppIcon-9")
            } else {
                // Fallback on earlier versions
            }
            newView.stringPassed = "9"
        }
        else if (segue.identifier == "orangeWhite") {
            if #available(iOS 10.3, *) {
                UIApplication.shared.setAlternateIconName("AppIcon-10")
            } else {
                // Fallback on earlier versions
            }
            newView.stringPassed = "10"
        }
        print(newView.stringPassed)
    }
    
}
