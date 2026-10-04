# Извлечённый текст

Источник: <https://github.com/fum-lab/fum/issues/26>

## Содержимое

Отделить минимальный бюджет доходного сценария FUM от исследовательской аппаратной сметы · Issue #26 · fum-lab/fum · GitHub
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
fum-lab / fum Public
Notifications You must be signed in to change notification settings
Fork 0
Star 1
Code
Issues 50
Pull requests 6
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
Отделить минимальный бюджет доходного сценария FUM от исследовательской аппаратной сметы #26
New issue
Copy link
New issue
Copy link
Open
Open
Отделить минимальный бюджет доходного сценария FUM от исследовательской аппаратной сметы #26
Copy link
Description
Roman-Kerimov
opened on Oct 3, 2026
Issue body actions
Цель и происхождение
Определить, сколько стоит проверить один оплачиваемый сценарий на доступных ресурсах и какие условия позволят покрывать эксплуатацию, труд и дальнейшее развитие. Сохранить долгосрочный аппаратный план, но не превращать покупку максимальной конфигурации в недоказанную предпосылку первой оплаты.
Поручение пользователя от 3 октября 2026 года: «Оформляй все необходимые ишью для этого» — продолжение обсуждения самофинансирования. Основа чтения: d86ee47861fae6672486010b64ab26308c82ec86 .
Развивать существующие бизнес-план и финансовую модель , поэтапный практический маршрут и пакет поддержки ограниченного этапа , а не заводить независимую смету. Фактические данные и определения стоимости брать из #25 .
Работа
Описать два самостоятельных профиля: минимальная проверка доходного сценария и исследовательская лаборатория. Для каждой позиции назвать способность, которую она обеспечивает, и доказательство необходимости. Подготовить вариант на фактически доступном оборудовании; доступность не выводить из обсуждавшейся покупки.
В обоих профилях учитывать труд, продажи и общение, проверку и сопровождение, подписки и API, хранение, резервные копии, связь, энергию, обязательные организационные расходы и резерв. Резерв задаётся явно с основанием, без произвольной маскировки неизвестных статей процентом.
Разделить капитальную покупку, эксплуатацию и замену оборудования, разовые и регулярные затраты. В денежном потоке не считать покупку повторно через амортизацию; в экономической стоимости использовать согласованное распределение. По кредиту отдельно показать получение, основной долг, проценты и комиссии.
Построить помесячный денежный поток на согласованный горизонт: свободный и целевой остаток, подтверждённое покрытие, обязательства и кассовый разрыв. Отдельно показать сценарии отсутствия новых донатов/грантов, задержки оплаты, роста вычислительных затрат и прекращения крупнейшего источника поддержки. Не выдавать эти сценарии за прогноз вероятности.
Для выбранного предложения рассчитать вклад одного принятого результата после переменных затрат, требуемую загрузку для покрытия постоянных расходов и достижимость этой загрузки с учётом часов человека. Если вклад неположителен либо входы неизвестны, явно показать отсутствие обоснованной точки безубыточности.
Сравнить обычный скрипт, доступную внешнюю модель и локальный вариант по сопоставимому принятому результату. Неподтверждённые скорости, цены, тарифы и налоги не заполнять догадками. Условия использования подписки не приравнивать к доступному API для клиентского сервиса.
Критерии приёмки
Профили разделены; исследовательская цель не отменена, но у каждой необходимой для первого сценария покупки есть основание либо статус «не доказано».
Модель использует согласованные определения Связать экономический паспорт результата FUM с учётом денег, труда и повторного использования #25 , явные валюты, даты цен и источники; неизвестные статьи не равны нулю.
Есть бюджет первого эксперимента, предел допустимого убытка, условия остановки и минимальный резерв на уже принятые обязательства.
Расчёты различают покрытие эксплуатации, покрытие труда и обновления оборудования, остаток на развитие. Разовое пожертвование или кредит не доказывают регулярное самообеспечение.
Сценарии проверены на арифметику, двойной учёт, кассовые разрывы и реальную пропускную способность команды; чувствительность к времени проверки показана отдельно.
Для выбранной закупки либо аренды есть актуальные условия и сравнение полной стоимости; при отсутствии данных сохраняется конкретный блокер, а не рекомендация занять деньги под ожидаемую выручку.
Модель, открытые примеры, методика и результаты сверки сохранены в монорепозитории и связаны с этой issue; приватные счета и данные участников остаются вне публичного Git.
Зависимости и границы
Подготовку структуры и сбор фактов можно вести параллельно #25 ; окончательная сверка использует согласованный экономический паспорт. Для первого ручного эксперимента не требуется завершение всей #24 . Эта задача не разрешает закупки, кредитные заявки, поручительства или расходование денег и не устанавливает цену услуги без отдельного решения.
Reactions are currently unavailable
Activity
Sign up for free to join this conversation on GitHub. Already have an account? Sign in to comment
Metadata
Metadata
Assignees
No one assigned
Labels
No labels
No labels
Type
No type
Projects
No projects
Milestone
No milestone
Relationships
None yet
Development
No branches or pull requests
Issue actions
Open in GitHub Copilot app
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
<!-- last-content-edit: 2026-10-03 20:28:43 MSK -->
<!-- content-sha256: sha256:71d7c215854e4982c909b926d677647429f4bb8819d5499be62b961850431e7c -->
<!-- FUM-MD-RECENCY:END -->
