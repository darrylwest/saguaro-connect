//
//  CaseInsensitiveDictionary.swift
//  Sandbox
//
//  Created by Daniel Duan on 4/21/15.
//  Copyright (c) 2015 JustHTTP. All rights reserved.
//

import Foundation

/// used for http header map
public struct CaseInsensitiveDictionary<Key: Hashable, Value>: CollectionType, DictionaryLiteralConvertible {
    private var _data:[Key: Value] = [:]
    private var _keyMap: [String: Key] = [:]
    
    typealias Element = (Key, Value)
    typealias Index = DictionaryIndex<Key, Value>
    public var startIndex: Index
    public var endIndex: Index
    
    public var count: Int {
        assert(_data.count == _keyMap.count, "internal keys out of sync")
        return _data.count
    }
    
    public var isEmpty: Bool {
        return _data.isEmpty
    }
    
    public init() {
        startIndex = _data.startIndex
        endIndex = _data.endIndex
    }
    
    public init(dictionaryLiteral elements: (Key, Value)...) {
        for (key, value) in elements {
            _keyMap["\(key)".lowercaseString] = key
            _data[key] = value
        }
        startIndex = _data.startIndex
        endIndex = _data.endIndex
    }
    
    public init(dictionary:[Key:Value]) {
        for (key, value) in dictionary {
            _keyMap["\(key)".lowercaseString] = key
            _data[key] = value
        }
        startIndex = _data.startIndex
        endIndex = _data.endIndex
    }
    
    public subscript (position: Index) -> Element {
        return _data[position]
    }
    
    public subscript (key: Key) -> Value? {
        get {
            if let realKey = _keyMap["\(key)".lowercaseString] {
                return _data[realKey]
            }
            return nil
        }
        set(newValue) {
            let lowerKey = "\(key)".lowercaseString
            if _keyMap[lowerKey] == nil {
                _keyMap[lowerKey] = key
            }
            _data[_keyMap[lowerKey]!] = newValue
        }
    }
    
    public func generate() -> DictionaryGenerator<Key, Value> {
        return _data.generate()
    }
    
    public var keys: LazyForwardCollection<MapCollectionView<[Key : Value], Key>> {
        return _data.keys
    }
    public var values: LazyForwardCollection<MapCollectionView<[Key : Value], Value>> {
        return _data.values
    }
}
