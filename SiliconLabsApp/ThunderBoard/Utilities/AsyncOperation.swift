//
//  AsyncOperation.swift
//  Thunderboard
//
//  Copyright © 2016 Silicon Labs. All rights reserved.
//

//  Inspired by ConcurrentOperation.swift
//  https://gist.github.com/calebd/93fa347397cec5f88233

import UIKit

typealias AsyncOperationBlock = ((AsyncOperation) -> Void)

class AsyncOperation: Operation {

    var operationBlock: AsyncOperationBlock?
    
    init(block: @escaping AsyncOperationBlock) {
        super.init()
        self.operationBlock = block
    }
    
    fileprivate var state = OperationState.ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath())
            willChangeValue(forKey: state.keyPath())
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath())
            didChangeValue(forKey: state.keyPath())
        }
    }
    fileprivate enum OperationState {
        case ready, executing, finished
        func keyPath() -> String {
            switch self {
            case .ready:     return "isReady"
            case .executing: return "isExecuting"
            case .finished:  return "isFinished"
            }
        }
    }
    
    //MARK: - Public
    
    func done() {
        state = .finished
    }

    //MARK:- Overrides
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isReady: Bool {
        return super.isReady && state == .ready
    }
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    override func start() {
        state = .executing
        operationBlock?(self)
    }
}

extension OperationQueue {    
    func tb_addAsyncOperationBlock(_ block: @escaping AsyncOperationBlock) -> AsyncOperation {
        let operation = AsyncOperation(block: block)
        self.addOperation(operation)
        return operation
    }
    
    func tb_addAsyncOperationBlock(_ name: String, block: @escaping AsyncOperationBlock) -> AsyncOperation {
        let operation = self.tb_addAsyncOperationBlock(block)
        operation.name = name
        return operation
    }
}
