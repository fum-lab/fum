import Foundation
import Darwin
import УстановкаStop
let arguments = Array(CommandLine.arguments.dropFirst())
if arguments.first == "--поддерживать-текущий" {
    exit(await УстановщикStop.поддерживатьТекущий(Array(arguments.dropFirst())))
} else {
    exit(УстановщикStop.команда(arguments))
}
