import Foundation

struct ISOInfo {
    let gameID: String?
    let volumeLabel: String
}

enum ISOReaderError: Error { case notISO9660 }

/// Lê o ISO9660 de uma imagem de PS2 e extrai o ID do jogo (ex.: SLUS_200.62) do SYSTEM.CNF.
enum ISOReader {
    private struct Layout { let sectorSize: UInt64; let dataOffset: UInt64 }
    // 2048 = ISO comum; 2352 = imagem "raw" (modo 1 ou modo 2)
    private static let layouts = [
        Layout(sectorSize: 2048, dataOffset: 0),
        Layout(sectorSize: 2352, dataOffset: 16),
        Layout(sectorSize: 2352, dataOffset: 24),
    ]

    static func read(url: URL) throws -> ISOInfo {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        for layout in layouts {
            let pvd = (try? readData(handle, layout, sector: 16, length: 2048)) ?? Data()
            if pvd.count == 2048, pvd[0] == 1,
               String(decoding: pvd.subdata(in: 1..<6), as: UTF8.self) == "CD001" {
                return try parse(handle, layout, pvd)
            }
        }
        throw ISOReaderError.notISO9660
    }

    private static func parse(_ h: FileHandle, _ layout: Layout, _ pvd: Data) throws -> ISOInfo {
        let label = String(decoding: pvd.subdata(in: 40..<72), as: UTF8.self)
            .trimmingCharacters(in: .whitespaces)
        let root = pvd.subdata(in: 156..<190)
        let rootLBA = UInt64(le32(root, 2))
        let rootLen = Int(le32(root, 10))
        let dir = try readData(h, layout, sector: rootLBA, length: min(rootLen, 1 << 20))

        var offset = 0
        while offset + 33 < dir.count {
            let recLen = Int(dir[offset])
            if recLen == 0 { offset = ((offset / 2048) + 1) * 2048; continue }
            let nameLen = Int(dir[offset + 32])
            guard offset + 33 + nameLen <= dir.count else { break }
            let name = String(decoding: dir.subdata(in: (offset + 33)..<(offset + 33 + nameLen)), as: UTF8.self)
            if name.uppercased().hasPrefix("SYSTEM.CNF") {
                let lba = UInt64(le32(dir, offset + 2))
                let len = min(Int(le32(dir, offset + 10)), 4096)
                let cnf = try readData(h, layout, sector: lba, length: len)
                let text = String(decoding: cnf, as: UTF8.self)
                return ISOInfo(gameID: extractID(text), volumeLabel: label)
            }
            offset += recLen
        }
        return ISOInfo(gameID: nil, volumeLabel: label)
    }

    private static func extractID(_ text: String) -> String? {
        guard let r = text.range(of: #"[A-Z]{4}[_-]\d{3}[._]\d{2}"#, options: .regularExpression) else { return nil }
        return String(text[r])
    }

    private static func readData(_ h: FileHandle, _ layout: Layout, sector: UInt64, length: Int) throws -> Data {
        var result = Data()
        var s = sector
        while result.count < length {
            try h.seek(toOffset: s * layout.sectorSize + layout.dataOffset)
            guard let chunk = try h.read(upToCount: 2048), !chunk.isEmpty else { break }
            result.append(chunk.prefix(length - result.count))
            s += 1
        }
        return result
    }

    private static func le32(_ d: Data, _ i: Int) -> UInt32 {
        UInt32(d[i]) | UInt32(d[i + 1]) << 8 | UInt32(d[i + 2]) << 16 | UInt32(d[i + 3]) << 24
    }
}
