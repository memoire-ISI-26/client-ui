# client_ui - Interface Mobile Max It (Flutter)

Ce répertoire contient l'application mobile de démonstration **client_ui**, développée avec **Flutter**. Elle sert d'interface utilisateur pour interagir avec le backend de microservices de la plateforme.

Le design graphique de l'application est inspiré de la charte de **Orange Max It**, adoptant un **Thème Sombre** élégant avec des touches de couleur orange vif (`#FF7900`).

---

## 📱 Écrans et Fonctionnalités

L'application intègre les modules essentiels d'un client de services de télécommunications et de paiement mobile :

### 1. Authentification & Inscription
* **Login (`LoginScreen`)** : Connexion sécurisée en saisissant le numéro de téléphone (ou identifiant administrateur) et le mot de passe.
* **Inscription (`RegisterScreen`)** : Création d'un nouveau compte client (nom, prénom, numéro de téléphone, mot de passe et date de naissance). L'inscription engendre automatiquement l'ouverture d'un portefeuille électronique associé à 0 XOF dans le backend.

### 2. Tableau de Bord (`HomeScreen`)
* Hub central présentant le profil du client connecté (son numéro) et des boutons d'accès rapide aux services.
* Un outil de recherche dynamique pour filtrer les services.

### 3. Achat de Crédit (`AchatCreditScreen`)
* Achat de crédit téléphonique pour son propre numéro ou pour un numéro tiers.
* Permet de consulter le solde actuel de son compte principal avant de valider la transaction.

### 4. Achat de Pass Internet & Illimix (`AchatInternetScreen` & `AchatIllimixScreen`)
* Récupère de façon dynamique les pass actifs depuis le `pricing-service`.
* Permet d'acheter un pass pour soi ou un destinataire en choisissant le moyen de paiement approprié :
  - **`WALLET`** : Débit direct sur le solde du portefeuille virtuel.
  - **`CREDIT`** : Achat via le crédit de communication téléphonique.

### 5. Module Rapido (`RapidoScreen`)
* Permet de gérer une carte de péage/transport **Rapido** :
  - Enregistrer une carte Rapido existante en saisissant son numéro à 10 chiffres.
  - Consulter le solde de la carte en temps réel.
  - Recharger le solde de la carte Rapido par débit du compte principal.

---

## 📡 Connexion Réseau & Détection Dynamique de l'Hôte

Pour simplifier le développement et le test sur mobile physique (connecté au même réseau Wi-Fi), l'application intègre un **mécanisme intelligent de détection de l'hôte** (`ApiService.getBaseUrl`) :

1. **Scan de sous-réseau (Mobile Debug)** : En mode debug, l'application liste les interfaces réseau de l'appareil mobile, détermine le sous-réseau local (ex: `192.168.1.0/24`), et tente de se connecter sur le port `8765` de toutes les adresses IP du sous-réseau en parallèle.
2. **Auto-détection** : Si le PC de développement exécutant l'API Gateway Spring Cloud est trouvé, son IP est mise en cache et utilisée pour toutes les requêtes subséquentes.
3. **Mécanisme de secours (Fallback)** :
   - Sur le Web : cible par défaut `http://localhost:8765`.
   - Sur l'émulateur Android : cible l'IP configurée ou l'IP de la passerelle de l'émulateur.

---

## 🚀 Démarrage et Installation

### Prérequis
- **Flutter SDK** (v3.12.0 ou supérieure).
- Un émulateur configuré ou un appareil mobile physique connecté.

### Étapes d'exécution :

1. **Installer les dépendances** :
   ```bash
   flutter pub get
   ```

2. **Lancer l'application** :
   * En mode développement classique :
     ```bash
     flutter run
     ```
   * En spécifiant une URL d'API fixe (ex: production ou staging) :
     ```bash
     flutter run --dart-define=API_URL=http://votre-serveur:8765
     ```
