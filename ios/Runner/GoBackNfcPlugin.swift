import CoreNFC
import Flutter

/// Handles NFC NDEF reading via NFCNDEFReaderSession.
/// Only requires the NDEF entitlement — no TAG entitlement needed.
@available(iOS 11.0, *)
class GoBackNfcPlugin: NSObject, NFCNDEFReaderSessionDelegate {

  private var session: NFCNDEFReaderSession?
  private var pendingResult: FlutterResult?

  // MARK: - Public

  func startReading(alertMessage: String, result: @escaping FlutterResult) {
    pendingResult = result
    session = NFCNDEFReaderSession(
      delegate: self,
      queue: DispatchQueue.main,
      invalidateAfterFirstRead: true
    )
    session?.alertMessage = alertMessage
    session?.begin()
  }

  // MARK: - NFCNDEFReaderSessionDelegate

  func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}

  func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    for message in messages {
      for record in message.records {
        if let text = parseTextRecord(record) {
          resolve(["type": "success", "text": text])
          return
        }
      }
    }
    session.invalidate(errorMessage: "Not a GoBack tag")
    resolve(["type": "invalid"])
  }

  func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
    guard pendingResult != nil else { return } // already resolved in didDetectNDEFs
    let code = (error as? NFCReaderError)?.code
    if code == .readerSessionInvalidationErrorFirstNDEFTagRead ||
       code == .readerSessionInvalidationErrorUserCanceled {
      resolve(["type": "cancelled"])
    } else {
      resolve(["type": "error", "message": error.localizedDescription])
    }
  }

  // MARK: - Helpers

  private func resolve(_ value: Any) {
    pendingResult?(value)
    pendingResult = nil
  }

  /// Parses an NFC Well-Known Text record and returns the UTF-8 string.
  private func parseTextRecord(_ record: NFCNDEFPayload) -> String? {
    guard record.typeNameFormat == .nfcWellKnown,
          let typeStr = String(data: record.type, encoding: .utf8),
          typeStr == "T" else { return nil }

    let payload = record.payload
    guard !payload.isEmpty else { return nil }

    let langLength = Int(payload[0] & 0x3F)
    guard payload.count > 1 + langLength else { return nil }

    let textData = payload.subdata(in: (1 + langLength)..<payload.count)
    return String(data: textData, encoding: .utf8)
  }
}
