import Foundation
import SLIPS

@main
struct SLIPSCLI {
    static func main() {
        SLIPS.createEnvironment()
        SLIPS.commandLoop()
    }
}

