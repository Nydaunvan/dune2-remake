class_name GameSession
## État partagé entre le menu et la partie (survit au changement de scène).

static var faction := "solis"
static var mode := "skirmish" # "skirmish" ou "campaign"
static var mission := 0
static var auto_player := false # tests : le camp du joueur est lui aussi piloté par une IA (banc d'équilibrage)
static var instant_bases := false # tests : bases complètes dès le départ
static var load_slot := -1 # emplacement à charger au prochain lancement de la partie (-1 : partie neuve)
static var opponents := 1 # escarmouche : nombre d'adversaires (1 à 3 ; à partir de 2, chacun pour soi)

# Paramètres de l'escarmouche (fenêtre de paramétrage du menu)
static var skirm_foe := ""          # faction adverse imposée (1 adversaire) ; "" : au hasard
static var skirm_size := 96         # taille de la carte (cases)
static var skirm_res := 1.0         # multiplicateur des ressources de départ
static var skirm_diff := 1          # difficulté de l'IA : 0 facile, 1 normale, 2 difficile
