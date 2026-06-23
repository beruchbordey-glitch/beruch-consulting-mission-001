# Beruch Consulting — Mission #001 : RetailCo

> Analyse des ventes e-commerce d'un détaillant britannique (2010-2011) avec PostgreSQL & Tableau.
> Cas fictif réalisé dans le cadre d'un défi data portfolio.*

---

##  À propos

Beruch Consulting accompagne les entreprises dans leur transition vers une culture *data-driven*, en transformant leurs données brutes en décisions stratégiques.
De la donnée à la décision.

Chaque projet de ce portfolio est présenté sous forme de mission client : un contexte, une problématique, des analyses et des recommandations concrètes.

---

##  Le client : RetailCo

RetailCo (entreprise fictive) est un e-commerçant britannique spécialisé dans les articles de décoration et de cadeaux. L'entreprise dispose de plus de 540 000 transactions sur un an (décembre 2010 – décembre 2011) mais pilote son activité « à l'aveugle », sans réelle exploitation de ses données.

## Problématique
> Comment RetailCo peut-il mieux comprendre ses ventes, ses clients et ses marchés pour prendre des décisions éclairées et identifier des leviers de croissance ?

## Données
- Source : jeu de données public Online Retail (UCI / Kaggle), utilisé pour simuler le cas RetailCo.
- ~541 000 lignes de transactions · 4 372 clients identifiés · 38 pays.
- Période : 01/12/2010 → 09/12/2011.

---

## Outils & compétences mobilisées

| Domaine | Détail |
| Base de données | PostgreSQL 18 (pgAdmin) |
| Préparation | Import en texte brut, typage, nettoyage (CAST, TO_TIMESTAMP, NULLIF) |
| Analyse SQL | Agrégations, filtres, GROUP BY, DISTINCT |
| SQL avancé| Fonctions fenêtre (RANK, NTILE), CTE , CASE WHEN, |
| Dates | DATE_TRUNC, calculs de récence |
| Visualisation | Tableau Public (courbe, camembert, barres) |

---

## 🔍 Démarche & analyses

L'analyse couvre les 4 dimensions clés d'une activité commerciale : quoi (produits), qui (clients), où (marchés) et quand (saisonnalité).

## 1. Santé globale
- Chiffre d'affaires net : ~9,7 M£.
- Annulations : ~897 K£, soit environ 9 % du CA un signal à investiguer.
- Les lignes les plus « annulées » sont en partie des lignes administratives (frais de port, saisies manuelles, remises), révélant un possible problème de process de facturation.

## 2. Produits
- Les best-sellers sont des articles de déco et réception (présentoirs à gâteaux, guirlandes, sacs, papercraft).
- Le REGENCY CAKESTAND est à la fois un top vendeur** et un top annulé → cas à surveiller (fragilité au transport ?), mais la donnée ne permet pas de conclure (motif d'annulation absent).

### 3. Clients
- 4 372 clients identifiés pour 540 000 lignes clientèle de type professionnels / revendeurs (gros volumes, commandes répétées).
- Le top 10 des clients pèse ~1,5M£ forte dépendance à quelques comptes clés.
- 871 clients (~20 %) dépensent plus que la moyenne  illustration du principe de Pareto (80/20).

## 4. Marchés 
- Le Royaume-Uni représente ~85 % du CA → marché domestique très solide, mais forte dépendance géographique.
- Les marchés européens (Pays-Bas, Irlande, Allemagne, France) restent sous le million  potentiel de croissance à l'international.

## 5. Saisonnalité
- Forte montée des ventes de septembre à novembre (préparation de Noël), avec un pic ~1,16 M£ en novembre.
- Creux en hiver/printemps.

## 6. Segmentation client RFM
Segmentation Récence / Fréquence / Montant (scores 1-5 via NTILE, segments via CASE WHEN) :

| Segment | Clients | Part |
|  Perdu / dormant | 1 447 | ~33 % |
|  Champion | 1 119 | ~26 % |
|  À surveiller | 868 | ~20 % |
|  Client récent | 616 | ~14 % |
|  À risque | 289 | ~7 % |

---

##  Recommandations pour RetailCo

1. Annulations :  Investiguer le process de facturation et **collecter les motifs d'annulation** (donnée aujourd'hui absente).
2. Produits :  Concentrer la communication sur les best-sellers déco/réception ; surveiller le cas du REGENCY CAKESTAND.
3. Clients : Mettre en place un programme de fidélité / VIP pour sécuriser les comptes clés (Pareto) et recontacter en priorité les 289 clients « à risque » (bons clients qui décrochent).
4. Marchés : Explorer le développement à l'international, principal levier de croissance.
5. aisonnalité : Anticiper le stock et la logistique dès l'été pour le pic de fin d'année (ne pas brader, la demande est déjà forte) ; promotions ciblées en période creuse (janvier-avril).
6. Réactivation :  Lancer une campagne pour les dormants et comprendre pourquoi tant de clients n'achètent qu'une fois.

---

## Limites des données

Plusieurs limites sont à noter :
- Pas de motif d'annulation (impossible d'expliquer certaines anomalies).
- Nombreuses ventes sans CustomerID (clients non identifiés exclus des analyses clients).
- Pas de coûts  analyse en chiffre d'affaires, pas en marge.
- Décembre 2011 incomplet (données arrêtées au 09/12).

---

## Visualisations (Tableau Public)

-  [Segmentation client RFM](https://public.tableau.com/shared/CKPPYYC42)
-  [Saisonnalité du chiffre d'affaires](https://public.tableau.com/views/Cartella1_17821700806400/saisonnalitduCA)
-  Chiffre d'affaires par pays

(Profil Tableau Public : Beruch Mouboungoulou De Ibala)

---

## Contenu du dépôt

```
beruch-consulting-mission-001/
├── README.md          ← ce fichier
└── queries.sql        ← les 10 analyses SQL, commentées
```

---

##  Auteur

Beruch Ibala
Projet réalisé dans le cadre d'un défi data portfolio (30 jours).

---

Données : Online Retail Dataset (UCI Machine Learning Repository). Cas client fictif à but pédagogique.
