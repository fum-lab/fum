# Извлечённый текст

Источник: <https://dev.mendeley.com/methods/>

## Содержимое

Mendeley API Reference NAV
cURL
Sign Up for a Developer Key
Documentation Powered by Slate
Introduction
This is the reference documentation for the Mendeley API.  It contains details of the endpoints that the API offers, and examples of how to use it.
For more information, see the developer portal .
When working with collections, paged results and ordering please consult the pagination section on our developer portal
Annotations
Annotation attributes
Attribute Type Description
id string identifier (UUID)
created string date the annotation was created.  This date is represented in ISO 8601 format.
last_modified string date the annotation was updated. This date is represented in ISO 8601 format.
color color RGB values
text string text value of the annotation
positions array of HighlightBox’s wrapper object contains page and coordinates of the annotation bounding box.
privacy_level string public, group or private.
document_id string UUID of the document which the file is attached to.
profile_id string UUID of the user that created the annotation.
filehash string filehash of which the annotation belongs to.
Retrieving annotations
curl 'https://api.mendeley.com/annotations' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-annotation.1+json' { "id" : "d6526d08-22f2-4c1f-b80b-092e6e3df528" , "color" : { "r" : 255, "g" : 255, "b" : 0 } , "text" : "This is a sticky note" , "positions" : [ { "top_left" : { "x" : 269.035, "y" : 695.428 } , "bottom_right" : { "x" : 269.035, "y" : 695.428 } , "page" : 1 } ] , "created" : "2011-10-07T14:19:09.000Z" , "last_modified" : "2011-10-07T14:19:37.000Z" , "privacy_level" : "private" , "filehash" : "bd3293b2-d20c-0d9f-3773-df51a506c7b2" , "document_id" : "2a3f09be-75b0-3bf9-bdbd-838c5e588969" , "profile_id" : "e2cc65ad-5ef2-3838-b934-737fdb3b196d" } AnnotationList annotationList = sdk . getAnnotations (); List < Annotation > annotations = annotationList . annotations ; Page next = annotationList . next ;
Retrieve all your annotations
HTTP Request
GET https://api.mendeley.com/annotations
URL Parameters
Parameter Type Description
group_id string UUID of the group you would like to get the annotations from. This will only return all the annotations in that group.
document_id string UUID of the document you would like to get the annotations from. This will only return the annotations associated with that document.
modified_since string returns only documents modified since this timestamp. Should be supplied in ISO 8601 format
deleted_since string returns only documents deleted since this timestamp. Should be supplied in ISO 8601 format
limit string the maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500
marker string a marker for the last key in the previous page (automatically generated, here for completeness)
Returns
Will return a paginated collection of all private annotations in your library.
Creating an annotation
curl 'https://api.mendeley.com/annotations' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-annotation.1+json' \ -H 'Accept: application/vnd.mendeley-annotation.1+json' \ --data-binary $' { "color" : { "r" : 255, "g" : 255, "b" : 0 } , "text" : "This is a sticky note" , "positions" : [ { "top_left" : { "x" : 269.035, "y" : 695.428 } , "bottom_right" : { "x" : 269.035, "y" : 695.428 } , "page" : 1 } ] , "privacy_level" : "private" , "filehash" : "bd3293b2-d20c-0d9f-3773-df51a506c7b2" , "document_id" : "2bf33ebd-7cd1-3786-903d-d74d04958e40" , "profile_id" : "e2cc65ad-5ef2-3838-b934-737fdb3b196d" } '
{
"id": "f2405d7a-466b-46f3-8f2f-ab57003dafcd",
"color": {
"r": 255,
"g": 255,
"b": 0
},
"text": "This is a sticky note",
"profile_id": "4afc0c0f-88ab-3aed-a20a-f50934fc83b1",
"positions": [
{
"top_left": {
"x": 269.035,
"y": 695.428
},
"bottom_right": {
"x": 269.035,
"y": 695.428
},
"page": 1
}
],
"created": "2014-07-03T11:17:11.868Z",
"last_modified": "2014-07-03T11:17:11.868Z",
"privacy_level": "private",
"filehash": "bd3293b2-d20c-0d9f-3773-df51a506c7b2",
"document_id": "2bf33ebd-7cd1-3786-903d-d74d04958e40"
} List < Box > positions = new ArrayList < Box >(); positions . add ( new Box ( new Point ( 269.035 , 695.428 ), new Point ( 269.035 , 695.428 ), 1 )); Annotation annotation = new Annotation . Builder () . setColor ( Color . rgb ( 255 , 255 , 0 )) . setText ( "This is a sticky note" ) . setPositions ( positions ) . setPrivacyLevel ( Annotation . PrivacyLevel . PRIVATE ) . setFileHash ( "bd3293b2-d20c-0d9f-3773-df51a506c7b2" ) . setDocumentId ( "2bf33ebd-7cd1-3786-903d-d74d04958e40" ) . setProfileId ( "e2cc65ad-5ef2-3838-b934-737fdb3b196d" ) . build (); sdk . postAnnotation ( annotation );
Creates a new annotation.
HTTP Request
POST https://api.mendeley.com/annotations
Returns
A 201 Created response containing the annotation object.
Updating an annotation
curl 'https://api.mendeley.com/annotations/f2405d7a-466b-46f3-8f2f-ab57003dafcd' -X PATCH
-H 'Authorization: Bearer <ACCESS_TOKEN>' -H 'Content-Type: application/vnd.mendeley-annotation.1+json' -H 'Accept: application/vnd.mendeley-annotation.1+json' --data-binary $' { "text" : "My new sticky note" } '
{
"id": "f2405d7a-466b-46f3-8f2f-ab57003dafcd",
"color": {
"r": 255,
"g": 255,
"b": 0
},
"text": "My new sticky note",
"profile_id": "4afc0c0f-88ab-3aed-a20a-f50934fc83b1",
"positions": [
{
"top_left": {
"x": 269.035,
"y": 695.428
},
"bottom_right": {
"x": 269.035,
"y": 695.428
},
"page": 1
}
],
"created": "2014-07-03T11:17:11.868Z",
"last_modified": "2014-07-03T11:26:07.311Z",
"privacy_level": "private",
"filehash": "bd3293b2-d20c-0d9f-3773-df51a506c7b2",
"document_id": "2bf33ebd-7cd1-3786-903d-d74d04958e40"
} Annotation amendment = new Annotation . Builder (). setColor ( Color . rgb ( 128 , 0 , 128 )). build (); sdk . patchAnnotation ( "f2405d7a-466b-46f3-8f2f-ab57003dafcd" , amendment );
Updates a specific annotation. Any parameters not provided will be left unchanged. The fields that can be updated are: text, color, positions, privacy_level and filehash.
HTTP Request
PATCH https://api.mendeley.com/annotations/{id}
URL Parameters
Parameter Type Description
id string annotations unique id
Returns
A 200 OK response containing the annotation object.
Deleting an annotation
curl 'https://api.mendeley.com/annotations/f2405d7a-466b-46f3-8f2f-ab57003dafcd' \ -X DELETE \ -H 'Authorization: Bearer <ACCESS_TOKEN>' sdk . deleteAnnotation ( "f2405d7a-466b-46f3-8f2f-ab57003dafcd" );
Deletes an annotation
HTTP Request
DELETE https://api.mendeley.com/annotations/{id}
URL Parameters
Parameter Type Description
id string annotations unique id
Returns
If the request is successful then the server will return a 204 No Content response.
Academic Statuses
Retrieve all academic statuses
Retrieves all academic statuses.
curl 'https://api.mendeley.com/academic_statuses' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.academic_status.1+json' [ { "description" : "Post Doc" } , { "description" : "Doctoral Student" } , { "description" : "Ph.D. Student" } , { "description" : "Student (Postgraduate)" } , { "description" : "Student (Master)" } , { "description" : "Student (Bachelor)" } , { "description" : "Professor" } , { "description" : "Associate Professor" } , { "description" : "Assistant Professor" } , { "description" : "Senior Lecturer" } , { "description" : "Lecturer" } , { "description" : "Researcher (at an Academic Institution)" } , { "description" : "Librarian" } , { "description" : "Researcher (at a non-Academic Institution)" } , { "description" : "Other Professional" } ] Not implemented . Not implemented .
HTTP Request
GET https://api.mendeley.com/academic_statuses
Returns
A 200 OK response containing a all academic statuses
Catalog Documents
Core catalog document attributes
The following attributes are returned by default.
Attribute Type Description
id string Identifier (UUID) of the document. This identifier is set by the server on create and it cannot be modified.
title string Title of the document.
type string The type of the document. Supported types: journal, book, generic, book_section, conference_proceedings, working_paper, report, web_page, thesis, magazine_article, statute, patent, newspaper_article, computer_program, hearing, television_broadcast, encyclopedia_article, case, film, bill.
abstract string Brief summary of the document.
source string Publication outlet, i.e. where the document was published.
year integer Year in which the document was issued/published.
authors array List of authors of the document, as person objects.
identifiers array List of identifiers available for the document. The supported identifiers are: arxiv, doi, isbn, issn, pmid (PubMed), scopus and ssrn.
keywords array 50 each
link string Link to the document’s page on the Mendeley website.
Additional catalog document attributes
The following attributes are available using a view .
Attribute Type Description
month integer Month in which the document was issued/published.
day integer Day in which the document was issued/published.
revision string Number identifying the item (e.g. a report number).
pages string range of pages the document covers in the issue, e.g 4-8.
volume string volume holding the document, e.g “2” from journal volume 2.
issue string issue holding the document, e.g. “5” for a journal article from journal volume 2, issue 5
websites array Where the document was accessed from.
publisher string Publisher of the document.
city string city where the document was published.
edition array edition holding the document, e.g. “3” from the third edition of a book.
institution string Institution in which the document was published.
series string title of the collection holding the document (e.g. the series title for a book)
chapter string Chapter number.
editors array List of editors of the document. Like authors, this is a collection (array) of person objects, which include first_name and last_name (strings), as person objects.
file_attached boolean
reader_count integer Total number of users in Mendeley that have the document in their library.
reader_count_by_academic_status object Number of readers based on their academic status.
reader_count_by_discipline object Number of readers based on their discipline.
reader_count_by_country object Number of readers based on their country.
group_count integer Number of Mendeley groups that this document has been added to.
imported boolean Whether the document metadata has been imported from a source other than a users library. For example, Scopus and is therefore likely to be of a higher quality.
has_pdf boolean Whether the catalogue document has an associated full-text pdf suitable for download.
Catalog document views
Value Description
bib Will return the core fields plus the bibliographic data. This includes: pages, volume, issue, websites, month, publisher, day, city, edition, institution, series, chapter, revision and editors.
client Will return the core fields plus file_attached and imported.
stats This view will return the core fields plus the statistics data. This includes: reader_count, reader_count_by_academic_status, reader_count_by_discipline, reader_by_country and group_count.
all Will return all fields.
Retrieving catalog documents
curl 'https://api.mendeley.com/catalog?doi=10.1016/j.molcel.2009.09.013' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-document.1+json' { "id" : "eaede082-7d8b-3f0c-be3a-fb7be685fbe6" , "title" : "How To Choose a Good Scientific Problem" , "type" : "journal" , "authors" : [ { "first_name" : "Uri" , "last_name" : "Alon" } ] , "year" : 2009, "source" : "Molecular Cell" , "identifiers" : { "doi" : "10.1016/j.molcel.2009.09.013" , "isbn" : "1097-4164 (Electronic) \\ r1097-2765 (Linking)" , "pmid" : "19782018" , "issn" : "10972765" , "arxiv" : "z0024" } , "abstract" : "Choosing good problems is essential for being a good scientist. But what is a good problem, and how do you choose one? The subject is not usually discussed explicitly within our profession. Scientists are expected to be smart enough to figure it out on their own and through the observation of their teachers. This lack of explicit discussion leaves a vacuum that can lead to approaches such as choosing problems that can give results that merit publication in valued journals, resulting in a job and tenure. ?? 2009 Elsevier Inc. All rights reserved." } doc = mendeley . catalog . by_identifier ( doi = '10.1016/j.molcel.2009.09.013' ) print doc . title Not implemented .
Retrieve catalog documents by identifier.
HTTP Request
GET https://api.mendeley.com/catalog
URL Parameters
Parameter Type Description
arxiv string arXiv identifier
doi string Digital Object Identifier
isbn string International Standard Book Number
issn string International Standard Serial Number
pmid string PubMed identifier
scopus string Scopus identifier
ssrn string Social Science Research Network
filehash string filehash of the file
view string includes core document fields plus additional fields.
Retrieving a catalog document
curl 'https://api.mendeley.com/catalog/eaede082-7d8b-3f0c-be3a-fb7be685fbe6?view=stats' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-document.1+json' { "id" : "eaede082-7d8b-3f0c-be3a-fb7be685fbe6" , "title" : "How To Choose a Good Scientific Problem" , "type" : "journal" , "authors" :[ { "first_name" : "Uri" , "last_name" : "Alon" } ] , "year" :2009, "source" : "Molecular Cell" , "identifiers" : { "doi" : "10.1016/j.molcel.2009.09.013" , "isbn" : "1097-4164 (Electronic) \\ r1097-2765 (Linking)" , "pmid" : "19782018" , "issn" : "10972765" , "arxiv" : "z0024" } , "reader_count" :65955, "reader_count_by_academic_status" : { "Professor" :2393, "Associate Professor" :1694, "Assistant Professor" :1936, "Post Doc" :4690, "Ph.D. Student" :14964, "Researcher (at an Academic Institution)" :3257, "Researcher (at a non-Academic Institution)" :2292, "Librarian" :592, "Other Professional" :2637, "Student (Postgraduate)" :4987, "Student (Master)" :11939, "Student (Bachelor)" :9485, "Senior Lecturer" :480, "Lecturer" :1025, "Doctoral Student" :3579 } , "reader_count_by_subdiscipline" : { "Chemistry" : { "Crystallography" :5, "Industrial and Engineering Chemistry" :17, "Inorganic Chemistry" :41, "Mass Spectrometry" :3, "Analytical Chemistry" :53, "Applied Chemistry" :23, "Chromatography" :1, "Physical Chemistry" :90, "Photochemistry" :5, "Radiochemistry" :4, "Polymer Chemistry" :30, "Nuclear Magnetic Resonance" :9, "Miscellaneous" :2525, "Petroleum" :5, "Organic Chemistry" :116, "Stereochemistry" :1, "Theoretical Chemistry" :34, "Biochemistry" :47 } , "Business Administration" : { "Banks and Banking" :4, "Accounting" :19, "Industrial Relations" :1, "Human Resource Management" :14, "Finance and Financial Services" :14, "Entrepreneurship" :25, "Management Information Systems" :27, "International Business" :9, "Insurance" :1, "Production, Operations and Manufacturing Management" :5, "Public and Non-Profit Management" :7, "Quality Control" :1, "Taxation" :3, "Management and Communication" :4, "Management and Strategy" :36, "Marketing" :30, "Miscellaneous" :677, "Technological Change" :2, "Logistics" :3 } , "Medicine" : { "Alcoholism and Addiction" :4, "AIDS" :11, "Anesthesiology" :36, "Allergy" :2, "Asthma" :1, "Arthritis" :1, "Cancer" :56, "Biomedical Engineering" :54, "Clinical Molecular and Microbiology" :19, "Cardiology" :47, "Dentistry and Oral Surgery" :67, "Communication Disorders" :3, "Emergency Medicine and Critical Care" :27, "Dermatology" :10, "Environmental" :4, "Endocrinology" :18, "Ophthalmology" :20, "Oncology" :35, "Occupational and Environmental" :8, "Occupational Therapy" :6, "Obstetrics" :20, "Obesity" :2, "Nutrition and Metabolism" :26, "Pharmacy" :47, "Pharmacology" :31, "Pediatrics" :33, "Pathology and Forensics" :17, "Pain Medicine and Palliative Care" :8, "Otolaryngology" :13, "Orthopedics" :23, "Optometry" :11, "Hematology" :16, "Histology" :2, "Geriatrics and Aging" :6, "Gynecology" :11, "Gastroenterology and Hepatology" :15, "General Medicine" :17, "Epidemiology" :85, "Family" :8, "Neurology" :46, "Neuroscience" :124, "Nephrology, Urology" :17, "Neurobiology" :6, "Medical Imaging" :33, "Miscellaneous" :9166, "Internal Medicine" :40, "Rheumatology" :14, "Surgery" :54, "Toxicology" :8, "Tropical" :5, "Physiology" :27, "Public Health and Community Medicine" :74, "Reproductive Medicine" :6, "Respiratory and Pulmonary" :23, "Nursing" :44, "Physiotherapy" :49 } } , "reader_count_by_country" : { "Belarus" :5, "Portugal" :218, "Philippines" :41, "Hong Kong" :18, "Morocco" :5, "Tanzania" :15, "Mali" :4, "Ecuador" :44, "...all countries listed..." :99 } , "abstract" : "Choosing good problems is essential for being a good scientist. But what is a good problem, and how do you choose one?.........." } doc = mendeley . catalog . get ( 'eaede082-7d8b-3f0c-be3a-fb7be685fbe6' , view = 'stats' ) print doc . reader_count Not implemented .
Retrieve a catalog document by ID.
HTTP Request
GET https://api.mendeley.com/catalog/{id}
URL Parameters
Parameter Type Description
id string the catalog id (UUID)
view string includes core document fields plus additional fields.
Catalog Search
The documents returned have the same attributes as the Catalog Documents API.
Search by query
curl 'https://api.mendeley.com/search/catalog?query=polar+bears&limit=3' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-document.1+json' [ { "id" : "52a7f7b4-3cde-399b-a20e-889dc90e62b8" , "title" : "In the Marine Environment" , "type" : "journal" , "authors" : [ { "first_name" : "Polar" , "last_name" : "Bears" } ] , "year" : 2002, "source" : "Arctic" , "identifiers" : { "issn" : "00063185" } , "abstract" : "..." } , { "id" : "dd18e5ad-74d0-3bfa-a5da-84640ad82976" , "title" : "Behavior" , "type" : "book_section" , "authors" : [ { "first_name" : "I" , "last_name" : "Stirling" } ] , "year" : 1988, "source" : "Polar Bears" , "abstract" : "..." } , { "id" : "248883ce-5377-3aa3-aa84-57163c89d3f6" , "title" : "Polar Bears" , "type" : "journal" , "authors" : [ { "first_name" : "Nicholas J" , "last_name" : "Lunn" } , { "first_name" : "Scott" , "last_name" : "Schliebe" } , { "first_name" : "Erik W" , "last_name" : "Born" } ] , "year" : 2003, "source" : "Oryx" , "identifiers" : { "pmid" : "20535730" , "issn" : "00306053" , "doi" : "10.1017/S0030605303250663" , "isbn" : "2831709598" } , "abstract" : "..." } ] page = mendeley . catalog . search ( 'polar bears' ) . list () for doc in page . items : print doc . title Not implemented .
Retrieve documents which match general query terms.
HTTP Request
GET https://api.mendeley.com/search/catalog
URL Parameters
The search query is considered to be a string of terms separated by spaces. The search will return documents which match any of these, but rank those which match many terms higher than those which only match a few.
Parameter Type Description
query string Query terms, which match any field in the document, e.g. title, author etc ( required ).
view string Request additional fields in the documents returned, as for Catalog Documents .
Advanced search
curl 'https://api.mendeley.com/search/catalog?source=polar+bears&limit=3' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-document.1+json' [ { "id" : "dd18e5ad-74d0-3bfa-a5da-84640ad82976" , "title" : "Behavior" , "type" : "book_section" , "authors" : [ { "first_name" : "I" , "last_name" : "Stirling" } ] , "year" : 1988, "source" : "Polar Bears" , "abstract" : "Our understanding of the behavior of any animal comes from many sources of information..." } , { "id" : "e807b6ff-1726-358a-9ec1-2768abe0936e" , "title" : "New data on the winter ecology of the polar bear (Ursus maritimus Phipps) on the Vrangel Island" , "type" : "journal" , "authors" : [ { "first_name" : "a a" , "last_name" : "Kishchinskij" } , { "first_name" : "S M" , "last_name" : "Uspenskij" } ] , "year" : 1973, "source" : "Ecology and morphology of the polar bear." , "abstract" : "Winter ecology of the polar bear was studied in March-April of 1969 and 1970..." } , { "id" : "a9ee415c-7e8d-3d96-84d8-eb2b6d88cd65" , "title" : "Uncertainty in climate model projections of Arctic sea ice decline: an evaluation relevant to polar bears" , "type" : "report" , "authors" : [ { "first_name" : "E T" , "last_name" : "DeWeaver" } ] , "year" : 2007, "source" : "USGS Science Strategy to Support U.S. Fish and Wildlife Service Polar Bear Listing Decision." , "abstract" : "This report describes uncertainties in climate model simulations of Arctic sea ice decline, and proposes a selection criterion for models to be used in projecting polar bear (Ursus maritimus) habitat loss..." } ] page = mendeley . catalog . advanced_search ( source = 'polar bears' ) . list () for doc in page . items : print doc . title Not implemented .
Retrieve documents which match the supplied values in specific fields.
HTTP Request
Advanced search uses the same endpoint as search by query:
GET https://api.mendeley.com/search/catalog
URL Parameters
Multiple search fields may be specified. At least one of title , author , source or abstract must be provided. If more than one of these is set, the results will return documents which match any of these, but rank those which match several fields higher than those which match fewer fields.
min_year , max_year and open_access act as filters. Setting either a minimum or maximum year excludes documents which do not have a year defined.
Parameter Type Description
title string Matches terms in the title of the document.
author string Matches the names of one or more authors.
source string Matches the publication name.
abstract string Matches terms in the abstract.
min_year integer The earliest publication year to return results for.
max_year integer The latest publication year to return results for.
open_access boolean Specify true to limit results to open access publications (default = false).
view string Request additional fields in documents returned, as for Catalog Documents .
Datasets
Public dataset attributes
Attribute Type Description
id string The unique identifier for the dataset (required for other operations).
version integer The version number of the dataset.
name string The name of the dataset.
description string A description of the data (files) contained in the dataset.
publish_date string The date that this dataset version was made public. This date is represented in ISO 8601 format.
files array The dataset files, as file objects .
categories array The categories that this dataset belongs to, as category objects .
contributors array The contributors of the dataset, as contributor objects .
doi object The DOI associated with the dataset, as DOI object .
versions array All versions of this dataset, as version objects .
data_licence object The licence that applies to this dataset version, as data licence object .
articles array Journal articles associated with the dataset, article objects .
File attributes
Attribute Type Description
filename string The file’s filename
name string A friendly name for the file
content_details object Immutable metadata about the file, as a content details object
File content details attributes
Attribute Type Description
id string File ID
sha256_hash string An SHA256 checksum for the file
content_type string The file’s content type
size number The file’s size in bytes
created_date string The date the file was uploaded. This date is represented in ISO 8601 format
status string The current status of the file object (claimed, unclaimed, not_uploaded)
download_url string The URL where the file can be downloaded. Sets the content-disposition: attachment; filename= using the parent file’s filename attribute
download_expiry_time string The time that the download URL will expire
view_url string Sets content-disposition: inline
Category attributes
Attribute Type Description
id string Category ID
label string The label to display for the category
The following categories are currently available:
id label
http://data.elsevier.com/vocabulary/OmniScience/Concept-170589324 Applied Sciences
http://data.elsevier.com/vocabulary/OmniScience/Concept-170589320 Arts and Humanities
http://data.elsevier.com/vocabulary/OmniScience/Concept-186201601 Health Sciences
http://data.elsevier.com/vocabulary/OmniScience/Concept-170589436 Mathematics
http://data.elsevier.com/vocabulary/OmniScience/Concept-170589326 Natural Sciences
http://data.elsevier.com/vocabulary/OmniScience/Concept-170589328 Social Sciences
Contributor attributes
Attribute Type Description
id string Mendeley Profile ID (optional)
first_name string The contributor’s first name
last_name string The contributor’s last name
email string The contributor’s email address (this attribute is not included in public datasets)
contribution string The contribution of this contributor
institution object Optional, the institution that the contributor belongs to. Contains id (optional), name
DOI attributes
Attribute Type Description
id string ID of this DOI
status string Status of the DOI. One of r equested or allocated for public datasets or reservered for draft datasets
Version attributes
Attribute Type Description
version string The version number
publish_date string The date that this dataset version was made public. This date is represented in ISO 8601 format
available string Whether this version is available (true, false)
Data licence attributes
Attribute Type Description
id string The ID of this licence type
short_name string Friendly name of this licence
full_name string Full legal name of this licence
description string Description of this licence’s details
url string URL of licence definition
Article attributes
Attribute Type Description
id string Article ID
title string The articles’s title
doi string The Digital Object Identifier for the article
journal_id string The ID of the journal this article is published in
Journal attributes
Attribute Type Description
id string Journal ID
name string The journal’s name
url string The journal’s home URL
logo_url string A URL to the journal’s logo
Draft dataset attributes
Draft dataset objects are similar to public dataset objects. They have some additional properties to help manage access to unpublished datasets.
Attribute Type Description
id string The unique identifier for the dataset (required for other operations).
name string The name of the dataset.
description string A description of the data (files) contained in the dataset.
files array The dataset files, as file objects .
categories array The dataset categories, as category objects .
contributors array The contributors of the dataset, as contributor objects .
doi object The DOI associated with the dataset, as DOI object .
versions array All versions of this dataset, as version objects .
data_licence object The licence that applies to this dataset version, as data licence object .
articles array Journal articles associated with the dataset, article objects .
owner_id string ID of dataset owner
created_data string Date that this dataset was created. This date is represented in ISO 8601 format.
last_modification_date string Date that this dataset was last modified. This date is represented in ISO 8601 format.
access_code string This will allow anyone to see the dataset if provided.
permissions array Permission IDs applied to this draft
Submission attributes
Submissions are a way for submission systems to add datasets (draft) related to the article submissions. Submissions and their data is only available to submission system and the authors associated with it.
Attribute Type Description
id string The unique (among the submission system) identifier for the submission (submission id) (required for other operations).
owner object Article author information as owner object .
submission_data string Submission system specific data in a form of JSON object
submission_token string A token generated when submission is created. It can later be used by other API clients (on behalf of the journal author) to add, modify and unlink datasets.
datasets array datasets, associated with submission, as objects with “id” and “version” properties of the draft datasets.
Owner attributes
Attribute Type Description
email string The article author’s email address.
Specifying fields to return
By default, only the id will be returned for requests. You should specify which attributes to return using the fields query paramenter.
For example, to return a list of datasets with the id , version , title , description and the mime_type for files , you would provide:
GET /datasets?fields=results.id,results.version,results.name,results.description,results.files.mime_type
For nested objects such as contributors, you must provide the keys within the object.
For example, to return a list of datasets, each with contributors’ first_name and last_name you would provide:
GET /datasets?fields=results.contributors.first_name,results.contributors.last_name
If you want to receive all fields, you can pass * to the fields parameter. Be aware that this query may take longer to receive and you may want to avoid using this in production.
GET /datasets?fields=*
Retrieving datasets (public)
Retrieve datasets with the id, name, description and version fields
curl 'https://api.mendeley.com/datasets?fields=results.id,results.name,results.description,results.version' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-public-dataset.1+json' \ { "results" : [ { "id" : "r4xggzrjxm" , "version" : 1, "name" : "Test dataset" , "description" : "Test description" } , { "id" : "xrnfvfkzkg" , "version" : 1, "name" : "Another dataset" , "description" : "Test description" } ] }
Retrieve datasets with the id, name, description, version and contributors first_name and last_name fields
curl 'https://api.mendeley.com/datasets?fields=results.id,results.name,results.description,results.version,results.contributors.first_name,results.contributors.last_name' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-public-dataset.1+json' \ { "results" : [ { "id" : "r4xggzrjxm" , "version" : 1, "name" : "Example dataset" , "description" : "Test description" , "contributors" : [{ "first_name" : "Dorian" , "last_name" : "Weimann" }] } , { "id" : "xrnfvfkzkg" , "version" : 1, "name" : "Another dataset" , "description" : "Test description" , "contributors" : [{ "first_name" : "Barry" , "last_name" : "Tester" }] } ] }
HTTP Request
GET https://api.mendeley.com/datasets
URL Parameters
Parameter Type Description
article_doi string Filter by datasets linked to an article doi (optional)
limit string The maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500
order string The sort order
fields string A comma separated list of fields to return in the response.
Returns
A 200 OK response containing a paginated list of public datasets.
Retrieving a dataset (public)
curl 'https://api.mendeley.com/datasets/856xgy2hy9' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-public-dataset.1+json' \ { "id" : "4c35399a-1c2e-42eb-baed-3dc5281141e3" , "version" : 2, "versions" : [ { "version" : 2, "publish_date" : "2015-12-15T10:34:34.897Z" , "available" : true } , { "version" : 1, "publish_date" : "2015-12-15T10:34:34.897Z" , "available" : true } ] , "collaborators" : [] , "name" : "Example dataset" , "description" : "Description of the data" , "contributors" : [{ "id" : "c4676e62-10c3-3efe-b494-2f2dcec084c7" , "first_name" : "Barry" , "last_name" : "Tester" } , { "id" : "eb0429bd-6f79-30b1-81b8-2855f457f380" , "first_name" : "Dorian" , "last_name" : "Weimann" }] "publish_date" : "2015-12-15T10:34:34.897Z" , "doi" : { "id" : "10.17632/856xgy2hy9.2" , "status" : "allocated" } , "short_id" : "856xgy2hy9" , "data_licence" : { "short_name" : "CC BY 4.0" , "full_name" : "Creative Commons Attribution 4.0 International" , "description" : "Unless indicated otherwise, you can share, copy and modify the images or other third party..." , "url" : "http://creativecommons.org/licenses/by/4.0" } }
Retrieves a public dataset for the provided dataset ID
HTTP Request
GET https://api.mendeley.com/datasets/{id}
URL Parameters
Parameter Type Description
version string Specify a version other than the latest
Returns
A 200 OK response containing a paginated list of public datasets.
Retrieving datasets (draft)
curl 'https://api.mendeley.com/datasets/drafts?roles=owner&fields=id,version,name,description' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-draft-dataset.1+json' \ [ { "id" : "mp98hktrwp" , "version" : 1, "name" : "Test dataset" , "description" : "Test description" } ]
Returns a list of draft datasets where the user is the owner.
HTTP Request
GET https://api.mendeley.com/datasets/drafts
URL Parameters
Parameter Type Description
roles string Comma delimited list of any roles the user should have on a dataset. Can include owner, author, collaborator.
limit string The maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500
order string The sort order
Returns
A 200 OK response containing a paginated list of draft datasets.
Retrieving a dataset (draft)
curl 'https://api.mendeley.com/datasets/drafts/{id}' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-draft-dataset.1+json' \ { "id" : "jynm7bxcyb" , "name" : "A dataset" , "description" : "Description of my dataset" , "owner_id" : "34851d06-9994-3732-ad14-b283e037c04c" , "version" : 1, "versions" : [ { "version" : 1, "available" : true } ] , "last_modification_date" : "2015-12-15T10:34:34.897Z" , "data_licence" : { "id" : "01d9c749-3c4d-4431-9df3-620b2dcfe144" , "short_name" : "CC BY 4.0" , "full_name" : "Creative Commons Attribution 4.0 International" , "description" : "Unless indicated otherwise, you can share, copy and modify..." , "url" : "http://creativecommons.org/licenses/by/4.0" } , "access_code" : "2d67e8e2-3d77-416e-9c1b-82bde731f4e5" , "contributors" : [{ "id" : "34851d06-9994-3732-ad14-b283e037c04c" , "first_name" : "Barry" , "last_name" : "Tester" , "email" : "barry.tester@mendeley.com" , "corresponding_author" : false }] , "collaborators" : [] , "all_versions" : [] , "files" : [{ "id" : "869290bb-0c47-43fc-ad83-44167f7316a7" , "filename" : "mugs.jpg" , "name" : "mugs" , "file_size" : 94839, "hash" : "cac511c0aa8eaf77c763bda2c2110121d055d2c3ab60d7339434b487bc2f13ef" , "last_modification_date" : "2015-12-15T10:34:34.897Z" , "mime_type" : "image/jpeg" , "created_date" : "2015-12-15T10:34:34.897Z" }] , "articles" : [] , "roles" : [ "owner" , "author" ] , "permissions" : [ "Read" , "ReadAccessCode" , "ReadAuthorEmailAddresses" , "ReadCollaborators" , "Update" , "Publish" ] }
Retrieves the draft dataset for the provided dataset ID
HTTP Request
GET https://api.mendeley.com/datasets/drafts/{id}
URL Parameters
Parameter Type Description
access_code string Provides access to users other than the owner (optional)
Returns
A 200 OK response containing a paginated list of public datasets.
Creating a dataset (draft)
curl 'https://api.mendeley.com/datasets/drafts' \ -X POST \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-dataset-creation-request.1+json' \ -H 'Accept: application/vnd.mendeley-draft-dataset.1+json' \ --data-binary $' { "name" : "Test dataset" , "description" : "Test description" , "contributors" : [{ "first_name" : "Dorian" , "last_name" : "Weimann" , "email" : "example@email.com" }]} '
{
"id": "mp98hktrwp",
"version": 1,
"versions": [
{ "version": 1, "available": true }
],
"name": "Test dataset",
"description": "Test description",
"contributors": [
{
"first_name": "Dorian",
"last_name": "Weimann",
"email": "example@email.com"
}
],
"files": [],
"categories": [
{
"id": "http://data.elsevier.com/vocabulary/OmniScience/Concept-170589324"
}
],
"roles": [
"owner",
"author"
],
"last_modification_date": "2015-12-15T10:34:34.897Z",
"doi": {
"id": "10.4124/mp98hktrwP.1",
"status": "reserved"
}
}
Returns a draft dataset.
HTTP Request
POST https://api.mendeley.com/datasets/drafts
Returns
A 201 CREATED response containing a draft dataset.
Updating a dataset (draft)
curl 'https://api.mendeley.com/datasets/drafts/mp98hktrwp' \ -X PATCH \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-dataset-patch.1+json' \ -H 'Accept: application/vnd.mendeley-draft-dataset.1+json' \ --data-binary $' { "name" : "Updated dataset" } '
{
"id": "mp98hktrwp",
"version": 1,
"versions": [
{ "version": 1, "available": true }
],
"name": "Updated dataset",
"description": "Test description",
"contributors": [
{
"first_name": "Dorian",
"last_name": "Weimann",
"email": "example@email.com"
}
],
"files": [],
"roles": [
"owner",
"author"
],
"last_modification_date": "2015-12-15T10:34:34.897Z",
"doi": {
"id": "10.4124/mp98hktrwP.1",
"status": "reserved"
}
}
Returns a draft dataset.
HTTP Request
PATCH https://api.mendeley.com/datasets/drafts/{id}
Returns
A 200 OK response containing a draft dataset.
Adding a file to a draft dataset
You will first need to upload the file content to the file content endpoint . Now, with the returned id , you can send it as the content_details.id for the file.
curl 'https://api.mendeley.com/datasets/drafts/mp98hktrwp' \ -X PATCH \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-dataset-patch.1+json' \ -H 'Accept: application/vnd.mendeley-draft-dataset.1+json' \ --data-binary $' { "content_details" : { "id" : "3f2f968f-553b-467d-8121-ba02cab937a0" } , "filename" : "my-file.pdf" , "description" : "Example decription" } '
{
"id": "mp98hktrwp",
"files": [
{
"filename": "my-file.pdf",
"description": "Example Description",
"content_details": {
"id": "3f2f968f-553b-467d-8121-ba02cab937a0",
"sha256_hash": "3fc0992551a40279346de32e6deb8bce0ca75d32a07c71451473bc024a400840",
"content_type": "image/jpeg",
"size": 141714,
"created_date": "2015-12-15T10:34:34.897Z",
"download_url": "https://downloads.mendeley.com/3fc0992551a40279346de32e6deb8bce0ca75d32a07c71451473bc024a400840",
"download_expiry_time": 1445343439786
}
}
],
...
}
Returns a draft dataset.
HTTP Request
PATCH https://api.mendeley.com/datasets/drafts/{id}
Returns
A 200 OK response containing a draft dataset.
Publishing a dataset (draft)
curl 'https://api.mendeley.com/datasets/drafts/{id}' \ -X POST \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-draft-dataset.1+json' \ -H 'Accept: application/vnd.mendeley-draft-dataset.1+json' \ --data-binary $' { "name" : "Test dataset" , "description" : "Test description" , "contributors" : [{ "first_name" : "Dorian" , "last_name" : "Weimann" , "email" : "example@email.com" }]} '
{
"id": "mp98hktrwp",
"version": 1,
"versions": [
{ "version": 1, "available": true }
],
"name": "Test dataset",
"description": "Test description",
"contributors": [
{
"first_name": "Dorian",
"last_name": "Weimann",
"email": "example@email.com"
}
],
"files": [
{
"filename": "my-file.pdf",
"description": "Example Description",
"content_details": {
"id": "3f2f968f-553b-467d-8121-ba02cab937a0",
"sha256_hash": "3fc0992551a40279346de32e6deb8bce0ca75d32a07c71451473bc024a400840",
"content_type": "image/jpeg",
"size": 141714,
"created_date": "2015-12-15T10:34:34.897Z",
"download_url": "https://downloads.mendeley.com/3fc0992551a40279346de32e6deb8bce0ca75d32a07c71451473bc024a400840",
"download_expiry_time": 1445343439786
}
}
],
"roles": [
"owner",
"author"
],
"last_modification_date": "2015-12-15T10:34:34.897Z",
"doi": {
"id": "10.4124/mp98hktrwP.1",
"status": "reserved"
}
}
Publishes a draft as the next sequential version
HTTP Request
POST https://api.mendeley.com/datasets/drafts/{id}
Returns
A 200 OK response containing the published dataset.
Deleting a dataset (draft)
curl 'https://api.mendeley.com/datasets/drafts/mp98hktrwp' \ -X DELETE \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \
Permanently deletes a draft dataset.
HTTP Request
DELETE https://api.mendeley.com/datasets/drafts/{id}
Returns
A 204 No Content response.
Creating a submission
curl 'https://api.mendeley.com/datasets/submissions/{submission_system}' \ -X POST \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-rdm-submission-creation-request.1+json' \ -H 'Accept: application/vnd.mendeley-rdm-submission.1+json' \ --data-binary $' { "id" : "b3zdUk4s" , "owner" : { "email" : "example@email.com" } , "submission_data" : { "title" : "Test title" , "authors" : [ ] }} '
{
"id": "b3zdUk4s",
"owner": {
"email": "example@email.com"
},
"submission_data": {
"title": "Test title",
"authors": []
},
"submission_token": "628e0343-5de5-4955-a64f-2637f675bd6e",
"datasets": []
}
Returns created submission.
HTTP Request
POST https://api.mendeley.com/datasets/submissions/{submission_system}
Returns
A 201 Created response containing a submission.
Updating a submission
curl 'https://api.mendeley.com/datasets/drafts/mp98hktrwp' \ -X PATCH \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-rdm-submission-modification-request.1+json' \ -H 'Accept: application/vnd.mendeley-rdm-submission.1+json' \ --data-binary $' { "id" : "b3zdUk4s" , "owner" : { "email" : "example@email.com" } , "submission_data" : { "title" : "Test title" , "authors" : [ { "first_name" : "Example" , "last_name" : "Author" , "email" : "example@email.com" , "webuser_id" : "1234-1234-1234-1234" } ]} } '
{
"id": "b3zdUk4s2",
"owner": {
"email": "example@email.com"
},
"submission_data": {
"title": "Test title",
"authors": [
{
"first_name": "Example",
"last_name": "Author",
"email": "example@email.com",
"webuser_id": "1234-1234-1234-1234"
}
]
},
"submission_token": "628e0343-5de5-4955-a64f-2637f675bd6e",
"datasets": []
}
Returns a modified submission.
HTTP Request
PATCH /datasets/submissions/{submission_system}/{id}
Returns
A 201 Created response containing a submission.
Adding dataset to submission
curl 'https://api.mendeley.com/datasets/submissions/{submission_system}/{id}/datasets?submission_token={submission_token}' \ -X POST \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-dataset-creation-request.1+json' \ -H 'Accept: application/vnd.mendeley-draft-dataset.1+json' \ --data-binary $' { "description" : "Some description goes here" , "files" : [ { "filename" : "test.txt" , "content_details" : { "id" : "883487f3-9bfe-4e44-9cc4-705fec68913a" } }] } '
{
"related_links": [],
"id": "6gz33fkcs7",
"doi": {
"id": "10.4124/6gz33fkcs7.1",
"status": "reserved"
},
"description": "Some description goes here",
"owner": {
"email": "example@email.com"
},
"version": 1,
"created_date": "2016-07-28T07:27:51.492Z",
"last_modification_date": "2016-07-28T07:27:51.492Z",
"view_token": "dc0c279a-dd71-4a48-8d96-62fbf58558aa",
"contributors": [],
"versions": [],
"files": [
{
"filename": "test.txt",
"content_details": {
"id": "883487f3-9bfe-4e44-9cc4-705fec68913a",
"sha256_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
"sha1_hash": "da39a3ee5e6b4b0d3255bfef95601890afd80709",
"content_type": "text/plain",
"size": 0,
"created_date": "2016-05-18T00:00:00.000Z",
"download_url": {download url},
"view_url": {download url},
"download_expiry_time": "2016-07-28T08:27:52.226Z"
}
}
],
"articles": [],
"permissions": [
"read_dataset",
"read_view_token",
"read_contributor_email_addresses",
"update_dataset",
"publish_dataset",
"delete_draft"
],
"categories": [],
"institutions": []
}
Returns created submission’s dataset.
HTTP Request
POST /datasets/submissions/{submission_system}/{id}/datasets?submission_token={submission_token}
Returns
A 201 Created response containing a dataset.
Getting datasets associated with submission
curl 'https://api.mendeley.com/datasets/submissions/{submission_system}/{id}/datasets?fields=id,version,description&submission_token={submission_token}' \ -X GET \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-draft-dataset.1+json' [ { "id" : "6gz33fkcs7" , "description" : "Some description goes here" , "version" : 1 } ]
Returns datasets associated with submission.
HTTP Request
GET /datasets/submissions/{submission_system}/{id}/datasets?fields=id,version,description&submission_token={submission_token}
Returns
A 200 Ok response containing a datasets.
Unlinking dataset from submission
curl 'https://api.mendeley.com/datasets/submissions/{submission_system}/{id}/datasets/{dataset_id}?submission_token={submission_token}' \ -X DELETE \ -H 'Authorization: Bearer <ACCESS_TOKEN>'
HTTP Request
DELETE https://api.mendeley.com/datasets/submissions/{submission_system}/{id}/datasets/{dataset_id}?submission_token={submission_token}
Returns
A 204 No Content response.
Disciplines
Retrieve all disciplines
Retrieves all disciplines and possible sub-disciplines. Sample JSON is abbreviated below to the top 3 disciplines.
curl 'https://api.mendeley.com/disciplines' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-discipline.1+json' [ { "name" : "Arts and Literature" , "subdisciplines" : [ "Architecture" , "Art History" , "Children's Literature" , "Culture Heritage" , "Film and TV Studies" , "Folklore" , "Latin" , "Literature" , "Miscellaneous" , "Music" , "Visual and Performing Arts" ] } , { "name" : "Astronomy / Astrophysics / Space Science" , "subdisciplines" : [ "Celestial Mechanics" , "Cosmology" , "Extragalactic Astronomy" , "Interstellar Matter" , "Meteors" , "Miscellaneous" , "Solar Terrestrial Physics" , "Stars" , "The Sun" , "Theoretical Astrophysics" ] } , { "name" : "Biological Sciences" , "subdisciplines" : [ "Agricultural Science" , "Algology" , "Animal Behavior" , "Animal Physiology" , "Biochemistry" , "Bioinformatics" , "Biometry" , "Biophysics" , "Biotechnology" , "Botany" , "Cellular Biology" , "Embryology" , "Entomology" , "Food Science and Technology" , "Forestry Science" , "Genetics" , "Hydrobiology" , "Ichthyology" , "Immunology" , "Limnology" , "Marine Biology" , "Microbiology" , "Microscopy" , "Miscellaneous" , "Molecular Biology" , "Mycology" , "Neurobiology" , "Ornithology" , "Parasitology" , "Plant Sciences" , "Soil Sciences" , "Veterinary Science" , "Virology" , "Zoology and Animal Science" ] } ] ....
.... Not implemented . Not implemented .
HTTP Request
GET https://api.mendeley.com/disciplines
Returns
A 200 OK response containing a all disciplines and subdisciplines in Mendeley.
Documents
Core document attributes
The following attributes are returned by default.
Some string attributes have a maximum length - these are indicated in the table below.
Attribute Type Maximum length Description
id string Identifier (UUID) of the document. This identifier is set by the server on create and it cannot be modified.
title string 500 Title of the document. This is a required field.
type string The type of the document. Supported types: journal, book, generic, book_section, conference_proceedings, working_paper, report, web_page, thesis, magazine_article, statute, patent, newspaper_article, computer_program, hearing, television_broadcast, encyclopedia_article, case, film, bill.
profile_id string Profile id (UUID) of the Mendeley user that added the document to the system.
group_id string Group id (UUID) that the document belongs to.
created string Date the document was added to the system. This date is set by the server after a successful create request. This date is represented in ISO 8601 format.
last_modified string Date in which the document was last modified. This date is set by the server after a successful update request. This date is represented in ISO 8601 format.
abstract string 10,000 Brief summary of the document.
source string 255 Publication outlet, i.e. where the document was published.
year integer Year in which the document was issued/published.
authors array List of authors of the document, as person objects.
identifiers object 500 each List of identifiers available for the document. The supported identifiers are: arxiv, doi, isbn, issn, pmid (PubMed), scopus and ssrn.
keywords array 300 each List of author-supplied keywords for the document.
Additional document attributes
The following attributes are available using a view .
Attribute Type Maximum length Description
month integer Month in which the document was issued/published. This should be an integer between 1 and 12.
day integer Day in which the document was issued/published. This should be an integer between 1 and 31.
revision string 255 Number identifying the item (e.g. a report number).
pages string 50 range of pages the document covers in the issue, e.g 4-8.
volume string 20 volume holding the document, e.g “2” from journal volume 2.
issue string 255 issue holding the document, e.g. “5” for a journal article from journal volume 2, issue 5
websites array 5000 total Where the document was accessed from.
publisher string 255 Publisher of the document.
city string 255 city where the document was published.
edition array 20 edition holding the document, e.g. “3” from the third edition of a book.
institution string 255 Institution in which the document was published.
series string 255 title of the collection holding the document (e.g. the series title for a book)
chapter string 20 Chapter number.
editors array List of editors of the document, as person objects.
accessed string Date that the document was accessed. This date is represented in ISO 8601 format.
tags array 100 each List of user-supplied tags for the document.
read boolean Flag used to identify whether the document has been read or not.
starred boolean Flag used to identify whether the user has marked the document as favourite.
authored boolean Flag used to identify whether the user has authored the document.
confirmed boolean Flag to identify whether the metadata of the document is correct after it has been extracted from the PDF file.
hidden boolean Flag to identify whether Mendeley can publish this document to the Mendeley catalog.
file_attached boolean Flag to identify whether the document has a file attached.  Files can be retrieved using the files API .
citation_key string 255 Identifier used by BibTeX when citing documents.
source_type string 255 Original type of a document imported from BibTeX.
language string 255 Language of the document.
short_title string 50 A short version of the title, used in some citations.
reprint_edition string 10 Edition number of this reprint of the document.
genre string 255 Class, type or genre of the document.
country string 255 Country where the document was published.
translators array List of translators of the document, as person objects.
series_editor string 255 Editor name for a book series.
code string 255 Code for legal documents.
medium string 255 Medium description (e.g. “CD”, “DVD”).
user_context string 255 The format of the item (e.g. Journal)
department string 255 University department name.
patent_owner string 255 Name of patent assignee.
patent_application_number string 255 Patent application number.
patent_legal_status string 255 Legal status of document, example values “Restricted”, “Pending approval”, “Granted”.
People
People are represented as an object with the following attributes:
Attribute Type Maximum length Description
last_name string 255 Last name of the person.  Required.
first_name string 255 First name of the person.
Document views
To get additional fields, you can use one of the following views:
Value Description
bib Will return the core fields plus the bibliographic data. This includes: pages, volume, issue, websites, month, publisher, day, city, edition, institution, series, chapter, revision, editors, accessed, citation_key, source_type, language, short_title, reprint_edition, genre, country, translators, series_editor, code, medium, user_context, department.
client Will return the core fields plus the fields needed for clients to sync across different devices like read, starred, authored, confirmed, hidden and file_attached.
tags Will return the core fields plus tags.
patent Will return the core fields plus patent_owner, patent_application_number and patent_legal_status.
all Will return all fields.
Retrieving a document
curl 'https://api.mendeley.com/documents/cb58a7d9-8463-34e2-b1b8-457a3872ecdc' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-document.1+json' { "id" : "cb58a7d9-8463-34e2-b1b8-457a3872ecdc" , "title" : "Linked Data - The Story So Far" , "type" : "journal" , "authors" : [ { "first_name" : "Christian" , "last_name" : "Bizer" } , { "first_name" : "Tom" , "last_name" : "Heath" } , { "first_name" : "Tim" , "last_name" : "Berners-Lee" } ] , "year" : 2009, "source" : "International Journal on Semantic Web and Information Systems" , "identifiers" : { "doi" : "10.4018/jswis.2009081901" , "issn" : "15526283" } , "created" : "2014-04-09T09:36:44.000Z" , "profile_id" : "4afc0c0f-88ab-3aed-a20a-f50934fc83b1" , "last_modified" : "2014-04-09T09:36:44.000Z" , "abstract" : "The term Linked Data refers to a set of best practices for publishing and connecting structured data on the Web......." } doc = mendeley . documents . get ( 'cb58a7d9-8463-34e2-b1b8-457a3872ecdc' ) print doc . title Document doc = sdk . getDocument ( "cb58a7d9-8463-34e2-b1b8-457a3872ecdc" , View . ALL );
Retrieves a document by ID.
HTTP Request
GET https://api.mendeley.com/documents/{id}
URL Parameters
Parameter Type Description
id string Identifier (UUID) of the document. This identifier is set by the server on create and it cannot be modified.
view string includes core document fields plus additional fields.
Returns
A 200 OK response containing a single document.
Retrieving documents
curl 'https://api.mendeley.com/documents' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-document.1+json' [ { "id" : "b9a91b83-c091-3bd1-93b4-88b4a3123f8e" , "title" : "Differential synchronization" , "type" : "journal" , "authors" : [ { "first_name" : "Igor" , "last_name" : "Žutić" } ] , "year" : 2009, "source" : "Proceedings of the 9th ACM symposium on Document engineering - DocEng '09" , "identifiers" : { "isbn" : "9781605585758" , "doi" : "10.1145/1600193.1600198" } , "created" : "2013-10-21T11:47:18.000Z" , "profile_id" : "4afc0c0f-88ab-3aed-a20a-f50934fc83b1" , "last_modified" : "2014-01-15T11:43:24.000Z" } , { "id" : "2bf33ebd-7cd1-3786-903d-d74d04958e40" , "title" : "How to Design a Good API and Why it Matters" , "type" : "report" , "authors" : [ { "first_name" : "Joshua" , "last_name" : "Bloch" } ] , "year" : 2006, "source" : "Google Inc" , "created" : "2014-04-07T08:42:34.000Z" , "profile_id" : "4afc0c0f-88ab-3aed-a20a-f50934fc83b1" , "last_modified" : "2014-04-08T10:11:41.000Z" , "abstract" : "In lieu of a traditional abstract, I’ve tried to distill the essence of the talk into a collection of maxims" } ] for doc in mendeley . documents . iter (): print doc . title DocumentList docList = sdk . getDocuments (); List < Document > docs = docList . documents ; // Get subsequent pages: Page next = docList . next ; while ( next != null ) { docList = sdk . getDcouments ( next ); docs . addAll ( docList . documents ); next = docList . next ; }
Retrieves a list of documents.
HTTP Request
GET https://api.mendeley.com/documents
URL Parameters
Parameter Type Description
view string includes core document fields plus additional fields.
profile_id string the id of the profile that the document belongs to, that does not belong to any group. If not supplied returns users documents.
group_id string the id of the group that the document belongs to. If not supplied returns users documents.
modified_since string returns only documents modified since this timestamp. Should be supplied in ISO 8601 format
deleted_since string returns only documents deleted since this timestamp. Should be supplied in ISO 8601 format
limit string the maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500
order string sort order
sort string field to sort on
Returns
A paginated list of documents.
Retrieving a BiBTex document
curl 'https://api.mendeley.com/documents/cb58a7d9-8463-34e2-b1b8-457a3872ecdc?view=bib' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/x-bibtex' @article { Armbrust2009,
title = { Above the clouds: A Berkeley view of cloud computing } ,
year = { 2009 } ,
journal = { University of California, Berkeley, Tech. Rep. UCB } ,
author = { Armbrust, M and Fox, A and Griffith, R and Joseph, AD and RH } ,
pages = { 07-013 } coming soon Not implemented
Retrieves a document in BiBTex format.
HTTP Request
GET https://api.mendeley.com/documents/{id}?view=bib
URL Parameters
Parameter Type Description
id string Identifier (UUID) of the document. This identifier is set by the server on create and it cannot be modified.
view string needs to be set to ‘bib’
Returns
A 200 OK response containing a single document in BiBTex format
Retrieving BiBTex documents
curl 'https://api.mendeley.com/documents?view=bib' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/x-bibtex' @article { Mirashe2010,
title = { Cloud Computing } ,
year = { 2010 } ,
journal = { Communications of the ACM } ,
author = { Mirashe, Shivaji P and Kalyankar, N V } ,
chapter = { 6 } ,
doi = { 10.1145/358438.349303 } ,
editor = { Antonopoulos, Nick and Gillam, Lee } ,
number = { 7 } ,
pages = { 9 } ,
series = { Informatik im Fokus } ,
volume = { 51 } } @misc { Ghemawat2003,
title = { The Google file system } ,
year = { 2003 } ,
booktitle = { ACM SIGOPS Operating Systems Review } ,
author = { Ghemawat, Sanjay and Gobioff, Howard and Leung, Shun-Tak } ,
number = { 5 } ,
pages = { 29 } ,
volume = { 37 } } @article { Armbrust2009,
title = { Above the clouds: A Berkeley view of cloud computing } ,
year = { 2009 } ,
journal = { University of California, Berkeley, Tech. Rep. UCB } ,
author = { Armbrust, M and Fox, A and Griffith, R and Joseph, AD and RH } ,
pages = { 07-013 } } @inproceedings { Chang2006,
title = { Bigtable: A distributed storage system for structured data } ,
year = { 2006 } ,
booktitle = { 7th Symposium on Operating Systems Design and Implementation ( OSDI '06), November 6-8, Seattle, WA, USA},
author = {Chang, Fay and Dean, Jeffrey and Ghemawat, Sanjay and Hsieh, Wilson C. and Wallach, Deborah A. and Burrows, Mike and Chandra, Tushar and Fikes, Andrew and Gruber, Robert E.},
pages = {205-218}
} coming soon Not implemented
Retrieves multiple documents in BiBTex format.
HTTP Request
GET https://api.mendeley.com/documents?view=bib
URL Parameters
Parameter Type Description
view string needs to be set to 'bib’
Returns
A paginated list of BiBTex documents
Creating a document from metadata
curl 'https://api.mendeley.com/documents' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-document.1+json' \ -H 'Content-Type: application/vnd.mendeley-document.1+json' \ --data-binary $' { "type" : "journal" , "title" : "How To Build a Mendeley API" } '
{
"id": "b3a561de-f317-3042-8a5e-0161e7b5fe1d",
"title": "How To Build a Mendeley API",
"type": "journal",
"created": "2014-07-01T10:59:51.357Z",
"profile_id": "4afc0c0f-88ab-3aed-a20a-f50934fc83b1",
"year": 2009,
"source": "Molecular Cell",
"title": "How To Choose a Good Scientific Problem",
"identifiers": {
"doi": "10.1016/j.molcel.2009.09.013",
"issn": "10972765"
},
"authors": [
{
"first_name": "Uri",
"last_name": "Alon"
}
],
"pages": "726-728",
"volume": "35",
"issue": "6"
} doc = mendeley . documents . create ( title = 'How To Choose a Good Scientific Problem' , type = 'journal' ) print doc . id Document doc = Document . getBuilder ( "How To Choose a Good Scientific Problem" , "journal" ). build (); Document created = sdk . postDocument ( doc ); String id = created . id ;
Creates a document.
HTTP Request
POST https://api.mendeley.com/documents
Returns
After a successful create request, the server will return newly created object and a 201 response with the URL of the newly created resource available in the Location header.
Creating a document from a file
curl 'https://api.mendeley.com/documents' \ -X POST \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/pdf' \ -H 'Content-Disposition: attachment; filename="example.pdf"' \ --data-binary @example.pdf document = mendeley . documents . create_from_file ( 'example.pdf' )
Creates a document by extracting metadata from a supplied file.
Header Parameters
The following header parameters must be set.
Parameter Description
Content-Type This header will tell the server the file’s media type. For example, application/pdf.
Content-Disposition This header is used to extract the file’s name. The value should be, for example: attachment; filename=“example.pdf”
Returns
After a successful create request, the server will return newly created object and a 201 response with the URL of the newly created resource available in the Location header.
Updating documents
curl 'https://api.mendeley.com/documents/6e456c13-e850-3cf4-9f25-0d8307d36443' \ -X PATCH \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-document.1+json' \ --data-binary '{"type": "journal", "title": "How To Build an Awesome Mendeley API"}' updated_doc = doc . update ( title = 'How To Build an Awesome Mendeley API' ) Document amendments = Document . getBuilder (). setYear ( 2015 ). build (); sdk . patchDocument ( "6e456c13-e850-3cf4-9f25-0d8307d36443" , null , Document amendments );
Only the fields you pass in the request will be updated. You can clear a field by passing a null value for it.
HTTP Request
PATCH https://api.mendeley.com/documents/{id}
URL Parameters
Parameter Type Description
id string Identifier (UUID) of the document. This identifier is set by the server on create and it cannot be modified.
Header Parameters
A client can put a precondition on the request using the If-Unmodified-Since header e.g do not apply an update if the document was modified after this time.
Parameter Description
If-Unmodified-Since RFC-2616
Returns
A successful update will return a HTTP 200 with the updated document.
Move a document to the trash
curl 'https://api.mendeley.com/documents/6e456c13-e850-3cf4-9f25-0d8307d36443/trash' \ -X POST \ -H 'Authorization: Bearer <ACCESS_TOKEN>' trashed_doc = doc . move_to_trash () sdk . trashDocument ( "6e456c13-e850-3cf4-9f25-0d8307d36443" );
Moves a document to the trash.  It can still be restored.
HTTP Request
POST https://api.mendeley.com/documents/{id}/trash
URL Parameters
Parameter Type Description
id string Identifier (UUID) of the document. This identifier is set by the server on create and it cannot be modified.
Returns
A 204 No Content response.
Delete a document
curl 'https://api.mendeley.com/documents/c9939b3f-eddd-33ab-8f2f-7337fcd5cf39' \ -X DELETE \ -H 'Authorization: Bearer <ACCESS_TOKEN>' doc . delete () sdk . deleteDocument ( "c9939b3f-eddd-33ab-8f2f-7337fcd5cf39" );
Permanently deletes a document.
DELETE https://api.mendeley.com/documents/{id}
URL Parameters
Parameter Type Description
id string Identifier (UUID) of the document. This identifier is set by the server on create and it cannot be modified.
Returns
A 204 No Content response.
Retrieve list of deleted documents ids
curl 'https://api.mendeley.com/deleted_documents' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-deleted-document.1+json'
Retrieve a list of deleted documents ids.
HTTP Request
GET https://api.mendeley.com/deleted_documents
URL Parameters
Parameter Type Description
since date Returns only documents deleted since this timestamp.  Should be supplied in ISO 8601 format
group_id string Group ID (UUID).  If not supplied, returns user documents
Returns
A 200 OK response containing the ids of the deleted documents
Documents Metadata Lookup
Metadata lookup
curl 'https://api.mendeley.com/metadata?doi=10.1038%2F35095137' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-document-lookup.1+json' { "catalog_id" : "f5cc2417-a636-3c6a-9748-13aab2c2b35d" , "score" : 100 } Coming soon Not implemented .
Finds the catalog_id with the best metadata for the provided data.
HTTP Request
GET https://api.mendeley.com/metadata
URL Parameters
Parameter Type Description
arxiv string arXiv identifier
doi string Digital Object Identifier
pmid string PubMed identifier
title string Matches terms in the title of the document.
filehash string Filehash of the file
authors string Matches the names of one or more authors.
year string Year of publication
source string Matches the publication name.
Returns
Returns the catalog_id of the closest matching catalog document. The score is a confidence indicator of the match with 100 being very confident.
Files
File attributes
Attribute Type Description
id string The unique identifier for the file (required for other operations).
file_name string The name of the file. This is currently a generated name from the metadata of the document that the file is attached to. However, we will support original file names from the upload soon.
mime_type string The mime type of the file. This is used to work out the extension of the file. More info on mime types here .
filehash string SHA1 hash of the file. This can be used to check the integrity of the file.
document_id string The id of the document the file is attached to.
size integer The size of the file, in bytes.
Retrieving files
curl 'https://api.mendeley.com/files' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-file.1+json' [ { "id" : "16bd4f6e-4578-3391-356d-66b374143457" , "document_id" : "183217fc-9c61-34d1-be8b-996556410ccb" , "mime_type" : "application/pdf" , "file_name" : "MapReduce" , "filehash" : "f22d97429926d433552174507586c1ff9df3cabd" , "size" : 383810 } , { "id" : "14336272-ae94-1b83-2193-158c3f6afcef" , "document_id" : "3a691e84-8922-3de1-8819-53b85e54c559" , "mime_type" : "application/pdf" , "file_name" : "Inside Front Cover - Scope & Editors" , "filehash" : "12aa3051a009fa6e9ab5983e68b8fd3302b57690" , "size" : 42641 } , { "id" : "2e0daf4b-bb2d-8979-0c1f-a7f44f456d29" , "document_id" : "99ff5452-0aab-333c-9c81-79329146c2fb" , "mime_type" : "application/pdf" , "file_name" : "MapReduce Online" , "filehash" : "6c577e7518c8dfcf472f3be7e5686d4bcbbc4c45" , "size" : 553896 } ] for file in mendeley . files . iter (): print file . filehash FileList fileList = sdk . getFiles (); List < File > files = fileList . files ; Page next = fileList . next ;
Returns a list of files in your library.
HTTP Request
GET https://api.mendeley.com/files
Query Parameters
Parameter Type Description
document_id When this is provided, the response will contain only the files attached to that particular document.
group_id When this is provided, the response will contain only the files attached to documents that belong to that particular group.
added_since Response will only contain those files uploaded since the ‘added_since’ date. This date should be an ISO 8601 timestamp.
deleted_since Response will only contain those files deleted since this date. It should be an ISO 8601 timestamp.
Downloading a file
curl 'https://api.mendeley.com/files/16bd4f6e-4578-3391-356d-66b374143457' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' path = doc . download_file ( '/tmp' ) MendeleySdk asyncSdk = MendeleySdkFactory . getInstance (); GetFileCallback getFileCallback = new GetFileCallback () { ... } asyncSdk . getFile ( "16bd4f6e-4578-3391-356d-66b374143457" , "/sdcard" , getFileCallback );
Downloads a file.
HTTP Request
GET /files/{id}
Returns
On a successful request the server will respond with a 303 See Other response together with a Location header. The URL in this location header is signed for a limited period of time where the file can be downloaded.
Uploading a file
curl 'https://api.mendeley.com/files' \ -X POST \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/pdf' \ -H 'Content-Disposition: attachment; filename="example.pdf"' \ -H 'Link: <https://api.mendeley.com/documents/cfb60e27-d3e4-397d-bb59-fc8388b98152>; rel="document"' \ --data-binary @example.pdf file = doc . attach_file ( 'example.pdf' ) PostFileCallback postFileCallback = new PostFileCallback () { ... } asyncSdk . postFile ( "application/pdf" , "cfb60e27-d3e4-397d-bb59-fc8388b98152" , "/sdcard/example.pdf" , postFileCallback );
Uploads a file.
Header Parameters
The following header parameters must be set.
Parameter Description
Content-Type This header will tell the server the file’s media type. For example, application/pdf.
Content-Disposition This header is used to extract the file’s name. The value should be, for example: attachment; filename=“example.pdf”
Link We use this header to specify the document that the file should be attached to. For example: https://api.mendeley.com/documents/cfb60e27-d3e4-397d-bb59-fc8388b98152
Returns
A successful request will respond with a 201 Created code and a Location header where you can find the URL where you can download the file.
Linking a file content to a file
Creates a file based on a file content ticket obtained from /file_contents endpoint
curl 'https://api.mendeley.com/files' \ -X POST \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-file.1+json' \ -H 'Content-Disposition: attachment; filename="file.pdf"' \ -H 'Content-Type: application/vnd.mendeley-file-link.1+json' \ -H 'Link: <https://api.mendeley.com/documents/34542a05-ca31-3f25-9280-678e81a8a848>; rel="document"' \ --data-binary '{"file_content_ticket" : "<FILE_CONTENT_TICKET_ID>"}'
Header Parameters
The following header parameters must be set.
Parameter Description
Accept application/vnd.mendeley-file.1+json
Content-Type application/vnd.mendeley-file-link.1+json
Content-Disposition This header is used to extract the file’s name. The value should be, for example: attachment; filename=“example.pdf”
Link We use this header to specify the document that the file should be attached to. For example: https://api.mendeley.com/documents/cfb60e27-d3e4-397d-bb59-fc8388b98152
Returns
A successful request will respond with a 201 Created code and a Location header where you can find the URL where you can download the file.
Deleting a file
curl 'https://api.mendeley.com/files/16bd4f6e-4578-3391-356d-66b374143457' \ -X DELETE \ -H 'Authorization: Bearer <ACCESS_TOKEN>' file . delete () DeleteFileCallback deleteFileCallback = new DeleteFileCallback () { ... } asyncSdk . deleteFile ( "16bd4f6e-4578-3391-356d-66b374143457" , deleteFileCallback );
Deletes a file.
HTTP Request
DELETE /files/{id}
Returns
A successful request will respond with a 204 No Content code. Files are permanently deleted and cannot be recovered.
File Content
File Content attributes
Attribute Type Description
id string The unique identifier for the content.
file_hash string sha-256 calculated from file to upload
signature string sha-256 calculated from concatenated profile id (UUID) and file to upload
Uploading file content
curl 'https://api.mendeley.com/file_contents' \ -X POST \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/pdf' \ -H 'Accept: application/vnd.mendeley-content-ticket.1+json' \ --data-binary @example.pdf { "id" : "3f2f968f-553b-467d-8121-ba02cab937a0" }
Uploads a file by sending its content as a payload.
HTTP Request
POST https://api.mendeley.com/file_contents
Headers
Parameter Type Description
Content-Type string The mime type of the file. More info on mime types here .
Returns
A 201 OK response containing a JSON object with the id for the content.
Uploading file contents via file hash with signature
curl 'https://api.mendeley.com/file_contents' \ -X POST \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-file-hash.1+json' \ -H 'Accept: application/vnd.mendeley-content-ticket.1+json' \ --data-binary '{"file_hash" : "4dab806d72af4224a5cfa168669dac17", "signature" : "7e280ae47152d6f39ddf7452fad300cf721c7b5c7487dfee434be0171e5031e1"}' { "id" : "3f2f968f-553b-467d-8121-ba02cab937a0" }
Uploads a file by sending a hash calculated from the file itself alongside a signature calculated from concatenated profile id (UUID) and the file itself.
HTTP Request
POST https://api.mendeley.com/file_contents
Returns
A 201 OK response containing a JSON object with the id for the content.
A 412 Precondition Failed response when fileHash or signature are invalid
Folders
Folder attributes
Attribute Type Description
id string id of the folder
name string name of the folder
parent_id string id of the parent folder
group_id string id of the owning group
created string date the folder was created. This date is represented in ISO 8601 format.
modified string date the folder was modified. This date is represented in ISO 8601 format.
List all folders
curl 'https://api.mendeley.com/folders' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-folder.1+json' [ { "id" : "68624820-2f4c-438d-ae54-ae2bc431cee3" , "name" : "API Related Papers" , "created" : "2014-04-08T10:11:40.000Z" } , { "id" : "1cb47377-e3a1-40dd-bd82-11aff83a46eb" , "name" : "MapReduce" , "created" : "2014-07-02T13:19:36.000Z" } ] FolderList folderList = sdk . getFolders (); List < Folder > folders = folderList . folders ; Page next = folderList . next ;
Retrieves a list of folders.
HTTP Request
GET https://api.mendeley.com/folders
Query Parameters
Parameter Type Description
group_id string returns all folders in a particular group.
limit string maximum number of entries to be returned
marker string a marker for the last key in the previous page (automatically generated, here for completeness)
Returns
Returns a paginated collection of all of the folders in the user’s library.
Creating a folder
curl 'https://api.mendeley.com/folders' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-folder.1+json' \ -H 'Content-Type: application/vnd.mendeley-folder.1+json' \ --data-binary $' { "name" : "My favourite publications" } '
{
"id": "a6433ad4-e694-498d-8134-b06d356e7f17",
"name": "My favourite publications",
"created": "2014-07-02T13:27:52.000Z"
} Folder folder = new Folder . Builder (). setName ( "My favourite publications" ). build (); sdk . postFolder ( folder );
Creates a folder.
HTTP Request
POST https://api.mendeley.com/folders
Returns
A successful request will return a 201 and the newly created folder will be returned in the body.
Updating a folder
curl 'https://api.mendeley.com/folders/a6433ad4-e694-498d-8134-b06d356e7f17' \ -X PATCH
-H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-folder.1+json' \ --data-binary $' { "name" : "My API Publications" } ' Folder amendment = new Folder . Builder (). setName ( "My API Publications" ). build (); sdk . patchFolder ( "a6433ad4-e694-498d-8134-b06d356e7f17" , amendment );
Update the name and parent_id of a folder.
HTTP Request
PATCH https://api.mendeley.com/folders/{id}
URL Parameters
Parameter Type Description
id string Identifier of the folder
Returns
A 204 No Content response.
Deleting a folder
curl 'https://api.mendeley.com/folders/a6433ad4-e694-498d-8134-b06d356e7f17' \ -X DELETE
-H 'Authorization: Bearer <ACCESS_TOKEN>' \ sdk . deleteFolder ( "a6433ad4-e694-498d-8134-b06d356e7f17" );
Deletes a folder.
HTTP Request
DELETE /folders/{id}
URL Parameters
Parameter Type Description
id string Identifier of the folder
Returns
A successful request will return a 204 No Content.
Retrieving documents in a folder
curl 'https://api.mendeley.com/folders/68624820-2f4c-438d-ae54-ae2bc431cee3/documents' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-document.1+json' [ { "id" : "2bf33ebd-7cd1-3786-903d-d74d04958e40" } , { "id" : "dc9c7b4d-4221-3872-8f78-817f6e125486" } , { "id" : "9cd2fd1b-ec10-3bf8-a46f-d60e1b709075" } , { "id" : "3078c081-717e-3525-81d7-c8e4b1cb9226" } , { "id" : "f86a9bac-34ae-347f-860a-6687b38b18dc" } , { "id" : "c395c80e-3112-3b1f-aebc-b3944cc2f8e9" } ] DocumentIdList docIdList = sdk . getFolderDocumentIds ( null , "68624820-2f4c-438d-ae54-ae2bc431cee3" ); List < DocumentId > docIds = docIdList . documentIds ; Page next = docIdList . next ;
Retrive documents in a folder.
HTTP Request
GET https://api.mendeley.com/folders/{id}/documents
URL Parameters
Parameter Type Description
id string Identifier of the folder
limit string number of items to return
Returns
A paginated collection of IDs of the documents in the folder.
Adding a document to a folder
Adds a document to a folder
curl 'https://api.mendeley.com/folders/68624820-2f4c-438d-ae54-ae2bc431cee3/documents' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-document.1+json' \ --data-binary $' { "id" : "cb58a7d9-8463-34e2-b1b8-457a3872ecdc" } ' sdk . postDocumentToFolder ( "68624820-2f4c-438d-ae54-ae2bc431cee3" , "cb58a7d9-8463-34e2-b1b8-457a3872ecdc" );
HTTP Request
POST https://api.mendeley.com/folders/{id}/documents
URL Parameters
Parameter Type Description
id string Identifier of the folder
Returns
A 201 Created response.
Deleting a document from a folder
Deletes a document from a folder.  This will remove the relationship between the folder and the document, but you can still access the document in your library or group.
curl 'https://api.mendeley.com/folders/68624820-2f4c-438d-ae54-ae2bc431cee3/documents/cb58a7d9-8463-34e2-b1b8-457a3872ecdc' \ -X DELETE \ -H 'Authorization: Bearer <ACCESS_TOKEN>' sdk . DeleteDocumentFromFolder ( "68624820-2f4c-438d-ae54-ae2bc431cee3" , "cb58a7d9-8463-34e2-b1b8-457a3872ecdc" );
HTTP Request
DELETE https://api.mendeley.com/folders/{id}/documents/{document_id}
URL Parameters
Parameter Type Description
id string Identifier of the folder
document_id string Identifier of the document to be deleted
Returns
A 204 No Content response.
Followers
Follower resource represent a relationship follower/followee.
Followers attributes
Attribute Type Description
id string UUID of the relationship
follower_id string UUID of the following profile
followed_id string UUID of the followed profile
status string Can be following or pending (for not yet accepted requests)
Retrieve the list of followers
Retrieve all the follow relationships for which the specified profile is the followee
curl 'https://api.mendeley.com/followers?followed=c0925ecf-4de0-3b61-ae9a-ebe5f7406327' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-follow.1+json' [ { "id" : "15e75590-a1e8-31b5-b0ff-1777b27806a6" , "follower_id" : "b84e3c54-55ad-35b3-9102-1b8ae5c13714" , "followed_id" : "c0925ecf-4de0-3b61-ae9a-ebe5f7406327" , "status" : "following" } , { "id" : "48cd5bcf-196c-3aac-a658-1d96bd77f2c9" , "follower_id" : "3c1c23ad-4dca-3065-86e4-5a168459a171" , "followed_id" : "c0925ecf-4de0-3b61-ae9a-ebe5f7406327" , "status" : "following" } , ... ]
HTTP Request
GET https://api.mendeley.com/followers?followed={followed_id}
URL Parameters
Parameter Type Description
followed_id string UUID of the profile for which the follower will be retrieved
status string (optional) Limit the results of the query to following or pending relationships
limit int The maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500.
Returns
A 200 response containing a paginated list of follow relationships.
Retrieve the list of followees
Retrieve all the follow relationships for which the specified profile is the follower
curl 'https://api.mendeley.com/followers?follower=c0925ecf-4de0-3b61-ae9a-ebe5f7406327' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-follow.1+json' [ { "id" : "0f68a3e7-2cfd-3ca7-beaf-969914c98b0b" , "follower_id" : "c0925ecf-4de0-3b61-ae9a-ebe5f7406327" , "followed_id" : "b84e3c54-55ad-35b3-9102-1b8ae5c13714" , "status" : "following" } , { "id" : "275bc168-5fc9-3d42-a5d0-821244e866fe" , "follower_id" : "c0925ecf-4de0-3b61-ae9a-ebe5f7406327" , "followed_id" : "3c1c23ad-4dca-3065-86e4-5a168459a171" , "status" : "following" } , ... ]
HTTP Request
GET https://api.mendeley.com/followers?follower={follower_id}
URL Parameters
Parameter Type Description
follower_id string UUID of the profile for which the followees will be retrieved
status string (optional) Limit the results of the query to following or pending relationships
limit int The maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500.
Returns
A 200 response containing a paginated list of follow relationships.
Follow a profile
Create a follow relationship with the logged profile as followers and the followed profile specified in the body.
curl -X POST 'https://api.mendeley.com/followers' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-follow-request.1+json' \ --data-binary '{"followed" : "c0925ecf-4de0-3b61-ae9a-ebe5f7406327"}' { "id" : "ba7073da-ec89-347a-9651-6f46235f93a3" , "follower_id" : "618fbf26-cd24-39d4-a49f-ceddccccfeb0" , "followed_id" : "c0925ecf-4de0-3b61-ae9a-ebe5f7406327" , "status" : "following" }
HTTP Request
POST https://api.mendeley.com/followers
Returns
A 201 Created response containing the follow object.
Accept a follow request
Change the status of a relationship from pending to following .
curl -X PATCH 'https://api.mendeley.com/followers/135e5b6e-ba36-3321-a33e-986ae35779bb' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-follow-acceptance.1+json' \ --data-binary '{"status" : "following"}' { "id" : "135e5b6e-ba36-3321-a33e-986ae35779bb" , "follower_id" : "105da48f-4201-37cf-9e2f-67c49c0707b0" , "followed_id" : "618fbf26-cd24-39d4-a49f-ceddccccfeb0" , "status" : "following" }
HTTP Request
PATCH https://api.mendeley.com/followers/{id}
URL Parameters
Parameter Type Description
id string UUID of the relationship
Returns
A 200 OK response containing the updated follow object.
Cancel follow request
Same procedure as Unfollow a profile
Reject follow request
Same procedure as Unfollow a profile
Unfollow a profile
Delete the follow relationship.
curl -X DELETE 'https://api.mendeley.com/followers/87fee9d4-3ea1-36fd-a2c4-ba2796564cb0' \ -H 'Authorization: Bearer <ACCESS_TOKEN>'
HTTP Request
DELETE https://api.mendeley.com/followers/{id}
URL Parameters
Parameter Type Description
id string UUID of the relationship
Returns
A 204 No Content response in case of success.
Groups
Group attributes
Attribute Type Description
id string Identifier (UUID) of the group. This identifier is set by the server on create and cannot be modified.
link string URL of the group page in Mendeley.
owning_profile_id string Profile identifier of the owner of the group.
access_level string Whether the group is public, private or invite_only. More on access levels below.
created string Date the group was created. This date is set by the server after a successful create reques and is represented in ISO 8601 format.
name string The name of the group.
description string Small description of what the group is about.
photo object The photo object contains the URL to the photo/logo of the group. There are three sizes available: original, standard and square.
webpage string Website of the group outside Mendeley.
disciplines array List of disciplines the group is part of.
tags array List of tags assigned to the group.
role string Role of the authenticated user in the group. More on group roles below.
Group roles
owner : the creator of the group.
admin : administrator of the group. Only owners and admins can make other members administrators.
normal : normal member of the group. Users can add new references, add files and start discussions in the newsfeed of the group.
follower : followers of the group. Only public groups can have followers. Followers cannot interact with other members, i.e. post in newsfeed and participate in discussions, nor add references to the group. This is a read-only access membership.
invited : person who has been invited to the group, but not accepted the invitation.  This is a read-only access membership.
Retrieving groups
curl 'https://api.mendeley.com/groups' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-group.1+json' [ { "name" : "Mendeley Advisor Group" , "description" : "This is an invite-only communication channel for Mendeley Advisors. Meet your fellow advisors from around the world, share papers, presentations, tips, and let us know how we're doing.  Also feel free to post your upcoming presentation to the \" Events Page \" by adding it here: www.mendeley.com/events. Add tips, tricks, and any relevant updates to the Mendeley Resource Center: http://resources.mendeley.com/" , "disciplines" : [ "Computer and Information Science" , "Social Sciences" , "Design" ] , "tags" : [] , "photo" : { "original" : "http://s3.amazonaws.com/mendeley-photos/bc/e8/bce8c532283273fb0f511321adcc2cafd07f5876.png" , "standard" : "http://s3.amazonaws.com/mendeley-photos/bc/e8/bce8c532283273fb0f511321adcc2cafd07f5876-standard.jpg" , "square" : "http://s3.amazonaws.com/mendeley-photos/bc/e8/bce8c532283273fb0f511321adcc2cafd07f5876-square.jpg" } , "webpage" : "http://resources.mendeley.com/" , "id" : "3463d2a0-f87e-3fea-a446-6c8287ce5a2f" , "created" : "2010-11-15T20:03:35.000Z" , "owning_profile_id" : "81727124-ca03-3684-ad66-90a4603bde26" , "link" : "http://www.mendeley.com/groups/665771/mendeley-advisor-group/" , "role" : "user" , "access_level" : "private" } , { "name" : "Mendeley API" , "description" : "A group for people interested in the Mendeley API." , "disciplines" : [ "Social Sciences" ] , "tags" : [] , "photo" : { "original" : "http://s3.amazonaws.com/mendeley-photos/bc/e8/bce8c532283273fb0f511321adcc2cafd07f5876.png" , "standard" : "http://s3.amazonaws.com/mendeley-photos/bc/e8/bce8c532283273fb0f511321adcc2cafd07f5876-standard.jpg" , "square" : "http://s3.amazonaws.com/mendeley-photos/bc/e8/bce8c532283273fb0f511321adcc2cafd07f5876-square.jpg" } , "webpage" : "http://dev.mendeley.com/" , "id" : "9da69ed0-9d44-3d5f-b999-970f41c94c35" , "created" : "2014-06-19T14:34:19.000Z" , "owning_profile_id" : "4afc0c0f-88ab-3aed-a20a-f50934fc83b1" , "link" : "http://www.mendeley.com/groups/4599001/mendeley-api/" , "role" : "owner" , "access_level" : "public" } ] for group in mendeley . groups . iter (): print group . name GroupList groupList = sdk . getGroups ( null ); List < Group > groups = groupList . groups ; Page next = groupList . next ;
Retrieve all groups a user belongs to.
HTTP Request
GET https://api.mendeley.com/groups
URL Parameters
Parameter Type Description
limit string the maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500
Returns
A paginated collection of groups.
Retrieving a group
curl 'https://api.mendeley.com/groups/9da69ed0-9d44-3d5f-b999-970f41c94c35' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-group.1+json' [ { "name" : "Mendeley API" , "description" : "A group for people interested in the Mendeley API." , "disciplines" : [ "Social Sciences" ] , "tags" : [] , "photo" : { "original" : "http://s3.amazonaws.com/mendeley-photos/bc/e8/bce8c532283273fb0f511321adcc2cafd07f5876.png" , "standard" : "http://s3.amazonaws.com/mendeley-photos/bc/e8/bce8c532283273fb0f511321adcc2cafd07f5876-standard.jpg" , "square" : "http://s3.amazonaws.com/mendeley-photos/bc/e8/bce8c532283273fb0f511321adcc2cafd07f5876-square.jpg" } , "webpage" : "http://dev.mendeley.com/" , "id" : "9da69ed0-9d44-3d5f-b999-970f41c94c35" , "created" : "2014-06-19T14:34:19.000Z" , "owning_profile_id" : "4afc0c0f-88ab-3aed-a20a-f50934fc83b1" , "link" : "http://www.mendeley.com/groups/4599001/mendeley-api/" , "role" : "owner" , "access_level" : "public" } ] group = mendeley . groups . get ( '9da69ed0-9d44-3d5f-b999-970f41c94c35' ) print group . name Group group = sdk . getGroup ( "9da69ed0-9d44-3d5f-b999-970f41c94c35" );
Retrieve a single group a user belongs to.
HTTP Request
GET https://api.mendeley.com/groups/{id}
URL Parameters
Parameter Type Description
id string unique id of the group
Returns
A 200 OK response with the group information.
Retrieving members from groups
curl 'https://api.mendeley.com/groups/9da69ed0-9d44-3d5f-b999-970f41c94c35/members' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-membership.1+json' [ { "profile_id" : "8349a3f4-8894-3910-81da-4f5d7a396e2a" , "role" : "user" , "joined" : "2014-07-02T00:13:10.000Z" } , { "profile_id" : "d9ef2853-d330-3427-b90f-eff3f3fc14a3" , "role" : "user" , "joined" : "2014-06-30T17:34:32.000Z" } , { "profile_id" : "caddcde9-bce7-3bd0-8762-c5058f92d910" , "role" : "user" , "joined" : "2014-07-01T08:32:29.000Z" } , { "profile_id" : "4afc0c0f-88ab-3aed-a20a-f50934fc83b1" , "role" : "owner" , "joined" : "2014-06-19T14:37:14.000Z" } , { "profile_id" : "27dcaab3-d366-3c39-83c9-a53e4961ac98" , "role" : "admin" , "joined" : "2014-06-19T14:34:19.000Z" } ] for member in group . members . iter (): print member . display_name GroupMembersList groupMembersList = sdk . getGroupMembers ( null , "9da69ed0-9d44-3d5f-b999-970f41c94c35" ); List < UserRole > roles = groupMembersList . userRoles ; List < String > memberProfileIds = new ArrayList < String >(); for ( UserRole role : roles ) { memberProfileIds . add ( role . profileId ); } Page next = groupMembersList . next ;
Returns information about the members in a group
HTTP Request
GET https://api.mendeley.com/groups/{id}/members
URL Parameters
Parameter Type Description
limit string the maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500.
Returns
A paginated collection of user roles.
Groups-V2
Group attributes
Attribute Type Description
id string Identifier (UUID) of the group. This identifier is set by the server on create and cannot be modified.
link string URL of the group.
owning_profile_id string Profile identifier of the owner of the group.
access_level string Whether the group is public, private or invite_only. More on access levels below.
created string Date the group was created. This date is set by the server after a successful create request and is represented in ISO 8601 format.
name string The name of the group.
description string Small description of what the group is about.
photo object The photo object contains the URL to the photo/logo of the group. There are three sizes available: original, standard and square.
webpage string Website of the group outside Mendeley.
disciplines array List of disciplines the group is part of.
tags array List of tags assigned to the group.
role string Role of the authenticated user in the group. More on group roles below.
Group roles
owner : owner of the group.
admin : administrator of the group. Only owners and admins can make other members administrators.
normal : normal member of the group. Users can add new references, add files and start discussions in the newsfeed of the group.
follower : followers of the group. Only public and invite-only groups can have followers. Followers cannot interact with other members, i.e. post in newsfeed and participate in discussions, nor add references to the group. This is a read-only access membership.
Group types
private : publically not visible, users can’t join nor follow, they have to be invited.
invite_only : publically visible, users can’t join, can follow, can ask to join.
public : publically visible, user can join or follow.
Creating group
curl -X POST "https://api.mendeley.com/groups/v2" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Content-Type: application/vnd.mendeley-group+json" \ -H "Accept: application/vnd.mendeley-group+json" \ --data-binary @new-group.json
new-group.json: { "name" : "New group" , "description" : "New group description" , "access_level" : "public" , "disciplines" : [ "Veterinary Science and Veterinary Medicine" ] , "tags" : [ "tag01" , "tag02" ] } Response: { "name" : "New group" , "description" : "New group description" , "disciplines" : [ "Veterinary Science and Veterinary Medicine" ] , "tags" : [ "tag01" , "tag02" ] , "photo" : { "standard" : "http://s3.amazonaws.com/mendeley-photos/awaiting.png" , "square" : "http://s3.amazonaws.com/mendeley-photos/disciplines/small/veterinary-science-and-veterinary-medicine.png" } , "id" : "efe1b21a-7d57-38bd-1d1e-314db97dc11a" , "created" : "2016-07-01T13:48:03.000Z" , "owning_profile_id" : "61eef301-26ac-2841-a143-c4c7ec1826af" , "link" : "http://api.mendeley.com/groups/v2/efe8b71a-7d57-38bd-9d1e-314db97dc21a" , "invite_only" : false , "public" : true , "role" : "owner" , "access_level" : "public" }
Retrieving groups
curl -X GET "https://api.mendeley.com/groups/v2" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Accept: application/vnd.mendeley-group-list+json" [ { "name" : "Some group" , "id" : "efe1b21a-7d57-38bd-1d1e-314db97dc11a" ,
... } , { "name" : "Another group" , "id" : "dee1b21a-7d57-38bd-1d1e-314db97dc11b" ,
... } ]
URL Parameters
Parameter Type Description
limit string the maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500.
Updating group
curl -X PATCH "https://api.mendeley.com/groups/v2/05bedb28-71ad-328b-82cb-9d6fb2e4ddf7" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Content-type: application/vnd.mendeley-group+json" \ -H "Accept: application/vnd.mendeley-group+json" \ --data-binary @patch_group.json
patch_group.json: { "name" : "New name" , "description" : "New description" , "disciplines" : [ "Veterinary Science and Veterinary Medicine" ] } Response: { "name" : "New name" , "id" : "05bedb28-71ad-328b-82cb-9d6fb2e4ddf7" "description" : "New description" , "disciplines" : [ "Veterinary Science and Veterinary Medicine" ] ,
... }
Deleting group
curl -X DELETE "https://api.mendeley.com/groups/v2/05bedb28-71ad-328b-82cb-9d6fb2e4ddf7" \ -H "Authorization: Bearer <ACCESS_TOKEN>"
Retrieving group
curl -X GET "https://api.mendeley.com/groups/v2/05bedb28-71ad-328b-82cb-9d6fb2e4ddf7" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Accept: application/vnd.mendeley-group+json" { "name" : "New name" , "id" : "05bedb28-71ad-328b-82cb-9d6fb2e4ddf7" "description" : "New description" , "disciplines" : [ "Veterinary Science and Veterinary Medicine" ] ,
... }
Retrieving popular groups
curl -X GET "https://api.mendeley.com/groups/v2/popular" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Accept: application/vnd.mendeley-group-list+json" [ { "name" : "New name" , "id" : "05bedb28-71ad-328b-82cb-9d6fb2e4ddf7" "description" : "New description" , "disciplines" : [ "Veterinary Science and Veterinary Medicine" ] ,
... } , { "name" : "Another group" , "id" : "6529abcd-71ad-328b-82cb-9d6fb2e4ddf7" "description" : "Another description" , "disciplines" : [ "Veterinary Science and Veterinary Medicine" ] ,
... } ]
URL Parameters
Parameter Type Description
limit int the maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500.
Retrieving group members
curl -X GET "https://api.mendeley.com/groups/v2/05bedb28-71ad-328b-82cb-9d6fb2e4ddf7/members" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Accept: application/vnd.mendeley-group-member-list+json" [ { "profile_id" : "17eef301-26fd-7641-a143-c4c7ec1822af" , "joined" : "2016-07-01T13:50:30.000Z" , "role" : "owner" } , { "profile_id" : "17eef301-26fd-2269-a143-c4c7ec1822af" , "joined" : "2016-07-01T13:50:30.000Z" , "role" : "admin" } ]
URL Parameters
Parameter Type Description
query string search query which is matched against members first or last name.
limit int the maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500.
Joining public group
curl -X POST "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/members" \ -H "Authorization: Bearer <ACCESS_TOKEN>"
Leaving public group
curl -X DELETE "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/members" \ -H "Authorization: Bearer <ACCESS_TOKEN>"
Following group
curl -X POST "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/followers" \ -H "Authorization: Bearer <ACCESS_TOKEN>"
Unfollowing group
curl -X DELETE "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/followers" \ -H "Authorization: Bearer <ACCESS_TOKEN>"
Removing member from group
curl -X DELETE "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/members/e9e11302-4887-30c8-88ec-fbded0cc22a3" \ -H "Authorization: Bearer <ACCESS_TOKEN>"
Updates member’s role
curl -X PATCH "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/members/e9e11302-4887-30c8-88ec-fbded0cc22a3" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Content-type: application/vnd.mendeley-group-membership+json" \ -H "Accept: application/vnd.mendeley-group-membership+json" \ --data-binary @new_membership.json
new_membership.json: { "membership" : "admin" } Response: { "profile_id" : "e9e11302-4887-30a1-88ec-fbded0cc22a3" , "joined" : "2016-07-01T14:03:26.000Z" , "role" : "admin" }
Inviting users
Note: Sending email is currently disabled
curl -X POST "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/invitations" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Content-type: application/vnd.mendeley-group-invitation+json" \ -H "Accept: application/vnd.mendeley-group-invitation-response-list+json" \ --data-binary @invitations.json
invitations.json: { "recipients" : [ { "email" : "email1@abc.com" } , { "email" : "email2@abc.com" } , { "email" : "email3@abc.com" } ] , "message" : "Custom invitation message which should be included in the mail" } Response: [ { "email" : "email1@abc.com" , "invitation_uuid" : "4ea48e40-20c5-4ff9-8153-4ab0487bf1da" } , { "email" : "email2@abc.com" , "error_message" : "Use already in a group" } , { "email" : "email3@abc.com" , "invitation_uuid" : "153e8734-f879-4838-93f1-b0e69bc49041" , "warning_message" : "Email sending failure" } ]
Retrieving group invitations
curl -X GET "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/invitations" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Accept: application/vnd.mendeley-group-invitation-list+json" [ { "invitation_uuid" : "8aa48e40-20c5-4ff9-8111-12b0487bf1da" , "group_uuid" : "f8c54bf7-82ba-374a-8877-3cac3fc15c5f" , "invitee_email" : "email1@abc.com" , "status" : "SENT" , "sent" : "2016-07-04T14:54:03.000Z" , "message" : "Custom invitation message which should be included in the mail" } , { "invitation_uuid" : "a4a529b9-6b83-40f9-9191-6fb55699042f" , "invitee_profile_uuid" : "55686f2d-b821-3997-a968-2430d6e1eb1e" , "group_uuid" : "f8c54bf7-a5d5-374a-9283-3cac3fc15c5f" , "invitee_name" : "John Smith" , "invitee_email" : "email3@abc.com" , "status" : "CREATED" , "sent" : "2016-07-04T14:54:03.000Z" , "message" : "Custom invitation message which should be included in the mail" } ]
URL Parameters
Parameter Type Description
invitation_code string invitation code of a single invitation to retrieve. It’s a mean to distinguish a non-Mendeley user who was invited to the group from other non-Mendeley users.
limit int the maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500.
Retrieving user invitations
curl -X GET "https://api.mendeley.com/groups/v2/invitations" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Accept: application/vnd.mendeley-group-invitation-list+json" [ { "invitation_uuid" : "d5a85daa-8eb3-4857-a6b2-28e11a97ca96" , "invitee_profile_uuid" : "abc23f13-134a-3f51-906e-d81643ef7dc4" , "group_uuid" : "f8c54bf7-a5d5-374a-2177-3cac3fc15c5f" , "invitee_name" : "John Smith" , "invitee_email" : "email3@abc.com" , "status" : "SENT" , "sent" : "2016-07-04T15:08:45.000Z" , "message" : "Custom invitation message which should be included in the mail" } ]
URL Parameters
Parameter Type Description
limit int the maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500.
Accepting invitation
curl -X POST "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/invitations/d5a85daa-8eb3-4857-a6b2-28e11a97ca96/actions/accept" \ -H "Authorization: Bearer <ACCESS_TOKEN>"
Declining invitation
curl -X POST "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/invitations/d5a85daa-8eb3-4857-a6b2-28e11a97ca96/actions/decline" \ -H "Authorization: Bearer <ACCESS_TOKEN>"
Revoking invitation
curl -X POST "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/invitations/d5a85daa-8eb3-4857-a6b2-28e11a97ca96/actions/revoke" \ -H "Authorization: Bearer <ACCESS_TOKEN>"
Resending invitation
curl -X POST "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/invitations/d5a85daa-8eb3-4857-a6b2-28e11a97ca96/actions/resend" \ -H "Authorization: Bearer <ACCESS_TOKEN>"
Asking to join a group
curl -X POST "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/actions/join_request" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Content-type: application/vnd.mendeley-group-message+json" \ --data-binary @message.json
message.json: { "message" : "I would like to join your group" }
Accepting join request
curl -X POST "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/members/abc23f13-134a-3f51-906e-d81643ef7dc4/actions/accept" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Content-type: application/vnd.mendeley-group-message+json" \ --data-binary @message.json
message.json: { "message" : "I accept your request!" }
Declining join request
curl -X POST "https://api.mendeley.com/groups/v2/c0bdadf0-1592-38b3-a1e3-a8be3b1b8d6c/members/abc23f13-134a-3f51-906e-d81643ef7dc4/actions/decline" \ -H "Authorization: Bearer <ACCESS_TOKEN>" \ -H "Content-type: application/vnd.mendeley-group-message+json" \ --data-binary @message.json
message.json: { "message" : "I decline your request!" }
Identifier Types
Retrieve all identifier types
Retrieves all identifier types used.
curl 'https://api.mendeley.com/identifier_types' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-document-identifier.1+json' [ { "name" : "arxiv" , "description" : "arXiv ID" } , { "name" : "doi" , "description" : "DOI" } , { "name" : "isbn" , "description" : "ISBN" } , { "name" : "issn" , "description" : "ISSN" } , { "name" : "pmid" , "description" : "PubMed Unique Identifier (PMID)" } , { "name" : "scopus" , "description" : "Scopus identifier (EID)" } ] Not implemented . Not implemented .
HTTP Request
GET https://api.mendeley.com/identifier_types
Returns
A 200 OK response containing a all identifier types.
Institution Trees
An institution tree is a set of institutions that form a hierarchy, connected by the parent_id attribute, eg. Cambridge University -> University of Cambridge Pembroke College etc.
The id field within the response indicates the root institution.   An institution tree may be either partial or complete.  Partial infers that the root institution may have a parent,
whereas complete is where the root institution has no parent.
Institution tree attributes
Attribute Type Description
id string Identifier (UUID) of the root institution.  This should be used by tree walking algorithms, eg. to build the tree.
institution_nodes array List of institutions as institution objects.
Retrieving complete institution_trees
This institution_id parameter may be any institution within the returned tree, eg. it could be a leaf node.
curl 'https://api.mendeley.com/institution_trees?institution_id=7f821859-e00b-5e3c-ad18-a03ad306f343' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-institution.1+json' [ { "id" : "7f821859-e00b-5e3c-ad18-a03ad306f343" , "institution_nodes" : [ { "id" : "7f821859-e00b-5e3c-ad18-a03ad306f343" , "name" : "Christchurch Polytechnic Institute of Technology" , "city" : "Christchurch" , "state" : "" , "country" : "NZ" , "urls" : [ "www.cpit.ac.nz" ] , "alt_names" : [ { "name" : "Library Learning and Information Services - Te Ara Awhina i te Matauranga" } , { "name" : "CPIT" } ] } , { "id" : "575055ff-a851-577b-8ad4-9b8f938382e6" , "name" : "Christchurch Polytechnic Institute of Technology School of Nursing and Human Services" , "city" : "Christchurch" , "state" : "" , "country" : "NZ" , "parent_id" : "7f821859-e00b-5e3c-ad18-a03ad306f343" , "urls" : [ "www.cpit.ac.nz/schools/school_of_nursing" ] } ] } ] Not implemented . Not implemented .
HTTP Request
GET https://api.mendeley.com/institution_trees
URL Parameters
Parameter Type Description
institution_id string Contained institution node
Returns
A 200 OK response.
A 403 Forbidden, tree to large.
Retrieving partial institution_trees
The id passed in the URL will always be the root id of the resulting tree.
nb. A parent_id exists for this example, which differs from the root id, hence it is a partial tree.
curl 'https://api.mendeley.com/institution_trees/575055ff-a851-577b-8ad4-9b8f938382e6' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-institution.1+json' { "id" : "575055ff-a851-577b-8ad4-9b8f938382e6" , "institution_nodes" : [ { "id" : "575055ff-a851-577b-8ad4-9b8f938382e6" , "name" : "Christchurch Polytechnic Institute of Technology School of Nursing and Human Services" , "city" : "Christchurch" , "state" : "" , "country" : "NZ" , "parent_id" : "7f821859-e00b-5e3c-ad18-a03ad306f343" , "urls" : [ "www.cpit.ac.nz/schools/school_of_nursing" ] } ] } Not implemented . Not implemented .
HTTP Request
GET https://api.mendeley.com/institution_trees/{id}
Returns
A 200 OK response.
A 403 Forbidden, tree to large.
Institutions
Institution attributes
Attribute Type Description
id string Identifier (UUID) of the institution.
name string English name of the institution.
city string City.
state string State.
country string Country.
parent_id string Identifier (UUID) of the parent institution, where one exists.
urls array URLs associated with the institution.
alt_names array List of alternative names for the institution, as alt_name objects.
alt_names
An alternative name is represented as an object with the following attribute:
Attribute Type Description
name string Alternative name
Retrieving institutions by hint
Hint must be at least three characters in length.
Limited to 100 results.  If no limit is provided then up to 100 results will be returned.
Ordering of results is primarily based upon size of institution in terms of person count.
Name and alternative names are searched when retrieving by hint.
Hint is case insensitive.
curl 'https://api.mendeley.com/institutions?hint=mendel&limit=3' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-institution.1+json' [ { "id" : "914b908c-e917-58fe-8a66-4361f1abf95f" , "name" : "Mendel University Brno" , "city" : "Brno" , "state" : "" , "country" : "CZ" , "urls" : [ "www.mendelu.cz" ] , "alt_names" : [ { "name" : "Mendel University of Agriculture and Forestry" } , { "name" : "Mendelova Univerzita v Brn?" } , { "name" : "Mendelova Zemedelska a Lesnicka Univerzita v Brne" } , { "name" : "Mendelova univerzita v Brne" } , { "name" : "Mendel University in Brno" } ] } , { "id" : "af7cf891-ad7b-5ce9-8913-0515da40b8a7" , "name" : "Rossiiskii khimiko-tekhnologicheskii universitet imeni DI Mendeleeva" , "city" : "Moscow" , "state" : "" , "country" : "RU" , "urls" : [ "www.muctr.ru" ] , "alt_names" : [ { "name" : "MUCTR" } , { "name" : "Mendeleev University of Chemical Technology of Russia" } ] } , { "id" : "38fbed71-139f-5dbc-95f6-b41714220efd" , "name" : "Yeshiva University" , "city" : "New York" , "state" : "NY" , "country" : "US" , "urls" : [ "www.yu.edu" ] , "alt_names" : [ { "name" : "Pollack Library" } , { "name" : "Mendel Gottesman Library" } ] } ] Not implemented . Not implemented .
Retrieving institutions by email address
The email domain (everything to the right of the @ symbol) will be matched against the URLs (stripped of www prefix) of the institutions.
Exact matches, if any, will be returned above partial matches.
Ordering of results is primarily based upon size of institution in terms of person count.
Limited to 100 results.  If no limit is provided then up to 100 results will be returned.
curl 'https://api.mendeley.com/institutions?email=joe%40cam.ac.uk&limit=3' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-institution.1+json' [ { "id" : "9bb25e66-bd83-544e-b1b5-d0df25a29993" , "name" : "University of Cambridge" , "city" : "Cambridge" , "state" : "Cambridgeshire" , "country" : "GB" , "urls" : [ "www.cam.ac.uk" ] , "alt_names" : [ { "name" : "Cambridge University" } , { "name" : "University of Cambridge Betty and Gordon Moore Library" } , { "name" : "University of Cambridge Central Science Library" } ] } , { "id" : "162d9c14-ff65-5d59-89ab-77dffb2d0e04" , "name" : "University of Cambridge Department of Land Economy" , "city" : "Cambridge" , "state" : "Cambridgeshire" , "country" : "GB" , "parent_id" : "afd94196-b4a8-5453-a28f-79525ed43efc" , "urls" : [ "www.landecon.cam.ac.uk" ] , "alt_names" : [ { "name" : "Mill Lane Library" } ] } , { "id" : "dae880dd-777a-5746-a9ea-7ad1eeefa48d" , "name" : "University of Cambridge Institute of Manufacturing" , "city" : "Cambridge" , "state" : "Cambridgeshire" , "country" : "GB" , "parent_id" : "9dcf803c-32b9-501f-844c-ccfbcf36bad8" , "urls" : [ "www.ifm.eng.cam.ac.uk" ] } ] Not implemented . Not implemented .
Retrieving institutions by name
This search matches the exact (case insensitive) name provided against the institution name field.
City, state and country (or any combination) may also be given to limit the results where name has multiple matches.
Ordering of results is primarily based upon size of institution in terms of person count.
Limited to 100 results.  If no limit is provided then up to 100 results will be returned.
curl 'https://api.mendeley.com/institutions?limit=10&name=City%20University' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-institution.1+json' [ { "id" : "0e091aba-868f-5c72-8b0b-6e2ec9e289f5" , "name" : "City University" , "city" : "London" , "state" : "London" , "country" : "GB" , "urls" : [ "www.city.ac.uk" ] , "alt_names" : [ { "name" : "City University Centre for Investigative Security and Police Sciences" } , { "name" : "City University Library" } ] } , { "id" : "354eff87-07e7-5c9f-881b-a1fa3f5f4fa4" , "name" : "City University" , "city" : "Dhaka" , "state" : "Dhaka District" , "country" : "BD" , "urls" : [ "cityuniversity.edu.bd" ] , "alt_names" : [ { "name" : "CU" } ] } ] Not implemented . Not implemented .
HTTP Request
GET https://api.mendeley.com/institutions
URL Parameters
Parameter Type Description
hint string Part of institution name
email string Email address
name string Full institution name
city string City of institution
state string State of institution
country string Country of institution
limit integer Max number of results, defaults and limited to 100
Returns
A 200 OK response
Retrieve institution by id
curl 'https://api.mendeley.com/institutions/354eff87-07e7-5c9f-881b-a1fa3f5f4fa4' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-institution.1+json' { "id" : "354eff87-07e7-5c9f-881b-a1fa3f5f4fa4" , "name" : "City University" , "city" : "Dhaka" , "state" : "Dhaka District" , "country" : "BD" , "urls" : [ "cityuniversity.edu.bd" ] , "alt_names" : [ { "name" : "CU" } ] } Not implemented . Not implemented .
HTTP Request
GET https://api.mendeley.com/institutions/{id}
Returns
A 200 OK response
Locations
Suggest locations
Suggests possible locations for a given prefix. Suggestions will be provided in cases where:
an unaccented search term will return an accented suggestion e.g. Evreux will return Évreux
an accented search term will return an accented suggestion e.g. Évreux will return Évreux
an accented search term will return an unaccented suggestion e.g. ádḍîś äḅâbà will return Addis Ababa
curl 'https://api.mendeley.com/locations?prefix=LON&limit=3' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H "Accept: application/vnd.mendeley-location.1+json" [ { "id" : "cc185ce9-a459-43c5-849d-35ee6b8bfd05" , "latitude" : -13.92, "longitude" : -171.47, "name" : "Lona, Samoa" , "city" : "Lona" , "state" : "Rest of Upolu" , "country" : "Samoa" } , { "id" : "c8c1a5e9-841d-4e46-8796-35ee6b8b3839" , "latitude" : 39.6002, "longitude" : -79.0112, "name" : "Lonaconing, Maryland, United States" , "city" : "Lonaconing" , "state" : "Maryland" , "country" : "United States" } , { "id" : "d369b444-6741-4510-a9e1-35ee6b8b9a6a" , "latitude" : 19.98, "longitude" : 76.53, "name" : "Lonār, India" , "city" : "Lonār" , "state" : "Maharashtra" , "country" : "India" } ] Not implemented . Not implemented .
HTTP Request
GET https://api.mendeley.com/locations?prefix={prefix}&limit={limit}
Query Parameters
These are required query parameters.
Parameter Type Description
prefix string first few characters of a city
limit string the maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 100
Returns
A 200 OK response containing a all locations
Retrieve a location
Retrieves a location by a ID
curl 'https://api.mendeley.com/locations/c8c1a5e9-841d-4e46-8796-35ee6b8b3839' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H "Accept: application/vnd.mendeley-location.1+json" { "id" : "c8c1a5e9-841d-4e46-8796-35ee6b8b3839" , "latitude" : 39.6002, "longitude" : -79.0112, "name" : "Lonaconing, Maryland, United States" , "city" : "Lonaconing" , "state" : "Maryland" , "country" : "United States" } Not implemented . Not implemented .
HTTP Request
GET https://api.mendeley.com/locations/{id}
Query Parameters
These are required query parameters.
Parameter Type Description
id string Identifier (UUID) of the document. This identifier is set by the server on create and it cannot be modified.
Returns
A 200 OK response containing a single location
Profiles
Profile attributes
Parameter Type Description
id string Identifier (UUID) of the profile.
first_name string First name of the user. This is a required field.
last_name string Last name of the user. This is a required field.
location object Current location of the user. The location object has the following information: name, latitude, longitude.
display_name string Name of the user including their title.
email string Primary email of the user. This is used as username for login into Mendeley services. The email will only be exposed through the GET /profiles/me request, but it will never be exposed to other users.
research_interests string Comma separated list of research topics the user is interested in.
education array[Education] Collection of education objects. See below for documentation.
employment array[Employment] Collection of employment objects.See below for documentation.
academic_status string Current academic status of the profile. Possible values can be found by doing GET /academic_statuses.
link string URL to the Mendeley public profile page.
discipline Discipline Current research discipline. Possible values can be found by doing GET /disciplines.
disciplines array[Discipline] Additional research . Possible values can be found by doing GET /disciplines.
photo object (TO BE DEPRECATED - Please use Photos) The photo object contains the URL to the profile’s picture. There are three sizes available: original, standard and square.
photos array[Image] Collection of Image objects for the profile’s picture. Each Image contains width, height, URL and original where original is the initially uploaded photo
verified boolean Whether the profile has verified their email address or not.
created string Date when the profile was created. This date is set by the server on creation and is represented in ISO 8601 format.
biography string Biographical information
marketing boolean Opt in or out of marketing material
user_type UserType Possible types are ‘normal’ or 'devpartner’ or 'advisor’ or 'lead’ or 'staff’ or 'admin’
Education
Education is represented as an object with the following attributes:
Attribute Type Maximum length Description
institution string 255 Name of the institution.
degree string 100 Degree
start_date string - Start date at institution. This date is represented in ISO 8601 format.
end_date string - End date at institution. This date is represented in ISO 8601 format.
website string 255 Website of the institution.
Employment
Employment is representated as a on object with the following attributes:
Attribute Type Maximum length Description
institution string 255 Name of the institution.
position string 100 Position held at instituion.
degree string 100 Degree
start_date string - Start date at institution. This date is represented in ISO 8601 format.
end_date string - End date at institution. This date is represented in ISO 8601 format.
website string 255 Website of the institution.
classes array[String] - Classes thought at the institution.
is_main_employment boolean - True if this is your current employment, false otherwise.
Disciplines
People are represented as an object with the following attributes:
Attribute Type Maximum length Description
name string 255 Current research discipline. Possible values can be found by doing GET /disciplines.
subdisciplines array[String] - Subdisciplines.
Image
People are represented as an object with the following attributes:
Attribute Type Maximum length Description
width integer - Width of the photo.
height integer - Height of the photo.
original boolean - True if the this is the original photo that was uploaded.
url string - The S3 URL of the file in storage. Auto-generated.
Retrieving a profile
curl 'https://api.mendeley.com/profiles/c0925ecf-4de0-3b61-ae9a-ebe5f7406327' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-profiles.1+json' { "id" : "c0925ecf-4de0-3b61-ae9a-ebe5f7406327" , "first_name" : "Victor" , "last_name" : "Henning" , "display_name" : "Dr. Victor Henning" , "link" : "http://www.mendeley.com/profiles/victor-henning/" , "research_interests" : "Emotions, Decision Making, Theory of Reasoned Action, Intertemporal Choice, Motion Picture Economics" , "academic_status" : "Post Doc" , "disciplines" : [ { "name" : "Computer and Information Science" , "subdisciplines" : [ "Software Engineering" ] } ] , "photos" : [ { "url" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29.png" , "original" : true } , { "height" : 120, "url" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29-standard.jpg" , "original" : false } , { "width" : 48, "height" : 48, "url" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29-square.jpg" , "original" : false } , { "width" : 256, "height" : 256, "url" : "http://s3.amazonaws.com/mendeley-photos/awaiting_square_256.png" , "original" : false } ] , "verified" : true , "location" : { "latitude" : 52.37, "longitude" : 4.89, "name" : "Amsterdam, Netherlands" } , "created_at" : "2008-03-25T16:51:10.000Z" , "education" : [ { "institution" : "Wissenschaftliche Hochschule für Unternehmensführung - Otto Beisheim Graduate School of Management" , "degree" : "Dipl.-Kfm. (MBA)" , "start_date" : "2000-10-01" , "end_date" : "2004-08-01" , "website" : "http://www.whu.edu" } , { "institution" : "Université Libre de Bruxelles - Free University of Brussel" , "degree" : "" , "start_date" : "2002-01-01" , "end_date" : "2002-06-01" , "website" : "http://www.ulb.ac.be" } , { "institution" : "Handelshøyskolen BI - Norwegian School of Management BI" , "degree" : "" , "start_date" : "2002-08-01" , "end_date" : "2002-12-01" , "website" : "http://www.bi.no" } ] , "employment" : [ { "institution" : "Mendeley Ltd." , "position" : "Co-Founder & CEO" , "start_date" : "2007-11-01" , "website" : "www.mendeley.com" } , { "institution" : "Bauhaus-University of Weimar" , "position" : "Lecturer / Doctoral Student" , "start_date" : "2004-10-01" , "end_date" : "2010-12-01" , "website" : "www.uni-weimar.de" , "classes" : [ "The Kid Stays In The Picture: Economics of the Film Industry" , "Guru*Lab: Production and Distribution of a Major German Motion Picture" , "Guru*Talk: The Film Industry in the 21st Century" , "Hedonic Consumption" ] } , { "institution" : "Oliver Wyman Consulting" , "position" : "Summer Associate" , "start_date" : "2003-05-01" , "end_date" : "2003-08-01" , "website" : "www.oliverwyman.de" } , { "institution" : "Revelation Records" , "position" : "Product Management / PR Dept." , "start_date" : "2001-05-01" , "end_date" : "2001-08-01" , "website" : "www.revelation-records.com" } , { "institution" : "Helkon Media AG" , "position" : "Film Production / Business Affairs Dept." , "start_date" : "2002-06-01" , "end_date" : "2002-08-01" , "website" : "http://www.imdb.com/company/co0069136/" } , { "institution" : "Sony Music Entertainment/Columbia Records" , "position" : "Junior A&R, Talent Scout" , "start_date" : "2000-01-01" , "end_date" : "2000-10-01" , "website" : "www.sonymusic.de" } , { "institution" : "Elsevier" , "position" : "Co-Founder/CEO, Mendeley & VP Strategy" , "start_date" : "2013-04-01" , "is_main_employment" : true } ] } profile = mendeley . profiles . get ( 'c0925ecf-4de0-3b61-ae9a-ebe5f7406327' ) print profile . display_name Profile profile = sdk . getProfile ( "c0925ecf-4de0-3b61-ae9a-ebe5f7406327" );
Get a profile by ID.
HTTP Request
GET https://api.mendeley.com/profiles/{id}
Query Parameters
Parameter Type Description
id string UUID of a profile
Returns
A 200 OK response with the profile.
Retrieving profiles
curl 'https://api.mendeley.com/profiles' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-profiles.1+json' { "id" : "c0925ecf-4de0-3b61-ae9a-ebe5f7406327" , "first_name" : "Victor" , "last_name" : "Henning" , "display_name" : "Dr. Victor Henning" , "link" : "http://www.mendeley.com/profiles/victor-henning/" , "research_interests" : "Emotions, Decision Making, Theory of Reasoned Action, Intertemporal Choice, Motion Picture Economics" , "academic_status" : "Post Doc" , "disciplines" : [ { "name" : "Computer and Information Science" , "subdisciplines" : [ "Software Engineering" ] } ] , "photos" : [ { "url" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29.png" , "original" : true } , { "height" : 120, "url" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29-standard.jpg" , "original" : false } , { "width" : 48, "height" : 48, "url" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29-square.jpg" , "original" : false } , { "width" : 256, "height" : 256, "url" : "http://s3.amazonaws.com/mendeley-photos/awaiting_square_256.png" , "original" : false } ] , "verified" : true , "location" : { "latitude" : 52.37, "longitude" : 4.89, "name" : "Amsterdam, Netherlands" } , "created_at" : "2008-03-25T16:51:10.000Z" , "education" : [ { "institution" : "Wissenschaftliche Hochschule für Unternehmensführung - Otto Beisheim Graduate School of Management" , "degree" : "Dipl.-Kfm. (MBA)" , "start_date" : "2000-10-01" , "end_date" : "2004-08-01" , "website" : "http://www.whu.edu" } , { "institution" : "Université Libre de Bruxelles - Free University of Brussel" , "degree" : "" , "start_date" : "2002-01-01" , "end_date" : "2002-06-01" , "website" : "http://www.ulb.ac.be" } , { "institution" : "Handelshøyskolen BI - Norwegian School of Management BI" , "degree" : "" , "start_date" : "2002-08-01" , "end_date" : "2002-12-01" , "website" : "http://www.bi.no" } ] , "employment" : [ { "institution" : "Mendeley Ltd." , "position" : "Co-Founder & CEO" , "start_date" : "2007-11-01" , "website" : "www.mendeley.com" } , { "institution" : "Bauhaus-University of Weimar" , "position" : "Lecturer / Doctoral Student" , "start_date" : "2004-10-01" , "end_date" : "2010-12-01" , "website" : "www.uni-weimar.de" , "classes" : [ "The Kid Stays In The Picture: Economics of the Film Industry" , "Guru*Lab: Production and Distribution of a Major German Motion Picture" , "Guru*Talk: The Film Industry in the 21st Century" , "Hedonic Consumption" ] } , { "institution" : "Oliver Wyman Consulting" , "position" : "Summer Associate" , "start_date" : "2003-05-01" , "end_date" : "2003-08-01" , "website" : "www.oliverwyman.de" } , { "institution" : "Revelation Records" , "position" : "Product Management / PR Dept." , "start_date" : "2001-05-01" , "end_date" : "2001-08-01" , "website" : "www.revelation-records.com" } , { "institution" : "Helkon Media AG" , "position" : "Film Production / Business Affairs Dept." , "start_date" : "2002-06-01" , "end_date" : "2002-08-01" , "website" : "http://www.imdb.com/company/co0069136/" } , { "institution" : "Sony Music Entertainment/Columbia Records" , "position" : "Junior A&R, Talent Scout" , "start_date" : "2000-01-01" , "end_date" : "2000-10-01" , "website" : "www.sonymusic.de" } , { "institution" : "Elsevier" , "position" : "Co-Founder/CEO, Mendeley & VP Strategy" , "start_date" : "2013-04-01" , "is_main_employment" : true } ] } profile = mendeley . profiles . get ( 'c0925ecf-4de0-3b61-ae9a-ebe5f7406327' ) print profile . display_name Profile profile = sdk . getProfile ( "c0925ecf-4de0-3b61-ae9a-ebe5f7406327" );
Get a profile by ID.
HTTP Request
GET https://api.mendeley.com/profiles/{id}
Query Parameters
Parameter Type Description
id string UUID of a profile
Returns
A 200 OK response with the profile.
Retrieving the logged-in user’s profile
curl 'https://api.mendeley.com/profiles/me' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-profiles.1+json' { "id" : "9930207c-c19f-3de0-b531-86bd4388fa94" , "first_name" : "Jenny" , "last_name" : "Johnson" , "display_name" : "Jenny Johnson" , "email" : "matt.thomson+jenny@mendeley.com" , "link" : "http://www.mendeley.com/profiles/jenny-johnson4/" , "academic_status" : "Librarian" , "discipline" : { "name" : "Computer and Information Science" , "subdisciplines" : [ "Software Engineering" ] } , "disciplines" : [ { "name" : "Computer and Information Science" , "subdisciplines" : [ "Software Engineering" ] } ] , "photos" : [ { "url" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29.png" , "original" : true } , { "height" : 120, "url" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29-standard.jpg" , "original" : false } , { "width" : 48, "height" : 48, "url" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29-square.jpg" , "original" : false } , { "width" : 256, "height" : 256, "url" : "http://s3.amazonaws.com/mendeley-photos/awaiting_square_256.png" , "original" : false } ] , "verified" : false , "user_type" : "normal" , "created" : "2014-08-26T15:24:45.000Z" } profile = mendeley . profiles . me print profile . display_name Profile profile = sdk . getMyProfile ();
HTTP Request
GET https://api.mendeley.com/profiles/me
Returns
A 200 OK response containing the profile of the logged-in user.
Updating the logged-in user’s profile
curl 'https://api.mendeley.com/profiles/me' \ -X PATCH \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Content-Type: application/vnd.mendeley-profile-amendment.1+json' \ --data-binary '{"title": "Dr.", "biography": "Knowledge Discovery products and R&D activities"}' { "id" : "4afc0c0f-88ab-3aed-a20a-f50934fc83b1" , "first_name" : "Joyce" , "last_name" : "Stack" , "display_name" : "Dr. Joyce Stack" , "email" : "joyce.stack@mendeley.com" , "link" : "http://www.mendeley.com/profiles/joyce-stack1/" , "institution" : "Imperial College" , "academic_status" : "Other Professional" , "discipline" : { "name" : "Computer and Information Science" , "subdisciplines" : [ "Software Engineering" ] } , "disciplines" : [ { "name" : "Computer and Information Science" , "subdisciplines" : [ "Software Engineering" ] } ] , "photo" : { "original" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29.png" , "standard" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29-standard.jpg" , "square" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29-square.jpg" } , "photos" : [ { "url" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29.png" , "original" : true } , { "height" : 120, "url" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29-standard.jpg" , "original" : false } , { "width" : 48, "height" : 48, "url" : "http://s3.amazonaws.com/mendeley-photos/6a/bd/6abdab776feb7a1fd4e5b4979ea9c5bfc754fd29-square.jpg" , "original" : false } , { "width" : 256, "height" : 256, "url" : "http://s3.amazonaws.com/mendeley-photos/awaiting_square_256.png" , "original" : false } ] , "verified" : true , "marketing" : false , "user_type" : "admin" , "location" : { "latitude" : 51.513, "longitude" : -0.123, "name" : "London, United Kingdom" } , "created" : "2013-10-08T09:26:16.000Z" , "employment" : [ { "institution" : "Mendeley" , "position" : "Developer Outreach" , "start_date" : "2013-10-01" , "website" : "http://dev.mendeley.com" , "is_main_employment" : true } ] , "title" : "Dr." , "biography" : "Knowledge Discovery products and R&D activities" } Not yet implemented Not yet implemented
HTTP Request
PATCH https://api.mendeley.com/profiles/me
Returns
A successful update will return a HTTP 200 with the updated profile.
400 if the academic_status does not match a valid academic status as specified in Academic Statuses
409 if the email is already in use
422 is used for non-trivial error conditions such as multiple fields returning errors.
Profile search
The profiles returned have the same attributes as the Profiles API.
Search by query
Retrieve profiles which match general query terms.
curl 'https://api.mendeley.com/search/profiles?query=Politecnico+di+Milano' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-profile.1+json' [ { "id" : "..." , "first_name" : "..." , "last_name" : "..." , "display_name" : "...." , "link" : "https://www.mendeley.com/profiles/....." , "folder" : "..." , "institution" : "Student" , "institution_details" : { "name" : "Student" } , "research_interests_list" : [] , "academic_status" : "Student  > Master" , "discipline" : { "name" : "Computer Science" , "subdisciplines" : [] } , "disciplines" : [ { "name" : "Computer Science" , "subdisciplines" : [] } ] , "photo" : {} , "photos" : [] , "verified" : true , "user_type" : "normal" , "created" : 1234567891011, "employment" : [ { "id" : "...." , "institution_details" : { "name" : "Student" } , "institution" : "Student" , "position" : "Politecnico di Milano" , "start_date" : [ 1970, 1, 1 ] } ] , "visibility" : "all" } ]
HTTP Request
GET https://api.mendeley.com/search/profiles?query=Politecnico+di+Milano
URL Parameters
Parameter Type Description
query string Query terms, which match any field in the profile, e.g. name, discipline, etc ( required ).
limit int The maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 100.
Returns
A 200 response containing a paginated list of the matching profiles.
Trash
The documents returned have the same attributes as the Documents API.
Retrieve a trashed document
Retrieves a document from the trash.
curl 'https://api.mendeley.com/trash/183217fc-9c61-34d1-be8b-996556410ccb' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-document.1+json' { "id" : "183217fc-9c61-34d1-be8b-996556410ccb" , "title" : "MapReduce" , "type" : "journal" , "authors" : [ { "first_name" : "Jeffrey" , "last_name" : "Dean" } , { "first_name" : "Sanjay" , "last_name" : "Ghemawat" } ] , "year" : 2008, "source" : "Communications of the ACM" , "identifiers" : { "issn" : "00010782" , "pmid" : "11687618" , "doi" : "10.1145/1327452.1327492" , "isbn" : "9781595936868" } , "created" : "2013-10-16T09:24:45.000Z" , "profile_id" : "4afc0c0f-88ab-3aed-a20a-f50934fc83b1" , "last_modified" : "2014-06-19T10:12:05.000Z" , "abstract" : "MapReduce is a programming model and an associated implementation for processing ......" } doc = mendeley . trash . get ( '183217fc-9c61-34d1-be8b-996556410ccb' ) print doc . title Not implemented .
HTTP Request
GET https://api.mendeley.com/trash/{id}
Parameter Type Description
id string Identifier (UUID) of the document.
view string includes core document fields plus additional fields.
Returns
A 200 OK response containing a single document.
Retrieve all trashed documents
curl 'https://api.mendeley.com/trash' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-document.1+json' [ { "id" : "183217fc-9c61-34d1-be8b-996556410ccb" , "title" : "MapReduce" , "type" : "journal" , "authors" : [ { "first_name" : "Jeffrey" , "last_name" : "Dean" } , { "first_name" : "Sanjay" , "last_name" : "Ghemawat" } ] , "year" : 2008, "source" : "Communications of the ACM" , "identifiers" : { "issn" : "00010782" , "pmid" : "11687618" , "doi" : "10.1145/1327452.1327492" , "isbn" : "9781595936868" } , "created" : "2013-10-16T09:24:45.000Z" , "profile_id" : "4afc0c0f-88ab-3aed-a20a-f50934fc83b1" , "last_modified" : "2014-06-19T10:12:05.000Z" , "abstract" : "MapReduce is a programming model and an associated implementation for processing ......" } , { "id" : "e76d1e0d-c3fc-39af-83b4-a10e3d42cb28" , "title" : "Antler growth and extinction of Irish elk" , "type" : "journal" , "authors" : [ { "first_name" : "Ron A" , "last_name" : "Moen" } , { "first_name" : "John" , "last_name" : "Pastor" } , { "first_name" : "Yosef" , "last_name" : "Cohen" } ] , "year" : 1999, "source" : "Evolutionary Ecology Research" , "identifiers" : { "isbn" : "1522-0613" } , "created" : "2014-01-15T12:38:57.000Z" , "profile_id" : "4afc0c0f-88ab-3aed-a20a-f50934fc83b1" , "last_modified" : "2014-06-30T14:24:09.000Z" , "abstract" : "Adult male Irish elk (Megaloceros giganteus) grew the largest antlers of any extinct or extant cervid...." } , ] for doc in mendeley . trash . iter (): print doc . title DocumentList documentList = sdk . getTrashedDocuments (); List < Document > docs = documentList . documents ; Page next = documentList . next ;
Retrieves all documents in the trash.
HTTP Request
GET https://api.mendeley.com/trash
URL Parameters
Parameter Type Description
view string includes core document fields plus additional fields.
group_id string the id of the group that the document belongs to. If not supplied returns users documents.
modified_since string returns only documents modified since this timestamp. Should be supplied in ISO 8601 format
deleted_since string returns only documents deleted since this timestamp. Should be supplied in ISO 8601 format
limit string the maximum number of items on the page. If not supplied, the default is 20. The largest allowable value is 500
order string sort order
sort string field to sort on
Returns
A paginated collection of documents.
Restoring a document
curl 'https://api.mendeley.com/trash/183217fc-9c61-34d1-be8b-996556410ccb/restore' -X POST \ -H 'Authorization: Bearer <ACCESS_TOKEN>' restored_doc = doc . restore () sdk . restoreDocument ( "183217fc-9c61-34d1-be8b-996556410ccb" );
Restores a document from the trash.
HTTP Request
POST /trash/{id}/restore
URL Parameters
Parameter Type Description
id string Identifier (UUID) of the document.
Returns
A 204 No Content response.
Deleting a trashed document
curl 'https://api.mendeley.com/trash/183217fc-9c61-34d1-be8b-996556410ccb' \ -X DELETE \ -H 'Authorization: Bearer <ACCESS_TOKEN>' doc . delete () Not implemented .
Permanently deletes a document from the trash.
HTTP Request
DELETE /trash/{id}
URL Parameters
Parameter Type Description
id string Identifier (UUID) of the document.
Returns
A 204 No Content response.
Subject Areas
Retrieve all subject areas
Retrieves all subject areas.
curl 'https://api.mendeley.com/subject_areas' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-subject-area.1+json' [ { "name" : "Agricultural and Biological Sciences" , "subdisciplines" : [] } , { "name" : "Arts and Humanities" , "subdisciplines" : [] } , { "name" : "Biochemistry, Genetics and Molecular Biology" , "subdisciplines" : [] } , { "name" : "Business, Management and Accounting" , "subdisciplines" : [] } , { "name" : "Chemical Engineering" , "subdisciplines" : [] } , { "name" : "Chemistry" , "subdisciplines" : [] } , { "name" : "Computer Science" , "subdisciplines" : [] } , { "name" : "Decision Sciences" , "subdisciplines" : [] } , { "name" : "Design" , "subdisciplines" : [] } , { "name" : "Earth and Planetary Sciences" , "subdisciplines" : [] } , { "name" : "Economics, Econometrics and Finance" , "subdisciplines" : [] } , { "name" : "Energy" , "subdisciplines" : [] } , { "name" : "Engineering" , "subdisciplines" : [] } , { "name" : "Environmental Science" , "subdisciplines" : [] } , { "name" : "Immunology and Microbiology" , "subdisciplines" : [] } , { "name" : "Linguistics" , "subdisciplines" : [] } , { "name" : "Materials Science" , "subdisciplines" : [] } , { "name" : "Mathematics" , "subdisciplines" : [] } , { "name" : "Medicine and Dentistry" , "subdisciplines" : [] } , { "name" : "Neuroscience" , "subdisciplines" : [] } , { "name" : "Nursing and Health Professions" , "subdisciplines" : [] } , { "name" : "Pharmacology, Toxicology and Pharmaceutical Science" , "subdisciplines" : [] } , { "name" : "Philosophy" , "subdisciplines" : [] } , { "name" : "Physics and Astronomy" , "subdisciplines" : [] } , { "name" : "Psychology" , "subdisciplines" : [] } , { "name" : "Social Sciences" , "subdisciplines" : [] } , { "name" : "Sports and Recreations" , "subdisciplines" : [] } , { "name" : "Veterinary Science and Veterinary Medicine" , "subdisciplines" : [] } ] Not implemented . Not implemented .
HTTP Request
GET https://api.mendeley.com/subject_areas
Returns
A 200 OK response containing a all subject areas.
User Roles
Retrieve all user roles
Retrieves all user roles.
curl 'https://api.mendeley.com/user_roles' \ -H 'Authorization: Bearer <ACCESS_TOKEN>' \ -H 'Accept: application/vnd.mendeley-user-role.1+json' [ { "description" : "Lecturer" } , { "description" : "Lecturer > Senior Lecturer" } , { "description" : "Librarian" } , { "description" : "Other" } , { "description" : "Professor" } , { "description" : "Professor > Associate Professor" } , { "description" : "Researcher" } , { "description" : "Student  > Bachelor" } , { "description" : "Student  > Doctoral Student" } , { "description" : "Student  > Master" } , { "description" : "Student  > Ph. D. Student" } , { "description" : "Student  > Postgraduate" } ] Not implemented . Not implemented .
HTTP Request
GET https://api.mendeley.com/user_roles
Returns
A 200 OK response containing a all user roles.
Errors
The Mendeley API uses standard HTTP codes to provide the clients with information about whether the request has been successful or not.
In some cases we have used extensions to HTTP such as RFC-4918
Error Code Meaning
200 OK – The request was successful
201 Created – The request has been fulfilled and resulted in a new resource being created. The newly created resource can be referenced by the URI(s) returned in the Location header.
204 No content – The request was successful and no extra information will be provided in the body of the response.
400 Bad Request – The request you sent to the server is invalid.
401 Unauthorized – Your API key is wrong
403 Forbidden – Access to the resource is not allowed.
404 Not Found – The resource you were requesting cannot be found.
405 Method Not Allowed – The HTTP method (GET/POST/PUT/PATCH/DELETE) is not valid for this resource.
406 Not Acceptable – The media type in the Accept header is not valid for this resource.
409 Conflict – The resource conflicts with one that already exists.
412 Precondition Failed
415 Unsupported Media Type – The media type in the Content-Type header is not valid for this resource.
422 Unprocessable Entity – The server understands the request entity but was semantically erroneous. See RFC-4918
429 Too Many Requests - We’ve rate limited you. Contact api-support@mendeley.com.
500 Internal Server Error – We had a problem with our server. Try again later.
503 Service Unavailable – We’re temporarily offline for maintenance. Please try again later.
cURL

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 23:34:45 MSK -->
<!-- content-sha256: sha256:ae0c3dcd9c903c35e5f900abd3b2104255e2b608791d23e25e913bac05b42168 -->
<!-- FUM-MD-RECENCY:END -->
