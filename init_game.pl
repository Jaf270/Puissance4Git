%lancer la commande load_files(init_game). en ligne de cmd pour bien
% charger ce fichier

:-dynamic(gamestateTest/1).
 gamestate([[],[],[],[],[],[],[]]).

:-dynamic(gamestateTestTampon/1).
 gamestateTestTampon([[],[],[],[],[],[],[]]).

:-dynamic(gamestateTampon2/1).
 gamestateTampon2([[],[],[],[],[],[],[]]).

:-dynamic(gamestateTampon3/1).
 gamestateTampon3([[],[],[],[],[],[],[]]).

:-dynamic(gamestateTest/1).
 gamestateTest([[x],[x],[],[],[x],[o],[x]]).
 %gamestateTest([[],[],[x],[x],[],[],[]]).


%inclut les clauses des fichiers jouer.pl et aGagner.pl

:-use_module(library(random)).

:-include(jouer).
:-include(aGagner).
:-include(affichage).
:-include(verifications).
:-include(ia).
:-include(minMax).
:-include(partie2Joueurs).
:-include(pionsAlignes).
%:-include(partieAleatoire).

