//=============================================================================
// PropHunt
// Two teams; one team of hiders that are props that need to hide and not
// be found by the hunters. Hunters need to kill all the hiders within a 
// timelimit, though need to be careful...every missed shot hurts their
// teammates so shots must be controlled! If the hiders have at least one
// hider left when the time runs out or hunters all die, the hiders win! If the hiders 
// are all found and executed, the hunters win!
// pseudo
// 1 - Hiders get a minute(hidetime) to hide without the threat of hunters finding them
// 2 - After that hide time is up, the hunters are cut loose to search for the hiders
// 3 - Search time(roundtime) is about 3-6 minutes to allow hunters to find all the hiders
// 4 - When a player dies, they spectate until round over 
// 5 - Hiders win if time runs out and at least one is alive 
// 5a - Hiders also win if all hunters die - hunters lose health for any shots missed
// 5b - Hunters win if all hiders are killed 
//=============================================================================
class PropHunt extends TeamGamePlus config(PropHunt);

var bool 	bHuntersFroze; 	// are all hunters frozen? prevents loop from constantly setting accelrate=0.0
var bool 	bHuntersLoose;	// hunters no longer frozen, they can walk and kill 
var() config int 	CurrentHiderTeam;
var() config int 	CurrentHunterTeam;
var() config int 	HunterHealth; 	// depending on how difficult you want the game to be, changing hunter health can dramaticlly impact gameplay
var() config int 	HiderHealth;	// hunters cannot see full hider-player body, lower health can make it fair 
var() config int 	HideTime; 		// seconds 
var() config int 	RoundTime; 		// minutes
var() config int 	CurrentRound;	// the current round number config bc saved.
var() config int 	RoundsToWin;	// like score to win, goal to win 
var() config int 	TeamWins[2]; 
var() config int 	RestartRoundWait;
var PropHuntPRI 	PHRPinfo[16];
var PropHunt_Prop	player_props[16];
var int 			temp_hidetime;
var int 			old_hidetime;
var int 			RoundEndTime;
var bool 			bSingleHider;	// is there only one hider left, if not do special things
var TeamInfo 		HiderTeam,HunterTeam;
var bool 			bRestartingPlayers;
var int 			WinTeam;
var int				RemainingRoundTime;
var bool			bRoundStarted;

var Decoration Props[];

function PreBeginPlay()
{
	Super.PreBeginPlay();
	
	if(CurrentRound == 1) ResetGame(); // this is a double check if a server resets and the config isn't properly saved.
	
	if(RoundTime <= 0)
		RoundTime = 4;		
	if(HideTime <= 0)
		HideTime = 60;
	temp_hidetime = HideTime;
	RemainingRoundTime = RoundTime*60+HideTime;
}

function CheckReady() // original function creates timelimit if fraglimit and timelimit both equal zero
{
	if(FragLimit != 0) 
		FragLimit = 0;
	if(TimeLimit != 0) 
		TimeLimit = 0;
}

function PostBeginPlay()
{
	local int i;
	local PropHunt_Prop pp;
	for (i=0;i<2;i++){
		Teams[i] = Spawn(class'Botpack.TeamInfo');
		Teams[i].Size = 0;
		Teams[i].Score = 0;
		Teams[i].TeamName = TeamColor[i];
		Teams[i].TeamIndex = i;
		PropHuntGRI(GameReplicationInfo).Teams[i] = Teams[i];
	}
	
	Super.PostBeginPlay();
}

function InitGame(string Options, out string Error)
{
	local Inventory inv;
	Super.InitGame(Options,Error);
	foreach AllActors(class'Engine.Inventory', inv){
		inv.Destroy();
	}
}

simulated function HideProps(bool bHide)
{
	local int i;
	for(i = 0; i < 16; i++){
		if(player_props[i] != None){
			player_props[i].bOnlyOwnerSee = bHide;
		}else break;	
	}
}

function InitGameReplicationInfo()
{
	InitPHGameReplicationInfo();
}

function InitPHGameReplicationInfo()
{
	PropHuntGRI(GameReplicationInfo).RoundsToWin = RoundsToWin;
	PropHuntGRI(GameReplicationInfo).HiderHealth = HiderHealth;
	PropHuntGRI(GameReplicationInfo).HunterHealth = HunterHealth;
	PropHuntGRI(GameReplicationInfo).TeamWins[0] = TeamWins[0];
	PropHuntGRI(GameReplicationInfo).TeamWins[1] = TeamWins[1];
	PropHuntGRI(GameReplicationInfo).CurrentRound = CurrentRound;
	PropHuntGRI(GameReplicationInfo).CurrentHiderTeam = CurrentHiderTeam;
	PropHuntGRI(GameReplicationInfo).CurrentHunterTeam = CurrentHunterTeam;
	PropHuntGRI(GameReplicationInfo).RoundTime = RoundTime;
	PropHuntGRI(GameReplicationInfo).HideTime = HideTime;
	PropHuntGRI(GameReplicationInfo).RemainingRoundTime = RemainingRoundTime;
	log("_____________________________");
	log("| PROP HUNT SETTINGS LOADED |");
	log("CurrentHiderTeam = "@ CurrentHiderTeam);
	log("CurrentHunterTeam = "@ CurrentHunterTeam);
	log("TeamWins[0] = "@ TeamWins[0]);
	log("TeamWins[1] = "@ TeamWins[1]);
	log("RoundsToWin = "@ RoundsToWin);
	log("HiderHealth = "@ HiderHealth);
	log("HunterHealth = "@ HunterHealth);
	log("RemainingRoundTime = "@ RemainingRoundTime);
	log("RoundTime = "@ RoundTime);
	log("HideTime = "@ HideTime);
	log("CurrentRound = "@CurrentRound);
	log("_____________________________");
}

event PostLogin( playerpawn NewPlayer )
{
	Super.PostLogin(NewPlayer);

	if(!bRoundStarted){
		if ( (NewPlayer != None) && !NewPlayer.IsA('Spectator') && !NewPlayer.IsA('Commander') ){
			NewPlayer.PlayerReplicationInfo.Score = 1;
			AddDefaultInventory(NewPlayer);
		}
	} else {
		NewPlayer.PlayerReplicationInfo.Score = 0;
		NewPlayer.PlayerRestartState = 'PlayerSpectating';
		RestartPlayer(NewPlayer); // in restart player, since their score is 0, they'll be kicked into a temporary spectate mode until round is over.	
		DiscardInventory(NewPlayer);
	}
}

simulated function StartMatch()
{
	local TimedTrigger T;
	
	if( (!bGameEnded) || (!bRequireReady && !bGameEnded) ) {
		if (LocalLog != None)
			LocalLog.LogGameStart();
		if (WorldLog != None)
			WorldLog.LogGameStart();
		
		ForEach AllActors(class'TimedTrigger', T)
			T.SetTimer(T.DelaySeconds, T.bRepeating);
		if ( Level.NetMode != NM_Standalone )
			RemainingBots = 0;
		bStartMatch = true;
		
		bRoundStarted = false;
		
		StartRound();
	}
	bStartMatch = false;
}

simulated function RestartPlayers()
{
	local int i;
	local Pawn p;
	local inventory inv;
	if(!bGameEnded) {
		CurrentRound++;

		if(CurrentHiderTeam == 1){
			CurrentHiderTeam = 0;
			CurrentHunterTeam = 1;
		}else{
			CurrentHiderTeam = 1;
			CurrentHunterTeam = 0;
		}
		RoundEndTime = 0;
		RemainingRoundTime = HideTime+RoundTime*60;
		InitPHGameReplicationInfo();
		temp_hidetime = HideTime;

		PropHuntGRI(GameReplicationInfo).CurrentHiderTeam = CurrentHiderTeam;
		PropHuntGRI(GameReplicationInfo).CurrentHunterTeam = CurrentHunterTeam;
		StaticSaveConfig();
		StartRound();
		bRestartingPlayers = false;
	} 
	else{
		RestartGame();
	}
}

simulated function StartRound()
{
	local PropHunt_Prop pp;
	local Pawn p;
	local int i;
	local Carcass cc;	
	
	if(!bRoundStarted && !bGameEnded){ // stop any weird calls while in the middle of a round
		i = 0;
		log("__________________PROP HUNT ROUND STARTING_________________");
		
		foreach AllActors(class'Engine.Carcass', cc){
			cc.Destroy();
		}
		
		HiderTeam = Teams[CurrentHiderTeam];
		HunterTeam = Teams[CurrentHunterTeam];
		bHuntersLoose = false;
		bHuntersFroze = false;
		CalcTeamScores();
		if(!bHuntersFroze){ // if hunters not frozen, this means players not initialized @ && bStartMatch - only perform for loop if the match has started and the hide time started
			for ( P = Level.PawnList; P!=None; P=P.nextPawn ){ // freeze hunters during this 
				P.PlayerReplicationInfo.Score = 1;
				DiscardInventory(P);
				if(P.PlayerReplicationInfo.Team == CurrentHunterTeam){ // is a hunter 	
					if(PlayerPawn(P) != None){
						P.PlayerRestartState = 'PlayerSpectating'; // hunters start off spectating
						RestartPlayer(P);
						PlayerPawn(P).ReceiveLocalizedMessage(class'PropHuntStartMessage',5,PlayerPawn(P).PlayerReplicationInfo,,self);
						PlayerPawn(P).bShowScores = false;
					} else if(Bot(P) != None) {
						P.PlayerRestartState = 'GameEnded';
						RestartPlayer(P);
					}
				}
				else{	// hiders
					P.PlayerRestartState = 'PlayerWalking'; // hiders start off walking unlike hunters
					RestartPlayer(P);
					P.SetCollision( true, true, true );
					P.Health = HiderHealth; // invisibility below 
					P.SetDisplayProperties(ERenderStyle.STY_Translucent, Texture'Botpack.Ammocount.miniammoledbase', true, true);
					if(PlayerPawn(P) != None){
						PlayerPawn(P).ReceiveLocalizedMessage(class'PropHuntStartMessage',5,PlayerPawn(P).PlayerReplicationInfo,,self);
						PlayerPawn(P).bShowScores = false;
					}
				}
			}
			bHuntersFroze = true; // just went through pawn list and set all beginning attributes, stop executing.
			foreach AllActors(class'PropHunt_Prop', pp){
				player_props[i] = pp;
				i++;
			}
		}
		HideProps(true);
		bRoundStarted = true;
	}
}

function AddDefaultInventory( pawn PlayerPawn )
{
	local inventory Inv;
	local int i;
	local Weapon weap;
		
	if ( PlayerPawn.IsA('Spectator') || (bRequireReady && (CountDown > 0)) ){
		return;
	}
	// if player is a hunter, alive, and is loose ( not in hide time )
	if(PlayerPawn.PlayerReplicationInfo.Team == CurrentHunterTeam && bHuntersLoose && PlayerPawn.PlayerReplicationInfo.Score != 0){
		GiveWeapon(PlayerPawn, "PropHunt.PropHuntWeapon");
		PlayerPawn.SwitchToBestWeapon();
		for ( inv=PlayerPawn.inventory; inv!=None; inv=inv.inventory ){
			weap = Weapon(inv);
			if ( (weap != None) && (weap.AmmoType != None) )
				weap.AmmoType.AmmoAmount = weap.AmmoType.MaxAmmo;
		}	
	} else if(PlayerPawn.PlayerReplicationInfo.Team == CurrentHiderTeam){ // hiders get their prop objec
		GiveWeapon(PlayerPawn, "PropHunt.PropHuntSelector");
		PlayerPawn.SwitchToBestWeapon();
	}
}

function bool RestartPlayer( pawn aPlayer )	
{
	local NavigationPoint startSpot;
	local bool foundStart;
	local Pawn P;

	if( bRestartLevel && Level.NetMode!=NM_DedicatedServer && Level.NetMode!=NM_ListenServer )
		return true;

	if ( aPlayer.PlayerReplicationInfo.Score < 1 && !bRestartingPlayers){
		if ( aPlayer.IsA('Bot') ){
			aPlayer.PlayerReplicationInfo.bIsSpectator = true;
			aPlayer.PlayerReplicationInfo.bWaitingPlayer = true;
			aPlayer.PlayerRestartState = 'GameEnded';
			return false; // bots don't respawn when ghosts
		}
	}

	startSpot = FindPlayerStart(None, 255);
	if( startSpot == None )
		return false;
		
	foundStart = aPlayer.SetLocation(startSpot.Location);
	if(bRestartingPlayers && foundStart){ // resetting the players for a new round 
		aPlayer.PlayerReplicationInfo.Score = 1; // score is now 1
		if(aPlayer.PlayerReplicationInfo.Team == CurrentHiderTeam){ // hiders 
			aPlayer.Health = HiderHealth;
		} else { // hunters 
			aPlayer.Health = HunterHealth;
		}			
	}
	if( foundStart ){
		startSpot.PlayTeleportEffect(aPlayer, true);
		aPlayer.SetRotation(startSpot.Rotation);
		aPlayer.ViewRotation = aPlayer.Rotation;
		aPlayer.Acceleration = vect(0,0,0);
		aPlayer.Velocity = vect(0,0,0);
		aPlayer.Health = aPlayer.Default.Health;
		aPlayer.ClientSetRotation( startSpot.Rotation );
		aPlayer.bHidden = false;
		aPlayer.SetCollisionSize(17.0, 39.0);
		aPlayer.SoundDampening = aPlayer.Default.SoundDampening;
		if ( aPlayer.PlayerReplicationInfo.Score != 1){ // for dead guys 
			aPlayer.bHidden = true;
			aPlayer.PlayerRestartState = 'PlayerSpectating';
		} 
		else{ // for starting new dudes 
			aPlayer.PlayerReplicationInfo.bIsSpectator = false;
			aPlayer.PlayerReplicationInfo.bWaitingPlayer = false;
			aPlayer.SetCollision( true, true, true );
			if(PlayerPawn(aPlayer) != None){
				//PlayStartUpMessage(PlayerPawn(aPlayer));
				PlayerPawn(aPlayer).ViewTarget = none;
				PlayerPawn(aPlayer).bBehindView = false;	
			}
			if(aPlayer.PlayerReplicationInfo.Team == CurrentHunterTeam)
				aPlayer.SetDefaultDisplayProperties();
			AddDefaultInventory(aPlayer);
			
			// A I
			if(Bot(aPlayer) != None && Bot(aPlayer).PlayerReplicationInfo.Team == CurrentHunterTeam) {
				SetBotOrders(Bot(aPlayer));
			}
		}
	}
	//log("Setting player "@ aPlayer @" to the state: "@ aPlayer.PlayerRestartState);
	aPlayer.GoToState(aPlayer.PlayerRestartState);
	if(Bot(aPlayer) != None) {
		Bot(P).SetMovementPhysics();
		ModifyBehaviour(Bot(P));
	}
	return foundStart;
}

simulated function Timer()
{
	local Pawn P;
	local bool bReady;
	local int i;
	local PropHunt_Prop pp;
	local int M;
	
	SentText = 0;
		
    if ( bNetReady ){
        if ( NumPlayers > 0 )
            ElapsedTime++;
        else
            ElapsedTime = 0;
        if ( ElapsedTime > NetWait ){
            if ( (NumPlayers + NumBots < 4) && NeedPlayers() )
                AddBot();
            else if ( (NumPlayers + NumBots > 1) || ((NumPlayers > 0) && (ElapsedTime > 2 * NetWait)) )
                bNetReady = false;
        }

        if ( bNetReady ){
            for (P=Level.PawnList; P!=None; P=P.NextPawn )
                if ( P.IsA('PlayerPawn') )
                    PlayerPawn(P).SetProgressTime(2);
            return;
        }
        else{
            while ( NeedPlayers() )
                AddBot();
            bRequireReady = false;
            StartMatch();
        }
    }
	
    if ( bRequireReady && (CountDown > 0) ){
		RemainingBots = MinPlayers - (NumPlayers+NumBots);
        while ( (RemainingBots > 0) && AddBot() ){
            RemainingBots--;
		}
        for (P=Level.PawnList; P!=None; P=P.NextPawn ){
            if ( P.IsA('PlayerPawn') )
                PlayerPawn(P).SetProgressTime(2);
		}
        if ( RemainingBots <= 0 ){   
            bReady = true;
            for (P=Level.PawnList; P!=None; P=P.NextPawn ){
                if ( P.IsA('PlayerPawn') && !P.IsA('Spectator') && !PlayerPawn(P).bReadyToPlay ){
                    bReady = false;		
				}
			}
            if ( bReady ){   
                StartCount = 30;
                CountDown--;
                if ( CountDown <= 0 )
                    StartMatch();
                else{
                    for ( P = Level.PawnList; P!=None; P=P.nextPawn ){
                        if ( P.IsA('PlayerPawn') ){
                            PlayerPawn(P).ClearProgressMessages();
                            if ( (CountDown < 11) && P.IsA('TournamentPlayer') )
                                TournamentPlayer(P).TimeMessage(CountDown);
                            else
                                PlayerPawn(P).SetProgressMessage(CountDown$CountDownMessage, 0);
                        }
					}
                }
            }
            else if ( StartCount > 8 ) {
                for ( P = Level.PawnList; P!=None; P=P.nextPawn ){
                    if ( P.IsA('PlayerPawn') ){
                        PlayerPawn(P).ClearProgressMessages();
                        PlayerPawn(P).SetProgressTime(2);
                        PlayerPawn(P).SetProgressMessage(WaitingMessage1, 0);
                        PlayerPawn(P).SetProgressMessage(WaitingMessage2, 1);
                        if ( PlayerPawn(P).bReadyToPlay )
                            PlayerPawn(P).SetProgressMessage(ReadyMessage, 2);
                        else
                            PlayerPawn(P).SetProgressMessage(NotReadyMessage, 2);
                    }
				}
            }
            else{
                StartCount++;
                if ( Level.NetMode != NM_Standalone )
                    StartCount = 30;
            }
        }
        else{
            for ( P = Level.PawnList; P!=None; P=P.nextPawn )
                if ( P.IsA('PlayerPawn') )
                    PlayStartupMessage(PlayerPawn(P));
        }
    }   
    else{
        if ( bAlwaysForceRespawn || (bForceRespawn && (Level.NetMode != NM_Standalone)) )
            For ( P=Level.PawnList; P!=None; P=P.NextPawn ){
                if ( P.IsInState('Dying') && P.IsA('PlayerPawn') && P.bHidden )
                    PlayerPawn(P).ServerReStartPlayer();
            }
        if ( Level.NetMode != NM_Standalone ){
            if ( NeedPlayers() )
                AddBot();
        }
        else
            while ( (RemainingBots > 0) && AddBot() )
                RemainingBots--;
		if(!bGameEnded){
			ElapsedTime++;
			GameReplicationInfo.ElapsedTime = ElapsedTime;
		}
    }
	
	if(bRoundStarted){
		RemainingRoundTime--;
		PropHuntGRI(GameReplicationInfo).RemainingRoundTime = RemainingRoundTime;
		temp_hidetime = RemainingRoundTime-(60*RoundTime);	
		if(temp_hidetime >= 0)
		{ // in hide time
			if(!bHuntersLoose && temp_hidetime > 0) 
			{  // hunters are not loose, hidetime is in progress
				if(bHuntersFroze)
				{
					for ( P = Level.PawnList; P!=None; P=P.nextPawn )
					{
						if(old_hidetime != temp_hidetime) { // if this check is not here, each second of the countdown gets called about 5 times each in log
							BroadcastMessage("Hunters loose in "$temp_hidetime, false, 'CriticalEvent');	// count down
							old_hidetime = temp_hidetime;
						}
						if(temp_hidetime <= 5 && PlayerPawn(P) != None)
							PlayerPawn(P).ClientPlaySound(Sound(DynamicLoadObject("UnrealShare.SeekLock", class'Sound')), true, true);
					}
				}
			} else ReleaseHunters();	 // release the hunters!
		}
	}
	else {
		if( (RoundEndTime != 0) && (Level.TimeSeconds - RoundEndTime) > RestartRoundWait && !bGameEnded ){ // i want to give 15 seconds of sort of an 'intermission"t
			RestartPlayers();
		} else if(bGameEnded) {
			RestartGame();
		}
	}	
	if(RemainingRoundTime <= 0)
		CheckEndRound();
	
}

simulated function ReleaseHunters()
{
	local Pawn P;
	
	bHuntersLoose = true;
	bHuntersFroze = false;
	for ( P = Level.PawnList; P!=None; P=P.nextPawn ){
		if(P.PlayerReplicationInfo.Team == CurrentHiderTeam){
			P.Health = HiderHealth; // reset
		}
		else{ // is a hunter 
			if(Bot(P) != None)
				Bot(P).PlayerRestartState = 'Attacking';
			else
				P.PlayerRestartState = 'PlayerWalking';
			RestartPlayer(P);				// restart
		}
	}
	BroadcastMessage("Hunters are loose!!!", false, 'CriticalEvent');	
	HideProps(false); // unhide props
}

function CalcTeamScores()
{
	local Pawn P;

	Teams[CurrentHiderTeam].Score = 0; // reset scores for the recount below 
	Teams[CurrentHunterTeam].Score = 0;
	for ( P = Level.PawnList; TournamentPlayer(P)!=None || Bot(P) != None; P=P.nextPawn ){
		if (P.PlayerReplicationInfo.Team != 255){
			Teams[P.PlayerReplicationInfo.Team].Score += P.PlayerReplicationInfo.Score;
		}
	}
}

function bool SetEndCams(string Reason)
{
	local pawn P,Best;
	
	for ( P=Level.PawnList; P != none; P=P.nextPawn ){
		if ( (P.PlayerReplicationInfo.Team == WinTeam) && (P.PlayerReplicationInfo.Score == 1) ){
			Best = P;
		}
        if ( PlayerPawn(P) != None ){
            if (!bTutorialGame)
                PlayWinMessage(PlayerPawn(P), (PlayerPawn(P).PlayerReplicationInfo.Team == WinTeam));
            PlayerPawn(P).bBehindView = true;
            if ( PlayerPawn(P) == Best )
                PlayerPawn(P).ViewTarget = None;
            else
                PlayerPawn(P).ViewTarget = Best;
            PlayerPawn(P).ClientGameEnded();
        }
        P.GotoState('GameEnded'); //restart rounds
	}

	PropHuntGRI(GameReplicationInfo).TeamWins[0] = TeamWins[0];
	PropHuntGRI(GameReplicationInfo).TeamWins[1] = TeamWins[1];
	StaticSaveConfig();
	if(Reason != "roundend"){
		CalcEndStats();
	}
    return true;
}

function RestartGame()
{
	local int i;
	if ( !bGameEnded || (EndTime > Level.TimeSeconds) ) // still showing end screen
		return;
		
	Super.RestartGame();
}

function CheckEndRound()
{
	if(bRoundStarted){
		if(Teams[CurrentHiderTeam].Score > 0 && RemainingRoundTime < 1) // if there is at least one hunter alive and the time ran out...
			EndRound("timereached");											// hiders win
			
		else if(Teams[CurrentHiderTeam].Score <= 0) // no hiders, theyve all been found, hunters win
			EndRound("hidersfound");

		else if(Teams[CurrentHunterTeam].Score <= 0) // no hunters, they died, hiders win
			EndRound("huntersdied");
	}
}

function AddToTeam(int num, Pawn Other)
{
	Super.AddToTeam(num,Other);
}

function EndGame( string Reason)
{
	EndTime = Level.TimeSeconds + 10;
	ResetGame();
	InitPHGameReplicationInfo();
	Super.EndGame(Reason);
}

function EndRound( string Reason)
{
	local string final_end_reason;
	if(Reason == "hidersfound"){ // hunters won
		WinTeam = CurrentHunterTeam;
	}
	else if(Reason == "timereached"){ // hiders won
		WinTeam = CurrentHiderTeam;
	}
	else if(Reason == "huntersdied"){ // hiders won
		WinTeam = CurrentHiderTeam;
	}
	TeamWins[WinTeam] += 1; // add 1 to the winning team's config score
	
	
	bRoundStarted = false;
	if (TeamWins[WinTeam] == RoundsToWin) { // search array, if a team has the amount of rounds to win, END THE GAME
		if(WinTeam == 0) 
			final_end_reason = "red";
		else 
			final_end_reason = "blue";
		EndGame(final_end_reason);
	} else {
		RoundEndTime = Level.TimeSeconds;
		SetEndCams("roundend");
		//RestartPlayers();
	}
}

static function ResetGame()
{
	Default.TeamWins[0] = 0;
	Default.TeamWins[1] = 0;
	Default.CurrentRound = 1;
	Default.CurrentHiderTeam = 0;
	Default.CurrentHunterTeam = 1;
	StaticSaveConfig();
}

event playerpawn Login
(
	string Portal,
	string Options,
	out string Error,
	class<playerpawn> SpawnClass
)
{
	local playerpawn NewPlayer;

	NewPlayer = Super.Login(Portal, Options, Error, SpawnClass);
	if(NewPlayer.PlayerReplicationInfo != None){
		PHRPinfo[NumPlayers] = Spawn(class'PropHuntPRI');
		PHRPinfo[NumPlayers].PlayerID = NewPlayer.PlayerReplicationInfo.PlayerID;
		log("spawning "@ PHRPinfo[NumPlayers] @" for "@ NewPlayer);
	}
	
	return NewPlayer;
}

function Logout( pawn Exiting )
{
	local int i;
	
	if(PlayerPawn(Exiting) != None){
		for(i = 0; i <= NumPlayers; i++){
			if(Exiting.PlayerReplicationInfo.PlayerID == PHRPinfo[i].PlayerID){
				PHRPinfo[i].Destroy();
				PHRPinfo[i] = none;
			}
		}
	}
	Super.Logout(Exiting);
}
function PropHuntPRI GetStats(playerpawn p)
{
	local int i;
	log("i want stats for "@ p);
	if(p.PlayerReplicationInfo != None){
		for(i = 0; i <= 16; i++){
			if(p.PlayerReplicationInfo.PlayerID == PHRPinfo[i].PlayerID)
				return PHRPinfo[i];
		}
	}
}

function ScoreKill(pawn Killer, pawn Other)
{
	Other.DieCount++;
	if (Other.PlayerReplicationInfo.Score > 0)
		Other.PlayerReplicationInfo.Score -= 1;
	if( (killer != Other) && (killer != None) )
		killer.killCount++;

	CalcTeamScores();
	CheckEndRound();
	BaseMutator.ScoreKill(Killer, Other);
}	

function Killed(pawn killer, pawn Other, name damageType)
{
	local int NextTaunt, i;
    local bool bAutoTaunt, bEndOverTime;
    local Pawn P, Best;
	local PropHuntPRI PHPRI;

    Super.Killed(killer, Other, damageType);

    
    if ( (killer == None) || (Other == None) )
        return;
	if ( Killer.bIsPlayer && (Killer != Other) )
		if (!Self.IsA('TrainingDM')){
			BroadcastLocalizedMessage( class'PropHuntKilledMessage', 0, Killer.PlayerReplicationInfo, Other.PlayerReplicationInfo );
		}
	// prop hunt player replication info
	if(Other.PlayerReplicationInfo.Team == CurrentHiderTeam){
		if(PlayerPawn(Other) != None){
			PHPRI = GetStats(PlayerPawn(Other));
			if(PHPRI != None)
				PHPRI.HideSec += (RoundTime * 60) - RemainingRoundTime;
		}		
		if(PlayerPawn(Killer) != None){
			PHPRI = GetStats(PlayerPawn(Killer));
			if(PHPRI != None)
				PHPRI.HidersFound++;
		}
	}
	
    if ( BotConfig.bAdjustSkill && (killer.IsA('PlayerPawn') || Other.IsA('PlayerPawn')) )
    {
        if ( killer.IsA('Bot') )
            BotConfig.AdjustSkill(Bot(killer),true);
        if ( Other.IsA('Bot') )
            BotConfig.AdjustSkill(Bot(Other),false);
    }

    bAutoTaunt = ((TournamentPlayer(Killer) != None) && TournamentPlayer(Killer).bAutoTaunt);
    if ( ((Bot(Killer) != None) || bAutoTaunt)
        && (Killer != Other) && (DamageType != 'gibbed') && (Killer.Health > 0)
        && (Level.TimeSeconds - LastTauntTime > 3) )
    {
        LastTauntTime = Level.TimeSeconds;
        NextTaunt = Rand(class<ChallengeVoicePack>(Killer.PlayerReplicationInfo.VoiceType).Default.NumTaunts);
        for ( i=0; i<4; i++ )
        {
            if ( NextTaunt == LastTaunt[i] )
                NextTaunt = Rand(class<ChallengeVoicePack>(Killer.PlayerReplicationInfo.VoiceType).Default.NumTaunts);
            if ( i > 0 )
                LastTaunt[i-1] = LastTaunt[i];
        }   
        LastTaunt[3] = NextTaunt;
        killer.SendGlobalMessage(None, 'AUTOTAUNT', NextTaunt, 5);
    }
    if ( bRatedGame )
        RateVs(Other, Killer);
}

function bool PickupQuery( Pawn Other, Inventory item )
{
	if ( Other.PlayerReplicationInfo.Team == CurrentHiderTeam)
		return false;
	else
		return Super.PickupQuery( Other, item );
}


function ShowTeamMessage(PlayerPawn theplayer)
{
	theplayer.ClearProgressMessages();
	theplayer.SetProgressColor(class'ChallengeTeamHUD'.Default.TeamColor[theplayer.PlayerReplicationInfo.Team], 0);
	if(theplayer.PlayerReplicationInfo.Team == CurrentHiderTeam)
		theplayer.SetProgressMessage(StartupTeamMessage@"HIDER"$StartupTeamTralier, 1);
	else if(theplayer.PlayerReplicationInfo.Team == CurrentHunterTeam)
		theplayer.SetProgressMessage(StartupTeamMessage@"HUNTER"$StartupTeamTralier, 1);
	theplayer.SetProgressColor(class'ChallengeTeamHUD'.Default.TeamColor[theplayer.PlayerReplicationInfo.Team], 0);
}

function PlayStartUpMessage(PlayerPawn NewPlayer)
{
	local int i;
	local color WhiteColor;

	NewPlayer.ClearProgressMessages();

	NewPlayer.SetProgressMessage(GameName, i++);
	if ( bRequireReady && (Level.NetMode != NM_Standalone) )
		NewPlayer.SetProgressMessage(TourneyMessage, i++);
	else
		NewPlayer.SetProgressMessage(StartUpMessage, i++);
		
	if ( NewPlayer.PlayerReplicationInfo.Team < 4 ){
		NewPlayer.SetProgressColor(class'ChallengeTeamHUD'.Default.TeamColor[NewPlayer.PlayerReplicationInfo.Team], i);
		if(NewPlayer.PlayerReplicationInfo.Team == CurrentHiderTeam)
			NewPlayer.SetProgressMessage(StartupTeamMessage@"HIDER"$StartupTeamTralier, i++);
		else if(NewPlayer.PlayerReplicationInfo.Team == CurrentHunterTeam)
			NewPlayer.SetProgressMessage(StartupTeamMessage@"HUNTER"$StartupTeamTralier, i++);
		WhiteColor.R = 255;
		WhiteColor.G = 255;
		WhiteColor.B = 255;
		NewPlayer.SetProgressColor(WhiteColor, i);
		if ( !bRatedGame)
			NewPlayer.SetProgressMessage(TeamChangeMessage, i++);
	}

	if ( Level.NetMode == NM_Standalone )
		NewPlayer.SetProgressMessage(SingleWaitingMessage, i++);
}
/// A.I.

function ModifyBehaviour(Bot NewBot)
{
	Super.ModifyBehaviour(NewBot);
}

function SetBotOrders(Bot aBot){
	if(aBot.PlayerReplicationInfo.Team == CurrentHunterTeam){
		aBot.bWantsToCamp = false;
		aBot.CampingRate = 0.0;
		aBot.SetOrders('Attack',aBot);
		aBot.GotoState('Attacking');
	} else if(aBot.PlayerReplicationInfo.Team == CurrentHiderTeam){
		aBot.bWantsToCamp = true;
		aBot.CampingRate = 1.0;
		aBot.SetOrders('Hold',aBot);
	}
}

function bool FindSpecialAttractionFor(Bot aBot)
{
	local Decoration d;
	
	if(aBot.PlayerReplicationInfo.Team == CurrentHiderTeam){
		//if(aBot.LastAttractCheck - Level.TimeSeconds > 10){
			//aBot.LastAttractCheck = Level.TimeSeconds;
			foreach aBot.VisibleActors(class'Decoration', d, 512.0){
				//LOG("I SEE A "$d);
				if(FRand() < 0.2){
					//log(aBot$"i see a "$ d $" so imma shoot it");
					aBot.Target = d;
					aBot.GotoState('RangedAttack');
				}
			}
		//}
	}	
}

defaultproperties
{
	bMuteSpectators=true
	bRestartingPlayers=false
	//TeamWins[0]=0
	//TeamWins[1]=0
	GoalTeamScore=0
	CountDown=10
	bScoreTeamKills=true
	bTournament=true
	StartUpTeamMessage="You are a"
	FragLimit=0
	TimeLimit=0
	RestartRoundWait=15
	bHuntersLoose=false
	bSingleHider=false
	bAlwaysRelevant=True
    RemoteRole=ROLE_SimulatedProxy
    StartUpMessage="Have fun"
    bTeamGame=True
	GameReplicationInfoClass=Class'PropHuntGRI'
    ScoreBoardType=Class'PropHuntScoreBoard'
    RulesMenuType="PropHunt.PropHuntRSClient"
    SettingsMenuType="PropHunt.PropHuntSSClient"
    HUDType=Class'PropHuntHUD'
    BeaconName="PH"
	MapPrefix="PH"
    GameName="Prop Hunt"
	HideTime=10
	RoundTime=3
	HiderHealth=50
	HunterHealth=100
	RoundsToWin=7
	CurrentRound=1
	CurrentHiderTeam=0
	CurrentHunterTeam=1
	TeamWins(0)=0
	TeamWins(1)=0
}