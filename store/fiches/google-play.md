# Fiche Google Play — Glance

Textes à coller dans la Play Console (package `fr.mymonkey.glance`). Langue par défaut :
**français (fr-FR)**, plus **anglais (en-US)**. Autres langues : allemand, espagnol, portugais du Brésil,
chinois simplifié (sections en bas du fichier ; l'app sera traduite par le ticket #16).

Les limites de Google sont entre crochets ; `python3 -I store/compter.py` les vérifie. Les visuels
vivent dans `store/visuels/google-play/` : captures téléphone 1080 × 1920 (8 par langue) et image de
présentation 1024 × 500 (`presentation-<langue>.png`).

Ce qui reste de `store/play/listing.md` : catégorie (Outils), coordonnées, déclaration Data safety
(aucune collecte), questionnaire IARC (tout public). Rien de cela ne change.

## Français (fr-FR)

**Titre** [30]

```
Glance: Umami & Plausible
```

**Description courte** [80]

> Vos stats Umami et Plausible : tableaux, événements, entonnoir, prévision.

**Description complète** [4000]

```
Glance est le client mobile et bureau d’Umami et de Plausible. Tous vos sites d’un coup d’œil, et de vrais tableaux pour comprendre ce qui s’y passe. Rien n’est collecté : l’appli ne parle qu’à vos serveurs.

VOS SITES, RÉUNIS
• Plusieurs comptes Umami et Plausible dans une seule liste, avec un total et une courbe lissée.
• Chaque site s’affiche dès que sa donnée arrive. Recherche par nom ou domaine, groupes, vue liste ou grille.
• Aujourd’hui, 24 h, 7 jours, 30 jours, ce mois-ci, 12 mois, cette année ou une plage libre, avec la comparaison à la période précédente.

DES TABLEAUX À VOTRE MESURE
• Compteurs, taux et répartitions : composez vos indicateurs à partir des événements de vos sites.
• Croisez vos sites : plusieurs sites côte à côte, une courbe par site plus le total, avec un filtre « venus de » ou « sauf venus de » un domaine.
• Une grille que vous organisez au doigt : on déplace et on redimensionne chaque carte.

CHAQUE ÉVÉNEMENT, SA COULEUR
• Une courbe par événement, filtrable par propriété (plan = pro, montant ≥ 20…).
• La répartition des valeurs d’une propriété, et son évolution dans le temps.

L’ENTONNOIR
• De 2 à 8 étapes, avec le nombre de visiteurs et le taux de perte à chaque passage. Propre à Umami.

LA RÉTENTION, CALCULÉE SUR VOTRE BASE
• Branchez une source de métriques : une petite API sur votre site, protégée par un jeton.
• Glance affiche alors la rétention J1, J7 et J30, les comptes créés, tout indicateur que votre site expose, avec ses effectifs.
• Une carte peut suivre la période : J1 sur une journée, J7 sur 30 jours, J30 sur un an.

ANTICIPEZ LA FIN DU MOIS
• Sur « ce mois-ci » et « cette année », la courbe se prolonge en pointillé orange, avec le total attendu. La prévision part du niveau des 7 derniers jours et du rythme de la semaine.

EN DIRECT, JUSQUE SUR L’ÉCRAN D’ACCUEIL
• Les visiteurs présents maintenant sur chaque site, triés par activité.
• Des widgets pour vos totaux ou pour un site précis.

SUR TOUS VOS APPAREILS
• Android, iPhone, Mac et Windows, en clair comme en sombre.
• Un QR code chiffré pour reprendre votre configuration en un scan, ou une synchronisation chiffrée de bout en bout entre vos appareils (option, achat unique).

VIE PRIVÉE
• Aucun serveur intermédiaire : Glance parle directement à vos instances.
• Vos identifiants restent chiffrés sur l’appareil. Accès en lecture seule.
• Pas de publicité, pas de pistage.

OUTILS SUPPORTÉS
• Umami, auto-hébergé.
• Plausible, Cloud ou auto-hébergé : compteurs, taux et répartitions.
• Fathom : bientôt.

Glance est un projet du collectif My-Monkey. Vos retours sont les bienvenus.
```

## English (en-US)

**Title** [30]

```
Glance: Umami & Plausible
```

**Short description** [80]

> Your Umami and Plausible stats: dashboards, events, funnels, forecasts.

**Full description** [4000]

```
Glance is the mobile and desktop client for Umami and Plausible. All your sites at a glance, plus real dashboards to understand what is happening on them. Nothing is collected: the app only talks to your own servers.

ALL YOUR SITES, TOGETHER
• Several Umami and Plausible accounts in one list, with a total and a smooth chart.
• Each site shows up as soon as its data arrives. Search by name or domain, groups, list or grid view.
• Today, 24 h, 7 days, 30 days, this month, 12 months, this year or a custom range, compared with the previous period.

DASHBOARDS YOUR WAY
• Counters, rates and breakdowns: build your own indicators from your sites' events.
• Compare your sites: several sites side by side, one curve per site plus the total, with a "from" or "excluding visitors from" filter on a domain.
• A grid you arrange by hand: move and resize each card.

EVERY EVENT, ITS OWN COLOR
• One curve per event, filterable by property (plan = pro, amount ≥ 20...).
• The breakdown of a property's values, and how it evolves over time.

THE FUNNEL
• From 2 to 8 steps, with the number of visitors and the drop-off at every step. Umami only.

RETENTION, COMPUTED ON YOUR OWN DATABASE
• Plug in a metrics source: a small API on your site, protected by a token.
• Glance then shows D1, D7 and D30 retention, accounts created, any indicator your site exposes, with its counts.
• A card can follow the period: D1 over a day, D7 over 30 days, D30 over a year.

SEE THE MONTH'S END COMING
• On "this month" and "this year", your curve continues as an orange dotted line, with the expected total. The forecast starts from the last 7 days' level and the weekly rhythm.

LIVE, RIGHT ON YOUR HOME SCREEN
• Who is on each site right now, sorted by activity.
• Widgets for your totals or for a specific site.

ON ALL YOUR DEVICES
• Android, iPhone, Mac and Windows, in light and dark.
• An encrypted QR code to pick up your setup in one scan, or end-to-end encrypted sync between your devices (optional, one-time purchase).

PRIVACY
• No middle server: Glance talks straight to your instances.
• Your credentials stay encrypted on the device. Read-only access.
• No ads, no tracking.

SUPPORTED TOOLS
• Umami, self-hosted.
• Plausible, Cloud or self-hosted: counters, rates and breakdowns.
• Fathom: coming soon.

Glance is a project by the My-Monkey collective. Your feedback is welcome.
```

## Deutsch (de-DE)

**Titel** [30]

```
Glance: Umami & Plausible
```

**Kurzbeschreibung** [80]

> Ihre Umami- und Plausible-Statistiken: Dashboards, Ereignisse, Funnel, Prognose.

**Vollständige Beschreibung** [4000]

```
Glance ist der Mobil- und Desktop-Client für Umami und Plausible. Alle Ihre Websites auf einen Blick, dazu echte Dashboards, um zu verstehen, was dort passiert. Nichts wird erfasst: Die App spricht nur mit Ihren eigenen Servern.

ALLE IHRE WEBSITES, VEREINT
• Mehrere Umami- und Plausible-Konten in einer Liste, mit Summe und geglätteter Kurve.
• Jede Website erscheint, sobald ihre Daten eintreffen. Suche nach Name oder Domain, Gruppen, Listen- oder Rasteransicht.
• Heute, 24 Std., 7 Tage, 30 Tage, dieser Monat, 12 Monate, dieses Jahr oder ein freier Zeitraum, mit Vergleich zur Vorperiode.

DASHBOARDS NACH MASS
• Zähler, Raten und Aufschlüsselungen: Stellen Sie Ihre Kennzahlen aus den Ereignissen Ihrer Websites zusammen.
• Websites vergleichen: mehrere Websites nebeneinander, eine Kurve pro Website plus Summe, mit einem Filter „von“ oder „außer von“ für eine Domain.
• Ein Raster, das Sie per Fingertipp anordnen: Jede Karte lässt sich verschieben und in der Größe ändern.

JEDES EREIGNIS IN SEINER FARBE
• Eine Kurve pro Ereignis, filterbar nach Eigenschaft (Tarif = Pro, Betrag ≥ 20…).
• Die Aufschlüsselung der Werte einer Eigenschaft und ihr Verlauf über die Zeit.

DER FUNNEL
• 2 bis 8 Schritte, mit Besucherzahl und Abbruchquote bei jedem Übergang. Nur bei Umami.

NUTZERBINDUNG, AUS IHRER EIGENEN DATENBANK BERECHNET
• Binden Sie eine Metrikquelle an: eine kleine API auf Ihrer Website, durch ein Token geschützt.
• Glance zeigt dann die Bindung D1, D7 und D30, erstellte Konten und jede Kennzahl, die Ihre Website bereitstellt, mit ihren Zahlen.
• Eine Karte kann dem Zeitraum folgen: D1 über einen Tag, D7 über 30 Tage, D30 über ein Jahr.

DAS MONATSENDE VORHERSEHEN
• Bei „Dieser Monat“ und „Dieses Jahr“ setzt sich die Kurve orange gestrichelt fort, mit der erwarteten Summe. Die Prognose geht vom Niveau der letzten 7 Tage und vom Wochenrhythmus aus.

LIVE, BIS AUF DEN HOME-BILDSCHIRM
• Die aktuell anwesenden Besucher jeder Website, nach Aktivität sortiert.
• Widgets für Ihre Summen oder für eine bestimmte Website.

AUF ALLEN IHREN GERÄTEN
• Android, iPhone, Mac und Windows, in Hell und Dunkel.
• Ein verschlüsselter QR-Code, um Ihre Konfiguration mit einem Scan zu übernehmen, oder eine Ende-zu-Ende-verschlüsselte Synchronisierung zwischen Ihren Geräten (optional, Einmalkauf).

DATENSCHUTZ
• Kein Zwischenserver: Glance spricht direkt mit Ihren Instanzen.
• Ihre Zugangsdaten bleiben verschlüsselt auf dem Gerät. Nur Lesezugriff.
• Keine Werbung, kein Tracking.

UNTERSTÜTZTE TOOLS
• Umami, selbst gehostet.
• Plausible, Cloud oder selbst gehostet: Zähler, Raten und Aufschlüsselungen.
• Fathom: demnächst.

Glance ist ein Projekt des Kollektivs My-Monkey. Ihr Feedback ist willkommen.
```

## Español (es-ES, es-419)

**Título** [30]

```
Glance: Umami & Plausible
```

**Descripción corta** [80]

> Tus estadísticas de Umami y Plausible: paneles, eventos, embudo, previsión.

**Descripción completa** [4000]

```
Glance es el cliente móvil y de escritorio de Umami y Plausible. Todos tus sitios de un vistazo y paneles de verdad para entender lo que pasa en ellos. No se recopila nada: la app solo habla con tus servidores.

TUS SITIOS, REUNIDOS
• Varias cuentas de Umami y Plausible en una sola lista, con un total y una curva suavizada.
• Cada sitio aparece en cuanto llegan sus datos. Búsqueda por nombre o dominio, grupos, vista de lista o cuadrícula.
• Hoy, 24 h, 7 días, 30 días, este mes, 12 meses, este año o un rango libre, con comparación con el periodo anterior.

PANELES A TU MEDIDA
• Contadores, tasas y desgloses: crea tus propios indicadores a partir de los eventos de tus sitios.
• Cruza tus sitios: varios sitios codo con codo, una curva por sitio más el total, con un filtro «desde» o «salvo desde» un dominio.
• Una cuadrícula que organizas con el dedo: mueve y cambia el tamaño de cada tarjeta.

CADA EVENTO, SU COLOR
• Una curva por evento, filtrable por propiedad (plan = pro, importe ≥ 20…).
• El desglose de los valores de una propiedad y su evolución en el tiempo.

EL EMBUDO
• De 2 a 8 pasos, con el número de visitantes y la tasa de pérdida en cada paso. Solo en Umami.

LA RETENCIÓN, CALCULADA SOBRE TU BASE DE DATOS
• Conecta una fuente de métricas: una pequeña API en tu sitio, protegida con un token.
• Glance muestra entonces la retención D1, D7 y D30, las cuentas creadas y cualquier indicador que tu sitio ofrezca, con sus cifras.
• Una tarjeta puede seguir el periodo: D1 sobre un día, D7 sobre 30 días, D30 sobre un año.

ANTICIPA EL FIN DE MES
• En «este mes» y «este año», la curva se prolonga con una línea punteada naranja, con el total previsto. La previsión parte del nivel de los últimos 7 días y del ritmo de la semana.

EN VIVO, HASTA EN LA PANTALLA DE INICIO
• Los visitantes presentes ahora mismo en cada sitio, ordenados por actividad.
• Widgets para tus totales o para un sitio concreto.

EN TODOS TUS DISPOSITIVOS
• Android, iPhone, Mac y Windows, en claro y en oscuro.
• Un código QR cifrado para recuperar tu configuración con un solo escaneo, o una sincronización cifrada de extremo a extremo entre tus dispositivos (opcional, compra única).

PRIVACIDAD
• Sin servidor intermedio: Glance habla directamente con tus instancias.
• Tus credenciales se quedan cifradas en el dispositivo. Acceso de solo lectura.
• Sin publicidad, sin rastreo.

HERRAMIENTAS COMPATIBLES
• Umami, autoalojado.
• Plausible, Cloud o autoalojado: contadores, tasas y desgloses.
• Fathom: próximamente.

Glance es un proyecto del colectivo My-Monkey. Tus comentarios son bienvenidos.
```

## Português (pt-BR)

**Título** [30]

```
Glance: Umami & Plausible
```

**Descrição curta** [80]

> Suas estatísticas Umami e Plausible: painéis, eventos, funil, previsão.

**Descrição completa** [4000]

```
O Glance é o cliente mobile e desktop do Umami e do Plausible. Todos os seus sites num relance, e painéis de verdade para entender o que acontece neles. Nada é coletado: o app só se comunica com os seus servidores.

SEUS SITES, REUNIDOS
• Várias contas Umami e Plausible em uma só lista, com um total e uma curva suave.
• Cada site aparece assim que seus dados chegam. Busca por nome ou domínio, grupos, visualização em lista ou grade.
• Hoje, 24 h, 7 dias, 30 dias, este mês, 12 meses, este ano ou um período livre, com comparação ao período anterior.

PAINÉIS SOB MEDIDA
• Contadores, taxas e detalhamentos: monte seus indicadores a partir dos eventos dos seus sites.
• Compare seus sites: vários sites lado a lado, uma curva por site mais o total, com um filtro “vindos de” ou “exceto vindos de” um domínio.
• Uma grade que você organiza com o dedo: mova e redimensione cada card.

CADA EVENTO, SUA COR
• Uma curva por evento, filtrável por propriedade (plano = pro, valor ≥ 20…).
• O detalhamento dos valores de uma propriedade e sua evolução ao longo do tempo.

O FUNIL
• De 2 a 8 etapas, com o número de visitantes e a taxa de perda em cada passagem. Exclusivo do Umami.

RETENÇÃO, CALCULADA NO SEU BANCO DE DADOS
• Conecte uma fonte de métricas: uma pequena API no seu site, protegida por um token.
• O Glance passa a mostrar a retenção D1, D7 e D30, as contas criadas e qualquer indicador que seu site exponha, com os números absolutos.
• Um card pode acompanhar o período: D1 em um dia, D7 em 30 dias, D30 em um ano.

ANTECIPE O FIM DO MÊS
• Em “este mês” e “este ano”, a curva continua em pontilhado laranja, com o total esperado. A previsão parte do nível dos últimos 7 dias e do ritmo da semana.

AO VIVO, ATÉ NA TELA INICIAL
• Os visitantes presentes agora em cada site, ordenados por atividade.
• Widgets para seus totais ou para um site específico.

EM TODOS OS SEUS DISPOSITIVOS
• Android, iPhone, Mac e Windows, nos modos claro e escuro.
• Um QR code criptografado para levar sua configuração com um só scan, ou sincronização criptografada de ponta a ponta entre seus dispositivos (opcional, compra única).

PRIVACIDADE
• Nenhum servidor intermediário: o Glance fala direto com as suas instâncias.
• Suas credenciais ficam criptografadas no dispositivo. Acesso somente leitura.
• Sem anúncios, sem rastreamento.

FERRAMENTAS SUPORTADAS
• Umami, auto-hospedado.
• Plausible, Cloud ou auto-hospedado: contadores, taxas e detalhamentos.
• Fathom: em breve.

O Glance é um projeto do coletivo My-Monkey. Seu feedback é bem-vindo.
```

## 简体中文 (zh-CN)

**Titre** [30]

```
Glance：Umami 与 Plausible 统计
```

**Description courte** [80]

> 您的 Umami 和 Plausible 数据：仪表盘、事件、漏斗、预测。

**Description complète** [4000]

```
Glance 是 Umami 和 Plausible 的移动端与桌面端客户端。所有站点一眼尽览，还有真正的仪表盘，帮您看懂站点上发生的一切。不收集任何数据：应用只与您自己的服务器通信。

所有站点，汇于一处
• 多个 Umami 和 Plausible 账户合并在同一列表中，附带总数和平滑曲线。
• 每个站点的数据一到就立即显示。支持按名称或域名搜索、分组、列表或网格视图。
• 今天、24 小时、7 天、30 天、本月、12 个月、今年或自定义时间段，并可与上一时期对比。

量身定制的仪表盘
• 计数、比率和分布：基于站点事件，组合出您自己的指标。
• 站点交叉对比：多个站点并排查看，每个站点一条曲线外加总数，还可按“来自”或“不含来自”某个域名筛选。
• 用手指自由排列的网格：每张卡片都能拖动、调整大小。

每个事件，各有其色
• 每个事件一条曲线，可按属性筛选（套餐 = pro，金额 ≥ 20……）。
• 查看某个属性各个值的分布，以及它随时间的变化。

漏斗
• 2 到 8 个步骤，显示每一步的访客数和流失率。仅限 Umami。

留存，基于您自己的数据库计算
• 接入指标数据源：您站点上的一个小型 API，由令牌保护。
• Glance 随即显示次日、7 日和 30 日留存、新增账户数，以及您的站点提供的任何指标和对应人数。
• 卡片可以跟随时间段：一天看次日留存，30 天看 7 日留存，一年看 30 日留存。

预见月底数据
• 在“本月”和“今年”下，曲线会以橙色虚线延伸，并给出预计总数。预测基于近 7 天的水平和每周的规律。

实时数据，直达主屏幕
• 每个站点此刻的在线访客，按活跃度排序。
• 小组件可显示总数或指定站点。

所有设备，同步随行
• Android、iPhone、Mac 和 Windows，支持浅色与深色模式。
• 加密二维码，一次扫描即可迁移配置；也可在设备间使用端到端加密同步（可选，一次性购买）。

隐私
• 没有中间服务器：Glance 直接与您的实例通信。
• 您的凭据在设备上加密保存。只读访问。
• 没有广告，没有追踪。

支持的工具
• Umami，自托管。
• Plausible，云端版或自托管：计数、比率和分布。
• Fathom：即将支持。

Glance 是 My-Monkey 团队的项目，欢迎提出反馈。
```
