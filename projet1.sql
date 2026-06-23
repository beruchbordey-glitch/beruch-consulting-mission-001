=====================================================================
   BERUCH CONSULTING — MISSION #001
   Client : RetailCo (cas fictif réalisé dans le cadre d'un défi data)
   Sujet  : Analyse des ventes e-commerce 2010-2011 (UK)
   Outil  : PostgreSQL
   Auteur : beruch ibala

   Contexte : RetailCo, e-commerçant britannique d'articles de décoration
   et de cadeaux, dispose de ~540 000 transactions mais pilote "à l'aveugle".
   
   Objectif : éclairer ses décisions (produits, clients, marchés) à partir
   de ses données.

   NB : le dataset public "Online Retail" est utilisé pour simuler ce cas.
=====================================================================


---------------------------------------------------------------------
   ÉTAPE 0 — PRÉPARATION DES DONNÉES
   
   Les données ont d'abord été importées en texte brut dans une table
   "online_retail" (pour éviter tout échec d'import : encodage LATIN1,
   dates au format américain, CustomerID parfois vides).
   On crée ensuite une table propre "online_retail_clean" avec les bons
   types de données.
---------------------------------------------------------------------
CREATE TABLE online_retail_clean AS
SELECT
    "Invoice"                                        AS invoice_no,
    "StockCode"                                      AS stock_code,
    "Description"                                    AS description,
    "Quantity"::INTEGER                              AS quantity,
    TO_TIMESTAMP("InvoiceDate", 'MM/DD/YY HH24:MI')  AS invoice_date,
    "Price"::NUMERIC(10,2)                           AS price_unit,
    NULLIF("Customer ID", '')                        AS customer_id,  
    "Country"                                        AS country
FROM online_retail;   
-- table d'import en texte brut


=====================================================================
   ANALYSE 1 :  CHIFFRE D'AFFAIRES TOTAL
   
   Question : quelle est la santé globale de RetailCo ?
   Note : ce total est NET, car les annulations (quantités négatives)
   se retranchent automatiquement.
=====================================================================

SELECT
    ROUND(SUM(quantity * price_unit), 2) AS chiffre_affaires_total
FROM online_retail_clean;


=====================================================================
   ANALYSE 2 :  IMPACT DES ANNULATIONS
   
   Les factures d'annulation commencent par "C".
   
   Question : combien pèsent les annulations ?
=====================================================================
SELECT
    ROUND(SUM(quantity * price_unit), 2) AS total_annulations
FROM online_retail_clean
WHERE invoice_no LIKE 'C%';
---------------------------------------------------------------------
   ANALYSE 2bis : PRODUITS LES PLUS ANNULÉS
   
   Constat : beaucoup de lignes ne sont pas des produits mais des lignes
   administratives (Manual, POSTAGE, Discount, SAMPLES...).
   piste d'un problème de process de facturation.
---------------------------------------------------------------------
SELECT
    description,
    COUNT(*) AS nombre_annulations
FROM online_retail_clean
WHERE invoice_no LIKE 'C%'
GROUP BY description
ORDER BY nombre_annulations DESC
LIMIT 10;

=====================================================================
   ANALYSE 3 :  TOP 10 DES PRODUITS PAR CHIFFRE D'AFFAIRES
   
   Question : quels produits rapportent le plus ?
   On ne garde que les VRAIES ventes : pas d'annulations + quantité > 0.
=====================================================================
SELECT
    description,
    ROUND(SUM(quantity * price_unit), 2) AS ca_produit
FROM online_retail_clean
WHERE invoice_no NOT LIKE 'C%'
  AND quantity > 0
GROUP BY description
ORDER BY ca_produit DESC
LIMIT 10;

Best-sellers : articles de déco / réception (présentoirs, guirlandes,
sacs, papercraft). 
NB : REGENCY CAKESTAND est star des ventes MAIS
aussi des annulations -> à surveiller (fragilité au transport ?).


=====================================================================
   ANALYSE 4 : NOMBRE DE CLIENTS UNIQUES
   
   Question : combien de clients différents ?
   DISTINCT pour ne compter chaque client qu'une fois.
   
===================================================================== 
SELECT
    COUNT(DISTINCT customer_id) AS nombre_clients
FROM online_retail_clean;

-- Résultat : 4 372 clients identifiés
-- (Limite : beaucoup de ventes sans CustomerID ne sont pas comptées.)


=====================================================================
   ANALYSE 5 : TOP 10 DES CLIENTS PAR CHIFFRE D'AFFAIRES
   
   Question : qui sont les meilleurs clients ?
   On exclut les lignes sans client identifié (customer_id IS NOT NULL).
===================================================================== */
SELECT
    customer_id,
    ROUND(SUM(quantity * price_unit), 2) AS ca_client
FROM online_retail_clean
WHERE invoice_no NOT LIKE 'C%'
  AND quantity > 0
  AND customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY ca_client DESC
LIMIT 10;

-- Le top 10 pèse à peu près 1,5 M  forte dépendance à quelques gros clients
-- (clientèle de type professionnels / revendeurs, gros volumes).


=====================================================================
   ANALYSE 6 : CHIFFRE D'AFFAIRES PAR PAYS
   
   Question : quels marchés sont les plus porteurs ?
=====================================================================
SELECT
    country,
    ROUND(SUM(quantity * price_unit), 2) AS ca_pays
FROM online_retail_clean
WHERE invoice_no NOT LIKE 'C%'
  AND quantity > 0
  AND customer_id IS NOT NULL
GROUP BY country
ORDER BY ca_pays DESC
LIMIT 10;

-- Le Royaume-Uni représente ~85 % du CA :  marché domestique très solide
-- mais international sous-exploité (fort potentiel de croissance).


=====================================================================
   ANALYSE 7 :  CLASSEMENT DES PRODUITS AVEC RANK() fonction fenêtre
   
   Question : établir un classement officiel des produits par CA.
   
   RANK() affiche le rang dans une colonne et gère les ex aequo.
=====================================================================
SELECT
    description,
    ROUND(SUM(quantity * price_unit), 2) AS ca_produit,
    RANK() OVER (ORDER BY ROUND(SUM(quantity * price_unit), 2) DESC) AS rang
FROM online_retail_clean
WHERE invoice_no NOT LIKE 'C%'
  AND quantity > 0
  AND customer_id IS NOT NULL
GROUP BY description
LIMIT 10;


=====================================================================
   ANALYSE 8 — CLIENTS AU-DESSUS DE LA MOYENNE CTE 
   
   Question : combien de clients dépensent plus que la moyenne ?
   
   Étape 1 (CTE) : on calcule le CA par client dans une table temporaire.
   Étape 2 : on compare chaque client à la moyenne de ces CA.
=====================================================================
WITH depenses_clients AS (
    SELECT
        customer_id,
        ROUND(SUM(quantity * price_unit), 2) AS ca_client
    FROM online_retail_clean
    WHERE invoice_no NOT LIKE 'C%'
      AND quantity > 0
      AND customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    customer_id,
    ca_client
FROM depenses_clients
WHERE ca_client > (SELECT AVG(ca_client) FROM depenses_clients)
ORDER BY ca_client DESC;

-- Résultat : 871 clients au-dessus de la moyenne, soit environ 20 % des clients.
-- Confirmation du principe de Pareto (80/20) : une minorité de clients génère l'essentiel du chiffre d'affaires.


=====================================================================
   ANALYSE 9 :  SAISONNALITÉ (CHIFFRE D'AFFAIRES PAR MOIS)
   
   Question : comment le CA évolue-t-il dans le temps ? Y a-t-il des
   pics / des creux ?
   
   DATE_TRUNC('month', ...) ramène chaque date au 1er du mois en gardant
   l'ANNÉE permet de distinguer déc. 2010 de déc. 2011 et de suivre
   l'évolution chronologique réelle.
=====================================================================
select
    date_trunc('month', invoice_date)::date as mois,
    round(sum(quantity*price_unit),2) as ca_mensuel
from public.online_retail_clean
where invoice_no not like 'C%' and quantity > 0 and customer_id is not null
group by mois
order by mois;

-- ordre chronologique (du plus ancien au plus récent)
-- Forte saisonnalité : montée entre sept et nov (préparation de Noël, pic 1,16 M
 en novembre), creux en hiver/printemps. 
 NB : décembre 2011 est partiel (données arrêtées au 09/12).


=====================================================================
   ANALYSE 10 :  SEGMENTATION CLIENT RFM (Récence, Fréquence, Montant)
   Méthode marketing de référence pour segmenter une base client.
   - R (Récence)   : nb de jours depuis le dernier achat (petit = bon)
   - F (Fréquence) : nb de commandes distinctes (grand = bon)
   - M (Montant)   : CA total du client (grand = bon)
  
  Chaque client reçoit un score de 1 à 5 par dimension (via NTILE),
   puis est rangé dans un segment métier (via CASE WHEN).
   Date de référence = 2011-12-09 (dernière date du dataset, = "aujourd'hui").
  nb:  la Récence est triée DESC dans NTILE, car une petite récence
   doit donner un BON score (logique inversée des deux autres dimensions).
=====================================================================

WITH rfm_base AS (
    -- Étape 1 : calcul des indicateurs bruts R, F, M par client
    SELECT
        customer_id,
        ROUND(SUM(quantity * price_unit), 2)                AS ca_client,        
        COUNT(DISTINCT invoice_no)                          AS nombre_fac_unique,
        DATE '2011-12-09' - MAX(invoice_date)::DATE         AS recence_jours     
    FROM online_retail_clean
    WHERE invoice_no NOT LIKE 'C%'
      AND quantity > 0
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),
rfm_scores AS (
    -- Étape 2 : transformation en scores de 1 à 5 (5 paquets égaux via NTILE)
    SELECT
        customer_id,
        recence_jours,
        nombre_fac_unique,
        ca_client,
        NTILE(5) OVER (ORDER BY recence_jours DESC)     AS score_r,  -- DESC -> petite récence = 5
        NTILE(5) OVER (ORDER BY nombre_fac_unique ASC)  AS score_f,
        NTILE(5) OVER (ORDER BY ca_client ASC)          AS score_m
    FROM rfm_base
),
rfm_final AS (
    -- Étape 3 : attribution d'un segment métier selon les scores
    SELECT
        customer_id,
        CASE
            WHEN score_r >= 4 AND score_f >= 4 THEN 'Champion'
            WHEN score_r >= 4                  THEN 'Client recent'
            WHEN score_r <= 2 AND score_f >= 4 THEN 'A risque'
            WHEN score_r <= 2                  THEN 'Perdu / dormant'
            ELSE 'A surveiller'
        END AS segment
    FROM rfm_scores
)
-- Résultat final : répartition de la clientèle par segment
SELECT
    segment,
    COUNT(*) AS nombre_clients
FROM rfm_final
GROUP BY segment
ORDER BY nombre_clients DESC;
-- Résultats : Perdu/dormant 1447 (~33%), Champion 1119 (~26%),
-- A surveiller 868, Client recent 616, A risque 289 (~7%).
--  Priorités : (1) recontacter d'urgence les 289 "A risque" (bons
--    clients qui décrochent), (2) programme VIP pour les Champions,
--    (3) campagne de réactivation des dormants.
 
-- NB : pour obtenir le détail client par client (avec scores et segment),
-- remplacer le SELECT final par : SELECT * FROM rfm_final  (ou interroger
-- rfm_scores pour voir les scores R/F/M individuels).
=====================================================================
   SYNTHÈSE DES RECOMMANDATIONS POUR RETAILCO
---------------------------------------------------------------------
1. ANNULATIONS (~9 % du CA) : investiguer le process de facturation
      (nombreuses lignes "Manual", "Discount"...). Recommandation :
      collecter les MOTIFS d'annulation, donnée aujourd'hui absente.
 
   2. PRODUITS : concentrer la communication sur les best-sellers déco/
      réception. Surveiller le REGENCY CAKESTAND (top ventes ET top
      annulations).
 
   3. CLIENTS : forte dépendance à une minorité de clients (Pareto).
      Mettre en place un programme de fidélité / VIP pour sécuriser les
      ~871 clients-clés, et faire monter les autres.
 
   4. MARCHÉS : Royaume-Uni ultra-dominant (~85 %). L'international est
      le principal levier de croissance à explorer.
 
   5. SAISONNALITÉ : pic des ventes de septembre à novembre (préparation
      de Noël). Recommandations :
      - Pic : anticiper le stock et les renforts logistiques/personnel
        dès l'été ; NE PAS brader (la demande est déjà forte, le risque
        est la rupture, pas le manque de clients).
      - Creux (janvier-avril) : campagnes promotionnelles ciblées pour
        stimuler une demande plus faible.
 
   6. SEGMENTATION RFM : 26% de Champions, mais 33% de clients dormants
      et 7% de bons clients "à risque". Recommandations :
      - Recontacter en PRIORITÉ les clients "à risque" (fidèles qui
        décrochent) avant de les perdre.
      - Programme VIP pour fidéliser les Champions.
      - Campagne de réactivation pour les dormants ; comprendre pourquoi
        tant de clients n'achètent qu'une fois.
 
   LIMITES DES DONNÉES : pas de motif d'annulation ; nombreuses ventes
   sans CustomerID ; pas de coûts (donc CA et non marge) ; décembre 2011
   incomplet.