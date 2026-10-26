import Foundation
import Testing
@testable import МатериализацияУзлов

@Suite struct ПрофильСинхронизации {
    @Test func короткийРазмерныйПрофиль() throws {
        var измерения: [String] = []

        for count in [1, 64, 256, 512] {
            var samples: [UInt64] = []
            for _ in 0..<3 {
                let start = DispatchTime.now().uptimeNanoseconds
                let inventory = образецИнвентаря(числоУзлов: count)
                let plan = try ПланировщикСинхронизации.построить(inventory)
                let bytes = try plan.байты()
                let elapsed = DispatchTime.now().uptimeNanoseconds - start
                #expect(!bytes.isEmpty)
                samples.append(elapsed)
            }
            let median = samples.sorted()[samples.count / 2]
            измерения.append("\(count)=\(median)")
        }

        print("FUM_SYNC_PROFILE_MEDIAN_NS " + измерения.joined(separator: " "))
    }
}
