import XCTest

@testable import Starknet

let invokeTransactionV1 = """
{"sender_address":"0x123","calldata":["0x1","0x2"],"max_fee":"0x859","signature":["0x1","0x2"],"nonce":"0x0","type":"INVOKE","version":"0x1","transaction_hash":"0x111"}
"""

let invokeTransactionV0 = """
{"contract_address":"0x123","calldata":["0x1","0x2"],"entry_point_selector":"0x123","max_fee":"0x859","signature":["0x1","0x2"],"type":"INVOKE","version":"0x0","transaction_hash":"0x111"}
"""

let declareTransactinoV0 = """
{"class_hash":"0x123","sender_address":"0x123","max_fee":"0x859","signature":["0x1","0x2"],"type":"DECLARE","version":"0x0","transaction_hash":"0x111"}
"""

let declareTransactionV1 = """
{"class_hash":"0x123","sender_address":"0x123","max_fee":"0x859","signature":["0x1","0x2"],"nonce":"0x0","type":"DECLARE","version":"0x1","transaction_hash":"0x111"}
"""

let declareTransactionV2 = """
{"class_hash":"0x123","compiled_class_hash":"0x123","sender_address":"0x123","max_fee":"0x859","signature":["0x1","0x2"],"nonce":"0x0","type":"DECLARE","version":"0x2","transaction_hash":"0x111"}
"""

let deployTransaction = """
{"class_hash":"0x123","constructor_calldata":["0x1","0x2"],"contract_address_salt":"0x123","type":"DEPLOY","version":"0x0","transaction_hash":"0x111"}
"""

let deployAccountTransaction = """
{"class_hash":"0x123","constructor_calldata":["0x1","0x2"],"contract_address_salt":"0x123","type":"DEPLOY_ACCOUNT","version":"0x1","max_fee":"0x123","nonce":"0x0","signature":["0x1","0x2"],"transaction_hash":"0x111"}
"""

let l1HandlerTransaction = """
{"contract_address":"0x123","calldata":["0x1","0x2"],"entry_point_selector":"0x123","nonce":"0x123","type":"L1_HANDLER","version":"0x0","transaction_hash":"0x111"}
"""

final class TransactionTests: XCTestCase {
    func testInvokeTransactionEncoding() throws {
        let invoke = StarknetSequencerInvokeTransaction(senderAddress: "0x123", calldata: [1, 2], signature: [1, 2], maxFee: "0x859", nonce: 0)

        let encoder = JSONEncoder()

        let encoded = try encoder.encode(invoke)
        let encodedString = String(data: encoded, encoding: .utf8)!

        let pairs = [
            "\"sender_address\":\"0x123\"",
            "\"calldata\":[\"0x1\",\"0x2\"]",
            "\"max_fee\":\"0x859\"",
            "\"signature\":[\"0x1\",\"0x2\"]",
            "\"nonce\":\"0x0\"",
            "\"type\":\"invoke\"",
            "\"version\":\"0x1\"",
        ]

        pairs.forEach {
            XCTAssertTrue(encodedString.localizedStandardContains($0))
        }
    }

    func testTransactionWrapperDecoding() throws {
        let cases: [(String, StarknetTransactionType, Felt)] = [
            (invokeTransactionV1, .invoke, 1),
            (invokeTransactionV0, .invoke, 0),
            (declareTransactinoV0, .declare, 0),
            (declareTransactionV1, .declare, 1),
            (declareTransactionV2, .declare, 2),
            (deployTransaction, .deploy, 0),
            (deployAccountTransaction, .deployAccount, 1),
            (l1HandlerTransaction, .l1Handler, 0),
        ]

        try cases.forEach { (string: String, type: StarknetTransactionType, version: Felt) in
            let data = string.data(using: .utf8)!

            let decoder = JSONDecoder()

            var result: TransactionWrapper?

            XCTAssertNoThrow(result = try decoder.decode(TransactionWrapper.self, from: data))
            XCTAssertTrue(result?.transaction.type == type && result?.transaction.version == version)
        }
    }

    func testSequencerInvokeTransactionDecoding() throws {
        let decoder = JSONDecoder()

        let json = """
        {"sender_address":"0x123","calldata":["0x1","0x2"],"max_fee":"0x859","signature":["0x1","0x2"],"nonce":"0x0","type":"INVOKE","version":"0x1"}
        """.data(using: .utf8)!

        let json2 = """
        {"sender_address":"0x123","calldata":["0x1","0x2"],"max_fee":"0x859","signature":["0x1","0x2"],"nonce":"0x0","type":"DEPLOY","version":"0x1"}
        """.data(using: .utf8)!

        XCTAssertNoThrow(try decoder.decode(StarknetSequencerInvokeTransaction.self, from: json))

        XCTAssertThrowsError(try decoder.decode(StarknetSequencerInvokeTransaction.self, from: json2))
    }
}
