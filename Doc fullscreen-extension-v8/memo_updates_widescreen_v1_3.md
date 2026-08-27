# MÉMO TECHNIQUE D'IMPLÉMENTATION & MISES À JOUR (v1.3)
## Sélecteur de Mode Écran (Wide / Middle / Normal) & Stabilisation de la Largeur des Tables

> **Date** : 27 Août 2026  
> **Auteur** : Architecte UI Front-End Senior  
> **Dossier** : `Doc fullscreen-extension-v8`  
> **Statut** : ✅ Implémenté, testé & validé sans erreurs de build TypeScript  

---

## 1. Contexte & Problématique Résolue

L'application utilisait initialement une extension Chrome externe pour forcer le mode Wide Screen sur les tables d'audit. Ce comportement a été migré vers un composant React natif (`ScreenSelector`). 

Cependant, lors de l'extension de la largeur des tables (notamment les tables modélisées d'audit comportant de nombreuses colonnes comme *Conclusion*, *Ecart*, *CTR 1-3*, *Description*), les versions précédentes provoquaient des anomalies d'affichage majeures :
1. **Débordement du viewport global** : Le navigateur forçait un défilement horizontal sur l'élément `body` ou `html`. Lors du scroll vers la droite pour visualiser la fin d'une table, la barre haute (**Topbar**) et la barre latérale (**Sidebar**) défilaient hors de l'écran (elles disparaissaient sur la gauche).
2. **Perte de symétrie et de centrage** : La zone de message et la zone de saisie du chat (`[data-widescreen-target="container"]`) n'étaient plus alignées de manière symétrique au milieu de l'écran.
3. **Coupure des colonnes à droite** : La dernière colonne (souvent cruciale, ex: *Description* ou *Conclusion*) voyait sa bordure droite tronquée contre le bord de l'écran.
4. **Perte d'espace horizontal (~176px)** : Les paddings cumulés par défaut (paddings de chat `p-6`, marge du conteneur `96%`, largeur d'avatar et écartement) réduisaient la largeur maximale réelle disponible pour les tables.

---

## 2. Nouvelles Actions Disponibles

Le composant [`ScreenSelector.tsx`](file:///h:/ClaraVerse/src/components/ScreenSelector.tsx) propose désormais 3 actions distinctes dans la Topbar :
1. **Wide screen (`wide`)** : Agrandissement maximal de la table à sa largeur naturelle, plafonné aux limites physiques sécurisées de l'écran. 
   * *Indicateur visuel* : Icône de moniteur **bleue** (`text-blue-500`).
2. **Middle screen (`middle`)** : Agrandissement intermédiaire calculé à **90%** de la largeur Wide screen.
   * *Indicateur visuel* : Icône de moniteur **orange** (`text-orange-500`).
3. **Normal screen (`normal`)** : Restauration des styles natifs réponsifs standards de l'application.
   * *Indicateur visuel* : Icône de moniteur **grise** (`text-gray-700 dark:text-gray-300`).

---

## 3. Architecture Technique de Stabilisation

La nouvelle architecture dans [`screenManager.ts`](file:///h:/ClaraVerse/src/utils/screenManager.ts) repose sur la séparation du **calcul de la largeur physique maximale**, la **sécurisation du viewport**, et la **réduction des retraits inutiles**.

### A. Calcul Dynamique et Capping de la Largeur
Lors de la détection de tables modélisées, le script scanne leur largeur réelle de contenu (`scrollWidth`). Au lieu d'injecter des valeurs brutes qui pourraient dépasser la résolution d'écran de l'utilisateur, la largeur est plafonnée :
```typescript
// Calcul de la largeur nécessaire
const neededWidth = tableScrollWidth + 60; // 60px de marge d'ajustement
if (neededWidth > sessionMaxTargetWidth) {
  sessionMaxTargetWidth = neededWidth;
}

// Récupération de la largeur réelle du viewport de l'utilisateur
const viewportWidth = window.innerWidth || document.documentElement.clientWidth || 1920;

// Marge d'écran minimale de 12px au total (6px à gauche, 6px à droite)
const maxSafeViewportWidth = Math.max(800, viewportWidth - 12);

// Application du multiplicateur (1.0 pour wide, 0.9 pour middle)
const rawTargetWidth = Math.round(sessionMaxTargetWidth * widthMultiplier);

// Capping de la largeur effective
const effectiveWidth = Math.min(rawTargetWidth, maxSafeViewportWidth);
```

### B. Isolation du Défilement et Verrouillage global (CSS Injecté)
Pour garantir que la Topbar et la structure de l'application restent fixes et centrées, le scroll horizontal au niveau du document est bloqué. Le défilement est restreint uniquement à la bulle de message contenant la table :
```css
/* Bloque tout défilement sur la page entière */
html, body {
  overflow-x: hidden !important;
}

/* Scrollboard isolé pour la table si celle-ci excède la largeur maximale de la bulle */
body[data-clara-screen-mode="wide"] .prose div:has(> table) {
  max-width: 100% !important;
  width: 100% !important;
  overflow-x: auto !important;
  box-sizing: border-box !important;
  padding-right: 6px !important;
  scrollbar-width: thin !important;
}
```

### C. Réduction des Retraits (Gains d'Espace Bord à Bord)
Afin de minimiser le retrait à gauche et à droite pour les écrans plus petits tout en conservant la symétrie, les styles injectés en mode `wide`/`middle` surchargent les paddings Tailwind :
* **Padding du chat réduit** : `.flex-1.overflow-y-auto` passe de `p-6` (24px) à `6px` à gauche et à droite.
* **Largeur du conteneur** : Passe de `96%` à `calc(100% - 12px)` (laisse exactement 6px de marge extérieure).
* **Gap d'avatar** : Réduit de `16px` à `8px`.
* **Padding de bulle** : Réduit de `20px` à `8px`.

*Résultat* : **Plus de 130px de largeur horizontale brute** sont récupérés au profit de l'affichage direct de la table sans avoir besoin de scroller.

---

## 4. Schéma de l'Arborescence & Détection

Le script [`screenManager.ts`](file:///h:/ClaraVerse/src/utils/screenManager.ts) intercepte les tables à agrandir en recherchant des mots-clés dans les 30 premières cellules d'en-tête (pour inclure les tables complexes de consolidation) :

```typescript
export function isModelizedTable(table: HTMLTableElement): boolean {
  const headers = Array.from(table.querySelectorAll('th, td')).slice(0, 30).map(c => c.textContent?.toLowerCase().trim() || '');
  if (headers.length > 0) {
    const hasKeyword = headers.some(h => {
      if (h.includes('conclusion')) return true;
      if (h.includes('assertion')) return true;
      if (h.includes('ecart') || h.includes('écart')) return true;
      if (h.includes('resultat') || h.includes('résultat')) return true;
      if (/ctr\s*\d*/i.test(h)) return true;
      if (h.includes('table de consolidation') || h.includes('consolidation')) return true;
      if (h.includes('cross reference') || h.includes('cross references')) return true;
      return false;
    });
    if (hasKeyword) return true;
  }
  // Fallback si plus de 5 colonnes
  const firstRowCells = table.querySelectorAll('tr:first-child th, tr:first-child td');
  return firstRowCells.length >= 5;
}
```

---

## 5. Directives pour les Futures Mises à Jour (Agents de code)

* **Règle 1** : Ne jamais appliquer de `margin-left` ou `margin-right` fixes sur `[data-widescreen-target="bubble"]` sous peine de casser l'alignement flexbox avec l'avatar.
* **Règle 2** : Conserver `box-sizing: border-box !important` sur tous les conteneurs élargis pour éviter que les paddings n'ajoutent de la largeur supplémentaire hors-viewport.
* **Règle 3** : Le `MutationObserver` dynamique se déconnecte temporairement lors des ajustements pour éviter les boucles de rendu infinies (voir fonction `debouncedAdjust`). Toujours conserver ce pattern en cas de modifications de l'observateur.
* **Règle 4** : Pour ajouter un nouveau mot-clé de table d'audit, modifier la fonction `isModelizedTable` dans `screenManager.ts` en ajoutant une règle d'inclusion dans le tableau `hasKeyword`.
