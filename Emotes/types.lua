-- types.lua
-- Configuration constants and emote data for the Emotes addon

local types = {};

-- =============================================================================
-- CORE CONSTANTS
-- =============================================================================

-- Default Values
types.DEFAULTS = {
    SCALE = 1.0,
}

-- Tab Indices
types.TABS = {
    MAIN = 0,
    JOB_EMOTES = 1,
    CHAIRS = 2,
}

-- =============================================================================
-- UI CONFIGURATION CONSTANTS
-- =============================================================================

types.WINDOW_DEFAULTS = {
    INITIAL_POS = { 100, 100 },
    INITIAL_SIZE = { 500, 750 },
    ROUNDING = 8.0,
}

types.TOGGLE_BUTTON = {
    INITIAL_POS = { 50, 50 },
    SIZE = 40,
}

types.TITLE_BAR = {
    HEIGHT = 30,
    ICON_SIZE = 30,
    CLOSE_BUTTON_SIZE = 20,
    LEFT_MARGIN = 8,
    TOP_MARGIN = 5,
    SPACING_AFTER = 15,
    TITLE_SCALE_MULTIPLIER = 1.5,
}

types.GRID_DEFAULTS = {
    MAIN_COLUMNS = 3,
    JOB_EMOTE_COLUMNS = 2,
    CHAIR_COLUMNS = 2,
    ICON_SIZE = 30,
    BUTTON_HEIGHT = 20,
    WINDOW_MARGIN = 20,
    SELECTABLE_MARGIN = 10,
    CHILD_BOTTOM_MARGIN = 35,
    -- Visual styling
    HOVER_BACKGROUND_COLOR = 0x440000FF,  -- Semi-transparent red (ABGR format)
    TEXT_COLOR = 0xFFFFFFFF,              -- White text
    IMAGE_TEXT_GAP = 5,                   -- Gap between image and text
}



types.CHECKBOX_DEFAULTS = {
    PADDING = 20,
    RIGHT_MARGIN = 10,
}

-- =============================================================================
-- FILE AND PATH CONSTANTS
-- =============================================================================

types.PATHS = {
    RESOURCE_FOLDER = "Resources",
    JOB_SUBFOLDER = "Jobs",
    IMAGE_EXTENSION = "png",
    FILE_READ_MODE = "r",
}

types.TEXTURES = {
    BLANK = "blank",
    FRAME = "frame",
    EMOTES_ICON = "Emotes",
    CLOSE_BUTTON = "X",
}

-- =============================================================================
-- COMMAND CONSTANTS
-- =============================================================================

types.COMMANDS = {
    PREFIX = "/",
    MOTION_SUFFIX = " motion",
    SITCHAIR = "/sitchair",
    JOBEMOTE = "/jobemote",
}



-- =============================================================================
-- UI TEXT CONSTANTS
-- =============================================================================

types.UI_TEXT = {
    WINDOW_TITLE = "Emotes",
    TOGGLE_TOOLTIP = "Emotes",
    TOGGLE_FALLBACK = "E",
    CLOSE_FALLBACK = "X",
    CHECKBOX_TEXT = "Display log message.",
    
    -- Tab Names
    TAB_GENERAL = "General",
    TAB_JOB_EMOTES = "Job Emotes", 
    TAB_CHAIRS = "Chairs",
}

-- =============================================================================
-- EMOTE DATA
-- =============================================================================

-- List of all available emotes (jobemote and sitchair removed)
types.emotes = T{
    'aim',
    'amazed',
    'angry',
    'bell',
    'blush',
    'bow',
    'cheer',
    'clap',
    'comfort',
    'cry',
    'dance',
    'dance1',
    'dance2',
    'dance3',
    'dance4',
    'disgusted',
    'doubt',
    'doze',
    'farewell',
    'fume',
    'goodbye',
    'grin',
    'huh',
    'hurray',
    'joy',
    'jump',
    'kneel',
    'laugh',
    'muted',
    'no',
    'nod',
    'panic',
    'point',
    'poke',
    'praise',
    'psych',
    'salute',
    'shocked',
    'sigh',
    'sit',
    'slap',
    'smile',
    'stagger',
    'stare',
    'sulk',
    'surprised',
    'think',
    'toss',
    'upset',
    'wave',
    'welcome',
    'yes'
};

-- List of all job emotes
types.jobEmotes = T{
    'Warrior',
    'Monk',
    'White Mage',
    'Black Mage',
    'Red Mage',
    'Thief',
    'Paladin',
    'Bard',
    'Ranger',
    'Samurai',
    'Ninja',
    'Dragoon',
    'Summoner',
    'Blue Mage',
    'Corsair',
    'Puppetmaster',
    'Dancer',
    'Scholar',
    'Geomancer',
    'Rune Fencer'
};

-- Job name to abbreviation lookup table
types.jobAbbreviations = T{
    ['Warrior'] = 'war',
    ['Monk'] = 'mnk',
    ['White Mage'] = 'whm',
    ['Black Mage'] = 'blm',
    ['Red Mage'] = 'rdm',
    ['Thief'] = 'thf',
    ['Paladin'] = 'pld',
    ['Bard'] = 'brd',
    ['Ranger'] = 'rng',
    ['Samurai'] = 'sam',
    ['Ninja'] = 'nin',
    ['Dragoon'] = 'drg',
    ['Summoner'] = 'smn',
    ['Blue Mage'] = 'blu',
    ['Corsair'] = 'cor',
    ['Puppetmaster'] = 'pup',
    ['Dancer'] = 'dnc',
    ['Scholar'] = 'sch',
    ['Geomancer'] = 'geo',
    ['Rune Fencer'] = 'run'
};

-- Chair data with names and numbers
types.chairs = T{
    { name = 'Wooden Stool', number = 0 },
    { name = 'Imperial Chair', number = 1 },
    { name = 'Decorative Chair', number = 2 },
    { name = 'Ornate Stool', number = 3 },
    { name = 'Refined Chair', number = 4 },
    { name = 'Portable Container', number = 5 },
    { name = 'Chocobo Chair', number = 6 },
    { name = 'Empramadian Throne', number = 7 },
    { name = 'Shadow Throne', number = 8 },
    { name = 'Leaf Bench', number = 9 },
    { name = 'Astral Cube', number = 10 },
    { name = 'Chocobo Chair', number = 11 },
    { name = 'Adenium Bench', number = 12 }
};

return types; 