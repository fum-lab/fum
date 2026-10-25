# Извлечённый текст

Источник: <https://github.com/fum-lab/fum/issues/25>

## Содержимое

Связать экономический паспорт результата FUM с учётом денег, труда и повторного использования · Issue #25 · fum-lab/fum · GitHub
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
Связать экономический паспорт результата FUM с учётом денег, труда и повторного использования #25
New issue
Copy link
New issue
Copy link
Open
Open
Связать экономический паспорт результата FUM с учётом денег, труда и повторного использования #25
Copy link
Description
Roman-Kerimov
opened on Oct 3, 2026
Issue body actions
Цель и основание
Связать конкретную работу FUM с её приёмкой, полной стоимостью, денежным исходом и оставшейся повторно используемой способностью. Разделить фактическое движение денег и экономическую стоимость с учётом труда; неоплаченное время разработчика не считать бесплатным ресурсом.
Постановка из обсуждения самофинансирования 3 октября 2026 года. Прямое поручение пользователя: «Оформляй все необходимые ишью для этого». Проверенная основа репозитория — d86ee47861fae6672486010b64ab26308c82ec86 ; это основа чтения, не обязательная будущая база реализации.
Продолжить существующие бизнес-план и учёт поддержки и расходов . Не создавать вторую несвязанную бухгалтерию или новый реестр вместо уже существующего.
Минимальный результат
Версионируемая схема экономического паспорта, локальный проверяемый расчёт и открытые синтетические примеры. Первая поставка допускает явный ручной ввод из проверенных подтверждений: интеграция с банком и автоматические платежи не требуются.
Паспорт связывает:
Работу и приёмку: устойчивый идентификатор заказа/эксперимента, согласованный объём и критерий, версию входа и исполнителя, попытки, состояние результата и основание принятия. Личность заказчика и исходные документы — в разрешённой приватной области.
Полную стоимость: вычисления всех попыток, подготовку, общение, проверку, исправления, сопровождение и долю общей инфраструктуры. Общие затраты распределяются один раз по явному правилу; оплата труда и его оценочная стоимость не суммируются повторно. Часы сохраняются даже при неизвестной ставке.
Денежные события: предложение, согласованную цену, счёт, аванс, оплату, комиссии, возвраты, задолженность и ещё не исполненные обязательства. Разделить событие оказания/принятия услуги и движение денег; применимый бухгалтерский и налоговый порядок подтверждается отдельно.
Повторное использование: созданный оператор, тест, адаптер, методику или фикстуру, их происхождение и права; ссылки на последующие применения и фактически измеренную экономию.
Суммы хранить с валютой, точностью, источником и датой. Денежные расчёты — без двоичной плавающей запятой; конвертация использует явный курс и дату. Оценка, лимит, резерв и окончательный расход имеют разные статусы. Неизвестное не превращать в ноль.
Кредиты и взносы на финансирование показывать отдельно от дохода от полезной работы. Бонусы и оборудование не приравнивать к свободным деньгам. Целевые средства и авансы с обязательствами не включать автоматически в свободный остаток. Переводы между собственными узлами исключать при расчёте внешнего дохода всей системы. Различать снижение фактических денежных расходов и снижение стоимости единицы работы при уже оплаченной подписке.
Критерии приёмки
Есть схема, словарь величин, правила распределения общих затрат и два отчёта: движение денег и экономическая стоимость работы.
Результат связан с приёмкой, всеми попытками и первичными подтверждениями; счётчик операций Уточнить и выровнять модель стоимости примитивов и ресурсные границы интерпретатора FUMA #14 и хэш наблюдения не выдаются за денежный расход или подтверждение платежа.
Тесты покрывают повторный импорт события без дубля, аванс до приёмки, частичную оплату, возврат, комиссию, неизвестную ставку труда, разные валюты, бонусы и внутренний перевод без фиктивной выручки.
На открытой фикстуре независимо сверяются начальный остаток, поступления, выплаты и конечный остаток; вклад работы в покрытие общих расходов отделён от итога после их распределения.
Исправления добавляются с происхождением, а не стирают прежние события. Импорт конфликтующего подтверждения даёт диагностику.
Публичное представление содержит только разрешённые агрегаты; персональные данные, реквизиты и клиентские материалы не попадают в Git или внешнюю модель автоматически.
Исходники, тесты, команды и ограничения сохранены в монорепозитории; текст issue и результаты связаны с памятью FUM и исходным обсуждением.
Границы
Это управленческий учёт и основа эксперимента, не замена обязательной бухгалтерской отчётности. Создание issue не подтверждает доход, не назначает ставки и не разрешает банковские операции, публикацию приватных данных или автоматическую интеграцию стороннего сервиса.
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
<!-- last-content-edit: 2026-10-03 20:19:10 MSK -->
<!-- content-sha256: sha256:44de8f15f351adc38b1e1e4046c3bb23e3b2eecfe1b83027dadf3e1715483c60 -->
<!-- FUM-MD-RECENCY:END -->
