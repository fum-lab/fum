# Извлечённый текст

Источник: <https://github.com/Roman-Kerimov/LinguisticKit/commit/837e2ce107b97ee7b9d3344c9fe99142281fe393>

## Содержимое

Add LinguisticKitBuildTool for JSON tables extraction · Roman-Kerimov/LinguisticKit@837e2ce · GitHub
Skip to content
Navigation Menu
Toggle navigation
Sign in
Appearance settings
Platform
AI CODE CREATION
GitHub Copilot Write better code with AI
GitHub Copilot app Direct agents from issue to merge
MCP Registry New Integrate external tools
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
Accelerator
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
Search or jump to...
Search code, repositories, users, issues, pull requests...
Search
Clear
Search syntax tips
Provide feedback
We read every piece of feedback, and take your input very seriously.
Include my email address so I can be contacted
Cancel Submit feedback
Saved searches
Use saved searches to filter your results more quickly
Name
Query
To see all available qualifiers, see our documentation .
Cancel Create saved search
Sign in
Sign up
Appearance settings
Resetting focus
You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert
Roman-Kerimov / LinguisticKit Public
Notifications You must be signed in to change notification settings
Fork 0
Star 1
Code
Issues 4
Pull requests 2
Actions
Projects
Security and quality 0
Insights
Additional navigation options
Code
Issues
Pull requests
Actions
Projects
Security and quality
Insights
Commit 837e2ce
Browse files Browse files
Roman-Kerimov
committed
Add LinguisticKitBuildTool for JSON tables extraction
1 parent 42b5aa1 commit 837e2ce
Copy full SHA for 837e2ce
20 file s changed
+ 7,720 - 42 Lines changed: 7720 additions & 42 deletions
File tree
Expand file tree Collapse file tree
Open diff view settings
Filter options
.swiftpm/xcode/package.xcworkspace
contents.xcworkspacedata
Extracted
ScriptTablesDescription
ContextValues.json
ScriptTables
az.json
be.json
bs.json
cnr.json
el.json
gr.json
ja.json
mk.json
ru.json
sr.json
uk.json
Scripts
caseSensitiveScripts.json
scripts.json
Package.swift
Sources
LinguisticKitBuildTool
main.swift
LinguisticKit
Script.swift
ScriptTable.RAWScriptTable.swift
ScriptTable.swift
Expand file tree Collapse file tree
Open diff view settings
Collapse file
‎ .swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata ‎
Copy file name to clipboard Expand all lines: .swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata
+ 1 - 1 Lines changed: 1 addition & 1 deletion
Load diff Some generated files are not rendered by default. Learn more about customizing how changed files appear on GitHub.
Collapse file
‎ Extracted/ScriptTables/az.json ‎
Copy file name to clipboard
+ 295 Lines changed: 295 additions & 0 deletions
Original file line number Diff line number Diff line change
@@ -0,0 +1,295 @@
1 +
{
2 +
"defaultScript" : " Latn " ,
3 +
"languageCode" : " az " ,
4 +
"name" : " az " ,
5 +
"table" : [
6 +
{
7 +
"postfixContext" : " any " ,
8 +
"prefixContext" : " any " ,
9 +
"scriptElements" : {
10 +
"Cyrl" : " а " ,
11 +
"Latn" : " a "
12 +
},
13 +
"type" : " vowel "
14 +
},
15 +
{
16 +
"postfixContext" : " any " ,
17 +
"prefixContext" : " any " ,
18 +
"scriptElements" : {
19 +
"Cyrl" : " б " ,
20 +
"Latn" : " b "
21 +
},
22 +
"type" : " consonant "
23 +
},
24 +
{
25 +
"postfixContext" : " any " ,
26 +
"prefixContext" : " any " ,
27 +
"scriptElements" : {
28 +
"Cyrl" : " ҹ " ,
29 +
"Latn" : " c "
30 +
},
31 +
"type" : " other "
32 +
},
33 +
{
34 +
"postfixContext" : " any " ,
35 +
"prefixContext" : " any " ,
36 +
"scriptElements" : {
37 +
"Cyrl" : " ч " ,
38 +
"Latn" : " ç "
39 +
},
40 +
"type" : " other "
41 +
},
42 +
{
43 +
"postfixContext" : " any " ,
44 +
"prefixContext" : " any " ,
45 +
"scriptElements" : {
46 +
"Cyrl" : " д " ,
47 +
"Latn" : " d "
48 +
},
49 +
"type" : " consonant "
50 +
},
51 +
{
52 +
"postfixContext" : " any " ,
53 +
"prefixContext" : " any " ,
54 +
"scriptElements" : {
55 +
"Cyrl" : " е " ,
56 +
"Latn" : " e "
57 +
},
58 +
"type" : " vowel "
59 +
},
60 +
{
61 +
"postfixContext" : " any " ,
62 +
"prefixContext" : " any " ,
63 +
"scriptElements" : {
64 +
"Cyrl" : " ә " ,
65 +
"Latn" : " ə "
66 +
},
67 +
"type" : " other "
68 +
},
69 +
{
70 +
"postfixContext" : " any " ,
71 +
"prefixContext" : " any " ,
72 +
"scriptElements" : {
73 +
"Cyrl" : " ф " ,
74 +
"Latn" : " f "
75 +
},
76 +
"type" : " consonant "
77 +
},
78 +
{
79 +
"postfixContext" : " any " ,
80 +
"prefixContext" : " any " ,
81 +
"scriptElements" : {
82 +
"Cyrl" : " ҝ " ,
83 +
"Latn" : " g "
84 +
},
85 +
"type" : " other "
86 +
},
87 +
{
88 +
"postfixContext" : " any " ,
89 +
"prefixContext" : " any " ,
90 +
"scriptElements" : {
91 +
"Cyrl" : " ғ " ,
92 +
"Latn" : " ğ "
93 +
},
94 +
"type" : " other "
95 +
},
96 +
{
97 +
"postfixContext" : " any " ,
98 +
"prefixContext" : " any " ,
99 +
"scriptElements" : {
100 +
"Cyrl" : " һ " ,
101 +
"Latn" : " h "
102 +
},
103 +
"type" : " consonant "
104 +
},
105 +
{
106 +
"postfixContext" : " any " ,
107 +
"prefixContext" : " any " ,
108 +
"scriptElements" : {
109 +
"Cyrl" : " х " ,
110 +
"Latn" : " x "
111 +
},
112 +
"type" : " other "
113 +
},
114 +
{
115 +
"postfixContext" : " any " ,
116 +
"prefixContext" : " any " ,
117 +
"scriptElements" : {
118 +
"Cyrl" : " ы " ,
119 +
"Latn" : " ı "
120 +
},
121 +
"type" : " other "
122 +
},
123 +
{
124 +
"postfixContext" : " any " ,
125 +
"prefixContext" : " any " ,
126 +
"scriptElements" : {
127 +
"Cyrl" : " и " ,
128 +
"Latn" : " i "
129 +
},
130 +
"type" : " vowel "
131 +
},
132 +
{
133 +
"postfixContext" : " any " ,
134 +
"prefixContext" : " any " ,
135 +
"scriptElements" : {
136 +
"Cyrl" : " ж " ,
137 +
"Latn" : " j "
138 +
},
139 +
"type" : " other "
140 +
},
141 +
{
142 +
"postfixContext" : " any " ,
143 +
"prefixContext" : " any " ,
144 +
"scriptElements" : {
145 +
"Cyrl" : " к " ,
146 +
"Latn" : " k "
147 +
},
148 +
"type" : " consonant "
149 +
},
150 +
{
151 +
"postfixContext" : " any " ,
152 +
"prefixContext" : " any " ,
153 +
"scriptElements" : {
154 +
"Cyrl" : " г " ,
155 +
"Latn" : " q "
156 +
},
157 +
"type" : " other "
158 +
},
159 +
{
160 +
"postfixContext" : " any " ,
161 +
"prefixContext" : " any " ,
162 +
"scriptElements" : {
163 +
"Cyrl" : " л " ,
164 +
"Latn" : " l "
165 +
},
166 +
"type" : " consonant "
167 +
},
168 +
{
169 +
"postfixContext" : " any " ,
170 +
"prefixContext" : " any " ,
171 +
"scriptElements" : {
172 +
"Cyrl" : " м " ,
173 +
"Latn" : " m "
174 +
},
175 +
"type" : " consonant "
176 +
},
177 +
{
178 +
"postfixContext" : " any " ,
179 +
"prefixContext" : " any " ,
180 +
"scriptElements" : {
181 +
"Cyrl" : " н " ,
182 +
"Latn" : " n "
183 +
},
184 +
"type" : " consonant "
185 +
},
186 +
{
187 +
"postfixContext" : " any " ,
188 +
"prefixContext" : " any " ,
189 +
"scriptElements" : {
190 +
"Cyrl" : " о " ,
191 +
"Latn" : " o "
192 +
},
193 +
"type" : " vowel "
194 +
},
195 +
{
196 +
"postfixContext" : " any " ,
197 +
"prefixContext" : " any " ,
198 +
"scriptElements" : {
199 +
"Cyrl" : " ө " ,
200 +
"Latn" : " ö "
201 +
},
202 +
"type" : " other "
203 +
},
204 +
{
205 +
"postfixContext" : " any " ,
206 +
"prefixContext" : " any " ,
207 +
"scriptElements" : {
208 +
"Cyrl" : " п " ,
209 +
"Latn" : " p "
210 +
},
211 +
"type" : " consonant "
212 +
},
213 +
{
214 +
"postfixContext" : " any " ,
215 +
"prefixContext" : " any " ,
216 +
"scriptElements" : {
217 +
"Cyrl" : " р " ,
218 +
"Latn" : " r "
219 +
},
220 +
"type" : " consonant "
221 +
},
222 +
{
223 +
"postfixContext" : " any " ,
224 +
"prefixContext" : " any " ,
225 +
"scriptElements" : {
226 +
"Cyrl" : " с " ,
227 +
"Latn" : " s "
228 +
},
229 +
"type" : " consonant "
230 +
},
231 +
{
232 +
"postfixContext" : " any " ,
233 +
"prefixContext" : " any " ,
234 +
"scriptElements" : {
235 +
"Cyrl" : " ш " ,
236 +
"Latn" : " ş "
237 +
},
238 +
"type" : " other "
239 +
},
240 +
{
241 +
"postfixContext" : " any " ,
242 +
"prefixContext" : " any " ,
243 +
"scriptElements" : {
244 +
"Cyrl" : " т " ,
245 +
"Latn" : " t "
246 +
},
247 +
"type" : " consonant "
248 +
},
249 +
{
250 +
"postfixContext" : " any " ,
251 +
"prefixContext" : " any " ,
252 +
"scriptElements" : {
253 +
"Cyrl" : " у " ,
254 +
"Latn" : " u "
255 +
},
256 +
"type" : " vowel "
257 +
},
258 +
{
259 +
"postfixContext" : " any " ,
260 +
"prefixContext" : " any " ,
261 +
"scriptElements" : {
262 +
"Cyrl" : " ү " ,
263 +
"Latn" : " ü "
264 +
},
265 +
"type" : " other "
266 +
},
267 +
{
268 +
"postfixContext" : " any " ,
269 +
"prefixContext" : " any " ,
270 +
"scriptElements" : {
271 +
"Cyrl" : " в " ,
272 +
"Latn" : " v "
273 +
},
274 +
"type" : " consonant "
275 +
},
276 +
{
277 +
"postfixContext" : " any " ,
278 +
"prefixContext" : " any " ,
279 +
"scriptElements" : {
280 +
"Cyrl" : " ј " ,
281 +
"Latn" : " y "
282 +
},
283 +
"type" : " other "
284 +
},
285 +
{
286 +
"postfixContext" : " any " ,
287 +
"prefixContext" : " any " ,
288 +
"scriptElements" : {
289 +
"Cyrl" : " з " ,
290 +
"Latn" : " z "
291 +
},
292 +
"type" : " consonant "
293 +
}
294 +
]
295 +
}
0 commit comments
Comments
0 ( 0 )
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
<!-- last-content-edit: 2026-07-21 12:41:09 MSK -->
<!-- content-sha256: sha256:d2ef0739188a1aee60d88bd271ee243b2ee76c80a3788fcf4b7e5ee83a6e24f2 -->
<!-- FUM-MD-RECENCY:END -->
