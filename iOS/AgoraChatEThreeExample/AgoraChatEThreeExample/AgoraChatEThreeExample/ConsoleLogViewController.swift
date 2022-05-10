//
//  ConsoleLogViewController.swift
//  AgoraChatEThreeExample
//
//  Created by 朱继超 on 2022/4/28.
//

import UIKit
import ProgressHUD
import ZSwiftBaseLib

final class ConsoleLogViewController: UIViewController,UITextFieldDelegate {
    
    private var index = 0
    
    private lazy var searchField: UITextField = {
        UITextField(frame: CGRect(x: 0, y: ZNavgationHeight, width: ScreenWidth, height: 40)).cornerRadius(5).layerProperties(.systemBlue, 1).placeholder("Search Log").delegate(self)
    }()
    
    private lazy var right: UIButton = {
        UIButton(type: .custom).addTargetFor(self, action: #selector(goNext), for: .touchUpInside).title("Next", .normal).frame(CGRect(x: 0, y: 0, width: 50, height: 40)).textColor(.systemBlue, .normal)
    }()
    
    private lazy var textView: UITextView = {
        UITextView(frame: CGRect(x: 0, y: self.searchField.frame.maxY, width: ScreenWidth, height: ScreenHeight - ZNavgationHeight - 40)).isEditable(false).font(UIFont.systemFont(ofSize: 20, weight: .medium))
    }()
    
    private var ranges = [NSRange]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubViews([self.searchField,self.textView])
        self.searchField.rightView = self.right
        self.searchField.rightViewMode = .always
        self.searchField.returnKeyType = .search
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: NSHomeDirectory() + "/Library/Application Support/HyphenateSDK/easemobLog/easemob.log"))
            self.textView.text = String(data: data, encoding: .utf8)
        } catch {
            ProgressHUD.showError("get log error:\(error.localizedDescription)")
        }
        // Do any additional setup after loading the view.
    }

}

extension ConsoleLogViewController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text,let content = self.textView.text else { return false }
        self.ranges = self.rangeOfString(string: content as NSString, andInString: text)
        if self.ranges.count <= 0 {
            return false
        }
        let range = NSMakeRange(0, 0)
        self.textView.scrollRangeToVisible(self.ranges.first ?? range)
        self.view.endEditing(true)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        true
    }
    
    @objc private func goNext() {
        self.view.endEditing(true)
        self.index += 1
        if self.ranges.count <= 0 {
            return
        }
        if self.index >= self.ranges.count {
            self.index = 0
        }
        let range = NSMakeRange(0, 0)
        self.textView.scrollRangeToVisible(self.ranges[safe: self.index] ?? range)
    }
    
    /// 获取字符出现的位置信息(支持多次位置获取)
    /// - Parameter string: 原始文本
    /// - Parameter inString: 需要查找的字符
    private func rangeOfString(string:NSString, andInString inString:String) -> [NSRange] {
        var arrRange = [NSRange]()
        var _fullText = string
        var rang:NSRange = _fullText.range(of: inString, options: .regularExpression)
        
        while rang.location != NSNotFound {
            var location:Int = 0
            for _range in arrRange {
                location += _range.location + _range.length
            }
            
            _fullText = NSString(string: _fullText.substring(from: rang.location + rang.length))
            
            if arrRange.count > 0 {
                rang.location += location
            }
            arrRange.append(rang)
            
            rang = _fullText.range(of: inString)
        }
        
        return arrRange
    }
    
}
