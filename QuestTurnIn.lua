QuestTurnIn_EventHandler = CreateFrame("FRAME")
QuestTurnIn_EventHandler:RegisterEvent("ADDON_LOADED")
local QuestTurnIn_EventList = {
    "QUEST_PROGRESS",
    "QUEST_COMPLETE",
    "GOSSIP_SHOW",
    "QUEST_GREETING"
}

function QuestTurnIn_RegisterEvents()
    for _, e in QuestTurnIn_EventList do
        QuestTurnIn_EventHandler:RegisterEvent(e)
    end
end

function QuestTurnIn_UnregisterEvents()
    for _, e in QuestTurnIn_EventList do
        QuestTurnIn_EventHandler:UnregisterEvent(e)
    end
end

local function filterEvens(t)
    local r = {}
    for k, v in t do
        if math.mod(k, 2) ~= 0 then
            r[(k + 1) / 2] = v
        end
    end
    return r
end

function menuHandler(available, active, name, complete)
    local function SetupBackground(b)
        b:SetAllPoints(b:GetParent())
        b:SetDrawLayer("BACKGROUND", -1)
        b:SetTexture(1, 1, 1)
        b:SetGradientAlpha("HORIZONTAL", 0.5, 1, 0, 0.5, 1, 1, 0, 0)
    end

    for i = 1, 32 do
        local f = getglobal(name .. i)

        if f.QTurnIn == nil then
            f.QTurnIn = { background = f:CreateTexture(), oldScript = f:GetScript("OnClick") }
            SetupBackground(f.QTurnIn.background)
            local function OnClick(...)
                f.QTurnIn.oldScript(unpack(arg))
            end
            f:SetScript("OnClick", OnClick)
        end
        if QuestTurnIn.autolist[f:GetText()] then
            f.QTurnIn.background:Show()
        else
            f.QTurnIn.background:Hide()
        end
    end
    if IsShiftKeyDown() then
        local logCompleted = {}
        for k = 1, GetNumQuestLogEntries() do
            local title, _, _, _, _, completed = GetQuestLogTitle(k)
            if completed then

                logCompleted[title] = true
            end

            if string.find(title, "Daily: Victory in Warsong Gulch") or string.find(title, "Daily: Victory in ZF Brawl") or string.find(title, "Daily: Victory in Arathi Basin") or string.find(title, "Daily: Victory in Alterac Valley") then
                local done
                for ldrIndex = 1, GetNumQuestLeaderBoards(k) do
                    local desc, type, currentDone = GetQuestLogLeaderBoard(ldrIndex, k)
                    done = currentDone or done 
                end

                if done then
)
                    logCompleted[title] = true
                end
            end
        end

        for k, v in active do
            if logCompleted[v] then
                QuestTurnIn.currentQuest = v
                complete(k)
                return
            end
        end


        if next(available) then
            QuestTurnIn.currentQuest = available[1]
            complete(1)
            return
        end


        if next(active) then
            QuestTurnIn.currentQuest = active[1]
            complete(1)
            return
        end
    end
end

function QuestTurnIn_EventHandler.GOSSIP_SHOW()
    local available = filterEvens({ GetGossipAvailableQuests() })
    local active = filterEvens({ GetGossipActiveQuests() })
    local name = "GossipTitleButton"
    menuHandler(available, active, name, SelectGossipActiveQuest)
end

function QuestTurnIn_EventHandler.QUEST_GREETING()
    local available = {}
    local active = {}
    for k = 1, GetNumAvailableQuests() do
        table.insert(available, GetAvailableTitle(k))
    end
    for k = 1, GetNumActiveQuests() do
        table.insert(active, GetActiveTitle(k))
    end
    local name = "QuestTitleButton"
    menuHandler(available, active, name, SelectActiveQuest)
end

function QuestTurnIn_EventHandler.QUEST_PROGRESS()
    local title = GetTitleText()

    if QuestTurnIn.currentQuest == title or QuestTurnIn_IsAutoComplete(title) ~= (IsShiftKeyDown() ~= nil) then
        QuestTurnIn.currentQuest = title
        CompleteQuest()
    else
        QuestTurnIn.currentQuest = ""
    end
end

function QuestTurnIn_EventHandler.QUEST_COMPLETE()
    local title = GetTitleText()

    if QuestTurnIn.currentQuest == title or QuestTurnIn_IsAutoComplete(title) ~= (IsShiftKeyDown() ~= nil) then
        UIErrorsFrame:AddMessage("Quest completed: " .. title)
    end
    QuestTurnIn.currentQuest = ""
end



function QuestTurnIn_EventHandler.ADDON_LOADED()
    if arg1 == "QuestGrabber_1.12.1" then
        QuestTurnIn_Session = {}
        if QuestTurnIn == nil or QuestTurnIn.autolist == nil then
            QuestTurnIn = { autolist = {}, dataVersion = "1.0.0" }
        end
        if QuestTurnIn.dataVersion == nil then
            local tmp = {}
            for k, _ in QuestTurnIn.autolist do
                tmp[k] = { complete = true }
            end
            QuestTurnIn.autolist = tmp
            QuestTurnIn.dataVersion = "1.0.0"
        end
        QuestTurnIn_RegisterEvents()
        QuestTurnIn_EventHandler:UnregisterEvent("ADDON_LOADED")
        DEFAULT_CHAT_FRAME:AddMessage("QuestGrabber 1.2.0 |cff00FF00 loaded.|cffffffff /qg for help.")
    end
end

QuestTurnIn_EventHandler:SetScript("OnEvent",
    function ()
        if QuestTurnIn_EventHandler[event] then
            QuestTurnIn_EventHandler[event]()
        end
    end
)

function QuestTurnIn_IsAutoComplete(title)
    return (QuestTurnIn.autolist[title] or false) and QuestTurnIn.autolist[title].complete
end

function QuestTurnIn_AddAutoComplete(title)
    if QuestTurnIn_IsAutoComplete(title) then return end
    if QuestTurnIn.autolist[title] == nil then QuestTurnIn.autolist[title] = {} end
    QuestTurnIn.autolist[title].complete = true
end

function QuestTurnIn_Proceed()
    if GossipFrame:IsShown() then
        QuestTurnIn.currentQuest = GetGossipActiveQuests()
        SelectGossipActiveQuest(1)
    elseif QuestFrame:IsShown() then
        local title = GetTitleText()
        if QuestFrameCompleteButton:IsShown() and IsQuestCompletable() then
            QuestTurnIn.currentQuest = title
            CompleteQuest()
        end
    end
end


local function SlashHandler(msg)
    if msg == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("1. Talk to a quest NPC, select the quests you want to automatically collect.", 1, 1, 0.5)
        DEFAULT_CHAT_FRAME:AddMessage("2. Remove the NPC quest window and hold Shift and right-click the NPC.", 1, 1, 0.5)
        DEFAULT_CHAT_FRAME:AddMessage("3. To turn in quests automatically, just hold Shift and right-click the NPC when the quest is done.", 1, 1, 0.5)
        DEFAULT_CHAT_FRAME:AddMessage("4. Right click to move the frame.", 1, 1, 0.5)		
    end
end

SLASH_QG1 = "/qg"
SlashCmdList["QG"] = SlashHandler
