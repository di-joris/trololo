import Testing
import Foundation
@testable import trololo

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

@Suite("DotEnv parser")
struct DotEnvTests {

    private func withTempEnvFile(
        contents: String,
        perform: (String) throws -> Void
    ) throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let filePath = dir.appendingPathComponent(".env").path
        try contents.write(toFile: filePath, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(atPath: dir.path)
        }
        try perform(filePath)
    }

    /// Clears an environment variable, restoring the previous value when done.
    private func withCleanEnv(key: String, perform: () throws -> Void) rethrows {
        let previous = ProcessInfo.processInfo.environment[key]
        unsetenv(key)
        defer {
            if let previous {
                setenv(key, previous, 1)
            } else {
                unsetenv(key)
            }
        }
        try perform()
    }

    @Test("Parses simple KEY=VALUE pairs")
    func parsesSimpleKeyValue() throws {
        try withCleanEnv(key: "TEST_DOTENV_A") {
            try withTempEnvFile(contents: "TEST_DOTENV_A=hello") { path in
                try DotEnv.load(path: path)
                let value = String(cString: getenv("TEST_DOTENV_A"))
                #expect(value == "hello")
                unsetenv("TEST_DOTENV_A")
            }
        }
    }

    @Test("Skips comments and blank lines")
    func skipsCommentsAndBlankLines() throws {
        let contents = """
        # This is a comment
        
        TEST_DOTENV_B=world
        
        # Another comment
        """
        try withCleanEnv(key: "TEST_DOTENV_B") {
            try withTempEnvFile(contents: contents) { path in
                try DotEnv.load(path: path)
                let value = String(cString: getenv("TEST_DOTENV_B"))
                #expect(value == "world")
                unsetenv("TEST_DOTENV_B")
            }
        }
    }

    @Test("Strips double quotes from values")
    func stripsDoubleQuotes() throws {
        try withCleanEnv(key: "TEST_DOTENV_C") {
            try withTempEnvFile(contents: "TEST_DOTENV_C=\"quoted value\"") { path in
                try DotEnv.load(path: path)
                let value = String(cString: getenv("TEST_DOTENV_C"))
                #expect(value == "quoted value")
                unsetenv("TEST_DOTENV_C")
            }
        }
    }

    @Test("Strips single quotes from values")
    func stripsSingleQuotes() throws {
        try withCleanEnv(key: "TEST_DOTENV_D") {
            try withTempEnvFile(contents: "TEST_DOTENV_D='single quoted'") { path in
                try DotEnv.load(path: path)
                let value = String(cString: getenv("TEST_DOTENV_D"))
                #expect(value == "single quoted")
                unsetenv("TEST_DOTENV_D")
            }
        }
    }

    @Test("Strips inline comments from unquoted values")
    func stripsInlineComments() throws {
        try withCleanEnv(key: "TEST_DOTENV_E") {
            try withTempEnvFile(contents: "TEST_DOTENV_E=value # this is a comment") { path in
                try DotEnv.load(path: path)
                let value = String(cString: getenv("TEST_DOTENV_E"))
                #expect(value == "value")
                unsetenv("TEST_DOTENV_E")
            }
        }
    }

    @Test("Does not overwrite existing environment variables")
    func doesNotOverwriteExisting() throws {
        let key = "TEST_DOTENV_F"
        setenv(key, "original", 1)
        defer { unsetenv(key) }

        try withTempEnvFile(contents: "\(key)=overwritten") { path in
            try DotEnv.load(path: path)
            let value = String(cString: getenv(key))
            #expect(value == "original")
        }
    }

    @Test("Silently ignores missing files")
    func ignoresMissingFiles() throws {
        try DotEnv.load(path: "/nonexistent/path/.env")
    }

    @Test("Trims whitespace around keys and values")
    func trimsWhitespace() throws {
        try withCleanEnv(key: "TEST_DOTENV_G") {
            try withTempEnvFile(contents: "  TEST_DOTENV_G  =  spaced  ") { path in
                try DotEnv.load(path: path)
                let value = String(cString: getenv("TEST_DOTENV_G"))
                #expect(value == "spaced")
                unsetenv("TEST_DOTENV_G")
            }
        }
    }

    @Test("Handles values containing equals signs")
    func valuesWithEqualsSigns() throws {
        try withCleanEnv(key: "TEST_DOTENV_H") {
            try withTempEnvFile(contents: "TEST_DOTENV_H=abc=def=ghi") { path in
                try DotEnv.load(path: path)
                let value = String(cString: getenv("TEST_DOTENV_H"))
                #expect(value == "abc=def=ghi")
                unsetenv("TEST_DOTENV_H")
            }
        }
    }

    @Test("Parses multiple key-value pairs")
    func parsesMultiplePairs() throws {
        let contents = """
        TEST_DOTENV_I=first
        TEST_DOTENV_J=second
        """
        try withCleanEnv(key: "TEST_DOTENV_I") {
            try withCleanEnv(key: "TEST_DOTENV_J") {
                try withTempEnvFile(contents: contents) { path in
                    try DotEnv.load(path: path)
                    #expect(String(cString: getenv("TEST_DOTENV_I")) == "first")
                    #expect(String(cString: getenv("TEST_DOTENV_J")) == "second")
                    unsetenv("TEST_DOTENV_I")
                    unsetenv("TEST_DOTENV_J")
                }
            }
        }
    }
}
