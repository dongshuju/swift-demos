//
//  ViewController.swift
//  Swift-GCD-demo
//
//  Created by shujucn on 2018/4/18.
//  Copyright © 2018 shuju. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    /// 队列类型
    enum DispatchTaskType: String {
        case serial
        case concurrent
        case main
        case global
    }
    
    // 定义队列
    let serialQueue = DispatchQueue(label: "com.DispatchQueueTest.serialQueue")
    let concurrentQueue = DispatchQueue(
        label: "com.DispatchQueueTest.concurrentQueue",
        attributes: .concurrent)
    let mainQueue = DispatchQueue.main
    let globalQueue = DispatchQueue.global()
    
    // 定义队列 key
    let serialQueueKey = DispatchSpecificKey<String>()
    let concurrentQueueKey = DispatchSpecificKey<String>()
    let mainQueueKey = DispatchSpecificKey<String>()
    let globalQueueKey = DispatchSpecificKey<String>()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // 初始化队列 key
        serialQueue.setSpecific(key: serialQueueKey, value: DispatchTaskType.serial.rawValue)
        concurrentQueue.setSpecific(key: concurrentQueueKey, value: DispatchTaskType.concurrent.rawValue)
        mainQueue.setSpecific(key: mainQueueKey, value: DispatchTaskType.main.rawValue)
        globalQueue.setSpecific(key: globalQueueKey, value: DispatchTaskType.global.rawValue)
        
        
        testSyncTaskNestedInSameConcurrentQueue();
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /// 打印当前线程
    func printCurrentThread(with des: String, _ terminator: String = "") {
        print("\(des) at thread: \(Thread.current), this is \(Thread.isMainThread ? "" : "not ")main thread\(terminator)")
    }
    
    /// 测试任务是否在指定队列中
    func testIsTaskInQueue(_ queueType: DispatchTaskType, key: DispatchSpecificKey<String>) {
        let value = DispatchQueue.getSpecific(key: key)
        let opnValue: String? = queueType.rawValue
        print("Is task in \(queueType.rawValue) queue: \(value == opnValue)")
    }
    
    
    /// 串行队列中新增同步任务
    func testSyncTaskInSerialQueue() {
        self.printCurrentThread(with: "start test")
        serialQueue.sync {
            print("\nserialQueue sync task--->")
            self.printCurrentThread(with: "serialQueue sync task")
            self.testIsTaskInQueue(.serial, key: serialQueueKey)
            print("--->serialQueue sync task\n")
        }
        self.printCurrentThread(with: "end test")
    }
    
    /// 串行队列任务中嵌套本队列的同步任务
    func testSyncTaskNestedInSameSerialQueue() {
        printCurrentThread(with: "start test")
        serialQueue.async {
            print("\nserialQueue async task--->")
            self.printCurrentThread(with: "serialQueue async task")
            self.testIsTaskInQueue(.serial, key: self.serialQueueKey)
            
            self.serialQueue.sync {
                print("\nserialQueue sync task--->")
                self.printCurrentThread(with: "serialQueue sync task")
                self.testIsTaskInQueue(.serial, key: self.serialQueueKey)
                print("--->serialQueue sync task\n")
            } // Thread 9: EXC_BREAKPOINT (code=1, subcode=0x101613ba4)
            
            /*
             执行结果，执行到嵌套任务时程序就崩溃了，这是死锁导致的。其中有个有意思的现象，这里串行队列的第一个任务运行在非主线程上，在异步任务部分会解释。
             这里死锁是由两个因素导致：串行队列、同步任务，回顾一下串行队列的特性就好解释了：串行队列中执行任务的线程不允许被当前队列中的任务阻塞。
             */
            
            print("--->serialQueue async task\n")
        }
        printCurrentThread(with: "end test")
    }
    
    /// 并行队列任务中嵌套本队列的同步任务
    func testSyncTaskNestedInSameConcurrentQueue() {
        /*
         同步任务直接在当前线程运行。
         */
        printCurrentThread(with: "start test")
        concurrentQueue.async {
            print("\nconcurrentQueue async task--->")
            self.printCurrentThread(with: "concurrentQueue async task")
            self.testIsTaskInQueue(.concurrent, key: self.concurrentQueueKey)
            
            self.concurrentQueue.sync {
                print("\nconcurrentQueue sync task--->")
                self.printCurrentThread(with: "concurrentQueue sync task")
                self.testIsTaskInQueue(.concurrent, key: self.concurrentQueueKey)
                print("--->concurrentQueue sync task\n")
            }
            
            print("--->concurrentQueue async task\n")
        }
        printCurrentThread(with: "end test")
    }
    
    /// 串行队列中嵌套其他队列的同步任务
    func testSyncTaskNestedInOtherSerialQueue() {
        // 创建另一个串行队列
        let serialQueue2 = DispatchQueue(
            label: "com.sinkingsoul.DispatchQueueTest.serialQueue2")
        let serialQueueKey2 = DispatchSpecificKey<String>()
        serialQueue2.setSpecific(key: serialQueueKey2, value: "serial2")
        
        self.printCurrentThread(with: "start test")
        serialQueue.sync {
            print("\nserialQueue sync task--->")
            self.printCurrentThread(with: "nserialQueue sync task")
            self.testIsTaskInQueue(.serial, key: self.serialQueueKey)
            
            serialQueue2.sync {
                print("\nserialQueue2 sync task--->")
                self.printCurrentThread(with: "serialQueue2 sync task")
                self.testIsTaskInQueue(.serial, key: self.serialQueueKey)
                
                let value = DispatchQueue.getSpecific(key: serialQueueKey2)
                let opnValue: String? = "serial2"
                print("Is task in serialQueue2: \(value == opnValue)")
                print("--->serialQueue2 sync task\n")
            }
            
            print("--->serialQueue sync task\n")
        }
    }
}

