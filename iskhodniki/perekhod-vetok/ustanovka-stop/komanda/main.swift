import Foundation
import Darwin
import УстановкаStop
let аргументы = Array(CommandLine.arguments.dropFirst())
if аргументы.first == "--поддерживать-текущий" {
    exit(await УстановщикStop.поддерживатьТекущий(Array(аргументы.dropFirst())))
} else {
    exit(УстановщикStop.команда(аргументы))
}
