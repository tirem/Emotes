-- Copyright (c) 2023 Tirem
-- Modified for Emotes addon

addon.name      = 'Emotes';
addon.author    = 'Tirem & Kidogo';
addon.version   = '1.0';
addon.desc      = 'Provides an ImGui window with a grid of emotes for easy access';
addon.link      = 'https://github.com/tirem/Emotes';

require('common');
local chat = require('chat');
local imgui = require('imgui');
local ffi = require('ffi');
local d3d = require('d3d8');
local settings = require('settings');
local types = require('types');
local helpers = require('helpers');
local C = ffi.C;
local d3d8dev = d3d.get_device();

-- Configuration
local user_settings = T{
    displayLogMessage = { true },
    showToggleButton = { true },
    globalScale = { types.DEFAULTS.SCALE },
};

local user_settings_container = T{
    userSettings = user_settings;
};

local config = settings.load(user_settings_container);
local gConfig = config.userSettings;



-- Non-saved settings (always default values)
local localSettings = T{
    showWindow = { false },
    mainColumns = types.GRID_DEFAULTS.MAIN_COLUMNS,
    jobEmoteColumns = types.GRID_DEFAULTS.JOB_EMOTE_COLUMNS,
    chairColumns = types.GRID_DEFAULTS.CHAIR_COLUMNS,
    windowSize = types.WINDOW_DEFAULTS.INITIAL_SIZE,
    globalScale = types.DEFAULTS.SCALE,
    currentTab = types.TABS.MAIN,

};



-- Load texture function wrapper
local function LoadTexture(textureName, subfolder)
    return helpers.LoadTexture(textureName, subfolder, addon.path);
end

-- Cache all emote textures at startup
local emoteTextures = {};
local jobEmoteTextures = {};
local chairTextures = {};
local blankTexture = LoadTexture(types.TEXTURES.BLANK);
local frameTexture = LoadTexture(types.TEXTURES.FRAME);

-- Function to cache textures for a given list
local function CacheTexturesForList(list, textureCache, useJobFormat)
    for i = 1, #list do
        local item = list[i];
        local textureName;
        local subfolder;
        
        if useJobFormat then
            -- For job emotes, use the job abbreviation and look in Jobs subfolder
            textureName = types.jobAbbreviations[item];
            subfolder = types.PATHS.JOB_SUBFOLDER;
        else
            -- For regular emotes, use the emote name directly
            textureName = item;
            subfolder = nil;
        end
        
        local texture = LoadTexture(textureName, subfolder);
        if texture then
            textureCache[item] = texture;
        else
            -- Fall back to blank texture if specific image doesn't exist
            textureCache[item] = blankTexture;
        end
    end
end

-- Function to cache chair textures (all use frame texture)
local function CacheChairTextures()
    for i = 1, #types.chairs do
        local chair = types.chairs[i];
        chairTextures[chair.name] = frameTexture or blankTexture;
    end
end

-- Function to update all scales based on global scale
local function UpdateScales()
    local globalScale = gConfig.globalScale[1];
    -- Store global scale for use in UI
    localSettings.globalScale = globalScale;
    
    -- Scale the window size
    localSettings.windowSize = { 
        types.WINDOW_DEFAULTS.INITIAL_SIZE[1] * globalScale, 
        types.WINDOW_DEFAULTS.INITIAL_SIZE[2] * globalScale 
    };
end

-- Cache all textures
CacheTexturesForList(types.emotes, emoteTextures, false);
CacheTexturesForList(types.jobEmotes, jobEmoteTextures, true);
CacheChairTextures();

-- Update scales after config is loaded
UpdateScales();

-- Helper function to save settings properly
local function SaveSettings()
    settings.save();
end

-- Function to execute a regular emote
local function ExecuteEmote(emoteName)
    local command = types.COMMANDS.PREFIX .. emoteName;
    if (not gConfig.displayLogMessage[1]) then
        command = command .. types.COMMANDS.MOTION_SUFFIX;
    end
    AshitaCore:GetChatManager():QueueCommand(-1, command);
end

-- Function to execute a sitchair emote with chair number
local function ExecuteSitchair(chairNumber)
    local command;
    if chairNumber == 0 then
        command = types.COMMANDS.SITCHAIR;
    else
        command = types.COMMANDS.SITCHAIR .. ' ' .. chairNumber;
    end
    if (not gConfig.displayLogMessage[1]) then
        command = command .. types.COMMANDS.MOTION_SUFFIX;
    end
    AshitaCore:GetChatManager():QueueCommand(-1, command);
end

-- Function to execute a job emote
local function ExecuteJobEmote(jobName)
    local command = types.COMMANDS.JOBEMOTE .. ' "' .. jobName .. '"';
    AshitaCore:GetChatManager():QueueCommand(-1, command);
end





-- Function to draw a grid of chairs with numbers overlaid on border icons
local function DrawChairGrid(chairList, textureCache, columns)
    local windowWidth = imgui.GetWindowWidth();
    local buttonWidth, buttonHeight, iconSize = 
        helpers.CalculateGridDimensions(windowWidth, columns, localSettings.globalScale);
    
    for i = 1, #chairList do
        local chair = chairList[i];
        
        imgui.PushID(chair.name);
        
        -- Draw an invisible button that covers the entire row area
        local pressed = imgui.InvisibleButton("##" .. chair.name, { buttonWidth, iconSize });
        
        -- Get the button area bounds for positioning content
        local buttonStartX, buttonStartY = imgui.GetItemRectMin();
        local buttonEndX, buttonEndY = imgui.GetItemRectMax();
        
        -- Draw hover background if the button is hovered
        if imgui.IsItemHovered() then
            imgui.GetWindowDrawList():AddRectFilled(
                { buttonStartX, buttonStartY }, 
                { buttonEndX, buttonEndY }, 
                types.GRID_DEFAULTS.HOVER_BACKGROUND_COLOR
            );
        end
        
        -- Draw the chair frame image at the start of the button area
        local chairTexture = textureCache[chair.name];
        if chairTexture and chairTexture.image then
            imgui.GetWindowDrawList():AddImage(
                tonumber(ffi.cast("uint32_t", chairTexture.image)), 
                { buttonStartX, buttonStartY }, 
                { buttonStartX + iconSize, buttonStartY + iconSize }
            );
            
            -- Draw number overlay on the icon
            local numberStr = tostring(chair.number);
            local textWidth, textHeight = imgui.CalcTextSize(numberStr);
            local textX = buttonStartX + (iconSize - textWidth) / 2;
            local textY = buttonStartY + (iconSize - textHeight) / 2;
            
            imgui.GetWindowDrawList():AddText({ textX, textY }, types.GRID_DEFAULTS.TEXT_COLOR, numberStr);
        end
        
        -- Draw the text next to the image
        local textX = buttonStartX + iconSize + (types.GRID_DEFAULTS.IMAGE_TEXT_GAP * localSettings.globalScale);
        local _, textHeight = imgui.CalcTextSize(chair.name);
        local textY = buttonStartY + (iconSize - textHeight) / 2;
        imgui.GetWindowDrawList():AddText({ textX, textY }, types.GRID_DEFAULTS.TEXT_COLOR, chair.name);
        
        imgui.PopID();
        
        if pressed then
            ExecuteSitchair(chair.number);
        end
        
        if (imgui.IsItemHovered()) then
            helpers.CreateTooltip(chair.name);
        end
        
        if (i % columns ~= 0) then
            imgui.SameLine();
        end
    end
end

-- Function to draw a grid of emotes/job emotes
local function DrawEmoteGrid(itemList, textureCache, isJobEmote, columns)
    local windowWidth = imgui.GetWindowWidth();
    local buttonWidth, buttonHeight, iconSize = 
        helpers.CalculateGridDimensions(windowWidth, columns, localSettings.globalScale);
    
    for i = 1, #itemList do
        local item = itemList[i];
        local displayName = helpers.GetDisplayName(item, isJobEmote);
        
        imgui.PushID(item);
        
        -- Draw an invisible button that covers the entire row area
        local pressed = imgui.InvisibleButton("##" .. item, { buttonWidth, iconSize });
        
        -- Get the button area bounds for positioning content
        local buttonStartX, buttonStartY = imgui.GetItemRectMin();
        local buttonEndX, buttonEndY = imgui.GetItemRectMax();
        
        -- Draw hover background if the button is hovered
        if imgui.IsItemHovered() then
            imgui.GetWindowDrawList():AddRectFilled(
                { buttonStartX, buttonStartY }, 
                { buttonEndX, buttonEndY }, 
                types.GRID_DEFAULTS.HOVER_BACKGROUND_COLOR
            );
        end
        
        -- Draw the image at the start of the button area
        local itemTexture = textureCache[item];
        if itemTexture and itemTexture.image then
            imgui.GetWindowDrawList():AddImage(
                tonumber(ffi.cast("uint32_t", itemTexture.image)), 
                { buttonStartX, buttonStartY }, 
                { buttonStartX + iconSize, buttonStartY + iconSize }
            );
        end
        
        -- Draw the text next to the image
        local textX = buttonStartX + iconSize + (types.GRID_DEFAULTS.IMAGE_TEXT_GAP * localSettings.globalScale);
        local _, textHeight = imgui.CalcTextSize(displayName);
        local textY = buttonStartY + (iconSize - textHeight) / 2;
        imgui.GetWindowDrawList():AddText({ textX, textY }, types.GRID_DEFAULTS.TEXT_COLOR, displayName);
        
        imgui.PopID();
        
        if pressed then
            if isJobEmote then
                ExecuteJobEmote(item);
            else
                ExecuteEmote(item);
            end
        end
        
        if (imgui.IsItemHovered()) then
            helpers.CreateTooltip(displayName);
        end
        
        if (i % columns ~= 0) then
            imgui.SameLine();
        end
    end
end



-- Function to draw the toggle button window
local function DrawToggleButton()
    if (not gConfig.showToggleButton[1]) then
        return;
    end

    -- Set window flags for a minimal button window
    -- Check if Ctrl is held to allow dragging
    local isCtrlHeld = imgui.GetIO().KeyCtrl;
    local windowFlags = bit.bor(
        ImGuiWindowFlags_NoTitleBar,
        ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoScrollbar,
        ImGuiWindowFlags_NoCollapse,
        ImGuiWindowFlags_AlwaysAutoResize,
        ImGuiWindowFlags_NoBackground
    );
    
    -- Only add NoMove flag if Ctrl is NOT held
    if not isCtrlHeld then
        windowFlags = bit.bor(windowFlags, ImGuiWindowFlags_NoMove);
    end
    
    -- Set initial position (will be overridden by user dragging)
    imgui.SetNextWindowPos(types.TOGGLE_BUTTON.INITIAL_POS, ImGuiCond_FirstUseEver);
    
    if (imgui.Begin('EmotesToggle', gConfig.showToggleButton, windowFlags)) then
        local emotesTexture = LoadTexture(types.TEXTURES.EMOTES_ICON);
        local buttonSize = helpers.CreateScaledSize(types.TOGGLE_BUTTON.SIZE, localSettings.globalScale);
        
        local toggleAction = function()
            if not isCtrlHeld then
                localSettings.showWindow[1] = not localSettings.showWindow[1];
            end
        end;
        
        helpers.DrawImageButtonWithFallback(emotesTexture, types.UI_TEXT.TOGGLE_FALLBACK, { buttonSize, buttonSize }, toggleAction);
        
        -- Add tooltip when hovering
        if imgui.IsItemHovered() then
            helpers.CreateTooltip(types.UI_TEXT.TOGGLE_TOOLTIP);
        end
    end
    imgui.End();
end

-- Function to draw the emotes window
local function DrawEmotesWindow()
    if (not localSettings.showWindow[1]) then
        return;
    end

    -- Set initial position to center of screen
    imgui.SetNextWindowPos(types.WINDOW_DEFAULTS.INITIAL_POS, ImGuiCond_FirstUseEver);
    imgui.SetNextWindowSize(localSettings.windowSize, ImGuiCond_FirstUseEver);
    
    -- Set window flags to remove title bar and minimize button
    local windowFlags = bit.bor(ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoCollapse);
    
    -- Add rounded corners to the window
    imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, types.WINDOW_DEFAULTS.ROUNDING);
    
    if (imgui.Begin(types.UI_TEXT.WINDOW_TITLE, localSettings.showWindow, windowFlags)) then
        -- Apply global scaling to the entire window
        imgui.SetWindowFontScale(localSettings.globalScale);
        
        -- Custom title bar
        local emotesTexture = LoadTexture(types.TEXTURES.EMOTES_ICON);
        local closeTexture = LoadTexture(types.TEXTURES.CLOSE_BUTTON);
        
        local windowWidth = imgui.GetWindowWidth();
        local titleBarHeight = helpers.CreateScaledSize(types.TITLE_BAR.HEIGHT, localSettings.globalScale);
        
        -- Left side: Emotes icon and text
        imgui.SetCursorPos(helpers.CreateScaledPosition({ types.TITLE_BAR.LEFT_MARGIN, types.TITLE_BAR.TOP_MARGIN }, localSettings.globalScale));
        if emotesTexture then
            local iconSize = helpers.CreateScaledSize(types.TITLE_BAR.ICON_SIZE, localSettings.globalScale);
            imgui.Image(tonumber(ffi.cast("uint32_t", emotesTexture.image)), { iconSize, iconSize });
            imgui.SameLine();
        end
        
        -- Large "Emotes" text (extra scale for title)
        imgui.SetWindowFontScale(localSettings.globalScale * types.TITLE_BAR.TITLE_SCALE_MULTIPLIER);
        imgui.Text(types.UI_TEXT.WINDOW_TITLE);
        imgui.SetWindowFontScale(localSettings.globalScale);
        
        -- Right side: Close button
        imgui.SameLine(windowWidth - helpers.CreateScaledSize(types.TITLE_BAR.ICON_SIZE, localSettings.globalScale));
        imgui.SetCursorPosY(helpers.CreateScaledSize(types.TITLE_BAR.TOP_MARGIN, localSettings.globalScale));
        
        local closeButtonSize = helpers.CreateScaledSize(types.TITLE_BAR.CLOSE_BUTTON_SIZE, localSettings.globalScale);
        local closeAction = function()
            localSettings.showWindow[1] = false;
        end;
        
        helpers.DrawImageButtonWithFallback(closeTexture, types.UI_TEXT.CLOSE_FALLBACK, { closeButtonSize, closeButtonSize }, closeAction);
        
        -- Add some spacing after custom title bar
        imgui.SetCursorPosY(titleBarHeight + helpers.CreateScaledSize(types.TITLE_BAR.SPACING_AFTER, localSettings.globalScale));
        -- Draw tabs
        if (imgui.BeginTabBar('EmoteTabs')) then
            local generalTabOpen = imgui.BeginTabItem(types.UI_TEXT.TAB_GENERAL);
            if (generalTabOpen) then
                localSettings.currentTab = types.TABS.MAIN;
                
                -- Create scrollable child window for main emotes
                local childBottomMargin = helpers.CreateScaledSize(types.GRID_DEFAULTS.CHILD_BOTTOM_MARGIN, localSettings.globalScale);
                imgui.BeginChild('MainEmotesGrid', { 0, -childBottomMargin }, true);
                DrawEmoteGrid(types.emotes, emoteTextures, false, localSettings.mainColumns);
                imgui.EndChild();
                
                imgui.EndTabItem();
            end
            
            local jobEmotesTabOpen = imgui.BeginTabItem(types.UI_TEXT.TAB_JOB_EMOTES);
            if (jobEmotesTabOpen) then
                localSettings.currentTab = types.TABS.JOB_EMOTES;
                
                -- Create scrollable child window for job emotes
                local childBottomMargin = helpers.CreateScaledSize(types.GRID_DEFAULTS.CHILD_BOTTOM_MARGIN, localSettings.globalScale);
                imgui.BeginChild('JobEmotesGrid', { 0, -childBottomMargin }, true);
                DrawEmoteGrid(types.jobEmotes, jobEmoteTextures, true, localSettings.jobEmoteColumns);
                imgui.EndChild();
                
                imgui.EndTabItem();
            end
            
            local chairsTabOpen = imgui.BeginTabItem(types.UI_TEXT.TAB_CHAIRS);
            if (chairsTabOpen) then
                localSettings.currentTab = types.TABS.CHAIRS;
                
                -- Create scrollable child window for chairs
                local childBottomMargin = helpers.CreateScaledSize(types.GRID_DEFAULTS.CHILD_BOTTOM_MARGIN, localSettings.globalScale);
                imgui.BeginChild('ChairsGrid', { 0, -childBottomMargin }, true);
                DrawChairGrid(types.chairs, chairTextures, localSettings.chairColumns);
                imgui.EndChild();
                
                imgui.EndTabItem();
            end
            
            imgui.EndTabBar();
        end
        
        -- Add checkbox for log message display (always visible, only affects regular emotes)
        imgui.Spacing();
        
        -- Calculate checkbox width and position it on the right
        local checkboxText = types.UI_TEXT.CHECKBOX_TEXT;
        local textWidth, _ = imgui.CalcTextSize(checkboxText);
        local checkboxWidth = textWidth + helpers.CreateScaledSize(types.CHECKBOX_DEFAULTS.PADDING, localSettings.globalScale);
        local rightMargin = helpers.CreateScaledSize(types.CHECKBOX_DEFAULTS.RIGHT_MARGIN, localSettings.globalScale);
        imgui.SetCursorPosX(imgui.GetWindowWidth() - checkboxWidth - rightMargin);
        
        local displayLog = { gConfig.displayLogMessage[1] };
        if (imgui.Checkbox(checkboxText, displayLog)) then
            gConfig.displayLogMessage[1] = displayLog[1];
            SaveSettings();
        end
        
        -- Reset font scale when done with the window
        imgui.SetWindowFontScale(1.0);
        
    end
    imgui.End();
    
    -- Pop the window rounding style
    imgui.PopStyleVar();
end

-- Function to handle addon commands (shared between /emotes and /em)
local function HandleAddonCommand(args)
    if (#args == 1) then
        -- Toggle window
        localSettings.showWindow[1] = not localSettings.showWindow[1];
        print(chat.header(addon.name):append(chat.message('Emotes window ' .. (localSettings.showWindow[1] and 'shown' or 'hidden'))));
        return true;
    elseif (#args == 2) then
        if (args[2] == 'help') then
            print(chat.header(addon.name):append(chat.message('Usage:')));
            print(chat.header(addon.name):append(chat.message('/emotes or /em - Toggle the emotes window')));
            print(chat.header(addon.name):append(chat.message('/emotes showbutton - Show the toggle button')));
            print(chat.header(addon.name):append(chat.message('/emotes hidebutton - Hide the toggle button')));
            print(chat.header(addon.name):append(chat.message('/emotes scale <number> - Set global scale (e.g., /emotes scale 1.5)')));
            return true;
        elseif (args[2] == 'showbutton') then
            gConfig.showToggleButton[1] = true;
            SaveSettings();
            print(chat.header(addon.name):append(chat.message('Toggle button shown')));
            return true;
        elseif (args[2] == 'hidebutton') then
            gConfig.showToggleButton[1] = false;
            SaveSettings();
            print(chat.header(addon.name):append(chat.message('Toggle button hidden')));
            return true;
        elseif (args[2] == 'scale') then
            print(chat.header(addon.name):append(chat.message('Usage: /emotes scale <number> (e.g., /emotes scale 1.5)')));
            return true;
        end
    elseif (#args == 3) then
        if (args[2] == 'scale') then
            local scaleValue = tonumber(args[3]);
            if scaleValue and scaleValue > 0 then
                gConfig.globalScale[1] = scaleValue;
                UpdateScales();
                SaveSettings();
                print(chat.header(addon.name):append(chat.message('Global scale set to ' .. scaleValue)));
            else
                print(chat.header(addon.name):append(chat.message('Invalid scale value. Please use a number greater than 0')));
            end
            return true;
        end
    end
    
    return false; -- Command not handled
end

-- Command handler
ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    
    if (#args == 0) then
        return;
    end
    
    -- Handle /emotes and /em commands identically
    if (args[1] == '/emotes' or args[1] == '/em') then
        -- Only block the command if it's handled by our addon
        if HandleAddonCommand(args) then
            e.blocked = true;
        end
        -- If HandleAddonCommand returns false, the command passes through to the game (like /em dance)
    end
end);

-- Render callback for ImGui
ashita.events.register('d3d_present', 'd3d_present_cb', function (e)
    -- Don't draw anything if the game interface is hidden
    if helpers.GetGameInterfaceHidden() then
        return;
    end
    
    -- Always draw the toggle button
    DrawToggleButton();
    
    if (localSettings.showWindow[1]) then
        DrawEmotesWindow();
    end
end);

-- Settings register callback (like HitPoints addon)
settings.register('settings', 'settings_update', function (s)
    if (s ~= nil) then
        config = s;
        gConfig = config.userSettings;
        UpdateScales();
    end
end);

-- Load event handler
ashita.events.register('load', 'load_cb', function ()
    print(chat.header(addon.name):append(chat.message('Emotes addon loaded!')));
    print(chat.header(addon.name):append(chat.message('Use /emotes, /em, or the on screen button to toggle.')));
    print(chat.header(addon.name):append(chat.message('/emotes help - Show all commands')));
end);