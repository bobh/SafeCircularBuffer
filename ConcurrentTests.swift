//
//  ConcurrentTests.swift
//  Swift6Test
//
//  Created by bobh on 5/22/25.
//

import Foundation
import AVFoundation
import os.log

// MARK: - Test Framework Actor
actor TestRunner: Sendable {
    private var passedTests = 0
    private var failedTests = 0
    private let logger = Logger(subsystem: "CircularBufferTests", category: "TestRunner")
    
    func recordPass(_ testName: String) {
        passedTests += 1
        logger.info("✅ \(testName) PASSED")
    }
    
    func recordFailure(_ testName: String, _ message: String) {
        failedTests += 1
        logger.error("❌ \(testName) FAILED: \(message)")
    }
    
    func printSummary() {
        let total = passedTests + failedTests
        logger.notice("📊 Test Summary: \(self.passedTests)/\(total) passed, \(self.failedTests) failed")
    }
}

// MARK: - Test Data Types
struct TestMessage: Sendable, Equatable {
    let id: Int
    let content: String
    
    init(id: Int, content: String = "test") {
        self.id = id
        self.content = content
    }
}

// MARK: - Basic Functionality Tests
actor BasicTests: Sendable {
    private let testRunner: TestRunner
    private let logger = Logger(subsystem: "CircularBufferTests", category: "BasicTests")
    
    init(testRunner: TestRunner) {
        self.testRunner = testRunner
    }
    
    func runAllTests() async {
        logger.notice("🚀 Starting Basic Functionality Tests")
        
        await testInitialization()
        await testEmptyBufferBehavior()
        await testSingleElementOperations()
        await testBufferFilling()
        await testOverwriteBehavior()
        await testClearOperation()
        await testPeekOperation()
        await testArrayConversion()
    }
    
    
    
    private func testInitialization() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 5)
        
        let isEmpty = await buffer.isEmpty
        let isFull = await buffer.isFull
        let count = await buffer.count
        
        if isEmpty && !isFull && count == 0 {
            await testRunner.recordPass("testInitialization")
        } else {
            await testRunner.recordFailure("testInitialization", "Expected empty buffer, got isEmpty:\(isEmpty), isFull:\(isFull), count:\(count)")
        }
    }
    
    private func testEmptyBufferBehavior() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 3)
        
        let popResult = await buffer.pop()
        let peekResult = await buffer.peek()
        
        if popResult == nil && peekResult == nil {
            await testRunner.recordPass("testEmptyBufferBehavior")
        } else {
            await testRunner.recordFailure("testEmptyBufferBehavior", "Expected nil from empty buffer operations")
        }
    }
    
    private func testSingleElementOperations() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 3)
        let testMsg = TestMessage(id: 1, content: "single")
        
        let overwritten = await buffer.push(testMsg)
        let peeked = await buffer.peek()
        let popped = await buffer.pop()
        let isEmpty = await buffer.isEmpty
        
        if overwritten == nil && peeked?.id == 1 && popped?.id == 1 && isEmpty {
            await testRunner.recordPass("testSingleElementOperations")
        } else {
            await testRunner.recordFailure("testSingleElementOperations", "Single element operations failed")
        }
    }
    
    private func testBufferFilling() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 3)
        
        // Fill buffer completely
        for i in 1...3 {
            _ = await buffer.push(TestMessage(id: i))
        }
        
        let isFull = await buffer.isFull
        let count = await buffer.count
        let isEmpty = await buffer.isEmpty
        
        if isFull && count == 3 && !isEmpty {
            await testRunner.recordPass("testBufferFilling")
        } else {
            await testRunner.recordFailure("testBufferFilling", "Buffer not properly filled: isFull:\(isFull), count:\(count)")
        }
    }
    
    private func testOverwriteBehavior() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 2)
        
        // Fill buffer
        _ = await buffer.push(TestMessage(id: 1))
        _ = await buffer.push(TestMessage(id: 2))
        
        // This should overwrite the first element
        let overwritten = await buffer.push(TestMessage(id: 3))
        let firstElement = await buffer.pop()
        
        if overwritten?.id == 1 && firstElement?.id == 2 {
            await testRunner.recordPass("testOverwriteBehavior")
        } else {
            /*
             await testRunner.recordFailure("testOverwriteBehavior", "Overwrite behavior incorrect: overwritten:\(overwritten?.id), first:\(firstElement?.id)")
             */
            await testRunner.recordFailure("testOverwriteBehavior", "Overwrite behavior incorrect: overwritten:\(String(describing: overwritten?.id)), first:\(String(describing: firstElement?.id))")
        }
    }
    
    private func testClearOperation() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 3)
        
        // Fill buffer
        for i in 1...3 {
            _ = await buffer.push(TestMessage(id: i))
        }
        
        await buffer.clear()
        
        let isEmpty = await buffer.isEmpty
        let count = await buffer.count
        let popResult = await buffer.pop()
        
        if isEmpty && count == 0 && popResult == nil {
            await testRunner.recordPass("testClearOperation")
        } else {
            await testRunner.recordFailure("testClearOperation", "Clear operation failed")
        }
    }
    
    private func testPeekOperation() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 3)
        
        _ = await buffer.push(TestMessage(id: 42))
        
        let peeked1 = await buffer.peek()
        let peeked2 = await buffer.peek()
        let count = await buffer.count
        
        if peeked1?.id == 42 && peeked2?.id == 42 && count == 1 {
            await testRunner.recordPass("testPeekOperation")
        } else {
            await testRunner.recordFailure("testPeekOperation", "Peek should not modify buffer")
        }
    }
    
    private func testArrayConversion() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 4)
        
        for i in 1...3 {
            _ = await buffer.push(TestMessage(id: i))
        }
        
        let array = await buffer.toArray()
        
        if array.count == 3 && array[0].id == 1 && array[1].id == 2 && array[2].id == 3 {
            await testRunner.recordPass("testArrayConversion")
        } else {
            await testRunner.recordFailure("testArrayConversion", "Array conversion failed: \(array.map(\.id))")
        }
    }
}


// MARK: - Edge Case Tests
actor EdgeCaseTests: Sendable {
    private let testRunner: TestRunner
    private let logger = Logger(subsystem: "CircularBufferTests", category: "EdgeCaseTests")
    
    init(testRunner: TestRunner) {
        self.testRunner = testRunner
    }
    
    func runAllTests() async {
        logger.notice("🔍 Starting Edge Case Tests")
        
        await testCapacityOne()
        await testLargeCapacity()
        await testRepeatedFillAndDrain()
        await testBatchPushEmpty()
        await testBatchPushPartialFill()
        await testBatchPushOverfill()
        await testMixedOperations()
    }
    
    private func testCapacityOne() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 1)
        
        let overwritten1 = await buffer.push(TestMessage(id: 1))
        let overwritten2 = await buffer.push(TestMessage(id: 2))
        let popped = await buffer.pop()
        let isEmpty = await buffer.isEmpty
        
        if overwritten1 == nil && overwritten2?.id == 1 && popped?.id == 2 && isEmpty {
            await testRunner.recordPass("testCapacityOne")
        } else {
            await testRunner.recordFailure("testCapacityOne", "Capacity-1 buffer failed")
        }
    }
    
    private func testLargeCapacity() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 1000)
        
        // Fill half the buffer
        for i in 1...500 {
            _ = await buffer.push(TestMessage(id: i))
        }
        
        let count = await buffer.count
        let isFull = await buffer.isFull
        let array = await buffer.toArray()
        
        if count == 500 && !isFull && array.count == 500 && array.first?.id == 1 && array.last?.id == 500 {
            await testRunner.recordPass("testLargeCapacity")
        } else {
            await testRunner.recordFailure("testLargeCapacity", "Large capacity test failed")
        }
    }
    
    private func testRepeatedFillAndDrain() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 3)
        
        var success = true
        
        // Perform multiple fill/drain cycles
        for cycle in 1...5 {
            // Fill
            for i in 1...3 {
                _ = await buffer.push(TestMessage(id: cycle * 10 + i))
            }
            
            // Drain
            for _ in 1...3 {
                _ = await buffer.pop()
            }
            
            let isEmpty = await buffer.isEmpty
            if !isEmpty {
                success = false
                break
            }
        }
        
        if success {
            await testRunner.recordPass("testRepeatedFillAndDrain")
        } else {
            await testRunner.recordFailure("testRepeatedFillAndDrain", "Repeated cycles failed")
        }
    }
    
    private func testBatchPushEmpty() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 5)
        let emptyBatch: [TestMessage] = []
        
        await buffer.pushBatch(emptyBatch)
        
        let isEmpty = await buffer.isEmpty
        let count = await buffer.count
        
        if isEmpty && count == 0 {
            await testRunner.recordPass("testBatchPushEmpty")
        } else {
            await testRunner.recordFailure("testBatchPushEmpty", "Empty batch push failed")
        }
    }
    
    private func testBatchPushPartialFill() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 5)
        let batch = [TestMessage(id: 1), TestMessage(id: 2), TestMessage(id: 3)]
        
        await buffer.pushBatch(batch)
        
        let count = await buffer.count
        let isFull = await buffer.isFull
        let array = await buffer.toArray()
        
        if count == 3 && !isFull && array.count == 3 && array[0].id == 1 {
            await testRunner.recordPass("testBatchPushPartialFill")
        } else {
            await testRunner.recordFailure("testBatchPushPartialFill", "Partial batch push failed")
        }
    }
    
    private func testBatchPushOverfill() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 3)
        let largeBatch = (1...5).map { TestMessage(id: $0) }
        
        await buffer.pushBatch(largeBatch)
        
        let count = await buffer.count
        let isFull = await buffer.isFull
        let array = await buffer.toArray()
        
        // Should only push first 3 elements due to current implementation
        if count == 3 && isFull && array.count == 3 && array[0].id == 1 && array[2].id == 3 {
            await testRunner.recordPass("testBatchPushOverfill")
        } else {
            await testRunner.recordFailure("testBatchPushOverfill", "Overfill batch push failed: count:\(count), array:\(array.map(\.id))")
        }
    }
    
    private func testMixedOperations() async {
        let buffer = SafeCircularBuffer<TestMessage>(capacity: 4)
        
        // Mixed sequence of operations
        _ = await buffer.push(TestMessage(id: 1))
        _ = await buffer.push(TestMessage(id: 2))
        _ = await buffer.pop()
        _ = await buffer.push(TestMessage(id: 3))
        _ = await buffer.push(TestMessage(id: 4))
        _ = await buffer.push(TestMessage(id: 5)) // Should overwrite id:2
        
        let array = await buffer.toArray()
        
        if array.count == 4 && array[0].id == 3 && array[3].id == 5 {
            await testRunner.recordPass("testMixedOperations")
        } else {
            await testRunner.recordFailure("testMixedOperations", "Mixed operations failed: \(array.map(\.id))")
        }
    }
    
    
    // MARK: - Concurrent Access Tests
    actor ConcurrentTests: Sendable {
        private let testRunner: TestRunner
        private let logger = Logger(subsystem: "CircularBufferTests", category: "ConcurrentTests")
        
        init(testRunner: TestRunner) {
            self.testRunner = testRunner
        }
        
        func runAllTests() async {
            logger.notice("⚡ Starting Concurrent Access Tests")
            
            
            // TODO: -
            await testConcurrentPushPop()
            await testConcurrentBatchOperations()
            await testConcurrentReaders()
            await testHighContentionScenario()
        }
        
        //}
        
        
        
        
        private func testConcurrentPushPop() async {
            let buffer = SafeCircularBuffer<TestMessage>(capacity: 10)
            
            await withTaskGroup(of: Void.self) { group in
                // Producer task
                group.addTask {
                    for i in 1...20 {
                        _ = await buffer.push(TestMessage(id: i))
                        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
                    }
                }
                
                // Consumer task
                group.addTask {
                    var consumedCount = 0
                    for _ in 1...20 {
                        while await buffer.isEmpty {
                            try? await Task.sleep(nanoseconds: 1_000_000)
                        }
                        if await buffer.pop() != nil {
                            consumedCount += 1
                        }
                    }
                }
            }
            
            let finalCount = await buffer.count
            //let isEmpty = await buffer.isEmpty
            _ = await buffer.isEmpty
            
            // Buffer should be empty or nearly empty after balanced push/pop
            if finalCount <= 1 {
                await testRunner.recordPass("testConcurrentPushPop")
            } else {
                await testRunner.recordFailure("testConcurrentPushPop", "Concurrent push/pop failed: final count \(finalCount)")
            }
        }
        
        
        
        private func testConcurrentBatchOperations() async {
            let buffer = SafeCircularBuffer<TestMessage>(capacity: 20)
            
            await withTaskGroup(of: Void.self) { group in
                // Multiple batch pushers
                for batchId in 1...3 {
                    group.addTask {
                        let batch = (1...5).map { TestMessage(id: batchId * 100 + $0) }
                        await buffer.pushBatch(batch)
                    }
                }
            }
            
            let finalCount = await buffer.count
            let array = await buffer.toArray()
            
            if finalCount == 15 && array.count == 15 {
                await testRunner.recordPass("testConcurrentBatchOperations")
            } else {
                await testRunner.recordFailure("testConcurrentBatchOperations", "Concurrent batch operations failed: count \(finalCount)")
            }
        }
        
        private func testConcurrentReaders() async {
            let buffer = SafeCircularBuffer<TestMessage>(capacity: 5)
            
            // Fill buffer first
            for i in 1...5 {
                _ = await buffer.push(TestMessage(id: i))
            }
            
            var readResults: [TestMessage?] = []
            
            await withTaskGroup(of: TestMessage?.self) { group in
                // Multiple concurrent readers
                for _ in 1...3 {
                    group.addTask {
                        await buffer.peek()
                    }
                }
                
                for await result in group {
                    readResults.append(result)
                }
            }
            
            let allSame = readResults.allSatisfy { $0?.id == readResults.first??.id }
            let count = await buffer.count
            
            if allSame && count == 5 && readResults.count == 3 {
                await testRunner.recordPass("testConcurrentReaders")
            } else {
                await testRunner.recordFailure("testConcurrentReaders", "Concurrent readers failed")
            }
        }
        
        private func testHighContentionScenario() async {
            let buffer = SafeCircularBuffer<TestMessage>(capacity: 5)
            let operationCount = 50
            
            await withTaskGroup(of: Void.self) { group in
                // High contention: many tasks doing random operations
                for taskId in 1...10 {
                    group.addTask {
                        for i in 1...operationCount {
                            let operation = i % 4
                            switch operation {
                            case 0:
                                _ = await buffer.push(TestMessage(id: taskId * 1000 + i))
                            case 1:
                                _ = await buffer.pop()
                            case 2:
                                _ = await buffer.peek()
                            case 3:
                                _ = await buffer.toArray()
                            default:
                                break
                            }
                        }
                    }
                }
            }
            
            // If we get here without crashes, the test passes
            let finalCount = await buffer.count
            
            if finalCount >= 0 && finalCount <= 5 {
                await testRunner.recordPass("testHighContentionScenario")
            } else {
                await testRunner.recordFailure("testHighContentionScenario", "High contention test failed: invalid count \(finalCount)")
            }
        }
    }
    
    
    
    
    
    // MARK: - Test Execution
    //@main
    struct CircularBufferTestSuite {
        static func main() async {
            
            let logger = Logger(subsystem: "CircularBufferTests", category: "Main")
            
            let testRunner = TestRunner()
            
            
            let basicTests = BasicTests(testRunner: testRunner)
            let edgeTests = EdgeCaseTests(testRunner: testRunner)
            let concurrentTests = ConcurrentTests(testRunner: testRunner)
            
            await basicTests.runAllTests()
            await edgeTests.runAllTests()
            await concurrentTests.runAllTests()
            
            await testRunner.printSummary()
            
            
            
            logger.notice("✨ Test Suite Complete")
        }
    }
    
    
} //end actor
