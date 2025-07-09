-- helpers.lua
-- Helper functions for the Emotes addon

local helpers = {};

-- =============================================================================
-- GAME INTERFACE DETECTION
-- =============================================================================

-- Function to check if player is logged in (dynamic check)
local function IsLoggedIn()
    local playerIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    if playerIndex == 0 then
        return false;
    end
    
    local entity = AshitaCore:GetMemoryManager():GetEntity();
    local flags = entity:GetRenderFlags0(playerIndex);
    return (bit.band(flags, 0x200) == 0x200) and (bit.band(flags, 0x4000) == 0);
end

-- Memory signatures for game interface detection
local pGameMenu = ashita.memory.find('FFXiMain.dll', 0, "8B480C85C974??8B510885D274??3B05", 16, 0);
local pEventSystem = ashita.memory.find('FFXiMain.dll', 0, "A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3", 0, 0);
local pInterfaceHidden = ashita.memory.find('FFXiMain.dll', 0, "8B4424046A016A0050B9????????E8????????F6D81BC040C3", 0, 0);

-- Get the current menu name
helpers.GetMenuName = function()
    local subPointer = ashita.memory.read_uint32(pGameMenu);
    local subValue = ashita.memory.read_uint32(subPointer);
    if (subValue == 0) then
        return '';
    end
    local menuHeader = ashita.memory.read_uint32(subValue + 4);
    local menuName = ashita.memory.read_string(menuHeader + 0x46, 16);
    return string.gsub(tostring(menuName), '\x00', '');
end

-- Check if the event system is active
helpers.GetEventSystemActive = function()
    if (pEventSystem == 0) then
        return false;
    end
    local ptr = ashita.memory.read_uint32(pEventSystem + 1);
    if (ptr == 0) then
        return false;
    end

    return (ashita.memory.read_uint8(ptr) == 1);
end

-- Check if the interface is hidden
helpers.GetInterfaceHidden = function()
    if (pEventSystem == 0) then
        return false;
    end
    local ptr = ashita.memory.read_uint32(pInterfaceHidden + 10);
    if (ptr == 0) then
        return false;
    end

    return (ashita.memory.read_uint8(ptr + 0xB4) == 1);
end

-- Main function to check if the game interface is hidden
helpers.GetGameInterfaceHidden = function()
    if (helpers.GetEventSystemActive()) then
        return true;
    end
    if (string.match(helpers.GetMenuName(), 'map')) then
        return true;
    end
    if (helpers.GetInterfaceHidden()) then
        return true;
    end
    if (not IsLoggedIn()) then
        return true;
    end
    return false;
end

-- =============================================================================
-- TEXTURE LOADING
-- =============================================================================

-- Load texture function
helpers.LoadTexture = function(textureName, subfolder, addonPath)
    local ffi = require('ffi');
    local d3d = require('d3d8');
    local types = require('types');
    local C = ffi.C;
    local d3d8dev = d3d.get_device();
    
    local textures = T{}
    local texture_ptr = ffi.new('IDirect3DTexture8*[1]');
    local fullPath;
    
    if subfolder then
        fullPath = string.format('%s/%s/%s/%s.%s', addonPath, types.PATHS.RESOURCE_FOLDER, subfolder, textureName, types.PATHS.IMAGE_EXTENSION);
    else
        fullPath = string.format('%s/%s/%s.%s', addonPath, types.PATHS.RESOURCE_FOLDER, textureName, types.PATHS.IMAGE_EXTENSION);
    end
    
    -- Check if file exists
    local file = io.open(fullPath, types.PATHS.FILE_READ_MODE);
    if file then
        file:close();
    else
        return nil;
    end
    
    local res = C.D3DXCreateTextureFromFileA(d3d8dev, fullPath, texture_ptr);
    if (res ~= C.S_OK) then
        return nil;
    end;
    textures.image = ffi.new('IDirect3DTexture8*', texture_ptr[0]);
    d3d.gc_safe_release(textures.image);
    return textures;
end

-- =============================================================================
-- UI HELPER FUNCTIONS
-- =============================================================================

-- Create a tooltip
helpers.CreateTooltip = function(text)
    local imgui = require('imgui');
    imgui.BeginTooltip();
    imgui.Text(text);
    imgui.EndTooltip();
end

-- Create scaled size (can handle both numbers and tables)
helpers.CreateScaledSize = function(baseSize, scale)
    if type(baseSize) == "table" then
        return { baseSize[1] * scale, baseSize[2] * scale };
    else
        return baseSize * scale;
    end
end

-- Create scaled position
helpers.CreateScaledPosition = function(basePos, scale)
    return { basePos[1] * scale, basePos[2] * scale };
end

-- Get display name for an item
helpers.GetDisplayName = function(item, isJobEmote)
    if isJobEmote then
        return item; -- Job names are already properly formatted
    else
        return item:sub(1,1):upper() .. item:sub(2); -- Capitalize first letter for regular emotes
    end
end



-- Calculate grid dimensions
helpers.CalculateGridDimensions = function(windowWidth, columns, scale)
    local types = require('types');
    local buttonWidth = (windowWidth - (types.GRID_DEFAULTS.WINDOW_MARGIN * scale)) / columns;
    local buttonHeight = types.GRID_DEFAULTS.BUTTON_HEIGHT * scale;
    local iconSize = types.GRID_DEFAULTS.ICON_SIZE * scale;
    
    return buttonWidth, buttonHeight, iconSize;
end

-- Draw image button with fallback
helpers.DrawImageButtonWithFallback = function(texture, fallbackText, size, onClick)
    local imgui = require('imgui');
    local ffi = require('ffi');
    
    if texture and texture.image then
        imgui.Image(tonumber(ffi.cast("uint32_t", texture.image)), size);
        
        if imgui.IsItemClicked() and onClick then
            onClick();
        end
        
        return true; -- Image was shown
    else
        -- Fallback to button
        if imgui.Button(fallbackText, size) and onClick then
            onClick();
        end
        
        return false; -- Fallback was used
    end
end



return helpers; 