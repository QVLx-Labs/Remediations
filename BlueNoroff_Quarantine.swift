// $t@$h
// BlueNoroff detection and quarantine. MacOS only
// !!!Warning: This script DOES affect your system. Puts suspicious files in jail.
import Foundation
import CryptoKit

class BlueNoroffRemediation {
  // Directories/files to scan are here
  let directoriesToScan = ["/Applications", "/Library"]
  let quarantineDirectory = "/Users/Shared/Quarantine/"
  var findings: [String] = []

  // All thanks to Malware Bazaar for these hashes. Help add to these as we learn more
  let maliciousHashes: Set<String> = [
    "60701bdae4b33de7c53e4a0708b7187f313730bd09c4c553847134f268160a73",
    "74896758c69b493ba78bb0f774b87cc8afc20ec5",
    "8d4c3091ce2448c130326c53547a8a45"
  ]

  // Domains are disarmed. Change before running
  let maliciousDomains: Set<String> = [
    "swissborg[.]blog"
  ]

  init() {
    createQuarantineDirectory()
  }

  // Quarantine is all about non-executable permissions. Be careful anyways
  private func createQuarantineDirectory() {
    let quarantineURL = URL(fileURLWithPath: quarantineDirectory)
    if !FileManager.default.fileExists(atPath: quarantineDirectory) {
      do {
        try FileManager.default.createDirectory(at: quarantineURL, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: quarantineDirectory)
      } catch {
        findings.append("Error creating quarantine directory: \(error)")
      }
    }
  }

  func scanForIoCs() {
    print("Scanning:")
    for directory in directoriesToScan {
      do {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: nil)
        for fileURL in fileURLs { checkFile(at: fileURL) }
      } catch {
        findings.append("Error scanning directory \(directory): \(error)")
      }
    }
  }

  // Check file for IoCs
  func checkFile(at url: URL) {
    if let fileHash = hashOfFile(at: url) {
      if maliciousHashes.contains(fileHash) { quarantineItem(itemPath: url.path) }
    }

    if let fileContent = try? String(contentsOf: url, encoding: .utf8) {
      for domain in maliciousDomains {
        if fileContent.contains(domain.replacingOccurrences(of: "[.]", with: ".")) {
          quarantineItem(itemPath: url.path)
          break
        }
      }
    }
  }

  // Generate hash
  func hashOfFile(at url: URL) -> String? {
    guard let inputStream = InputStream(url: url) else {
      findings.append("Failed to open file for hashing: \(url.path)")
      return nil
    }
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
    inputStream.open()
    defer {
      inputStream.close()
      buffer.deallocate()
    }
    var context = SHA256()
    while inputStream.hasBytesAvailable {
      let read = inputStream.read(buffer, maxLength: 1024)
      if read > 0 { context.update(data: Data(bytes: buffer, count: read)) }
    }
    let digest = context.finalize()
    return digest.compactMap { String(format: "%02x", $0) }.joined()
  }

  // Quarantine sketchy files and set as non-executable
  func quarantineItem(itemPath: String) {
    let fileName = URL(fileURLWithPath: itemPath).lastPathComponent
    let quarantinePath = quarantineDirectory + fileName + ".quarantine"
    do {
      try FileManager.default.moveItem(atPath: itemPath, toPath: quarantinePath)
      try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: quarantinePath)
      findings.append("Quarantined and set non-executable: \(itemPath)")
    } catch {
      findings.append("Error in quarantining item at \(itemPath): \(error)")
    }
  }

  func reportFindings() {
    if findings.isEmpty { findings.append("No BlueNoroff signatures detected") }
    print("Report:")
    for finding in findings { print(finding) }
  }

  func remediate() {
    print("Starting BlueNoroff remediation")
    scanForIoCs()
    reportFindings()
    print("Remediation complete")
  }
}

extension String {
  var lastPathComponent: String {
    return (self as NSString).lastPathComponent
  }
}

let remediation = BlueNoroffRemediation()
remediation.remediate()
