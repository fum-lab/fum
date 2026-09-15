# Извлечённый текст

Источник: <https://dev.mendeley.com/overview/core_resources.html>

## Содержимое

API Objects - Mendeley Developer Portal
Core API Resources
A guide to commonly used resource types in found in the Mendeley API
Documents
Documents are the reason Mendeley exists. Documents encapsulate the metadata for journal
articles, books, working papers, reports and more. Documents can be found in user libraries
or in the crowdsourced Catalog. More…
Files
File are references to media files and contain everything you need to know about a file.
Files can be downloaded and uploaded. Files are owned owned by documents and each can have
none, one or many files. More…
Groups
Groups let users work together and share resources. Groups can be public or private. Groups
contain profiles as members, are owned by a profile and can own documents. More…
Annotations
Annotations let users mark up and comment on documents. Annotations can highlight ranges of
text or attach sticky notes to a page. Annotations are attached to documents and are owned
by user profiles and groups. More…
The Mendeley API provides access to more objects adding richness to the platform objects above,
including profiles to combine user account metadata with academic history and folders to collate group documents.
Documents
Document objects represent a wide variety of research material including journal articles, books,
theses, working papers, reports, conferences, newspaper and magazine articles and web pages.
Documents contain metadata detailing the subject matter, external catalog references, the authors
and publishing process. Documents representing many diverse sources are described using a single
document object: the document type is declared through the type member of document. Documents do not contain the content media data — this data is
available through file references. Users enhance documents using annotations to highlight ranges of text or add notes.
Documents are found in two locations: users' and groups' libraries, and in the crowd-sourced Catalog. User documents and catalog documents have small differences depending on the
location: users or Mendeley can augment documents with new metadata additions.
Moving documents between locations creates a copy of the document: each document is only
found in a single location. To move a document, your application should copy the existing target
document's metadata and create a new document in the destination.
User Documents
Users create new documents using Mendeley's web and desktop tools or possibly your application.
User's documents can be stored in a user's library or in a group the user is a member of. User
documents, from a library or group, are accessed through the API resource /documents .
API requests can create, edit and remove any user documents the authorized user has permission to
access.
User documents differ from catalog documents because they can be:
edited, created and removed
linked with media content files
annotated with notes or highlights and tagged
added to, and removed from, groups and folders
Catalog documents:
Catalog documents are found in the Mendeley crowdsourced Catalog and are the starting point for
building a personalized research collection. Catalog documents are public, read-only and shared
between all users – API requests can search and retrieve catalog documents.
Searching and fetching from the catalog is possible through two API resources:
Metadata searches using terms from the document title, abstract, author names or year of
publication use the /search/catalog API resource.
Mendeley identifier or external scheme identifier fetches using types such as DOI, ISBN or
Scopus use the /catalog API resource.
Readership statistics are available for catalog documents because they are public and shared between
users. Statistics include the number of readers, their country locations, academic status and
discipline. See the sample code Readership
Locations for an example using catalog document statistics.
Catalog documents differ from user documents because they:
are read-only
can be requested using the client credentials OAuth flow
have reading statistics aggregated from all Mendeley users
have lower default and maximum values for paged result sets in API responses
External Identifier Schemes
Many documents may already exist in a number of recognized external catalogs: many papers include a
Digital Object Identifier (DOI), books an ISBN and magazines and journals an ISSN. All documents may
optionally have a number of identifiers for external schemes. A catalog document can be fetched,
from an external identifier, using the /catalog API resource.
Supported external schemes are:
DOI is a system, managed by the International DOI Foundation,
for assigning permanent identifiers to digital resources.
ArXiv is an archive, maintained by Cornell University, for
research in the field of physics, mathematics, computer science and statistics.
PubMed is a database of biomedical literature
and research in life sciences.
ISBN is the
International Standard Book Number assigned to all commercially published books
ISSN is the International Standard Serial Number assigned to a
journal or magazine.
Scopus is a database of abstracts and citations from
peer-reviewed literature.
The supported external schemes can be retrieved using the API's document_identifiers resource. See the sample code identifier_catalog_search.rb for
an example using external scheme identifier types.
Views
Each document contains a wealth of metadata applicable to a diverse range of source documents.
Delivering and parsing such a volume of data can be resource intensive and potentially not
neccessary in your application. To reduce network load times and memory footprint, your application
can request just the set of JSON members in the response it needs by using the view field in the request's HTTP query string:
GET /documents?view=client
GET /search/catalog?view=stats
Not specifying a value for view returns the core members of a document. Five values
represent the sets of additional JSON object members available to document requests:
bib Bibliographic metadata includes the location within a larger publication, publishing
process and publication date. Available to all document responses. client Client application metadata to assist tracking a document's reading and user engagement
status and populate a user interface. Available to all documents but richer metadata is
available for user documents. tags Tags are added by users from personal taxonomies to classify a document. Only available
to user documents. stats Statistics metadata includes the number of readers, their country locations, academic
status and discipline. Only available to catalog documents. all All available metadata will be included in the response. Available to all document
responses.
Common tasks
Determine if a document
for a PDF file exists within the Mendeley catalog
Files
File objects in the API are references to media resources attached to documents. Files contain
metadata about a media file but do not contain the file's text or binary contents — although, using
the API, it is possible to download files.
A file is always associated with a document. Creating a file requires an existing document reference
and removing a document also removes all the files attached to the document. A document can have
none, one or many files attached. User documents frequently have one or more file attachments while
Catalog documents, for copyright or commercial reasons, often do not have any file attachments. A
document can only attach a file once — attempting to re-upload an existing file to a document will
generate a 400 Bad Request response.
File objects frequently represent PDF files but can reference any type of text or binary file. Your
application should favor PDF files as this format provides the greatest opportunities for
interoperability and cooperation with the platform and other applications. The API will not alter or
change the media file your application uploads and an exact byte-for-byte duplicate will be
available through the API.
Common tasks
Checking if a document has
a file attached
Download a media file
Upload a media file
Updating a file object
Profiles
Profiles are the Mendeley users. Profiles combine personal characteristics with education, discipline
and employment metadata. Profiles have have names, email addresses, web links and portrait photos,
and can own documents and groups. Each profile combines:
personal information including given and family names, email addresses and personal or
professional web page links
portrait or avatar image uploaded by the user, scaled and cropped into three different
sizes
location coordinates and English language place name
academic status and discipline values chosen from controlled vocabularies
education history listing previous courses and qualifications achieved by the user
professional history listing employment positions held by the user
The API can be used to request the authorized user profile and profiles for members of Groups. The
API can be used to show the currently "logged-in" user and display group membership within a client
application. Profiles can not be created, edited or removed using the API, including the profile
representing the authorized user. Profiles can not be discovered outside of the authorized user's
existing circle of contacts.
Profiles use values from the disciplines platform object to define a
user's academic discipline and values from the academic_statuses platform object to define the current academic status.
Groups
Groups let profiles work together and share resources. Groups have metadata that describes and
identifies the group including a name, description and image. There are three types of group:
Private groups are not listed in Mendeley search results. Private groups are
the only groups able to share files. Users in a group are also able to share document
references. Private groups are best suited for privately sharing files. A private group has a
value of private for the access_level member.
Invite-Only groups are listed in Mendeley search results and group activity is
publicly listed on the Mendeley web site. Users are able to join the group on invitation from
the group's administrators. Users are able to share document references but not files.
Invite-only groups are best suited for privately sharing reading and reference lists. An
invite-only group has a value of invite_only for the access_level member.
Open groups are listed in Mendeley search results and group activity is
publicly listed on the Mendeley web site. Users are freely able to join open groups. Users are
able to share document references but not files. Open groups are best suited for widely sharing
reading lists. An open group has a value of public for the access_level member.
Groups can have an owner, administrators, members and followers. Each is represented by a profile or collection of profiles. The current authorized user's role
within a group can be determined by inspecting the role member of a group in an API
response.
Owner s of groups are a single user profile. Often this is the profile that
created the group initially but a profile may receive ownership as part of a transfer process.
Disk space for group document storage is allocated against the owner's account. Owners can
create administrators and can transfer ownership to another profile. Owners can remove profiles
from a group. The value of role is owner if the current authorized
user is the owner of the group.
Administrators are a collection of profiles within a group. Administrators can
create administrators from existing members. Administrators can remove profiles, except the
owner, from the group and can reduce the role of a profile within the group. The value of role is admin if the current authorized user is an administrator of
the group.
Members are a collection of profiles within a group. Members can contribute
documents and files to private groups and documents to invite-only and open groups. The value of role is member if the current authorized user is a member of the
group.
Followers are a collection of profiles within a group. Only invite-only and
open groups have followers. Followers effectively have read-only access to the group and can not
contribute documents. The value of role is follower if the current
authorized user is a follower of the group.
The owner of a group can be identified using the owning_profile_id member of a group API
response. Group membership size is limited by the owner's subscription.
Groups can not be created, edited or removed using the API and group membership can not be changed
using the API. Groups and membership should be managed using the Mendeley web and desktop
applications.
Groups can have documents submitted by owners, administrators and members. Private groups can contain
files for the documents. Documents and files are available to all members of the group. Documents
can be added to groups using the POST /documents/{id} request and specifying a group_id member in the body. Documents can be removed from a group using a DELETE /documents/{id} request.
Common tasks
Get documents for a group
Add a document to a group
Find the owner of a group
Annotations
Users mark up documents and files using annotations. Three types of annotations are available.
Notes are scoped to documents and provide a high-level comments using
styled text. Only a single note annotation can be attached to a document and subsequent attempts
to create further note annotations will fail. Note annotations have a value of note for the member type .
Highlights are scoped to files and highlight text ranges or elements
on the page. Highlight annotations are located by their bounding rectangles within a page.
Highlight annotations have a value of highlight for the member type .
Sticky notes are scoped to files and provide the ability to attach
short, plain text notes to elements on a page. Sticky notes have location within a page. Sticky
note annotations have a value of sticky_note for the member type .
Annotations are removed when the parent resource is removed. Removing a file, removes all the
highlight and sticky note annotations. Removing a document, removes all the annotations.
The author of an annotation is recorded in the profile_id member. Annotation collections
for a particular document, a group's documents or the authorized user can be requested through the
API using identifiers included in the request's HTTP query string.
Rendering and styles
Highlight and sticky note annotations have a location on a page. The location is defined by the
bounding rectangle and coordinates are available for the top-left and bottom-right. Sticky note
annotations must have zero dimensions so use the same point for the top-left and bottom-right
corners. Coordinates units are typographic points and are measured from the origin located in the lower-left corner of the page.
The Mendeley Desktop application supports rich text styling of note annotations using inline markup.
Styles are available to italicize, set bold weight, underline and set the alignment of text in
paragraphs. All annotations have a color member enabling your application to set an RGB
(8 bits per channel) color value to use as a background or highlight color. The Mendeley
applications do not currently use the color value but your application should be aware this
value may appear and be editable in the future.
Annotations on group documents
Documents in groups can be annotated. Your application can create or edit note, highlight and sticky
note annotations on documents in groups for authorized users who are group members.
All group members can update a document's note annotation. API requests can update and remove
highlight and sticky note annotations created by the authorized user.
Annotation visibility, on all documents not only group documents, is determined by the privacy_level member. A value of private indicates the annotation is only
visible to the authorized user and a value of group indicates the annotation is visible
to all group members. The group member who added a document to a group is able to create personal,
invisible annotations by supplying private as the value for privacy_level when creating an annotation using the API.
Your application should remember to copy annotations appropriately when duplicating documents. Note
annotations should accompany a document when copied from a user's library to a group. User's
highlight and sticky note annotations must not be copied or made available to the group
members.
Folders
Folders help users organize and group collections of documents. Folders can be created, edited, moved
and removed using the API. Folders can contain documents and other folders.
Folder names can contain any Unicode characters (from the Basic Multilingual Plane) up to a maximum
length of 255 characters. Folder names are required to create a folder and must be unique within the
container.
Folders can belong to a user's library or a group. Folders in a group can be created by members of
the group and are available to members of the group. Folders are listed for a group, or created in a
group, by including a value for group_id field in the HTTP query string for an API
request.
Folders can contain documents . A folder is not an exclusive location and
documents contained in a folder will be available through API resources /folders/{id}/documents and /documents . A document can appear in many
folders within a library or group. Removing a folder, does not remove the documents contained in the
folder, or any child folders. After removing a folder, the previously contained documents will be
available through the user's library or group.
Folders can contain other folders, and they in turn can contain other folders. Folder hierarchy is
maintained by a folder's link to a parent using a parent_id member value. Folders
located in the root level do not have a value for the parent_id member. Editing the
value for the parent_id member changes the folder's position in the hierarchy. Removing
a folder, also removes all descendent child folders in a cascading manner.
Common tasks
Create a folder inside an
existing folder
Create a folder in a
group
Move a folder into another folder
List the child folders of a
folder
Move a child folder to the root
level
Trash
Trash, as the name implies, is a location for documents that are no longer required. Trash can be
used to provide users with a chance to reconsider document removal before the document is
permanently deleted. Trash is used by Mendeley desktop, mobile and web applications but API requests
can remove documents from users' libraries or groups directly.
Trash is a separate location for documents. Documents in Trash do not appear in responses to requests
for other resources and manipulation of documents in Trash must be made using the /trash API resource. Documents can be moved into and out of Trash.
Common tasks
Move a document to Trash
Remove a document from Trash
Document types
Document types are a controlled vocabulary for a document's type member. Document types
can represent journal articles, books, working papers, magazine articles reports and many more.
As a reference resource, document types are read-only and can not be edited by the API. Document
types, being a reference resource, can be fetched using an access token from any OAuth authorization
flow.Document types can not be created, updated or deleted using the API. API responses return the
entire collection of documents types in response to a request for /document_types .
Each value is accompanied by a US English description of the term and this description is
suitable for populating user interface controls.
Your application should use the results of GET /document_types to present users with a
choice of types for a document and not rely on hard-coded lists of values. Your application can then
take advantage of future document type additions without an app update.
Common tasks
Populate user interface controls
for with document types
Identifier types
Identifier types are a controlled vocabulary listing the set of external identifier schemes available
to the API. See Document: Identifiers above. As a reference
resource, identifier types are read-only and can not be edited by the API. Identifier types, being a
reference resource, can be fetched using an access token from any OAuth authorization flow.
Identifier types can not be created, updated or deleted using the API. Controlled vocabularies are
most useful as a set, so the API returns the entire collection in response to a request to fetch the
values. The collection is not expected to change frequently or expand significantly.
Each value key is accompanied by a US English description of the term and this description
is suitable for populating user interface controls.
Your application should use the results of GET /identifier_types to present users with
a choice of identifiers for a document and not rely on hard-coded lists of values. Your application
can then take advantage of searching for documents future, new identifier types without requiring an
app update.
See the sample code identifier_catalog_search.rb for
an example using identifier types to populate a user interface.
Disciplines
Disciplines are a controlled vocabulary listing academic disciplines to define a user profile 's area of study. As a reference resource, disciplines are read-only and can not be
edited by the API. Disciplines, being a reference resource, can be fetched using an access token
from any OAuth authorization flow. Disciplines can not be created, updated or deleted using the API.
Controlled vocabularies are most useful as a set, so the API returns the entire collection in
response to a request to fetch the values.
Discipline values are British English language values. Each discipline is accompanied by a
list of sub-disciplines values to further refine interests using the profile's subdisciplines member.
Academic statuses
Academic statuses types are a controlled vocabulary for a profile's academic_status member. The set is available as US English language values. As a reference resource,
academic statuses are read-only and can not be edited by the API. Academic statuses, being a
reference resource, can be fetched using an access token from any OAuth authorization flow. Academic
statuses can not be created, updated or deleted using the API. Controlled vocabularies are most
useful as a set, so the API returns the entire collection in response to a request to fetch the
values.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 23:59:28 MSK -->
<!-- content-sha256: sha256:98e2a3592cd2acb06b9959e253417b6b90e7e5a9733548190b5f8e8e4968e0e3 -->
<!-- FUM-MD-RECENCY:END -->
