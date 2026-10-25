import Testing
import Darwin

@main enum ЗапускПроверокМанифеста {
    static func main() async {
        let код: CInt = await Testing.__swiftPMEntryPoint()
        exit(код)
    }
}
