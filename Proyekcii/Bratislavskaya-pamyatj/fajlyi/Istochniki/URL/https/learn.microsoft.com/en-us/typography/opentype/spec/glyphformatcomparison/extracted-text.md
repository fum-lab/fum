# Извлечённый текст

Источник: <https://learn.microsoft.com/en-us/typography/opentype/spec/glyphformatcomparison>

## Содержимое

Comparison of 'glyf', 'CFF ' and CFF2 tables  (OpenType 1.9.1) - Typography | Microsoft Learn
Skip to main content Skip to Ask Learn chat experience
This browser is no longer supported.
Upgrade to Microsoft Edge to take advantage of the latest features, security updates, and technical support.
Download Microsoft Edge More info about Internet Explorer and Microsoft Edge
Table of contents Exit editor mode
Ask Learn Ask Learn
Reading mode Table of contents Read in English Add Add to Plans Edit Copy Markdown Print
Note
Access to this page requires authorization. You can try signing in or changing directories .
Access to this page requires authorization. You can try changing directories .
Comparison of 'glyf', 'CFF ' and CFF2 tables
Feedback
Summarize this article for me
In this article
Three alternate formats are available for storing monochrome glyph outlines in OpenType fonts: the 'glyf' table, the 'CFF ' table, and the CFF2 table. A functioning OpenType font must contain one of these tables. This section provides a comparison of these alternate formats for glyph data.
CFF2 and CFF use cubic (3rd order) Bézier curves to represent glyph outlines, whereas the 'glyf' table uses quadratic (2nd order) Bézier curves. CFF2 and CFF also use a different conceptual model for “hints” than the 'glyf' table. The three tables also differ in relation to support of variations and in how variation data is stored.
The following table provides a summary comparison of the CFF2, 'CFF ' and 'glyf' tables. Note that some of these differences might not be exposed in high-level font editing software or in runtime programming interfaces.
Consideration glyf CFF CFF2
curves quadratic (2nd order) Bézier cubic (3rd order) Bézier cubic (3rd order) Bézier
coordinate precision 1 design unit 1/65536 design unit 1/65536 design unit
de-duplication contours can be shared by multiple glyphs using composite glyphs CharString data can be shared by multiple glyphs using subroutines CharString data can be shared by multiple glyphs using subroutines
hinting TrueType instructions move outline points by controlled amounts alignment zones apply to all glyphs, stem locations are declared in each glyph alignment zones apply to arbitrary groups of glyphs, stem locations are declared in each glyph
decoding not stack-based (except TrueType instructions) mostly stack-based mostly stack-based
OpenType variations supported: outline variation data is stored in the 'gvar' table (OFF: 7.3.4); hint variation data is stored in the 'cvar' table (OFF: 7.3.2) not supported supported: variation data for outlines and hints is stored within the CFF2 table, partially using common formats for variation data also used in other tables, and partially interleaved within the CharString data for individual glyph descriptions
data redundancy low moderate low
overlapping contours supported not supported supported
Other CFF2 versus CFF differences
The CFF2 format was changed from the CFF format to consolidate with other parts of the OpenType format, to eliminate data not needed within an OpenType font, and to support OpenType Font Variations. The following are key differences.
FontSets are not supported in a CFF2 table. Accordingly, a CFF2 table may contain only one TopDICT, and a TopDICT INDEX is not supported.
Name INDEX and String INDEX are not supported in the CFF2 table.
Encoding and charset tables are not supported in CFF2. The corresponding TopDICT operators are removed, along with several other TopDICT operators.
CFF2 CharStrings do not contain a value for advance width.
For CFF2 tables, the fill rule for CharStrings must always be the nonzero winding number rule, rather than the even-odd rule. This is required in order to support variable font data, in which it is not practical to enforce removal of overlaps between paths.
For CFF2, the CharString stack depth is increased from 48 to 513.
The PrivateDICT and CharString operator sets are extended in CFF2 to include blend and vsindex operators.
The Type 2 endchar and return CharString operators are removed from CFF2, as well as all logic, storage and math operators.
Collaborate with us on GitHub
The source for this content can be found on GitHub, where you can also create and review issues and pull requests. For more information, see our contributor guide .
OpenType specification
Open a documentation issue Provide product feedback
Feedback
Was this page helpful?
Yes No No
Need help with this topic?
Want to try using Ask Learn to clarify or guide you through this topic?
Ask Learn Ask Learn
Suggest a fix?
Additional resources
Last updated on 2024-05-31
In this article
Was this page helpful?
Need help with this topic?
Want to try using Ask Learn to clarify or guide you through this topic?
Ask Learn Ask Learn
Suggest a fix?
en-us
Your Privacy Choices
Theme
Light
Dark
High contrast
AI Disclaimer
Previous Versions
Blog
Contribute
Privacy
Consumer Health Privacy
Terms of Use
Trademarks
© Microsoft 2026

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 21:41:45 MSK -->
<!-- content-sha256: sha256:48b75ca104b505d4e46b851dbddf3be6139f064b9e9c648476378d03478c9370 -->
<!-- FUM-MD-RECENCY:END -->
