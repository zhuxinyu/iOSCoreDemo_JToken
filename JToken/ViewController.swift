//
//  ViewController.swift
//  JToken
//
//  Created by xyz on 2022/3/29.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // test
        let a = JTokenizer("(multiply (add 1.4 3))").tokenizer()
        print(a)
    }
}

public struct JToken {
    var type = ""
    var value = ""
}

public class JTokenizer {
    private var _input: String
    private var _index: String.Index
    
    //parser tool
    var currentChar: Character? {
        return _index < _input.endIndex ? _input[_index] : nil
    }
    
    func advanceIndex() {
        _input.formIndex(after: &_index)
    }
    
    public init(_ input: String) {
//        _input = input.filterAnnotationBlock()
        _input = input
        _index = _input.startIndex
    }
    
    public func tokenizer() -> [JToken] {
        var tokens = [JToken]()
        while let aChar = currentChar {
            let s = aChar.description
            let symbols = ["(", ")"," "]
            if symbols.contains(s) {
                if s == " " {
                    advanceIndex()
                    continue
                }
                tokens.append(JToken(type: "paren", value: s))
                advanceIndex()
                continue
            } else {
                var word = ""
                while let sChar = currentChar {
                    let str = sChar.description
                    if symbols.contains(str) {
                        break
                    }
                    word.append(str)
                    advanceIndex()
                    continue
                }
                // 开始把连续字符进行 token 存储
                if word.count > 0 {
                    var tkType = "char"
                    if word.isFloat() {
                        tkType = "float"
                    }
                    if word.isInt() {
                        tkType = "int"
                    }
                    
                    tokens.append(JToken(type: tkType, value: word))
                }
                continue
            } // end if
        } // end while
        
        return tokens
    }
}

extension String {
    // 判断是否是整数
    func isInt() -> Bool {
        let scan: Scanner = Scanner(string: self)
        var val: Int = 0
        return scan.scanInt(&val) && scan.isAtEnd
    }
    
    // 判断是否是 Float
    func isFloat() -> Bool {
        let scan: Scanner = Scanner(string: self)
        var val: Float = 0
        return scan.scanFloat(&val) && scan.isAtEnd
    }
}
