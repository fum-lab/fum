# Извлечённый текст

Источник: <https://learn.microsoft.com/en-us/typography/opentype/spec/otff>

## Содержимое

OpenType font file (OpenType 1.9.1) - Typography | Microsoft Learn
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
The OpenType Font File
Feedback
Summarize this article for me
In this article
An OpenType font file contains data, in table format, used for rendering of text. Portions of the data are used by applications to calculate the layout of text using the font; that is, the selection of glyphs and their placement within a line. Other data provide descriptions of glyphs as TrueType or Compact Font Format (CFF) outlines. Still other data can provide monochromatic or color bitmaps, SVG documents or binary, 2D vector graphics compositions as alternate glyph descriptions. The font data also includes meta-information, such as name strings that can be used to present the font as an available choice in a font-picker user interface. Each of these types of data is stored in one or more tables, each designed for a particular purpose.
Filenames
OpenType font files may have the extension .OTF, .TTF, .OTC or .TTC. (The extension may be upper or lower case.) The extensions .OTC and .TTC should only be used for font collection files. For additional information on filename extension conventions, see “Filenames” in Recommendations for OpenType fonts .
Data Types
The following data types are used in the OpenType font file. All OpenType fonts use big-endian (network) byte order:
Data Type Description
uint8 8-bit unsigned integer.
int8 8-bit signed integer.
uint16 16-bit unsigned integer.
int16 16-bit signed integer.
uint24 24-bit unsigned integer.
uint32 32-bit unsigned integer.
int32 32-bit signed integer.
Fixed 32-bit signed fixed-point number (16.16)
FWORD int16 that describes a quantity in font design units.
UFWORD uint16 that describes a quantity in font design units.
F2DOT14 16-bit signed fixed number with the low 14 bits of fraction (2.14).
LONGDATETIME Date and time represented in number of seconds since 12:00 midnight, January 1, 1904, UTC. The value is represented as a signed 64-bit integer.
Tag Array of four uint8s (length = 32 bits) used to identify a table, design-variation axis, script, language system, feature, or baseline.
Offset8 8-bit offset to a table, same as uint8, NULL offset = 0x00
Offset16 Short offset to a table, same as uint16, NULL offset = 0x0000
Offset24 24-bit offset to a table, same as uint24, NULL offset = 0x000000
Offset32 Long offset to a table, same as uint32, NULL offset = 0x00000000
Version16Dot16 Packed 32-bit value with major and minor version numbers. (See Table Version Numbers .)
The F2DOT14 format consists of a signed, 2’s complement integer and an unsigned fraction. To compute the actual value, take the integer and add the fraction. Examples of 2.14 values are:
Decimal Value Hex Value Integer Fraction
1.999939 0x7fff 1 16383/16384
1.75 0x7000 1 12288/16384
0.000061 0x0001 0 1/16384
0.0 0x0000 0 0/16384
-0.000061 0xffff -1 16383/16384
-2.0 0x8000 -2 0/16384
A Tag value is a uint8 array. Each byte within the array must have a value in the range 0x20 to 0x7E. This corresponds to the range of values of Unicode Basic Latin characters in UTF-8 encoding, which is the same as the printable ASCII characters. As a result, a Tag value can be re-interpreted as a four-character sequence, which is conventionally how they are referred to. Formally, however, the value is a byte array. When re-interpreted as characters, the Tag value is case sensitive. It must have one to four non-space characters, padded with trailing spaces (byte value 0x20). A space character must not be followed by a non-space character.
Within this specification, many structures are defined in terms of the data types listed above. Structures are characterized as either records or tables . The distinction between records and tables is based on these general criteria:
Tables are referenced by offsets. If a table contains an offset to a sub-structure, the offset is normally from the start of that table.
Records occur sequentially within a parent structure, either within a sequence of table fields or within an array of records of a given type. If a record contains an offset to a sub-structure, that structure is logically a subtable of the record’s parent table and the offset is normally from the start of the parent table.
In some cases, fields for subtable offsets are documented as permitting NULL values when the given subtable is optional. For example, in the BASE table header , the horizAxisOffset and vertAxisOffset fields may be NULL, meaning that either subtable (or both) is optional. A NULL subtable offset always indicates that the given subtable is not present. Applications must never interpret a NULL offset value as the offset to subtable data. For cases in which subtable offset fields are not documented as permitting NULL values, font compilers must include a subtable of the indicated format, even if it is a header stub without further data (for example, a coverage table with no glyph IDs). Applications parsing font data should, however, anticipate non-conformant font data that has a NULL subtable offset where only a non-NULL value is expected.
Table Version Numbers
Most tables have version numbers, and the version number for the entire font is contained in the table directory . Note that there are five different table version number types, each with its own numbering scheme.
A single uint16 field. This is used in a number of tables, usually with versions starting at zero (0).
Separate, uint16 major and minor version fields. This is used in a number of tables, usually with versions starting at 1.0.
A uint32 field with enumerated values.
A uint32 field with a numeric value. This is used only in the DSIG and 'meta' tables.
A Version16Dot16 field for major/minor version numbers. This is used only in the 'maxp' , 'post' and 'vhea' tables.
The Version16Dot16 type is used for the version field of certain tables, and only for reasons of backward compatibility. (In earlier versions, these fields were documented as using a Fixed value, but had minor version numbers that did not follow the definition of the Fixed type.) Version16Dot16 is a packed value: the upper 16 bits comprise a major version number, and the lower 16 bits, a minor version. Non-zero minor version numbers are represented using digits 0 to 9 in the highest-order nibbles of the lower 16 bits. For example, the version field of 'maxp' table version 0.5 is 0x00005000, and that of 'vhea' table version 1.1 is 0x00011000. This type is used only in the 'maxp', 'post' and 'vhea' tables, and will not be used for any other tables in the future.
The table directory uses a uint32 field, sfntVersion, with an enumeration of defined values, some of which represent four-character tags; see the section below, “Organization of an OpenType Font”, for details.
Implementations reading tables must include code to check version numbers so that, if and when the format and version number changes, older implementations will handle newer versions gracefully.
Minor version number changes always imply format changes that are compatible extensions. If an implementation understands a major version number, then it can safely proceed with reading the table. If the minor version is greater than the latest version recognized by the implementation, then the extension fields will be undetectable to the implementation.
For purposes of compatibility, version numbers that are represented using a single uint16 or uint32 value are treated like a minor version number, and any format changes are compatible extensions.
Note that some field values that were undefined or reserved in an earlier revision may be assigned meanings in a minor version change. Implementations should never make assumptions regarding reserved or unassigned values or bits in bit fields, and can ignore them if encountered. When writing font data, tools should always write zero for reserved fields or bits. Validators should warn of any non-zero values for fields or bits that are not defined for the given version against which data is being validated.
If the major version is not recognized, the implementation must not read the table as it can make no assumptions regarding interpretation of the binary data. The implementation should treat the table as missing.
Organization of an OpenType Font
Table Directory
A key characteristic of the OpenType format is the TrueType sfnt “wrapper”, which provides organization for a collection of tables in a general and extensible manner.
The OpenType font starts with the table directory, which is a directory of the top-level tables in a font. If the font file contains only one font, the table directory will begin at byte 0 of the file. If the font file is an OpenType Font Collection file (see below), the beginning point of the table directory for each font is indicated in the TTCHeader.
TableDirectory:
Type Name Description
uint32 sfntVersion 0x00010000 or 0x4F54544F ('OTTO') — see below.
uint16 numTables Number of tables.
uint16 searchRange Maximum power of 2 less than or equal to numTables, times 16 ((2**floor(log2(numTables))) * 16, where “**” is an exponentiation operator).
uint16 entrySelector Log 2 of the maximum power of 2 less than or equal to numTables (log 2 (searchRange/16), which is equal to floor(log 2 (numTables))).
uint16 rangeShift numTables times 16, minus searchRange ((numTables * 16) - searchRange).
TableRecord tableRecords[numTables] Table records array—one for each top-level table in the font.
Note: In the preceding table, the symbol “**” is an exponentiation operator, as used in several programming languages.
OpenType fonts that contain TrueType outlines should use the value of 0x00010000 for sfntVersion. OpenType fonts containing CFF data (version 1 or 2) should use 0x4F54544F ('OTTO', when re-interpreted as a Tag) for sfntVersion.
Note: Apple's TrueType Reference Manual allows for 'true' and 'typ1' for sfntVersion. These version tags should not be used for OpenType fonts.
The table directory format allows for a large number of tables. To assist in quick binary searches, the searchRange, entrySelector and rangeShift fields are included as parameters that may be used in configuring search algorithms. Binary search is optimal when the number of entries is a power of two. The searchRange field provides the largest number of items that can be searched with that constraint (maximum power of two). The rangeShift field provides the remaining number of items that would also need to be searched. The entrySelector field indicates the maximum number of levels into the binary tree will need to be entered. Values are multiplied by 16, which is the size of each TableRecord.
In early implementations on devices with limited hardware capabilities, optimizations provided by the searchRange, entrySelector and rangeShift fields were of high importance. They have less importance on modern devices, but may still be used in some implementations. However, incorrect values could potentially be used as an attack vector against some implementations. Since these values can be derived from the numTables field when the file is parsed, it is strongly recommended that parsing implementations not rely on the searchRange, entrySelector and rangeShift fields in the font but derive them independently from numTables. Font files, however, should continue to provide valid values for these fields to maintain compatibility with all existing implementations.
The table directory ends with the tableRecords array. The TableRecord format is as follows.
TableRecord:
Type Name Description
Tag tableTag Table identifier.
uint32 checksum Checksum for this table.
Offset32 offset Offset from beginning of font file.
uint32 length Length of this table.
Table tags are the names given to tables in the OpenType font file. The tableRecords array makes it possible for a given font to contain only those tables it actually needs. As a result, there is no standard value for numTables. The records in the array must be sorted in ascending order by tag.
For requirements of Tag values, see Data Types , above. Several tags and their associated table formats are defined in this specification. For table tags defined in this specification, a font resource should have at most one table record using a given tag. If a font resource does contain more than one table of a given type, behaviour is unpredictable: apps or platforms may select one of the tables arbitrarily, or may reject the font as invalid.
Platform vendors may define additional tables and associated tags to provide platform-specific functionality See, for example, Apple’s TrueType Reference Manual which defines various tables with associated tags not defined in OpenType. Some font development tools may also define special tables. Fonts that contain such additional tables can still qualify as OpenType fonts if they satisfy the requirements of this specification. For custom tables defined outside this specification, an external specification of such a table may permit multiple tables of that type within a single font resource.
Note: Vendors should notify Microsoft when they define custom tags to ensure forward compatibility in the event of future expansion of OpenType.
Note: Apple’s specification stipulates that tag names consisting of all lower case letters are reserved for Apple’s use.
All tables must begin on four-byte boundaries, and any remaining space between tables must be padded with zeros. The length of each table should be recorded in the table record with the actual length of data, not the padded length.
Note: The requirement for four-byte alignment applies to top-level tables only and does not extend to sub-table offsets, records, or fields within tables or records.
Some tables have an internal structure with subtables located at specified offsets, and as a result, it is possible to construct a font with data for different tables interleaved. In general, tables should be arranged contiguously without overlapping the ranges of distinct tables. In any case, however, table lengths measure a contiguous range of bytes that encompasses all of the data for a table. This applies to any subtables as well as to top-level tables.
Calculating Checksums
Table checksums are the unsigned sum of the uint32 units of a given table. In C, the following function can be used to determine a checksum:
uint32
CalcTableChecksum(uint32 *Table, uint32 Length)
{
uint32 Sum = 0L;
uint32 *EndPtr = Table+((Length+3) & ~3) / sizeof(uint32);
while (Table < EndPtr)
Sum += *Table++;
return Sum;
}
Note: This function assumes that the length of any table is a multiple of four bytes, or that tables are padded with zero to four-byte aligned offsets. Actual table lengths recorded in the table directory should not include padding, however. To accommodate data with a length that is not a multiple of four, the above algorithm must be modified to treat the data as though it contains zero padding to a length that is a multiple of four.
The 'head' table is a special case in checksum calculations, as it includes a checksumAdjustment field that is calculated and written after the table’s checksum is calculated and written into the table directory entry, necessarily invalidating that checksum value.
When generating font data, to calculate and write the 'head' table checksum and checksumAdjustment field, do the following:
Set the checksumAdjustment field to 0.
Calculate the checksum for all tables including the 'head' table and enter the value for each table into the corresponding record in the table directory.
Calculate the checksum for the entire font.
Subtract that value from 0xB1B0AFBA.
Store the result in the 'head' table checksumAdjustment field.
An application attempting to verify that the 'head' table has not changed should calculate the checksum for that table assuming that the checksumAdjustment value is zero, rather than the actual value in the font, before comparing the result with the 'head' table record in the table directory.
Within a font collection file (see below), table checksums must reflect the tables as they are in the collection file. The checksumAdjustment field in the 'head' table is not used for collection files and may be set to zero.
Font Collections
An OpenType Font Collection (either TTC or OTC, formerly known as TrueType Collection) is a means of delivering multiple OpenType font resources in a single file structure. The format for font collections allows font tables that are identical between two or more fonts to be shared. Font collections containing outline glyph data (TrueType, CFF, CFF2 or SVG) are most useful when the fonts to be delivered together share many glyphs in common. By allowing multiple fonts to share glyph sets and other common font tables, font collections can result in a significant saving of file space.
For example, a group of Japanese fonts may each have their own designs for the kana glyphs, but share identical designs for the kanji. With ordinary OpenType font files, the only way to include the common kanji glyphs is to copy their glyph data into each font. Since the kanji represent much more data than the kana, this results in a great deal of wasteful duplication of glyph data. Font collections were defined to solve this problem.
Note: Even though the original definition of Font Collection (as part of the TrueType specification) was intended to be used with fonts containing TrueType outlines, and this constraint was maintained in earlier OpenType versions, this is no longer a constraint in OpenType. Font collection files may contain various types of outlines (or a mix of them), regardless of whether or not fonts have layout tables present. For backward compatibility and simplicity, the description of the font collection file structure is using the term “TrueType Collection”, or “TTC”, though it is understood that it is used to identify a generic font collection structure containing any type of outline tables.
Note: An OpenType variable font is functionally equivalent to multiple non-variable fonts. Variable fonts do not need to be contained within a collection file. A collection file can include one or even multiple variable fonts, however, and may even combine variable and non-variable fonts.
The Font Collection File Structure
A font collection file consists of a single TTC header table, one or more table directories (each corresponding to a different font resource), and a number of OpenType tables. The TTC header must be located at the beginning of the TTC file.
The TTC file must contain a complete table directory for each font resource. The same TableDirectory format is used for each font resource in a collection file as is used in a non-collection file. The table offsets in all table directories within a TTC file are measured from the beginning of the TTC file.
Each OpenType table in a TTC file is referenced through the table directory of each font which uses that table. Some of the OpenType tables must appear multiple times, once for each font included in the TTC; while other tables may be shared by multiple fonts in the TTC.
As an example, consider a TTC file which combines two Japanese fonts (Font1 and Font2). The fonts have different kana designs (Kana1 and Kana2) but use the same design for kanji. The TTC file contains a single 'glyf' table which includes both designs of kana together with the kanji; both fonts’ table directories point to this 'glyf' table. But each font’s table directory points to a different 'cmap' table, which identifies the glyph set to use. Font1’s 'cmap' table points to the Kana1 region of the 'loca' and 'glyf' tables for kana glyphs, and to the kanji region for the kanji. Font2’s 'cmap' table points to the Kana2 region of the 'loca' and 'glyf' tables for kana glyphs, and to the same kanji region for the kanji.
The tables that should have a unique copy per font are those that are used by the system in identifying the font and its character mapping, including 'cmap', 'name', and OS/2. The tables that should be shared by fonts in the TTC are those that define glyph and instruction data or use glyph indices to access data: 'glyf', 'loca', 'hmtx', 'hdmx', LTSH, 'cvt ', 'fpgm', 'prep', EBLC, EBDT, EBSC, 'maxp', and so on. In practice, any tables which have identical data for two or more fonts may be shared.
Note: When building a collection file from separate font files, close attention needs to be paid to the issue of glyph renumbering in a font and the side effects that can result in the 'cmap' table and elsewhere. The fonts to be merged also need to have compatible TrueType instructions; that is, their preprograms, function definitions, and control values cannot conflict.
Collection files containing TrueType glyph outlines should use the file extension .TTC. Collection files containing CFF or CFF2 outlines should use the file extension .OTC.
TTC Header
There are two versions of the TTC header: Version 1.0 has been used for TTC files without digital signatures. Version 2.0 can be used for TTC files with or without digital signatures — if there’s no signature, then the last three fields of the version 2.0 header are left null.
If a digital signature is used, the DSIG table for the file must be located at the end of the TTC file, following any other font tables. Signatures in a TTC file are expected to be Format 1 signatures.
The purpose of the TTC header table is to locate the different table directories within a TTC file. The TTC header is located at the beginning of the TTC file (offset = 0). It consists of an identification tag, a version number, a count of the number of OpenType fonts in the file, and an array of offsets to each table directory.
TTCHeader Version 1.0:
Type Name Description
Tag ttcTag Font Collection ID string: 'ttcf' (used for fonts with CFF or CFF2 outlines, as well as TrueType outlines)
uint16 majorVersion Major version of the TTCHeader, = 1.
uint16 minorVersion Minor version of the TTCHeader, = 0.
uint32 numFonts Number of fonts in TTC
Offset32 tableDirectoryOffsets[numFonts] Array of offsets to the TableDirectory for each font from the beginning of the file
TTCHeader Version 2.0:
Type Name Description
Tag ttcTag Font Collection ID string: 'ttcf'
uint16 majorVersion Major version of the TTCHeader, = 2.
uint16 minorVersion Minor version of the TTCHeader, = 0.
uint32 numFonts Number of fonts in TTC
Offset32 tableDirectoryOffsets[numFonts] Array of offsets to the TableDirectory for each font from the beginning of the file
uint32 dsigTag Tag indicating that a DSIG table exists, 0x44534947 ('DSIG') (null if no signature)
uint32 dsigLength The length (in bytes) of the DSIG table (null if no signature)
uint32 dsigOffset The offset (in bytes) of the DSIG table from the beginning of the TTC file (null if no signature)
Font Tables
Required Tables
Whether TrueType or CFF outlines are used in an OpenType font, the following tables are required for the font to function correctly:
Tag Name
'cmap' Character to glyph mapping
'head' Font header
'hhea' Horizontal header
'hmtx' Horizontal metrics
'maxp' Maximum profile
'name' Naming table
OS/2 OS/2 and Windows specific metrics
'post' PostScript information
Tables Related to TrueType Outlines
For OpenType fonts based on TrueType outlines, the following tables are used:
Tag Name
'cvt ' Control Value Table (optional table)
'fpgm' Font program (optional table)
'glyf' Glyph data
'loca' Index to location
'prep' Control Value Program (optional table)
'gasp' Grid-fitting/Scan-conversion (optional table)
Tables Related to CFF Outlines
For OpenType fonts based on CFF outlines, the following tables are used:
Tag Name
'CFF ' Compact Font Format 1.0
CFF2 Compact Font Format 2.0
VORG Vertical Origin (optional table)
It is strongly recommended that CFF OpenType fonts that are used for vertical writing include a Vertical Origin (VORG) table .
Table Related to SVG Outlines
Tag Name
'SVG ' The SVG (Scalable Vector Graphics) table
Tables Related to Bitmap Glyphs
Tag Name
EBDT Embedded bitmap data
EBLC Embedded bitmap location data
EBSC Embedded bitmap scaling data
CBDT Color bitmap data
CBLC Color bitmap location data
'sbix' Standard bitmap graphics
OpenType fonts may also contain bitmaps of glyphs, in addition to outlines. Hand-tuned bitmaps are especially useful in OpenType fonts for representing complex glyphs at very small sizes. If a bitmap for a particular size is provided in a font, it will be used by the system instead of the outline when rendering the glyph.
Advanced Typographic Tables
Several optional tables support advanced typographic functions:
Tag Name
BASE Baseline data
GDEF Glyph definition data
GPOS Glyph positioning data
GSUB Glyph substitution data
JSTF Justification data
MATH Math layout data
For information on common table formats, please see OpenType Layout Common Table Formats .
Tables used for OpenType Font Variations
Tag Name
'avar' Axis variations
'cvar' CVT variations (TrueType outlines only)
'fvar' Font variations
'gvar' Glyph variations (TrueType outlines only)
HVAR Horizontal metrics variations
MVAR Metrics variations
STAT Style attributes (required for variable fonts, optional for non-variable fonts)
VVAR Vertical metrics variations
For an overview of OpenType Font Variations and the specification of the interpolation algorithm used for variations, see OpenType Font Variations Overview . For details regarding which tables are required or optional in variable fonts, see Variation Data Tables and Miscellaneous Requirements in the Overview chapter.
For information on common table formats used for variations, see OpenType Font Variations Common Table Formats .
Note that some variation-related formats may be used in tables other than the variations-specific tables listed above. In particular, the GDEF, BASE or COLR tables in a variable font can include variation data using common table formats. A CFF2 table in a variable font can also include variation data, though using formats that are specific to the CFF2 table.
Tables Related to Color Fonts
Tag Name
COLR Color table
CPAL Color palette table
CBDT Color bitmap data
CBLC Color bitmap location data
'sbix' Standard bitmap graphics
'SVG ' The SVG (Scalable Vector Graphics) table
Note that several of these tables were also listed in other sections for tables related to SVG outlines, and for tables related to bitmap glyphs.
Other OpenType Tables
Tag Name
DSIG Digital signature
'hdmx' Horizontal device metrics
'kern' Kerning
LTSH Linear threshold data
MERG Merge
'meta' Metadata
STAT Style attributes
PCLT PCL 5 data
VDMX Vertical device metrics
'vhea' Vertical Metrics header
'vmtx' Vertical Metrics
Note that the STAT table is required in variable fonts. Also, the 'hdmx' and VDMX tables are not used in variable fonts.
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
Last updated on 2024-05-29
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
<!-- content-sha256: sha256:47677e0d33870b11715644433415a82decbb55b6ae2da21f42e0cf166185044f -->
<!-- FUM-MD-RECENCY:END -->
