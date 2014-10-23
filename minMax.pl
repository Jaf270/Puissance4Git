%en fonction de si on a gagner, perdu, qu'on ai un avantage
%ou un desavantage, la regle renvoie un certain score
eval(GamestateEnCours,Joueur,Score):-
	solution(Qui,GamestateEnCours),  %on demande si il y a un vainqueur et de le mettre dans Qui

	%on compare si c'est notre Joueur
	%si c'est oui on donne un gros score positif
	%si c'est non on donne un scrore negatif
	(	(Qui = Joueur , Score = 100 , ! );	(not(Qui = Joueur),Score = -100 , ! )	).

eval(GamestateEnCours,_,Score):-
	%supposons que solution renvoie true et le nom du vainqueur quand on lui demande et false sinon
	not(solution(_,GamestateEnCours)),
	Score = 0.

%Principe: L'IA (joueur m) en fonction d'un certain nombre de CoupDAvance et en fonction de sa ListeDeCoup possible
% va chercher le meilleur coup a jouer et le jouera.
% Du coup cette regle recupere l'etat courant du jeu, et fais la liste des coup possible.
% Pour chaque coup possible l'IA devra simuler ce coup et verra le nouvel etat du jeu.
% C'est a partir de ce nouvel etat de jeu que l'adversaire devra jouer un coup. Il cherchera donc a minimiser notre score.
% Parmi tous les score min (proposé par l'adversaire) qui s'offrent à l'IA,
% faudra qu'il choisisse le plus élevé (car il veut maximiser son score).
iaMinMax(Joueur,CoupDAvance,MeilleurCoup,LigneDuNouvelElem,ListPoids):-
	gamestate(X),

	init_gamestate,

	coupPossible(X,ListeDeCoup),

	%Simul tous les coup possible et renvoit le meilleur coup a jouer ainsi que la valeur de son poids
	simul(Joueur,CoupDAvance,ListeDeCoup,ListPoids,MeilleurCoup),
	joueIa(Joueur,MeilleurCoup,ListPoids,LigneDuNouvelElem).

% Determine si l'IA doit jouer au milieu pour un premier tour, jouer de façon prémédité ou bien de façon aléatoire
joueIa(Joueur,_,ListPoids,LigneDuNouvelElem):-
	subtract(ListPoids,[-1000000],TrueListPoids),
	gamestate(X),subtract(TrueListPoids,[0],[]),X=[[],[],[],[],[],[],[]],jouer(Joueur,4,LigneDuNouvelElem), ! .

joueIa(Joueur,_,ListPoids,LigneDuNouvelElem):-
	subtract(ListPoids,[-1000000],TrueListPoids),
	gamestate(X),subtract(TrueListPoids,[0],[]),not(X=[[],[],[],[],[],[],[]]),iaRandom(Joueur,_,LigneDuNouvelElem),!.

joueIa(Joueur,MeilleurCoup,ListPoids,LigneDuNouvelElem):-
	subtract(ListPoids,[-1000000],TrueListPoids),
	not(subtract(TrueListPoids,[0],[])), jouer(Joueur,MeilleurCoup,LigneDuNouvelElem),!.

%condition d'arret:
%Lorsqu'il n'y a plus de coup possible a jouer -> [].
%On choisit des valeur par defaut pour 'Poids' et 'Coup'.
%Le Poids sera comparé à un vrai poids calculé à partir d'un coup de l'adversaire
simul(_,_,[],Poids,4):-
	Poids = [-1000000].

simul(Joueur,ProfondeurEnCours,ListeDeCoup,ListPoids,MeilleurCoup):-
	ListeDeCoup = [CoupActuel|Queue],

	%sauvegarde du ctx actuel
	gamestateTampon(GamestateEnCours),

	simulationCoup(Joueur,CoupActuel,NewGamestate),

	%sur la profondeur suivante, ça sera a l'adversaire de jouer et bien sur il jouera le coup donnant à l'IA le pire score
	ProfondeurSuivante is ProfondeurEnCours-1,
	min(NewGamestate,Joueur,ProfondeurSuivante,PoidsCoupActuel),

	%on revient a la configuration du jeu en cours pour simuler un prochain coup:
	retract(gamestateTampon(_)),
	assert(gamestateTampon(GamestateEnCours)),

	%on simule le prochain coup possible
	simul(Joueur,ProfondeurEnCours,Queue,ListPoidsCoupsSuivants,CoupSuivantAssocie),

	append([PoidsCoupActuel],ListPoidsCoupsSuivants,ListPoids),
	meilleurCoup(ListPoids,PoidsCoupActuel,CoupActuel,CoupSuivantAssocie,MeilleurCoup).

meilleurCoup(ListPoids,PoidsCoupActuel,CoupActuel,_,MeilleurCoup):-
	max_member(MeilleurPoids,ListPoids),
	PoidsCoupActuel = MeilleurPoids, MeilleurCoup = CoupActuel,!.

meilleurCoup(ListPoids,PoidsCoupActuel,_,CoupSuivantAssocie,MeilleurCoup):-
	max_member(MeilleurPoids,ListPoids),
	not(PoidsCoupActuel = MeilleurPoids), MeilleurCoup = CoupSuivantAssocie,!.

%Principe de min: A un certain etat/configuration du jeu (GamestateEnCours) pour la profondeur d'arbre 'Profondeur'
% on renvoie le coup procurant un score Result minimum pour notre Joueur (en l'occurence l'IA) et correspondant au
% coup 'Coup' pour l'adversaire (Colonne jouee)
% NOTE: dans la realisation en s'en fout du Result c'est Coup qui sera interessant de recup pour la regle iaMinMax
min(GamestateEnCours,Joueur,Profondeur, Result):-
	not(Profondeur = 0),

	% selon la configuration du jeu, on recupere la ListeDeCoup possible
	coupPossible(GamestateEnCours,ListeDeCoup),

	% L'adversaire va simuler tout les coups possible et en prévoyant un nombre 'Profondeur'
	% de coup d'avance va donner dans la variable Result le pire score (poids) pour son adversaire associe au coup Coup
	simulAdversaire(Joueur,Profondeur,ListeDeCoup,ListPoids,_),
	min_member(Result,ListPoids).

%condition d'arret :
%lorsqu'on atteint la profondeur 0, on evalue la situation du jeu
min(GamestateEnCours,Joueur,0, Result):-
	eval(GamestateEnCours,Joueur,Result).

%condition d'arret :
%-infini represente le pire poid possible pour commencer nos comparaison
simulAdversaire(_,_,[],PirePoids,4):-
	PirePoids = [1000000].

% recursion interne dans min ou l'adversaire teste tous les coup possible et donne le poid du coup et le coup associe
simulAdversaire(Joueur,ProfondeurEnCours,ListeDeCoup,ListPoids,PireCoup):-
	ListeDeCoup = [CoupActuel|Queue],
	changerPion(Joueur,Adversaire),

	%sauvegarde du ctx actuel
	gamestateTampon(GamestateEnCours),

	simulationCoup(Adversaire,CoupActuel,NewGamestate),

	%sur la profondeur suivante, ça sera a l'IA de jouer et bien sur il jouera le coup lui donnant le plus gros score
	ProfondeurSuivante is ProfondeurEnCours-1,
	max(NewGamestate,Joueur,ProfondeurSuivante,PoidsCoupActuel),

	%on revient a la configuration du jeu en cours:
	retract(gamestateTampon(_)),
	assert(gamestateTampon(GamestateEnCours)),

	%on simule le prochain coup possible
	simulAdversaire(Joueur,ProfondeurEnCours,Queue,ListPoidsCoupsSuivants, CoupSuivantAssocie),

	append([PoidsCoupActuel],ListPoidsCoupsSuivants,ListPoids),
	pireCoup(ListPoids,PoidsCoupActuel,CoupActuel,CoupSuivantAssocie,PireCoup).

pireCoup(ListPoids,PoidsCoupActuel,CoupActuel,_,PireCoup):-
	min_member(PirePoids,ListPoids),
	PoidsCoupActuel = PirePoids, PireCoup = CoupActuel,!.

pireCoup(ListPoids,PoidsCoupActuel,_,CoupSuivantAssocie,PireCoup):-
	min_member(PirePoids,ListPoids),
	not(PoidsCoupActuel = PirePoids), PireCoup = CoupSuivantAssocie,!.

max(GamestateEnCours,Joueur,Profondeur, Result):-
	not(Profondeur = 0),

	% selon la configuration du jeu, on recupere la ListeDeCoup possible
	coupPossible(GamestateEnCours,ListeDeCoup),

	% L'IA va simuler tout les coups possible et en prévoyant un nombre 'Profondeur'
	% de coup d'avance va donner dans la variable Result le meilleur score (poids) associe au coup 'Coup'
	simul(Joueur,Profondeur,ListeDeCoup,ListPoids,_),
	max_member(Result,ListPoids).

%condition d'arret: lorsque max recoit en parametre la profondeur 0 c'est que l'adversaire ne doit plus regarder ce
% que pourrait jouer l'ia et evalue pour lui même le score qu'il effectuerais pour ce(son) dernier tour de jeu prémédité
max(GamestateEnCours,Joueur,0, Result):-
	eval(GamestateEnCours,Joueur,Result).


%Liste de regle fonctionnelle
init_gamestate:-
	gamestate(X),
	retract(gamestateTampon(_)),
	assert(gamestateTampon(X)).