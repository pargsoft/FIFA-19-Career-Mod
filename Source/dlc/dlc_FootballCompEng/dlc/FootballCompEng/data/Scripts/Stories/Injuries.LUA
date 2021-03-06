-- "PREVIEW" news are blocked from C++ code in SendNews(), even if their logic is still kept in Lua code. So, they no longer get sent.
---------------------------------INJURIES--------------------------------------
function ExamineFor_InjuryStories( numDays, gametype, fixture )
	if( numDays == 0 ) then
		local category = "INJURY"
		local numStories = Engine.GetNumStoriesByCategory( category )
		if( numStories > 0 ) then
			local userTeam = Engine.GetUserTeam()
			local cpuInjuries = 0
			local userInjuries = 0
			local cpuTeam = 0
			local userPlayers = {}
			local cpuPlayers = {}
			for storyCount = 1, numStories do
				local currentStory = Engine.GetStoryByCategoryAndIndex( category, storyCount )
				local storyTeam = Engine.GetStoryTeam( currentStory )
				local storyPlayer = Engine.GetStoryPlayer( currentStory )	
				local playerTier = Engine.GetPlayerTier( storyTeam, storyPlayer )
				if( storyTeam == userTeam ) then
					if( playerTier < 4 ) then
						table.insert( userPlayers, storyPlayer )
					end
					SetStages_Injury( storyTeam, storyPlayer, currentStory, storyCount )
				else
					if( playerTier < 4 ) then
						table.insert( cpuPlayers, storyPlayer )
					end
					SetStages_Injury( storyTeam, storyPlayer, currentStory, storyCount )
					if( cpuTeam == 0 ) then
						cpuTeam = storyTeam
					end
				end
			end
			local numInjuries = # userPlayers
			local teamToCompare = userTeam
			local injuredPlayerList = userPlayers
			for injuryCount = 1, 2 do
				if( injuryCount == 2 ) then
					numInjuries = # cpuPlayers
					teamToCompare = cpuTeam
					injuredPlayerList = cpuPlayers
				end
				if( numInjuries > 1 ) then
					if( StartStory_InjuryCrisis( teamToCompare, numInjuries ) == true ) then
						if( numInjuries >= 5 ) then
							InjuryCrisis_News( teamToCompare, injuredPlayerList )
						end
					end
				end
			end
		end
	end
end

function SetStages_Injury( teamId, playerId, currentStory, index )
	local posId = GetAudioPositionId( teamId, playerId )
	local playerTier = Engine.GetPlayerTier( teamId, playerId )
	if( playerTier < 3 ) then
		Engine.SetStoryStage( currentStory, posId )
		Engine.UpdateStoryActivity( currentStory )
		if( index == 1 ) then
			Engine.SetStringPlayers( playerId )
			Engine.SetStringTeams( teamId )
			PublishToPreview( nil, "news_body_injury_top_player_", 1, 100 )
		end
	else
		Engine.SetStoryStage( currentStory, 99 )
	end
end

function StartStory_InjuryCrisis( teamId, numInjuries )
	local category = "INJURY"
	local storyId = "INJURYCRISIS"
	local userTeam = Engine.GetUserTeam()
	local success = false
	local stage = 0 .. numInjuries
	if( teamId ~= userTeam ) then
		storyId = "CPU_" .. storyId
	end
	if( Engine.MarkPlayerForStory( teamId, 0, category, storyId ) == true ) then
		success = true
		local currentStory = Engine.GetStoryById( storyId )
		if( numInjuries > 5 ) then
			stage = 00
		end
		Engine.SetStoryStage( currentStory, stage )
		Engine.UpdateStoryActivity( currentStory )
		Engine.KillStoryAfterMatch( currentStory, false )
	end
	return success
end

function InjuryCrisis_News( teamToCompare, injuredPlayerList )
	local storyId = "INJURYCRISIS"
	local userTeam = Engine.GetUserTeam()
	local isCpu = ""
	local weight = Tuning.INJURY.newsWeight
	if( teamToCompare ~= userTeam ) then
		storyId = "CPU_" .. storyId
		if( Engine.IsStoryIDActive( "INJURYCRISIS" ) == true ) then
			local userStory = Engine.GetStoryById( "INJURYCRISIS" )
			local userStage = Engine.GetStoryStage( userStory )
			if( userStage == 00 or userStage == 01 ) then
				isCpu = "cpu_"
				weight = Tuning.INJURY.newsWeightCpu
			end
		end
	end
	if( Engine.IsStoryIDActive( storyId ) == true ) then
		local currentStory = Engine.GetStoryById( storyId )
		Engine.SetStringPlayers( injuredPlayerList[1], injuredPlayerList[2], injuredPlayerList[3], injuredPlayerList[4], injuredPlayerList[5] )
		Engine.SetStringTeams( teamToCompare, userTeam )
		PublishToPreview( currentStory, "news_body_injury_crisis_", 1, weight )
		local preview = Engine.GetNewsById( "PREVIEW" )
		if( isCpu == "" ) then
			Engine.SetStringTeams( teamToCompare )
			Engine.SetNewsCinematic ( "CM_News_ManagerActionNegative" )
			Engine.SetNewsHeadlineByObject( preview, "news_title_injury_crisis_", 1 )
		end
	end
end