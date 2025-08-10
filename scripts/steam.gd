extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#À quoi ça sert ? Tu “indiques” à l’API Steam
	#quel jeu est en train de tourner.
	#Pourquoi 480 ? C’est l’ID de Spacewar, l’appli de test
	#officielle de Steam. On l’utilise en local pour prototyper
	#(overlay, succès, stats, callbacks…)
	#sans avoir encore publié son propre AppID.
	#En prod : remplace 480 par ton vrai AppID
	#ou utilise un fichier steam_appid.txt.
	#Évite de shipper avec l’ID 480.
	OS.set_environment("SteamAppID", str(480))
	OS.set_environment("SteamGameID", str(480))
	#Steam.steamInitEx() est la version “pro” de l’initialisation Steamworks,
	#qui te donne plus de détails et de contrôle,
	#et que tu dois appeler une seule fois
	#au lancement du jeu pour que toutes les API Steam fonctionnent.
	Steam.steamInitEx()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#À quoi ça sert ? Cette ligne “draine” à chaque frame
	#les callbacks Steamworks (ouverture/fermeture de l’overlay,
	#possession d’achievements, réponses réseau P2P, micro-transactions,
	#rich presence, etc.). Sans ça ? Les événements Steam
	#n’arrivent pas et “rien ne se passe” côté overlay/succès/réseau,
	#même si l’init s’est bien faite.
	Steam.run_callbacks()
