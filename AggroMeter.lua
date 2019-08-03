AggroMeter = {}
local Version = "1.1"
local PlayerName = wstring.sub(GameData.Player.name,1,-3)

function AggroMeter.Initialize()
	RegisterEventHandler(TextLogGetUpdateEventId("Chat"), "AggroMeter.OnChatLogUpdated") -- runs the function when Chatlog gets a new text
	AggroMeter.Enabled = true
	CreateWindow("AggroMeter_Button", true)	
	
	AggroMeter.PlayersAggro = {}
	AggroMeter.AggroHolder = {}
	AggroMeter.MobID = {}
	AggroMeter.MobName = {}
	AggroMeter.MobRank	= {}
	AggroMeter.MaxAggro = {}
	AggroMeter.Timers = {}
	AggroMeter.Stacks = {}
	AggroMeter.CombatTime = {}	
	
	AggroMeter.HideChannel(65)

	if not AggroMeter.Settings then AggroMeter.Settings = {} end
	if not AggroMeter.Settings.Style then AggroMeter.Settings.Style = 1 end
	if not AggroMeter.Settings.ShowRank then AggroMeter.Settings.ShowRank = {true,true,true} end
end

function AggroMeter.Shutdown()
	UnregisterEventHandler(TextLogGetUpdateEventId("Chat"), "AggroMeter.OnChatLogUpdated")	
end

function AggroMeter.OnChatLogUpdated(updateType, filterType)
	if AggroMeter.Enabled == true then
			if( updateType == SystemData.TextLogUpdate.ADDED ) then 		
				if filterType == SystemData.ChatLogFilters.CHANNEL_9 then	
					local _, filterId, text = TextLogGetEntry( "Chat", TextLogGetNumEntries("Chat") - 1 ) 
					if text:find(L"NPC_AGGRO") then 
						AggroMeter.SplitText(text)
						if AggroMeter.Debug == true then DEBUG(text) end
					end
				end
			end
	end		
end

function AggroMeter.SplitText(text)
	if text ~= nil then
		text = tostring(text)
	end

	xListSplit = StringSplit(text, ";")
	xListSplit[#xListSplit] = nil
	local MobID = tostring(xListSplit[2])
	local MobRank = tostring(xListSplit[3])	
	local MobName = tostring(xListSplit[4])
	if AggroMeter.Settings.ShowRank[tonumber(MobRank)] == true then
		
		if DoesWindowExist("AggroMeterWindow"..MobID) == false then
		CreateWindowFromTemplate("AggroMeterWindow"..MobID, "AggroMeterWindow", "Root")
		WindowStartAlphaAnimation("AggroMeterWindow"..MobID, Window.AnimationType.SINGLE_NO_RESET, 0, 1, 0.5, false, 0, 0)
			for i=1,6 do	
				LabelSetText("AggroMeterWindow"..MobID.."AggroLabel"..i,L"Aggro"..towstring(i))					
				DynamicImageSetTexture("AggroMeterWindow"..MobID.."Tactic"..i,"icon022709",0,0)		
				StatusBarSetMaximumValue("AggroMeterWindow"..MobID.."Timer"..i.."Bar", 100  )
				StatusBarSetForegroundTint( "AggroMeterWindow"..MobID.."Timer"..i.."Bar", DefaultColor.GREEN.r, DefaultColor.GREEN.g, DefaultColor.GREEN.b )
				StatusBarSetBackgroundTint( "AggroMeterWindow"..MobID.."Timer"..i.."Bar", DefaultColor.BLACK.r, DefaultColor.BLACK.g, DefaultColor.BLACK.b )	
				LabelSetText("AggroMeterWindow"..MobID.."Timer"..i.."BarText",L"")	
			end	
			LabelSetText("AggroMeterWindow"..MobID.."NameLabel",L"MobName "..towstring(MobID))
			AggroMeter.Stacks[MobID] = 1
			AggroMeter.CombatTime[MobID] = 0
		end
		
		AggroMeter.MobID[MobID] = tostring(xListSplit[2])	
		AggroMeter.MobRank[MobID] = tostring(xListSplit[3])	
		AggroMeter.MobName[MobID] = tostring(xListSplit[4])	
		AggroMeter.PlayersAggro[MobID] = (#xListSplit-4)/4
		AggroMeter.AggroHolder[MobID] = {}
		
		for i=1,6 do
			LabelSetText("AggroMeterWindow"..MobID.."AggroLabel"..i,L"")
			WindowSetShowing("AggroMeterWindow"..MobID.."Timer"..i,false)
			WindowSetShowing("AggroMeterWindow"..MobID.."Tactic"..i,false)			
		end

		AggroMeter.MaxAggro[MobID] = 0

		for i=1,(AggroMeter.PlayersAggro[MobID]) do
			AggroMeter.AggroHolder[MobID][i] = {}
			AggroMeter.AggroHolder[MobID][i].name = tostring(xListSplit[(1+(i*4))])
			AggroMeter.AggroHolder[MobID][i].aggro = tonumber(xListSplit[(2+(i*4))])
			AggroMeter.AggroHolder[MobID][i].tactic = tonumber(xListSplit[(3+(i*4))])	
			AggroMeter.AggroHolder[MobID][i].career = tonumber(xListSplit[(4+(i*4))])				
			AggroMeter.MaxAggro[MobID] = AggroMeter.AggroHolder[MobID][1].aggro
		end

		for i=1,(AggroMeter.PlayersAggro[MobID]) do
			LabelSetText("AggroMeterWindow"..MobID.."AggroLabel"..i,towstring(AggroMeter.AggroHolder[MobID][i].name)..L"<icon"..towstring(Icons.GetCareerIconIDFromCareerLine(tonumber(AggroMeter.AggroHolder[MobID][i].career)))..L">")	
			StatusBarSetForegroundTint( "AggroMeterWindow"..MobID.."Timer"..i.."Bar", 255*(((AggroMeter.AggroHolder[MobID][i].aggro/AggroMeter.MaxAggro[MobID])*100)/100), 255*(1-(((AggroMeter.AggroHolder[MobID][i].aggro/AggroMeter.MaxAggro[MobID])*100)/100)), 0)
			StatusBarSetCurrentValue("AggroMeterWindow"..MobID.."Timer"..i.."Bar", (AggroMeter.AggroHolder[MobID][i].aggro/AggroMeter.MaxAggro[MobID])*100 )

				if towstring(AggroMeter.AggroHolder[MobID][i].name) == PlayerName then
						LabelSetTextColor("AggroMeterWindow"..MobID.."AggroLabel"..i, 0, 250, 100)
				else
						LabelSetTextColor("AggroMeterWindow"..MobID.."AggroLabel"..i, 255, 255, 77)
				end
			
				if AggroMeter.Settings.Style == 1 then
					if	AggroMeter.AggroHolder[MobID][i].aggro > 0 then
						LabelSetText("AggroMeterWindow"..MobID.."Timer"..i.."BarText",wstring.format(L"%.01f",(AggroMeter.AggroHolder[MobID][i].aggro/AggroMeter.MaxAggro[MobID])*100)..L"%")
					else
						LabelSetText("AggroMeterWindow"..MobID.."Timer"..i.."BarText",L"0%")
					end
				else
					LabelSetText("AggroMeterWindow"..MobID.."Timer"..i.."BarText",towstring(AggroMeter.AggroHolder[MobID][i].aggro))
				end
	
			WindowSetShowing("AggroMeterWindow"..MobID.."Tactic"..i,AggroMeter.AggroHolder[MobID][i].tactic > 0)	
			WindowSetShowing("AggroMeterWindow"..MobID.."Timer"..i,(LabelGetText("AggroMeterWindow"..MobID.."AggroLabel"..i) ~= ""))
		end
		
		LabelSetText("AggroMeterWindow"..MobID.."NameLabel",towstring(AggroMeter.MobName[MobID]))	
		AggroMeter.Timers[MobID] = 3
		WindowSetDimensions("AggroMeterWindow"..MobID,310,35+(25*AggroMeter.PlayersAggro[MobID]))		
	
		local StackHeight = 33

		for  k,v in pairs(AggroMeter.Stacks) do
		local width,height = WindowGetDimensions("AggroMeterWindow"..k)
			WindowClearAnchors("AggroMeterWindow"..k)
			WindowAddAnchor("AggroMeterWindow"..k, "topright", "AggroMeter_Button", "topright",-33,StackHeight)		
			StackHeight = StackHeight + (height+5)
		end	
	end
end

function AggroMeter.OnMouseOverStart()
	local WinParent = WindowGetParent(SystemData.MouseOverWindow.name)
	local WindowName = towstring(SystemData.MouseOverWindow.name)
	
	if WindowName:match(L"AggroMeterWindow([%d.]+)Timer.") then
		local MobNumber = 	tostring(WindowName:match(L"AggroMeterWindow([%d.]+)Timer."))
		local TimerNumber = tonumber(WindowName:match(L"Timer([^%.]+)"))
		local Ttip = L""
			Tooltips.CreateTextOnlyTooltip(SystemData.MouseOverWindow.name,nil)
			Tooltips.SetTooltipText( 1, 1,towstring(AggroMeter.AggroHolder[tostring(MobNumber)][tonumber(TimerNumber)].name))
			Tooltips.SetTooltipColorDef( 1, 1, Tooltips.MAP_DESC_TEXT_COLOR )
			if AggroMeter.AggroHolder[tostring(MobNumber)][tonumber(TimerNumber)].aggro > 0 then
				Ttip =  wstring.format(L"%.01f",(AggroMeter.AggroHolder[tostring(MobNumber)][tonumber(TimerNumber)].aggro/AggroMeter.MaxAggro[tostring(MobNumber)])*100)..L"%"
			else
				Ttip = L"0%"
			end
			Tooltips.SetTooltipText( 1, 3, Ttip)
			Tooltips.SetTooltipText( 2, 1, L"Hatred: "..towstring(AggroMeter.AggroHolder[tostring(MobNumber)][TimerNumber].aggro)..L" / "..towstring(AggroMeter.MaxAggro[tostring(MobNumber)]))		
	elseif WindowName:match(L"AggroMeterWindow([%d.]+)Tactic.") then
		local MobNumber = 	tostring(WindowName:match(L"AggroMeterWindow([%d.]+)Tactic."))
		local TacticNumber = tonumber(WindowName:match(L"Tactic([^%.]+)"))
		Tooltips.CreateTextOnlyTooltip(SystemData.MouseOverWindow.name,nil)
		Tooltips.SetTooltipText( 1, 1,L"This player is using "..towstring(GetAbilityName(tonumber(AggroMeter.AggroHolder[tostring(MobNumber)][tonumber(TacticNumber)].tactic)))..L" Tactic")
		Tooltips.SetTooltipColorDef( 1, 1, Tooltips.MAP_DESC_TEXT_COLOR )
	elseif WindowName:match(L"AggroMeter_Button") then
			Tooltips.CreateTextOnlyTooltip(SystemData.MouseOverWindow.name,nil)
			Tooltips.SetTooltipText( 1, 1,L"AggroMeter")
			Tooltips.SetTooltipColorDef( 1, 1, Tooltips.MAP_DESC_TEXT_COLOR )
			Tooltips.SetTooltipText( 1, 3, L"Ver: "..towstring(Version))
			Tooltips.SetTooltipText( 2, 1, L"RightClick for options")					
	end
	
	Tooltips.Finalize()    
	Tooltips.AnchorTooltip( Tooltips.ANCHOR_WINDOW_TOP )
	
end

function AggroMeter.SelectChar()
	local WinParent = WindowGetParent(SystemData.MouseOverWindow.name)
	local WindowName = towstring(SystemData.MouseOverWindow.name)
	local MobNumber = 	tostring(WindowName:match(L"AggroMeterWindow([%d.]+)AggroLabel."))
	local LabelNumber = tonumber(WindowName:match(L"AggroLabel([^%.]+)"))
		
	WindowSetGameActionData(tostring(WindowName),GameData.PlayerActions.SET_TARGET,0,towstring(AggroMeter.AggroHolder[tostring(MobNumber)][tonumber(LabelNumber)].name))	
end

function AggroMeter.OnTabRBU()

local function MakeCallBack( SelectedOption )
		    return function() AggroMeter.ToggleShow(SelectedOption) end
		end

	EA_Window_ContextMenu.CreateContextMenu( SystemData.MouseOverWindow.name, EA_Window_ContextMenu.CONTEXT_MENU_1,L"Options")
    EA_Window_ContextMenu.AddMenuDivider( EA_Window_ContextMenu.CONTEXT_MENU_1 )	
	if AggroMeter.Enabled == true then  
		EA_Window_ContextMenu.AddMenuItem( L"<icon00057> Enabled" , AggroMeter.ToggeEnable, false, true )
	else
		EA_Window_ContextMenu.AddMenuItem( L"<icon00058> Disabled" , AggroMeter.ToggeEnable, false, true )
	end

	if AggroMeter.Settings.ShowRank[1] == true then
		EA_Window_ContextMenu.AddMenuItem( L"   <icon00057> Champions" , MakeCallBack(1), not AggroMeter.Enabled, true )	
	else
		EA_Window_ContextMenu.AddMenuItem( L"   <icon00058> Champions" , MakeCallBack(1), not AggroMeter.Enabled, true )	
	end
	
	if AggroMeter.Settings.ShowRank[2] == true then
		EA_Window_ContextMenu.AddMenuItem( L"   <icon00057> Heroes" , MakeCallBack(2), not AggroMeter.Enabled, true )	
	else
		EA_Window_ContextMenu.AddMenuItem( L"   <icon00058> Heroes" , MakeCallBack(2), not AggroMeter.Enabled, true )	
	end	

	if AggroMeter.Settings.ShowRank[3] == true then
		EA_Window_ContextMenu.AddMenuItem( L"   <icon00057> Lords" , MakeCallBack(3), not AggroMeter.Enabled, true )	
	else
		EA_Window_ContextMenu.AddMenuItem( L"   <icon00058> Lords" , MakeCallBack(3), not AggroMeter.Enabled, true )	
	end
    EA_Window_ContextMenu.AddMenuDivider( EA_Window_ContextMenu.CONTEXT_MENU_1 )	
	if AggroMeter.Settings.Style == 1 then
		EA_Window_ContextMenu.AddMenuItem( L"AggroBar: Percentage" , AggroMeter.ToggeBar, false, true )	
	else
		EA_Window_ContextMenu.AddMenuItem( L"AggroBar: Numbers" , AggroMeter.ToggeBar, false, true )	
	end
	
	EA_Window_ContextMenu.Finalize()	
end

function AggroMeter.ToggeEnable()
	AggroMeter.Enabled = not AggroMeter.Enabled
	AggroMeter.OnTabRBU()	
end

function AggroMeter.ToggeBar()
	if AggroMeter.Settings.Style == 1 then 
		AggroMeter.Settings.Style = 2 
	else 
		AggroMeter.Settings.Style = 1 
	end
end

function AggroMeter.ToggleShow(SelectedOption)
	AggroMeter.Settings.ShowRank[tonumber(SelectedOption)] = not AggroMeter.Settings.ShowRank[tonumber(SelectedOption)]	
end

function AggroMeter.OnUpdate(timeElapsed)
	for  k,v in pairs(AggroMeter.Timers) do
		LabelSetText("AggroMeterWindow"..k.."CombatLabel",towstring(TimeUtils.FormatClock(AggroMeter.CombatTime[k])))	
			
		AggroMeter.Timers[k] = v - timeElapsed
		AggroMeter.CombatTime[k] = AggroMeter.CombatTime[k] + timeElapsed

		if v <= 0 then
			DestroyWindow( "AggroMeterWindow"..k )
			AggroMeter.Timers[k] = nil
			AggroMeter.Stacks[k] = nil	
			AggroMeter.CombatTime[k] = nil		
		end
	end
end

function AggroMeter.HideChannel(channelId)
	for _, wndGroup in ipairs(EA_ChatWindowGroups) do 
		if wndGroup.used == true then
			for tabId, tab in ipairs(wndGroup.Tabs) do
				local tabName = EA_ChatTabManager.GetTabName( tab.tabManagerId )		
				if tabName then
					if tab.tabText ~= L"Debug" then
						LogDisplaySetFilterState(tabName.."TextLog", "Chat", channelId, false)
					else
						LogDisplaySetFilterState(tabName.."TextLog", "Chat", channelId, true)
						LogDisplaySetFilterColor(tabName.."TextLog", "Chat", channelId, 168, 187, 160 )
					end
				end
				
			end
			
		end
		
	end	
end

