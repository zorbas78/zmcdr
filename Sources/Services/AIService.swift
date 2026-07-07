import Foundation

enum AIProvider: String, CaseIterable, Codable {
    case ollama = "Ollama"
    case openai = "OpenAI-compatible"
}

struct AIService {

    struct Result {
        let raw: String
        let description: String
        let matchedNames: [String]
        let generationPrompt: String
        let safetyPrompt: String
        let safetyRaw: String
    }

    struct SafetyCheck {
        let safe: Bool
        let reason: String
    }

    enum Error: Swift.Error, LocalizedError {
        case notConfigured
        case httpError(Int)
        case noResponse
        case parseError(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Configure AI in Settings (Cmd+,)"
            case .httpError(let code): return "HTTP \(code)"
            case .noResponse: return "No response from service"
            case .parseError(let msg): return "Parse error: \(msg)"
            }
        }
    }

    private let systemPrompt = """
    You are a read-only file selection assistant.
    Current directory: <DIR>
    User request: <REQUEST>

    FULL FILE LIST (name, size, date):
    <FILELIST>

    Rules:
    - Return EXACTLY one JSON line: {"action":"select","description":"...","matches":["filename1","filename2"]}
    - Every filename in "matches" MUST be an exact copy of a filename from the file list above
    - Do NOT modify, create, or guess filenames — only return names that appear in the list
    - Only select files matching the user's criteria
    - Never suggest delete, move, rename, or execute commands
    - If no files match, return {"action":"select","description":"No matching files","matches":[]}
    """

    private let safetyPrompt = """
    Review this file selection operation for safety:
    Description: <DESC>
    Matched filenames: <NAMES>
    Is this safe and read-only? Does it avoid any destructive operations?
    Respond with EXACTLY: {"safe":true} or {"safe":false,"reason":"explain"}
    """

    func generateAction(
        prompt: String, fileList: String, provider: AIProvider,
        ollamaHost: String, ollamaModel: String,
        openaiHost: String, openaiModel: String, openaiKey: String,
        dir: String
    ) async throws -> Result {
        switch provider {
        case .ollama:
            return try await ollamaGenerate(prompt: prompt, fileList: fileList, host: ollamaHost, model: ollamaModel, dir: dir)
        case .openai:
            return try await openaiGenerate(prompt: prompt, fileList: fileList, endpoint: openaiHost, model: openaiModel, key: openaiKey, dir: dir)
        }
    }

    func safetyValidate(
        result: Result, provider: AIProvider,
        ollamaHost: String, ollamaModel: String,
        openaiHost: String, openaiModel: String, openaiKey: String
    ) async throws -> (SafetyCheck, Result) {
        let safety: SafetyCheck
        let sprompt: String
        let sraw: String
        switch provider {
        case .ollama:
            (safety, sprompt, sraw) = try await ollamaSafety(result: result, host: ollamaHost, model: ollamaModel)
        case .openai:
            (safety, sprompt, sraw) = try await openaiSafety(result: result, endpoint: openaiHost, model: openaiModel, key: openaiKey)
        }
        let updatedResult = Result(raw: result.raw, description: result.description,
                                   matchedNames: result.matchedNames,
                                   generationPrompt: result.generationPrompt,
                                   safetyPrompt: sprompt, safetyRaw: sraw)
        return (safety, updatedResult)
    }

    // MARK: - Ollama

    private func ollamaGenerate(prompt: String, fileList: String, host: String, model: String, dir: String) async throws -> Result {
        guard let url = URL(string: "\(host)/api/generate") else { throw Error.notConfigured }
        let msg = systemPrompt
            .replacingOccurrences(of: "<DIR>", with: dir)
            .replacingOccurrences(of: "<REQUEST>", with: prompt)
            .replacingOccurrences(of: "<FILELIST>", with: fileList)
        let raw = try await postOllama(url: url, model: model, prompt: msg)
        let result = try parseResult(raw)
        return Result(raw: result.raw, description: result.description,
                      matchedNames: result.matchedNames,
                      generationPrompt: msg, safetyPrompt: "", safetyRaw: "")
    }

    private func ollamaSafety(result: Result, host: String, model: String) async throws -> (SafetyCheck, String, String) {
        guard let url = URL(string: "\(host)/api/generate") else { throw Error.notConfigured }
        let msg = safetyPrompt
            .replacingOccurrences(of: "<DESC>", with: result.description)
            .replacingOccurrences(of: "<NAMES>", with: result.matchedNames.joined(separator: ", "))
        let raw = try await postOllama(url: url, model: model, prompt: msg)
        let safety = parseSafety(raw)
        return (safety, msg, raw)
    }

    private func postOllama(url: URL, model: String, prompt: String) async throws -> String {
        var req = URLRequest(url: url, timeoutInterval: 45)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["model": model, "prompt": prompt, "stream": false, "temperature": 0]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else { throw Error.httpError(code) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let response = json["response"] as? String
        else { throw Error.noResponse }
        return response
    }

    // MARK: - OpenAI-compatible

    private func openaiGenerate(prompt: String, fileList: String, endpoint: String, model: String, key: String, dir: String) async throws -> Result {
        guard let url = URL(string: "\(endpoint)/v1/chat/completions") else { throw Error.notConfigured }
        let sys = "You are a file selection assistant. Respond only with valid JSON."
        let msg = systemPrompt
            .replacingOccurrences(of: "<DIR>", with: dir)
            .replacingOccurrences(of: "<REQUEST>", with: prompt)
            .replacingOccurrences(of: "<FILELIST>", with: fileList)
        let raw = try await postOpenAI(url: url, model: model, key: key, messages: [
            ["role": "system", "content": sys],
            ["role": "user", "content": msg]
        ])
        let result = try parseResult(raw)
        let genPrompt = "[system] \(sys)\n\n[user] \(msg)"
        return Result(raw: result.raw, description: result.description,
                      matchedNames: result.matchedNames,
                      generationPrompt: genPrompt, safetyPrompt: "", safetyRaw: "")
    }

    private func openaiSafety(result: Result, endpoint: String, model: String, key: String) async throws -> (SafetyCheck, String, String) {
        guard let url = URL(string: "\(endpoint)/v1/chat/completions") else { throw Error.notConfigured }
        let msg = safetyPrompt
            .replacingOccurrences(of: "<DESC>", with: result.description)
            .replacingOccurrences(of: "<NAMES>", with: result.matchedNames.joined(separator: ", "))
        let raw = try await postOpenAI(url: url, model: model, key: key, messages: [
            ["role": "system", "content": "You are a safety validator. Respond only with valid JSON."],
            ["role": "user", "content": msg]
        ])
        let safety = parseSafety(raw)
        return (safety, msg, raw)
    }

    private func postOpenAI(url: URL, model: String, key: String, messages: [[String: String]]) async throws -> String {
        var req = URLRequest(url: url, timeoutInterval: 45)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = ["model": model, "messages": messages, "temperature": 0, "stream": false]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let err = json["error"] as? [String: Any],
               let msg = err["message"] as? String {
                throw Error.parseError(msg.prefix(200).description)
            }
            throw Error.httpError(code)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String
        else { throw Error.noResponse }
        return content
    }

    // MARK: - Parsing

    func testConnection(provider: AIProvider, ollamaHost: String, ollamaModel: String,
                        openaiHost: String, openaiModel: String, openaiKey: String) async throws -> String {
        switch provider {
        case .ollama:
            guard let url = URL(string: "\(ollamaHost)/api/tags") else { throw Error.notConfigured }
            let req = URLRequest(url: url, timeoutInterval: 10)
            let (_, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            guard code == 200 else { throw Error.httpError(code) }
            return "Ollama connected (\(ollamaModel.isEmpty ? "no model selected" : ollamaModel))"
        case .openai:
            guard let url = URL(string: "\(openaiHost)/v1/models") else { throw Error.notConfigured }
            var req = URLRequest(url: url, timeoutInterval: 10)
            req.setValue("Bearer \(openaiKey)", forHTTPHeaderField: "Authorization")
            let (data, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            guard code == 200 else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let err = json["error"] as? [String: Any],
                   let msg = err["message"] as? String {
                    throw Error.parseError(msg.prefix(200).description)
                }
                throw Error.httpError(code)
            }
            return "API connected (\(openaiModel.isEmpty ? "no model selected" : openaiModel))"
        }
    }

    // MARK: - Parsing

    private func parseResult(_ raw: String) throws -> Result {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let action = json["action"] as? String,
              action == "select" || action == "deselect",
              let description = json["description"] as? String
        else { throw Error.parseError(raw.prefix(200).description) }

        let matches = json["matches"] as? [String] ?? []
        return Result(raw: raw, description: description, matchedNames: matches,
                      generationPrompt: "", safetyPrompt: "", safetyRaw: "")
    }

    private func parseSafety(_ raw: String) -> SafetyCheck {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("\"safe\":true") {
            return SafetyCheck(safe: true, reason: "Approved")
        }
        if let data = trimmed.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let reason = json["reason"] as? String {
            return SafetyCheck(safe: false, reason: reason)
        }
        let fallback = !trimmed.contains("unsafe") && !trimmed.contains("dangerous")
        return SafetyCheck(safe: fallback, reason: trimmed.prefix(120).description)
    }
}
