import Foundation
import SLIPS

@main
struct SLIPSCLI {
    static func main() {
        CLIPS.createEnvironment()
        CLIPS.commandLoop()
    }
}

