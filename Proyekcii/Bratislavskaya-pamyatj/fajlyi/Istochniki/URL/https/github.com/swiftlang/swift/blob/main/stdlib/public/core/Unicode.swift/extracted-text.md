# Извлечённый текст

Источник: <https://github.com/swiftlang/swift/blob/main/stdlib/public/core/Unicode.swift>

## Содержимое

swift/stdlib/public/core/Unicode.swift at main · swiftlang/swift · GitHub
Skip to content
Navigation Menu
Sign in
Appearance settings
Platform
AI CODE CREATION
GitHub Copilot Write better code with AI
GitHub Copilot app Direct agents from issue to merge
MCP Registry Integrate external tools
DEVELOPER WORKFLOWS
Actions Automate any workflow
Codespaces Instant dev environments
Issues Plan and track work
Code Review Manage code changes
Code Quality Enforce quality at merge
APPLICATION SECURITY
GitHub Advanced Security Find and fix vulnerabilities
Code security Secure your code as you build
Secret protection Stop leaks before they start
EXPLORE
Why GitHub
Documentation
Blog
Changelog
Marketplace
View all features
Solutions
BY COMPANY SIZE
Enterprises
Small and medium teams
Startups
Nonprofits
BY USE CASE
App Modernization
DevSecOps
DevOps
CI/CD
View all use cases
BY INDUSTRY
Healthcare
Financial services
Manufacturing
Government
View all industries
View all solutions
Resources
EXPLORE BY TOPIC
AI
Software Development
DevOps
Security
View all topics
EXPLORE BY TYPE
Customer stories
Events & webinars
Ebooks & reports
Business insights
GitHub Skills
SUPPORT & SERVICES
Documentation
Customer support
Community forum
Trust center
Partners
View all resources
Open Source
COMMUNITY
GitHub Sponsors Fund open source developers
PROGRAMS
Security Lab
Maintainer Community
GitHub Stars
Archive Program
REPOSITORIES
Topics
Trending
Collections
Enterprise
ENTERPRISE SOLUTIONS
Enterprise platform AI-powered developer platform
AVAILABLE ADD-ONS
GitHub Advanced Security Enterprise-grade security features
Copilot for Business Enterprise-grade AI features
Premium Support Enterprise-grade 24/7 support
Pricing
Search /
Sign in
Sign up
Appearance settings
You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert
Uh oh!
There was an error while loading. Please reload this page .
swiftlang / swift Public
Notifications You must be signed in to change notification settings
Fork 10.8k
Star 70.3k
Code
Issues 5k+
Pull requests 1.7k
Security and quality 0
Insights
Additional navigation options
Code
Issues
Pull requests
Security and quality
Insights
Files Expand file tree
main
Breadcrumbs
swift
/ stdlib
/ public
/ core
/
Unicode.swift
Copy path
Blame
More file actions
Blame
More file actions
Latest commit
History
History
History
676 lines (635 loc) · 24.4 KB
main
Breadcrumbs
swift
/ stdlib
/ public
/ core
/
Unicode.swift
Copy path
Top
File metadata and controls
Code
Blame
676 lines (635 loc) · 24.4 KB
Raw
Copy raw file
Download raw file
Open symbols panel
Edit and raw actions
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
92
93
94
95
96
97
98
99
100
101
102
103
104
105
106
107
108
109
110
111
112
113
114
115
116
117
118
119
120
121
122
123
124
125
126
127
128
129
130
131
132
133
134
135
136
137
138
139
140
141
142
143
144
145
146
147
148
149
150
151
152
153
154
155
156
157
158
159
160
161
162
163
164
165
166
167
168
169
170
171
172
173
174
175
176
177
178
179
180
181
182
183
184
185
186
187
188
189
190
191
192
193
194
195
196
197
198
199
200
201
202
203
204
205
206
207
208
209
210
211
212
213
214
215
216
217
218
219
220
221
222
223
224
225
226
227
228
229
230
231
232
233
234
235
236
237
238
239
240
241
242
243
244
245
246
247
248
249
250
251
252
253
254
255
256
257
258
259
260
261
262
263
264
265
266
267
268
269
270
271
272
273
274
275
276
277
278
279
280
281
282
283
284
285
286
287
288
289
290
291
292
293
294
295
296
297
298
299
300
301
302
303
304
305
306
307
308
309
310
311
312
313
314
315
316
317
318
319
320
321
322
323
324
325
326
327
328
329
330
331
332
333
334
335
336
337
338
339
340
341
342
343
344
345
346
347
348
349
350
351
352
353
354
355
356
357
358
359
360
361
362
363
364
365
366
367
368
369
370
371
372
373
374
375
376
377
378
379
380
381
382
383
384
385
386
387
388
389
390
391
392
393
394
395
396
397
398
399
400
401
402
403
404
405
406
407
408
409
410
411
412
413
414
415
416
417
418
419
420
421
422
423
424
425
426
427
428
429
430
431
432
433
434
435
436
437
438
439
440
441
442
443
444
445
446
447
448
449
450
451
452
453
454
455
456
457
458
459
460
461
462
463
464
465
466
467
468
469
470
471
472
473
474
475
476
477
478
479
480
481
482
483
484
485
486
487
488
489
490
491
492
493
494
495
496
497
498
499
500
501
502
503
504
505
506
507
508
509
510
511
512
513
514
515
516
517
518
519
520
521
522
523
524
525
526
527
528
529
530
531
532
533
534
535
536
537
538
539
540
541
542
543
544
545
546
547
548
549
550
551
552
553
554
555
556
557
558
559
560
561
562
563
564
565
566
567
568
569
570
571
572
573
574
575
576
577
578
579
580
581
582
583
584
585
586
587
588
589
590
591
592
593
594
595
596
597
598
599
600
601
602
603
604
605
606
607
608
609
610
611
612
613
614
615
616
617
618
619
620
621
622
623
624
625
626
627
628
629
630
631
632
633
634
635
636
637
638
639
640
641
642
643
644
645
646
647
648
649
650
651
652
653
654
655
656
657
658
659
660
661
662
663
664
665
666
667
668
669
670
671
672
673
674
675
676
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
import SwiftShims
// Conversions between different Unicode encodings.  Note that UTF-16 and
// UTF-32 decoding are *not* currently resilient to erroneous data.
/// The result of one Unicode decoding step.
///
/// Each `UnicodeDecodingResult` instance can represent a Unicode scalar value,
/// an indication that no more Unicode scalars are available, or an indication
/// of a decoding error.
@ frozen
public enum UnicodeDecodingResult : Equatable , Sendable {
/// A decoded Unicode scalar value.
case scalarValue ( Unicode . Scalar )
/// An indication that no more Unicode scalars are available in the input.
case emptyInput
/// An indication of a decoding error.
case error
@ inlinable
public static func == (
lhs : UnicodeDecodingResult ,
rhs : UnicodeDecodingResult
) -> Bool {
switch ( lhs , rhs ) {
case ( . scalarValue ( let lhsScalar ) , . scalarValue ( let rhsScalar ) ) :
return lhsScalar == rhsScalar
case ( . emptyInput , . emptyInput ) :
return true
case ( . error , . error ) :
return true
default :
return false
}
}
}
/// A Unicode encoding form that translates between Unicode scalar values and
/// form-specific code units.
///
/// The `UnicodeCodec` protocol declares methods that decode code unit
/// sequences into Unicode scalar values and encode Unicode scalar values
/// into code unit sequences. The standard library implements codecs for the
/// UTF-8, UTF-16, and UTF-32 encoding schemes as the `UTF8`, `UTF16`, and
/// `UTF32` types, respectively. Use the `Unicode.Scalar` type to work with
/// decoded Unicode scalar values.
public protocol UnicodeCodec : _UnicodeEncoding {
/// Creates an instance of the codec.
init ( )
/// Starts or continues decoding a code unit sequence into Unicode scalar
/// values.
///
/// To decode a code unit sequence completely, call this method repeatedly
/// until it returns `UnicodeDecodingResult.emptyInput`. Checking that the
/// iterator was exhausted is not sufficient, because the decoder can store
/// buffered data from the input iterator.
///
/// Because of buffering, it is impossible to find the corresponding position
/// in the iterator for a given returned `Unicode.Scalar` or an error.
///
/// The following example decodes the UTF-8 encoded bytes of a string into an
/// array of `Unicode.Scalar` instances:
///
///     let str = "✨Unicode✨"
///     print(Array(str.utf8))
///     // Prints "[226, 156, 168, 85, 110, 105, 99, 111, 100, 101, 226, 156, 168]"
///
///     var bytesIterator = str.utf8.makeIterator()
///     var scalars: [Unicode.Scalar] = []
///     var utf8Decoder = UTF8()
///     Decode: while true {
///         switch utf8Decoder.decode(&bytesIterator) {
///         case .scalarValue(let v): scalars.append(v)
///         case .emptyInput: break Decode
///         case .error:
///             print("Decoding error")
///             break Decode
///         }
///     }
///     print(scalars)
///     // Prints "["\u{2728}", "U", "n", "i", "c", "o", "d", "e", "\u{2728}"]"
///
/// - Parameter input: An iterator of code units to be decoded. `input` must be
///   the same iterator instance in repeated calls to this method. Do not
///   advance the iterator or any copies of the iterator outside this
///   method.
/// - Returns: A `UnicodeDecodingResult` instance, representing the next
///   Unicode scalar, an indication of an error, or an indication that the
///   UTF sequence has been fully decoded.
mutating func decode < I : IteratorProtocol > (
_ input : inout I
) -> UnicodeDecodingResult where I . Element == CodeUnit
/// Encodes a Unicode scalar as a series of code units by calling the given
/// closure on each code unit.
///
/// For example, the musical fermata symbol ("𝄐") is a single Unicode scalar
/// value (`\u{1D110}`) but requires four code units for its UTF-8
/// representation. The following code uses the `UTF8` codec to encode a
/// fermata in UTF-8:
///
///     var bytes: [UTF8.CodeUnit] = []
///     UTF8.encode("𝄐", into: { bytes.append($0) })
///     print(bytes)
///     // Prints "[240, 157, 132, 144]"
///
/// - Parameters:
///   - input: The Unicode scalar value to encode.
///   - processCodeUnit: A closure that processes one code unit argument at a
///     time.
static func encode (
_ input : Unicode . Scalar ,
into processCodeUnit : ( CodeUnit ) -> Void
)
/// Searches for the first occurrence of a `CodeUnit` that is equal to 0.
///
/// Is an equivalent of `strlen` for C-strings.
///
/// - Complexity: O(*n*)
static func _nullCodeUnitOffset ( in input : UnsafePointer < CodeUnit > ) -> Int
}
/// A codec for translating between Unicode scalar values and UTF-8 code
/// units.
extension Unicode . UTF8 : UnicodeCodec {
/// Creates an instance of the UTF-8 codec.
@ inlinable
public init ( ) { self = . _swift3Buffer ( ForwardParser ( ) ) }
/// Starts or continues decoding a UTF-8 sequence.
///
/// To decode a code unit sequence completely, call this method repeatedly
/// until it returns `UnicodeDecodingResult.emptyInput`. Checking that the
/// iterator was exhausted is not sufficient, because the decoder can store
/// buffered data from the input iterator.
///
/// Because of buffering, it is impossible to find the corresponding position
/// in the iterator for a given returned `Unicode.Scalar` or an error.
///
/// The following example decodes the UTF-8 encoded bytes of a string into an
/// array of `Unicode.Scalar` instances. This is a demonstration only---if
/// you need the Unicode scalar representation of a string, use its
/// `unicodeScalars` view.
///
///     let str = "✨Unicode✨"
///     print(Array(str.utf8))
///     // Prints "[226, 156, 168, 85, 110, 105, 99, 111, 100, 101, 226, 156, 168]"
///
///     var bytesIterator = str.utf8.makeIterator()
///     var scalars: [Unicode.Scalar] = []
///     var utf8Decoder = UTF8()
///     Decode: while true {
///         switch utf8Decoder.decode(&bytesIterator) {
///         case .scalarValue(let v): scalars.append(v)
///         case .emptyInput: break Decode
///         case .error:
///             print("Decoding error")
///             break Decode
///         }
///     }
///     print(scalars)
///     // Prints "["\u{2728}", "U", "n", "i", "c", "o", "d", "e", "\u{2728}"]"
///
/// - Parameter input: An iterator of code units to be decoded. `input` must be
///   the same iterator instance in repeated calls to this method. Do not
///   advance the iterator or any copies of the iterator outside this
///   method.
/// - Returns: A `UnicodeDecodingResult` instance, representing the next
///   Unicode scalar, an indication of an error, or an indication that the
///   UTF sequence has been fully decoded.
@ inlinable
@ inline ( __always )
public mutating func decode < I : IteratorProtocol > (
_ input : inout I
) -> UnicodeDecodingResult where I . Element == CodeUnit {
guard case . _swift3Buffer ( var parser ) = self else {
Builtin . unreachable ( )
}
defer { self = . _swift3Buffer ( parser ) }
switch parser . parseScalar ( from : & input ) {
case . valid ( let s ) : return . scalarValue ( UTF8 . decode ( s ) )
case . error : return . error
case . emptyInput : return . emptyInput
}
}
/// Attempts to decode a single UTF-8 code unit sequence starting at the LSB
/// of `buffer`.
///
/// - Returns:
///   - result: The decoded code point if the code unit sequence is
///     well-formed; `nil` otherwise.
///   - length: The length of the code unit sequence in bytes if it is
///     well-formed; otherwise the *maximal subpart of the ill-formed
///     sequence* (Unicode 8.0.0, Ch 3.9, D93b), i.e. the number of leading
///     code units that were valid or 1 in case none were valid.  Unicode
///     recommends to skip these bytes and replace them by a single
///     replacement character (U+FFFD).
///
/// - Requires: There is at least one used byte in `buffer`, and the unused
///   space in `buffer` is filled with some value not matching the UTF-8
///   continuation byte form (`0b10xxxxxx`).
@ inlinable
public // @testable
static func _decodeOne ( _ buffer : UInt32 ) -> ( result : UInt32 ? , length : UInt8 ) {
// Note the buffer is read least significant byte first: [ #3 #2 #1 #0 ].
if buffer & 0x80 == 0 { // 1-byte sequence (ASCII), buffer: [ ... ... ... CU0 ].
let value = buffer & 0xff
return ( value , 1 )
}
var p = ForwardParser ( )
p . _buffer . _storage = buffer
p . _buffer . _bitCount = 32
var i = EmptyCollection < UInt8 > ( ) . makeIterator ( )
switch p . parseScalar ( from : & i ) {
case . valid ( let s ) :
return (
result : UTF8 . decode ( s ) . value ,
length : UInt8 ( truncatingIfNeeded : s . count ) )
case . error ( let l ) :
return ( result : nil , length : UInt8 ( truncatingIfNeeded : l ) )
case . emptyInput : Builtin . unreachable ( )
}
}
/// Encodes a Unicode scalar as a series of code units by calling the given
/// closure on each code unit.
///
/// For example, the musical fermata symbol ("𝄐") is a single Unicode scalar
/// value (`\u{1D110}`) but requires four code units for its UTF-8
/// representation. The following code encodes a fermata in UTF-8:
///
///     var bytes: [UTF8.CodeUnit] = []
///     UTF8.encode("𝄐", into: { bytes.append($0) })
///     print(bytes)
///     // Prints "[240, 157, 132, 144]"
///
/// - Parameters:
///   - input: The Unicode scalar value to encode.
///   - processCodeUnit: A closure that processes one code unit argument at a
///     time.
@ inlinable
@ inline ( __always )
public static func encode (
_ input : Unicode . Scalar ,
into processCodeUnit : ( CodeUnit ) -> Void
) {
var s = encode ( input ) ! . _biasedBits
processCodeUnit ( UInt8 ( truncatingIfNeeded : s ) &- 0x01 )
s &>>= 8
if _fastPath ( s == 0 ) { return }
processCodeUnit ( UInt8 ( truncatingIfNeeded : s ) &- 0x01 )
s &>>= 8
if _fastPath ( s == 0 ) { return }
processCodeUnit ( UInt8 ( truncatingIfNeeded : s ) &- 0x01 )
s &>>= 8
if _fastPath ( s == 0 ) { return }
processCodeUnit ( UInt8 ( truncatingIfNeeded : s ) &- 0x01 )
}
/// Returns a Boolean value indicating whether the specified code unit is a
/// UTF-8 continuation byte.
///
/// Continuation bytes take the form `0b10xxxxxx`. For example, a lowercase
/// "e" with an acute accent above it (`"é"`) uses 2 bytes for its UTF-8
/// representation: `0b11000011` (195) and `0b10101001` (169). The second
/// byte is a continuation byte.
///
///     let eAcute = "é"
///     for codeUnit in eAcute.utf8 {
///         print(codeUnit, UTF8.isContinuation(codeUnit))
///     }
///     // Prints "195 false"
///     // Prints "169 true"
///
/// - Parameter byte: A UTF-8 code unit.
/// - Returns: `true` if `byte` is a continuation byte; otherwise, `false`.
@ inlinable
public static func isContinuation ( _ byte : CodeUnit ) -> Bool {
return byte & 0b11_00__0000 == 0b10_00__0000
}
@ inlinable
public static func _nullCodeUnitOffset (
in input : UnsafePointer < CodeUnit >
) -> Int {
return unsafe Int ( _swift_stdlib_strlen_unsigned ( input ) )
}
// Support parsing C strings as-if they are UTF8 strings.
@ inlinable
public static func _nullCodeUnitOffset (
in input : UnsafePointer < CChar >
) -> Int {
return unsafe Int ( _swift_stdlib_strlen ( input ) )
}
}
/// A codec for translating between Unicode scalar values and UTF-16 code
/// units.
extension Unicode . UTF16 : UnicodeCodec {
/// Creates an instance of the UTF-16 codec.
@ inlinable
public init ( ) { self = . _swift3Buffer ( ForwardParser ( ) ) }
/// Starts or continues decoding a UTF-16 sequence.
///
/// To decode a code unit sequence completely, call this method repeatedly
/// until it returns `UnicodeDecodingResult.emptyInput`. Checking that the
/// iterator was exhausted is not sufficient, because the decoder can store
/// buffered data from the input iterator.
///
/// Because of buffering, it is impossible to find the corresponding position
/// in the iterator for a given returned `Unicode.Scalar` or an error.
///
/// The following example decodes the UTF-16 encoded bytes of a string into an
/// array of `Unicode.Scalar` instances. This is a demonstration only---if
/// you need the Unicode scalar representation of a string, use its
/// `unicodeScalars` view.
///
///     let str = "✨Unicode✨"
///     print(Array(str.utf16))
///     // Prints "[10024, 85, 110, 105, 99, 111, 100, 101, 10024]"
///
///     var codeUnitIterator = str.utf16.makeIterator()
///     var scalars: [Unicode.Scalar] = []
///     var utf16Decoder = UTF16()
///     Decode: while true {
///         switch utf16Decoder.decode(&codeUnitIterator) {
///         case .scalarValue(let v): scalars.append(v)
///         case .emptyInput: break Decode
///         case .error:
///             print("Decoding error")
///             break Decode
///         }
///     }
///     print(scalars)
///     // Prints "["\u{2728}", "U", "n", "i", "c", "o", "d", "e", "\u{2728}"]"
///
/// - Parameter input: An iterator of code units to be decoded. `input` must be
///   the same iterator instance in repeated calls to this method. Do not
///   advance the iterator or any copies of the iterator outside this
///   method.
/// - Returns: A `UnicodeDecodingResult` instance, representing the next
///   Unicode scalar, an indication of an error, or an indication that the
///   UTF sequence has been fully decoded.
@ inlinable
public mutating func decode < I : IteratorProtocol > (
_ input : inout I
) -> UnicodeDecodingResult where I . Element == CodeUnit {
guard case . _swift3Buffer ( var parser ) = self else {
Builtin . unreachable ( )
}
defer { self = . _swift3Buffer ( parser ) }
switch parser . parseScalar ( from : & input ) {
case . valid ( let s ) : return . scalarValue ( UTF16 . decode ( s ) )
case . error : return . error
case . emptyInput : return . emptyInput
}
}
/// Try to decode one Unicode scalar, and return the actual number of code
/// units it spanned in the input.  This function may consume more code
/// units than required for this scalar.
@ inlinable
internal mutating func _decodeOne < I : IteratorProtocol > (
_ input : inout I
) -> ( UnicodeDecodingResult , Int ) where I . Element == CodeUnit {
let result = decode ( & input )
switch result {
case . scalarValue ( let us ) :
return ( result , UTF16 . width ( us ) )
case . emptyInput :
return ( result , 0 )
case . error :
return ( result , 1 )
}
}
/// Encodes a Unicode scalar as a series of code units by calling the given
/// closure on each code unit.
///
/// For example, the musical fermata symbol ("𝄐") is a single Unicode scalar
/// value (`\u{1D110}`) but requires two code units for its UTF-16
/// representation. The following code encodes a fermata in UTF-16:
///
///     var codeUnits: [UTF16.CodeUnit] = []
///     UTF16.encode("𝄐", into: { codeUnits.append($0) })
///     print(codeUnits)
///     // Prints "[55348, 56592]"
///
/// - Parameters:
///   - input: The Unicode scalar value to encode.
///   - processCodeUnit: A closure that processes one code unit argument at a
///     time.
@ inlinable
public static func encode (
_ input : Unicode . Scalar ,
into processCodeUnit : ( CodeUnit ) -> Void
) {
var s = encode ( input ) ! . _storage
processCodeUnit ( UInt16 ( truncatingIfNeeded : s ) )
s &>>= 16
if _fastPath ( s == 0 ) { return }
processCodeUnit ( UInt16 ( truncatingIfNeeded : s ) )
}
}
/// A codec for translating between Unicode scalar values and UTF-32 code
/// units.
extension Unicode . UTF32 : UnicodeCodec {
/// Creates an instance of the UTF-32 codec.
@ inlinable
public init ( ) { self = . _swift3Codec }
/// Starts or continues decoding a UTF-32 sequence.
///
/// To decode a code unit sequence completely, call this method repeatedly
/// until it returns `UnicodeDecodingResult.emptyInput`. Checking that the
/// iterator was exhausted is not sufficient, because the decoder can store
/// buffered data from the input iterator.
///
/// Because of buffering, it is impossible to find the corresponding position
/// in the iterator for a given returned `Unicode.Scalar` or an error.
///
/// The following example decodes the UTF-16 encoded bytes of a string
/// into an array of `Unicode.Scalar` instances. This is a demonstration
/// only---if you need the Unicode scalar representation of a string, use
/// its `unicodeScalars` view.
///
///     // UTF-32 representation of "✨Unicode✨"
///     let codeUnits: [UTF32.CodeUnit] =
///             [10024, 85, 110, 105, 99, 111, 100, 101, 10024]
///
///     var codeUnitIterator = codeUnits.makeIterator()
///     var scalars: [Unicode.Scalar] = []
///     var utf32Decoder = UTF32()
///     Decode: while true {
///         switch utf32Decoder.decode(&codeUnitIterator) {
///         case .scalarValue(let v): scalars.append(v)
///         case .emptyInput: break Decode
///         case .error:
///             print("Decoding error")
///             break Decode
///         }
///     }
///     print(scalars)
///     // Prints "["\u{2728}", "U", "n", "i", "c", "o", "d", "e", "\u{2728}"]"
///
/// - Parameter input: An iterator of code units to be decoded. `input` must be
///   the same iterator instance in repeated calls to this method. Do not
///   advance the iterator or any copies of the iterator outside this
///   method.
/// - Returns: A `UnicodeDecodingResult` instance, representing the next
///   Unicode scalar, an indication of an error, or an indication that the
///   UTF sequence has been fully decoded.
@ inlinable
public mutating func decode < I : IteratorProtocol > (
_ input : inout I
) -> UnicodeDecodingResult where I . Element == CodeUnit {
var parser = ForwardParser ( )
switch parser . parseScalar ( from : & input ) {
case . valid ( let s ) : return . scalarValue ( UTF32 . decode ( s ) )
case . error : return . error
case . emptyInput : return . emptyInput
}
}
/// Encodes a Unicode scalar as a UTF-32 code unit by calling the given
/// closure.
///
/// For example, like every Unicode scalar, the musical fermata symbol ("𝄐")
/// can be represented in UTF-32 as a single code unit. The following code
/// encodes a fermata in UTF-32:
///
///     var codeUnit: UTF32.CodeUnit = 0
///     UTF32.encode("𝄐", into: { codeUnit = $0 })
///     print(codeUnit)
///     // Prints "119056"
///
/// - Parameters:
///   - input: The Unicode scalar value to encode.
///   - processCodeUnit: A closure that processes one code unit argument at a
///     time.
@ inlinable
public static func encode (
_ input : Unicode . Scalar ,
into processCodeUnit : ( CodeUnit ) -> Void
) {
processCodeUnit ( UInt32 ( input ) )
}
}
/// Translates the given input from one Unicode encoding to another by calling
/// the given closure.
///
/// The following example transcodes the UTF-8 representation of the string
/// `"Fermata 𝄐"` into UTF-32.
///
///     let fermata = "Fermata 𝄐"
///     let bytes = fermata.utf8
///     print(Array(bytes))
///     // Prints "[70, 101, 114, 109, 97, 116, 97, 32, 240, 157, 132, 144]"
///
///     var codeUnits: [UTF32.CodeUnit] = []
///     let sink = { codeUnits.append($0) }
///     transcode(bytes.makeIterator(), from: UTF8.self, to: UTF32.self,
///               stoppingOnError: false, into: sink)
///     print(codeUnits)
///     // Prints "[70, 101, 114, 109, 97, 116, 97, 32, 119056]"
///
/// The `sink` closure is called with each resulting UTF-32 code unit as the
/// function iterates over its input.
///
/// - Parameters:
///   - input: An iterator of code units to be translated, encoded as
///     `inputEncoding`. If `stopOnError` is `false`, the entire iterator will
///     be exhausted. Otherwise, iteration will stop if an encoding error is
///     detected.
///   - inputEncoding: The Unicode encoding of `input`.
///   - outputEncoding: The destination Unicode encoding.
///   - stopOnError: Pass `true` to stop translation when an encoding error is
///     detected in `input`. Otherwise, a Unicode replacement character
///     (`"\u{FFFD}"`) is inserted for each detected error.
///   - processCodeUnit: A closure that processes one `outputEncoding` code
///     unit at a time.
/// - Returns: `true` if the translation detected encoding errors in `input`;
///   otherwise, `false`.
@ inlinable
@ inline ( __always )
public func transcode <
Input : IteratorProtocol ,
InputEncoding : Unicode . Encoding ,
OutputEncoding : Unicode . Encoding
> (
_ input : Input ,
from inputEncoding : InputEncoding . Type ,
to outputEncoding : OutputEncoding . Type ,
stoppingOnError stopOnError : Bool ,
into processCodeUnit : ( OutputEncoding . CodeUnit ) -> Void
) -> Bool
where InputEncoding . CodeUnit == Input . Element {
var input = input
// NB.  It is not possible to optimize this routine to a memcpy if
// InputEncoding == OutputEncoding.  The reason is that memcpy will not
// substitute U+FFFD replacement characters for ill-formed sequences.
var p = InputEncoding . ForwardParser ( )
var hadError = false
loop:
while true {
switch p . parseScalar ( from : & input ) {
case . valid ( let s ) :
let t = OutputEncoding . transcode ( s , from : inputEncoding )
guard _fastPath ( t != nil ) , let s = t else { break }
s . forEach ( processCodeUnit )
continue loop
case . emptyInput :
return hadError
case . error :
if _slowPath ( stopOnError ) { return true }
hadError = true
}
OutputEncoding . encodedReplacementCharacter . forEach ( processCodeUnit )
}
fatalError ( )
}
/// Instances of conforming types are used in internal `String`
/// representation.
public // @testable
protocol _StringElement {
static func _toUTF16CodeUnit ( _ : Self ) -> UTF16 . CodeUnit
static func _fromUTF16CodeUnit ( _ utf16 : UTF16 . CodeUnit ) -> Self
}
extension UTF16 . CodeUnit : _StringElement {
@ inlinable
public // @testable
static func _toUTF16CodeUnit ( _ x : UTF16 . CodeUnit ) -> UTF16 . CodeUnit {
return x
}
@ inlinable
public // @testable
static func _fromUTF16CodeUnit (
_ utf16 : UTF16 . CodeUnit
) -> UTF16 . CodeUnit {
return utf16
}
}
extension UTF8 . CodeUnit : _StringElement {
@ inlinable
public // @testable
static func _toUTF16CodeUnit ( _ x : UTF8 . CodeUnit ) -> UTF16 . CodeUnit {
_internalInvariant ( x <= 0x7f , " should only be doing this with ASCII " )
return UTF16 . CodeUnit ( truncatingIfNeeded : x )
}
@ inlinable
public // @testable
static func _fromUTF16CodeUnit (
_ utf16 : UTF16 . CodeUnit
) -> UTF8 . CodeUnit {
_internalInvariant ( utf16 <= 0x7f , " should only be doing this with ASCII " )
return UTF8 . CodeUnit ( truncatingIfNeeded : utf16 )
}
}
// Unchecked init to avoid precondition branches in hot code paths where we
// already know the value is a valid unicode scalar.
extension Unicode . Scalar {
/// Create an instance with numeric value `value`, bypassing the regular
/// precondition checks for code point validity.
@ inlinable
internal init ( _unchecked value : UInt32 ) {
_internalInvariant ( value < 0xD800 || value > 0xDFFF ,
" high- and low-surrogate code points are not valid Unicode scalar values " )
_internalInvariant ( value <= 0x10FFFF , " value is outside of Unicode codespace " )
self . _value = value
}
}
extension UnicodeCodec {
@ inlinable
public static func _nullCodeUnitOffset (
in input : UnsafePointer < CodeUnit >
) -> Int {
var length = 0
while unsafe input [ length ] != 0 {
length += 1
}
return length
}
}
@ available ( * , unavailable , message : " use 'transcode(_:from:to:stoppingOnError:into:)' " )
public func transcode < Input , InputEncoding , OutputEncoding > (
_ inputEncoding : InputEncoding . Type , _ outputEncoding : OutputEncoding . Type ,
_ input : Input , _ output : ( OutputEncoding . CodeUnit ) -> Void ,
stopOnError : Bool
) -> Bool
where
Input : IteratorProtocol ,
InputEncoding : UnicodeCodec ,
OutputEncoding : UnicodeCodec ,
InputEncoding . CodeUnit == Input . Element {
Builtin . unreachable ( )
}
/// A namespace for Unicode utilities.
@ frozen
public enum Unicode : ~ BitwiseCopyable { }
Footer
© 2026 GitHub, Inc.
Footer navigation
Terms
Privacy
Security
Status
Community
Docs
Contact
Manage cookies
Do not share my personal information
You can’t perform that action at this time.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-11 12:26:13 MSK -->
<!-- content-sha256: sha256:263a211894d894b064f7882ca26e9127b38487a8ecea44188487b60e0341fdbd -->
<!-- FUM-MD-RECENCY:END -->
