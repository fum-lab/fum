# Извлечённый текст

Источник: <https://github.com/git/git/blob/v2.54.0/builtin/update-ref.c>

## Содержимое

git/builtin/update-ref.c at v2.54.0 · git/git · GitHub
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
git / git Public
Notifications You must be signed in to change notification settings
Fork 28.4k
Star 63.1k
Code
Pull requests 381
Actions
Security and quality 32
Insights
Additional navigation options
Code
Pull requests
Actions
Security and quality
Insights
Files Expand file tree
v2.54.0
Breadcrumbs
git
/ builtin
/
update-ref.c
Copy path
Blame
More file actions
Blame
More file actions
Latest commit
History
History
History
847 lines (720 loc) · 23 KB
v2.54.0
Breadcrumbs
git
/ builtin
/
update-ref.c
Copy path
Top
File metadata and controls
Code
Blame
847 lines (720 loc) · 23 KB
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
677
678
679
680
681
682
683
684
685
686
687
688
689
690
691
692
693
694
695
696
697
698
699
700
701
702
703
704
705
706
707
708
709
710
711
712
713
714
715
716
717
718
719
720
721
722
723
724
725
726
727
728
729
730
731
732
733
734
735
736
737
738
739
740
741
742
743
744
745
746
747
748
749
750
751
752
753
754
755
756
757
758
759
760
761
762
763
764
765
766
767
768
769
770
771
772
773
774
775
776
777
778
779
780
781
782
783
784
785
786
787
788
789
790
791
792
793
794
795
796
797
798
799
800
801
802
803
804
805
806
807
808
809
810
811
812
813
814
815
816
817
818
819
820
821
822
823
824
825
826
827
828
829
830
831
832
833
834
835
836
837
838
839
840
841
842
843
844
845
846
847
#define USE_THE_REPOSITORY_VARIABLE
#define DISABLE_SIGN_COMPARE_WARNINGS
#include "builtin.h"
#include "config.h"
#include "environment.h"
#include "gettext.h"
#include "hash.h"
#include "hex.h"
#include "refs.h"
#include "object-name.h"
#include "parse-options.h"
#include "quote.h"
static const char * const git_update_ref_usage [] = {
N_ ( "git update-ref [<options>] -d <refname> [<old-oid>]" ),
N_ ( "git update-ref [<options>]    <refname> <new-oid> [<old-oid>]" ),
N_ ( "git update-ref [<options>] --stdin [-z] [--batch-updates]" ),
NULL
};
static char line_termination = '\n' ;
static unsigned int update_flags ;
static unsigned int default_flags ;
static unsigned create_reflog_flag ;
static const char * msg ;
/*
* Parse one whitespace- or NUL-terminated, possibly C-quoted argument
* and append the result to arg.  Return a pointer to the terminator.
* Die if there is an error in how the argument is C-quoted.  This
* function is only used if not -z.
*/
static const char * parse_arg ( const char * next , struct strbuf * arg )
{
if ( * next == '"' ) {
const char * orig = next ;
if ( unquote_c_style ( arg , next , & next ))
die ( "badly quoted argument: %s" , orig );
if ( * next && ! isspace ( * next ))
die ( "unexpected character after quoted argument: %s" , orig );
} else {
while ( * next && ! isspace ( * next ))
strbuf_addch ( arg , * next ++ );
}
return next ;
}
/*
* Parse the reference name immediately after "command SP".  If not
* -z, then handle C-quoting.  Return a pointer to a newly allocated
* string containing the name of the reference, or NULL if there was
* an error.  Update *next to point at the character that terminates
* the argument.  Die if C-quoting is malformed or the reference name
* is invalid.
*/
static char * parse_refname ( const char * * next )
{
struct strbuf ref = STRBUF_INIT ;
if ( line_termination ) {
/* Without -z, use the next argument */
* next = parse_arg ( * next , & ref );
} else {
/* With -z, use everything up to the next NUL */
strbuf_addstr ( & ref , * next );
* next += ref . len ;
}
if (! ref . len ) {
strbuf_release ( & ref );
return NULL ;
}
if ( check_refname_format ( ref . buf , REFNAME_ALLOW_ONELEVEL ))
die ( "invalid ref format: %s" , ref . buf );
return strbuf_detach ( & ref , NULL );
}
/*
* Wrapper around parse_refname which skips the next delimiter.
*/
static char * parse_next_refname ( const char * * next )
{
if ( line_termination ) {
/* Without -z, consume SP and use next argument */
if (! * * next || * * next == line_termination )
return NULL ;
if ( * * next != ' ' )
die ( "expected SP but got: %s" , * next );
} else {
/* With -z, read the next NUL-terminated line */
if ( * * next )
return NULL ;
}
/* Skip the delimiter */
( * next ) ++ ;
return parse_refname ( next );
}
/*
* Wrapper around parse_arg which skips the next delimiter.
*/
static char * parse_next_arg ( const char * * next )
{
struct strbuf arg = STRBUF_INIT ;
if ( line_termination ) {
/* Without -z, consume SP and use next argument */
if (! * * next || * * next == line_termination )
return NULL ;
if ( * * next != ' ' )
die ( "expected SP but got: %s" , * next );
} else {
/* With -z, read the next NUL-terminated line */
if ( * * next )
return NULL ;
}
/* Skip the delimiter */
( * next ) ++ ;
if ( line_termination ) {
/* Without -z, use the next argument */
* next = parse_arg ( * next , & arg );
} else {
/* With -z, use everything up to the next NUL */
strbuf_addstr ( & arg , * next );
* next += arg . len ;
}
if ( arg . len )
return strbuf_detach ( & arg , NULL );
strbuf_release ( & arg );
return NULL ;
}
/*
* The value being parsed is <old-oid> (as opposed to <new-oid>; the
* difference affects which error messages are generated):
*/
#define PARSE_SHA1_OLD 0x01
/*
* For backwards compatibility, accept an empty string for update's
* <new-oid> in binary mode to be equivalent to specifying zeros.
*/
#define PARSE_SHA1_ALLOW_EMPTY 0x02
/*
* Parse an argument separator followed by the next argument, if any.
* If there is an argument, convert it to a SHA-1, write it to sha1,
* set *next to point at the character terminating the argument, and
* return 0.  If there is no argument at all (not even the empty
* string), return 1 and leave *next unchanged.  If the value is
* provided but cannot be converted to a SHA-1, die.  flags can
* include PARSE_SHA1_OLD and/or PARSE_SHA1_ALLOW_EMPTY.
*/
static int parse_next_oid ( const char * * next , const char * end ,
struct object_id * oid ,
const char * command , const char * refname ,
int flags )
{
struct strbuf arg = STRBUF_INIT ;
int ret = 0 ;
if ( * next == end )
goto eof ;
if ( line_termination ) {
/* Without -z, consume SP and use next argument */
if (! * * next || * * next == line_termination )
return 1 ;
if ( * * next != ' ' )
die ( "%s %s: expected SP but got: %s" ,
command , refname , * next );
( * next ) ++ ;
* next = parse_arg ( * next , & arg );
if ( arg . len ) {
if ( repo_get_oid_with_flags ( the_repository , arg . buf , oid ,
GET_OID_SKIP_AMBIGUITY_CHECK ))
goto invalid ;
} else {
/* Without -z, an empty value means all zeros: */
oidclr ( oid , the_repository -> hash_algo );
}
} else {
/* With -z, read the next NUL-terminated line */
if ( * * next )
die ( "%s %s: expected NUL but got: %s" ,
command , refname , * next );
( * next ) ++ ;
if ( * next == end )
goto eof ;
strbuf_addstr ( & arg , * next );
* next += arg . len ;
if ( arg . len ) {
if ( repo_get_oid_with_flags ( the_repository , arg . buf , oid ,
GET_OID_SKIP_AMBIGUITY_CHECK ))
goto invalid ;
} else if ( flags & PARSE_SHA1_ALLOW_EMPTY ) {
/* With -z, treat an empty value as all zeros: */
warning ( "%s %s: missing <new-oid>, treating as zero" ,
command , refname );
oidclr ( oid , the_repository -> hash_algo );
} else {
/*
* With -z, an empty non-required value means
* unspecified:
*/
ret = 1 ;
}
}
strbuf_release ( & arg );
return ret ;
invalid :
die ( flags & PARSE_SHA1_OLD ?
"%s %s: invalid <old-oid>: %s" :
"%s %s: invalid <new-oid>: %s" ,
command , refname , arg . buf );
eof :
die ( flags & PARSE_SHA1_OLD ?
"%s %s: unexpected end of input when reading <old-oid>" :
"%s %s: unexpected end of input when reading <new-oid>" ,
command , refname );
}
/*
* The following five parse_cmd_*() functions parse the corresponding
* command.  In each case, next points at the character following the
* command name and the following space.  They each return a pointer
* to the character terminating the command, and die with an
* explanatory message if there are any parsing problems.  All of
* these functions handle either text or binary format input,
* depending on how line_termination is set.
*/
static void parse_cmd_update ( struct ref_transaction * transaction ,
const char * next , const char * end )
{
struct strbuf err = STRBUF_INIT ;
char * refname ;
struct object_id new_oid , old_oid ;
int have_old ;
refname = parse_refname ( & next );
if (! refname )
die ( "update: missing <ref>" );
if ( parse_next_oid ( & next , end , & new_oid , "update" , refname ,
PARSE_SHA1_ALLOW_EMPTY ))
die ( "update %s: missing <new-oid>" , refname );
have_old = ! parse_next_oid ( & next , end , & old_oid , "update" , refname ,
PARSE_SHA1_OLD );
if ( * next != line_termination )
die ( "update %s: extra input: %s" , refname , next );
if ( ref_transaction_update ( transaction , refname ,
& new_oid , have_old ? & old_oid : NULL ,
NULL , NULL ,
update_flags | create_reflog_flag ,
msg , & err ))
die ( "%s" , err . buf );
update_flags = default_flags ;
free ( refname );
strbuf_release ( & err );
}
static void parse_cmd_symref_update ( struct ref_transaction * transaction ,
const char * next , const char * end UNUSED )
{
char * refname , * new_target , * old_arg ;
char * old_target = NULL ;
struct strbuf err = STRBUF_INIT ;
struct object_id old_oid ;
int have_old_oid = 0 ;
refname = parse_refname ( & next );
if (! refname )
die ( "symref-update: missing <ref>" );
new_target = parse_next_refname ( & next );
if (! new_target )
die ( "symref-update %s: missing <new-target>" , refname );
old_arg = parse_next_arg ( & next );
if ( old_arg ) {
old_target = parse_next_arg ( & next );
if (! old_target )
die ( "symref-update %s: expected old value" , refname );
if (! strcmp ( old_arg , "oid" )) {
if ( repo_get_oid_with_flags ( the_repository , old_target , & old_oid ,
GET_OID_SKIP_AMBIGUITY_CHECK ))
die ( "symref-update %s: invalid oid: %s" , refname , old_target );
have_old_oid = 1 ;
} else if (! strcmp ( old_arg , "ref" )) {
if ( check_refname_format ( old_target , REFNAME_ALLOW_ONELEVEL ))
die ( "symref-update %s: invalid ref: %s" , refname , old_target );
} else {
die ( "symref-update %s: invalid arg '%s' for old value" , refname , old_arg );
}
}
if ( * next != line_termination )
die ( "symref-update %s: extra input: %s" , refname , next );
if ( ref_transaction_update ( transaction , refname , NULL ,
have_old_oid ? & old_oid : NULL ,
new_target ,
have_old_oid ? NULL : old_target ,
update_flags | create_reflog_flag ,
msg , & err ))
die ( "%s" , err . buf );
update_flags = default_flags ;
free ( refname );
free ( old_arg );
free ( old_target );
free ( new_target );
strbuf_release ( & err );
}
static void parse_cmd_create ( struct ref_transaction * transaction ,
const char * next , const char * end )
{
struct strbuf err = STRBUF_INIT ;
char * refname ;
struct object_id new_oid ;
refname = parse_refname ( & next );
if (! refname )
die ( "create: missing <ref>" );
if ( parse_next_oid ( & next , end , & new_oid , "create" , refname , 0 ))
die ( "create %s: missing <new-oid>" , refname );
if ( is_null_oid ( & new_oid ))
die ( "create %s: zero <new-oid>" , refname );
if ( * next != line_termination )
die ( "create %s: extra input: %s" , refname , next );
if ( ref_transaction_create ( transaction , refname , & new_oid , NULL ,
update_flags | create_reflog_flag ,
msg , & err ))
die ( "%s" , err . buf );
update_flags = default_flags ;
free ( refname );
strbuf_release ( & err );
}
static void parse_cmd_symref_create ( struct ref_transaction * transaction ,
const char * next , const char * end UNUSED )
{
struct strbuf err = STRBUF_INIT ;
char * refname , * new_target ;
refname = parse_refname ( & next );
if (! refname )
die ( "symref-create: missing <ref>" );
new_target = parse_next_refname ( & next );
if (! new_target )
die ( "symref-create %s: missing <new-target>" , refname );
if ( * next != line_termination )
die ( "symref-create %s: extra input: %s" , refname , next );
if ( ref_transaction_create ( transaction , refname , NULL , new_target ,
update_flags | create_reflog_flag ,
msg , & err ))
die ( "%s" , err . buf );
update_flags = default_flags ;
free ( refname );
free ( new_target );
strbuf_release ( & err );
}
static void parse_cmd_delete ( struct ref_transaction * transaction ,
const char * next , const char * end )
{
struct strbuf err = STRBUF_INIT ;
char * refname ;
struct object_id old_oid ;
int have_old ;
refname = parse_refname ( & next );
if (! refname )
die ( "delete: missing <ref>" );
if ( parse_next_oid ( & next , end , & old_oid , "delete" , refname ,
PARSE_SHA1_OLD )) {
have_old = 0 ;
} else {
if ( is_null_oid ( & old_oid ))
die ( "delete %s: zero <old-oid>" , refname );
have_old = 1 ;
}
if ( * next != line_termination )
die ( "delete %s: extra input: %s" , refname , next );
if ( ref_transaction_delete ( transaction , refname ,
have_old ? & old_oid : NULL ,
NULL , update_flags , msg , & err ))
die ( "%s" , err . buf );
update_flags = default_flags ;
free ( refname );
strbuf_release ( & err );
}
static void parse_cmd_symref_delete ( struct ref_transaction * transaction ,
const char * next , const char * end UNUSED )
{
struct strbuf err = STRBUF_INIT ;
char * refname , * old_target ;
if (!( update_flags & REF_NO_DEREF ))
die ( "symref-delete: cannot operate with deref mode" );
refname = parse_refname ( & next );
if (! refname )
die ( "symref-delete: missing <ref>" );
old_target = parse_next_refname ( & next );
if ( * next != line_termination )
die ( "symref-delete %s: extra input: %s" , refname , next );
if ( ref_transaction_delete ( transaction , refname , NULL ,
old_target , update_flags , msg , & err ))
die ( "%s" , err . buf );
update_flags = default_flags ;
free ( refname );
free ( old_target );
strbuf_release ( & err );
}
static void parse_cmd_verify ( struct ref_transaction * transaction ,
const char * next , const char * end )
{
struct strbuf err = STRBUF_INIT ;
char * refname ;
struct object_id old_oid ;
refname = parse_refname ( & next );
if (! refname )
die ( "verify: missing <ref>" );
if ( parse_next_oid ( & next , end , & old_oid , "verify" , refname ,
PARSE_SHA1_OLD ))
oidclr ( & old_oid , the_repository -> hash_algo );
if ( * next != line_termination )
die ( "verify %s: extra input: %s" , refname , next );
if ( ref_transaction_verify ( transaction , refname , & old_oid ,
NULL , update_flags , & err ))
die ( "%s" , err . buf );
update_flags = default_flags ;
free ( refname );
strbuf_release ( & err );
}
static void parse_cmd_symref_verify ( struct ref_transaction * transaction ,
const char * next , const char * end UNUSED )
{
struct strbuf err = STRBUF_INIT ;
struct object_id old_oid ;
char * refname , * old_target ;
if (!( update_flags & REF_NO_DEREF ))
die ( "symref-verify: cannot operate with deref mode" );
refname = parse_refname ( & next );
if (! refname )
die ( "symref-verify: missing <ref>" );
/*
* old_ref is optional, if not provided, we need to ensure that the
* ref doesn't exist.
*/
old_target = parse_next_refname ( & next );
if (! old_target )
oidcpy ( & old_oid , null_oid ( the_hash_algo ));
if ( * next != line_termination )
die ( "symref-verify %s: extra input: %s" , refname , next );
if ( ref_transaction_verify ( transaction , refname ,
old_target ? NULL : & old_oid ,
old_target , update_flags , & err ))
die ( "%s" , err . buf );
update_flags = default_flags ;
free ( refname );
free ( old_target );
strbuf_release ( & err );
}
static void report_ok ( const char * command )
{
fprintf ( stdout , "%s: ok\n" , command );
fflush ( stdout );
}
static void parse_cmd_option ( struct ref_transaction * transaction UNUSED ,
const char * next , const char * end UNUSED )
{
const char * rest ;
if ( skip_prefix ( next , "no-deref" , & rest ) && * rest == line_termination )
update_flags |= REF_NO_DEREF ;
else
die ( "option unknown: %s" , next );
}
static void parse_cmd_start ( struct ref_transaction * transaction UNUSED ,
const char * next , const char * end UNUSED )
{
if ( * next != line_termination )
die ( "start: extra input: %s" , next );
report_ok ( "start" );
}
static void parse_cmd_prepare ( struct ref_transaction * transaction ,
const char * next , const char * end UNUSED )
{
struct strbuf error = STRBUF_INIT ;
if ( * next != line_termination )
die ( "prepare: extra input: %s" , next );
if ( ref_transaction_prepare ( transaction , & error ))
die ( "prepare: %s" , error . buf );
report_ok ( "prepare" );
}
static void parse_cmd_abort ( struct ref_transaction * transaction ,
const char * next , const char * end UNUSED )
{
struct strbuf error = STRBUF_INIT ;
if ( * next != line_termination )
die ( "abort: extra input: %s" , next );
if ( ref_transaction_abort ( transaction , & error ))
die ( "abort: %s" , error . buf );
report_ok ( "abort" );
}
static void print_rejected_refs ( const char * refname ,
const struct object_id * old_oid ,
const struct object_id * new_oid ,
const char * old_target ,
const char * new_target ,
enum ref_transaction_error err ,
const char * details ,
void * cb_data UNUSED )
{
struct strbuf sb = STRBUF_INIT ;
if ( details && * details )
error ( "%s" , details );
strbuf_addf ( & sb , "rejected %s %s %s %s\n" , refname ,
new_oid ? oid_to_hex ( new_oid ) : new_target ,
old_oid ? oid_to_hex ( old_oid ) : old_target ,
ref_transaction_error_msg ( err ));
fwrite ( sb . buf , sb . len , 1 , stdout );
strbuf_release ( & sb );
}
static void parse_cmd_commit ( struct ref_transaction * transaction ,
const char * next , const char * end UNUSED )
{
struct strbuf error = STRBUF_INIT ;
if ( * next != line_termination )
die ( "commit: extra input: %s" , next );
if ( ref_transaction_commit ( transaction , & error ))
die ( "commit: %s" , error . buf );
ref_transaction_for_each_rejected_update ( transaction ,
print_rejected_refs , NULL );
report_ok ( "commit" );
ref_transaction_free ( transaction );
}
enum update_refs_state {
/* Non-transactional state open for updates. */
UPDATE_REFS_OPEN ,
/* A transaction has been started. */
UPDATE_REFS_STARTED ,
/* References are locked and ready for commit */
UPDATE_REFS_PREPARED ,
/* Transaction has been committed or closed. */
UPDATE_REFS_CLOSED ,
};
static const struct parse_cmd {
const char * prefix ;
void ( * fn )( struct ref_transaction * , const char * , const char * );
unsigned args ;
enum update_refs_state state ;
} command [] = {
{ "update" , parse_cmd_update , 3 , UPDATE_REFS_OPEN },
{ "create" , parse_cmd_create , 2 , UPDATE_REFS_OPEN },
{ "delete" , parse_cmd_delete , 2 , UPDATE_REFS_OPEN },
{ "verify" , parse_cmd_verify , 2 , UPDATE_REFS_OPEN },
{ "symref-update" , parse_cmd_symref_update , 4 , UPDATE_REFS_OPEN },
{ "symref-create" , parse_cmd_symref_create , 2 , UPDATE_REFS_OPEN },
{ "symref-delete" , parse_cmd_symref_delete , 2 , UPDATE_REFS_OPEN },
{ "symref-verify" , parse_cmd_symref_verify , 2 , UPDATE_REFS_OPEN },
{ "option" , parse_cmd_option , 1 , UPDATE_REFS_OPEN },
{ "start" , parse_cmd_start , 0 , UPDATE_REFS_STARTED },
{ "prepare" , parse_cmd_prepare , 0 , UPDATE_REFS_PREPARED },
{ "abort" , parse_cmd_abort , 0 , UPDATE_REFS_CLOSED },
{ "commit" , parse_cmd_commit , 0 , UPDATE_REFS_CLOSED },
};
static void update_refs_stdin ( unsigned int flags )
{
struct strbuf input = STRBUF_INIT , err = STRBUF_INIT ;
enum update_refs_state state = UPDATE_REFS_OPEN ;
struct ref_transaction * transaction ;
int i , j ;
transaction = ref_store_transaction_begin ( get_main_ref_store ( the_repository ),
flags , & err );
if (! transaction )
die ( "%s" , err . buf );
/* Read each line dispatch its command */
while (! strbuf_getwholeline ( & input , stdin , line_termination )) {
const struct parse_cmd * cmd = NULL ;
if ( * input . buf == line_termination )
die ( "empty command in input" );
else if ( isspace ( * input . buf ))
die ( "whitespace before command: %s" , input . buf );
for ( i = 0 ; i < ARRAY_SIZE ( command ); i ++ ) {
const char * prefix = command [ i ]. prefix ;
char c ;
if (! starts_with ( input . buf , prefix ))
continue ;
/*
* If the command has arguments, verify that it's
* followed by a space. Otherwise, it shall be followed
* by a line terminator.
*/
c = command [ i ]. args ? ' ' : line_termination ;
if ( input . buf [ strlen ( prefix )] != c )
continue ;
cmd = & command [ i ];
break ;
}
if (! cmd )
die ( "unknown command: %s" , input . buf );
/*
* Read additional arguments if NUL-terminated. Do not raise an
* error in case there is an early EOF to let the command
* handle missing arguments with a proper error message.
*/
for ( j = 1 ; line_termination == '\0' && j < cmd -> args ; j ++ )
if ( strbuf_appendwholeline ( & input , stdin , line_termination ))
break ;
switch ( state ) {
case UPDATE_REFS_OPEN :
case UPDATE_REFS_STARTED :
if ( state == UPDATE_REFS_STARTED && cmd -> state == UPDATE_REFS_STARTED )
die ( "cannot restart ongoing transaction" );
/* Do not downgrade a transaction to a non-transaction. */
if ( cmd -> state >= state )
state = cmd -> state ;
break ;
case UPDATE_REFS_PREPARED :
if ( cmd -> state != UPDATE_REFS_CLOSED )
die ( "prepared transactions can only be closed" );
state = cmd -> state ;
break ;
case UPDATE_REFS_CLOSED :
if ( cmd -> state != UPDATE_REFS_STARTED )
die ( "transaction is closed" );
/*
* Open a new transaction if we're currently closed and
* get a "start".
*/
state = cmd -> state ;
transaction = ref_store_transaction_begin ( get_main_ref_store ( the_repository ),
flags , & err );
if (! transaction )
die ( "%s" , err . buf );
break ;
}
cmd -> fn ( transaction , input . buf + strlen ( cmd -> prefix ) + !! cmd -> args ,
input . buf + input . len );
}
switch ( state ) {
case UPDATE_REFS_OPEN :
/* Commit by default if no transaction was requested. */
if ( ref_transaction_commit ( transaction , & err ))
die ( "%s" , err . buf );
ref_transaction_for_each_rejected_update ( transaction ,
print_rejected_refs , NULL );
ref_transaction_free ( transaction );
break ;
case UPDATE_REFS_STARTED :
case UPDATE_REFS_PREPARED :
/* If using a transaction, we want to abort it. */
if ( ref_transaction_abort ( transaction , & err ))
die ( "%s" , err . buf );
break ;
case UPDATE_REFS_CLOSED :
/* Otherwise no need to do anything, the transaction was closed already. */
break ;
}
strbuf_release ( & err );
strbuf_release ( & input );
}
int cmd_update_ref ( int argc ,
const char * * argv ,
const char * prefix ,
struct repository * repo UNUSED )
{
const char * refname , * oldval ;
struct object_id oid , oldoid ;
int delete = 0 , no_deref = 0 , read_stdin = 0 , end_null = 0 ;
int create_reflog = 0 ;
unsigned int flags = 0 ;
struct option options [] = {
OPT_STRING ( 'm' , NULL , & msg , N_ ( "reason" ), N_ ( "reason of the update" )),
OPT_BOOL ( 'd' , NULL , & delete , N_ ( "delete the reference" )),
OPT_BOOL ( 0 , "no-deref" , & no_deref ,
N_ ( "update <refname> not the one it points to" )),
OPT_BOOL ( 'z' , NULL , & end_null , N_ ( "stdin has NUL-terminated arguments" )),
OPT_BOOL ( 0 , "stdin" , & read_stdin , N_ ( "read updates from stdin" )),
OPT_BOOL ( 0 , "create-reflog" , & create_reflog , N_ ( "create a reflog" )),
OPT_BIT ( '0' , "batch-updates" , & flags , N_ ( "batch reference updates" ),
REF_TRANSACTION_ALLOW_FAILURE ),
OPT_END (),
};
repo_config ( the_repository , git_default_config , NULL );
argc = parse_options ( argc , argv , prefix , options , git_update_ref_usage ,
0 );
if ( msg && ! * msg )
die ( "Refusing to perform update with empty message." );
create_reflog_flag = create_reflog ? REF_FORCE_CREATE_REFLOG : 0 ;
if ( no_deref ) {
default_flags = REF_NO_DEREF ;
update_flags = default_flags ;
}
if ( read_stdin ) {
if ( delete || argc > 0 )
usage_with_options ( git_update_ref_usage , options );
if ( end_null )
line_termination = '\0' ;
update_refs_stdin ( flags );
return 0 ;
} else if ( flags & REF_TRANSACTION_ALLOW_FAILURE ) {
die ( "--batch-updates can only be used with --stdin" );
}
if ( end_null )
usage_with_options ( git_update_ref_usage , options );
if ( delete ) {
if ( argc < 1 || argc > 2 )
usage_with_options ( git_update_ref_usage , options );
refname = argv [ 0 ];
oldval = argv [ 1 ];
} else {
const char * value ;
if ( argc < 2 || argc > 3 )
usage_with_options ( git_update_ref_usage , options );
refname = argv [ 0 ];
value = argv [ 1 ];
oldval = argv [ 2 ];
if ( repo_get_oid_with_flags ( the_repository , value , & oid ,
GET_OID_SKIP_AMBIGUITY_CHECK ))
die ( "%s: not a valid SHA1" , value );
}
if ( oldval ) {
if (! * oldval )
/*
* The empty string implies that the reference
* must not already exist:
*/
oidclr ( & oldoid , the_repository -> hash_algo );
else if ( repo_get_oid_with_flags ( the_repository , oldval , & oldoid ,
GET_OID_SKIP_AMBIGUITY_CHECK ))
die ( "%s: not a valid old SHA1" , oldval );
}
if ( delete )
/*
* For purposes of backwards compatibility, we treat
* NULL_SHA1 as "don't care" here:
*/
return refs_delete_ref ( get_main_ref_store ( the_repository ),
msg , refname ,
( oldval && ! is_null_oid ( & oldoid )) ? & oldoid : NULL ,
default_flags );
else
return refs_update_ref ( get_main_ref_store ( the_repository ),
msg , refname , & oid ,
oldval ? & oldoid : NULL ,
default_flags | create_reflog_flag ,
UPDATE_REFS_DIE_ON_ERR );
}
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
<!-- last-content-edit: 2026-09-10 21:26:37 MSK -->
<!-- content-sha256: sha256:7cdaa4b45bd9ed3df576c8a04e17fe55bf107ee203f9dfef28bfda52dd87975d -->
<!-- FUM-MD-RECENCY:END -->
