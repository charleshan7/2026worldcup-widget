import Foundation
import Network

// 极小的 localhost HTTP 服务：返回「当前外观 + 最新赛况」(LocalPayload 的 JSON)。
// 桌面组件被沙盒隔离、读不到 App 的文件/偏好，但有 network.client，可访问 localhost；
// 菜单栏 App（network.server）在此监听，组件取数时一次拿全外观与比分——既能让菜单栏控制组件，
// 又因走本地服务而比远程拉取快得多。
final class ThemeServer {
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "worldcup.themeserver")
    private var payload = Data(#"{"theme":"system","snapshot":{"live":[],"results":[],"upcoming":[],"updated":0}}"#.utf8)

    func start() {
        guard listener == nil else { return }
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        params.requiredLocalEndpoint = .hostPort(host: "127.0.0.1",
                                                 port: NWEndpoint.Port(rawValue: ThemeServerInfo.port)!)
        guard let l = try? NWListener(using: params) else { return }
        listener = l
        l.newConnectionHandler = { [weak self] conn in
            conn.start(queue: self?.queue ?? .global())
            self?.respond(on: conn)
        }
        l.start(queue: queue)
    }

    // 由 App 在外观或赛况变化时调用，更新对外供给的数据。
    func setPayload(_ data: Data) {
        queue.async { self.payload = data }
    }

    private func respond(on conn: NWConnection) {
        // 读掉请求（内容无所谓），回固定 JSON 后关闭连接。
        conn.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] _, _, _, _ in
            let body = self?.payload ?? Data("{}".utf8)
            let header = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n"
            var out = Data(header.utf8)
            out.append(body)
            conn.send(content: out, completion: .contentProcessed { _ in conn.cancel() })
        }
    }
}
