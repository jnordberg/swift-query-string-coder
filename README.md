# swift-query-string-coder

Standards compliant query string encoder & decoder for the `Codable` protocol.

```swift

struct MyQuery: Codable {
    let hello: String
    let tags: [String]
    let flag: Bool
}

let encoder = QueryStringEncoder()

let query = MyQuery(hello: "world™", tags: ["foo", "bar"], flag: true)

let result = try encoder.encode(query)

print(result) // hello=world&tags=foo&tags=bar&flag
```

TODO
 - [x] Encoder
 - [ ] Decoder

```

