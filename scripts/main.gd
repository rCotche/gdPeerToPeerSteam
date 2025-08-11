extends Node

var lobby_id = 0
#instancie un objet SteamMultiplayerPeer,
#c’est-à-dire une implémentation
#de l’interface MultiplayerPeer
#branchée sur les API réseau de Steam (P2P).
#Cet objet pourra ensuite être branché
#sur le MultiplayerAPI de Godot pour piloter le multijoueur
var peer = SteamMultiplayerPeer.new()

#Ce nœud sert à répliquer automatiquement des scènes instanciées
#chez l’autorité vers tous les pairs
#(y compris les joueurs qui rejoignent en cours de partie).
@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready() -> void:
	#On indique au spawner d’utiliser une fonction de spawn personnalisée.
	#Avec un “custom spawn”, Godot enverra la donnée data à tous les pairs,
	#qui appelleront localement spawn_level(data)
	#et retourneront un Node non encore dans l’arbre.
	multiplayer_spawner.spawn_function = spawn_level
	#connect le signal
	peer.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(on_lobby_match_list)
	open_lobby_list()

func join_lobby(id):
	#on se connecte avec le lobby : lobby_id
	peer.connect_lobby(id)
	#godot
	multiplayer.multiplayer_peer = peer
	lobby_id = id
	$Host.hide()
	$LobbyContainer/Lobbies.hide()
	$Refresh.hide()

#Ta fonction de spawn reçoit data (ici, un chemin de scène),
#charge le PackedScene, instancie le niveau,
#puis renvoie le Node à faire apparaître côté local.
#Le Spawner l’ajoutera là où il est configuré
#et veillera à ce que tout le monde ait la même instance.
#La méthode spawn() retourne d’ailleurs l’instance locale immédiatement.
func spawn_level(data):
	#instanciation du level
	var a = (load(data) as PackedScene).instantiate()
	return a

func _on_host_pressed() -> void:
	#Créer un lobby Steam (public) pour rassembler les joueurs.
	#Dans GodotSteam, la gestion de lobby repose sur l’API Matchmaking
	#(fonctions type createLobby, joinLobby, etc.).
	#Le SteamMultiplayerPeer sait ensuite se connecter à un lobby
	#et l’héberger pour le réseau haut-niveau de Godot.
	peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_PUBLIC)
	#branche le transport réseau de ton arbre de scènes
	#sur Steam (au lieu d’ENet). C’est ce peer qui transporte RPC,
	#synchronisation, etc.
	multiplayer.multiplayer_peer = peer
	#demande au Spawner de répliquer ce niveau à tout le monde
	#en appelant spawn_level sur chaque machine.
	#Ainsi, tous les pairs chargent la même scène immédiatement,
	#et les retardataires la recevront à la connexion.
	multiplayer_spawner.spawn("res://scenes/level.tscn")
	$Host.hide()
	$LobbyContainer/Lobbies.hide()
	$Refresh.hide()

func _on_lobby_created(connect, id):
	#Si la création a réussi, on mémorise l’id du lobby.
	if connect:
		lobby_id = id
		#définit des métadonnées de lobby
		#(ici, un nom lisible, construit avec le persona name de l’hôte).
		#Côté Steamworks, seul le propriétaire du lobby peut écrire ces données.
		Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName()+"'s lobby"))
		#rend le lobby rejoignable
		#et visible dans les recherches
		#(condition nécessaire pour que requestLobbyList le renvoie). 
		Steam.setLobbyJoinable(lobby_id, true)
		print(lobby_id)

func open_lobby_list():
	#règle le filtre de distance
	#sur worldwide (pas de restriction géographique).
	#Le filtrage se base sur la géolocalisation IP
	#de l’utilisateur ;
	#les valeurs possibles sont CLOSE / DEFAULT / FAR / WORLDWIDE.
	#Attention : WORLDWIDE peut renvoyer des lobbies très éloignés
	#⇒ latence élevée.
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	#envoie la requête asynchrone qui applique les filtres définis juste avant.
	#Par défaut (si tu n’appelles pas le filtre),
	#Steam utilise DEFAULT
	#et ne renverra que des lobbies de ta région ou proches.
	Steam.requestLobbyList()

func on_lobby_match_list(lobbies):
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var member_count = Steam.getNumLobbyMembers(lobby)
		
		var btn = Button.new()
		btn.set_text(str(lobby_name, "| Player count : ", member_count))
		btn.set_size(Vector2(100,5))
		#connect le signal pressed
		btn.connect("pressed", Callable(self, "join_lobby").bind(lobby))
		
		$LobbyContainer/Lobbies.add_child(btn)


func _on_refresh_pressed() -> void:
	if $LobbyContainer/Lobbies.get_child_count() > 0:
		for unLobby in $LobbyContainer/Lobbies.get_children():
			unLobby.queue_free()
	open_lobby_list()
