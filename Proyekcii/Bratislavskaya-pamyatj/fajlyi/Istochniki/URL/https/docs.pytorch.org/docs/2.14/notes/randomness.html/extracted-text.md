# Извлечённый текст

Источник: <https://docs.pytorch.org/docs/2.14/notes/randomness.html>

## Содержимое

Reproducibility — PyTorch 2.14 documentation
Skip to main content
Back to top
Ctrl + K
Install PyTorch
User Guide
PyTorch Main Components
torch.compiler
torch.export
Developer Notes
Accelerator Integration
Reference API
torch
torch.nn
torch.nn.functional
torch.Tensor
Tensor Attributes
Tensor Views
Automatic Mixed Precision package - torch.amp
Automatic differentiation package - torch.autograd
torch.library
torch.accelerator
torch.cpu
torch.cuda
Understanding CUDA Memory Usage
torch.mps
torch.xpu
torch.mtia
torch.mtia.memory
torch.mtia.mtia_graph
Meta device
torch.backends
torch.export
Distributed communication package - torch.distributed
torch.distributed.tensor
Generic Join Context Manager
Torch Distributed Elastic
FullyShardedDataParallel
torch.distributed.fsdp.fully_shard
Tensor Parallelism - torch.distributed.tensor.parallel
Distributed Optimizers
Pipeline Parallelism
PyTorch Symmetric Memory
Distributed Checkpoint - torch.distributed.checkpoint
Probability distributions - torch.distributions
torch.compiler API reference
torch.fft
torch.func
torch.futures
torch.fx
torch.fx.experimental
torch.hub
torch.linalg
torch.monitor
torch.signal
torch.special
torch.overrides
torch.nativert
torch.package
torch.profiler
torch.nn.init
torch.nn.attention
torch.onnx
torch.optim
Complex Numbers
DDP Communication Hooks
Quantization
Distributed RPC Framework
torch.random
torch.masked
torch.nested
torch.Size
torch.sparse
torch.Storage
torch.testing
torch.utils
Benchmark Utils - torch.utils.benchmark
torch.utils.checkpoint
torch.utils.cpp_extension
torch.utils.data
torch.utils.deterministic
JIT Utils - torch.utils.jit
torch.utils.dlpack
torch.utils.mobile_optimizer
torch.utils.model_zoo
torch.utils.tensorboard
torch.utils.module_tracker
Type Info
torch.config
torch.__future__
torch._logging
Torch Environment Variables
Developer Notes
Automatic Mixed Precision examples
Autograd mechanics
Broadcasting semantics
CPU threading and TorchScript inference
CUDA semantics
PyTorch Custom Operators Landing Page
Distributed Data Parallel
Extending PyTorch
Extending torch.func with autograd.Function
Frequently Asked Questions
Getting Started on Intel GPU
Gradcheck mechanics
HIP (ROCm) semantics
Features for large-scale deployments
LibTorch Stable ABI
LocalTensor Tutorial: Single-Process SPMD Debugging
MKLDNN backend
Modules
MPS backend
Multiprocessing best practices
Numerical accuracy
Out Notes
Reproducibility
Serialization semantics
TensorIterator (Python)
Windows FAQ
Community
PyTorch Governance | Build + CI
PyTorch Contribution Guide
PyTorch Design Philosophy
PyTorch Governance | Mechanics
PyTorch Governance | Maintainers
Tutorials
Go to pytorch.org
Ctrl + K
X
GitHub
PyTorch Forum
PyPi
Install PyTorch
User Guide
PyTorch Main Components
torch.compiler
torch.export
Developer Notes
Accelerator Integration
Reference API
torch
torch.nn
torch.nn.functional
torch.Tensor
Tensor Attributes
Tensor Views
Automatic Mixed Precision package - torch.amp
Automatic differentiation package - torch.autograd
torch.library
torch.accelerator
torch.cpu
torch.cuda
Understanding CUDA Memory Usage
torch.mps
torch.xpu
torch.mtia
torch.mtia.memory
torch.mtia.mtia_graph
Meta device
torch.backends
torch.export
Distributed communication package - torch.distributed
torch.distributed.tensor
Generic Join Context Manager
Torch Distributed Elastic
FullyShardedDataParallel
torch.distributed.fsdp.fully_shard
Tensor Parallelism - torch.distributed.tensor.parallel
Distributed Optimizers
Pipeline Parallelism
PyTorch Symmetric Memory
Distributed Checkpoint - torch.distributed.checkpoint
Probability distributions - torch.distributions
torch.compiler API reference
torch.fft
torch.func
torch.futures
torch.fx
torch.fx.experimental
torch.hub
torch.linalg
torch.monitor
torch.signal
torch.special
torch.overrides
torch.nativert
torch.package
torch.profiler
torch.nn.init
torch.nn.attention
torch.onnx
torch.optim
Complex Numbers
DDP Communication Hooks
Quantization
Distributed RPC Framework
torch.random
torch.masked
torch.nested
torch.Size
torch.sparse
torch.Storage
torch.testing
torch.utils
Benchmark Utils - torch.utils.benchmark
torch.utils.checkpoint
torch.utils.cpp_extension
torch.utils.data
torch.utils.deterministic
JIT Utils - torch.utils.jit
torch.utils.dlpack
torch.utils.mobile_optimizer
torch.utils.model_zoo
torch.utils.tensorboard
torch.utils.module_tracker
Type Info
torch.config
torch.__future__
torch._logging
Torch Environment Variables
Developer Notes
Automatic Mixed Precision examples
Autograd mechanics
Broadcasting semantics
CPU threading and TorchScript inference
CUDA semantics
PyTorch Custom Operators Landing Page
Distributed Data Parallel
Extending PyTorch
Extending torch.func with autograd.Function
Frequently Asked Questions
Getting Started on Intel GPU
Gradcheck mechanics
HIP (ROCm) semantics
Features for large-scale deployments
LibTorch Stable ABI
LocalTensor Tutorial: Single-Process SPMD Debugging
MKLDNN backend
Modules
MPS backend
Multiprocessing best practices
Numerical accuracy
Out Notes
Reproducibility
Serialization semantics
TensorIterator (Python)
Windows FAQ
Community
PyTorch Governance | Build + CI
PyTorch Contribution Guide
PyTorch Design Philosophy
PyTorch Governance | Mechanics
PyTorch Governance | Maintainers
Tutorials
Go to pytorch.org
Ctrl + K
X
GitHub
PyTorch Forum
PyPi
Section Navigation
Introduction
PyTorch Overview
Get Started
Learn the Basics
Core Concepts
PyTorch Main Components
Torch Compile
Torch.compile
Getting Started
Core Concepts
torch.compile Programming Model
Dynamo Core Concepts
Working with Graph Breaks
Non-strict Tracing Programming Model
Dealing with Recompilations
Reducing Compile Time
Reducing Guard Overhead
tlparse / TORCH_TRACE
Reporting Issues
Dynamo Overview
PyTorch 2.0 NNModule Support
torch.compile has different autograd semantics
Performance
PyTorch 2.0 Performance Dashboard
TorchInductor GPU Profiling
Profiling to understand torch.compile performance
CUDAGraph Trees
Advanced
Dynamo Deep-Dive
Writing Graph Transformations on ATen IR
Fake tensor
Custom Backends
Dynamic Shapes
Dynamic Shapes Core Concepts
Troubleshooting Dynamic Shapes
Advanced Options to Control Dynamic Behavior
Beyond the Basics
Ahead-of-Time Compilation with torch.compile
Complex Number Support in torch.compile
Troubleshooting FAQs
tlparse / TORCH_TRACE
Reporting Issues
torch.compile Troubleshooting
Frequently Asked Questions
Reference/API
torch.compiler API reference
torch.compiler.compile
torch.compiler.reset
torch.compiler.nonstrict_trace
torch.compiler.allow_in_graph
torch.compiler.substitute_in_graph
torch.compiler.assume_constant_result
torch.compiler.list_backends
torch.compiler.disable
torch.compiler.set_default_backend
torch.compiler.get_default_backend
torch.compiler.set_stance
torch.compiler.set_enable_guard_collectives
torch.compiler.cudagraph_mark_step_begin
torch.compiler.cudagraph_mark_warmup_incomplete
torch.compiler.is_compiling
torch.compiler.is_dynamo_compiling
torch.compiler.is_exporting
torch.compiler.keep_portable_guards_unsafe
torch.compiler.skip_guard_on_inbuilt_nn_modules_unsafe
torch.compiler.skip_guard_on_all_nn_modules_unsafe
torch.compiler.keep_tensor_guards_unsafe
torch.compiler.skip_guard_on_globals_unsafe
torch.compiler.skip_all_guards_unsafe
torch.compiler.nested_compile_region
torch.compiler.load_cache_artifacts
torch.compiler.load_compiled_function
torch.compiler.save_cache_artifacts
torch.compiler.wrap_numpy
torch.compiler.config
TorchDynamo APIs for fine-grained tracing
TorchInductor and AOTInductor Provenance Tracking
Torch.export
torch.export API Reference
torch.export Programming Model
torch.export IR Specification
PT2 Archive Spec
Draft Export
Joint with descriptors
Control Flow Operators
Control Flow - Cond
Control Flow - Switch
Control Flow - While Loop
Control Flow - Scan
Control Flow - Associative Scan
Control Flow - Map
ExportDB
torch.escape-hatch
torch.dynamic-shape
torch.cond
python.closure
torch.dynamic-value
python.data-structure
python.assert
python.control-flow
torch.map
python.builtin
python.object-model
python.context-manager
torch.operator
torch.mutation
AOTInductor: Ahead-Of-Time Compilation for Torch.Export-ed Models
torch._logging
torch._logging.set_logs
AOTInductor Minifier
AOTInductor Debugging Guide
IRs
Dynamic Shapes
Dynamic Shapes Core Concepts
Troubleshooting Dynamic Shapes
Debugging with tlparse and TORCH_LOGS=dynamic
Troubleshooting GuardOnDataDependentSymNode Errors
Advanced Options to Control Dynamic Behavior
Beyond the Basics
The Zero-One Specialization Problem
Backed vs Unbacked Symints
Fake tensor
Writing Graph Transformations on ATen IR
Developer Notes
Developer Notes
Automatic Mixed Precision examples
Autograd mechanics
Broadcasting semantics
CPU threading and TorchScript inference
CUDA semantics
PyTorch Custom Operators Landing Page
Distributed Data Parallel
Extending PyTorch
Extending torch.func with autograd.Function
Frequently Asked Questions
Getting Started on Intel GPU
Gradcheck mechanics
HIP (ROCm) semantics
Features for large-scale deployments
LibTorch Stable ABI
LocalTensor Tutorial: Single-Process SPMD Debugging
MKLDNN backend
Modules
MPS backend
Multiprocessing best practices
Numerical accuracy
Out Notes
Reproducibility
Serialization semantics
TensorIterator (Python)
Windows FAQ
Accelerator Integration
Accelerator Integration
Device Management
Accelerator Hooks
Guard
Autoload Mechanism
Operator Registration
Automatic Mixed Precision
Profiler Integration
Distributed Training Integration
CI Integration
User Guide
Developer Notes
Reproducibility
Rate this Page
★ ★ ★ ★ ★
Reproducibility #
Created On: May 14, 2026 | Last Updated On: May 14, 2026
Completely reproducible results are not guaranteed across PyTorch releases,
individual commits, or different platforms. Furthermore, results may not be
reproducible between CPU and GPU executions, even when using identical seeds.
However, there are some steps you can take to limit the number of sources of
nondeterministic behavior for a specific platform, device, and PyTorch release.
First, you can control sources of randomness that can cause multiple executions
of your application to behave differently. Second, you can configure PyTorch
to avoid using nondeterministic algorithms for some operations, so that multiple
calls to those operations, given the same inputs, will produce the same result.
Warning
Deterministic operations are often slower than nondeterministic operations, so
single-run performance may decrease for your model. However, determinism may
save time in development by facilitating experimentation, debugging, and
regression testing.
Controlling sources of randomness #
PyTorch random number generator #
You can use torch.manual_seed() to seed the RNG for all devices (both
CPU and CUDA):
import torch torch . manual_seed ( 0 )
Some PyTorch operations may use random numbers internally. torch.svd_lowrank() does this, for instance. Consequently, calling it
multiple times back-to-back with the same input arguments may give different
results. However, as long as torch.manual_seed() is set to a constant
at the beginning of an application and all other sources of nondeterminism have
been eliminated, the same series of random numbers will be generated each time
the application is run in the same environment.
It is also possible to obtain identical results from an operation that uses
random numbers by setting torch.manual_seed() to the same value between
subsequent calls.
Python #
For custom operators, you might need to set python seed as well:
import random random . seed ( 0 )
Random number generators in other libraries #
If you or any of the libraries you are using rely on NumPy, you can seed the global
NumPy RNG with:
import numpy as np np . random . seed ( 0 )
However, some applications and libraries may use NumPy Random Generator objects,
not the global RNG ( https://numpy.org/doc/stable/reference/random/generator.html ),
and those will need to be seeded consistently as well.
If you are using any other libraries that use random number generators, refer to
the documentation for those libraries to see how to set consistent seeds for them.
CUDA convolution benchmarking #
The cuDNN library, used by CUDA convolution operations, can be a source of nondeterminism
across multiple executions of an application. When a cuDNN convolution is called with a
new set of size parameters, an optional feature can run multiple convolution algorithms,
benchmarking them to find the fastest one. Then, the fastest algorithm will be used
consistently during the rest of the process for the corresponding set of size parameters.
Due to benchmarking noise and different hardware, the benchmark may select different
algorithms on subsequent runs, even on the same machine.
Disabling the benchmarking feature with torch.backends.cudnn.benchmark = False causes cuDNN to deterministically select an algorithm, possibly at the cost of reduced
performance.
However, if you do not need reproducibility across multiple executions of your application,
then performance might improve if the benchmarking feature is enabled with torch.backends.cudnn.benchmark = True .
Note that this setting is different from the torch.backends.cudnn.deterministic setting discussed below.
Avoiding nondeterministic algorithms #
torch.use_deterministic_algorithms() lets you configure PyTorch to use
deterministic algorithms instead of nondeterministic ones where available, and
to throw an error if an operation is known to be nondeterministic (and without
a deterministic alternative).
Please check the documentation for torch.use_deterministic_algorithms() for a full list of affected operations. If an operation does not act correctly
according to the documentation, or if you need a deterministic implementation
of an operation that does not have one, please submit an issue: https://github.com/pytorch/pytorch/issues?q=label:”module: determinism”
For example, running the nondeterministic CUDA implementation of torch.Tensor.index_add_() will throw an error:
>>> import torch >>> torch . use_deterministic_algorithms ( True ) >>> torch . randn ( 2 , 2 ) . cuda () . index_add_ ( 0 , torch . tensor ([ 0 , 1 ]), torch . randn ( 2 , 2 )) Traceback (most recent call last): File "<stdin>", line 1, in <module> RuntimeError : index_add_cuda_ does not have a deterministic implementation, but you set 'torch.use_deterministic_algorithms(True)'. ...
When torch.bmm() is called with sparse-dense CUDA tensors it typically uses a
nondeterministic algorithm, but when the deterministic flag is turned on, its alternate
deterministic implementation will be used:
>>> import torch >>> torch . use_deterministic_algorithms ( True ) >>> torch . bmm ( torch . randn ( 2 , 2 , 2 ) . to_sparse () . cuda (), torch . randn ( 2 , 2 , 2 ) . cuda ()) tensor([[[ 1.1900, -2.3409], [ 0.4796,  0.8003]], [[ 0.1509,  1.8027], [ 0.0333, -1.1444]]], device='cuda:0')
CUDA convolution determinism #
While disabling CUDA convolution benchmarking (discussed above) ensures that
CUDA selects the same algorithm each time an application is run, that algorithm
itself may be nondeterministic, unless either torch.use_deterministic_algorithms(True) or torch.backends.cudnn.deterministic = True is set. The latter setting
controls only this behavior, unlike torch.use_deterministic_algorithms() which will make other PyTorch operations behave deterministically, too.
CUDA Scaled Dot Product Attention #
torch.nn.functional.scaled_dot_product_attention() (SDPA) dispatches to
multiple backends at runtime. Each backend has different determinism
characteristics, summarized in the table below:
Backend
Forward
Backward
Notes
SDPBackend.MATH
Deterministic
Deterministic
Uses standard PyTorch operators ( matmul , softmax ). Deterministic
when torch.use_deterministic_algorithms() is enabled.
SDPBackend.FLASH_ATTENTION
Deterministic
Non-deterministic
The backward pass uses non-deterministic atomic operations by default.
Setting torch.use_deterministic_algorithms(True, warn_only=False) enables a deterministic backward implementation.
SDPBackend.EFFICIENT_ATTENTION
Deterministic
Non-deterministic
The backward pass may split work across keys ( num_splits_key > 1 )
for performance, which is non-deterministic. Setting torch.use_deterministic_algorithms(True, warn_only=False) forces num_splits_key = 1 , making the backward pass deterministic.
SDPBackend.CUDNN_ATTENTION
Deterministic
Non-deterministic
cuDNN provides an opt-in deterministic backward for float16 starting in cuDNN 9.18 (via set_deterministic_algorithm ),
but this has not yet been integrated into PyTorch. This backend is disabled when torch.use_deterministic_algorithms(True, warn_only=False) is set,
regardless of whether inputs require gradients or the call is
inside a torch.no_grad() context.
When torch.use_deterministic_algorithms(True, warn_only=True) is set,
the fused backends (Flash, Efficient, and cuDNN) emit a one-time warning but
still use their default non-deterministic code paths. To actually enforce
determinism, pass warn_only=False .
Low-precision dtypes and numerical reproducibility
Bitwise matching numerics across different SDPA backends are not
guaranteed , even for the same inputs and dtype. Each backend performs
floating-point accumulation in a different order, and because floating-point
addition is not associative, the results will differ between backends.
The Math backend by default accumulates in float32 even when given float16 or bfloat16 inputs. The function torch.backends.cuda.allow_fp16_bf16_reduction_math_sdp() can enable
reduced-precision accumulation for higher performance at the cost of
different numerical results.
Selecting a specific backend
Use the torch.nn.attention.sdpa_kernel() context manager to restrict
which backends SDPA may use. For example, to guarantee deterministic behavior
regardless of hardware:
import torch from torch.nn.attention import sdpa_kernel , SDPBackend torch . use_deterministic_algorithms ( True ) # Option 1: Use only the Math backend (always deterministic) with sdpa_kernel ( SDPBackend . MATH ): out = torch . nn . functional . scaled_dot_product_attention ( q , k , v ) # Option 2: Allow Flash and Efficient (deterministic with the flag above) with sdpa_kernel ([ SDPBackend . FLASH_ATTENTION , SDPBackend . EFFICIENT_ATTENTION ]): out = torch . nn . functional . scaled_dot_product_attention ( q , k , v )
CUDA RNN and LSTM #
In some versions of CUDA, RNNs and LSTM networks may have non-deterministic behavior.
See torch.nn.RNN() and torch.nn.LSTM() for details and workarounds.
Filling uninitialized memory #
Operations like torch.empty() and torch.Tensor.resize_() can return
tensors with uninitialized memory that contain undefined values. Using such a
tensor as an input to another operation is invalid if determinism is required,
because the output will be nondeterministic. But there is nothing to actually
prevent such invalid code from being run. So for safety, torch.utils.deterministic.fill_uninitialized_memory is set to True by default, which will fill the uninitialized memory with a known value if torch.use_deterministic_algorithms(True) is set. This will prevent the
possibility of this kind of nondeterministic behavior.
However, filling uninitialized memory is detrimental to performance. So if your
program is valid and does not use uninitialized memory as the input to an
operation, then this setting can be turned off for better performance.
DataLoader #
DataLoader will reseed workers following the Randomness in multi-process data loading algorithm.
Use worker_init_fn() and generator to preserve reproducibility:
def seed_worker ( worker_id ): worker_seed = torch . initial_seed () % 2 ** 32 numpy . random . seed ( worker_seed ) random . seed ( worker_seed ) g = torch . Generator () g . manual_seed ( 0 ) DataLoader ( train_dataset , batch_size = batch_size , num_workers = num_workers , worker_init_fn = seed_worker , generator = g , )
Rate this Page
★ ★ ★ ★ ★
Send Feedback
previous
Out Notes
next
Serialization semantics
Built with the PyData Sphinx Theme 0.15.4.
previous
Out Notes
next
Serialization semantics
On this page
Controlling sources of randomness
PyTorch random number generator
Python
Random number generators in other libraries
CUDA convolution benchmarking
Avoiding nondeterministic algorithms
CUDA convolution determinism
CUDA Scaled Dot Product Attention
CUDA RNN and LSTM
Filling uninitialized memory
DataLoader
Edit on GitHub
Show Source
PyTorch Libraries
ExecuTorch
Helion
torchao
kineto
torchtitan
TorchRL
torchvision
torchaudio
tensordict
PyTorch on XLA Devices
Docs
Access comprehensive developer documentation for PyTorch
View Docs
Tutorials
Get in-depth tutorials for beginners and advanced developers
View Tutorials
Resources
Find development resources and get your questions answered
View Resources
Stay in touch for updates, event info, and
the latest news
By submitting this form, I consent to receive marketing emails from the LF and its
projects regarding their events, training, research, developments, and related announcements. I understand that
I can unsubscribe at any time using the links in the footers of the emails I receive. Privacy Policy .
© PyTorch. Copyright © The Linux Foundation®. All rights reserved. The Linux Foundation has registered
trademarks and uses trademarks. For more information, including terms of use, privacy policy, and trademark
usage, please see our Policies page. Trademark Usage . Privacy Policy .
To analyze traffic and optimize your experience, we serve cookies on this site. By clicking or navigating, you agree to allow our usage of cookies. As the current maintainers of this site, Facebook’s Cookies Policy applies. Learn more, including about available controls: Cookies Policy .
© Copyright PyTorch Contributors.
Created using Sphinx 7.2.6.
Built with the PyData Sphinx Theme 0.15.4.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 22:09:58 MSK -->
<!-- content-sha256: sha256:b2e4136c2fab52a1a7104788187958c233dcd609154484be1aca0294f0700da6 -->
<!-- FUM-MD-RECENCY:END -->
