module {
  func.func @mul_add(%left: tensor<4xf32>, %right: tensor<4xf32>, %bias: tensor<4xf32>) -> tensor<4xf32> {
    %product = stablehlo.multiply %left, %right : tensor<4xf32>
    %output = stablehlo.add %product, %bias : tensor<4xf32>
    return %output : tensor<4xf32>
  }
}
