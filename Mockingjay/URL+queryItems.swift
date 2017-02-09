//
//  URL+queryItems.swift
//  Mockingjay
//
//  Created by Ivan Cheung on 2017-02-09.
//  Copyright © 2017 Cocode. All rights reserved.
//

extension URL {
  var queryItems: [String: String]? {
    return URLComponents(url: self, resolvingAgainstBaseURL: false)?
      .queryItems?
      .flatMap { $0.dictionaryRepresentation }
      .reduce([:], +)
  }
}

extension URLQueryItem {
  var dictionaryRepresentation: [String: String]? {
    if let value = value {
      return [name: value]
    }
    return nil
  }
}

func +<Key, Value> (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
  var result = lhs
  rhs.forEach{ result[$0] = $1 }
  return result
}
