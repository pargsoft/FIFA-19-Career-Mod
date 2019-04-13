function ExamineFor_TalkToPress_CPU( numDays, gametype, fixture )
	if( string.find( gametype, "INTERNATIONAL" ) == nil ) then
		if( numDays == 0 ) then
			local chanceToStart = RollPercentageDice( Tuning.PRESS.chanceToStartPerc ) -- 25%
			if( chanceToStart == true ) then
				------------------------------------ Choose Positive or Negative
				local optionChance = RollPercentageDice( Tuning.PRESS.optionChancePerc ) --25%
				local option = "POSITIVE"
				if( optionChance == true ) then
					option = "POSITIVE" --"NEGATIVE"
				end
				------------------------------------ Check Reverse Fixture
				local match = false
				if( gametype == "LEAGUE" ) then
					local seasonPerc = Engine.GetPercentageThroughSeason()
					if( seasonPerc >= Tuning.PRESS.lateSeasonPerc ) then
					--if( reverseFixture == true ) then
						match = true
					--end
					end
				end
				------------------------------------ Check For Foul Language
				local swear = false
				local storyActive = Engine.IsStoryIDActive( "FOULLANGUAGE", true )
				if( storyActive == true ) then
					swear = true
				end
				------------------------------------ Choose Story
				local userTeam, cpuTeam = GetTeamsFromFixture( fixture )
				local teamId = userTeam
				local teamId2 = cpuTeam
				local success = false
				if( match == true ) then
					local chanceOfReverse = RollPercentageDice( Tuning.PRESS.chanceOfReversePerc )
					if( chanceOfReverse == true ) then
						TalkToPress_Match( option, fixture, true, cpuTeam )
						success = true
					end
				elseif( swear == true ) then
					TalkToPress_Manager( teamId, "ADAMBELL", option, true, cpuTeam )
					success = true
				end
				if( success == false ) then
					local choice = RollPercentageDice( Tuning.PRESS.choicePerc ) -- 35%
					if( choice == true ) then
						local teamChoice1 = RollPercentageDice( Tuning.PRESS.teamChoice1Perc ) -- 30%
						if( teamChoice1 == true ) then
							teamId = cpuTeam
							teamId2 = userTeam
						else
							teamId = userTeam
							teamId2 = cpuTeam
						end	
					else
						local choose = 1
						if( Engine.IsPlayAsPlayer() == true ) then
							choose = 2
						end
						local randChoice = Engine.GetRandomNumber( 1, choose ) -- 1, 2
						if( randChoice == 2 ) then -- PAP
							local randomNumber = Engine.GetRandomNumber( 1, 4 )
							if( randomNumber == 1 ) then
								teamId = cpuTeam
								teamId2 = userTeam
							elseif( randomNumber == 2 ) then
								teamId = userTeam
								teamId2 = cpuTeam
							elseif( randomNumber == 3 ) then
								teamId = userTeam
								teamId2 = userTeam
							else
								teamId = cpuTeam
								teamId2 = cpuTeam
							end
						else
							local teamChoice2 = RollPercentageDice( Tuning.PRESS.teamChoice2Perc ) -- 30%
							if( teamChoice2 == true ) then
								teamId = cpuTeam
								teamId2 = cpuTeam
							else
								teamId = userTeam
								teamId2 = cpuTeam
							end					
						end
					end
					if( choice == true ) then
						TalkToPress_Team( teamId, option, true, teamId2 )
					else
						local playerId = GetPlayerByStrength( teamId, true )
						local appearances, goals, yellows, reds = GetStats( teamId, playerId )
						TalkToPress_Player( teamId, playerId, appearances, goals, yellows, reds, option, true, teamId2 )
					end
				end
			end
		end
	end
end

function GetPlayerByStrength( teamId, isStrong )
	teamId = Engine.StackRankTeamByOverall( teamId )
	local listPlayers = {}
	if( isStrong == true ) then
		local numPlayers = 10
		for playerCount = 1, numPlayers do
			local foundPlayer = Engine.GetPlayer( teamId, playerCount )
			table.insert( listPlayers, foundPlayer )
		end
	else
		local numPlayers = Engine.GetNumPlayers( teamId )
		for playerCount = numPlayers, 1, -1 do
			local foundPlayer = Engine.GetPlayer( teamId, playerCount )
			table.insert( listPlayers, foundPlayer )
		end
	end
	local playerId = nil
	local numList = # listPlayers
	if( numList > 0 ) then
		local randChoice = Engine.GetRandomNumber( 1, numList )
		playerId = listPlayers[ randChoice ]
	end
	return playerId
end

function GetStats( teamId, playerId )
	local appearances = Engine.GetPlayerStat( teamId, playerId, "APPEARANCES" )
	local goals = Engine.GetPlayerStat( teamId, playerId, "GOALS" )
	local yellows = Engine.GetPlayerStat( teamId, playerId, "YELLOWS" )
	local reds = Engine.GetPlayerStat( teamId, playerId, "REDS" )
	return appearances, goals, yellows, reds
end
	
function TalkToPress_Player( teamId, playerId, appearances, goals, yellows, reds, option, isCpu, cpuTeam )
	local category = "PRESS"
	local storyId = "T2PPLAYER_"
	if( isCpu == true ) then
		storyId = "CPU_" .. storyId
	end
	storyId = storyId .. option
	if( Engine.MarkPlayerForStory( Engine.GetUserTeam(), playerId, category, storyId ) == true ) then
		local currentStory = Engine.GetStoryById( storyId )
		Engine.KillStoryAfterMatch( currentStory )
		Engine.UpdateStoryActivity( currentStory )		
		
		local numPlayers = Engine.GetNumPlayers( teamId )
		local age = Engine.GetPlayerAge( teamId, playerId )
		local area = Engine.GetPlayerPitchArea( teamId, playerId )
		local overall = Engine.GetPlayerOverall( playerId )
		local goalsPG = 0.0
		local disciplinePG = 0.0
		local form = NIL
		if( Engine.GetUserTeam() == teamId ) then
			form = Engine.GetPlayerFormData( teamId, playerId )
		end
		local disciplineScore = ( yellows * 1 ) + ( reds * 3 )
		local injured = Engine.IsInjured( teamId, playerId )
		local isInjuredButPlayable = false
		if( injured == true ) then 
			isInjuredButPlayable = Engine.IsRecoveringFromInjury( teamId, playerId )
		end
		
		if( goals > 0 ) then
			goalsPG = appearances / goals
		end

		if( disciplineScore > 0 ) then
			disciplinePG = appearances / disciplineScore
		end

		local isSuspended = Engine.IsPlayerSuspendedForNextGame( teamId, playerId )
		local general = true
		
		local doesMatchYoungAge = false
		local doesMatchOldAge = false
		local doesMatchGoodOverall = false
		local doesMatchBadOverall = false
		local doesMatchGoodGoalScoring = false
		local doesMatchBadGoalScoring = false
		local doesMatchForm = false
		local doesMatchGoodDiscipline = false
		local doesMatchBadDiscipline = false
		local doesMatchInjured = false
		local doesMatchSuspended = false
		local doesMatchGeneral = true		-- always has one
		local doesMatchSuperStar = false
		
		-- Age
		doesMatchYoungAge = ( doesMatchYoungAge == true or ( area == "GK" and age < Tuning.PRESS.youngGkThreshold ) )
		doesMatchOldAge = ( doesMatchOldAge == true or ( area == "GK" and age > Tuning.PRESS.oldGkThreshold ) )
		
		doesMatchYoungAge = ( doesMatchYoungAge == true or ( area == "DEF" and age < Tuning.PRESS.youngDefThreshold ) )
		doesMatchOldAge = ( doesMatchOldAge == true or ( area == "DEF" and age > Tuning.PRESS.oldDefThreshold ) )

		doesMatchYoungAge = ( doesMatchYoungAge == true or ( area == "MID" and age < Tuning.PRESS.youngMidThreshold ) )
		doesMatchOldAge = ( doesMatchOldAge == true or ( area == "MID" and age > Tuning.PRESS.oldMidThreshold ) )

		doesMatchYoungAge = ( doesMatchYoungAge == true or ( area == "ATT" and age < Tuning.PRESS.youngAttThreshold ) )
		doesMatchOldAge = ( doesMatchOldAge == true or ( area == "ATT" and age > Tuning.PRESS.oldAttThreshold ) )
				
		-- Overall
		local numPlayers = Engine.GetNumPlayers( teamId )
		teamId = Engine.StackRankTeamByOverall( teamId )
		doesMatchGoodOverall = ( doesMatchGoodOverall == true or ( Engine.GetPlayer( teamId, 1 ) == playerId ) )
		doesMatchGoodOverall = ( doesMatchGoodOverall == true or ( Engine.GetPlayer( teamId, 2 ) == playerId ) )
		doesMatchGoodOverall = ( doesMatchGoodOverall == true or ( Engine.GetPlayer( teamId, 3 ) == playerId ) )
		doesMatchGoodOverall = ( doesMatchGoodOverall == true or ( Engine.GetPlayer( teamId, 4 ) == playerId ) )

		doesMatchBadOverall = ( doesMatchBadOverall == true or ( Engine.GetPlayer( teamId, numPlayers ) == playerId ) )
		doesMatchBadOverall = ( doesMatchBadOverall == true or ( Engine.GetPlayer( teamId, numPlayers - 1 ) == playerId ) )
		doesMatchBadOverall = ( doesMatchBadOverall == true or ( Engine.GetPlayer( teamId, numPlayers - 2 ) == playerId ) )
		doesMatchBadOverall = ( doesMatchBadOverall == true or ( Engine.GetPlayer( teamId, numPlayers - 3 ) == playerId ) )

		-- Good Goal Scoring
		doesMatchGoodGoalScoring = ( area == "ATT" and goalsPG > Tuning.PRESS.goodGoalScoringThreshold and appearances >= Tuning.PRESS.minGoalScoringAppearances )
		
		-- Bad Goal Scoring
		doesMatchBadGoalScoring = ( area == "ATT" and goalsPG < Tuning.PRESS.badGoalScoringThreshold and appearances >= Tuning.PRESS.minGoalScoringAppearances )
		
		-- Good Form
		if( form ~= NIL ) then
			doesMatchGoodForm = ( Engine.IsInVeryGoodForm( form ) or Engine.IsInGoodForm( form ) )
		end
		
		-- Bad Form
		if( form ~= NIL ) then
			doesMatchBadForm = ( IsInVeryBadForm( form ) or Engine.IsInBadForm( form ) )
		end
		
		-- Good Discipline
		doesMatchGoodDiscipline = ( disciplinePG < Tuning.PRESS.goodDisciplineThreshold and appearances >= Tuning.PRESS.minDisciplineAppearances )
		
		-- Bad Discipline
		doesMatchBadDiscipline = ( disciplinePG > Tuning.PRESS.badDisciplineThreshold and appearances >= Tuning.PRESS.minDisciplineAppearances )
		
		-- Injured ( can it ignore injured players who can't play cost that's what I've done)
		doesMatchInjured = injured
		--doesMatchInjured = ( injured and isInjuredButPlayable )
		
		-- Suspended
		doesMatchSuspended = isSuspended
		
		-- General
		doesMatchGeneral = true -- always true
		
		-- SuperStar
		doesMatchSuperStar = ( overall >= Tuning.PRESS.superStarOvr )
			
		-- Collate
		local categories = 11
		local variableArray = { "YOUNGAGE",
								"OLDAGE",
								"GOODOVERALL",
								"BADOVERALL",
								"GOODGOALS",
								"BADGOALS",
								"GOODFORM",
								"BADFORM",
								"GOODDISCIPLINE",
								"BADDISCIPLINE",
--								"INJURED",
--								"SUSPENDED",
								--"GENERAL",
								"SUPERSTAR" }
		
		local newsArray = {	"Young_",
							"Old_",
							"Good_",
							"Bad_",
							"GoalscoringGood_",
							"GoalscoringBad_",
							"FormGood_",
							"FormBad_",
							"DisciplineGood_",
							"DisciplineBad_",
--							"Injured_",
--							"Suspended_",
							--"GeneralComment",
							"SuperstarComment_" }
		
		local testArray = { doesMatchYoungAge,
							doesMatchOldAge,
							doesMatchGoodOverall,
							doesMatchBadOverall,
							doesMatchGoodGoalScoring,
							doesMatchBadGoalScoring,
							doesMatchGoodForm,
							doesMatchBadForm,
							doesMatchGoodDiscipline,
							doesMatchBadDiscipline,
--							doesMatchInjured,
--							doesMatchSuspended,
							--doesMatchGeneral,
							doesMatchSuperStar,
						  }						 
						  
		local validCategories = {}
		local validCatCount = 0
		local validNews = {}
		for catCount = 1, categories do			
			if( testArray[ catCount ] == true ) then
				Print( variableArray[ catCount ] )
				validCatCount = validCatCount + 1
				validCategories[ validCatCount ] = variableArray[ catCount ]
				validNews[ validCatCount ] = newsArray[ catCount ]
			end
		end
		local newsItem = ""
		local storyVar = "" 
		if( validCatCount > 0 ) then
			local randNo = Engine.GetRandomNumber( 1, validCatCount )
			storyVar = validCategories[ randNo ]
			Engine.SetStoryVariable( currentStory, storyVar )
			newsItem = validNews[ randNo ]
		else
			Engine.SetStoryVariable( currentStory, "GENERAL" )
			newsItem = "GeneralComment_"
			area = "None"
		end	

		if( storyVar == "GOODGOALS" or storyVar == "BADGOALS" or
			storyVar == "GOODFORM" or storyVar == "BADFORM" or
			storyVar == "GOODDISCIPLINE" or storyVar == "BADDISCIPLINE" or
			storyVar == "INJURED" or storyVar == "SUSPENDED" or storyVar == "SUPERSTAR" ) then
				area = "None"
		end
					
		local newsString = "TalkToPress_"
		local titleString = "Title_"
		local bodyString = "Body_"
		local emotionString = ""
		if( option == "POSITIVE" ) then
			emotionString = emotionString .. "Praise_"
		else
			emotionString = emotionString .. "Unnerve_"
		end
		local useTeam = ""
		local userTeam = Engine.GetUserTeam()
		if( isCpu == true ) then
			if( teamId == cpuTeam ) then
				useTeam = "Own"
			else
				useTeam = "Opponent"
			end
		else
			if( Engine.GetUserTeam() == teamId ) then
				useTeam = "Own"
			else
				useTeam = "Opponent"
			end
		end
		local useTitleStr = newsString .. titleString .. emotionString .. newsItem .. useTeam .. area .. "_Player_"
		local useBodyStr = newsString .. bodyString .. emotionString .. newsItem ..  useTeam .. area .. "_Player_"
		local userTeamId = userTeam
		local newsTeamFocus = userTeam
		if( isCpu == true ) then
			if( cpuTeam == userTeam and teamId == userTeam ) then
				userTeamId = teamId
				newsTeamFocus = teamId
			elseif( cpuTeam ~= userTeam and teamId ~= userTeam ) then
				userTeamId = teamId
				newsTeamFocus = teamId
			elseif( cpuTeam == userTeam and teamId ~= userTeam ) then
				userTeamId = teamId
				newsTeamFocus = teamId
			else
				userTeamId = cpuTeam
				newsTeamFocus = cpuTeam
			end
		end
		Engine.SetStringPlayer( playerId )
		Engine.SetStringPlayer( playerId, 2 )
		Engine.SetStringTeam( userTeamId, 1 )
		Engine.SetStringTeam( teamId, 2 )
		Engine.SetNewsPlayer( playerId )
		Engine.SetNewsTeam( newsTeamFocus )
		Engine.SetNewsImportance( "EXCLUSIVE" )
		Engine.SetNewsType( "CLUB" )
		Engine.SetNewsForegroundImage( "CENTER", "PLAYER_IMG", playerId )		
		Engine.SetNewsBackgroundImage( "PRESS_CONFERENCE" )
		TriggerNews( useTitleStr, 1, 1, useBodyStr, 1, 1, NIL )
	end
end

function TalkToPress_Manager( teamId, managerName, option, isCpu, cpuTeam )
	local category = "PRESS"
	local storyId = "T2PMANAGER_"
	local userTeamId = Engine.GetUserTeam()
	if( isCpu == true ) then
		storyId = "CPU_" .. storyId
	end
	storyId = storyId .. option
	if( Engine.MarkPlayerForStory( userTeamId, 0, category, storyId ) == true ) then
		local currentStory = Engine.GetStoryById( storyId )
		Engine.KillStoryAfterMatch( currentStory )
		Engine.UpdateStoryActivity( currentStory )

		local variableStr = ""
		local newsAddon = ""
		local randNo = Engine.GetRandomNumber( 1, 3 )
		if( randNo == 1 ) then
			variableStr = "TACTICS"
			newsAddon = "Tactics"
		elseif( randNo == 2 ) then
			variableStr = "TRANSFER"
			newsAddon = "TransferDealings"
		else
			variableStr = "DISCIPLINE"
			newsAddon = "Discipline"
		end
		Engine.SetStoryVariable( currentStory, variableStr )
		
		local newsString = "TalkToPress_"
		local titleString = "Title_"
		local bodyString = "Body_"
		local emotionString = ""
		if( option == "POSITIVE" ) then
			emotionString = emotionString .. "Praise_"
		else
			emotionString = emotionString .. "Unnerve_"
		end
		local useTitleStr = newsString .. titleString .. emotionString .. newsAddon .. "_Manager_"
		local useBodyStr = newsString .. bodyString .. emotionString .. newsAddon .. "_Manager_"		
		
		if( isCpu == true ) then
			userTeamId = cpuTeam
		end
		
		Engine.SetStringTeam( userTeamId, 1 )
		Engine.SetStringTeam( teamId, 2 )
		Engine.SetNewsTeam( teamId )
		Engine.SetNewsImportance( "EXCLUSIVE" )
		Engine.SetNewsType( "CLUB" )
		Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
		Engine.SetNewsBackgroundImage( "PRESS_CONFERENCE" )
		TriggerNews( useTitleStr, 1, 2, useBodyStr, 1, 2, NIL )
	end --if( Engine.MarkPlayerForStory( userTeamId, 0, category, storyId ) == true ) then
end

function TalkToPress_Team( teamId, option, isCpu, cpuTeam )
	local category = "PRESS"
	local storyId = "T2PTEAM_"
	
	local userTeamId = Engine.GetUserTeam()
	if( isCpu == true ) then
		storyId = "CPU_" .. storyId
	end
	storyId = storyId .. option
	
	local fixture = Engine.GetCurrentGameFixtureData()
	local fixtureType = Engine.GetFixtureType( fixture )
	local homeTeam, awayTeam = Engine.GetTeamsFromFixtureData( fixture )
	local isDerby = Engine.AreTeamsDerby( homeTeam, awayTeam )
	local isRival = Engine.AreTeamsRivals( homeTeam, awayTeam )
	
	local opponentTeamId = 0
	if( isCpu == true ) then
		opponentTeamId = teamId
		userTeamId = cpuTeam
	else
		if( homeTeam == userTeamId ) then
			opponentTeamId = awayTeam
		else
			opponentTeamId = homeTeam
		end
	end
	local derbyRival = ( isDerby == true or isRival == true )
	
	if( Engine.MarkPlayerForStory( Engine.GetUserTeam(), 0, category, storyId ) == true ) then
		local currentStory = Engine.GetStoryById( storyId )
		Engine.KillStoryAfterMatch( currentStory )
		Engine.UpdateStoryActivity( currentStory )
		
		local newsString = "TalkToPress_"
		local titleString = "Title_"
		local bodyString = "Body_"
		local emotionString = ""
		local teamString = ""
		local derbyStr = "Neither"
		if( option == "POSITIVE" ) then
			emotionString = emotionString .. "Praise"
		else
			emotionString = emotionString .. "MotivateUnnerve"
		end
		
		if( isCpu == true ) then
			if( Engine.GetUserTeam() == teamId ) then
				teamString = "Opponent"
			else
				teamString = "UserTeam"
			end
		else
			if( Engine.GetUserTeam() == teamId ) then
				teamString = "UserTeam"
			else
				teamString = "Opponent"
			end
		end
		
		if( derbyRival == true ) then
			derbyStr = "DerbyRival"
		end
		local useTitleStr = newsString .. titleString .. emotionString .. teamString .. derbyStr .. "_"
		local useBodyStr = newsString .. bodyString .. emotionString .. teamString .. derbyStr .. "_"
		
		if( fixtureType == "LEAGUE" ) then
			TalkToPress_Team_League( currentStory, teamId, userTeamId, opponentTeamId, category, storyId, fixture, derbyRival, useTitleStr, useBodyStr )
		elseif( fixtureType == "CUP" or fixtureType == "SUPERCUP" ) then
			TalkToPress_Team_Cup( currentStory, teamId, userTeamId, opponentTeamId, category, storyId, fixture, derbyRival, useTitleStr, useBodyStr )
		end			
	end
end

function TalkToPress_Team_League( currentStory, teamId, userTeamId, opponentTeamId, category, storyId, fixture, derbyRival, titleStr, bodyStr )
	local storyVar = "LEAGUE"
		-- Derby/Rival
	if( derbyRival == true ) then
		storyVar = storyVar .. ".DBYRIV"
	end
	local leagueId = Engine.GetLeagueId( userTeamId )
	local numTeams = Engine.GetNumberOfTeamsInLeague( leagueId )
	local cpuTeamPosition = Engine.GetLeaguePosition( opponentTeamId )
	local userTeamPosition = Engine.GetLeaguePosition( userTeamId )
		
	local bottomPerc = Tuning.PRESS.bottomPerc
	local topPerc = Tuning.PRESS.topPerc
	local bottomPos = ( numTeams - ( numTeams * bottomPerc ) / 100 )
	local topPos = ( ( numTeams * topPerc ) / 100 )
	
	local topTwo = ( ( userTeamPosition == 1 and cpuTeamPosition == 2 ) or ( userTeamPosition == 2 and cpuTeamPosition == 1 ) )
	local topOfTable = ( topTwo == false and ( userTeamPosition <= topPos and cpuTeamPosition <= topPos ) )
	local bottomOfTable = ( userTeamPosition >= bottomPos and cpuTeamPosition >= bottomPos )
		
	local tablePosStr = ""
	if( topTwo == true ) then
		storyVar = storyVar .."_TOP"
		tablePosStr = "TopofTable_"
	elseif( topOfTable == true ) then
		storyVar = storyVar .."_HIGH"
		tablePosStr = "HighTeams_"
	elseif( bottomOfTable == true ) then
		storyVar = storyVar .."_RELEG"
		tablePosStr = "RelegationBattle_"
	else
		storyVar = storyVar .."_MID"
		tablePosStr = "Generic_"
	end
	titleStr = titleStr .. tablePosStr
	bodyStr = bodyStr .. tablePosStr
	Engine.SetStoryVariable( currentStory, storyVar )
	Engine.SetStringTeam( userTeamId, 1 )
	Engine.SetStringTeam( opponentTeamId, 2 )
	Engine.SetStringCompetition( Engine.GetCompetitionFromFixture( fixture ) )	
	Engine.SetNewsTeam( userTeamId )
	Engine.SetNewsImportance( "EXCLUSIVE" )
	Engine.SetNewsType( "CLUB" )
	Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
	Engine.SetNewsBackgroundImage( "PRESS_CONFERENCE" )
	TriggerNews( titleStr, 1, 1, bodyStr, 1, 1, NIL )
end

function TalkToPress_Team_Cup( currentStory, teamId, userTeamId, opponentTeamId, category, storyId, fixture, derbyRival, titleStr, bodyStr )
	local storyVar = "CUP"
	-- Derby/Rival
	if( derbyRival == true ) then
		storyVar = storyVar .. ".DBYRIV"
	end
	
	-- Round
	local round = Engine.GetRoundFromCupFixtureData( fixture )	
	storyVar = storyVar .. "." .. round
	
	-- Opponenent Quality
	local qualityDiff = TalkToPress_DetermineTeamDifference( userTeamId, opponentTeamId )
	
	storyVar = storyVar .. "." .. qualityDiff
	
	local qualityStr = ""
	local roundStr = ""
	if( round == "FINAL" ) then
		roundStr = "Final"
	elseif( round == "SEMI" ) then
		roundStr = "SemiQuarter"
	elseif( round == "QTR" ) then
		roundStr = "SemiQuarter"
	else
		roundStr = "Other"
	end
	
	if( qualityDiff == "EVEN"  ) then
		qualityStr = "Even"
	elseif( qualityDiff == "USR_BETTER" ) then
		qualityStr = "WorseThanUser"
	elseif( qualityDiff == "USR_SIGBETTER" ) then
		qualityStr = "MuchWorseThanUser"
	elseif( qualityDiff == "OPP_BETTER" ) then
		qualityStr = "BetterThanUser"
	elseif( qualityDiff == "OPP_SIGBETTER" ) then
		qualityStr = "MuchBetterThanUser"
	end
	
	titleStr = titleStr .. roundStr .. "_" .. qualityStr .. "_"
	bodyStr = bodyStr .. roundStr .. "_" .. qualityStr .. "_"
	Engine.SetStoryVariable( currentStory, storyVar )
	Engine.SetStringTeam( userTeamId, 1 )
	Engine.SetStringTeam( opponentTeamId, 2 )
	Engine.SetStringCompetition( Engine.GetCompetitionFromFixture( fixture ) )
	Engine.SetNewsTeam( userTeamId )
	Engine.SetNewsImportance( "EXCLUSIVE" )
	Engine.SetNewsType( "CLUB" )
	Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", teamId )
	Engine.SetNewsBackgroundImage( "PRESS_CONFERENCE" )
	TriggerNews( titleStr, 1, 1, bodyStr, 1, 1, NIL )
end

function TalkToPress_DetermineTeamDifference( userTeamId, opponentTeamId )	
	local evenDiff = Tuning.PRESS.evenDiff
	local better = Tuning.PRESS.better
	local sigBetter = Tuning.PRESS.sigBetter
	
	local diffLevel = ""
	local userTeamOverall = Engine.GetTeamOverall( userTeamId )
	local opponentOverall = Engine.GetTeamOverall( opponentTeamId )
	local diff = userTeamOverall - opponentOverall
	if( diff > 0 ) then
		if( diff <= evenDiff ) then
			diffLevel = "EVEN"
		elseif( diff <= better ) then
			diffLevel = "USR_BETTER"
		elseif( diff <= sigBetter ) then
			diffLevel = "USR_SIGBETTER"
		else
			diffLevel = "ERROR"
		end
	else
		diff = math.abs( diff )
		if( diff <= evenDiff ) then
			diffLevel = "EVEN"
		elseif( diff <= better ) then
			diffLevel = "OPP_BETTER"
		elseif( diff <= sigBetter ) then
			diffLevel = "OPP_SIGBETTER"
		else
			diffLevel = "ERROR"
		end
	end
	return diffLevel
end

function TalkToPress_Match( option, fixture, isCpu, cpuTeam )
	local category = "PRESS"
	local storyId = "T2PMATCH_"
	
	if( isCpu == true ) then
		storyId = "CPU_" .. storyId
	end
	storyId = storyId .. option
	
	local userTeamId = Engine.GetUserTeam()
	if( Engine.MarkPlayerForStory( Engine.GetUserTeam(), 0, category, storyId ) == true ) then
		local currentStory = Engine.GetStoryById( storyId )
		Engine.UpdateStoryActivity( currentStory )
	
		local homeGoals, awayGoals = Engine.GetGoalsFromFixtureData( fixture )
		local homeTeamId, awayTeamId = Engine.GetTeamsFromFixtureData( fixture )
		local userGoals = -1
		local opponentGoals = -1
		local opponentTeamId = -1
		
		if( isCpu == true ) then
			if( homeTeamId == userTeamId ) then
				userGoals = awayGoals
				opponentGoals = homeGoals
				opponentTeamId = homeTeamId
				userTeamId = cpuTeam
			else
				userGoals = homeGoals
				opponentGoals = awayGoals
				opponentTeamId = awayTeamId
				userTeamId = cpuTeam
			end
		else
			if( homeTeamId == userTeamId ) then
				userGoals = homeGoals
				opponentGoals = awayGoals
				opponentTeamId = awayTeamId
			else
				userGoals = awayGoals
				opponentGoals = homeGoals
				opponentTeamId = homeTeamId
			end
		end
		
		local scoreType = "" 
		if( userGoals == opponentGoals ) then -- draw
			Engine.SetStoryVariable( currentStory, "DRAW" )
			scoreType = "Draw_"
		elseif( userGoals - opponentGoals >= Tuning.PRESS.minBigScoreDifference ) then -- user big win
			Engine.SetStoryVariable( currentStory, "USER_BIG_WIN" )
			scoreType = "BigWin_"
		elseif( userGoals - opponentGoals > 0 ) then  -- user win
			Engine.SetStoryVariable( currentStory, "USER_WIN" )
			scoreType = "Win_"
		elseif( opponentGoals - userGoals >= Tuning.PRESS.minBigScoreDifference ) then  -- user big loss
			Engine.SetStoryVariable( currentStory, "USER_BIG_LOSS" )
			scoreType = "BigDefeat_"
		elseif( opponentGoals - userGoals > 0 ) then  -- user loss
			Engine.SetStoryVariable( currentStory, "USER_LOSS" )
			scoreType = "Defeat_"
		else
			Engine.SetStoryVariable( currentStory, "ERROR" )
		end
		
		local newsString = "TalkToPress_"
		local titleString = "Title_"
		local bodyString = "Body_"
		local emotionString = ""
		if( option == "POSITIVE" ) then
			emotionString = emotionString .. "Praise_"
		else
			emotionString = emotionString .. "Unnerve_"
		end
		local useTitleStr = newsString .. titleString .. emotionString .. scoreType .. "Previous Result_"
		local useBodyStr = newsString .. bodyString .. emotionString .. scoreType .. "Previous Result_"
		Engine.SetStringTeam( userTeamId, 1 )
		Engine.SetStringTeam( opponentTeamId, 2 )
		Engine.SetNewsTeam( userTeamId )
		Engine.SetNewsImportance( "EXCLUSIVE" )
		Engine.SetNewsType( "CLUB" )
		Engine.SetNewsForegroundImage( "CENTER", "CLUB_CREST", userTeamId )
		Engine.SetNewsForegroundImage( "RIGHT", "CLUB_CREST", opponentTeamId )
		Engine.SetNewsBackgroundImage( "PRESS_CONFERENCE" )
		TriggerNews( useTitleStr, 1, 1, useBodyStr, 1, 1, NIL )	
		Engine.KillStoryAfterMatch( currentStory )
	end --if( Engine.MarkPlayerForStory( userTeamId, 0, category, storyId ) == true ) then
end
