import HTTP
import Vapor

let VERSION = "0.1.0"
setupClient()

let config = try Config(prioritized: [.directory(root: workingDirectory + "Config/")])

guard let token = config["bot-config", "token"]?.string else { throw BotError.missingConfig }

let rtmResponse = try BasicClient.loadRealtimeApi(token: token)
guard let webSocketURL = rtmResponse.data["url"]?.string else { throw BotError.invalidResponse }

try WebSocket.connect(to: webSocketURL) { ws in
    print("Connected to \(webSocketURL)")

    ws.onText = { ws, text in
        print("[event] - \(text)")

        let event = try JSON(bytes: text.utf8.array)
        guard
            let channel = event["channel"]?.string,
            let text = event["text"]?.string
            else { return }

        if text.hasPrefix("hello") {
            let response = SlackMessage(to: channel, text: "Hi there 👋")
            try ws.send(response)
        } else if text.hasPrefix("version") {
            let response = SlackMessage(to: channel, text: "Current Version: \(VERSION)")
            try ws.send(response)
        }
    }

    ws.onClose = { ws, _, _, _ in
        print("\n[CLOSED]\n")
    }
}
