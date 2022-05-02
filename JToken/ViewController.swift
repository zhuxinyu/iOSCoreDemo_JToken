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
    
    // 打印语法树 （遍历语法树打印每一个节点）
    private func astPrintable(_ tree: [JNode]) {
        for aNode in tree {
            recDesNode(aNode, level: 0)
        }
    }
    
    // 打印一个节点
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
        case .Root:
            dataStr = "Root is \(node.type)(\(node.name)"
        case .ExpressionStatement:
            dataStr = "ExpressionStatement is \(node.type)(\(node.name)"
        case .Identifier:
            dataStr = "Identifier is \(node.type)(\(node.name)"
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
    
    // 词法分析
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
public enum JNodeType: String {
    case None
    case NumberLiteral
    case CallExpression
    case Root
    case ExpressionStatement
    case Identifier
}

public protocol JNodeBase {
    var type: JNodeType {get}
    var name: String {get}
    var params: [JNode] {get}
    var expressionts: [JNode] {get}
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
    public var expressionts = [JNode]()
    public var numberType = JNumberType.int
    public var intValue: Int = 0
    public var floatValue: Float = 0
    public var callee = JnodeCallee()
}

public struct JnodeCallee: JNodeBase, JNodeNumberLiteral {
    public var type = JNodeType.None
    public var name = ""
    public var params = [JNode]()
    public var expressionts = [JNode]()
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
    
    // 语法分析 （遍历词法数组，对每个解析成语法节点的添加到语法树）
    public func parser() -> [JNode] {
        _current = 0
        var nodeTree = [JNode]()
        while _current < _tokens.count {
            nodeTree.append(walk())
        }
        _current = 0 // 用完重置
        return nodeTree
    }
    
    // 处理当前节点，组装成语法节点
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

// 遍历器-转换器 -> 语法树转节点树
public class JTransformer {
    
    public typealias VisitorClosure = (JNode, JNode) -> JNode
     
    var ast = [JNode]()
    
    public func traverser(visitor: [String: VisitorClosure], ast:[JNode]) {
        func traverseChildNode(childrens:[JNode], parent: JNode) {
            for child in childrens {
                traverseNode(node: child, parent: parent)
            }
        }
        
        func traverseNode(node: JNode, parent: JNode) {
            // 执行外部传入的closure
            if visitor.keys.contains(node.type.rawValue) {
                if let closure:VisitorClosure = visitor[node.type.rawValue] {
                    self.ast.append(closure(node, parent))
                }
            }
            // 看是否有子节点需要继续遍历
            if node.params.count > 0 {
                traverseChildNode(childrens: node.params, parent: node)
            }
        }
        
        var rootNode = JNode()
        rootNode.type = .Root
        traverseChildNode(childrens: ast, parent: rootNode)
    }
    
    let numberLiteralClosure: VisitorClosure = { (node, parent) in
        var currentParent = parent
        if currentParent.type == .ExpressionStatement {
            currentParent.expressionts[0].params.append(node)
        }
        if currentParent.type == .CallExpression {
            currentParent.params.append(node)
        }
        return currentParent
    }
    
    let callExpressionClosure: VisitorClosure = { (node, parent) in
        var currentParent = parent
        
        var exp = JNode()
        exp.type = .CallExpression
        
        var callee = JnodeCallee()
        callee.type = .Identifier
        callee.name = node.name
        exp.callee = callee
        
        if parent.type != .CallExpression {
            var exps = JNode()
            exp.type = .ExpressionStatement
            exp.expressionts.append(exp)
            currentParent = exps
        } else {
            currentParent.expressionts[0].params.append(exp)
            currentParent = exp
        }
        return currentParent
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
