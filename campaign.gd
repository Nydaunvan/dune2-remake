class_name Campaign
## Campagnes : 10 missions par faction, objectifs variés, progression sauvegardée.
## Tous les camps démarrent avec un simple engin de chantier à déployer.

const SAVE_PATH := "user://campaign.cfg"

## (l'élimination d'une faction n'est jamais requise sauf si destroy_all figure dans les objectifs)
## Types d'objectifs : build, harvest, train, survive, destroy_all, outposts,
## escort.
const BASE := {"centrale": 1, "raffinerie": 1, "fonderie": 1, "usine": 1}

## Une campagne différente par faction : 10 missions chacune, avec son propre adversaire,
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
			"id": "ligne", "title": "Tenir la ligne", "enemy": "kharn", "rival": true, "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "ally_units": 2,
			"objectives": [{"type": "survive", "time": 600.0}, {"type": "kills", "count": 10}],
			"ai": {"slowdown": 1.5, "grace": 300.0, "pause": 60.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Survivez 10 minutes et abattez 10 unités ennemies",
			"brief": "{ENEMY} va déferler en force et {RIVAL} guette le moment où nous faiblirons. Aucune de ces deux maisons n'est notre amie : fortifiez-vous, tenez la durée exigée et faites payer chaque assaut.",
		},
		{
			"id": "cristaux", "title": "Convoi de cristaux", "enemy": "kharn", "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"],
			"convoy": {"count": 5, "need": 4, "ambushes": 2, "start": 420.0, "ambush_size": 2},
			"objectives": [{"type": "escort"}, {"type": "train", "count": 6}, {"type": "harvest", "amount": 2500}],
			"ai": {"slowdown": 1.6, "grace": 600.0, "pause": 80.0, "max_army": 10, "wave": 5, "credits": 1500, "ore": 1800},
			"obj": "Escortez le convoi (4 camions sur 5), formez 6 unités et récoltez 2500 Solaris",
			"brief": "Cinq camions chargés de cristaux de focalisation doivent atteindre notre laboratoire. {ENEMY} a posté des embuscades : sécurisez la route avec votre armée et ne perdez qu'un camion au plus.",
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
			"brief": "Le conseil de Solis veut une vitrine : un campement entièrement modernisé. Montez le Chantier, l'Usine et la Centrale aux niveaux demandés, puis ajoutez radar et réacteur. Pendant les travaux un bâtiment ne produit plus : échelonnez les chantiers pendant que {ENEMY} observe de loin.",
		},
		{
			"id": "tempete", "title": "Tempête d'épice", "enemy": "kharn", "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["recolteur", "recolteur", "@0", "@1"], "worm_rate": 5.0, "worm_grace": 60.0,
			"objectives": [{"type": "harvest", "amount": 4000}, {"type": "survive", "time": 480.0}, {"type": "train", "count": 6}],
			"ai": {"slowdown": 1.5, "grace": 240.0, "pause": 60.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Récoltez 4000 Solaris et tenez 8 minutes malgré les vers",
			"brief": "Une tempête d'épice a réveillé les vers de sable : ils rôdent partout. Récoltez malgré eux, faites fuir vos récolteurs au bon moment et gardez une escorte. {ENEMY} profite du chaos pour tâter nos défenses.",
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
			"id": "pont", "title": "Pont aérien", "enemy": "kharn", "size": 112, "credits": 3500, "ore": 3500,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "build", "label": "la base aérienne", "ids": {"usine": 1, "aerodrome": 1}},
					{"type": "air", "count": 4}, {"type": "kills", "count": 15}],
			"ai": {"slowdown": 1.3, "grace": 300.0, "pause": 50.0, "max_army": 16, "wave": 6, "credits": 2200, "ore": 2400},
			"obj": "Bâtissez un aérodrome, alignez 4 appareils et abattez 15 unités ennemies",
			"brief": "L'avenir de Solis est dans le ciel. Construisez un aérodrome, formez une escadre et prouvez sa valeur en détruisant les unités de {ENEMY}. Leurs batteries antiaériennes sont rares mais redoutables.",
		},
		{
			"id": "aiguille", "title": "L'Aiguille", "enemy": "kharn", "start_base": true, "size": 112, "credits": 3000, "ore": 3000,
			"start_units": ["@0", "@0", "@1"],
			"objectives": [{"type": "survive", "time": 780.0}, {"type": "kills", "count": 25},
					{"type": "build", "label": "le front", "ids": {"tourelle": 4}}, {"type": "upgrade", "id": "tourelle", "level": 2}],
			"ai": {"slowdown": 1.1, "grace": 200.0, "pause": 45.0, "max_army": 24, "wave": 7, "credits": 3000, "ore": 3200},
			"obj": "Tenez 13 minutes, détruisez 25 unités, alignez 4 tourelles dont une améliorée",
			"brief": "Dernier rempart : la base de l'Aiguille est déjà bâtie, mais {ENEMY} y envoie tout ce qu'il possède. Fortifiez, améliorez vos tourelles et brisez ses assauts un par un jusqu'à la relève.",
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
			"id": "guerre", "title": "Convoi de guerre", "enemy": "vael", "rival": true, "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "ally_units": 2,
			"convoy": {"count": 4, "need": 3, "ambushes": 3, "start": 420.0, "ambush_size": 3},
			"objectives": [{"type": "escort"}, {"type": "train", "count": 5}],
			"ai": {"slowdown": 1.7, "grace": 600.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1500, "ore": 1800},
			"obj": "Escortez le convoi de munitions : 3 camions sur 4 doivent arriver",
			"brief": "Un convoi de munitions doit rejoindre le front. {ENEMY} a tendu trois embuscades sur la route, plus nombreuses mais moins bien défendues : brisez-les. {RIVAL} rôde aussi dans la région et ne fera aucun cadeau.",
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
			"id": "pluie", "title": "Pluie d'acier", "enemy": "vael", "enemy_base": true, "size": 112, "credits": 3500, "ore": 3500,
			"start_units": ["@0", "@1"], "time_limit": 1500.0,
			"objectives": [{"type": "air", "count": 5}, {"type": "destroy_all"}],
			"ai": {"slowdown": 1.3, "grace": 420.0, "pause": 60.0, "max_army": 16, "wave": 6, "credits": 2200, "ore": 2400},
			"obj": "Alignez 5 appareils et détruisez la base ennemie en 25 minutes",
			"brief": "La Légion apprend à frapper d'en haut. Bâtissez un aérodrome, montez une escadre puis écrasez la forteresse de {ENEMY} avec l'appui du ciel. Le temps est compté.",
		},
		{
			"id": "disputees", "title": "Terres disputées", "enemy": "solis", "rival": true, "size": 112, "outposts": 3, "credits": 2500, "ore": 2500,
			"ally_units": 3, "start_units": ["@0", "@0", "@1"],
			"objectives": [{"type": "outposts"}, {"type": "kills", "count": 30}, {"type": "harvest", "amount": 3000}, {"type": "ore", "amount": 2000}],
			"ai": {"slowdown": 1.7, "grace": 360.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"third_ai": {"slowdown": 1.7, "grace": 420.0, "pause": 70.0, "max_army": 10, "wave": 5, "credits": 1600, "ore": 1800},
			"obj": "Rasez 3 avant-postes, détruisez 30 unités, récoltez 3000 Solaris et 2000 minerai",
			"brief": "Trois maisons se disputent la même vallée. {ENEMY} garde trois avant-postes, {RIVAL} pille tout ce qui passe. Prenez-les à tous les deux : abattez les avant-postes, faites des victimes et remplissez les silos.",
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
			"obj": "Faites passer 4 camions sur 5 jusqu'au point de livraison",
			"brief": "Nos camions de marchandises doivent traverser le territoire de {ENEMY} avant que ses patrouilles ne réagissent. Le départ est rapide, vos éclaireurs doivent l'être aussi.",
		},
		{
			"id": "double", "title": "Double jeu", "enemy": "kharn", "rival": true, "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "ally_units": 2,
			"objectives": [{"type": "survive", "time": 420.0}, {"type": "kills", "count": 12}],
			"ai": {"slowdown": 1.4, "grace": 240.0, "pause": 50.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Survivez 7 minutes et abattez 12 unités ennemies",
			"brief": "{ENEMY} et {RIVAL} se disputent le même territoire et chacun veut notre peau. Le temps convenu : assez pour toucher la prime, pas assez pour leur laisser le désert. Frappez celui qui s'expose.",
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
			"brief": "Le coup du siècle : le coffre central de {ENEMY} intéresse aussi {RIVAL}. Prenez-le avant eux, remplissez les caisses et abattez ceux qui vous barrent la route.",
		},
		{
			"id": "marche", "title": "Le marché noir", "enemy": "solis", "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "worm_rate": 2.0,
			"objectives": [{"type": "harvest", "amount": 6000}, {"type": "ore", "amount": 3000},
					{"type": "build", "label": "les entrepôts", "ids": {"silo": 3}}],
			"ai": {"slowdown": 1.9, "grace": 420.0, "pause": 70.0, "max_army": 10, "wave": 5, "credits": 1500, "ore": 1800},
			"obj": "Récoltez 6000 Solaris et 3000 minerai, bâtissez 3 silos",
			"brief": "Le Cartel ouvre son plus gros marché clandestin : il faut de l'épice, du minerai et des silos pour tout entreposer. Les vers sont nerveux, les récolteurs doivent l'être aussi. {ENEMY} n'y verra que du feu.",
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
			"id": "fragile", "title": "Route assiégée", "enemy": "solis", "rival": true, "size": 112, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@1"], "ally_units": 3,
			"convoy": {"count": 5, "need": 4, "ambushes": 3, "start": 360.0, "ambush_size": 3},
			"objectives": [{"type": "escort"}, {"type": "kills", "count": 10}, {"type": "upgrade", "id": "raffinerie", "level": 2}],
			"ai": {"slowdown": 1.5, "grace": 360.0, "pause": 70.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Escortez 4 camions sur 5, abattez 10 unités ennemies et passez la raffinerie au niveau 2",
			"brief": "{ENEMY} a tendu ses embuscades sur la route et {RIVAL} attend que nous trébuchions. Escortez les camions jusqu'au bout, repoussez les deux camps et prouvez le savoir-faire du Cartel en modernisant la raffinerie.",
		},
		{
			"id": "troisgrands", "title": "Guerre des trois", "enemy": "kharn", "rival": true, "size": 112, "credits": 3000, "ore": 3000,
			"ally_units": 3, "start_units": ["@0", "@0", "@1", "@2"],
			"objectives": [{"type": "destroy_type", "id": "chantier", "count": 2}, {"type": "survive", "time": 600.0},
					{"type": "harvest", "amount": 3500}, {"type": "kills", "count": 20}],
			"ai": {"slowdown": 1.6, "grace": 300.0, "pause": 60.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"third_ai": {"slowdown": 1.7, "grace": 360.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1700, "ore": 1900},
			"obj": "Détruisez les deux chantiers ennemis, tenez 10 minutes, récoltez 3500 Solaris et abattez 20 unités",
			"brief": "{ENEMY} et {RIVAL} se détestent : laissez-les s'user. Tenez la durée convenue, remplissez les caisses et frappez l'instant venu : il faut décapiter les deux camps en détruisant leurs chantiers.",
		},
		{
			"id": "roi", "title": "Roi du désert", "enemy": "solis", "rival": true, "start_base": true, "enemy_base": true, "third_base": true,
			"size": 112, "credits": 3500, "ore": 3500, "time_limit": 1500.0,
			"ally_units": 4, "start_units": ["@0", "@0", "@1", "@2"],
			"objectives": [{"type": "harvest", "amount": 8000}, {"type": "destroy_all"}, {"type": "air", "count": 4},
					{"type": "upgrade", "id": "chantier", "level": 3}],
			"ai": {"slowdown": 1.2, "grace": 300.0, "pause": 50.0, "max_army": 22, "wave": 6, "credits": 2800, "ore": 3000},
			"third_ai": {"slowdown": 1.4, "grace": 360.0, "pause": 60.0, "max_army": 18, "wave": 6, "credits": 2400, "ore": 2600},
			"obj": "En 25 minutes : 8000 Solaris, Chantier niveau 3, 4 appareils et la destruction des deux camps",
			"brief": "Trois bases, déjà bâties, une seule couronne. Le Cartel doit tout faire à la fois : remplir les caisses, moderniser, bâtir une flotte et effacer {ENEMY} et {RIVAL} avant que le temps ne s'écoule. Qui tient le désert tient le commerce.",
		},
	],
}

const FLAVOR := {
	"solis": "La Maison Solis mise sur la technologie et la précision.",
	"kharn": "La Légion Kharn mise sur la puissance brute et le blindage.",
	"vael": "Le Cartel Vael mise sur la vitesse et la ruse.",
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
	var g := float(i) / 9.0
	d["ai"] = AI_CURVE[i].duplicate()
	var a: Dictionary = d["ai"]
	a["skill"] = clampf(0.15 + 0.85 * g, 0.0, 1.0) # finesse de jeu de l'IA : de simple à redoutable
	# Second adversaire : même courbe, en un peu plus faible
	d["third_ai"] = {"slowdown": float(a["slowdown"]) * 1.3, "grace": float(a["grace"]) * 1.3, "pause": float(a["pause"]) * 1.3,
			"max_army": int(int(a["max_army"]) * 0.6), "wave": maxi(int(int(a["wave"]) * 0.7), 3),
			"credits": int(int(a["credits"]) * 0.7), "ore": int(int(a["ore"]) * 0.7), "skill": float(a["skill"]) * 0.8}
	# Les dernières missions : adversaire déjà installé, et la finale oppose trois camps
	if i >= 7:
		d["enemy_base"] = true
	if i == 9:
		d["rival"] = true
		if d.get("rival", false):
			d["third_base"] = true
	# Objectifs plus longs et plus exigeants avec le niveau (jusqu'à plusieurs fois la durée de base)
	for o in d["objectives"]:
		match o["type"]:
			"harvest", "ore", "power":
				o["amount"] = _round_to(float(o["amount"]) * (1.0 + 1.5 * g), 100)
			"survive":
				o["time"] = _round_to(float(o["time"]) * (1.0 + 1.8 * g), 30)
			"train", "air", "kills":
				o["count"] = maxi(int(round(float(o["count"]) * (1.0 + 1.2 * g))), int(o["count"]))
	if d.has("zone"):
		d["zone"]["time"] = _round_to(float(d["zone"]["time"]) * (1.0 + 1.0 * g), 15)
		d["zone"]["units"] = int(round(float(d["zone"]["units"]) * (1.0 + 0.6 * g)))
	if d.has("time_limit"):
		d["time_limit"] = _round_to(float(d["time_limit"]) * (1.0 + 2.0 * g), 60)
	if d.has("convoy"):
		d["convoy"]["ambushes"] = int(d["convoy"]["ambushes"]) + int(i / 3)
		d["convoy"]["ambush_size"] = int(d["convoy"]["ambush_size"]) + int(i / 3)
	d["obj"] = _obj_short(d)
	return d


## Résumé court des objectifs (cartes de mission, guide).
static func _obj_short(d: Dictionary) -> String:
	var parts: PackedStringArray = []
	for o in d["objectives"]:
		match o["type"]:
			"build":
				var names: PackedStringArray = []
				for id in o["ids"]:
					names.append(String(GameData.BUILDINGS[id]["name"]).to_lower())
				parts.append("bâtir " + ", ".join(names))
			"harvest": parts.append("récolter %d Solaris" % int(o["amount"]))
			"train": parts.append("former %d unités" % int(o["count"]))
			"survive": parts.append("tenir %s" % _mins(float(o["time"])))
			"escort": parts.append("escorter le convoi")
			"outposts": parts.append("raser les avant-postes")
			"hold": parts.append("tenir la zone %s" % _mins(float(d["zone"]["time"])))
			"destroy_all": parts.append("détruire tous les adversaires" if d.get("rival", false) else "détruire l'adversaire")
			"upgrade": parts.append("%s niveau %d" % [String(GameData.def(o["id"])["name"]).to_lower(), int(o["level"])])
			"kills": parts.append("%d victimes" % int(o["count"]))
			"destroy_type": parts.append("détruire %d %s" % [int(o["count"]), String(GameData.def(o["id"])["name"]).to_lower()])
			"ore": parts.append("récolter %d minerai" % int(o["amount"]))
			"power": parts.append("%d d'énergie" % int(o["power"] if o.has("power") else o["amount"]))
			"air": parts.append("%d appareils volants" % int(o["count"]))
	var t := ", ".join(parts)
	if d.has("time_limit"):
		t += " — en %s" % _mins(float(d["time_limit"]))
	return t.substr(0, 1).to_upper() + t.substr(1)


static func _round_to(v: float, step: int) -> float:
	return float(int(round(v / float(step))) * step)


## Niveau de difficulté affiché (1 à 10).
static func level_of(m: int) -> int:
	return m + 1


## Troisième faction de la mission (second adversaire), "" s'il n'y en a pas.
static func third_of(faction: String, m: int) -> String:
	var d: Dictionary = mission(faction, m)
	if not d.get("rival", false):
		return ""
	return _third(faction, d)


static func _third(faction: String, d: Dictionary) -> String:
	for k in GameData.FACTIONS.keys():
		if k != faction and k != d["enemy"]:
			return k
	return ""


## Second adversaire (chacun pour soi) : la troisième faction est hostile à tous.
static func rival_of(faction: String, m: int) -> String:
	return third_of(faction, m) if mission(faction, m).get("rival", false) else ""


static func briefing(faction: String, m: int) -> String:
	var t: String = mission(faction, m)["brief"]
	t = t.replace("{ENEMY}", GameData.FACTIONS[enemy_of(faction, m)]["name"])
	var rival := rival_of(faction, m)
	t = t.replace("{RIVAL}", GameData.FACTIONS[rival]["name"] if rival != "" else "")
	return FLAVOR[faction] + "\n\n" + t


static func _mins(s: float) -> String:
	var mn := int(s) / 60
	var sec := int(s) % 60
	if mn == 0:
		return "%d s" % sec
	return "%d min" % mn if sec == 0 else "%d min %02d s" % [mn, sec]


## Nombre d'adversaires (factions hostiles au joueur) d'une mission.
static func foe_count(faction: String, m: int) -> int:
	return 2 if rival_of(faction, m) != "" else 1


## « Adversaire : X » ou « Adversaires (2) : X et Y » (toutes les factions hostiles présentes).
static func foes_text(faction: String, m: int) -> String:
	var e: String = GameData.FACTIONS[enemy_of(faction, m)]["name"]
	var r := rival_of(faction, m)
	if r == "":
		return "Adversaire : %s" % e
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
					parts.append("%s ×%d" % [GameData.BUILDINGS[id]["name"], int(o["ids"][id])])
				obj.append("Construire : " + ", ".join(parts))
			"harvest":
				obj.append("Récolter %d Solaris au total" % int(o["amount"]))
			"train":
				obj.append("Produire %d unités de combat" % int(o["count"]))
			"survive":
				obj.append("Survivre %s" % _mins(float(o["time"])))
			"escort":
				var cv: Dictionary = d["convoy"]
				obj.append("Escorter le convoi (%d camions) jusqu'au point de livraison : %d doivent arriver" % [int(cv["count"]), int(cv["need"])])
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
				obj.append("Améliorer : %s au niveau %d" % [GameData.def(o["id"])["name"], int(o["level"])])
			"kills":
				obj.append("Détruire %d unités ennemies" % int(o["count"]))
			"destroy_type":
				obj.append("Détruire %d %s ennemi(s)" % [int(o["count"]), String(GameData.def(o["id"])["name"]).to_lower()])
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
		sit.append("La base du second adversaire est aussi déjà bâtie")
	if d.has("worm_rate"):
		sit.append("Les vers de sable sont %d fois plus fréquents : surveillez vos récolteurs" % int(d["worm_rate"]))
	var su: Array = d.get("start_units", [])
	if not su.is_empty():
		var names: PackedStringArray = []
		for id in resolve_units(faction, su):
			names.append(String(GameData.UNITS[id]["name"]))
		sit.append("Escorte de départ : " + ", ".join(names))
	sit.append(foes_text(faction, m))
	if rival_of(faction, m) != "":
		sit.append("Deux adversaires : toutes les factions présentes vous sont hostiles, et chacune attaque aussi l'autre (chacun pour soi)")
	if d.has("convoy"):
		sit.append("Le convoi part après %s : préparez votre escorte avant" % _mins(float(d["convoy"]["start"])))
		sit.append("%d embuscades ennemies (%d unités chacune) sur une route dégagée" % [int(d["convoy"]["ambushes"]), int(d["convoy"]["ambush_size"])])
	if d.has("outposts"):
		sit.append("Chaque avant-poste est gardé par des tourelles et des patrouilles")
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
		if int(bd.get("unlock", 0)) == m and m > 0:
			nb.append(String(bd["name"]))
	if m > 0:
		tech.append("Nouveaux bâtiments : " + (", ".join(nb) if not nb.is_empty() else "aucun"))
	else:
		tech.append("Bâtiments : Centrale, Raffinerie, Fonderie, Usine, Tourelle")
	var un: PackedStringArray = []
	for id in fd["units"]:
		un.append("%s (Usine niv. %d)" % [GameData.UNITS[id]["name"], int(GameData.UNITS[id].get("level", 1))])
	tech.append("Unités : " + ", ".join(un))
	var ua: PackedStringArray = []
	for id in fd["air"]:
		ua.append("%s (Usine niv. %d)" % [GameData.UNITS[id]["name"], int(GameData.UNITS[id].get("level", 1))])
	tech.append("Unités volantes (Aérodrome, dès la mission 3) : " + ", ".join(ua))
	tech.append("Les unités plus puissantes demandent d'améliorer l'Usine")
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
