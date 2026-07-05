# Politique de confidentialité — Realm Guard

**Dernière mise à jour : 5 juillet 2026**

> Version source (versionnée) de la politique de confidentialité de Realm Guard.
> À publier à une URL publique — par ex. `https://realmguard.nexusrealm.fr/confidentialite` —
> puis à référencer dans la fiche Google Play. Remplacez l'adresse de contact avant publication.

Realm Guard est un gestionnaire de mots de passe **hors ligne**. Cette politique
décrit les données que l'application traite — en résumé : elles ne quittent
jamais votre appareil.

## 1. Responsable du traitement
Realm Guard est édité par Nexus Realm. Pour toute question relative à cette
politique : **[contact@nexusrealm.fr]**.

## 2. Aucune collecte, aucune transmission
Realm Guard ne dispose d'aucun serveur et n'établit aucune connexion réseau
destinée à transmettre vos données. Tout ce que vous enregistrez — identifiants,
mots de passe, codes à usage unique (TOTP), profils, notes et champs
personnalisés — est stocké **exclusivement sur votre appareil**.

Nous n'avons **aucun accès** à ces données : ni consultation, ni copie, ni
sauvegarde à distance.

## 3. Stockage et chiffrement
Vos données sont conservées dans une base de données locale **entièrement
chiffrée** (SQLCipher). La clé de chiffrement est **dérivée de votre mot de passe
maître** au moyen de l'algorithme **Argon2id** et n'est jamais stockée en clair.
Le mot de passe maître lui-même n'est jamais enregistré.

## 4. Aucun tiers, aucune analyse, aucune publicité
L'application n'intègre **aucun** outil d'analyse (analytics), **aucun** traceur,
**aucun** SDK publicitaire et **aucun** service de rapport de plantage. Aucune
donnée n'est partagée avec des tiers, quels qu'ils soient.

## 5. Autorisations demandées
- **Biométrie** (empreinte / reconnaissance faciale) : uniquement pour
  déverrouiller votre coffre. L'authentification est gérée par le système
  Android ; aucune donnée biométrique n'est lue ni transmise par l'application.
- **Caméra** : uniquement pour scanner les QR codes de configuration des codes
  TOTP. Aucune image n'est enregistrée ni envoyée.
- **Service de remplissage automatique (Autofill)** : pour vous proposer vos
  identifiants enregistrés dans d'autres applications et navigateurs. Cette
  opération est réalisée **localement** sur votre appareil.

## 6. Conservation et suppression des données
Vos données restent sur votre appareil aussi longtemps que vous le souhaitez.
Vous pouvez à tout moment :
- **supprimer l'intégralité de vos données** depuis **Paramètres → Zone de
  danger → « Supprimer toutes les données »** ;
- **désinstaller l'application**, ce qui efface également toutes les données
  locales.

## 7. Sécurité
Vos données sont chiffrées au repos (SQLCipher). L'accès au coffre est protégé
par votre mot de passe maître et, en option, par la biométrie, avec verrouillage
automatique et limitation des tentatives répétées. Aucune donnée n'étant
transmise, il n'existe aucune exposition réseau.

## 8. Enfants
Realm Guard ne s'adresse pas spécifiquement aux enfants et ne collecte sciemment
aucune donnée les concernant.

## 9. Modifications de cette politique
Cette politique peut être mise à jour. La date de dernière mise à jour figure en
tête de document ; les modifications importantes seront signalées via la fiche de
l'application ou dans l'application.

## 10. Contact
Pour toute question ou demande : **[contact@nexusrealm.fr]**.
