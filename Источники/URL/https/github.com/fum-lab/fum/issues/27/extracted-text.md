# Извлечённый текст

Источник: <https://github.com/fum-lab/fum/issues/27>

## Содержимое

Проверить получателя платежей FUM и актуализировать доступные маршруты оплаты и поддержки · Issue #27 · fum-lab/fum · GitHub
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
Проверить получателя платежей FUM и актуализировать доступные маршруты оплаты и поддержки #27
New issue
Copy link
New issue
Copy link
Open
Open
Проверить получателя платежей FUM и актуализировать доступные маршруты оплаты и поддержки #27
Copy link
Description
Roman-Kerimov
opened on Oct 3, 2026
Issue body actions
Цель и основание
Подготовить проверяемый путь получения оплаты за работу и добровольной поддержки для реального получателя FUM. Отличать выбранную организационную форму от регистрации, платёжный канал от найденного донора, а бонусы от денег.
Поручение пользователя от 3 октября 2026 года: «Оформляй все необходимые ишью для этого». Основа чтения — d86ee47861fae6672486010b64ab26308c82ec86 .
Продолжить FUM-REQ-0069 и существующий финансовый поток: реестр и порядок обновления , пакеты поддержки , бизнес-план . Бизнес-план от 23 сентября фиксирует выбор АНО, но не подтверждает регистрацию. Более раннее «форма неизвестна» нужно согласовать с поздним решением, не переписывая исторические свидетельства.
Ограниченная работа
Составить приватный паспорт фактического получателя: регистрация и полномочия, виды деятельности, регион, доступный счёт, разрешённые способы получения средств. Сохранить выбранную пользователем АНО; иной вариант не подставлять без решения человека.
Для оплаты услуг, добровольного пожертвования, поддержки с встречными обязательствами, целевого гранта и ресурсной скидки отдельно проверить договорные основания, применимые требования к учёту, налогам, возвратам и документам. Проверку выполнять по текущим официальным источникам и, где нужна индивидуальная квалификация, с профильным специалистом. Issue не является юридическим заключением.
Для ограниченного числа практически подходящих маршрутов проверить тип получателя, региональные и договорные ограничения, идентификацию, комиссии, валюту, сроки расчётов, удержания/резервы, возвраты и возможность получить подтверждение. Неполное чтение оферты не считать положительным допуском. Не использовать чужие реквизиты или вымышленную географию для обхода ограничений.
Подготовить один путь оплаты выбранного пилота и один путь добровольной поддержки либо доказанный блокер каждого. До внешнего запуска нужны конкретное решение пользователя и соответствующие документы. Проверку возврата и сверки сначала описать/исполнить в разрешённой тестовой среде; тестовые деньги не объявлять выручкой.
Внести новые датированные наблюдения штатным механизмом реестра и сверить производные представления. Сохранить ID, прежние даты и отрицательные результаты. Дата генерации списка не заменяет дату чтения условий; не исследовать все организации заново без необходимости.
Конкретные основания для актуализации
На 3 октября 2026 года:
MWS, специальные условия : поисковое извлечение официальной страницы указывает окно 01.08–30.09.2026 и отдельный срок использования начисленного гранта — три календарных месяца с предоставления. Прямое открытие в этом просмотре не удалось. Не считать это новым полным снимком или подтверждением продления; завершившееся окно не включать в новые доступные поступления. Фактическое прежнее начисление и его остаток неизвестны.
Beget, правила : прочитанная официальная страница указывает подачу до 31.10.2026 включительно , индивидуальное одобрение и бонусную скидку без обналичивания; GPU VPS и выделенные серверы исключены. Это повод для адресной проверки допуска и подготовки комплекта, не подтверждение финансирования FUM. Дата — условие программы, не назначенный срок исполнителю.
GitHub Sponsors : получатель должен соответствовать требованиям поддерживаемого региона; России в прочитанном списке нет. Наличие репозитория не подтверждает доступность выплат конкретному получателю.
Перед действием перепроверить актуальную редакцию. Остальные каналы из существующего реестра, включая Boosty/Sponsr/CloudTips, не объявляются перепроверенными этой постановкой.
Критерии приёмки
По каждому выбранному маршруту есть датированные первичные источники, фактический получатель, статус допуска, неизвестные поля и минимальное следующее действие.
Оплата услуг, пожертвования, целевые средства, долг и бонусы не смешаны; факты передаются в учёт Связать экономический паспорт результата FUM с учётом денег, труда и повторного использования #25 и бюджет Отделить минимальный бюджет доходного сценария FUM от исследовательской аппаратной сметы #26 без фиктивного покрытия дефицита.
Условия MWS/Beget и текущая доступность выплат актуализированы в действующем реестре без подмены прежних наблюдений; неудачное чтение отмечено честно.
Есть подготовленный путь приёма и сверки оплаты/возврата либо точный блокер, а не недоказанная готовность платёжной формы.
Права на приватные материалы, условия CC0 собственных результатов и обязательства перед плательщиком описаны раздельно.
Публичный итог не содержит реквизитов, документов личности или иных приватных данных. Исходные запросы, точный текст issue и результаты связаны с памятью FUM.
Границы
Это подготовка и проверка допуска. Создание issue не регистрирует организацию или аккаунт, не отправляет заявку, не принимает оферту, не публикует сбор и не совершает платёж. Подготовку можно вести параллельно #25 / #26 ; отсутствие готового получателя блокирует реальные финансовые действия, но не внутренний эксперимент на открытых данных.
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
<!-- last-content-edit: 2026-10-03 20:27:00 MSK -->
<!-- content-sha256: sha256:da0ebb3bf83ef7592c2d290fb1458b52e57ec00b2fd0e44223e944821aad6db1 -->
<!-- FUM-MD-RECENCY:END -->
