class_name Campaign
## Campagnes : 10 missions par faction, objectifs variés, progression sauvegardée.
## Tous les camps démarrent avec un simple engin de chantier à déployer.

const SAVE_PATH := "user://campaign.cfg"

## Types d'objectifs : build, harvest, train, survive, destroy_all, outposts,
## escort, hold, protect_ally (contrainte : la base alliée ne doit pas tomber).
const BASE := {"centrale": 1, "raffinerie": 1, "fonderie": 1, "usine": 1}

## Une campagne différente par faction : 10 missions chacune, avec son propre adversaire,
## ses objectifs, son rythme et son briefing ({ENEMY} et {ALLY} = noms des factions).
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
			"id": "ligne", "title": "Tenir la ligne", "enemy": "kharn", "ally": true, "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "ally_units": 2,
			"objectives": [{"type": "survive", "time": 600.0}, {"type": "protect_ally"}],
			"ai": {"slowdown": 1.5, "grace": 300.0, "pause": 60.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"ally_ai": {"slowdown": 1.8, "grace": 600.0, "pause": 90.0, "max_army": 8, "wave": 5, "credits": 1200, "ore": 1500},
			"obj": "Survivez 10 minutes sans perdre la base alliée",
			"brief": "{ALLY} a besoin de notre bouclier. {ENEMY} va déferler en force : fortifiez-vous, tenez dix minutes et protégez notre allié.",
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
			"zone": {"units": 4, "time": 75.0},
			"objectives": [{"type": "hold"}, {"type": "destroy_all"}, {"type": "train", "count": 10}],
			"ai": {"slowdown": 1.15, "grace": 360.0, "pause": 50.0, "max_army": 22, "wave": 6, "credits": 2500, "ore": 2800},
			"third_ai": {"slowdown": 1.5, "grace": 420.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Tenez la zone centrale, formez 10 unités et détruisez les deux camps adverses",
			"brief": "Le grand sommet réunit trois maisons et aucune n'a d'allié. {ENEMY} et {RIVAL} se battent aussi entre eux : tenez la zone centrale, bâtissez une armée et ne laissez personne debout.",
		},
		{
			"id": "laboratoire", "title": "Le laboratoire", "enemy": "vael", "size": 96, "credits": 3000, "ore": 3500,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "upgrade", "id": "chantier", "level": 3}, {"type": "upgrade", "id": "usine", "level": 2},
					{"type": "upgrade", "id": "centrale", "level": 3}, {"type": "build", "label": "le complexe", "ids": {"radar": 1, "reacteur": 1}}],
			"ai": {"slowdown": 1.9, "grace": 420.0, "pause": 70.0, "max_army": 10, "wave": 5, "credits": 1500, "ore": 1800},
			"obj": "Portez Chantier, Usine et Centrale à leur niveau cible et bâtissez radar et réacteur",
			"brief": "Le conseil de Solis veut une vitrine : un campement entièrement modernisé. Montez le Chantier au niveau 3, l'Usine au niveau 2 et la Centrale au niveau 3, puis ajoutez radar et réacteur. Pendant les travaux un bâtiment ne produit plus : échelonnez les chantiers pendant que {ENEMY} observe de loin.",
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
			"brief": "La base de {ENEMY} est déjà là, en ordre de marche. Précision d'abord : coupez son énergie, sa récolte et son minerai en moins d'un quart d'heure. Chaque minute perdue lui laisse le temps de se fortifier.",
		},
		{
			"id": "pont", "title": "Pont aérien", "enemy": "kharn", "size": 112, "credits": 3500, "ore": 3500,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "build", "label": "la base aérienne", "ids": {"usine": 1, "aerodrome": 1}},
					{"type": "air", "count": 4}, {"type": "kills", "count": 15}],
			"ai": {"slowdown": 1.3, "grace": 300.0, "pause": 50.0, "max_army": 16, "wave": 6, "credits": 2200, "ore": 2400},
			"obj": "Bâtissez un aérodrome, alignez 4 appareils et abattez 15 unités ennemies",
			"brief": "L'avenir de Solis est dans le ciel. Construisez un aérodrome, formez une escadre de quatre appareils et prouvez sa valeur en détruisant quinze unités de {ENEMY}. Leurs batteries antiaériennes sont rares mais redoutables.",
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
			"zone": {"units": 5, "time": 90.0},
			"objectives": [{"type": "hold"}, {"type": "train", "count": 8}, {"type": "harvest", "amount": 2500}],
			"ai": {"slowdown": 1.5, "grace": 300.0, "pause": 60.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"third_ai": {"slowdown": 1.5, "grace": 420.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Tenez la zone centrale, formez 8 unités et récoltez 2500 Solaris",
			"brief": "Le col central attire aussi {RIVAL}, qui n'est l'ami de personne. Occupez-le avec cinq unités face à {ENEMY} et aux pillards, sans négliger la récolte.",
		},
		{
			"id": "guerre", "title": "Convoi de guerre", "enemy": "vael", "ally": true, "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "ally_units": 2,
			"convoy": {"count": 4, "need": 3, "ambushes": 3, "start": 420.0, "ambush_size": 3},
			"objectives": [{"type": "escort"}, {"type": "train", "count": 5}],
			"ai": {"slowdown": 1.7, "grace": 600.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1500, "ore": 1800},
			"ally_ai": {"slowdown": 1.9, "grace": 600.0, "pause": 90.0, "max_army": 8, "wave": 5, "credits": 1200, "ore": 1500},
			"obj": "Escortez le convoi de munitions : 3 camions sur 4 doivent arriver",
			"brief": "Un convoi de munitions doit rejoindre le front. {ENEMY} a tendu trois embuscades sur la route, plus nombreuses mais moins bien défendues : brisez-les. {ALLY} nous couvre à l'arrière.",
		},
		{
			"id": "ecrasement", "title": "L'écrasement", "enemy": "solis", "rival": true, "size": 112, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@0", "@1", "@1"], "ally_units": 3,
			"objectives": [{"type": "destroy_all"}, {"type": "train", "count": 12}, {"type": "harvest", "amount": 5000}],
			"ai": {"slowdown": 1.1, "grace": 360.0, "pause": 50.0, "max_army": 24, "wave": 6, "credits": 2500, "ore": 2800},
			"third_ai": {"slowdown": 1.5, "grace": 420.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Détruisez les deux armées, formez 12 unités et récoltez 5000 Solaris",
			"brief": "La campagne se joue ici et chacun pour soi : {ENEMY} et {RIVAL} s'entre-déchirent. Prenez-les l'un après l'autre, remplissez les caisses et ne laissez rien debout.",
		},
		{
			"id": "blitz", "title": "Blitzkrieg", "enemy": "solis", "start_base": true, "enemy_base": true, "size": 80, "credits": 3000, "ore": 3000,
			"start_units": ["@0", "@0", "@1", "@1", "@2", "@2"], "time_limit": 720.0,
			"objectives": [{"type": "destroy_all"}, {"type": "kills", "count": 15}],
			"ai": {"slowdown": 2.0, "grace": 900.0, "pause": 90.0, "max_army": 8, "wave": 4, "credits": 1200, "ore": 1500},
			"obj": "Rasez toute la présence ennemie en 12 minutes",
			"brief": "Pas de préparatifs : la base est prête, les blindés aussi. {ENEMY} n'a pas fini de s'installer. Douze minutes pour tout raser avant que ses renforts n'arrivent.",
		},
		{
			"id": "forge", "title": "La forge de guerre", "enemy": "vael", "size": 96, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@1"],
			"objectives": [{"type": "ore", "amount": 5000}, {"type": "train", "count": 14},
					{"type": "build", "label": "les défenses", "ids": {"tourelle": 4}}, {"type": "power", "amount": 250}],
			"ai": {"slowdown": 1.6, "grace": 360.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Récoltez 5000 minerai, alignez 14 unités, 4 tourelles et 250 d'énergie",
			"brief": "La Légion forge ses armes dans le minerai. Alimentez les fournaises : 5000 de minerai, une armée de quatorze machines, quatre tourelles et assez d'énergie pour tout faire tourner. {ENEMY} tentera de saboter l'effort.",
		},
		{
			"id": "pluie", "title": "Pluie d'acier", "enemy": "vael", "enemy_base": true, "size": 112, "credits": 3500, "ore": 3500,
			"start_units": ["@0", "@1"], "time_limit": 1500.0,
			"objectives": [{"type": "air", "count": 5}, {"type": "destroy_all"}],
			"ai": {"slowdown": 1.3, "grace": 420.0, "pause": 60.0, "max_army": 16, "wave": 6, "credits": 2200, "ore": 2400},
			"obj": "Alignez 5 appareils et détruisez la base ennemie en 25 minutes",
			"brief": "La Légion apprend à frapper d'en haut. Bâtissez un aérodrome, montez une escadre de cinq appareils puis écrasez la forteresse de {ENEMY} avec l'appui du ciel. Le temps est compté.",
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
			"ally_units": 4, "start_units": ["@0", "@0", "@1", "@1"], "zone": {"units": 8, "time": 120.0},
			"objectives": [{"type": "hold"}, {"type": "kills", "count": 40}, {"type": "upgrade", "id": "chantier", "level": 3},
					{"type": "power", "amount": 400}, {"type": "train", "count": 20}],
			"ai": {"slowdown": 1.2, "grace": 300.0, "pause": 50.0, "max_army": 20, "wave": 6, "credits": 2600, "ore": 2800},
			"third_ai": {"slowdown": 1.4, "grace": 360.0, "pause": 60.0, "max_army": 16, "wave": 6, "credits": 2200, "ore": 2400},
			"obj": "Tenez le trône avec 8 unités pendant 2 minutes, détruisez 40 unités, Chantier niveau 3, 400 d'énergie, 20 unités",
			"brief": "Le trône de fer est au centre du monde et {ENEMY} comme {RIVAL} le veulent. Montez votre empire : chantier au sommet, énergie en abondance, vingt machines, puis posez huit unités sur le trône et gardez-le deux minutes. Quarante victimes feront taire les prétendants.",
		},
	],
	# --- Cartel Vael : vitesse, ruse, commerce ---
	"vael": [
		{
			"id": "contrebande", "title": "Contrebande", "enemy": "kharn", "size": 80, "credits": 1500, "ore": 1800,
			"objectives": [{"type": "build", "label": "la base", "ids": BASE}, {"type": "harvest", "amount": 4000}],
			"ai": {"slowdown": 2.4, "grace": 900.0, "pause": 120.0, "max_army": 6, "wave": 4, "credits": 1000, "ore": 1200},
			"obj": "Bâtissez la base et récoltez 4000 Solaris",
			"brief": "Le Cartel ouvre un comptoir clandestin. Posez la base, lancez la récolte et amassez 4000 Solaris : l'argent est la première arme. {ENEMY} n'est pas encore au courant.",
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
			"id": "double", "title": "Double jeu", "enemy": "kharn", "ally": true, "size": 96, "credits": 2000, "ore": 2200,
			"start_units": ["@0", "@1"], "ally_units": 2,
			"objectives": [{"type": "survive", "time": 420.0}, {"type": "protect_ally"}],
			"ai": {"slowdown": 1.4, "grace": 240.0, "pause": 50.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"ally_ai": {"slowdown": 1.8, "grace": 600.0, "pause": 90.0, "max_army": 8, "wave": 5, "credits": 1200, "ore": 1500},
			"obj": "Survivez 7 minutes sans perdre la base de l'allié",
			"brief": "{ALLY} nous paie pour tenir les assauts de {ENEMY}. Sept minutes : assez pour toucher la prime, pas assez pour laisser sa base tomber.",
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
			"zone": {"units": 3, "time": 45.0},
			"objectives": [{"type": "hold"}, {"type": "destroy_all"}, {"type": "harvest", "amount": 4000}],
			"ai": {"slowdown": 1.15, "grace": 360.0, "pause": 50.0, "max_army": 22, "wave": 6, "credits": 2500, "ore": 2800},
			"third_ai": {"slowdown": 1.5, "grace": 420.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1800, "ore": 2000},
			"obj": "Prenez la zone centrale 45 s, amassez 4000 Solaris et éliminez les deux camps adverses",
			"brief": "Le coup du siècle : le coffre central de {ENEMY} intéresse aussi {RIVAL}. Prenez-le avant eux, remplissez les caisses, puis détruisez tout ce qui reste.",
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
			"brief": "{ENEMY} a mis sa tête à prix, et nous touchons à chaque blindé abattu. Trente victimes en quatorze minutes : harcelez, repliez-vous, recommencez. Quelques Solaris au passage ne feront pas de mal.",
		},
		{
			"id": "fragile", "title": "Alliance fragile", "enemy": "solis", "ally": true, "size": 112, "credits": 2500, "ore": 2500,
			"start_units": ["@0", "@1"], "ally_units": 3,
			"convoy": {"count": 5, "need": 4, "ambushes": 3, "start": 360.0, "ambush_size": 3},
			"objectives": [{"type": "escort"}, {"type": "protect_ally"}, {"type": "upgrade", "id": "raffinerie", "level": 2}],
			"ai": {"slowdown": 1.5, "grace": 360.0, "pause": 70.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"ally_ai": {"slowdown": 1.8, "grace": 600.0, "pause": 90.0, "max_army": 8, "wave": 5, "credits": 1200, "ore": 1500},
			"obj": "Escortez 4 camions sur 5, gardez la base de l'allié et passez la raffinerie au niveau 2",
			"brief": "{ALLY} ne nous aime pas, mais il paie. Escortez ses camions à travers les embuscades de {ENEMY}, empêchez sa base de tomber et prouvez le savoir-faire du Cartel en modernisant la raffinerie.",
		},
		{
			"id": "troisgrands", "title": "Guerre des trois", "enemy": "kharn", "rival": true, "size": 112, "credits": 3000, "ore": 3000,
			"ally_units": 3, "start_units": ["@0", "@0", "@1", "@2"],
			"objectives": [{"type": "destroy_type", "id": "chantier", "count": 2}, {"type": "survive", "time": 600.0},
					{"type": "harvest", "amount": 3500}, {"type": "kills", "count": 20}],
			"ai": {"slowdown": 1.6, "grace": 300.0, "pause": 60.0, "max_army": 14, "wave": 5, "credits": 1800, "ore": 2000},
			"third_ai": {"slowdown": 1.7, "grace": 360.0, "pause": 70.0, "max_army": 12, "wave": 5, "credits": 1700, "ore": 1900},
			"obj": "Détruisez les deux chantiers ennemis, tenez 10 minutes, récoltez 3500 Solaris et abattez 20 unités",
			"brief": "{ENEMY} et {RIVAL} se détestent : laissez-les s'user. Tenez dix minutes, remplissez les caisses et frappez l'instant venu : il faut décapiter les deux camps en détruisant leurs chantiers.",
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
	return CAMPAIGNS[faction]


static func mission(faction: String, m: int) -> Dictionary:
	return CAMPAIGNS[faction][m]


static func count(faction := "solis") -> int:
	return CAMPAIGNS[faction].size()


static func title_of(faction: String, m: int) -> String:
	return CAMPAIGNS[faction][m]["title"]


static func enemy_of(faction: String, m: int) -> String:
	return CAMPAIGNS[faction][m]["enemy"]


## Troisième faction de la mission (allié ou rival), "" s'il n'y en a pas.
static func third_of(faction: String, m: int) -> String:
	var d: Dictionary = CAMPAIGNS[faction][m]
	if not (d.get("ally", false) or d.get("rival", false)):
		return ""
	for k in GameData.FACTIONS.keys():
		if k != faction and k != enemy_of(faction, m):
			return k
	return ""


static func ally_of(faction: String, m: int) -> String:
	return third_of(faction, m) if CAMPAIGNS[faction][m].get("ally", false) else ""


## Second adversaire (chacun pour soi) : la troisième faction est hostile à tous.
static func rival_of(faction: String, m: int) -> String:
	return third_of(faction, m) if CAMPAIGNS[faction][m].get("rival", false) else ""


static func briefing(faction: String, m: int) -> String:
	var t: String = CAMPAIGNS[faction][m]["brief"]
	t = t.replace("{ENEMY}", GameData.FACTIONS[enemy_of(faction, m)]["name"])
	var ally := ally_of(faction, m)
	t = t.replace("{ALLY}", GameData.FACTIONS[ally]["name"] if ally != "" else "")
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
static func details(faction: String, m: int) -> Array:
	var d: Dictionary = CAMPAIGNS[faction][m]
	var fd: Dictionary = GameData.FACTIONS[faction]
	var enemy: String = GameData.FACTIONS[enemy_of(faction, m)]["name"]
	var ally := ally_of(faction, m)
	var out: Array = []
	# Objectifs
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
				if rival_of(faction, m) != "":
					obj.append("Détruire toutes les unités et structures de %s et de %s" % [enemy, GameData.FACTIONS[rival_of(faction, m)]["name"]])
				else:
					obj.append("Détruire toutes les unités et structures de %s" % enemy)
			"protect_ally":
				obj.append("Ne pas laisser tomber la base alliée (défaite sinon)")
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
	if ally != "":
		sit.append("Allié : %s (IA, démarre aussi avec un engin de chantier)" % GameData.FACTIONS[ally]["name"])
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
