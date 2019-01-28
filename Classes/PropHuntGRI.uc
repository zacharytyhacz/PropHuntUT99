class PropHuntGRI extends TournamentGameReplicationInfo;

var int CurrentHiderTeam;
var int CurrentHunterTeam;
var int TeamWins[2];
var int RoundsToWin;
var int HiderHealth;
var int HunterHealth;
var int RoundTime;
var int HideTime;
var int RemainingRoundTime;
var int CurrentRound;


replication
{
	reliable if ( Role == ROLE_Authority )
		CurrentHiderTeam, CurrentHunterTeam, TeamWins,
		RoundsToWin, HiderHealth, HunterHealth, RoundTime, HideTime, CurrentRound, RemainingRoundTime;
}

defaultproperties
{
}