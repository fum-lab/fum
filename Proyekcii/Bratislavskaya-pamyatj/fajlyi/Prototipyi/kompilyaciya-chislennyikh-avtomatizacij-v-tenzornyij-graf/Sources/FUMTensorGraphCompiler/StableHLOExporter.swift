public enum StableHLOExporter {
  public static func export(_ graph: TypedTensorGraph) -> String {
    let arguments = graph.inputs
      .map { "%\($0.name): \(render($0.type))" }
      .joined(separator: ", ")
    var lines = [
      "module {",
      "  func.func @\(graph.functionName)(\(arguments)) -> \(render(graph.output.type)) {",
    ]
    for operation in graph.operations {
      lines.append(
        "    %\(operation.result) = stablehlo.\(operation.operation.rawValue) "
          + "%\(operation.left), %\(operation.right) : \(render(operation.type))"
      )
    }
    lines.append("    return %\(graph.output.name) : \(render(graph.output.type))")
    lines.append("  }")
    lines.append("}")
    return lines.joined(separator: "\n") + "\n"
  }

  private static func render(_ type: TensorType) -> String {
    let dimensions = type.shape.map(String.init).joined(separator: "x")
    return "tensor<\(dimensions)x\(type.element.rawValue)>"
  }
}
