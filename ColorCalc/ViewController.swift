//
//  ViewController.swift
//  ColorCalc
//
//  Created by Craig Faist on 2/12/17.
//  Copyright © 2017 Spectrum Image, LLC. All rights reserved.
//

import UIKit
import GoogleMobileAds // google mobile ads

enum modes {
    case not_set
    case addition
    case subtraction
    case multiplication
    case division
}


class ViewController: UIViewController, UIInputViewAudioFeedback, GADBannerViewDelegate { // google mobile ads
    @IBOutlet weak var label: UILabel!
    
    let bannerView: GADBannerView = GADBannerView.init(adSize: kGADAdSizeSmartBannerPortrait)
    
    var enableInputClicksWhenVisible: Bool {
        return true
    }
    
    var labelString:String = "0"
    var operator1:String = ""
    var equation:String = ""
    var currentMode:modes = .not_set
    var saveNum:Double = 0
    var saveNum2:Double = 0
    var lastButtonWasMode:Bool = false
    var decimalUsed = false
    var memoryNum:Double = 0
    let redColor = UIColor(hue: 359/360, saturation: 0.95, brightness: 0.84, alpha: 1)
    let lightGray = UIColor(hue: 359/360, saturation: 0, brightness: 0.8, alpha: 1)
    let darkGray = UIColor(hue: 359/360, saturation: 0, brightness: 0.6, alpha: 1)
    let mediumGray = UIColor(hue: 359/360, saturation: 0, brightness: 0.7, alpha: 1)
    let greenColor = UIColor(hue: 120/360, saturation: 1, brightness: 0.5, alpha: 1)
    let goldColor = UIColor(hue: 56/360, saturation: 1, brightness: 1, alpha: 1)
    let medGoldColor = UIColor(hue: 56/360, saturation: 1, brightness: 0.9, alpha: 1)
    let darkGoldColor = UIColor(hue: 56/360, saturation: 1, brightness: 0.8, alpha: 1)
    
    @IBOutlet var operatorButtons: [UIButton]!
    @IBOutlet var functionButtons: [UIButton]!
    @IBOutlet var clearButtons: [UIButton]!
    @IBOutlet var numberButtons: [UIButton]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupAdBanner()
        
// testing button color changes
        for button in self.operatorButtons {
            button.backgroundColor = redColor
        }
        for button in self.functionButtons {
            button.backgroundColor = mediumGray
        }
        for button in self.clearButtons {
            button.backgroundColor = darkGray
        }
        for button in self.numberButtons {
            button.backgroundColor = lightGray
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPressSettings(_ sender: Any) {
        for button in self.operatorButtons {
            button.backgroundColor = greenColor
        }
        for button in self.functionButtons {
            button.backgroundColor = medGoldColor
        }
        for button in self.clearButtons {
            button.backgroundColor = darkGoldColor
        }
        for button in self.numberButtons {
            button.backgroundColor = goldColor
        }
        
    }
    
    @IBOutlet weak var memUsedLabel: UILabel!
    @IBOutlet weak var labelDarkGray: UILabel!
    @IBOutlet weak var labelBlack: UILabel!
    
    
    @IBAction func didPressPlus(_ sender: Any) {
        operator1 = "+"
        changeMode(newMode: .addition)
    }
    @IBAction func didPressMinus(_ sender: Any) {
        operator1 = "-"
        changeMode(newMode: .subtraction)
    }
    @IBAction func didPressMultiply(_ sender: Any) {
        operator1 = "*"
        changeMode(newMode: .multiplication)
    }
    @IBAction func didPressDivide(_ sender: Any) {
        operator1 = "/"
        changeMode(newMode: .division)
    }
    
    @IBAction func didPressMClear(_ sender: Any) {
        UIDevice.current.playInputClick()
        memoryNum = 0
        memUsedLabel.textColor = labelDarkGray.textColor
    }
    @IBAction func didPressMPlus(_ sender: Any) {
        UIDevice.current.playInputClick()
        memoryNum += Double(labelString)!
        memUsedLabel.textColor = labelBlack.textColor
        lastButtonWasMode = true
    }
    @IBAction func didPressMMinus(_ sender: Any) {
        UIDevice.current.playInputClick()
        memoryNum -= Double(labelString)!
        memUsedLabel.textColor = labelBlack.textColor
        lastButtonWasMode = true
    }
    @IBAction func didPressMRecall(_ sender: Any) {
        UIDevice.current.playInputClick()
        //        currentMode = .not_set
        labelString = "\(memoryNum)"
        updateText()
        lastButtonWasMode = true
        decimalUsed = false
    }
    
    @IBAction func didPressEquals(_ sender: Any) {
        if currentMode == .not_set  {  // || lastButtonWasMode
            return
        }
        
        equation = equation + labelString // testing equation for correct math function
        
        currentMode = .not_set
  
        print(equation)
        let expression = NSExpression(format: equation)
        saveNum2 = expression.expressionValue(with: nil, context: nil) as! Double
        
        print(saveNum2,saveNum,equation)
        labelString = "\(saveNum2)"
        equation = ""
        
        updateText()
        lastButtonWasMode = true
        decimalUsed = false
    }
    
    @IBAction func didPressClear(_ sender: Any) {
        UIDevice.current.playInputClick()
        if (sender as AnyObject).titleLabel??.text == "AC" {
            (sender as AnyObject).setTitle("C", for: .normal)
            currentMode = .not_set
            saveNum = 0
            saveNum2 = 0
            lastButtonWasMode = false
        } else if currentMode != .not_set {
            (sender as AnyObject).setTitle("AC", for: .normal)
        }
        labelString = "0"
        label.text = "0"
    }
    @IBAction func didPressNumber(_ sender: UIButton) {
        let stringValue:String? = sender.titleLabel?.text
        if sender.titleLabel?.text == "." && decimalUsed {
            return
        } else {
            
            if sender.titleLabel?.text == "." {
                decimalUsed = true
            }
            
            if lastButtonWasMode {
                lastButtonWasMode = false
                labelString = "0"
            }
            if labelString.characters.count > 10 {
                return
            }
            labelString = labelString.appending(stringValue!)
            updateText()
        }
    }
    
    @IBAction func didPressPlusMinus(_ sender: Any) {
        UIDevice.current.playInputClick()
        if labelString[labelString.startIndex] == "-" {
            labelString.remove(at: labelString.startIndex)
        } else {
            labelString = "-" + labelString
        }
        updateText()
    }
    
    @IBAction func didPressPercent(_ sender: Any) {
        if currentMode == .not_set {
            labelString = "\(Double(labelString)! / 100)"
            updateText()
            return
        }
        if currentMode == .addition {
            labelString = "\(saveNum * Double(labelString)! / 100)"
        } else if currentMode == .subtraction {
            labelString = "\(saveNum * Double(labelString)! / 100)"
        } else if currentMode == .multiplication {
            labelString = "\(Double(labelString)! / 100)"
        } else if currentMode == .division {
            labelString = "\(Double(labelString)! / 100)"
        }
        updateText()
    }
    @IBAction func didPressDelete(_ sender: Any) {
        if lastButtonWasMode {
            return
        }
        UIDevice.current.playInputClick()
        if labelString == "0" {
            labelString = "0"
            label.text = "0"
        } else {
            if labelString[labelString.index(before: labelString.endIndex)] == "." {
                decimalUsed = false
            }
            labelString.remove(at: labelString.index(before: labelString.endIndex))
            updateText()
        }
        
    }
    
    func updateText() {
        UIDevice.current.playInputClick()
        guard let labelNbr:Double = Double(labelString) else {
            return
        }
        if (currentMode == .not_set) {
            saveNum = labelNbr
        }
        let formatter:NumberFormatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 9
        let num:NSNumber = NSNumber(value: labelNbr)
        label.text = formatter.string(from: num)
        if labelString[labelString.index(before: labelString.endIndex)] == "." {
            label.text = label.text! + "."
        }
    }
    
    func changeMode(newMode:modes) {
            equation = equation + "\(Double(labelString)!)"

        if currentMode != .not_set && (newMode == .addition || newMode == .subtraction) {
            let exp: NSExpression = NSExpression(format: equation)
            saveNum = exp.expressionValue(with: nil, context: nil) as! Double
            equation = "\(saveNum)"
            labelString = "\(saveNum)"
            updateText()
        }
        equation = equation + operator1
print(equation)
        currentMode = newMode
        lastButtonWasMode = true
        decimalUsed = false

  print(currentMode,newMode,saveNum,saveNum2)
    }
    
    
    // google ads
    func setupAdBanner() {
        // set the banner orientation when the view loads
        let currentDevice: UIDevice = UIDevice.current
        let orientation: UIDeviceOrientation = currentDevice.orientation
        
        if orientation.isLandscape {
            setBannerOrientation(portrait: false)
        }

        // Load an ad in the usual way
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        bannerView.adUnitID = "ca-app-pub-2036170160247702/7529154872"
        bannerView.rootViewController = self
        let request = GADRequest()
        
        // google test ads begin
        request.testDevices = [ kGADSimulatorID, "5be20290b246c80a40a8a5748a64c1f8" ]
        // google test ads end
        
        bannerView.load(request)
        self.bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        // create contraints to centre the add and pin to the bottom of the view
        let xConstraint = NSLayoutConstraint(item: bannerView, attribute: .centerX,
                                             relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
        
        let pinBottom = NSLayoutConstraint(item: bannerView, attribute: .bottom,
                                           relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        
        // must add to sub view prior to adding constraints
        self.view.addSubview(bannerView)
        
        self.view.addConstraint(xConstraint)
        self.view.addConstraint(pinBottom)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        // detect orientation change and adjust banner accordingly
        if UIDevice.current.orientation.isLandscape {
            setBannerOrientation(portrait: false)
        } else {
            setBannerOrientation(portrait: true)
        }
    }
    
    func setBannerOrientation( portrait: Bool ){
        if portrait {
            self.bannerView.adSize = kGADAdSizeSmartBannerPortrait;
        } else {
            // Landscape
            self.bannerView.adSize = kGADAdSizeSmartBannerLandscape;
        }
    }
    // google ads
}

