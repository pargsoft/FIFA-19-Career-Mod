function Trigger_AboutToInitMode()
	isFinalVar = Engine.IsFinal()
	local userTeam = Engine.GetUserTeam()
	local seasonNumber = 0
	NewJob_JobChanged( seasonNumber, false, -1, userTeam, false, false, false )
	if( Engine.UserNationalityHasTeam() == true ) then
		InternationalTeaser()
	end
end

function Trigger_PostLoadEvent()
	isFinalVar = Engine.IsFinal()
end

function Trigger_NewSeasonStarted( seasonNumber )


	require "logging.file"

	local logger = logging.file("c:\\v2k4test%s.log", "%Y-%m-%d")

	logger:info("logging.file test")
	logger:debug("debugging...")
	logger:error("error!")


	local storyId = "NEWPLAYER"
	local storyActive = Engine.IsStoryIDActive( storyId )
	if( storyActive == true ) then
		local currentStory = Engine.GetStoryById( storyId )
		local fromTeam = tonumber( Engine.GetStoryVariable( currentStory ) )
		if( fromTeam < 1 ) then
			local playerId = Engine.GetPlayAsPlayerID()
			local toTeam = Engine.GetTeamIdFromPlayerId( playerId )
			StartStory_NewSigning( toTeam, fromTeam, playerId )
			Engine.EndStoryId( storyId, false )
		end
	end
end

function Trigger_AboutToSwitchJob( seasonNumber, isLoanReturn, fromTeam, toTeam, wasFired, isLoan, retiring )
	Engine.EndAllStoriesForTeam( fromTeam, false )
	Engine.EndStoryCategory( "LOST", false )
	Engine.EndStoryCategory( "SIGNING", false )
	Engine.EndStoryCategory( "INJURY", false )
	Engine.EndStoryCategory( "SUSPENSION", false )
	Engine.KillAllDynamicEvents()
	if( isLoan == false ) then
		Engine.EndStoryCategory( "JOBCHANGE", false )
	end
	NewJob_JobChanged( seasonNumber, isLoanReturn, fromTeam, toTeam, wasFired, isLoan, retiring )
end 

function Trigger_JobChanged( seasonNumber, isLoanReturn, fromTeam, toTeam, wasFired, isLoan )
	SeasonPreviewJobChanged()
end

function Trigger_MainCompetitionScheduled()
	Engine.AddDateEvent( "SSNPRVDAY1", 2 )
	-- ExamineFor_RetiringPlayer()  NOTE: Retiring player currently removed
end

function Trigger_PreSeasonComplete()
	HasRecoveringPlayerTrigger()
end

function Trigger_PostUserGame( matchResult, gametype, playType, matchSituationTypes )	
	local isInPreSeason = Engine.IsInPreSeason()
	if( isInPreSeason == false ) then
		PUG_CheckPreSeasonFormStory( matchResult, gametype )
	end --if( isInPreSeason == false ) then
	-- ExamineForRetiringPlayer( matchResult, gametype )  NOTE: Retiring player currently removed
	NewJob_PostMatch( matchResult, gametype, playType )
	ManagerJobOffers_PostMatch( matchResult, gametype, playType )
	ExamineResultForIncident( matchResult, gametype, playType )
	if( string.find( gametype, "INTERNATIONAL" ) == nil ) then
		InjuredPlayerRecoveredStoryLine( matchResult, gametype )
		LowEnergyAppealMatch( matchResult )
		PlayerOnBenchPostMatch( matchResult, gametype, playType )
		PFR_Stage2_PostMatch( matchResult, gametype, playType )
		PlayerCriticizes_Stages( matchResult, gametype, playType )
		PostMatch_PlayerVsFormerTeam( matchResult, gametype, playType )
		ExamineFor_StarInPoorForm( matchResult, gametype, playType )
		ReserveRequest_PostMatch( matchResult, gametype, playType )
		ExamineFor_FoulLanguage( matchResult, gametype, playType )
		NewSigningPostMatch( matchResult, gametype, playType )
		PostMatch_ReverseFixture( matchResult, gametype, playType )
		PostMatch_Streak( matchResult, gametype, playType )
		ImportantPostUserGame( matchResult, gametype, playType, matchSituationTypes )
	end
end

function Trigger_PostUserInternationalGame( matchResult, gametype, playType )
	NewJob_PostMatch( matchResult, gametype, playType )
end

function Trigger_PostCPUGame( matchResult, gametype )	
	ExamineResultForIncident( matchResult, gametype, "SIMMED" )
end

function Trigger_UserTeamPlayerFormChange( numPlayers, playerId1, formString1, playerId2, formString2, playerId3, formString3 )
	if( numPlayers > 0 ) then
		local playersList = { playerId1, playerId2, playerId3 }
		local formList = { formString1, formString2, formString3 }
		local userTeam = Engine.GetUserTeam()
		for playerCount = 1, numPlayers do
			local playerId = playersList[ playerCount ]
			local formString = formList[ playerCount ]
			if( playerId > 0 ) then
				if( Engine.IsInPreSeason() == true ) then
					ExamineFor_PreSeasonForm( userTeam, playerId, formString )
				end
				local involved = Engine.IsPlayerInvolvedInStoryCategory( playerId, "SIGNING" )
				if( involved == true ) then
					NewSigning_FormChange( userTeam, playerId, formString )
				else
					ExamineFor_FormChange( userTeam, playerId, formString )
				end
			end
		end
	end
end

function Trigger_PlayerInjury( teamId, playerId, severity, returnDate )
	-- RetiringPlayerInjury( teamId, playerId, severity, returnDate )  NOTE: Retiring player currently removed
	ExamineFor_PNFR( teamId, playerId, severity, returnDate )
	PlayerSagaInjuryEnding( teamId, playerId, severity, returnDate )
end

function Trigger_UserTeamKnockedOutOfCup()

end

function Trigger_UserTeamAdvanceNextRound( numAdvancingTeams )
	-- RetiringPlayerAdvanceInCup( numAdvancingTeams )  NOTE: Retiring player currently removed
end

function Trigger_HourPassed( hoursRemaining )
	-- deadlineDayPassedLMTR( hoursRemaining )  NOTE: LMTR currently removed
end

function Trigger_DynamicEvent( eventId, linkId )
	-- RetiringDynamicEvent( eventId, linkId )           NOTE: Retiring player currently removed
	SeasonPreviewDynamicEvent( eventId, linkId )
	LoanListedDynamicEvent( eventId, linkId )
	TransferListedDynamicEvent( eventId, linkId )
	-- ForeignUpsetStoryDynamicEvent( eventId, linkId )  NOTE: Foreign upset player currently removed
	-- ContractRebelDynamicEvent( eventId, linkId )      NOTE: Contract rebel currently removed
	-- LMTRDynamicEvent( eventId, linkId )               NOTE: LMTR currently removed
	InvestorDynamicEvent( eventId, linkId )
	PlayTimeHappinessDynamicEvent( eventId, linkId )
	SagaEndingDynamicEvent( eventId, linkId )
	NewSigningDynamicEvent( eventId, linkId )
	PFR_DynamicEvent( eventId, linkId )
	LostPlayerDynamicEvent( eventId, linkId )
	-- WeakSpot_DynamicEvent( eventId, linkId )          NOTE: Weak player replacement currently removed
	DynamicEvent_CounterOffer( eventId, linkId )
	MoveRequest_DynamicEvent( eventId, linkId )
	JobOffer_DynamicEvent( eventId, linkId )
	FoulLaunguage_DynamicEvent( eventId, linkId )
	-- UnhappyWithWage_DynamicEvent( eventId, linkId )   NOTE: Player upset with wage currently removed
end

function Trigger_NumDaysBeforeUserGame( numDays, gametype, fixture )
	NewJob_PreMatch( numDays, gametype, fixture )
	if( string.find( gametype, "INTERNATIONAL" ) == nil ) then
		RecoveringPlayerDaysBeforeGame( numDays, gametype, fixture )
		PreSeasonFormPlayerDaysBeforeGame( numDays, gametype, fixture )
		ExamineFor_LEA( numDays, gametype, fixture )
		ExamineFor_POB( numDays, gametype, fixture )
		NewSigningPreMatch( numDays, gametype, fixture )
		ExamineFor_PlayerCriticizes( numDays, gametype, fixture )
		ExamineFor_PlayerVsFormerTeam( numDays, gametype, fixture )
		ExamineFor_ReservePlayerRequest( numDays, gametype, fixture )
		StarInPoorForm_PreMatch( numDays, gametype, fixture )
		ExamineFor_TalkToPress_CPU( numDays, gametype, fixture )
		ExamineFor_CPUForm( numDays, gametype, fixture )
		PreMatch_StartingXI( numDays, gametype, fixture )
		PreMatch_TopScorer( numDays, gametype, fixture )
		PreMatch_ReverseFixture( numDays, gametype, fixture )
		ExamineFor_InjuryStories( numDays, gametype, fixture )
		ExamineFor_SuspensionStories( numDays, gametype, fixture )
		PreMatch_Streak( numDays, gametype, fixture )
		PreMatch_5GameForm( numDays, gametype, fixture )
		ExamineFor_IMP( numDays, gametype, fixture )
	end
end

function Trigger_NumDaysBeforeLastLeagueGame( numDays )
	-- RetiringPlayerLastLeagueGame( numDays ) NOTE: Retiring player currently removed
end

function Trigger_EndOfSeasonDayReached()
--	ClearHappyUnhappyStories()
end

function Trigger_MonthPassed( months )
	-- ExamineFor_UFP( months )                NOTE: Foreign upset player currently removed
	ExamineFor_ForeignInvestor( months )
	PlayTimeUnhappinessMonthlyAppeal()
	-- MonthPassed_CPUContractRebel( months )  NOTE: Contract rebel currently removed
	local isPap = Engine.IsPlayAsPlayer()
	if( isPap == false ) then
		-- ExamineFor_WeakSpot( months )       NOTE: Weak player replacement currently removed
		if( Engine.IsStoryIDActive( "RENEW" ) == false ) then
			ExamineFor_InternationalManagerRumours( months )
		end
	end
end

function Trigger_TransferListedEventUserTeam( teamId, playerId, leagueId, marketValue, currency )
	local storyId = "TRANSREQUEST"
	local storyActive = Engine.IsStoryIDActive( storyId )
	local ifNotRequested = true
	if( storyActive == true ) then
		local player = Engine.GetPlayAsPlayerID()
		if( player == playerId ) then
			MoveRequest_Listed( teamId, playerId, leagueId, "TRANSFERED" )
			ifNotRequested = false
		end
	end
	local saga = IsPlayerInvolvedInSaga( playerId )
	if( saga == false ) then
		PoorRun_TransferListed( teamId, playerId, leagueId, marketValue, currency )
		if( ifNotRequested == true ) then
			ExamineFor_PlayerListed( teamId, playerId, leagueId, marketValue, currency )
		end
	end
	-- LMTRTransferListed( teamId, playerId, leagueId, marketValue, currency )  NOTE: LMTR currently removed
	PlayTimeListedPlayer( teamId, playerId, leagueId, marketValue, currency )
	PlayerCriticizes_TransferListed( teamId, playerId, leagueId, marketValue, currency )
	PFR_TransferListed( teamId, playerId, leagueId, marketValue, currency )
end

function Trigger_TransferListedEvent( teamId, playerId, leagueId, marketValue, currency )
	ExamineFor_PlayerListed( teamId, playerId, leagueId, marketValue, currency )
	-- LMTRTransferListed( teamId, playerId, leagueId, marketValue, currency )  NOTE: LMTR currently removed
end

function Trigger_TransferLoanListedEventUserTeam( teamId, playerId, leagueId )
	local storyId = "LOANREQUEST"
	local storyActive = Engine.IsStoryIDActive( storyId )
	local requested = false
	if( storyActive == true ) then
		local player = Engine.GetPlayAsPlayerID()
		if( player == playerId ) then
			MoveRequest_Listed( teamId, playerId, leagueId, "LOANED" )
			requested = true
		end
	end
	local saga = IsPlayerInvolvedInSaga( playerId )
	if( saga == false ) then
		if( requested == false ) then
			ExamineFor_PlayerLoanListed( teamId, playerId, leagueId )
		end
		PoorRun_LoanListed( teamId, playerId, leagueId )
	end
	PlayTimeListedPlayer( teamId, playerId, leagueId )
	PlayerCriticizes_LoanListed( teamId, playerId, leagueId )
	PFR_LoanListed( teamId, playerId, leagueId )
end

function Trigger_TransferLoanListedEvent( teamId, playerId, leagueId )
	ExamineFor_PlayerLoanListed( teamId, playerId, leagueId )
end

function Trigger_EnteringTeamManagement( method )
end

function Trigger_LeavingTeamManagement()
end

function Trigger_TransferMoveCompleteUserSell( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue, realDate )
	-- NOTE: Contract rebel currently removed
	-- ContractRebelTransferComplete( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue )
	
	-- NOTE: LMTR currently removed
	-- if( Engine.IsPlayerInvolvedInStoryCategory( playerId, "LOST" ) == false ) then
		-- if( Engine.IsPlayerInvolvedInStoryId( playerId, "LMTR_USR1" ) == true ) then
			-- PostSaleAudio_LMTR( playerId )
		-- end
	-- end
end

function Trigger_TransferMoveCompleteUserBuy( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue, realDate )
	if( sellingTeam ~= Tuning.TRANSFERS.exceptionSellingTeamId ) then
		ExamineFor_NewSigningCompleted( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue, realDate )
	end
	-- WeakSpot_TransferStage( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue )  NOTE: Weak player replacement currently removed
end

function Trigger_TransferMoveComplete( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue, realDate )
	-- ForeignUpsetStoryTransfered( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue )  NOTE: Foreign upset player currently removed
	InvestorClubPurchase( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue )
	-- ContractRebelTransferComplete( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue )  NOTE: Contract rebel currently removed
	
	-- NOTE: Last minute transfer disabled.
	-- if( Engine.IsPlayerInvolvedInStoryCategory( playerId, "LOST" ) == false ) then

		-- if( Engine.IsPlayerInvolvedInStoryId( playerId, "LMTR_USR1" ) == false ) then
			-- Engine.EndAllStoriesForPlayer( playerId )
		-- end
	-- end

end

function Trigger_TransferMoveAboutToCompleteUserSell( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue, realDate )
	StartStory_LostPlayer( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue, realDate )
	if( transfer == "TRANSFER" ) then
		if( sellingTeam ~= Tuning.TRANSFERS.exceptionSellingTeamId ) then
			if( price > 0 ) then
				ExamineFor_OverPricedDeal( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue )
			end
		end
	end
end

function Trigger_TransferMoveAboutToCompleteUserBuy( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue, realDate )
	if( transfer == "TRANSFER" ) then
		if( sellingTeam ~= Tuning.TRANSFERS.exceptionSellingTeamId ) then
			if( price > 0 ) then
				ExamineFor_OverPricedDeal( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue )
			end
		end
	end
end

-- NOTE: Must uncomment call from C++ to receive this.
-- function Trigger_TransferMoveAboutToComplete( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue, exchangeValue, realDate )
	-- LastMinTransferComplete( buyingTeam, sellingTeam, playerId, transfer, contract, price, wage, playerValue )  NOTE: LMTR currently removed
-- end

function Trigger_LiveTableUpdated()
	SeasonPreviewPostLoad()	
end

function Trigger_TransferBidRejected( buyingTeamId, playerId, marketValue, marketWage, moneyOffered, sellingTeamId )
	local userTeam = Engine.GetUserTeam()
	if( userTeam == buyingTeamId ) then
		ExamineFor_StupidBid( buyingTeamId, playerId, marketValue, marketWage, moneyOffered, sellingTeamId )
	end
	
	-- NOTE: Contract rebel currently removed
	-- if( userTeam == sellingTeamId ) then
		-- ContractRebelBidRejected( buyingTeamId, playerId, marketValue, marketWage, moneyOffered, sellingTeamId )
	-- end
end

function Trigger_TransferBidCounterRejected( buyingTeamId, playerId, sellingTeamId, moneyOffered, moneyDesired, counterOfferNum )
	RejectOffer_CounterOffer( buyingTeamId, playerId, sellingTeamId, moneyOffered, moneyDesired, counterOfferNum )
end

function Trigger_TransferBidRetracted( buyingTeamId, playerId, marketValue, marketWage, moneyOffered, sellingTeamId )
	-- NOTE: Contract rebel currently removed
	-- local userTeam = Engine.GetUserTeam()
	-- if( userTeam == sellingTeamId ) then
		-- ContractRebelBidRejected( buyingTeamId, playerId, marketValue, marketWage, moneyOffered, sellingTeamId )
	-- end
end

function Trigger_TransferBidCounterOffer( buyingTeamId, playerId, sellingTeamId, moneyOffered, moneyDesired, counterOfferNum )
	ExamineFor_CounterOffer( buyingTeamId, playerId, sellingTeamId, moneyOffered, moneyDesired, counterOfferNum )
end

-- NOTE: Must uncomment call from C++ to receive this.
-- function Trigger_PlayerContractNegotiation( teamId, playerId, status )
	-- local userTeam = Engine.GetUserTeam()
	-- if( userTeam == teamId ) then
		-- if( status == "NEGOTIATING" ) then
			-- ExamineFor_ContractRebel( teamId, playerId )
			-- UnhappyWithWage_ContractAccept( teamId, playerId )
		-- end
		-- NewContractForeignPlayer( teamId, playerId, status )
	-- end	
-- end

-- NOTE: Must uncomment call from C++ to receive this.
-- function Trigger_PlayerContractAccept( teamId, playerId )
	-- UnhappyWithWage_ContractAccept( teamId, playerId )
-- end

function Trigger_TransferWindowCloseDayReached()
	-- ForeignUpsetStoryEndOfWindow( 0 )
	StupidTransferClose( 0 )
	LostPlayer_WindowPassed( 0 )
	MoveRequest_TransferWindowClose( 0 )
	EndOfWindow_CounterOffer( 0 )
end

-- NOTE: Must uncomment call from C++ to receive this.
-- function Trigger_TransferWindowNumDaysTillClose( numDays )
	-- ExamineFor_LMTR( numDays )              NOTE: LMTR currently removed
	-- LMTREndOfTransferWindow( numDays )      NOTE: LMTR currently removed
	-- WeakSpot_Stage4( numDays )              NOTE: Weak player replacement currently removed
	-- NumDaysLeft_CPUTransferRebel( numDays ) NOTE: Contract rebel currently removed
-- end

function Trigger_TransferWindowNumDaysSinceOpened( numDays )
	-- ContractRebelWindowOpen( numDays )      NOTE: Contract rebel currently removed
	PlayTimeBoardWarning( numDays )
	PlayTimeUnhappinessListMe( numDays )
	-- WeakSpot_Stage3( numDays )              NOTE: Weak player replacement currently removed
end

function Trigger_PlayTimeMoraleChange( teamId, playerId, oldHappiness, newHappiness )
	ExamineFor_PTH( teamId, playerId, oldHappiness, newHappiness )
	PFR_Stage3( teamId, playerId, oldHappiness, newHappiness )
end

function Trigger_PlayTimeMoraleChange_FlaggedPlayer( teamId, playerId, oldHappiness, newHappiness )
	ExamineFor_PlayTimePromise( teamId, playerId, oldHappiness, newHappiness )
end

function Trigger_PlayerUnhappyWithWage( teamId, playerId )
	-- ExamineFor_UnhappyWithWage( teamId, playerId )  NOTE: Player upset with wage currently removed
end

-- Move this code into C++, what about one story triggering another??
function Trigger_TeamPlayerRemoval( teamId, playerId )
	local userTeam = Engine.GetUserTeam()
	if( userTeam == teamId ) then
		EndFormStoriesForPlayer( teamId, playerId )
	end
end

function Trigger_TalkToPress_Player( teamId, playerId, appearances, goals, yellows, reds, option )
	TalkToPress_Player( teamId, playerId, appearances, goals, yellows, reds, option )
end

function Trigger_TalkToPress_Manager( teamId, managerName, option )
	TalkToPress_Manager( teamId, managerName, option )
end

function Trigger_TalkToPress_Team( teamId, option )
	TalkToPress_Team( teamId, option )
end

function Trigger_TalkToPress_Match( option, fixture )
	TalkToPress_Match( option, fixture )
end

function Trigger_PlayerReleased( teamId, playerId )
	PlayerSagaReleasedEnding( teamId, playerId )
	PoorRun_Released( teamId, playerId )
	PFR_Released( teamId, playerId )
	PlayerCriticizes_Released( teamId, playerId )
	local userTeam = Engine.GetUserTeam()
	if( userTeam == teamId ) then
		if( IsPlayerInvolvedInSaga( playerId ) == false ) then
			Engine.EndAllStoriesForPlayer( playerId )
		end
	end
end


function Trigger_SoakStarted()
	--Debug_StartSoak()
end

function Trigger_InternationalsJobOfferAccepted( teamId )
	InternationalJob_OfferAccepted( teamId )
end

function Trigger_InternationalsJobOfferMade( teamId )
	InternationalJob_OfferMade( teamId )
end

function Trigger_InternationalsJobOfferDeclined( teamId )
	InternationalJob_OfferDeclined( teamId )
end

function Trigger_InternationalsJobOfferStalled( teamId )
	InternationalJob_OfferStalled( teamId )
end

function Trigger_InternationalJobOfferExpired( teamId )
	InternationalJob_OfferRetracted( teamId )
end

function Trigger_PapJobSwitchAccepted( teamId, isLoan )
	JobOffer_OfferAccepted( teamId )
end

function Trigger_PapJobSwitchRejected( teamId, wasLoan )
	JobOffer_OfferDeclined( teamId )
end

function Trigger_PapRequestMove( isLoan )
	ExamineFor_MoveRequest( isLoan )
end

function Trigger_PapRequestManagerDecision( allow, loanInstead, numRequests )
	MoveRequest_ManagerDecision( allow, loanInstead )
end

function Trigger_PapOfferReceived( teamId, isLoan )
	local category = "REQUEST"
	local numStories = Engine.GetNumStoriesByCategory( category )
	if( numStories > 0 ) then
		MoveRequest_OfferReceived( teamId, isLoan )
	else
		JobOffer_OfferMade( teamId, isLoan )
	end
end

function Trigger_PapOfferExpired( teamId, isLoan )
	JobOffer_OfferRetracted( teamId )
end

function Trigger_JobOfferReceived( teamId )
	JobOffer_OfferMade( teamId, false )
end

function Trigger_JobOfferAccepted( teamId )
	JobOffer_OfferAccepted( teamId )
end

function Trigger_JobOfferRejected( teamId )
	JobOffer_OfferDeclined( teamId )
end

function Trigger_JobOfferExpired( teamId )
	JobOffer_OfferRetracted( teamId )
end

function Trigger_InternationalJobFired( teamId )
	InternationalJobRenewal_Fired( teamId )
end

function Trigger_InternationalPAPSelected( teamId )
	local userTeam = Engine.GetUserTeam()
	StartStory_NewJob( teamId, userTeam, "INTPLAYER", false, false )
end

function Trigger_InternationalPAPNotSelected( teamId )
	
end

function Trigger_WeekBeforeInternationalJobReview( teamId )
	StartStory_InternationalJobRenewal( teamId )
end

function Trigger_InternationalJobReview( teamId )
	
end

function Trigger_JobOffersGenerated( numJobs, job1, job2, job3, job4, job5 )
end

function Trigger_PapRequestListWithdraw( listed, loaned )

end

function Trigger_PapListWithdrawalResponse( listed, loaned, allowWithdraw )
	if( allowWithdraw == true ) then
		local category = "REQUEST"
		local numStories = Engine.GetNumStoriesByCategory( category )
		if( numStories > 0 ) then
			Engine.EndStoryCategory( category, false )
		end
	end
end

function Trigger_PapRequestToManagerToPlay()
	local userTeam = Engine.GetUserTeam()
	local playerId = Engine.GetPlayAsPlayerID()
	local playerTier = Engine.GetPlayerTier( userTeam, playerId )
	if( playerTier > Tuning.RESERVE.minPlayerTier )then
		StartStory_ReserveRequest( userTeam, playerId )
	else
		local playerForm = Engine.GetPlayerFormData( userTeam, playerId )
		local isInGoodForm = Engine.IsInGoodForm( playerForm )
		local isInVeryGoodForm = Engine.IsInVeryGoodForm( playerForm )
		if( isInGoodForm == true or isInVeryGoodForm == true ) then
			StartStory_POB( userTeam, playerId )
		end
	end
end

function Trigger_InternationalJobResign( teamId )
	InternationalJob_Resign( teamId )
end

function Trigger_CPUOpponentTransferIn( teamId, checkForDebuts, numTransfers, player1, player2, player3, player4, player5, player6, player7 )
	ExamineFor_CPUNewSigning( teamId, checkForDebuts, numTransfers, player1, player2, player3, player4, player5, player6, player7 )
end

function Trigger_CPUOpponentTransferOut( teamId, checkForDebuts, numTransfers, player1, player2, player3, player4, player5, player6, player7 )
	ExamineFor_CPULostPlayer( teamId, numTransfers, player1, player2, player3, player4, player5, player6, player7 )
end

function Trigger_TableRivalMatch( userTeamId, userTeamLeaguePos, opponentTeamId, opponentTeamLeaguePos, numTeamsInLeague )

end
