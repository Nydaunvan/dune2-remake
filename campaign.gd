class_name Campaign
## Campagnes : de 15 à 18 missions selon la faction, objectifs variés, progression sauvegardée.
## Tous les camps démarrent avec un simple engin de chantier à déployer.

const SAVE_PATH := "user://campaign.cfg"

## (l'élimination d'une faction n'est jamais requise sauf si destroy_all figure dans les objectifs)
## Types d'objectifs : build, harvest, train, survive, destroy_all, outposts,
## escort, waves (assauts ennemis repoussés), worms (vers géants abattus).
const BASE := {"centrale": 1, "raffinerie": 1, "fonderie": 1, "usine": 1}

## Une campagne différente par faction : 15 à 18 missions chacune, avec son propre adversaire,
## ses objectifs, son rythme et son briefing ({ENEMY} et {RIVAL} = noms des factions).
const CAMPAIGNS := {
	# --- Maison Solis : défense, précision, patience ---
	"solis": [
		{
			"id": "camp", "title": "Premier camp", "enemy": "vael", "size": 80, "credits": 1500, "ore": 1800,
			"objectives": [{"type": "build", "label": "la base", "ids": BASE}, {"type": "harvest", "amount": 2500}],
			"ai": {"slowdown": 2.4, "grace": 900.0, "pause": 120.0, "max_army": 6, "wave": 4, "credits": 1000, "ore": 1200},
			"obj": "Établissez votre base et récoltez 2500 Solaris",
			"brief": "Les ingénieurs de Solis ont repéré un plateau stable. Déployez le chantier, bâtissez une base propre et efficace, puis récoltez de quoi lancer la campagne. {ENEMY} rôde dans la région, mais ne frappera pas avant longtemps.",
		},
		{
			"id": "balises", "title": "Les balises", "enemy": "kharn", "size": 96, "outposts": 2, "credits": 1800, "ore": 2000,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "outposts"}, {"type": "train", "count": 5}],
			"ai": {"slowdown": 2.0, "grace": 420.0, "pause": 80.0, "max_army": 8, "wave": 4, "credits": 1200, "ore": 1500},
			"obj": "Détruisez les 2 balises de guerre ennemies",
			"brief": "{ENEMY} a planté deux balises de guerre pour brouiller nos capteurs. Précision d'abord : montez une petite armée de qualité et détruisez-les avant que la Légion ne s'organise.",
		},
		{
			"id": "relais", "title": "Relais de surveillance", "enemy": "vael", "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "build", "label": "le poste de guet", "ids": {"radar": 1, "tourelle": 2}}, {"type": "kills", "count": 8}],
			"obj": "Bâtissez un radar et deux tourelles, abattez 8 unités ennemies",
			"brief": "Solis veut voir venir : installez un radar et deux tourelles sur la crête. {ENEMY} enverra des éclaireurs pour vous en empêcher ; abattez-les et gardez votre poste de guet.",
		},
		{
			"id": "ligne", "title": "Tenir la ligne", "enemy": "kharn", "rival": true, "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "ally_units": 2,
			"objectives": [{"type": "waves", "count": 3}, {"type": "kills", "count": 10}],
			"ai": {"slowdown": 1.5, "grace": 300.0, "pause": 60.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Repoussez 3 assauts et abattez 10 unités ennemies",
			"brief": "{ENEMY} va déferler en force et {RIVAL} guette le moment où nous faiblirons. Aucune de ces deux maisons n'est notre amie : fortifiez-vous, repoussez leurs assauts et faites payer chaque vague.",
		},
		{
			"id": "aurore", "title": "Défense de l'aube", "enemy": "kharn", "size": 96, "credits": 2200, "ore": 2400,
			"start_units": ["@0", "@0", "@1"], "zone": {"time": 240.0, "units": 5},
			"objectives": [{"type": "hold"}, {"type": "train", "count": 6}],
			"obj": "Tenez la zone centrale avec 5 unités et formez 6 unités",
			"brief": "Au centre du plateau, les capteurs de Solis captent l'aurore : un lieu stratégique que {ENEMY} convoite. Gardez la zone avec une troupe solide, sans y laisser un seul ennemi.",
		},
		{
			"id": "cristaux", "title": "Convoi de cristaux", "enemy": "kharn", "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"],
			"convoy": {"count": 5, "need": 4, "ambushes": 2, "start": 420.0, "ambush_size": 2},
			"objectives": [{"type": "escort"}, {"type": "train", "count": 6}, {"type": "harvest", "amount": 2500}],
			"ai": {"slowdown": 1.6, "grace": 600.0, "pause": 80.0, "max_army": 10, "wave": 5, "credits": 1500, "ore": 1800},
			"obj": "Escortez le convoi (4 camions sur 5), formez 6 unités et récoltez 2500 Solaris",
			"brief": "Cinq camions chargés de cristaux de focalisation doivent quitter la région par le point d'évacuation, près des lignes de {ENEMY}, qui a posté des embuscades : sécurisez la route avec votre armée et ne perdez qu'un camion au plus.",
		},
		{
			"id": "sommet", "title": "Le sommet", "enemy": "kharn", "rival": true, "size": 112, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@0", "@1", "@1"], "ally_units": 3,
			"outposts": 3,
			"objectives": [{"type": "outposts"}, {"type": "kills", "count": 20}, {"type": "train", "count": 10}],
			"ai": {"slowdown": 1.15, "grace": 360.0, "pause": 50.0, "max_army": 22, "wave": 6, "credits": 2500, "ore": 2800},
			"third_ai": {"slowdown": 1.5, "grace": 420.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Rasez 3 avant-postes, formez 10 unités et abattez 20 unités ennemies",
			"brief": "Le grand sommet réunit trois maisons et aucune n'a d'allié. {ENEMY} et {RIVAL} se battent aussi entre eux : rasez les avant-postes disséminés sur le plateau, bâtissez une armée et faites payer chaque camp qui s'approche.",
		},
		{
			"id": "laboratoire", "title": "Le laboratoire", "enemy": "vael", "size": 96, "credits": 3000, "ore": 3500,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "upgrade", "id": "chantier", "level": 3}, {"type": "upgrade", "id": "usine", "level": 2},
					{"type": "upgrade", "id": "centrale", "level": 3}, {"type": "build", "label": "le complexe", "ids": {"radar": 1, "reacteur": 1}}],
			"ai": {"slowdown": 1.9, "grace": 420.0, "pause": 70.0, "max_army": 10, "wave": 5, "credits": 1500, "ore": 1800},
			"obj": "Portez Chantier, Usine et Centrale à leur niveau cible et bâtissez radar et réacteur",
			"brief": "Le conseil de Solis veut une vitrine : un campement entièrement modernisé. Montez le Chantier, l'Usine et la Centrale aux niveaux demandés, puis ajoutez un radar et un réacteur. Pendant les travaux un bâtiment ne produit plus : échelonnez les chantiers pendant que {ENEMY} observe de loin.",
		},
		{
			"id": "foreuses", "title": "Les foreuses", "enemy": "conclave", "size": 96, "credits": 2200, "ore": 2400,
			"start_units": ["recolteur", "recolteur", "@0", "@1"], "worm_rate": 3.0, "worm_hp": 4000.0, "worm_grace": 90.0,
			"objectives": [{"type": "ore", "amount": 3000}, {"type": "harvest", "amount": 3000}, {"type": "worms", "count": 1}],
			"obj": "Récoltez 3000 minerai et 3000 Solaris, et abattez un ver géant",
			"brief": "Les ingénieurs veulent de nouvelles foreuses : il faut du minerai et de l'épice en quantité, et des vers qui rôdent. Protégez vos engins de récolte, abattez l'un de ces vers géants et surveillez {ENEMY}, qui teste vos lignes.",
		},
		{
			"id": "tempete", "title": "Tempête d'épice", "enemy": "kharn", "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["recolteur", "recolteur", "@0", "@1"], "worm_rate": 5.0, "worm_hp": 4000.0, "worm_grace": 60.0,
			"objectives": [{"type": "harvest", "amount": 4000}, {"type": "worms", "count": 1}, {"type": "train", "count": 6}],
			"ai": {"slowdown": 1.5, "grace": 240.0, "pause": 60.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Récoltez 4000 Solaris, abattez un ver géant et formez 6 unités",
			"brief": "Une tempête d'épice a réveillé les vers de sable : ils rôdent partout. Récoltez malgré eux, faites fuir vos récolteurs au bon moment, gardez une escorte et abattez l'un de ces monstres quand il se dresse. {ENEMY} profite du chaos pour tâter nos défenses.",
		},
		{
			"id": "frappe", "title": "Frappe chirurgicale", "enemy": "vael", "enemy_base": true, "size": 96, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@0", "@1", "@2"], "time_limit": 900.0,
			"objectives": [{"type": "destroy_type", "id": "centrale", "count": 1}, {"type": "destroy_type", "id": "raffinerie", "count": 1},
					{"type": "destroy_type", "id": "fonderie", "count": 1}],
			"ai": {"slowdown": 1.6, "grace": 360.0, "pause": 60.0, "max_army": 12, "wave": 5, "credits": 2000, "ore": 2200},
			"obj": "Détruisez la centrale, la raffinerie et la fonderie de l'ennemi en 15 minutes",
			"brief": "La base de {ENEMY} est déjà là, en ordre de marche. Précision d'abord : coupez son énergie, sa récolte et son minerai avant la fin du temps imparti. Chaque minute perdue lui laisse le temps de se fortifier.",
		},
		{
			"id": "orbite", "title": "Tir orbital", "enemy": "kharn", "size": 112, "credits": 3500, "ore": 3500,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "build", "label": "la batterie orbitale", "ids": {"radar": 1, "canon_solaire": 1}}, {"type": "kills", "count": 20}],
			"obj": "Bâtissez un radar et un canon solaire, abattez 20 unités ennemies",
			"brief": "Le projet le plus secret de Solis : une frappe orbitale à très longue portée. Montez le canon solaire, protégez-le et prouvez sa puissance sur les colonnes de {ENEMY}.",
		},
		{
			"id": "pont", "title": "Pont aérien", "enemy": "conclave", "size": 112, "credits": 3500, "ore": 3500,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "build", "label": "la base aérienne", "ids": {"usine": 1, "aerodrome": 1}},
					{"type": "air", "count": 4}, {"type": "kills", "count": 15}],
			"ai": {"slowdown": 1.3, "grace": 300.0, "pause": 50.0, "max_army": 16, "wave": 6, "credits": 2200, "ore": 2400},
			"obj": "Bâtissez un aérodrome, alignez 4 appareils et abattez 15 unités ennemies",
			"brief": "L'avenir de Solis est dans le ciel. Construisez un aérodrome, formez une escadre et prouvez sa valeur en détruisant les unités de {ENEMY}. Leurs batteries antiaériennes sont rares mais redoutables.",
		},
		{
			"id": "siege", "title": "Siège de la citadelle", "enemy": "vael", "enemy_base": true, "size": 112, "credits": 3500, "ore": 3500,
			"start_units": ["@0", "@0", "@1", "@1", "@2"], "time_limit": 1200.0,
			"objectives": [{"type": "destroy_all"}],
			"obj": "Détruisez la base de l'ennemi en 20 minutes",
			"brief": "{ENEMY} s'est retranché dans une citadelle. Il faut la prendre avant qu'elle ne soit terminée : levez une armée, avancez sous couverture de vos tourelles et rasez tout ce qui s'y trouve.",
		},
		{
			"id": "aiguille", "title": "L'Aiguille", "enemy": "kharn", "start_base": true, "size": 112, "credits": 3000, "ore": 3000,
			"start_units": ["@0", "@0", "@1"],
			"objectives": [{"type": "waves", "count": 4}, {"type": "kills", "count": 25},
					{"type": "build", "label": "le front", "ids": {"tourelle": 4}}, {"type": "upgrade", "id": "tourelle", "level": 2}],
			"ai": {"slowdown": 1.1, "grace": 200.0, "pause": 45.0, "max_army": 24, "wave": 7, "credits": 3000, "ore": 3200},
			"obj": "Repoussez 4 assauts, détruisez 25 unités, alignez 4 tourelles dont une améliorée",
			"brief": "Dernier rempart : la base de l'Aiguille est déjà bâtie, mais {ENEMY} y envoie tout ce qu'elle possède. Fortifiez, améliorez vos tourelles et brisez ses assauts un par un jusqu'à la relève.",
		},
	],
	# --- Légion Kharn : puissance brute, offensive ---
	"kharn": [
		{
			"id": "terre", "title": "Terre brûlée", "enemy": "solis", "size": 80, "credits": 1500, "ore": 1800,
			"objectives": [{"type": "build", "label": "la base", "ids": BASE}, {"type": "train", "count": 4}],
			"ai": {"slowdown": 2.4, "grace": 900.0, "pause": 120.0, "max_army": 6, "wave": 4, "credits": 1000, "ore": 1200},
			"obj": "Bâtissez la base et produisez 4 unités",
			"brief": "La Légion pose son premier camp sur une terre ravagée. Montez les murs de la base, sortez les premiers blindés, et montrez à {ENEMY} que la région nous appartient.",
		},
		{
			"id": "raid", "title": "Raid des avant-postes", "enemy": "vael", "size": 112, "outposts": 3, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@0", "@1"],
			"objectives": [{"type": "outposts"}, {"type": "train", "count": 6}],
			"ai": {"slowdown": 1.9, "grace": 360.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1500, "ore": 1800},
			"obj": "Rasez les 3 avant-postes de contrebande",
			"brief": "{ENEMY} abrite ses entrepôts derrière trois avant-postes. Pas de finesse : alignez vos blindés et rasez-les un par un.",
		},
		{
			"id": "garnison", "title": "La garnison", "enemy": "solis", "size": 96, "credits": 1800, "ore": 2000,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "waves", "count": 2}, {"type": "kills", "count": 10}],
			"obj": "Repoussez 2 assauts et abattez 10 unités ennemies",
			"brief": "Notre garnison avancée est isolée. {ENEMY} la sait faible et lance des raids. Repoussez leurs assauts, laissez-les se briser sur vos blindés, puis passez à la contre-attaque.",
		},
		{
			"id": "percee", "title": "La percée", "rival": true, "enemy": "solis", "size": 96, "credits": 2000, "ore": 2200,
			"ally_units": 2, "start_units": ["@0", "@1"],
			"outposts": 3,
			"objectives": [{"type": "outposts"}, {"type": "train", "count": 8}, {"type": "harvest", "amount": 2500}],
			"ai": {"slowdown": 1.5, "grace": 300.0, "pause": 60.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"third_ai": {"slowdown": 1.5, "grace": 420.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Rasez 3 avant-postes, formez 8 unités et récoltez 2500 Solaris",
			"brief": "Le col central attire aussi {RIVAL}, qui n'est l'ami de personne. Occupez-le avec une troupe solide face à {ENEMY} et aux pillards, sans négliger la récolte.",
		},
		{
			"id": "colline", "title": "La colline 31", "enemy": "solis", "size": 96, "credits": 2200, "ore": 2400,
			"start_units": ["@0", "@0", "@1"], "zone": {"time": 240.0, "units": 6},
			"objectives": [{"type": "hold"}, {"type": "train", "count": 8}],
			"obj": "Tenez la colline avec 6 unités et formez 8 unités",
			"brief": "La colline 31 domine la vallée : qui la tient commande la région. Prenez-la, installez une troupe de blindés et interdisez-la à {ENEMY}.",
		},
		{
			"id": "guerre", "title": "Convoi de guerre", "enemy": "vael", "rival": true, "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "ally_units": 2,
			"convoy": {"count": 4, "need": 3, "ambushes": 3, "start": 420.0, "ambush_size": 3},
			"objectives": [{"type": "escort"}, {"type": "train", "count": 5}],
			"ai": {"slowdown": 1.7, "grace": 600.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1500, "ore": 1800},
			"obj": "Escortez le convoi de munitions : 3 camions sur 4 doivent être évacués",
			"brief": "Un convoi de munitions doit être évacué vers le front par le point d'évacuation, non loin des lignes de {ENEMY}, qui a tendu trois embuscades sur la route, plus nombreuses mais moins bien défendues : brisez-les. {RIVAL} rôde aussi dans la région et ne fera aucun cadeau.",
		},
		{
			"id": "ecrasement", "title": "L'écrasement", "enemy": "solis", "rival": true, "size": 112, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@0", "@1", "@1"], "ally_units": 3,
			"objectives": [{"type": "kills", "count": 30}, {"type": "train", "count": 12}, {"type": "harvest", "amount": 5000}],
			"ai": {"slowdown": 1.1, "grace": 360.0, "pause": 50.0, "max_army": 24, "wave": 6, "credits": 2500, "ore": 2800},
			"third_ai": {"slowdown": 1.5, "grace": 420.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Abattez 30 unités ennemies, formez 12 unités et récoltez 5000 Solaris",
			"brief": "La campagne se joue ici et chacun pour soi : {ENEMY} et {RIVAL} s'entre-déchirent. Écrasez leurs armées l'une après l'autre, mais gardez l'œil sur les caisses : la guerre se paie.",
		},
		{
			"id": "rouge", "title": "Tempête rouge", "enemy": "vael", "size": 96, "credits": 2500, "ore": 2500,
			"start_units": ["recolteur", "recolteur", "@0", "@1"], "worm_rate": 4.0, "worm_hp": 4000.0, "worm_grace": 60.0,
			"objectives": [{"type": "harvest", "amount": 4000}, {"type": "kills", "count": 15}, {"type": "worms", "count": 1}],
			"obj": "Récoltez 4000 Solaris, abattez 15 unités et un ver géant",
			"brief": "Une tempête rouge soulève les vers. {ENEMY} compte en profiter pour nous harceler. La Légion ne recule pas : escortez vos récolteurs, abattez les harceleurs et terrassez l'un de ces vers.",
		},
		{
			"id": "blitz", "title": "Blitzkrieg", "enemy": "solis", "start_base": true, "enemy_base": true, "size": 80, "credits": 3000, "ore": 3000,
			"start_units": ["@0", "@0", "@1", "@1", "@2", "@2"], "time_limit": 720.0,
			"objectives": [{"type": "destroy_all"}, {"type": "kills", "count": 15}],
			"ai": {"slowdown": 2.0, "grace": 900.0, "pause": 90.0, "max_army": 8, "wave": 4, "credits": 1200, "ore": 1500},
			"obj": "Rasez toute la présence ennemie en 12 minutes",
			"brief": "Pas de préparatifs : la base est prête, les blindés aussi. {ENEMY} n'a pas fini de s'installer. Le temps est compté : tout raser avant que ses renforts n'arrivent.",
		},
		{
			"id": "forge", "title": "La forge de guerre", "enemy": "vael", "size": 96, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "ore", "amount": 5000}, {"type": "train", "count": 14},
					{"type": "build", "label": "les défenses", "ids": {"tourelle": 4}}, {"type": "power", "amount": 250}],
			"ai": {"slowdown": 1.6, "grace": 360.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Récoltez 5000 minerai, alignez 14 unités, 4 tourelles et 250 d'énergie",
			"brief": "La Légion forge ses armes dans le minerai. Alimentez les fournaises : des tonnes de minerai, une armée de machines, des tourelles et assez d'énergie pour tout faire tourner. {ENEMY} tentera de saboter l'effort.",
		},
		{
			"id": "tranchees", "title": "Guerre de tranchées", "enemy": "solis", "size": 96, "credits": 3000, "ore": 3000,
			"start_units": ["@0", "@0", "@1"],
			"objectives": [{"type": "build", "label": "les défenses", "ids": {"tourelle": 4, "bunker": 2}}, {"type": "waves", "count": 3}, {"type": "kills", "count": 20}],
			"obj": "Bâtissez 4 tourelles et 2 bunkers, repoussez 3 assauts et abattez 20 unités",
			"brief": "Rien ne passe : enterrez vos défenses et repoussez les assauts de {ENEMY} : elle s'épuisera sur la ligne. Quand elle faiblira, c'est la Légion qui frappera.",
		},
		{
			"id": "pluie", "title": "Pluie d'acier", "enemy": "conclave", "enemy_base": true, "size": 112, "credits": 3500, "ore": 3500,
			"start_units": ["@0", "@1"], "time_limit": 1500.0,
			"objectives": [{"type": "air", "count": 5}, {"type": "destroy_all"}],
			"ai": {"slowdown": 1.3, "grace": 420.0, "pause": 60.0, "max_army": 16, "wave": 6, "credits": 2200, "ore": 2400},
			"obj": "Alignez 5 appareils et détruisez la base ennemie en 25 minutes",
			"brief": "La Légion apprend à frapper d'en haut. Bâtissez un aérodrome, montez une escadre puis écrasez la forteresse de {ENEMY} avec l'appui du ciel. Le temps est compté.",
		},
		{
			"id": "decapitation", "title": "Décapitation", "enemy": "vael", "enemy_base": true, "size": 96, "credits": 3000, "ore": 3000,
			"start_units": ["@0", "@0", "@1", "@1", "@2"], "time_limit": 900.0,
			"objectives": [{"type": "destroy_type", "id": "chantier", "count": 1}, {"type": "destroy_type", "id": "centrale", "count": 1}],
			"obj": "Détruisez le chantier et la centrale ennemis en 15 minutes",
			"brief": "Sans chantier ni énergie, {ENEMY} ne reconstruira plus. Percez sa base d'un seul coup de poing et détruisez-en le cœur avant la fin du temps imparti.",
		},
		{
			"id": "disputees", "title": "Terres disputées", "enemy": "solis", "rival": true, "size": 112, "outposts": 3, "credits": 2500, "ore": 2500,
			"ally_units": 3, "start_units": ["@0", "@0", "@1"],
			"objectives": [{"type": "outposts"}, {"type": "kills", "count": 30}, {"type": "harvest", "amount": 3000}, {"type": "ore", "amount": 2000}],
			"ai": {"slowdown": 1.7, "grace": 360.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"third_ai": {"slowdown": 1.7, "grace": 420.0, "pause": 70.0, "max_army": 10, "wave": 5, "credits": 1600, "ore": 1800},
			"obj": "Rasez 3 avant-postes, détruisez 30 unités, récoltez 3000 Solaris et 2000 minerai",
			"brief": "Trois maisons se disputent la même vallée. {ENEMY} garde trois avant-postes, {RIVAL} pille tout ce qui passe. Prenez-les à tous les deux : abattez les avant-postes, faites des victimes et remplissez vos réserves de Solaris et de minerai.",
		},
		{
			"id": "cimetiere", "title": "Le cimetière d'acier", "enemy": "solis", "rival": true, "size": 112, "outposts": 4, "credits": 3000, "ore": 3000,
			"start_units": ["@0", "@0", "@1", "@1"], "ally_units": 2,
			"objectives": [{"type": "outposts"}, {"type": "kills", "count": 35}],
			"obj": "Rasez 4 avant-postes et abattez 35 unités ennemies",
			"brief": "Les carcasses des guerres passées gardent encore des avant-postes. {ENEMY} et {RIVAL} s'y disputent la ferraille : écrasez les uns et les autres, la Légion prendra tout.",
		},
		{
			"id": "trone", "title": "Le trône de fer", "enemy": "vael", "rival": true, "size": 112, "credits": 3000, "ore": 3000,
			"ally_units": 4, "start_units": ["@0", "@0", "@1", "@1"], "outposts": 4,
			"objectives": [{"type": "outposts"}, {"type": "kills", "count": 40}, {"type": "upgrade", "id": "chantier", "level": 3},
					{"type": "power", "amount": 400}, {"type": "train", "count": 20}],
			"ai": {"slowdown": 1.2, "grace": 300.0, "pause": 50.0, "max_army": 20, "wave": 6, "credits": 2600, "ore": 2800},
			"third_ai": {"slowdown": 1.4, "grace": 360.0, "pause": 60.0, "max_army": 16, "wave": 6, "credits": 2200, "ore": 2400},
			"obj": "Rasez les 4 avant-postes du trône, détruisez 40 unités, Chantier niveau 3, 400 d'énergie, 20 unités",
			"brief": "Le trône de fer est au centre du monde et {ENEMY} comme {RIVAL} le veulent. Montez votre empire : chantier au sommet, énergie en abondance, une armée nombreuse, puis rasez les avant-postes qui gardent ses abords. Les victimes feront taire les prétendants.",
		},
	],
	# --- Cartel Vael : vitesse, ruse, commerce ---
	"vael": [
		{
			"id": "contrebande", "title": "Contrebande", "enemy": "kharn", "size": 80, "credits": 1500, "ore": 1800,
			"objectives": [{"type": "build", "label": "la base", "ids": BASE}, {"type": "harvest", "amount": 4000}],
			"ai": {"slowdown": 2.4, "grace": 900.0, "pause": 120.0, "max_army": 6, "wave": 4, "credits": 1000, "ore": 1200},
			"obj": "Bâtissez la base et récoltez 4000 Solaris",
			"brief": "Le Cartel ouvre un comptoir clandestin. Posez la base, lancez la récolte et amassez des Solaris : l'argent est la première arme. {ENEMY} n'est pas encore au courant.",
		},
		{
			"id": "coup", "title": "Le coup de main", "enemy": "solis", "size": 96, "credits": 1800, "ore": 2000,
			"start_units": ["@0", "@1"],
			"convoy": {"count": 5, "need": 4, "ambushes": 2, "start": 300.0, "ambush_size": 2},
			"objectives": [{"type": "escort"}, {"type": "train", "count": 4}],
			"ai": {"slowdown": 2.0, "grace": 480.0, "pause": 80.0, "max_army": 8, "wave": 4, "credits": 1200, "ore": 1500},
			"obj": "Évacuez 4 camions sur 5 par le point d'évacuation",
			"brief": "Nos camions de marchandises doivent traverser le territoire de {ENEMY} et quitter la carte par le point d'évacuation avant que ses patrouilles ne réagissent. Le départ est rapide, vos éclaireurs doivent l'être aussi.",
		},
		{
			"id": "filature", "title": "La filature", "enemy": "solis", "size": 96, "credits": 1800, "ore": 2000,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "train", "count": 6}, {"type": "kills", "count": 8}, {"type": "harvest", "amount": 3000}],
			"obj": "Formez 6 unités, abattez 8 éclaireurs et récoltez 3000 Solaris",
			"brief": "Les éclaireurs de {ENEMY} suivent nos caravanes de trop près. Montez des patrouilles rapides, abattez-les sans bruit et faites tourner le commerce pendant ce temps.",
		},
		{
			"id": "double", "title": "Double jeu", "enemy": "kharn", "rival": true, "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "ally_units": 2,
			"objectives": [{"type": "waves", "count": 2}, {"type": "kills", "count": 12}],
			"ai": {"slowdown": 1.4, "grace": 240.0, "pause": 50.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Repoussez 2 assauts et abattez 12 unités ennemies",
			"brief": "{ENEMY} et {RIVAL} se disputent le même territoire et chacun veut notre peau. Repoussez leurs assauts sans leur laisser le désert, puis frappez le camp qui s'expose.",
		},
		{
			"id": "pillage", "title": "Pillage aérien", "enemy": "kharn", "size": 112, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "build", "label": "la base aérienne", "ids": {"usine": 1, "aerodrome": 1}}, {"type": "air", "count": 4}, {"type": "kills", "count": 12}],
			"obj": "Bâtissez un aérodrome, alignez 4 appareils et abattez 12 unités ennemies",
			"brief": "Les colonnes lourdes de {ENEMY} ne regardent jamais en l'air. Construisez un aérodrome, formez une escadre légère et pillez leurs convois avant qu'ils ne comprennent.",
		},
		{
			"id": "entrepots", "title": "Les entrepôts", "rival": true, "enemy": "solis", "size": 112, "outposts": 4, "credits": 2000, "ore": 2200,
			"ally_units": 2, "start_units": ["@0", "@0", "@1"],
			"objectives": [{"type": "outposts"}, {"type": "harvest", "amount": 3000}, {"type": "train", "count": 6}],
			"ai": {"slowdown": 1.7, "grace": 360.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1500, "ore": 1800},
			"third_ai": {"slowdown": 1.5, "grace": 420.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Pillez les 4 entrepôts, récoltez 3000 Solaris et formez 6 unités",
			"brief": "{ENEMY} stocke ses réserves dans quatre entrepôts fortifiés, et {RIVAL} lorgne dessus aussi. Frappez vite, remplissez les caisses du Cartel et armez-vous contre les deux.",
		},
		{
			"id": "braquage", "title": "Le grand braquage", "enemy": "solis", "rival": true, "size": 112, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@0", "@1", "@1"], "ally_units": 3,
			"outposts": 3,
			"objectives": [{"type": "outposts"}, {"type": "kills", "count": 25}, {"type": "harvest", "amount": 4000}],
			"ai": {"slowdown": 1.15, "grace": 360.0, "pause": 50.0, "max_army": 22, "wave": 6, "credits": 2500, "ore": 2800},
			"third_ai": {"slowdown": 1.5, "grace": 420.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Rasez 3 avant-postes, amassez 4000 Solaris et abattez 25 unités ennemies",
			"brief": "Le coup du siècle : le coffre central de {ENEMY} intéresse aussi {RIVAL}. Prenez-le avant les autres, remplissez les caisses et abattez ceux qui vous barrent la route.",
		},
		{
			"id": "caravane", "title": "La grande caravane", "enemy": "kharn", "size": 112, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@1"],
			"convoy": {"count": 6, "need": 5, "ambushes": 3, "start": 360.0, "ambush_size": 3},
			"objectives": [{"type": "escort"}, {"type": "train", "count": 8}],
			"obj": "Escortez la caravane : 5 camions sur 6 doivent être évacués",
			"brief": "Six camions chargés d'épice doivent traverser le désert jusqu'au point d'évacuation. {ENEMY} a posté des embuscades sur le parcours : sécurisez la route, la caravane ne peut en perdre qu'un.",
		},
		{
			"id": "marche", "title": "Le marché noir", "enemy": "conclave", "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "worm_rate": 2.0,
			"objectives": [{"type": "harvest", "amount": 6000}, {"type": "ore", "amount": 3000},
					{"type": "build", "label": "les entrepôts", "ids": {"silo": 2, "silo_minerai": 2}}],
			"ai": {"slowdown": 1.9, "grace": 420.0, "pause": 70.0, "max_army": 10, "wave": 5, "credits": 1500, "ore": 1800},
			"obj": "Récoltez 6000 Solaris et 3000 minerai, bâtissez 2 silos d'épice et 2 silos de minerai",
			"brief": "Le Cartel ouvre son plus gros marché clandestin : il faut de l'épice, du minerai et des entrepôts pour tout stocker. Les vers sont nerveux, les récolteurs doivent l'être aussi. {ENEMY} n'y verra que du feu.",
		},
		{
			"id": "mirage", "title": "Mirage", "enemy": "solis", "size": 96, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@0", "@1"], "zone": {"time": 210.0, "units": 5},
			"objectives": [{"type": "hold"}, {"type": "kills", "count": 15}],
			"obj": "Tenez la zone centrale avec 5 unités et abattez 15 unités ennemies",
			"brief": "Un mirage se dresse au-dessus de l'oasis : la zone est à qui saura la tenir. Gardez-la avec votre troupe la plus mobile et faites tomber les colonnes de {ENEMY} un à un.",
		},
		{
			"id": "primes", "title": "Chasseurs de primes", "enemy": "kharn", "size": 96, "credits": 2500, "ore": 2500,
			"start_units": ["faucon", "faucon", "vipere", "vipere"], "time_limit": 840.0,
			"objectives": [{"type": "kills", "count": 30}, {"type": "train", "count": 10}, {"type": "harvest", "amount": 2000}],
			"ai": {"slowdown": 1.4, "grace": 200.0, "pause": 45.0, "max_army": 16, "wave": 6, "credits": 2000, "ore": 2200},
			"obj": "Détruisez 30 unités ennemies en 14 minutes, formez 10 unités et récoltez 2000 Solaris",
			"brief": "{ENEMY} a mis sa tête à prix, et nous touchons à chaque blindé abattu. Un maximum de victimes dans le temps imparti : harcelez, repliez-vous, recommencez. Quelques Solaris au passage ne feront pas de mal.",
		},
		{
			"id": "epice_noire", "title": "L'épice noire", "enemy": "conclave", "size": 96, "credits": 2500, "ore": 2500,
			"start_units": ["recolteur", "recolteur", "@0", "@1"], "worm_rate": 3.0, "worm_hp": 4000.0, "worm_grace": 60.0,
			"objectives": [{"type": "harvest", "amount": 6000}, {"type": "worms", "count": 2}],
			"obj": "Récoltez 6000 Solaris et abattez 2 vers géants",
			"brief": "Une veine d'épice noire a été repérée au cœur des dunes, mais les vers la gardent. {ENEMY} la veut aussi : récoltez vite, fuyez à temps, terrassez deux de ces gardiens et ne laissez rien aux Obsidiens.",
		},
		{
			"id": "fragile", "title": "Route assiégée", "enemy": "solis", "rival": true, "size": 112, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@1"], "ally_units": 3,
			"convoy": {"count": 5, "need": 4, "ambushes": 3, "start": 360.0, "ambush_size": 3},
			"objectives": [{"type": "escort"}, {"type": "kills", "count": 10}, {"type": "upgrade", "id": "raffinerie", "level": 2}],
			"ai": {"slowdown": 1.5, "grace": 360.0, "pause": 70.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Escortez 4 camions sur 5, abattez 10 unités ennemies et passez la raffinerie au niveau 2",
			"brief": "{ENEMY} a tendu ses embuscades sur la route et {RIVAL} attend que nous trébuchions. Escortez les camions jusqu'au point d'évacuation, repoussez les deux camps et prouvez le savoir-faire du Cartel en modernisant la raffinerie.",
		},
		{
			"id": "sabotage", "title": "Sabotage", "enemy": "solis", "enemy_base": true, "size": 96, "credits": 3000, "ore": 3000,
			"start_units": ["@0", "@0", "@1", "@1", "@2", "@4"], "time_limit": 900.0,
			"objectives": [{"type": "destroy_type", "id": "centrale", "count": 2}, {"type": "destroy_type", "id": "raffinerie", "count": 1}],
			"obj": "Détruisez 2 centrales et une raffinerie ennemies en 15 minutes",
			"brief": "{ENEMY} fortifie sa base : ses centrales sont son point faible. Frappez vite, avec vos saboteurs en tête, puis disparaissez avant qu'elle ne réagisse.",
		},
		{
			"id": "troisgrands", "title": "Guerre des trois", "enemy": "kharn", "rival": true, "size": 112, "credits": 3000, "ore": 3000,
			"ally_units": 3, "start_units": ["@0", "@0", "@1", "@2"],
			"objectives": [{"type": "destroy_type", "id": "chantier", "count": 2}, {"type": "waves", "count": 4},
					{"type": "harvest", "amount": 3500}, {"type": "kills", "count": 20}],
			"ai": {"slowdown": 1.6, "grace": 300.0, "pause": 60.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"third_ai": {"slowdown": 1.7, "grace": 360.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1700, "ore": 1900},
			"obj": "Détruisez les deux chantiers ennemis, repoussez 4 assauts, récoltez 3500 Solaris et abattez 20 unités",
			"brief": "{ENEMY} et {RIVAL} se détestent : laissez-les s'user. Repoussez leurs assauts, remplissez les caisses et frappez l'instant venu : il faut décapiter les deux camps en détruisant leurs chantiers.",
		},
		{
			"id": "razzia", "title": "La grande razzia", "enemy": "kharn", "rival": true, "size": 112, "credits": 3500, "ore": 3500,
			"start_units": ["@0", "@0", "@1", "@1"], "ally_units": 2, "time_limit": 1200.0,
			"objectives": [{"type": "kills", "count": 40}, {"type": "train", "count": 14}, {"type": "harvest", "amount": 5000}],
			"obj": "Abattez 40 unités, formez 14 unités et récoltez 5000 Solaris en 20 minutes",
			"brief": "Les trois grandes maisons s'affrontent et le Cartel veut sa part du butin. {ENEMY} et {RIVAL} se détruisent entre eux : intervenez au bon moment, pillez, et repartez avec tout.",
		},
		{
			"id": "roi", "title": "Roi du désert", "enemy": "solis", "rival": true, "start_base": true, "enemy_base": true, "third_base": true,
			"size": 112, "credits": 3500, "ore": 3500, "time_limit": 1500.0,
			"ally_units": 4, "start_units": ["@0", "@0", "@1", "@2"],
			"objectives": [{"type": "harvest", "amount": 8000}, {"type": "destroy_all"}, {"type": "air", "count": 4},
					{"type": "upgrade", "id": "chantier", "level": 3}],
			"ai": {"slowdown": 1.2, "grace": 300.0, "pause": 50.0, "max_army": 22, "wave": 6, "credits": 2800, "ore": 3000},
			"third_ai": {"slowdown": 1.4, "grace": 360.0, "pause": 60.0, "max_army": 18, "wave": 6, "credits": 2400, "ore": 2600},
			"obj": "En 25 minutes : 8000 Solaris, Chantier niveau 3, 4 appareils et la destruction des trois camps",
			"brief": "Quatre bases, déjà bâties, une seule couronne. Le Cartel doit tout faire à la fois : remplir les caisses, moderniser, bâtir une flotte et effacer {ENEMY}, {RIVAL} et {FOURTH} avant que le temps ne s'écoule. Qui tient le désert tient le commerce.",
		},
	],
	# --- Conclave Obsidien : cristal, régénération, endurance ---
	"conclave": [
		{
			"id": "eclat", "title": "Premier éclat", "enemy": "kharn", "size": 80, "credits": 1500, "ore": 1800,
			"objectives": [{"type": "build", "label": "la base", "ids": BASE}, {"type": "ore", "amount": 3000}],
			"ai": {"slowdown": 2.4, "grace": 900.0, "pause": 120.0, "max_army": 6, "wave": 4, "credits": 1000, "ore": 1200},
			"obj": "Bâtissez la base et récoltez 3000 minerai",
			"brief": "Le Conclave s'éveille autour d'un filon de cristal. Posez la base, lancez l'extraction et amassez du minerai : le cristal est la première arme. {ENEMY} n'a pas encore repéré la veine.",
		},
		{
			"id": "geode", "title": "La géode", "enemy": "solis", "size": 96, "credits": 1800, "ore": 2000,
			"start_units": ["@0", "@1"],
			"convoy": {"count": 5, "need": 4, "ambushes": 2, "start": 300.0, "ambush_size": 2},
			"objectives": [{"type": "escort"}, {"type": "train", "count": 4}],
			"ai": {"slowdown": 2.0, "grace": 480.0, "pause": 80.0, "max_army": 8, "wave": 4, "credits": 1200, "ore": 1500},
			"obj": "Évacuez 4 camions sur 5 par le point d'évacuation",
			"brief": "Cinq chariots chargés de cristaux bruts doivent traverser les terres de {ENEMY} et quitter la carte par le point d'évacuation. Escortez-les : un éclat perdu se pleure, deux seraient une faute.",
		},
		{
			"id": "veine", "title": "La veine de cristal", "enemy": "kharn", "size": 96, "credits": 1800, "ore": 2000,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "ore", "amount": 3500}, {"type": "train", "count": 5}],
			"obj": "Récoltez 3500 minerai et formez 5 unités",
			"brief": "Une veine de cristal affleure sous la plaine. Posez vos foreuses, formez une garde pour les protéger et gardez à l'œil les pillards de {ENEMY}.",
		},
		{
			"id": "eclats", "title": "Éclats croisés", "enemy": "kharn", "rival": true, "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "ally_units": 2,
			"objectives": [{"type": "waves", "count": 2}, {"type": "kills", "count": 12}],
			"ai": {"slowdown": 1.4, "grace": 240.0, "pause": 50.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Repoussez 2 assauts et abattez 12 unités ennemies",
			"brief": "{ENEMY} et {RIVAL} se disputent la même vallée et chacun veut briser notre cristal. Repoussez leurs assauts, laissez-les s'user et frappez le camp qui s'expose.",
		},
		{
			"id": "sanctuaire", "title": "Le sanctuaire", "enemy": "vael", "size": 96, "credits": 2200, "ore": 2400,
			"start_units": ["@0", "@0", "@1"], "zone": {"time": 210.0, "units": 5},
			"objectives": [{"type": "hold"}, {"type": "train", "count": 6}],
			"obj": "Tenez la zone centrale avec 5 unités et formez 6 unités",
			"brief": "Le sanctuaire obsidien est menacé : {ENEMY} veut le profaner. Occupez ses abords avec une troupe régénérante et ne cédez pas un pouce.",
		},
		{
			"id": "fissure", "title": "La fissure", "rival": true, "enemy": "solis", "size": 112, "outposts": 4, "credits": 2000, "ore": 2200,
			"ally_units": 2, "start_units": ["@0", "@0", "@1"],
			"objectives": [{"type": "outposts"}, {"type": "harvest", "amount": 3000}, {"type": "train", "count": 6}],
			"ai": {"slowdown": 1.7, "grace": 360.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1500, "ore": 1800},
			"third_ai": {"slowdown": 1.5, "grace": 420.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Pillez les 4 entrepôts, récoltez 3000 Solaris et formez 6 unités",
			"brief": "Quatre postes gardent les galeries de {ENEMY}, et {RIVAL} s'y intéresse aussi. Rasez-les avant les autres, remplissez nos réserves et armez le Conclave contre les deux.",
		},
		{
			"id": "prisme", "title": "Le prisme", "enemy": "solis", "size": 96, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "build", "label": "la base aérienne", "ids": {"usine": 1, "aerodrome": 1}}, {"type": "air", "count": 3}, {"type": "kills", "count": 12}],
			"obj": "Bâtissez un aérodrome, alignez 3 appareils et abattez 12 unités ennemies",
			"brief": "Le prisme du Conclave capte la lumière et ouvre la voie aux appareils obsidiens. Formez une escadre et éprouvez-la sur les colonnes de {ENEMY}.",
		},
		{
			"id": "resonance", "title": "Résonance", "enemy": "vael", "rival": true, "size": 112, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@0", "@1", "@1"], "ally_units": 3,
			"outposts": 3,
			"objectives": [{"type": "outposts"}, {"type": "kills", "count": 25}, {"type": "harvest", "amount": 4000}],
			"ai": {"slowdown": 1.15, "grace": 360.0, "pause": 50.0, "max_army": 22, "wave": 6, "credits": 2500, "ore": 2800},
			"third_ai": {"slowdown": 1.5, "grace": 420.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Rasez 3 avant-postes, amassez 4000 Solaris et abattez 25 unités ennemies",
			"brief": "Le grand cristal de {ENEMY} chante : {RIVAL} l'entend aussi. Prenez les postes qui l'entourent, abattez ceux qui s'approchent et faites sonner nos coffres.",
		},
		{
			"id": "geysers", "title": "Les geysers", "enemy": "vael", "size": 96, "credits": 2200, "ore": 2400,
			"start_units": ["recolteur", "recolteur", "@0", "@1"], "worm_rate": 3.0, "worm_hp": 4000.0, "worm_grace": 60.0,
			"objectives": [{"type": "harvest", "amount": 4000}, {"type": "worms", "count": 1}],
			"obj": "Récoltez 4000 Solaris et abattez un ver géant",
			"brief": "Des geysers d'épice ont percé près du campement, et les vers affluent. Récoltez entre deux éruptions et gardez une escorte régénérante pour vos engins et abattez l'un de ces vers.",
		},
		{
			"id": "serres", "title": "Les serres", "enemy": "kharn", "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "worm_rate": 2.0,
			"objectives": [{"type": "ore", "amount": 5000}, {"type": "harvest", "amount": 3000},
					{"type": "build", "label": "les serres", "ids": {"serre": 2}}],
			"ai": {"slowdown": 1.9, "grace": 420.0, "pause": 70.0, "max_army": 10, "wave": 5, "credits": 1500, "ore": 1800},
			"obj": "Récoltez 5000 minerai et 3000 Solaris, bâtissez 2 serres cristallines",
			"brief": "Le Conclave fait pousser son minerai : il faut des serres cristallines, de l'extraction et des Solaris pour tout financer. Les vers rôdent, les mineurs doivent être prudents. {ENEMY} observe de loin.",
		},
		{
			"id": "gardiens", "title": "Les gardiens", "enemy": "solis", "size": 112, "outposts": 3, "credits": 2800, "ore": 2800,
			"start_units": ["@0", "@0", "@1", "@1"],
			"objectives": [{"type": "outposts"}, {"type": "kills", "count": 25}],
			"obj": "Rasez 3 avant-postes et abattez 25 unités ennemies",
			"brief": "Trois avant-postes de {ENEMY} bloquent la route des cristaux. Leurs gardiens sont solides : avancez en formation, régénérez entre deux assauts et rasez-les.",
		},
		{
			"id": "chasse", "title": "La chasse obsidienne", "enemy": "solis", "size": 96, "credits": 2500, "ore": 2500,
			"start_units": ["ombre", "ombre", "prisme", "prisme"], "time_limit": 840.0,
			"objectives": [{"type": "kills", "count": 30}, {"type": "train", "count": 10}, {"type": "harvest", "amount": 2000}],
			"ai": {"slowdown": 1.4, "grace": 200.0, "pause": 45.0, "max_army": 16, "wave": 6, "credits": 2000, "ore": 2200},
			"obj": "Détruisez 30 unités ennemies en 14 minutes, formez 10 unités et récoltez 2000 Solaris",
			"brief": "{ENEMY} a pris nos veilleurs en chasse. Harcelez, régénérez-vous à couvert et frappez de nouveau : chaque ennemi abattu nourrit le cristal. Quelques Solaris au passage ne nuiront pas.",
		},
		{
			"id": "monolithes", "title": "La ligne des monolithes", "enemy": "kharn", "size": 112, "credits": 3000, "ore": 3000,
			"start_units": ["@0", "@0", "@1"],
			"objectives": [{"type": "build", "label": "la ligne", "ids": {"tourelle": 4, "tour_geode": 2}}, {"type": "waves", "count": 3}, {"type": "kills", "count": 20}],
			"obj": "Bâtissez 4 tourelles et 2 tours géodes, repoussez 3 assauts et abattez 20 unités",
			"brief": "Les monolithes forment une ligne que rien ne doit franchir. Doublez-la de tourelles et de tours géodes : {ENEMY} y viendra mourir, et le Conclave regénérera pendant ce temps.",
		},
		{
			"id": "faille", "title": "La faille", "enemy": "kharn", "rival": true, "size": 112, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@1"], "ally_units": 3,
			"convoy": {"count": 5, "need": 4, "ambushes": 3, "start": 360.0, "ambush_size": 3},
			"objectives": [{"type": "escort"}, {"type": "kills", "count": 10}, {"type": "upgrade", "id": "raffinerie", "level": 2}],
			"ai": {"slowdown": 1.5, "grace": 360.0, "pause": 70.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Escortez 4 camions sur 5, abattez 10 unités ennemies et passez la raffinerie au niveau 2",
			"brief": "{ENEMY} a tendu ses embuscades sur la route de la faille et {RIVAL} attend notre faux pas. Escortez les chariots, repoussez les deux camps et modernisez la raffinerie.",
		},
		{
			"id": "eclipse", "title": "Éclipse", "enemy": "solis", "enemy_base": true, "size": 112, "credits": 3500, "ore": 3500,
			"start_units": ["@0", "@0", "@1", "@1", "@2"], "time_limit": 1200.0,
			"objectives": [{"type": "destroy_type", "id": "chantier", "count": 1}, {"type": "destroy_type", "id": "centrale", "count": 1}, {"type": "kills", "count": 20}],
			"obj": "Détruisez le chantier et la centrale ennemis et abattez 20 unités en 20 minutes",
			"brief": "Une éclipse approche : le soleil de {ENEMY} va s'éteindre. Brisez sa base pendant qu'elle est aveugle, chantier et centrale d'abord.",
		},
		{
			"id": "triade", "title": "La triade", "enemy": "vael", "rival": true, "size": 112, "credits": 3000, "ore": 3000,
			"ally_units": 3, "start_units": ["@0", "@0", "@1", "@2"],
			"objectives": [{"type": "destroy_type", "id": "chantier", "count": 2}, {"type": "waves", "count": 4},
					{"type": "harvest", "amount": 3500}, {"type": "kills", "count": 20}],
			"ai": {"slowdown": 1.6, "grace": 300.0, "pause": 60.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"third_ai": {"slowdown": 1.7, "grace": 360.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1700, "ore": 1900},
			"obj": "Détruisez les deux chantiers ennemis, repoussez 4 assauts, récoltez 3500 Solaris et abattez 20 unités",
			"brief": "{ENEMY} et {RIVAL} se haïssent : laissez-les se déchirer. Repoussez leurs assauts, bâtissez vos réserves puis décapitez les deux camps en brisant leurs chantiers.",
		},
		{
			"id": "dernier_cristal", "title": "Le dernier cristal", "enemy": "kharn", "rival": true, "size": 112, "credits": 3500, "ore": 3500,
			"start_units": ["@0", "@0", "@1", "@1"], "ally_units": 2,
			"objectives": [{"type": "waves", "count": 4}, {"type": "kills", "count": 35}, {"type": "ore", "amount": 5000}],
			"obj": "Repoussez 4 assauts, abattez 35 unités et récoltez 5000 minerai",
			"brief": "Le dernier cristal de la plaine attire toutes les convoitises. {ENEMY} et {RIVAL} s'y entretuent : tenez-vous au centre, régénérez et récoltez avant de leur porter le coup de grâce.",
		},
		{
			"id": "obsidienne", "title": "Le trône d'obsidienne", "enemy": "kharn", "rival": true, "start_base": true, "enemy_base": true, "third_base": true,
			"size": 112, "credits": 3500, "ore": 3500, "time_limit": 1500.0,
			"ally_units": 4, "start_units": ["@0", "@0", "@1", "@2"],
			"objectives": [{"type": "harvest", "amount": 8000}, {"type": "destroy_all"}, {"type": "air", "count": 4},
					{"type": "upgrade", "id": "chantier", "level": 3}],
			"ai": {"slowdown": 1.2, "grace": 300.0, "pause": 50.0, "max_army": 22, "wave": 6, "credits": 2800, "ore": 3000},
			"third_ai": {"slowdown": 1.4, "grace": 360.0, "pause": 60.0, "max_army": 18, "wave": 6, "credits": 2400, "ore": 2600},
			"obj": "En 25 minutes : 8000 Solaris, Chantier niveau 3, 4 appareils et la destruction des trois camps",
			"brief": "Quatre bases, déjà bâties, un seul trône de verre noir. Le Conclave doit tout faire à la fois : remplir ses réserves, moderniser, bâtir une flotte et effacer {ENEMY}, {RIVAL} et {FOURTH} avant que le temps ne s'écoule.",
		},
	],
}

const FLAVOR := {
	"solis": "La Maison Solis mise sur la technologie et la précision.",
	"kharn": "La Légion Kharn mise sur la puissance brute et le blindage.",
	"vael": "Le Cartel Vael mise sur la vitesse et la ruse.",
	"conclave": "Le Conclave Obsidien mise sur le cristal, la régénération et l'endurance.",
}


static func missions(faction: String) -> Array:
	_ensure()
	return _scaled[faction]


static func mission(faction: String, m: int) -> Dictionary:
	_ensure()
	return _scaled[faction][m]


static func count(faction := "solis") -> int:
	return CAMPAIGNS[faction].size()


static func title_of(faction: String, m: int) -> String:
	return mission(faction, m)["title"]


static func enemy_of(faction: String, m: int) -> String:
	return mission(faction, m)["enemy"]


# --- Courbe de difficulté : de la mission 1 (tranquille) à la mission 10 (épreuve finale) ---

## IA de l'adversaire par niveau de mission (0..9) : lenteur de construction, délai du premier
## assaut, répit entre vagues, taille de l'armée et des vagues, réserves de départ.
const AI_CURVE := [
	{"slowdown": 2.4, "grace": 900.0, "pause": 120.0, "max_army": 6, "wave": 4, "credits": 1000, "ore": 1200},
	{"slowdown": 2.1, "grace": 600.0, "pause": 100.0, "max_army": 8, "wave": 4, "credits": 1200, "ore": 1500},
	{"slowdown": 1.8, "grace": 480.0, "pause": 85.0, "max_army": 11, "wave": 5, "credits": 1500, "ore": 1800},
	{"slowdown": 1.6, "grace": 420.0, "pause": 75.0, "max_army": 14, "wave": 6, "credits": 1800, "ore": 2000},
	{"slowdown": 1.4, "grace": 360.0, "pause": 65.0, "max_army": 18, "wave": 7, "credits": 2200, "ore": 2400},
	{"slowdown": 1.25, "grace": 300.0, "pause": 55.0, "max_army": 23, "wave": 9, "credits": 2800, "ore": 3000},
	{"slowdown": 1.12, "grace": 240.0, "pause": 45.0, "max_army": 29, "wave": 11, "credits": 3500, "ore": 3800},
	{"slowdown": 1.0, "grace": 200.0, "pause": 38.0, "max_army": 36, "wave": 13, "credits": 4500, "ore": 4800},
	{"slowdown": 0.9, "grace": 160.0, "pause": 30.0, "max_army": 44, "wave": 16, "credits": 6000, "ore": 6000},
	{"slowdown": 0.8, "grace": 120.0, "pause": 22.0, "max_army": 55, "wave": 20, "credits": 8000, "ore": 8000},
]

static var _scaled := {}


## Courbe d'IA interpolée pour une progression g (0..1) dans la campagne, quelle que soit sa longueur.
static func _curve(g: float) -> Dictionary:
	var p := clampf(g, 0.0, 1.0) * float(AI_CURVE.size() - 1)
	var i0 := int(floor(p))
	var i1 := mini(i0 + 1, AI_CURVE.size() - 1)
	var t := p - float(i0)
	var out := {}
	for k in AI_CURVE[0]:
		var v = lerpf(float(AI_CURVE[i0][k]), float(AI_CURVE[i1][k]), t)
		out[k] = int(round(v)) if (AI_CURVE[0][k] is int) else v
	return out


## Palier technologique atteint en jouant la mission m (0 = première) : les 4 paliers de
## bâtiments (« unlock » 1 à 4) se débloquent progressivement, quelle que soit la longueur.
static func tier_of(faction: String, m: int) -> int:
	return int(round(float(m) * 9.0 / float(count(faction) - 1)))


## Palier minimal pour que tous les bâtiments exigés par les objectifs (et leurs prérequis) soient bâtissables.
static func needed_tier(faction: String, m: int) -> int:
	var t := tier_of(faction, m)
	for o in mission(faction, m)["objectives"]:
		var ids: Array = []
		if o["type"] == "build":
			ids = o["ids"].keys()
		elif o["type"] == "upgrade":
			ids = [o["id"]]
		elif o["type"] == "air":
			ids = ["aerodrome"]
		for id in ids:
			t = maxi(t, _chain_tier(String(id)))
	return t


static func _chain_tier(id: String) -> int:
	if not GameData.BUILDINGS.has(id):
		return 0
	var d: Dictionary = GameData.BUILDINGS[id]
	var t := int(d.get("unlock", 0))
	for r in d["requires"]:
		t = maxi(t, _chain_tier(String(r)))
	return t


## Numéro (1 = après la première mission terminée) de la mission après laquelle un
## bâtiment d'« unlock » donné devient disponible.
static func mission_for_unlock(faction: String, unlock: int) -> int:
	for m in count(faction):
		if tier_of(faction, m) >= unlock:
			return maxi(m, 1)
	return count(faction) - 1


static func _ensure() -> void:
	if not _scaled.is_empty():
		return
	for f in CAMPAIGNS:
		var arr: Array = []
		for i in CAMPAIGNS[f].size():
			arr.append(_scale(f, i, CAMPAIGNS[f][i].duplicate(true)))
		_scaled[f] = arr


## Applique la difficulté du niveau i à une mission : IA, objectifs plus longs, délais, embuscades.
static func _scale(faction: String, i: int, d: Dictionary) -> Dictionary:
	var n: int = CAMPAIGNS[faction].size()
	var g := float(i) / float(n - 1)
	d["ai"] = _curve(g)
	var a: Dictionary = d["ai"]
	a["skill"] = clampf(0.15 + 0.85 * g, 0.0, 1.0) # finesse de jeu de l'IA : de simple à redoutable
	# Second adversaire : même courbe, en un peu plus faible
	d["third_ai"] = {"slowdown": float(a["slowdown"]) * 1.3, "grace": float(a["grace"]) * 1.3, "pause": float(a["pause"]) * 1.3,
			"max_army": int(int(a["max_army"]) * 0.6), "wave": maxi(int(int(a["wave"]) * 0.7), 3),
			"credits": int(int(a["credits"]) * 0.7), "ore": int(int(a["ore"]) * 0.7), "skill": float(a["skill"]) * 0.8}
	# Les dernières missions : adversaire déjà installé, et la finale oppose trois camps
	if i >= n - 3:
		d["enemy_base"] = true
	if i == n - 1:
		d["rival"] = true
		if d.get("rival", false):
			d["third_base"] = true
			d["quad"] = true # la finale oppose quatre camps : le joueur et trois adversaires
			d["fourth_base"] = true
	# Objectifs plus longs et plus exigeants avec le niveau (jusqu'à plusieurs fois la durée de base)
	for o in d["objectives"]:
		match o["type"]:
			"harvest", "ore", "power":
				o["amount"] = _round_to(float(o["amount"]) * (1.0 + 1.5 * g), 100)
			"survive":
				o["time"] = _round_to(float(o["time"]) * (1.0 + 1.8 * g), 30)
			"train", "air", "kills", "waves":
				o["count"] = maxi(int(round(float(o["count"]) * (1.0 + 1.2 * g))), int(o["count"]))
	if d.has("zone"):
		d["zone"]["time"] = _round_to(float(d["zone"]["time"]) * (1.0 + 1.0 * g), 15)
		d["zone"]["units"] = int(round(float(d["zone"]["units"]) * (1.0 + 0.6 * g)))
	if d.has("time_limit"):
		d["time_limit"] = _round_to(float(d["time_limit"]) * (1.0 + 2.0 * g), 60)
	# Plafonds réalistes, d'après les rythmes mesurés au banc d'essai (tools/bench.gd) : environ 450 Solaris
	# et 220 minerai récoltés par minute, 1,5 unité ennemie produite par minute. `budget` = minutes qu'une
	# mission peut consacrer à un objectif (12 au début, 30 à la fin ; 60 % du temps imparti s'il y en a un).
	var budget := 12.0 + 18.0 * g
	if d.has("time_limit"):
		budget = minf(budget, float(d["time_limit"]) / 60.0 * 0.6)
	for o in d["objectives"]:
		match o["type"]:
			"harvest":
				o["amount"] = minf(float(o["amount"]), _round_to(450.0 * budget, 100))
			"ore":
				o["amount"] = minf(float(o["amount"]), _round_to(220.0 * budget, 100))
			"power":
				o["amount"] = minf(float(o["amount"]), 800.0)
			"kills":
				o["count"] = mini(int(o["count"]), int(1.5 * budget))
			"train":
				o["count"] = mini(int(o["count"]), int(1.0 * budget))
			"survive":
				o["time"] = minf(float(o["time"]), _round_to(60.0 * (10.0 + 15.0 * g), 30))
			"waves":
				o["count"] = mini(int(o["count"]), maxi(2, int((10.0 + 15.0 * g) / 3.0)))
			"worms":
				o["count"] = mini(int(o["count"]), 3) # il n'existe que trois vers
	if d.has("convoy"):
		d["convoy"]["ambushes"] = int(d["convoy"]["ambushes"]) + int(g * 3.0)
		d["convoy"]["ambush_size"] = int(d["convoy"]["ambush_size"]) + int(g * 3.0)
	d["obj"] = _obj_short(d, faction)
	return d


## Résumé court des objectifs (cartes de mission, guide).
static func _obj_short(d: Dictionary, faction: String) -> String:
	var parts: PackedStringArray = []
	for o in d["objectives"]:
		match o["type"]:
			"build":
				var names: PackedStringArray = []
				for id in o["ids"]:
					names.append("%s ×%d" % [GameData.name_of(id, faction).to_lower(), int(o["ids"][id])])
				parts.append("bâtir " + ", ".join(names))
			"harvest": parts.append("récolter %d Solaris" % int(o["amount"]))
			"train": parts.append("former %d unités" % int(o["count"]))
			"survive": parts.append("tenir %s" % _mins(float(o["time"])))
			"waves": parts.append("repousser %d assauts" % int(o["count"]))
			"worms": parts.append("abattre " + _worms_txt(int(o["count"])))
			"escort": parts.append("escorter le convoi")
			"outposts": parts.append("raser les avant-postes")
			"hold": parts.append("tenir la zone %s" % _mins(float(d["zone"]["time"])))
			"destroy_all": parts.append("détruire tous les adversaires" if d.get("rival", false) else "détruire l'adversaire")
			"upgrade": parts.append("améliorer %s au niveau %d" % [GameData.name_of(o["id"], faction).to_lower(), int(o["level"])])
			"kills": parts.append("%d victimes" % int(o["count"]))
			"destroy_type": parts.append("détruire %s ×%d" % [foe_building_names(o["id"], d, faction).to_lower(), int(o["count"])])
			"ore": parts.append("récolter %d minerai" % int(o["amount"]))
			"power": parts.append("produire %d d'énergie" % int(o["power"] if o.has("power") else o["amount"]))
			"air": parts.append("%d appareils volants" % int(o["count"]))
	var t := ", ".join(parts)
	if d.has("time_limit"):
		t += " — en %s" % _mins(float(d["time_limit"]))
	return t.substr(0, 1).to_upper() + t.substr(1)


static func _worms_txt(n: int) -> String:
	return "un ver géant" if n <= 1 else "%d vers géants" % n


static func _round_to(v: float, step: int) -> float:
	return float(int(round(v / float(step))) * step)


## Niveau de difficulté affiché (1 à 10).
static func level_of(faction: String, m: int) -> int:
	return 1 + tier_of(faction, m)


## Troisième faction de la mission (second adversaire), "" s'il n'y en a pas.
static func third_of(faction: String, m: int) -> String:
	var d: Dictionary = mission(faction, m)
	if not d.get("rival", false):
		return ""
	return _third(faction, d)


## Nom d'un bâtiment chez le ou les adversaires (leur nom à eux, pas celui de la faction du joueur).
static func foe_building_names(id: String, d: Dictionary, faction: String) -> String:
	var fs: Array = [d["enemy"]]
	if d.get("rival", false):
		fs.append(_third(faction, d))
	var names: Array = []
	for f in fs:
		var n: String = GameData.name_of(id, f)
		if not names.has(n):
			names.append(n)
	return " / ".join(PackedStringArray(names))


static func _third(faction: String, d: Dictionary) -> String:
	for k in GameData.FACTIONS.keys():
		if k != faction and k != d["enemy"]:
			return k
	return ""


## Quatrième faction de la mission (troisième adversaire), "" s'il n'y en a pas.
static func fourth_of(faction: String, m: int) -> String:
	var d: Dictionary = mission(faction, m)
	if not d.get("quad", false):
		return ""
	for k in GameData.FACTIONS.keys():
		if k != faction and k != d["enemy"] and k != _third(faction, d):
			return k
	return ""


## Second adversaire (chacun pour soi) : la troisième faction est hostile à tous.
static func rival_of(faction: String, m: int) -> String:
	return third_of(faction, m) if mission(faction, m).get("rival", false) else ""


static func briefing(faction: String, m: int) -> String:
	var t: String = mission(faction, m)["brief"]
	var rival := rival_of(faction, m)
	var f4 := fourth_of(faction, m)
	# Camps supplémentaires non cités dans le briefing d'origine (finale à quatre camps)
	if rival != "" and not t.contains("{RIVAL}"):
		t += " {RIVAL} est aussi de la partie, hostile à tous."
	if f4 != "" and not t.contains("{FOURTH}"):
		t += " {FOURTH} entre aussi dans la mêlée : quatre camps, chacun pour soi."
	t = _put_faction(t, "{ENEMY}", enemy_of(faction, m))
	t = _put_faction(t, "{RIVAL}", rival)
	t = _put_faction(t, "{FOURTH}", f4)
	return FLAVOR[faction] + "\n\n" + _gnames(t, faction)


## Insère « la Légion Kharn » / « le Cartel Vael » à la place d'un repère, avec l'article et la contraction
## (du, au, de la, à la) qui conviennent au contexte, et la majuscule en début de phrase.
static func _put_faction(t: String, token: String, f: String) -> String:
	while t.contains(token):
		var i := t.find(token)
		var nm: String = GameData.FACTIONS[f]["name"] if f != "" else ""
		var fem: bool = FACTION_ART.get(f, "m") == "f"
		var before := t.substr(0, i)
		var after := t.substr(i + token.length())
		var art := "la " if fem else "le "
		if before.ends_with(" de ") or before == "de ":
			before = before.substr(0, before.length() - 3)
			art = "de la " if fem else "du "
			before += art
		elif before.ends_with(" à ") or before == "à ":
			before = before.substr(0, before.length() - 2)
			before += ("à la " if fem else "au ")
		else:
			var start := before.strip_edges() == "" or before.rstrip(" ").ends_with(".") or before.rstrip(" ").ends_with("!") or before.rstrip(" ").ends_with("?")
			before += (art.capitalize().substr(0, 1) + art.substr(1)) if start else art
		t = before + nm + after
	return t


## Genre et pluriel des noms de bâtiments de chaque faction (pour accorder articles et déterminants).
## id -> faction -> [genre, pluriel]. Un nom absent de cette table n'est pas réécrit.
const NOUNS := {
	"radar": {"solis": ["m", "centres de veille"], "kharn": ["m", "postes d'écoute"],
			"vael": ["f", "vigies nomades"], "conclave": ["m", "yeux de cristal"]},
	"tourelle": {"solis": ["f", "tourelles de garde"], "kharn": ["f", "casemates"],
			"vael": ["m", "postes d'embuscade"], "conclave": ["f", "sentinelles de cristal"]},
	"aerodrome": {"solis": ["m", "aérodromes"], "kharn": ["f", "pistes de guerre"],
			"vael": ["f", "pistes de fortune"], "conclave": ["f", "plateformes d'envol"]},
	"reacteur": {"solis": ["m", "réacteurs solaires"], "kharn": ["m", "réacteurs lourds"],
			"vael": ["m", "réacteurs de contrebande"], "conclave": ["m", "cœurs de cristal"]},
	"chantier": {"solis": ["m", "ateliers de conception"], "kharn": ["f", "forteresses de commandement"],
			"vael": ["m", "camps de base"], "conclave": ["m", "noyaux cristallins"]},
	"centrale": {"solis": ["f", "centrales solaires"], "kharn": ["f", "chaudières de guerre"],
			"vael": ["f", "dynamos du désert"], "conclave": ["f", "cuves d'énergie vive"]},
	"raffinerie": {"solis": ["f", "raffineries solaires"], "kharn": ["f", "raffineries lourdes"],
			"vael": ["m", "comptoirs de raffinage"], "conclave": ["m", "alambics de cristal"]},
	"usine": {"solis": ["f", "usines d'assemblage"], "kharn": ["m", "arsenaux"],
			"vael": ["m", "ateliers ambulants"], "conclave": ["f", "matrices de cristal"]},
	"fonderie": {"solis": ["f", "fonderies de précision"], "kharn": ["m", "hauts fourneaux"],
			"vael": ["f", "forges nomades"], "conclave": ["m", "creusets d'obsidienne"]},
}
const NOUN_RX := {"radar": "radars?", "tourelle": "tourelles?", "aerodrome": "a[ée]rodromes?", "reacteur": "r[ée]acteurs?",
		"chantier": "chantiers?", "centrale": "centrales?", "raffinerie": "raffineries?", "usine": "usines?", "fonderie": "fonderies?"}
## Faction -> [genre, nom] pour « la Légion Kharn », « le Cartel Vael »…
const FACTION_ART := {"solis": "f", "kharn": "f", "vael": "m", "conclave": "m"}


static func _starts_vowel(w: String) -> bool:
	var c := w.substr(0, 1).to_lower()
	return c in ["a", "e", "i", "o", "u", "y", "h", "é", "è", "ê", "œ", "â", "î", "ô", "û"]


## Mots courants du briefing (radar, tourelle…) -> nom du bâtiment de la faction, avec article et
## pluriel accordés, pour rester cohérent avec les objectifs en jeu.
static func _gnames(t: String, faction: String) -> String:
	for id in NOUN_RX:
		if not NOUNS[id].has(faction):
			continue
		var gender: String = NOUNS[id][faction][0]
		var plural_nm: String = NOUNS[id][faction][1]
		var sing_nm: String = GameData.name_of(id, faction).to_lower()
		var re := RegEx.create_from_string("(?i)(?<![\\wéèêàâîôûœ'-])(?:(un|une|le|la|l'|les|des|du|de la|de l'|d'|deux|trois|quatre|\\d+|vos|votre|ses|leurs?|son|sa|notre|nos|ce|cette)\\s?)?(" + String(NOUN_RX[id]) + ")(?![\\wéèêàâîôûœ-])")
		var out := ""
		var last := 0
		for mt in re.search_all(t):
			var det: String = mt.get_string(1)
			var word: String = mt.get_string(2).to_lower()
			var dl := det.to_lower()
			var plural := word.ends_with("s") or dl in ["les", "des", "deux", "trois", "quatre", "vos", "ses", "leurs", "nos"] or dl.is_valid_int()
			var nm := plural_nm if plural else sing_nm
			var vow := _starts_vowel(nm)
			var nd := det
			match dl:
				"un", "une":
					nd = "un" if gender == "m" else "une"
				"le", "la", "l'":
					nd = ("l'" if vow else ("le" if gender == "m" else "la")) if not plural else "les"
				"du", "de la", "de l'":
					nd = ("de l'" if vow else ("du" if gender == "m" else "de la")) if not plural else "des"
				"d'":
					nd = "d'" if vow else "de "
				"ce", "cette":
					nd = "ce" if gender == "m" else "cette"
				"son", "sa":
					nd = "son" if (gender == "m" or vow) else "sa"
			var sep := "" if (nd.ends_with("'") or nd.ends_with(" ") or nd == "") else " "
			var repl := nd + sep + nm
			if det != "" and det.substr(0, 1) == det.substr(0, 1).to_upper() and nd != "":
				repl = repl.substr(0, 1).to_upper() + repl.substr(1)
			elif det == "" and mt.get_string(2).substr(0, 1) == mt.get_string(2).substr(0, 1).to_upper():
				repl = repl.substr(0, 1).to_upper() + repl.substr(1)
			out += t.substr(last, mt.get_start() - last) + repl
			last = mt.get_end()
		t = out + t.substr(last)
	return t


static func _mins(s: float) -> String:
	var mn := int(s) / 60
	var sec := int(s) % 60
	if mn == 0:
		return "%d s" % sec
	return "%d min" % mn if sec == 0 else "%d min %02d s" % [mn, sec]


## Nombre d'adversaires (factions hostiles au joueur) d'une mission.
static func foe_count(faction: String, m: int) -> int:
	var n := 1
	if rival_of(faction, m) != "":
		n += 1
	if fourth_of(faction, m) != "":
		n += 1
	return n


## « Adversaire : X » ou « Adversaires (2) : X et Y » (toutes les factions hostiles présentes).
static func foes_text(faction: String, m: int) -> String:
	var e: String = GameData.FACTIONS[enemy_of(faction, m)]["name"]
	var r := rival_of(faction, m)
	if r == "":
		return "Adversaire : %s" % e
	var f4 := fourth_of(faction, m)
	if f4 != "":
		return "Adversaires (3) : %s, %s et %s" % [e, GameData.FACTIONS[r]["name"], GameData.FACTIONS[f4]["name"]]
	return "Adversaires (2) : %s et %s" % [e, GameData.FACTIONS[r]["name"]]


## Fiche détaillée d'une mission : liste de [titre, [lignes]].
static func objective_lines(faction: String, m: int, d: Dictionary) -> Array:
	var enemy: String = GameData.FACTIONS[d["enemy"]]["name"]
	var obj: Array = []
	for o in d["objectives"]:
		match o["type"]:
			"build":
				var parts: PackedStringArray = []
				for id in o["ids"]:
					parts.append("%s ×%d" % [GameData.name_of(id, faction), int(o["ids"][id])])
				obj.append("Construire : " + ", ".join(parts))
			"harvest":
				obj.append("Récolter %d Solaris au total" % int(o["amount"]))
			"train":
				obj.append("Produire %d unités de combat" % int(o["count"]))
			"survive":
				obj.append("Survivre %s" % _mins(float(o["time"])))
			"waves":
				obj.append("Repousser %d assauts ennemis (un assaut est repoussé quand l'armée adverse lancée contre vous est détruite ou battue en retraite)" % int(o["count"]))
			"worms":
				obj.append("Abattre %s (ils ne se montrent que sur les champs de récolte et gardent leurs blessures d'une apparition à l'autre)" % _worms_txt(int(o["count"])))
			"escort":
				var cv: Dictionary = d["convoy"]
				obj.append("Escorter le convoi (%d camions) jusqu'au point d'évacuation : %d doivent quitter la carte" % [int(cv["count"]), int(cv["need"])])
			"outposts":
				obj.append("Détruire les %d avant-postes ennemis" % int(d.get("outposts", 3)))
			"hold":
				var z: Dictionary = d["zone"]
				obj.append("Tenir la zone centrale avec %d unités pendant %s" % [int(z["units"]), _mins(float(z["time"]))])
			"destroy_all":
				if d.get("rival", false):
					obj.append("Détruire toutes les unités et structures de %s et de %s" % [enemy, GameData.FACTIONS[_third(faction, d)]["name"]])
				else:
					obj.append("Détruire toutes les unités et structures de %s" % enemy)
			"upgrade":
				obj.append("Améliorer : %s au niveau %d" % [GameData.name_of(o["id"], faction), int(o["level"])])
			"kills":
				obj.append("Détruire %d unités ennemies" % int(o["count"]))
			"destroy_type":
				obj.append("Détruire chez l'ennemi : %s ×%d" % [foe_building_names(o["id"], d, faction), int(o["count"])])
			"ore":
				obj.append("Récolter %d minerai au total" % int(o["amount"]))
			"power":
				obj.append("Produire %d d'énergie" % int(o["amount"]))
			"air":
				obj.append("Aligner %d appareils volants de combat" % int(o["count"]))
	return obj


static func details(faction: String, m: int) -> Array:
	var d: Dictionary = mission(faction, m)
	var fd: Dictionary = GameData.FACTIONS[faction]
	var enemy: String = GameData.FACTIONS[enemy_of(faction, m)]["name"]
	var out: Array = []
	# Objectifs
	var obj: Array = objective_lines(faction, m, d)
	if d.has("time_limit"):
		obj.append("Défaite : si les objectifs ne sont pas remplis en %s" % _mins(float(d["time_limit"])))
	obj.append("Défaite : perdre toute votre base et vos unités")
	out.append(["OBJECTIFS", obj])
	# Situation
	var sit: Array = []
	sit.append("Carte générée aléatoirement, %d × %d cases" % [int(d["size"]), int(d["size"])])
	if d.get("start_base", false):
		sit.append("Départ : %d Solaris, %d minerai, une base déjà bâtie (chantier, centrale, raffinerie, fonderie)" % [int(d["credits"]), int(d["ore"])])
	else:
		sit.append("Départ : %d Solaris, %d minerai, un engin de chantier à déployer" % [int(d["credits"]), int(d["ore"])])
	if d.get("enemy_base", false):
		sit.append("La base de l'adversaire est déjà bâtie et opérationnelle")
	if d.get("third_base", false):
		sit.append("Les bases des autres adversaires sont aussi déjà bâties" if d.get("quad", false) else "La base du second adversaire est aussi déjà bâtie")
	if d.has("worm_rate"):
		sit.append("Les vers de sable sont %d fois plus fréquents : surveillez vos récolteurs" % int(d["worm_rate"]))
	var su: Array = d.get("start_units", [])
	if not su.is_empty():
		var names: PackedStringArray = []
		for id in resolve_units(faction, su):
			names.append(GameData.name_of(id, faction))
		sit.append("Escorte de départ : " + ", ".join(names))
	sit.append(foes_text(faction, m))
	if rival_of(faction, m) != "":
		sit.append("Deux adversaires : toutes les factions présentes vous sont hostiles, et chacune attaque aussi l'autre (chacun pour soi)")
	if d.has("convoy"):
		sit.append("Le convoi part après %s : préparez votre escorte avant" % _mins(float(d["convoy"]["start"])))
		sit.append("%d embuscades ennemies (%d unités chacune) sur une route dégagée" % [int(d["convoy"]["ambushes"]), int(d["convoy"]["ambush_size"])])
	if d.has("outposts"):
		sit.append(_gnames("Chaque avant-poste est gardé par des tourelles et des patrouilles", faction))
	out.append(["SITUATION", sit])
	# Ennemi
	var ai: Dictionary = d["ai"]
	var foe: Array = []
	foe.append("Premier assaut après environ %s" % _mins(float(ai["grace"])))
	foe.append("Vagues de %d unités, répit d'environ %s entre deux" % [int(ai["wave"]), _mins(float(ai["pause"]))])
	foe.append("Armée maximale : %d unités" % int(ai["max_army"]))
	var sl := float(ai["slowdown"])
	foe.append("Rythme de construction : " + ("très lent" if sl >= 2.0 else "lent" if sl >= 1.6 else "soutenu" if sl >= 1.3 else "rapide"))
	out.append(["ENNEMI", foe])
	# Technologie
	var tech: Array = []
	var nb: PackedStringArray = []
	for id in GameData.buildings_for(faction):
		var bd: Dictionary = GameData.BUILDINGS[id]
		var ub := int(bd.get("unlock", 0))
		if m > 0 and ub > 0 and ub <= tier_of(faction, m) and ub > tier_of(faction, m - 1):
			nb.append(GameData.name_of(id, faction))
	if m > 0:
		tech.append("Nouveaux bâtiments : " + (", ".join(nb) if not nb.is_empty() else "aucun"))
	else:
		tech.append("Bâtiments : " + ", ".join(PackedStringArray(["centrale", "raffinerie", "fonderie", "usine", "tourelle"].map(func(i: String) -> String: return GameData.name_of(i, faction)))))
	var un: PackedStringArray = []
	for id in fd["units"]:
		un.append("%s (%s niv. %d)" % [GameData.name_of(id, faction), GameData.name_of("usine", faction), int(GameData.UNITS[id].get("level", 1))])
	tech.append("Unités terrestres et mechas : " + ", ".join(un))
	var ua: PackedStringArray = []
	for id in fd["air"]:
		ua.append("%s (%s niv. %d)" % [GameData.name_of(id, faction), GameData.name_of("usine", faction), int(GameData.UNITS[id].get("level", 1))])
	tech.append(("Unités volantes (%s, dès la mission %d) : " % [GameData.name_of("aerodrome", faction), mission_for_unlock(faction, 2) + 1]) + ", ".join(ua))
	tech.append("Les unités plus puissantes demandent d'améliorer : %s" % GameData.name_of("usine", faction))
	out.append(["TECHNOLOGIE", tech])
	return out


## Unités de départ : "@i" = i-ième unité de combat de la faction jouée.
static func resolve_units(faction: String, ids: Array) -> Array:
	var out: Array = []
	var fu: Array = GameData.FACTIONS[faction]["units"]
	for id in ids:
		if String(id).begins_with("@"):
			out.append(fu[int(String(id).substr(1)) % fu.size()])
		else:
			out.append(id)
	return out


static func cleared(faction: String) -> int:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return 0
	return int(cf.get_value("progress", faction, 0))


static func mark_cleared(faction: String, m: int) -> void:
	var cf := ConfigFile.new()
	cf.load(SAVE_PATH)
	var cur := int(cf.get_value("progress", faction, 0))
	if m + 1 > cur:
		cf.set_value("progress", faction, m + 1)
		cf.save(SAVE_PATH)


## Remet la progression d'une campagne à zéro (les missions se reverrouillent).
static func reset(faction: String) -> void:
	var cf := ConfigFile.new()
	cf.load(SAVE_PATH)
	cf.set_value("progress", faction, 0)
	cf.save(SAVE_PATH)
