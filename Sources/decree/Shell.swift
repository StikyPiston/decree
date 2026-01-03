import Foundation

@discardableResult
func runShell(_ command: String) throws -> Int32 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments     = ["-c", command]

    let stdoutPipe         = Pipe()
    let stderrPipe         = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError  = stderrPipe

    try process.run()
    process.waitUntilExit()

    let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

    if process.terminationStatus != 0 {
        print(stdout)
        print(stderr)
    }

    return process.terminationStatus
}
