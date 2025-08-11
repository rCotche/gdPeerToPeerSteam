extends MultiplayerSpawner

@export var playerScene: PackedScene
#dictionary qui va contenir tous les player
var players = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_function = spawnPlayer
	#On exécute la suite uniquement sur le nœud qui a l’autorité.
	#Par défaut, l’autorité d’un nœud est le serveur,
	#mais elle peut être changée nœud par nœud. 
	if is_multiplayer_authority():
		#On crée tout de suite le joueur du serveur.
		#Le peer ID du serveur est toujours 1 en Godot 4,
		#les clients reçoivent des IDs positifs aléatoires.
		spawn(1)
		#On s’abonne au signal peer_connected(id: int) de l’API réseau;
		#à chaque nouvelle connexion,
		#Godot émet ce signal avec l’ID du pair,
		#et on appelle spawn(id) pour instancier son joueur.
		#Assure-toi que spawn prend bien un paramètre id. 
		multiplayer.peer_connected.connect(spawn)
		#Même idée pour peer_disconnected(id: int) :
		#quand un pair se déconnecte, on appelle removePlayer(id)
		#pour nettoyer sa présence
		#(désinstancier, libérer ressources, etc.).
		multiplayer.peer_disconnected.connect(removePlayer)


func spawnPlayer(data):
	var p = playerScene.instantiate()
	#donne à ce nœud l’autorité réseau du pair dont l’ID est data.
	#En Godot 4, l’autorité décide qui a le droit d’émettre des RPC
	#et de pousser des états synchronisés pour ce nœud
	#(par défaut c’est le serveur). 
	p.set_multiplayer_authority(data)
	players[data] = p
	return p

func removePlayer(data)->void:
	players[data].queue_free()
	players.erase(data)
