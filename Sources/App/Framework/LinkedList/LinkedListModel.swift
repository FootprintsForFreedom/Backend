//
//  LinkedListModel.swift
//  
//
//  Created by niklhut on 13.02.22.
//

import Vapor
import Fluent

protocol LinkedListModel: LinkedList, DatabaseModelInterface where NodeObject: NodeModel {
    var currentProperty: OptionalChildProperty<Self, NodeObject> { get }
    var lastProperty: OptionalChildProperty<Self, NodeObject> { get }
    
    func load(on db: Database) async throws
    
    func beforeAppend(_ node: NodeObject, on req: Request) async throws
    func append(_ node: NodeObject, on req: Request) async throws -> NodeObject
    func append(_ node: NodeObject, on db: Database) async throws -> NodeObject
    func afterAppend(_ node: NodeObject, on req: Request) async throws
    
    func beforeRemove(_ node: NodeObject, on req: Request) async throws
    func remove(_ node: NodeObject, on req: Request) async throws -> Element
    func remove(_ node: NodeObject, on db: Database) async throws -> Element
    func afterRemove(_ node: NodeObject, on req: Request) async throws
    
    func beforeRemoveAll(on req: Request) async throws
    func removeAll(on req: Request) async throws
    func removeAll(on db: Database) async throws
    func afterRemoveAll(on req: Request) async throws
    
    func beforeIncrementCurrent(on req: Request) async throws
    func incrementCurrent(on req: Request) async throws
    func incrementCurrent(on db: Database) async throws
    func afterIncrementCurrent(on req: Request) async throws
    
    func beforeSwap(_ node1: inout NodeObject, _ node2: inout NodeObject, on req: Request) async throws
    func swap(_ node1: inout NodeObject, _ node2: inout NodeObject, on req: Request) async throws
    func swap(_ node1: inout NodeObject, _ node2: inout NodeObject, on db: Database) async throws
    func afterSwap(_ node1: inout NodeObject, _ node2: inout NodeObject, on req: Request) async throws
}

extension LinkedListModel {
    var isEmpty: Bool {
        current == nil
    }
    
    // TODO: perform in transactions so nothing is changed if one fails
    func load(on db: Database) async throws {
        try await currentProperty.load(on: db)
        try await lastProperty.load(on: db)
    }
    
    // MARK: - append
    
    func beforeAppend(_ node: NodeObject, on req: Request) async throws { }
    func afterAppend(_ node: NodeObject, on req: Request) async throws { }
    func append(_ node: NodeObject, on req: Request) async throws -> NodeObject {
        try await beforeAppend(node, on: req)
        let node = try await append(node, on: req.db)
        try await afterAppend(node, on: req)
        return node
    }
    
    func append(_ node: NodeObject, on db: Database) async throws -> NodeObject {
        /// load last object in list to see if list is empty
        try await self.lastProperty.load(on: db)
        /// if list is not empty
        if let lastNode = last {
            /// unlink old last node
            lastNode.lastObjectInListProperty.id = nil
            try await lastNode.update(on: db)
            /// set old last node to be previous node of new node
            node.previousProperty.id = try lastNode.requireID()
        } else {
            /// if the list is empty the new object is also the current object in the list
            node.currentObjectInListProperty.id = try self.requireID()
        }
        /// set the new node to be the last node in the list
        node.lastObjectInListProperty.id = try self.requireID()
        /// Create and  the node on the db
        try await node.create(on: db)
        /// Reload the linked list model to reflect the changes
        try await self.load(on: db)
        /// return the newly created node
        return node
    }
    
    // MARK: - remove
    
    func beforeRemove(_ node: NodeObject, on req: Request) async throws { }
    func afterRemove(_ node: NodeObject, on req: Request) async throws { }
    @discardableResult
    func remove(_ node: NodeObject, on req: Request) async throws -> Element {
        try await beforeRemove(node, on: req)
        let removedElement = try await remove(node, on: req.db)
        try await afterRemove(node, on: req)
        return removedElement
    }
    
    @discardableResult
    func remove(_ node: NodeObject, on db: Database) async throws -> Element {
        /// load the node
        try await node.loadPreviousAndNext(on: db)
        /// if the node has a next node
        /// if the node is **not** the last node
        if let nextNode = node.next {
            if let previousNode = node.previous {
                /// if the node also has a previous node link the two nodes
                nextNode.previousProperty.id = try previousNode.requireID()
            } else {
                /// if the node has no previous node / if the node is the first node
                /// set the next nodes previous property to nil
                nextNode.previousProperty.id = nil
            }
        }
        /// load the linked list model
        try await self.load(on: db)
        /// if the node to be removed is the current node
        if node == current {
            if let previousNode = node.previous {
                /// if the node to be removed has previous node set it to be the new current node
                previousNode.currentObjectInListProperty.id = try self.requireID()
            } else if let nextNode = node.next {
                /// if the node has no previous node / if the node is the first node
                /// set the possible next node as current object or current object will be nil
                nextNode.currentObjectInListProperty.id = try self.requireID()
            }
        }
        /// if the node is the last node
        if node == last {
            /// set the possibly available previous node as last node or the list is empty and therefore the last object nil
            node.previous?.lastObjectInListProperty.id = try self.requireID()
        }
        /// remove the node on the db
        try await node.delete(on: db)
        /// save the updated links on previous and next node
        try await node.previous?.update(on: db)
        try await node.next?.update(on: db)
        /// reload the linked list model to reflect the changes
        try await self.load(on: db)
        /// return the value of the deleted node
        return node.value
    }
    
    // MARK: - remove all
    
    func beforeRemoveAll(on req: Request) async throws { }
    func afterRemoveAll(on req: Request) async throws { }
    func removeAll(on req: Request) async throws {
        try await beforeRemoveAll(on: req)
        try await removeAll(on: req.db)
        try await afterRemoveAll(on: req)
    }
    
    func removeAll(on db: Database) async throws {
        /// load the last node of the list
        try await self.lastProperty.load(on: db)
        /// set the item to delete to the last node of the list
        var nodeToDelete = last
        /// while there is an node to delete
        while nodeToDelete != nil {
            /// load the previous node of the node to delete
            try await nodeToDelete!.previousProperty.load(on: db)
            /// set the next node to be deleted to the previous node of the one that will now be deleted
            let nextNodeToDelete = nodeToDelete!.previous
            /// delete the node on the db
            try await nodeToDelete!.delete(on: db)
            /// set the node to be deleted to the one before
            nodeToDelete = nextNodeToDelete
        }
    }
    
    // MARK: - increment current
    
    func beforeIncrementCurrent(on req: Request) async throws { }
    func afterIncrementCurrent(on req: Request) async throws { }
    func incrementCurrent(on req: Request) async throws {
        try await beforeIncrementCurrent(on: req)
        try await incrementCurrent(on: req.db)
        try await afterIncrementCurrent(on: req)
    }
    
    func incrementCurrent(on db: Database) async throws {
        /// load the current property of the list
        try await self.currentProperty.load(on: db)
        /// load the next node after the current node
        try await self.current?.nextProperty.load(on: db)
        /// confirm there actually is a next node
        guard let nextNode = current?.next else {
            /// otherwise abort and throw error
            throw LinkedListError.noNextValue
        }
        /// set the current node to no longer be the current node
        current?.currentObjectInListProperty.id = nil
        /// set the next node to be the current node
        nextNode.currentObjectInListProperty.id = try self.requireID()
        // save the changes on the db
        try await current?.update(on: db)
        try await nextNode.update(on: db)
        /// reload the linked list model to reflect the changes
        try await self.load(on: db)
    }
    
    // MARK: - swap
    
    func beforeSwap(_ node1: inout NodeObject, _ node2: inout NodeObject, on req: Request) async throws { }
    func afterSwap(_ node1: inout NodeObject, _ node2: inout NodeObject, on req: Request) async throws { }
    func swap(_ node1: inout NodeObject, _ node2: inout NodeObject, on req: Request) async throws {
        try await beforeSwap(&node1, &node2, on: req)
        try await swap(&node1, &node2, on: req.db)
        try await afterSwap(&node1, &node2, on: req)
    }
    
    func swap(_ node1: inout NodeObject, _ node2: inout NodeObject, on db: Database) async throws {
        /// if the nodes to be swapped are the same return since they don't need to be swapped
        if node1 == node2 {
            return
        }
        /// load the list
        try await self.load(on: db)
        if node1 == current {
            /// if node1 is the current node
            /// make it no longer the current node and save the change on the db so there is no conflict
            node1.currentObjectInListProperty.id = nil
            try await node1.update(on: db)
            /// make node2 the current node
            node2.currentObjectInListProperty.id = try self.requireID()
        } else if node2 == current {
            /// else if node2 is the current node
            /// make it no longer the current node and save the change on the db so there is no conflict
            node2.currentObjectInListProperty.id = nil
            try await node2.update(on: db)
            /// make node1 the current node
            node1.currentObjectInListProperty.id = try self.requireID()
        }
        if node1 == last {
            /// if node1 is the last node
            /// make it no longer the last node and save the change on the db so there is no conflict
            node1.lastObjectInListProperty.id = nil
            try await node1.update(on: db)
            /// make node2 the last node
            node2.lastObjectInListProperty.id = try self.requireID()
        } else if node2 == last {
            /// else if node2 is the last node
            /// make it no longer the last node and save the change on the db so there is no conflict
            node2.lastObjectInListProperty.id = nil
            try await node2.update(on: db)
            /// make node1 the last node
            node1.lastObjectInListProperty.id = try self.requireID()
        }
        
        /// load the two nodes
        try await node1.loadPreviousAndNext(on: db)
        try await node2.loadPreviousAndNext(on: db)
        
        if node1.previous == node2 {
            /// save the id of the node before node2
            let node2PreviousId = node2.previousProperty.id
            /// set the node before node1 to nil so there is no conflict
            node2.previousProperty.id = nil
            /// save the changes on the db
            try await node2.update(on: db)
            /// set the node before node1 to the node previously before node1
            node1.previousProperty.id = node2PreviousId
            /// set the node before node2 to node1
            node2.previousProperty.id = try node1.requireID()
            /// set the node before the node after node1 to node2
            node1.next?.previousProperty.id = try node2.requireID()
            /// save the changes on the db
            try await node1.update(on: db)
            try await node1.next?.update(on: db)
            try await node2.update(on: db)
        } else if node2.previous == node1 {
            /// save the id of the node before node1
            let node1PreviousId = node1.previousProperty.id
            /// set the node before node1 to nil so there is no conflict
            node1.previousProperty.id = nil
            /// save the changes on the db
            try await node1.update(on: db)
            /// set the node before node2 to the node previously before node1
            node2.previousProperty.id = node1PreviousId
            /// set the node before node1 to node2
            node1.previousProperty.id = try node2.requireID()
            /// set the node before the node after node2 to node1
            node2.next?.previousProperty.id = try node1.requireID()
            /// save the changes on the db
            try await node2.update(on: db)
            try await node2.next?.update(on: db)
            try await node1.update(on: db)
        } else {
            /// save the id of the node before node1
            let node1PreviousId = node1.previousProperty.id
            /// set the new node before node1 to the node currently before node2
            node1.previousProperty.id = node2.previousProperty.id
            /// set the node before node2 to nil so there is no conflict
            node2.previousProperty.id = nil
            /// save the changes on the db
            try await node2.update(on: db)
            try await node1.update(on: db)
            /// set the new node before node2 to the node previously before node1
            node2.previousProperty.id = node1PreviousId
            /// save the changes on the db
            try await node2.update(on: db)
            
            /// set the node before the node after node1 to node2
            node1.next?.previousProperty.id = try node2.requireID()
            /// set the node before the node after node2 to nil so there is no conflict
            node2.next?.previousProperty.id = nil
            /// save the changes on the db
            try await node2.next?.update(on: db)
            try await node1.next?.update(on: db)
            /// set the node before the node after node2 to node1
            node2.next?.previousProperty.id = try node1.requireID()
            /// save the changes on the db
            try await node2.next?.update(on: db)
        }
        
        /// reload the linked list model to reflect the changes
        try await self.load(on: db)
    }
}
