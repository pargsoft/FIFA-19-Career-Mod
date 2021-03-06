-- "PREVIEW" news are blocked from C++ code in SendNews(), even if their logic is still kept in Lua code. So, they no longer get sent.

--------------------------------SUSPENSIONS----------------------------------------
function ExamineFor_SuspensionStories( numDays, gametype, fixture )
	if( numDays == 0 ) then
		local category = "SUSPENSION"
		local numStories = Engine.GetNumStoriesByCategory( category )
		if( numStories > 0 ) then
			local userTeam = Engine.GetUserTeam()
			local cpuSuspensions = 0
			local userSuspensions = 0
			local cpuTeam = 0
			local userPlayers = {}
			local cpuPlayers = {}
			for storyCount = 1, numStories do
				local currentStory = Engine.GetStoryByCategoryAndIndex( category, storyCount )
				local storyTeam = Engine.GetStoryTeam( currentStory )
				local storyPlayer = Engine.GetStoryPlayer( currentStory )	
				if( storyTeam == userTeam ) then
					table.insert( userPlayers, storyPlayer )
					SetStages_Suspensions( storyTeam, storyPlayer, currentStory, storyCount )
				else
					table.insert( cpuPlayers, storyPlayer )
					SetStages_Suspensions( storyTeam, storyPlayer, currentStory, storyCount )
					if( cpuTeam == 0 ) then
						cpuTeam = storyTeam
					end
				end
			end
			local numSuspensions = # userPlayers
			local teamToCompare = userTeam
			local suspendedPlayerList = userPlayers
			for suspensionCount = 1, 2 do
				if( suspensionCount == 2 ) then
					numSuspensions = # cpuPlayers
					teamToCompare = cpuTeam
					suspendedPlayerList = cpuPlayers
				end
				if( numSuspensions > 1 ) then
					if( StartStory_SuspensionCrisis( teamToCompare, numSuspensions ) == true ) then
						SuspensionCrisis_News( teamToCompare, suspendedPlayerList )
					end
				end
			end
		end
	end
end

function SetStages_Suspensions( teamId, playerId, currentStory, index )
	local posId = GetAudioPositionId( teamId, playerId )
	local playerTier = Engine.GetPlayerTier( teamId, playerId )
	if( playerTier < 3 ) then
		Engine.SetStoryStage( currentStory, posId )
		Engine.UpdateStoryActivity( currentStory )
		if( index == 1 ) then
			Engine.SetStringPlayers( playerId )
			Engine.SetStringTeams( teamId )
			local newsWeight = Tuning.SUSPENSIONS.topPlayerSuspensionNewsWeight
			PublishToPreview( nil, "news_body_suspension_top_player_", 1, newsWeight )
		end
	end
end

function StartStory_SuspensionCrisis( teamId, numSuspensions )
	local category = "SUSPENSION"
	local storyId = "SUSPENSIONCRISIS"
	local userTeam = Engine.GetUserTeam()
	local success = false
	local stage = 0 .. numSuspensions
	if( teamId ~= userTeam ) then
		storyId = "CPU_" .. storyId
	end
	if( Engine.MarkPlayerForStory( teamId, 0, category, storyId ) == true ) then
		success = true
		local currentStory = Engine.GetStoryById( storyId )
		if( numSuspensions <= Tuning.SUSPENSIONS.maxNumSuspensionsToUpdateStory ) then
			Engine.SetStoryStage( currentStory, stage )
			Engine.UpdateStoryActivity( currentStory )
		end
		Engine.KillStoryAfterMatch( currentStory, false )
	end
	return success
end

function SuspensionCrisis_News( teamToCompare, suspendedPlayerList )
	local storyId = "SUSPENSIONCRISIS"
	local userTeam = Engine.GetUserTeam()
	local isCpu = ""
	local newsWeight = Tuning.SUSPENSIONS.suspensionCrisisNewsWeight
	if( teamToCompare ~= userTeam ) then
		storyId = "CPU_" .. storyId
		if( Engine.IsStoryIDActive( "SUSPENSIONCRISIS" ) == true ) then
			local userStory = Engine.GetStoryById( "SUSPENSIONCRISIS" )
			local userStage = Engine.GetStoryStage( userStory )
			if( userStage == 00 or userStage == 01 ) then
				isCpu = "cpu_"
				newsWeight = newsWeight - 1
			end
		end
	end
	if( Engine.IsStoryIDActive( storyId ) == true ) then
		local currentStory = Engine.GetStoryById( storyId )
		Engine.SetStringPlayers( suspendedPlayerList[1], suspendedPlayerList[2], suspendedPlayerList[3], suspendedPlayerList[4], suspendedPlayerList[5] )
		Engine.SetStringTeams( teamToCompare, userTeam )
		PublishToPreview( currentStory, "news_body_suspension_crisis_", 1, newsWeight )
		local preview = Engine.GetNewsById( "PREVIEW" )
		if( isCpu == "" ) then
			Engine.SetStringTeams( teamToCompare )
			Engine.SetNewsHeadlineByObject( preview, "news_title_suspension_crisis_", 1 )
		end
	end
end