class_name GameSession
## État partagé entre le menu et la partie (survit au changement de scène).

static var faction := "solis"
static var mode := "skirmish" # "skirmish" ou "campaign"
static var mission := 0
static var instant_bases := false # tests : bases complètes dès le départ
static var load_slot := -1 # emplacement à charger au prochain lancement de la partie (-1 : partie neuve)
