# Извлечённый текст

Источник: <https://github.com/git/git/blob/v2.54.0/refs/files-backend.c>

## Содержимое

git/refs/files-backend.c at v2.54.0 · git/git · GitHub
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
/ refs
/
files-backend.c
Copy path
Blame
More file actions
Blame
More file actions
Latest commit
History
History
History
4069 lines (3546 loc) · 112 KB
v2.54.0
Breadcrumbs
git
/ refs
/
files-backend.c
Copy path
Top
File metadata and controls
Code
Blame
4069 lines (3546 loc) · 112 KB
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
848
849
850
851
852
853
854
855
856
857
858
859
860
861
862
863
864
865
866
867
868
869
870
871
872
873
874
875
876
877
878
879
880
881
882
883
884
885
886
887
888
889
890
891
892
893
894
895
896
897
898
899
900
901
902
903
904
905
906
907
908
909
910
911
912
913
914
915
916
917
918
919
920
921
922
923
924
925
926
927
928
929
930
931
932
933
934
935
936
937
938
939
940
941
942
943
944
945
946
947
948
949
950
951
952
953
954
955
956
957
958
959
960
961
962
963
964
965
966
967
968
969
970
971
972
973
974
975
976
977
978
979
980
981
982
983
984
985
986
987
988
989
990
991
992
993
994
995
996
997
998
999
1000
#define USE_THE_REPOSITORY_VARIABLE
#define DISABLE_SIGN_COMPARE_WARNINGS
#include "../git-compat-util.h"
#include "../abspath.h"
#include "../config.h"
#include "../copy.h"
#include "../environment.h"
#include "../gettext.h"
#include "../hash.h"
#include "../hex.h"
#include "../fsck.h"
#include "../refs.h"
#include "../repo-settings.h"
#include "refs-internal.h"
#include "ref-cache.h"
#include "packed-backend.h"
#include "../ident.h"
#include "../iterator.h"
#include "../dir-iterator.h"
#include "../lockfile.h"
#include "../object.h"
#include "../path.h"
#include "../dir.h"
#include "../chdir-notify.h"
#include "../setup.h"
#include "../worktree.h"
#include "../wrapper.h"
#include "../write-or-die.h"
#include "../revision.h"
#include <wildmatch.h>
/*
* This backend uses the following flags in `ref_update::flags` for
* internal bookkeeping purposes. Their numerical values must not
* conflict with REF_NO_DEREF, REF_FORCE_CREATE_REFLOG, REF_HAVE_NEW,
* or REF_HAVE_OLD, which are also stored in `ref_update::flags`.
*/
/*
* Used as a flag in ref_update::flags when a loose ref is being
* pruned. This flag must only be used when REF_NO_DEREF is set.
*/
#define REF_IS_PRUNING (1 << 4)
/*
* Flag passed to lock_ref_sha1_basic() telling it to tolerate broken
* refs (i.e., because the reference is about to be deleted anyway).
*/
#define REF_DELETING (1 << 5)
/*
* Used as a flag in ref_update::flags when the lockfile needs to be
* committed.
*/
#define REF_NEEDS_COMMIT (1 << 6)
/*
* Used as a flag in ref_update::flags when the ref_update was via an
* update to HEAD.
*/
#define REF_UPDATE_VIA_HEAD (1 << 8)
/*
* Used as a flag in ref_update::flags when a reference has been
* deleted and the ref's parent directories may need cleanup.
*/
#define REF_DELETED_RMDIR (1 << 9)
/*
* Used to indicate that the reflog-only update has been created via
* `split_head_update()`.
*/
#define REF_LOG_VIA_SPLIT (1 << 14)
struct ref_lock {
char * ref_name ;
struct lock_file lk ;
struct object_id old_oid ;
unsigned int count ; /* track users of the lock (ref update + reflog updates) */
};
struct files_ref_store {
struct ref_store base ;
unsigned int store_flags ;
char * gitcommondir ;
enum log_refs_config log_all_ref_updates ;
int prefer_symlink_refs ;
struct ref_cache * loose ;
struct ref_store * packed_ref_store ;
};
static void clear_loose_ref_cache ( struct files_ref_store * refs )
{
if ( refs -> loose ) {
free_ref_cache ( refs -> loose );
refs -> loose = NULL ;
}
}
/*
* Create a new submodule ref cache and add it to the internal
* set of caches.
*/
static struct ref_store * files_ref_store_init ( struct repository * repo ,
const char * payload ,
const char * gitdir ,
unsigned int flags )
{
struct files_ref_store * refs = xcalloc ( 1 , sizeof ( * refs ));
struct ref_store * ref_store = ( struct ref_store * ) refs ;
struct strbuf ref_common_dir = STRBUF_INIT ;
struct strbuf refdir = STRBUF_INIT ;
bool is_worktree ;
refs_compute_filesystem_location ( gitdir , payload , & is_worktree , & refdir ,
& ref_common_dir );
base_ref_store_init ( ref_store , repo , refdir . buf , & refs_be_files );
refs -> store_flags = flags ;
refs -> gitcommondir = strbuf_detach ( & ref_common_dir , NULL );
refs -> packed_ref_store =
packed_ref_store_init ( repo , NULL , refs -> gitcommondir , flags );
refs -> log_all_ref_updates = repo_settings_get_log_all_ref_updates ( repo );
repo_config_get_bool ( repo , "core.prefersymlinkrefs" , & refs -> prefer_symlink_refs );
chdir_notify_reparent ( "files-backend $GIT_DIR" , & refs -> base . gitdir );
chdir_notify_reparent ( "files-backend $GIT_COMMONDIR" ,
& refs -> gitcommondir );
strbuf_release ( & refdir );
return ref_store ;
}
/*
* Die if refs is not the main ref store. caller is used in any
* necessary error messages.
*/
static void files_assert_main_repository ( struct files_ref_store * refs ,
const char * caller )
{
if ( refs -> store_flags & REF_STORE_MAIN )
return ;
BUG ( "operation %s only allowed for main ref store" , caller );
}
/*
* Downcast ref_store to files_ref_store. Die if ref_store is not a
* files_ref_store. required_flags is compared with ref_store's
* store_flags to ensure the ref_store has all required capabilities.
* "caller" is used in any necessary error messages.
*/
static struct files_ref_store * files_downcast ( struct ref_store * ref_store ,
unsigned int required_flags ,
const char * caller )
{
struct files_ref_store * refs ;
if ( ref_store -> be != & refs_be_files )
BUG ( "ref_store is type \"%s\" not \"files\" in %s" ,
ref_store -> be -> name , caller );
refs = ( struct files_ref_store * ) ref_store ;
if (( refs -> store_flags & required_flags ) != required_flags )
BUG ( "operation %s requires abilities 0x%x, but only have 0x%x" ,
caller , required_flags , refs -> store_flags );
return refs ;
}
static void files_ref_store_release ( struct ref_store * ref_store )
{
struct files_ref_store * refs = files_downcast ( ref_store , 0 , "release" );
free_ref_cache ( refs -> loose );
free ( refs -> gitcommondir );
ref_store_release ( refs -> packed_ref_store );
free ( refs -> packed_ref_store );
}
static void files_reflog_path ( struct files_ref_store * refs ,
struct strbuf * sb ,
const char * refname )
{
const char * bare_refname ;
const char * wtname ;
int wtname_len ;
enum ref_worktree_type wt_type = parse_worktree_ref (
refname , & wtname , & wtname_len , & bare_refname );
switch ( wt_type ) {
case REF_WORKTREE_CURRENT :
strbuf_addf ( sb , "%s/logs/%s" , refs -> base . gitdir , refname );
break ;
case REF_WORKTREE_SHARED :
case REF_WORKTREE_MAIN :
strbuf_addf ( sb , "%s/logs/%s" , refs -> gitcommondir , bare_refname );
break ;
case REF_WORKTREE_OTHER :
strbuf_addf ( sb , "%s/worktrees/%.*s/logs/%s" , refs -> gitcommondir ,
wtname_len , wtname , bare_refname );
break ;
default :
BUG ( "unknown ref type %d of ref %s" , wt_type , refname );
}
}
static void files_ref_path ( struct files_ref_store * refs ,
struct strbuf * sb ,
const char * refname )
{
const char * bare_refname ;
const char * wtname ;
int wtname_len ;
enum ref_worktree_type wt_type = parse_worktree_ref (
refname , & wtname , & wtname_len , & bare_refname );
switch ( wt_type ) {
case REF_WORKTREE_CURRENT :
strbuf_addf ( sb , "%s/%s" , refs -> base . gitdir , refname );
break ;
case REF_WORKTREE_OTHER :
strbuf_addf ( sb , "%s/worktrees/%.*s/%s" , refs -> gitcommondir ,
wtname_len , wtname , bare_refname );
break ;
case REF_WORKTREE_SHARED :
case REF_WORKTREE_MAIN :
strbuf_addf ( sb , "%s/%s" , refs -> gitcommondir , bare_refname );
break ;
default :
BUG ( "unknown ref type %d of ref %s" , wt_type , refname );
}
}
/*
* Manually add refs/bisect, refs/rewritten and refs/worktree, which, being
* per-worktree, might not appear in the directory listing for
* refs/ in the main repo.
*/
static void add_per_worktree_entries_to_dir ( struct ref_dir * dir , const char * dirname )
{
const char * prefixes [] = { "refs/bisect/" , "refs/worktree/" , "refs/rewritten/" };
int ip ;
if ( strcmp ( dirname , "refs/" ))
return ;
for ( ip = 0 ; ip < ARRAY_SIZE ( prefixes ); ip ++ ) {
const char * prefix = prefixes [ ip ];
int prefix_len = strlen ( prefix );
struct ref_entry * child_entry ;
int pos ;
pos = search_ref_dir ( dir , prefix , prefix_len );
if ( pos >= 0 )
continue ;
child_entry = create_dir_entry ( dir -> cache , prefix , prefix_len );
add_entry_to_dir ( dir , child_entry );
}
}
static void loose_fill_ref_dir_regular_file ( struct files_ref_store * refs ,
const char * refname ,
struct ref_dir * dir )
{
struct object_id oid ;
int flag ;
const char * referent = refs_resolve_ref_unsafe ( & refs -> base ,
refname ,
RESOLVE_REF_READING ,
& oid , & flag );
if (! referent ) {
oidclr ( & oid , refs -> base . repo -> hash_algo );
flag |= REF_ISBROKEN ;
} else if ( is_null_oid ( & oid )) {
/*
* It is so astronomically unlikely
* that null_oid is the OID of an
* actual object that we consider its
* appearance in a loose reference
* file to be repo corruption
* (probably due to a software bug).
*/
flag |= REF_ISBROKEN ;
}
if ( check_refname_format ( refname , REFNAME_ALLOW_ONELEVEL )) {
if (! refname_is_safe ( refname ))
die ( "loose refname is dangerous: %s" , refname );
oidclr ( & oid , refs -> base . repo -> hash_algo );
flag |= REF_BAD_NAME | REF_ISBROKEN ;
}
if (!( flag & REF_ISSYMREF ))
referent = NULL ;
add_entry_to_dir ( dir , create_ref_entry ( refname , referent , & oid , flag ));
}
/*
* Read the loose references from the namespace dirname into dir
* (without recursing).  dirname must end with '/'.  dir must be the
* directory entry corresponding to dirname.
*/
static void loose_fill_ref_dir ( struct ref_store * ref_store ,
struct ref_dir * dir , const char * dirname )
{
struct files_ref_store * refs =
files_downcast ( ref_store , REF_STORE_READ , "fill_ref_dir" );
DIR * d ;
struct dirent * de ;
int dirnamelen = strlen ( dirname );
struct strbuf refname ;
struct strbuf path = STRBUF_INIT ;
files_ref_path ( refs , & path , dirname );
d = opendir ( path . buf );
if (! d ) {
strbuf_release ( & path );
return ;
}
strbuf_init ( & refname , dirnamelen + 257 );
strbuf_add ( & refname , dirname , dirnamelen );
while (( de = readdir ( d )) != NULL ) {
unsigned char dtype ;
if ( de -> d_name [ 0 ] == '.' )
continue ;
if ( ends_with ( de -> d_name , ".lock" ))
continue ;
strbuf_addstr ( & refname , de -> d_name );
dtype = get_dtype ( de , & path , 1 );
if ( dtype == DT_DIR ) {
strbuf_addch ( & refname , '/' );
add_entry_to_dir ( dir ,
create_dir_entry ( dir -> cache , refname . buf ,
refname . len ));
} else if ( dtype == DT_REG ) {
loose_fill_ref_dir_regular_file ( refs , refname . buf , dir );
}
strbuf_setlen ( & refname , dirnamelen );
}
strbuf_release ( & refname );
strbuf_release ( & path );
closedir ( d );
add_per_worktree_entries_to_dir ( dir , dirname );
}
static int for_each_root_ref ( struct files_ref_store * refs ,
int ( * cb )( const char * refname , void * cb_data ),
void * cb_data )
{
struct strbuf path = STRBUF_INIT , refname = STRBUF_INIT ;
struct dirent * de ;
int ret ;
DIR * d ;
files_ref_path ( refs , & path , "" );
d = opendir ( path . buf );
if (! d ) {
strbuf_release ( & path );
return -1 ;
}
while (( de = readdir ( d )) != NULL ) {
unsigned char dtype ;
if ( de -> d_name [ 0 ] == '.' )
continue ;
if ( ends_with ( de -> d_name , ".lock" ))
continue ;
strbuf_reset ( & refname );
strbuf_addstr ( & refname , de -> d_name );
dtype = get_dtype ( de , & path , 1 );
if ( dtype == DT_REG && is_root_ref ( de -> d_name )) {
ret = cb ( refname . buf , cb_data );
if ( ret )
goto done ;
}
}
ret = 0 ;
done :
strbuf_release ( & refname );
strbuf_release ( & path );
closedir ( d );
return ret ;
}
struct fill_root_ref_data {
struct files_ref_store * refs ;
struct ref_dir * dir ;
};
static int fill_root_ref ( const char * refname , void * cb_data )
{
struct fill_root_ref_data * data = cb_data ;
loose_fill_ref_dir_regular_file ( data -> refs , refname , data -> dir );
return 0 ;
}
/*
* Add root refs to the ref dir by parsing the directory for any files which
* follow the root ref syntax.
*/
static void add_root_refs ( struct files_ref_store * refs ,
struct ref_dir * dir )
{
struct fill_root_ref_data data = {
. refs = refs ,
. dir = dir ,
};
for_each_root_ref ( refs , fill_root_ref , & data );
}
static struct ref_cache * get_loose_ref_cache ( struct files_ref_store * refs ,
unsigned int flags )
{
if (! refs -> loose ) {
struct ref_dir * dir ;
/*
* Mark the top-level directory complete because we
* are about to read the only subdirectory that can
* hold references:
*/
refs -> loose = create_ref_cache ( & refs -> base , loose_fill_ref_dir );
/* We're going to fill the top level ourselves: */
refs -> loose -> root -> flag &= ~ REF_INCOMPLETE ;
dir = get_ref_dir ( refs -> loose -> root );
if ( flags & REFS_FOR_EACH_INCLUDE_ROOT_REFS )
add_root_refs ( refs , dir );
/*
* Add an incomplete entry for "refs/" (to be filled
* lazily):
*/
add_entry_to_dir ( dir , create_dir_entry ( refs -> loose , "refs/" , 5 ));
}
return refs -> loose ;
}
static int read_ref_internal ( struct ref_store * ref_store , const char * refname ,
struct object_id * oid , struct strbuf * referent ,
unsigned int * type , int * failure_errno , int skip_packed_refs )
{
struct files_ref_store * refs =
files_downcast ( ref_store , REF_STORE_READ , "read_raw_ref" );
struct strbuf sb_contents = STRBUF_INIT ;
struct strbuf sb_path = STRBUF_INIT ;
const char * path ;
const char * buf ;
struct stat st ;
int fd ;
int ret = -1 ;
int remaining_retries = 3 ;
int myerr = 0 ;
* type = 0 ;
strbuf_reset ( & sb_path );
files_ref_path ( refs , & sb_path , refname );
path = sb_path . buf ;
stat_ref :
/*
* We might have to loop back here to avoid a race
* condition: first we lstat() the file, then we try
* to read it as a link or as a file.  But if somebody
* changes the type of the file (file <-> directory
* <-> symlink) between the lstat() and reading, then
* we don't want to report that as an error but rather
* try again starting with the lstat().
*
* We'll keep a count of the retries, though, just to avoid
* any confusing situation sending us into an infinite loop.
*/
if ( remaining_retries -- <= 0 )
goto out ;
if ( lstat ( path , & st ) < 0 ) {
int ignore_errno ;
myerr = errno ;
if ( myerr != ENOENT || skip_packed_refs )
goto out ;
if ( refs_read_raw_ref ( refs -> packed_ref_store , refname , oid ,
referent , type , & ignore_errno )) {
myerr = ENOENT ;
goto out ;
}
ret = 0 ;
goto out ;
}
/* Follow "normalized" - ie "refs/.." symlinks by hand */
if ( S_ISLNK ( st . st_mode )) {
strbuf_reset ( & sb_contents );
if ( strbuf_readlink ( & sb_contents , path , st . st_size ) < 0 ) {
myerr = errno ;
if ( myerr == ENOENT || myerr == EINVAL )
/* inconsistent with lstat; retry */
goto stat_ref ;
else
goto out ;
}
if ( starts_with ( sb_contents . buf , "refs/" ) &&
! check_refname_format ( sb_contents . buf , 0 )) {
strbuf_swap ( & sb_contents , referent );
* type |= REF_ISSYMREF ;
ret = 0 ;
goto out ;
}
/*
* It doesn't look like a refname; fall through to just
* treating it like a non-symlink, and reading whatever it
* points to.
*/
}
/* Is it a directory? */
if ( S_ISDIR ( st . st_mode )) {
int ignore_errno ;
/*
* Even though there is a directory where the loose
* ref is supposed to be, there could still be a
* packed ref:
*/
if ( skip_packed_refs ||
refs_read_raw_ref ( refs -> packed_ref_store , refname , oid ,
referent , type , & ignore_errno )) {
myerr = EISDIR ;
goto out ;
}
ret = 0 ;
goto out ;
}
/*
* Anything else, just open it and try to use it as
* a ref
*/
fd = open ( path , O_RDONLY );
if ( fd < 0 ) {
myerr = errno ;
if ( myerr == ENOENT && ! S_ISLNK ( st . st_mode ))
/* inconsistent with lstat; retry */
goto stat_ref ;
else
goto out ;
}
strbuf_reset ( & sb_contents );
if ( strbuf_read ( & sb_contents , fd , 256 ) < 0 ) {
myerr = errno ;
close ( fd );
goto out ;
}
close ( fd );
strbuf_rtrim ( & sb_contents );
buf = sb_contents . buf ;
ret = parse_loose_ref_contents ( ref_store -> repo -> hash_algo , buf ,
oid , referent , type , NULL , & myerr );
out :
if ( ret && ! myerr )
BUG ( "returning non-zero %d, should have set myerr!" , ret );
* failure_errno = myerr ;
strbuf_release ( & sb_path );
strbuf_release ( & sb_contents );
errno = 0 ;
return ret ;
}
static int files_read_raw_ref ( struct ref_store * ref_store , const char * refname ,
struct object_id * oid , struct strbuf * referent ,
unsigned int * type , int * failure_errno )
{
return read_ref_internal ( ref_store , refname , oid , referent , type , failure_errno , 0 );
}
static int files_read_symbolic_ref ( struct ref_store * ref_store , const char * refname ,
struct strbuf * referent )
{
struct object_id oid ;
int failure_errno , ret ;
unsigned int type ;
ret = read_ref_internal ( ref_store , refname , & oid , referent , & type , & failure_errno , 1 );
if (! ret && !( type & REF_ISSYMREF ))
return NOT_A_SYMREF ;
return ret ;
}
int parse_loose_ref_contents ( const struct git_hash_algo * algop ,
const char * buf , struct object_id * oid ,
struct strbuf * referent , unsigned int * type ,
const char * * trailing , int * failure_errno )
{
const char * p ;
if ( skip_prefix ( buf , "ref:" , & buf )) {
while ( isspace ( * buf ))
buf ++ ;
strbuf_reset ( referent );
strbuf_addstr ( referent , buf );
* type |= REF_ISSYMREF ;
return 0 ;
}
/*
* FETCH_HEAD has additional data after the sha.
*/
if ( parse_oid_hex_algop ( buf , oid , & p , algop ) ||
( * p != '\0' && ! isspace ( * p ))) {
* type |= REF_ISBROKEN ;
* failure_errno = EINVAL ;
return -1 ;
}
if ( trailing )
* trailing = p ;
return 0 ;
}
static void unlock_ref ( struct ref_lock * lock )
{
lock -> count -- ;
if (! lock -> count ) {
rollback_lock_file ( & lock -> lk );
free ( lock -> ref_name );
free ( lock );
}
}
/*
* Check if the transaction has another update with a case-insensitive refname
* match.
*
* If the update is part of the transaction, we only check up to that index.
* Further updates are expected to call this function to match previous indices.
*/
static bool transaction_has_case_conflicting_update ( struct ref_transaction * transaction ,
struct ref_update * update )
{
for ( size_t i = 0 ; i < transaction -> nr ; i ++ ) {
if ( transaction -> updates [ i ] == update )
break ;
if (! strcasecmp ( transaction -> updates [ i ] -> refname , update -> refname ))
return true;
}
return false;
}
/*
* Lock refname, without following symrefs, and set *lock_p to point
* at a newly-allocated lock object. Fill in lock->old_oid, referent,
* and type similarly to read_raw_ref().
*
* The caller must verify that refname is a "safe" reference name (in
* the sense of refname_is_safe()) before calling this function.
*
* If the reference doesn't already exist, verify that refname doesn't
* have a D/F conflict with any existing references. extras and skip
* are passed to refs_verify_refname_available() for this check.
*
* If mustexist is not set and the reference is not found or is
* broken, lock the reference anyway but clear old_oid.
*
* Return 0 on success. On failure, write an error message to err and
* return REF_TRANSACTION_ERROR_NAME_CONFLICT or REF_TRANSACTION_ERROR_GENERIC.
*
* Implementation note: This function is basically
*
*     lock reference
*     read_raw_ref()
*
* but it includes a lot more code to
* - Deal with possible races with other processes
* - Avoid calling refs_verify_refname_available() when it can be
*   avoided, namely if we were successfully able to read the ref
* - Generate informative error messages in the case of failure
*/
static enum ref_transaction_error lock_raw_ref ( struct files_ref_store * refs ,
struct ref_transaction * transaction ,
size_t update_idx ,
int mustexist ,
struct string_list * refnames_to_check ,
struct ref_lock * * lock_p ,
struct strbuf * referent ,
struct strbuf * err )
{
enum ref_transaction_error ret = REF_TRANSACTION_ERROR_GENERIC ;
struct ref_update * update = transaction -> updates [ update_idx ];
const struct string_list * extras = & transaction -> refnames ;
const char * refname = update -> refname ;
unsigned int * type = & update -> type ;
struct ref_lock * lock ;
struct strbuf ref_file = STRBUF_INIT ;
int attempts_remaining = 3 ;
int failure_errno ;
assert ( err );
files_assert_main_repository ( refs , "lock_raw_ref" );
* type = 0 ;
/* First lock the file so it can't change out from under us. */
* lock_p = CALLOC_ARRAY ( lock , 1 );
lock -> ref_name = xstrdup ( refname );
lock -> count = 1 ;
files_ref_path ( refs , & ref_file , refname );
retry :
switch ( safe_create_leading_directories ( the_repository , ref_file . buf )) {
case SCLD_OK :
break ; /* success */
case SCLD_EXISTS :
/*
* Suppose refname is "refs/foo/bar". We just failed
* to create the containing directory, "refs/foo",
* because there was a non-directory in the way. This
* indicates a D/F conflict, probably because of
* another reference such as "refs/foo". There is no
* reason to expect this error to be transitory.
*/
if ( refs_verify_refname_available ( & refs -> base , refname ,
extras , NULL , 0 , err )) {
if ( mustexist ) {
/*
* To the user the relevant error is
* that the "mustexist" reference is
* missing:
*/
strbuf_reset ( err );
strbuf_addf ( err , "unable to resolve reference '%s'" ,
refname );
ret = REF_TRANSACTION_ERROR_NONEXISTENT_REF ;
} else {
/*
* The error message set by
* refs_verify_refname_available() is
* OK.
*/
ret = REF_TRANSACTION_ERROR_NAME_CONFLICT ;
}
} else {
/*
* The file that is in the way isn't a loose
* reference. Report it as a low-level
* failure.
*/
strbuf_addf ( err , "unable to create lock file %s.lock; "
"non-directory in the way" ,
ref_file . buf );
}
goto error_return ;
case SCLD_VANISHED :
/* Maybe another process was tidying up. Try again. */
if ( -- attempts_remaining > 0 )
goto retry ;
/* fall through */
default :
strbuf_addf ( err , "unable to create directory for %s" ,
ref_file . buf );
goto error_return ;
}
if ( hold_lock_file_for_update_timeout (
& lock -> lk , ref_file . buf , LOCK_NO_DEREF ,
get_files_ref_lock_timeout_ms ()) < 0 ) {
int myerr = errno ;
errno = 0 ;
if ( myerr == ENOENT && -- attempts_remaining > 0 ) {
/*
* Maybe somebody just deleted one of the
* directories leading to ref_file.  Try
* again:
*/
goto retry ;
} else {
unable_to_lock_message ( ref_file . buf , myerr , err );
if ( myerr == EEXIST ) {
if ( ignore_case &&
transaction_has_case_conflicting_update ( transaction , update )) {
/*
* In case-insensitive filesystems, ensure that conflicts within a
* given transaction are handled. Pre-existing refs on a
* case-insensitive system will be overridden without any issue.
*/
ret = REF_TRANSACTION_ERROR_CASE_CONFLICT ;
} else {
/*
* Pre-existing case-conflicting reference locks should also be
* specially categorized to avoid failing all batched updates.
*/
ret = REF_TRANSACTION_ERROR_CREATE_EXISTS ;
}
}
goto error_return ;
}
}
/*
* Now we hold the lock and can read the reference without
* fear that its value will change.
*/
if ( files_read_raw_ref ( & refs -> base , refname , & lock -> old_oid , referent ,
type , & failure_errno )) {
struct string_list_item * item ;
if ( failure_errno == ENOENT ) {
if ( mustexist ) {
/* Garden variety missing reference. */
strbuf_addf ( err , "unable to resolve reference '%s'" ,
refname );
ret = REF_TRANSACTION_ERROR_NONEXISTENT_REF ;
goto error_return ;
} else {
/*
* Reference is missing, but that's OK. We
* know that there is not a conflict with
* another loose reference because
* (supposing that we are trying to lock
* reference "refs/foo/bar"):
*
* - We were successfully able to create
*   the lockfile refs/foo/bar.lock, so we
*   know there cannot be a loose reference
*   named "refs/foo".
*
* - We got ENOENT and not EISDIR, so we
*   know that there cannot be a loose
*   reference named "refs/foo/bar/baz".
*/
}
} else if ( failure_errno == EISDIR ) {
/*
* There is a directory in the way. It might have
* contained references that have been deleted. If
* we don't require that the reference already
* exists, try to remove the directory so that it
* doesn't cause trouble when we want to rename the
* lockfile into place later.
*/
if ( mustexist ) {
/* Garden variety missing reference. */
strbuf_addf ( err , "unable to resolve reference '%s'" ,
refname );
ret = REF_TRANSACTION_ERROR_NONEXISTENT_REF ;
goto error_return ;
} else if ( remove_dir_recursively ( & ref_file ,
REMOVE_DIR_EMPTY_ONLY )) {
ret = REF_TRANSACTION_ERROR_NAME_CONFLICT ;
if ( refs_verify_refname_available (
& refs -> base , refname ,
extras , NULL , 0 , err )) {
/*
* The error message set by
* verify_refname_available() is OK.
*/
goto error_return ;
} else {
/*
* Directory conflicts can occur if there
* is an existing lock file in the directory
* or if the filesystem is case-insensitive
* and the directory contains a valid reference
* but conflicts with the update.
*/
strbuf_addf ( err , "there is a non-empty directory '%s' "
"blocking reference '%s'" ,
ref_file . buf , refname );
goto error_return ;
}
}
} else if ( failure_errno == EINVAL && ( * type & REF_ISBROKEN )) {
strbuf_addf ( err , "unable to resolve reference '%s': "
"reference broken" , refname );
goto error_return ;
} else {
strbuf_addf ( err , "unable to resolve reference '%s': %s" ,
refname , strerror ( failure_errno ));
goto error_return ;
}
/*
* If the ref did not exist and we are creating it, we have to
* make sure there is no existing packed ref that conflicts
* with refname. This check is deferred so that we can batch it.
*
* For case-insensitive filesystems, we should also check for F/D
* conflicts between 'foo' and 'Foo/bar'. So let's lowercase
* the refname.
*/
if ( ignore_case ) {
struct strbuf lower = STRBUF_INIT ;
strbuf_addstr ( & lower , refname );
strbuf_tolower ( & lower );
item = string_list_append_nodup ( refnames_to_check ,
strbuf_detach ( & lower , NULL ));
} else {
item = string_list_append ( refnames_to_check , refname );
}
item -> util = xmalloc ( sizeof ( update_idx ));
memcpy ( item -> util , & update_idx , sizeof ( update_idx ));
}
ret = 0 ;
goto out ;
error_return :
unlock_ref ( lock );
* lock_p = NULL ;
out :
strbuf_release ( & ref_file );
return ret ;
}
struct files_ref_iterator {
struct ref_iterator base ;
struct ref_iterator * iter0 ;
struct repository * repo ;
unsigned int flags ;
};
static int files_ref_iterator_advance ( struct ref_iterator * ref_iterator )
{
struct files_ref_iterator * iter =
( struct files_ref_iterator * ) ref_iterator ;
int ok ;
while (( ok = ref_iterator_advance ( iter -> iter0 )) == ITER_OK ) {
if ( iter -> flags & REFS_FOR_EACH_PER_WORKTREE_ONLY &&
parse_worktree_ref ( iter -> iter0 -> ref . name , NULL , NULL ,
NULL ) != REF_WORKTREE_CURRENT )
continue ;
if (( iter -> flags & REFS_FOR_EACH_OMIT_DANGLING_SYMREFS ) &&
( iter -> iter0 -> ref . flags & REF_ISSYMREF ) &&
( iter -> iter0 -> ref . flags & REF_ISBROKEN ))
continue ;
if (!( iter -> flags & REFS_FOR_EACH_INCLUDE_BROKEN ) &&
! ref_resolves_to_object ( iter -> iter0 -> ref . name ,
iter -> repo ,
iter -> iter0 -> ref . oid ,
iter -> iter0 -> ref . flags ))
continue ;
iter -> base . ref = iter -> iter0 -> ref ;
return ITER_OK ;
}
return ok ;
}
static int files_ref_iterator_seek ( struct ref_iterator * ref_iterator ,
const char * refname , unsigned int flags )
{
struct files_ref_iterator * iter =
( struct files_ref_iterator * ) ref_iterator ;
return ref_iterator_seek ( iter -> iter0 , refname , flags );
}
static void files_ref_iterator_release ( struct ref_iterator * ref_iterator )
{
struct files_ref_iterator * iter =
View remainder of file in raw view
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
<!-- content-sha256: sha256:802a0b93817bf7d26df7d389e46002c91192c622cb9d85fda86b1db0a2d727e1 -->
<!-- FUM-MD-RECENCY:END -->
