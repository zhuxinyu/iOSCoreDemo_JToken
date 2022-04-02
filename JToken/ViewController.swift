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
        
        // 词法分析
        let a = JTokenizer("(multiply (add 1.4 3))").tokenizer()
        // 语法分析
        let b = JParser("(multiply (add 1.4 3))").parser()
        
        print(a)
        print(astPrintable(b))
    }
    
    private func astPrintable(_ tree: [JNode]) {
        for aNode in tree {
            recDesNode(aNode, level: 0)
        }
    }
    
    private func recDesNode(_ node:JNode, level: Int) {
        let nodeTypeStr = node.type
        var preSpace = ""
        for _ in 0...level {
            if level > 0 {
                preSpace += " "
            }
        }
        var dataStr = ""
        switch node.type {
        case .NumberLiteral:
            var numberStr = ""
            if node.numberType == .float {
                numberStr = "\(node.floatValue)"
            }
            if node.numberType == .int {
                numberStr = "\(node.intValue)"
            }
            dataStr = "number type is \(node.numberType) number is \(numberStr)"
        case .None:
            dataStr = ""
        case .CallExpression:
            dataStr = "expression is \(node.type)(\(node.name))"
        }
        print("\(preSpace) \(nodeTypeStr) \(dataStr)")
        
        if node.params.count > 0 {
            for aNode in node.params {
                recDesNode(aNode, level: level + 1)
            }
        }
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

// 值类型
public enum JNumberType {
    case int, float
}

// 节点类型
public enum JNodeType {
    case None
    case NumberLiteral
    case CallExpression
}

public protocol JNodeBase {
    var type: JNodeType {get}
    var name: String {get}
    var params: [JNode] {get}
}

public protocol JNodeNumberLiteral {
    var numberType: JNumberType {get}
    var intValue: Int {get}
    var floatValue: Float {get}
}

public struct JNode: JNodeBase, JNodeNumberLiteral {
    public var type = JNodeType.None
    public var name = ""
    public var params = [JNode]()
    public var numberType = JNumberType.int
    public var intValue: Int = 0
    public var floatValue: Float = 0
}

// 解析类
public class JParser {
    private var _tokens: [JToken]
    private var _current: Int
    
    public init(_ input: String) {
        _tokens = JTokenizer(input).tokenizer()
        _current = 0
    }
    
    public func parser() -> [JNode] {
        _current = 0
        var nodeTree = [JNode]()
        while _current < _tokens.count {
            nodeTree.append(walk())
        }
        _current = 0 // 用完重置
        return nodeTree
    }
    
    private func walk() -> JNode {
        var tk = _tokens[_current]
        var jNode = JNode()
        // 检查是不是数字类型节点
        if tk.type == "int" || tk.type == "float" {
            _current += 1
            jNode.type = .NumberLiteral
            if tk.type == "int", let intV = Int(tk.value) {
                jNode.intValue = intV
                jNode.numberType = .int
            }
            if tk.type == "float", let floatV = Float(tk.value) {
                jNode.floatValue = floatV
                jNode.numberType = .float
            }
            return jNode
        }
        
        // 检查是或否是CallExpression类型
        if tk.type == "paren" && tk.value == "(" {
            // 跳过符号
            _current += 1
            tk = _tokens[_current]
            
            jNode.type = .CallExpression
            jNode.name = tk.value
            _current += 1
            while tk.type != "paren" || (tk.type == "paren" && tk.value != ")") {
                // 递归下降
                jNode.params.append(walk())
                tk = _tokens[_current]
            }
            // 跳到下一个
            _current += 1
            return jNode
        }
        _current += 1
        return jNode
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
