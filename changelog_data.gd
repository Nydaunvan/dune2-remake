class_name ChangelogData
## Journal des versions (du plus récent au plus ancien). Voir aussi CHANGELOG.md.

const VERSIONS := [
	["0.20", "2026-11-12", "Accueil désert", ["Écran d'accueil : dunes en couches, deux lunes, voie lactée, étoiles, étoile filante", "Noms de faction centrés, capacité des mineurs exacte (160)"]],
	["0.19", "2026-11-12", "Escarmouche paramétrable", ["Fenêtre de paramètres : 1 ou 2 adversaires, faction adverse, taille de carte, ressources, difficulté", "Adversaires indiqués dans les missions de campagne", "Difficulté croissante de 1 à 10, objectifs plus longs, finale à trois camps"]],
	["0.18", "2026-11-12", "Journal, victoire et circulation", ["Journal des versions cliquable (menu principal, pause, F2)", "Une mission n'est gagnée que si tous ses objectifs sont remplis", "Circulation plus intelligente, ouvriers pleins toujours vers le dépôt", "Bouton central de la souris : glisser la carte"]],
	["0.17", "2026-11-12", "Radar et brouillard par faction", ["Radar modernisé", "Brouillard propre au joueur : bases et unités non découvertes toujours cachées", "Prérequis clarifiés (« Usine niveau 3 » une seule fois)"]],
	["0.16", "2026-11-12", "Campagnes étendues", ["10 missions par faction, toutes différentes, nouveaux types d'objectifs, temps limites", "Coûts prélevés progressivement, annulation = remboursement du déjà payé", "Zone de construction autour des Chantiers, Engin de chantier pour une seconde base", "Le convoi de mission n'est plus commandable"]],
	["0.15", "2026-11-12", "Ergonomie", ["Boutons Améliorer / Réparer / Démolir en haut de la fiche", "Barre d'énergie : consommation à gauche, production à droite, dégradé bleu → rouge", "Les véhicules contournent un véhicule à l'arrêt, limite d'ouvriers selon le Chantier", "Barres de bâtiments toujours visibles, bâtiment hors service pendant les travaux"]],
	["0.14", "2026-11-12", "Guide du joueur", ["Touche F1, bouton GUIDE, menu pause et menu principal", "Poussière et éclats pendant la récolte", "Récolteurs et mineurs : une case de ressource chacun"]],
	["0.13", "2026-11-12", "Trois camps et bâtiments évolutifs", ["3e faction hostile (chacun pour soi) en escarmouche et dans 5 missions, objectifs multiples", "Design amélioré à chaque niveau : blindages, antenne, module de toit, bande énergétique, dôme doré"]],
	["0.12", "2026-11-12", "Combat aérien et commandes", ["Anti-air réservé à certaines unités et défenses, vol plus haut, orientation alignée sur le cap", "Commandes d'unité dans l'encart d'information, journal des événements"]],
	["0.11", "2026-11-12", "Énergie et interface", ["Consommation électrique visible sur chaque bâtiment ; les améliorations consomment plus", "Pannes d'énergie : récolte, radar, réparation, défenses et aérodrome hors tension", "Interface translucide, cartouche d'information compact", "Alerte ver de sable : zone de danger sur la carte et le radar"]],
	["0.10", "2026-11-12", "Sauvegarde et menu", ["Sauvegarde et chargement à tout moment (menu pause, F6 / F7)", "Menu principal modernisé : emblèmes de faction animés, titre à reflet", "Bouton OBJECTIFS (touche O)"]],
	["0.09", "2026-11-11", "Escarmouche et économie", ["Bâtiments débloqués par le niveau du Chantier", "Murs alignés, bouton Démolir avec remboursement", "Véhicules plus lents, bâtiments payés aussi en Solaris, récolte nettement plus lente", "Effets d'armes plus discrets, collisions entre unités terrestres, stockage affiché"]],
	["0.08", "2026-11-11", "Unités volantes", ["9 unités volantes, Aérodrome, transport, icônes issues des vrais modèles 3D", "Terrain lissé (bicubique, bords organiques), IA adoucie, réparations"]],
	["0.07", "2026-11-11", "Missions détaillées", ["Fiche détaillée de chaque mission dans le menu campagne", "Plus de temps de préparation, route du convoi plus dégagée", "Une campagne différente par faction (15 missions)"]],
	["0.06", "2026-11-11", "Énergie et déblocages", ["Gestion de l'énergie : constructions bloquées sans courant, défenses hors tension", "12 bâtiments débloqués par la campagne, unités débloquées par le niveau d'Usine", "Améliorations avec coût et durée, modernisation des unités"]],
	["0.05", "2026-11-11", "Campagnes", ["Premières campagnes avec briefings et progression, sons et musique générés par code", "Départ avec l'engin de chantier à déployer, cartes plus grandes, alliés", "Écran de chargement ; le jeu devient « The Building of a Dynasty »"]],
	["0.04", "2026-11-11", "Gestion de la base", ["File d'attente de production, améliorations, panneau d'informations, rangs", "Brouillard de guerre et équilibrage", "Style Sietch-tech : coins coupés, crochets dorés, jauges segmentées"]],
	["0.03", "2026-11-11", "Combat et modèles 3D", ["Combat, tourelles, IA d'escarmouche, victoire et défaite", "Modèles 3D low-poly cuits en sprites, ombres et projection oblique"]],
	["0.02", "2026-11-11", "Rendu et factions", ["Rendu Forward+ avec MSAA, HDR et lueurs, résolution adaptative", "Interface en verre dépoli néon", "Trois factions, menu de choix, récolte d'épice et de minerai, vers de sable géants"]],
	["0.01", "2026-11-11", "Fondations", ["Carte générée, caméra libre, sélection et déplacement des unités", "Terrain sable/roche procédural", "Interface : radar, ressources, menu de construction"]],
]


static func current() -> String:
	return VERSIONS[0][0]
