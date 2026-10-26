--[[
    MOCHI
    ---------------------------------------------------------------
    A little menu that floats on your screen in Roblox.
    It has buttons and sliders that change how YOU see and move
    around in the game. Think of it like a remote control.

    How to read this file (super simple version):
      * Lines that start with two dashes (--) are notes for people.
        The computer ignores them completely.
      * "local" means "make a box and give it a name".
      * A "function" is a little recipe. You write it once,
        then use it again and again by saying its name.
      * "Instance.new" means "make a brand new thing".
      * "Parent" means "put this thing inside that other thing",
        like putting a toy inside a toy box.
]]

-- ================================================================
-- PART 0: THE "OOPS" SCREEN
-- If MOCHI breaks while starting, this draws a small red box that
-- tells you what went wrong, instead of failing silently.
-- ================================================================
local function showFatal(message)
    -- pcall = "try this, and if it breaks, don't crash everything"
    pcall(function()
        local plr = game:GetService("Players").LocalPlayer
        local pg = plr:WaitForChild("PlayerGui", 5) -- PlayerGui = the place all your screen stuff lives
        if not pg then return end

        -- If an old error box is still there, throw it away first.
        local existing = pg:FindFirstChild("MOCHI_Error")
        if existing then existing:Destroy() end

        -- ScreenGui = a clear sheet of glass over your screen. Everything is drawn on it.
        local g = Instance.new("ScreenGui")
        g.Name = "MOCHI_Error"
        g.ResetOnSpawn = false      -- don't vanish when your character respawns
        g.IgnoreGuiInset = true
        g.DisplayOrder = 1000000    -- huge number = draw on top of everything
        g.Parent = pg

        -- The dark red box.
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, 330, 0, 200)
        f.Position = UDim2.new(0.5, -165, 0.5, -100) -- middle of the screen
        f.BackgroundColor3 = Color3.fromRGB(40, 22, 22)
        f.BorderSizePixel = 0
        f.Parent = g
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12) -- rounded corners

        -- The title text.
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.Text = "MOCHI failed to start"
        t.Font = Enum.Font.GothamBold
        t.TextSize = 14
        t.TextColor3 = Color3.fromRGB(255, 170, 160)
        t.Size = UDim2.new(1, -16, 0, 28)
        t.Position = UDim2.new(0, 8, 0, 4)
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.Parent = f

        -- A scrolling area so long error messages still fit.
        local s = Instance.new("ScrollingFrame")
        s.BackgroundTransparency = 1
        s.BorderSizePixel = 0
        s.Position = UDim2.new(0, 8, 0, 34)
        s.Size = UDim2.new(1, -16, 1, -76)
        s.AutomaticCanvasSize = Enum.AutomaticSize.Y
        s.CanvasSize = UDim2.new()
        s.ScrollBarThickness = 3
        s.Parent = f

        -- The actual error words.
        local m = Instance.new("TextLabel")
        m.BackgroundTransparency = 1
        m.Text = tostring(message)
        m.Font = Enum.Font.Code
        m.TextSize = 11
        m.TextColor3 = Color3.fromRGB(244, 244, 222)
        m.TextWrapped = true
        m.TextXAlignment = Enum.TextXAlignment.Left
        m.TextYAlignment = Enum.TextYAlignment.Top
        m.Size = UDim2.new(1, -6, 0, 0)
        m.AutomaticSize = Enum.AutomaticSize.Y
        m.Parent = s

        -- A Close button.
        local c = Instance.new("TextButton")
        c.Text = "Close"
        c.Font = Enum.Font.GothamSemibold
        c.TextSize = 12
        c.TextColor3 = Color3.fromRGB(244, 244, 222)
        c.BackgroundColor3 = Color3.fromRGB(90, 45, 45)
        c.Size = UDim2.new(1, -16, 0, 28)
        c.Position = UDim2.new(0, 8, 1, -34)
        c.Parent = f
        Instance.new("UICorner", c).CornerRadius = UDim.new(0, 8)
        c.Activated:Connect(function() g:Destroy() end) -- tap = remove the box
    end)
end

-- xpcall runs everything below. If ANYTHING inside breaks, the
-- little function at the very bottom of the file catches the error
-- and shows it with the red box above.
local ok, err = xpcall(function()

-- ================================================================
-- PART 1: GETTING TOOLS
-- "Services" are built-in helpers that Roblox gives us.
-- ================================================================
local Players = game:GetService("Players")                       -- everyone in the game
local RunService = game:GetService("RunService")                 -- runs code every frame
local UserInputService = game:GetService("UserInputService")     -- keyboard, mouse, touch
local MarketplaceService = game:GetService("MarketplaceService") -- can look up game names
local TweenService = game:GetService("TweenService")             -- makes smooth animations
local Lighting = game:GetService("Lighting")                     -- sun, brightness, fog

local LP = Players.LocalPlayer                -- LP = "Local Player" = YOU
local PG = LP:WaitForChild("PlayerGui")       -- the place where our menu will live

-- ================================================================
-- PART 2: SETTINGS AND LISTS
-- Numbers and words that the rest of the code uses.
-- ================================================================
local DEFAULT_SPEED, DEFAULT_JUMP = 16, 50   -- how fast / high a normal Roblox character goes
local SPEED_MIN, SPEED_MAX = 0, 999999          -- the slowest and fastest we allow
local JUMP_MIN, JUMP_MAX = 0, 999999
local FLY_MIN, FLY_MAX = 0, 999999
-- Where Infinite Yield (a famous admin-commands script) is downloaded from.
local IY_SOURCE = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"

-- Fun facts. The Mochi Buddy reads these out loud in his speech bubble.
local FACTS = {
    "Honey never spoils. Edible honey has been found in ancient Egyptian tombs.",
    "Octopuses have three hearts and blue blood.",
    "Bananas are botanically berries, but strawberries are not.",
    "A day on Venus is longer than a year on Venus.",
    "Wombat droppings are shaped like cubes.",
    "Sharks existed before trees did.",
    "The Eiffel Tower can grow about 15 cm taller in summer heat.",
    "Sea otters hold hands while sleeping so they don't drift apart.",
    "Scotland's national animal is the unicorn.",
    "Lightning is several times hotter than the surface of the Sun.",
    "A group of flamingos is called a flamboyance.",
    "Mochi is a Japanese rice cake made from pounded glutinous rice.",
    "Roblox was released to the public in 2006.",
    "Your brain is roughly 75% water.",
    "Cows form close friendships and get stressed when separated.",
    "Space is silent because sound needs air to travel through.",
    "Butterflies taste with their feet.",
    "The shortest war in history, in 1896, lasted about 40 minutes.",
    "A crocodile cannot stick its tongue out.",
    "Oxford University is older than the Aztec Empire.",
    "Dolphins sleep with only half of their brain at a time.",
    "Koala fingerprints are almost identical to human ones.",
    "There are likely more stars in the universe than grains of sand on Earth's beaches.",
    "A single cloud can weigh over a million pounds.",
    "Hummingbirds are among the few birds that can fly backwards.",
    "A blue whale's heart can be as big as a small car.",
    "Polar bears have black skin under their white-looking fur.",
    "A pineapple plant takes about two years to produce one fruit.",
    "Sloths can hold their breath for up to 40 minutes.",
    "Your stomach lining replaces itself every few days.",
    "Mount Everest grows a few millimeters taller every year.",
    "Crows can recognize individual human faces.",
    "The Great Wall of China is not visible to the naked eye from space.",
    "Rats laugh when they are tickled.",
    "A group of crows is called a murder.",
    "A worker honeybee makes only about 1/12 of a teaspoon of honey in her life.",
    "The first computer 'bug' was a real moth, found in a computer in 1947.",
    "Venus spins backwards compared to most planets.",
    "Saturn is less dense than water, so it would float in a big enough bathtub.",
    "Sound travels about four times faster through water than through air.",
    "A shrimp's heart is located in its head.",
    "Every human has a unique tongue print.",
    "Tomatoes are botanically fruits.",
    "The Moon drifts about 3.8 cm farther from Earth every year.",
    "Giraffes have the same number of neck bones as humans: seven.",
    "Tardigrades can survive in the vacuum of space.",
    "Some penguins propose to their partners with a pebble.",
    "The first YouTube video was uploaded in 2005.",
    "A teaspoon of neutron star would weigh billions of tons.",
    "Some bamboo species can grow almost a meter in a single day.",
}

-- Lists of scripts people can run with one tap.
-- Each one has a name (for the button) and a url (where to download it).
local GAMES = {
    {name = "The Strongest Battlegrounds", url = "https://scriptblox.com/raw/The-Strongest-Battlegrounds-Best-keyless-tsb-script-231002"},
    {name = "Build a Boat", url = "https://scriptblox.com/raw/Build-A-Boat-For-Treasure-auto-farm-copy-build-and-troll-57251"},
    {name = "MM2", url = "https://scriptblox.com/raw/Universal-Script-YARHM-12403"},
    {name = "RoChess", url = "https://scriptblox.com/raw/RoChess-Stockfish-or-Autoplay-or-Hints-NO-KEY-232915"},
    {name = "Natural Disasters Survival", url = "https://scriptblox.com/raw/Natural-Disaster-Survival-HzReyzn-Hub-or-Last-Update-229523"},
    {name = "JJS", url = "https://scriptblox.com/raw/SKY-ASSASSIN-Jujutsu-Shenanigans-Nexus-keyless-script-232015"},
    {name = "Slap Battles", url = "https://scriptblox.com/raw/UPDATE-Slap-Battles-RAGEBOTAUTOFARM-or-KEYLESS-232207"},
    {name = "Rivals", url = "https://scriptblox.com/raw/Universal-Script-Atherhub-41929"},
    {name = "Steal Time for Swords", url = "https://scriptblox.com/raw/Steal-TIME-for-SWORDS-Reach-Orbit-Auto-Swing-Skins-Fly-Speed-242959"},
    {name = "99 Nights in the Forest", url = "https://scriptblox.com/raw/Universal-Script-99N-void-ware-74341"},
}

local TOOLS = {
    {name = "Backdoor", url = "https://scriptblox.com/raw/Universal-Script-Epic-Backdoor-SS-Executor-227858"},
    {name = "AI", url = "https://scriptblox.com/raw/Universal-Script-Project-UAI-2.0-230405"},
}

local HUBS = {
    {name = "Moondiety", url = "https://scriptblox.com/raw/Universal-Script-Moondiety-Scripts-Hub-45712"},
    {name = "XVC Hub", url = "https://scriptblox.com/raw/Universal-Script-XVC-Hub-CRACKED-210495"},
    {name = "Zerohub", url = "https://scriptblox.com/raw/Universal-Script-zerohub-universal:-AI-and-more-231529"},
}

-- A list of every feature. The Search tab looks through this list.
--   name = what it is called
--   tab  = which tab it lives in
--   keys = extra words that should also find it (like "fast" finds Walk speed)
local FEATURES = {
    {name = "Walk speed", tab = "Player", keys = "speed run fast"},
    {name = "Jump power", tab = "Player", keys = "jump high"},
    {name = "Flight", tab = "Player", keys = "fly rise descend"},
    {name = "Camera & view", tab = "Player", keys = "spectate watch camera player"},
    {name = "Field of view slider", tab = "Player", keys = "fov zoom"},
    {name = "Free camera", tab = "Player", keys = "freecam camera"},
    {name = "Camera reset", tab = "Player", keys = "reset camera"},
    {name = "Fullbright", tab = "Visuals", keys = "light dark bright"},
    {name = "Custom brightness", tab = "Visuals", keys = "brightness light"},
    {name = "Disable camera effects", tab = "Visuals", keys = "blur bloom effects"},
    {name = "Fling", tab = "Players", keys = "launch"},
    {name = "Player info, track, go to", tab = "Players", keys = "teleport track info"},
    {name = "Mochi Buddy", tab = "Extras", keys = "companion pet buddy"},
    {name = "Buddy dance", tab = "Extras", keys = "dance emote"},
    {name = "Chat mode and commands", tab = "Extras", keys = "chat keywords talk commands"},
    {name = "Executor", tab = "Executor", keys = "lua run script"},
    {name = "Infinite Yield", tab = "Home", keys = "iy admin commands"},
    {name = "Clock", tab = "Home", keys = "time date"},
    {name = "Activity log", tab = "Activity", keys = "history log"},
    {name = "Notifications", tab = "Activity", keys = "toast alerts errors"},
}

-- If an old MOCHI is already on screen, remove it so we never get two.
local old = PG:FindFirstChild("MOCHI")
if old then old:Destroy() end

-- ================================================================
-- PART 3: COLORS
-- All the colors live here so we can change the whole look in one place.
-- Color3.fromRGB(red, green, blue) - each number goes from 0 to 255.
-- ================================================================
local theme = {
    bg = Color3.fromRGB(20, 26, 22),        -- darkest background
    panel = Color3.fromRGB(31, 41, 34),     -- cards
    panel2 = Color3.fromRGB(45, 58, 48),    -- buttons
    accent = Color3.fromRGB(153, 190, 133), -- main green
    leaf = Color3.fromRGB(88, 138, 78),     -- darker green
    text = Color3.fromRGB(244, 244, 222),   -- cream-colored words
    muted = Color3.fromRGB(165, 180, 158),  -- soft grey-green words
    good = Color3.fromRGB(165, 215, 153),   -- "it worked" green
    danger = Color3.fromRGB(218, 125, 117), -- "careful" red
    glow = Color3.fromRGB(210, 238, 190),   -- shiny highlight
}

local rng = Random.new() -- a dice we can roll for random numbers
local api = {}           -- a box where we store actions that other parts can call (like api.setFly)

-- "conns" is a list of listeners (things waiting for something to happen).
-- We save them so we can switch them all off when MOCHI closes.
local conns = {}
local function track(c)
    conns[#conns + 1] = c
    return c
end

-- ================================================================
-- PART 4: SMALL HELPER RECIPES
-- Little functions that build buttons, labels and so on, so we
-- don't have to write the same long code over and over.
-- ================================================================

-- make: creates a new thing (like a Frame or a TextLabel),
-- sets its properties, and puts it inside its parent.
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

-- tween: slowly changes something from how it is now to how we want it.
-- Example: fading a button's color instead of snapping it instantly.
local performanceMode = false
local orbStrokeRef
local decorativeTweens = {}
local function registerDecorativeTween(t)
    if t then
        decorativeTweens[#decorativeTweens + 1] = t
        if performanceMode then pcall(function() t:Pause() end) end
    end
    return t
end
local function tween(obj, props, time, style, dir)
    if performanceMode then
        for property, value in pairs(props) do
            pcall(function() obj[property] = value end)
        end
        return nil
    end
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

-- round: gives something rounded corners.
local function round(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, obj)
end

-- outline: draws a thin colored line around something.
local function outline(obj, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or theme.panel2,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end

-- isPress: true if the input was a mouse click or a finger tap.
local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

-- label: makes a piece of text.
local function label(parent, text, size, color, bold)
    return make("TextLabel", {
        BackgroundTransparency = 1, -- see-through background
        Text = text,
        TextColor3 = color or theme.text,
        TextSize = size or 12,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,                       -- long words go to the next line
        AutomaticSize = Enum.AutomaticSize.Y,     -- grows taller if it needs room
        Size = UDim2.new(1, 0, 0, 18),
    }, parent)
end

-- button: makes a button that gets a bit smaller when pressed
-- and glows when your mouse is over it. "callback" is the recipe
-- that runs when the button is tapped.
local function button(parent, text, callback, color, height)
    local bg = color or theme.panel2
    local b = make("TextButton", {
        Text = text,
        -- dark words on the bright green button, light words on the others
        TextColor3 = bg == theme.accent and theme.bg or theme.text,
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
        BackgroundColor3 = bg,
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, math.min(height or 28, 24)),
    }, parent)
    round(b, 8)

    -- UIScale lets us shrink/grow the button for the "press" effect.
    local scale = make("UIScale", {Scale = 1}, b)
    -- A see-through white layer that fades in when you hover.
    local glow = make("Frame", {
        Name = "Hover",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        Size = UDim2.new(1, 0, 1, 0),
    }, b)
    round(glow, 8)

    b.MouseEnter:Connect(function()
        tween(glow, {BackgroundTransparency = 0.88}, 0.15)
    end)
    b.MouseLeave:Connect(function()
        tween(glow, {BackgroundTransparency = 1}, 0.2)
        tween(scale, {Scale = 1}, 0.15)
    end)
    b.InputBegan:Connect(function(input)
        if isPress(input) then
            tween(scale, {Scale = 0.96}, 0.08) -- squish!
        end
    end)
    b.InputEnded:Connect(function(input)
        if isPress(input) then
            tween(scale, {Scale = 1}, 0.22, Enum.EasingStyle.Back) -- boing back
            if input.UserInputType == Enum.UserInputType.Touch then
                tween(glow, {BackgroundTransparency = 1}, 0.25)
            end
        end
    end)

    b.Activated:Connect(function()
        callback(b)
    end)
    return b
end

-- inputBox: makes a box you can type into.
local function inputBox(parent, placeholder, text)
    local box = make("TextBox", {
        PlaceholderText = placeholder, -- the faint hint words
        Text = text or "",
        TextColor3 = theme.text,
        PlaceholderColor3 = theme.muted,
        BackgroundColor3 = theme.panel2,
        ClearTextOnFocus = false,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(1, 0, 0, 28),
    }, parent)
    round(box, 8)
    -- A green outline that fades in while you are typing.
    local stroke = outline(box, theme.accent, 1, 1)
    box.Focused:Connect(function()
        tween(stroke, {Transparency = 0.2}, 0.2)
    end)
    box.FocusLost:Connect(function()
        tween(stroke, {Transparency = 1}, 0.25)
    end)
    return box
end

-- scroll: makes a page that you can scroll up and down,
-- and stacks everything inside it in a neat column.
local function scroll(parent)
    local s = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.accent,
    }, parent)
    make("UIPadding", { -- empty space around the edges
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 26),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 6),
    }, s)
    make("UIListLayout", { -- stacks children one under the other
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, s)
    return s
end

-- section: makes a card with a title. We put buttons inside it.
local function section(parent, title)
    local box = make("Frame", {
        BackgroundColor3 = theme.panel,
        Size = UDim2.new(1, 0, 0, 36),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, parent)
    round(box, 10)
    outline(box, theme.panel2, 1, 0.2)
    make("UIGradient", { -- a soft color fade so it isn't flat
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(212, 224, 215)),
        Rotation = 90,
    }, box)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
    }, box)
    make("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, box)
    label(box, title, 12, theme.accent, true)
    return box
end

-- slider: a bar with a round knob you drag left and right to pick a number.
--   min / max = smallest and biggest number
--   start     = number it begins on
--   decimals  = how many numbers after the dot (0 = whole numbers only)
--   onChange  = recipe to run whenever the number changes
local function slider(parent, name, min, max, start, decimals, onChange)
    local mult = 10 ^ (decimals or 0)
    local value = start

    local wrap = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 44),
    }, parent)
    -- The words above the bar, like "Field of view: 70".
    local title = make("TextLabel", {
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = theme.text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 16),
    }, wrap)
    -- The empty bar.
    local bar = make("Frame", {
        BackgroundColor3 = theme.panel2,
        Position = UDim2.new(0, 0, 0, 26),
        Size = UDim2.new(1, 0, 0, 8),
    }, wrap)
    round(bar, 4)
    -- The green part that fills up as you slide.
    local fill = make("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.new(0, 0, 1, 0),
    }, bar)
    round(fill, 4)
    make("UIGradient", {
        Color = ColorSequence.new(theme.leaf, theme.accent),
    }, fill)
    -- The round knob.
    local knob = make("Frame", {
        BackgroundColor3 = theme.text,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        ZIndex = 2,
    }, bar)
    round(knob, 8)
    outline(knob, theme.accent, 2, 0.3)
    -- An invisible, bigger button on top so it is easy to grab.
    local hit = make("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Position = UDim2.new(0, 0, 0, 16),
        Size = UDim2.new(1, 0, 0, 28),
    }, wrap)

    -- render: moves the knob and fill to match the current number.
    local function render(instant)
        local rel = math.clamp((value - min) / (max - min), 0, 1) -- 0 = far left, 1 = far right
        local t = instant and 0 or 0.09
        tween(fill, {Size = UDim2.new(rel, 0, 1, 0)}, t)
        tween(knob, {Position = UDim2.new(rel, 0, 0.5, 0)}, t)
        title.Text = name .. ": " .. tostring(value)
    end

    -- setValue: changes the number (and keeps it between min and max).
    local function setValue(v, silent)
        v = math.clamp(v, min, max)
        v = math.floor(v * mult + 0.5) / mult -- round to the right number of decimals
        value = v
        render()
        if not silent and onChange then onChange(v) end
    end

    local dragging, lockedScroll = false, nil
    -- fromX: turns "where your finger is" into a number.
    local function fromX(x)
        local w = bar.AbsoluteSize.X
        if w <= 0 then return end
        local rel = math.clamp((x - bar.AbsolutePosition.X) / w, 0, 1)
        setValue(min + (max - min) * rel)
    end

    hit.InputBegan:Connect(function(input)
        if isPress(input) then
            dragging = true
            tween(knob, {Size = UDim2.fromOffset(21, 21)}, 0.15, Enum.EasingStyle.Back) -- knob gets bigger
            -- Freeze the page scrolling so the page doesn't slide while you drag.
            lockedScroll = wrap:FindFirstAncestorOfClass("ScrollingFrame")
            if lockedScroll then lockedScroll.ScrollingEnabled = false end
            fromX(input.Position.X)
        end
    end)
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            fromX(input.Position.X)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if dragging and isPress(input) then
            dragging = false
            tween(knob, {Size = UDim2.fromOffset(16, 16)}, 0.2, Enum.EasingStyle.Back)
            if lockedScroll then
                lockedScroll.ScrollingEnabled = true -- let the page scroll again
                lockedScroll = nil
            end
        end
    end))

    render(true)
    return {set = setValue, frame = wrap}
end

-- makeLogo: draws the little mochi face (a round body, a leaf, two eyes, two blushy cheeks).
local function makeLogo(parent, size, position, anchor, bodyColor)
    local holder = make("Frame", {
        Name = "Logo",
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(size, size),
        Position = position or UDim2.new(),
        AnchorPoint = anchor or Vector2.new(0, 0),
    }, parent)

    -- The round body.
    local body = make("Frame", {
        BackgroundColor3 = bodyColor or theme.text,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.58, 0),
        Size = UDim2.new(0.86, 0, 0.7, 0),
    }, holder)
    round(body, size)

    -- The leaf on top.
    local leaf = make("Frame", {
        BackgroundColor3 = theme.leaf,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.62, 0, 0.22, 0),
        Size = UDim2.new(0.34, 0, 0.18, 0),
        Rotation = -30,
    }, holder)
    round(leaf, size)

    -- Two eyes (left and right).
    for _, x in ipairs({0.34, 0.66}) do
        local eye = make("Frame", {
            BackgroundColor3 = theme.bg,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(x, 0, 0.5, 0),
            Size = UDim2.new(0.09, 0, 0.09, 0),
        }, body)
        round(eye, size)
    end

    -- Two pink cheeks.
    for _, x in ipairs({0.2, 0.8}) do
        local blush = make("Frame", {
            BackgroundColor3 = theme.danger,
            BackgroundTransparency = 0.5,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(x, 0, 0.66, 0),
            Size = UDim2.new(0.14, 0, 0.09, 0),
        }, body)
        round(blush, size)
    end

    return holder
end

-- ================================================================
-- PART 5: THE SCREEN AND POP-UP MESSAGES
-- ================================================================

-- "gui" is MOCHI's own sheet of glass. Everything we draw goes on it.
local gui = make("ScreenGui", {
    Name = "MOCHI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PG)

-- Minimal boot splash: one solid background, centered logo, and progress bar.
local bootUI = {startedAt = os.clock(), minimumDuration = 2.8}
bootUI.splash = make("Frame", {
    Name = "MOCHIBootSplash", BackgroundColor3 = Color3.fromRGB(39,57,34),
    BackgroundTransparency = 0, Size = UDim2.fromScale(1,1), ZIndex = 200,
}, gui)
bootUI.card = make("Frame", {
    Name = "BootCard", AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
    Size = UDim2.new(0,250,0,112), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 201,
}, bootUI.splash)
bootUI.logo = makeLogo(bootUI.card, 58, UDim2.new(0.5,0,0,0), Vector2.new(0.5,0), theme.text)
bootUI.logo.Name = "BootMochiLogo"
for _, logoPart in ipairs(bootUI.logo:GetDescendants()) do
    if logoPart:IsA("GuiObject") then logoPart.ZIndex = 202 end
end
bootUI.track = make("Frame", {
    Name = "BootProgressTrack", Position = UDim2.new(0,24,0,91), Size = UDim2.new(1,-48,0,6),
    BackgroundColor3 = Color3.fromRGB(25,39,23), BorderSizePixel = 0, ZIndex = 202,
}, bootUI.card)
make("UICorner", {CornerRadius = UDim.new(1,0)}, bootUI.track)
bootUI.fill = make("Frame", {
    Name = "BootProgressFill", Size = UDim2.new(0.03,0,1,0),
    BackgroundColor3 = Color3.fromRGB(225,244,190), BorderSizePixel = 0, ZIndex = 203,
}, bootUI.track)
make("UICorner", {CornerRadius = UDim.new(1,0)}, bootUI.fill)
task.spawn(function()
    for _, progress in ipairs({0.18,0.38,0.61,0.82,1}) do
        if not bootUI.splash.Parent then return end
        TweenService:Create(bootUI.fill, TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(progress,0,1,0)
        }):Play()
        task.wait(0.5)
    end
end)
-- notify: shows a small pop-up message at the top of the screen.
-- kind can be "error" (red), "good" (green), or nothing (normal).
local notifEnabled = true
local notify
do
    -- The invisible holder that stacks the pop-ups.
    local toastHolder = make("Frame", {
        Name = "Toasts",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 8),
        Size = UDim2.new(0, 280, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 60,
    }, gui)
    make("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, toastHolder)

    local toastId = 0 -- counts pop-ups so they stay in order
    notify = function(text, kind)
        if not notifEnabled or not toastHolder.Parent then return end
        text = tostring(text)
        if #text > 140 then text = text:sub(1, 137) .. "..." end -- cut super long messages
        local color = kind == "error" and theme.danger or (kind == "good" and theme.good or theme.accent)

        toastId += 1
        local t = make("TextButton", {
            Name = "Toast",
            LayoutOrder = toastId,
            Text = text,
            TextColor3 = theme.text,
            TextTransparency = 1, -- starts invisible, then fades in
            TextSize = 11,
            Font = Enum.Font.GothamSemibold,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundColor3 = theme.panel,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 60,
        }, toastHolder)
        round(t, 9)
        local stroke = outline(t, color, 1.5, 1)
        make("UIPadding", {
            PaddingTop = UDim.new(0, 7),
            PaddingBottom = UDim.new(0, 7),
            PaddingLeft = UDim.new(0, 11),
            PaddingRight = UDim.new(0, 11),
        }, t)
        local pop = make("UIScale", {Scale = 0.9}, t)

        -- Fade in and "pop" bigger.
        tween(t, {BackgroundTransparency = 0, TextTransparency = 0}, 0.25)
        tween(stroke, {Transparency = 0.1}, 0.25)
        tween(pop, {Scale = 1}, 0.35, Enum.EasingStyle.Back)

        -- Only keep 4 pop-ups at once. Remove the oldest if there are more.
        local toasts = {}
        for _, c in ipairs(toastHolder:GetChildren()) do
            if c.Name == "Toast" then toasts[#toasts + 1] = c end
        end
        if #toasts > 4 then toasts[1]:Destroy() end

        -- dismiss: fades the pop-up away and deletes it.
        local function dismiss()
            if not t.Parent then return end
            tween(t, {BackgroundTransparency = 1, TextTransparency = 1}, 0.3)
            tween(stroke, {Transparency = 1}, 0.3)
            tween(pop, {Scale = 0.92}, 0.3)
            task.wait(0.3)
            if t.Parent then t:Destroy() end
        end

        t.Activated:Connect(function() task.spawn(dismiss) end) -- tap it to close it early
        -- Disappears on its own: errors stay 5 seconds, others 3 seconds.
        task.delay(kind == "error" and 5 or 3, function()
            task.spawn(dismiss)
        end)
    end
end

-- ================================================================
-- PART 6: REMEMBERING THINGS ABOUT YOUR CHARACTER
-- These are "boxes" that hold the current state of everything.
-- ================================================================
local character, humanoid, root                -- your character, its brain (humanoid), and its middle part (root)
local currentSpeed, currentJump = DEFAULT_SPEED, DEFAULT_JUMP
local flySpeed = 60
local flyEnabled, flyUp, flyDown = false, false, false
local flyAttachment, flyVelocity, flyOrientation, flyConnection
local savedAutoRotate
local poseMotors = {}                          -- the arm/leg joints we pose while flying
local trackedPlayer, trackBillboard, trackConnection
local spectatingPlayer, selectedPlayer
local activityScroll, infoText, msgLabel, playerList
local speedInput, jumpInput
local speedValueLabel, jumpValueLabel, flySpeedInput, flySpeedLabel
local flyToggle
local pages, navButtons = {}, {}               -- every tab page, and every tab button on the left
local main, orb, orbScale                      -- the main window, and the little floating ball
local addLog                                   -- recipe that writes a line in the Activity tab
local ready = false                            -- true once the loading screen is done
local orbMoved = false
local menuOpen = false
local execSaved = nil
local restoreExec, enterTypingMode
local toggleMenu
local viewStatus
local deleteBuddy, stopFling, clearTracking, refreshPlayers

-- getParts: finds your character, its humanoid and its root part.
-- It waits if your character hasn't loaded yet.
local function getParts()
    character = LP.Character or LP.CharacterAdded:Wait()
    humanoid = character:FindFirstChildOfClass("Humanoid")
    root = character:FindFirstChild("HumanoidRootPart")
    return humanoid, root
end

getParts()

-- applyMovement: gives your character the speed and jump we picked.
local function applyMovement()
    local h = select(1, getParts())
    if not h then return end
    h.WalkSpeed = currentSpeed
    h.UseJumpPower = true
    h.JumpPower = currentJump
end

-- ================================================================
-- PART 7: FLYING
-- ================================================================

-- clearPose: puts arms and legs back to normal.
local function clearPose()
    for motor, _ in pairs(poseMotors) do
        if motor and motor.Parent then
            motor.Transform = CFrame.new()
        end
    end
    table.clear(poseMotors)
end

-- setFlightPose: holds your arms and legs straight while flying.
local function setFlightPose(ch)
    local function pose(name, cf)
        local motor = ch:FindFirstChild(name, true)
        if motor and motor:IsA("Motor6D") then -- Motor6D = a body joint
            poseMotors[motor] = true
            motor.Transform = cf
        end
    end
    -- R15 characters and R6 characters name their joints differently, so we try both.
    pose("LeftShoulder", CFrame.Angles(0, 0, 0))
    pose("RightShoulder", CFrame.Angles(0, 0, 0))
    pose("Left Shoulder", CFrame.Angles(0, 0, 0))
    pose("Right Shoulder", CFrame.Angles(0, 0, 0))
    pose("LeftHip", CFrame.Angles(0, 0, 0))
    pose("RightHip", CFrame.Angles(0, 0, 0))
    pose("Left Hip", CFrame.Angles(0, 0, 0))
    pose("Right Hip", CFrame.Angles(0, 0, 0))
end

-- stopFly: turns flying off and cleans up everything we added.
local function stopFly()
    flyEnabled = false
    flyUp, flyDown = false, false

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
    if flyOrientation then flyOrientation:Destroy(); flyOrientation = nil end
    if flyAttachment then flyAttachment:Destroy(); flyAttachment = nil end

    clearPose()

    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = savedAutoRotate ~= nil and savedAutoRotate or true
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    savedAutoRotate = nil
end

-- startFly: turns flying on.
-- Idea: we add an invisible "pusher" (LinearVelocity) to your body that
-- pushes you the way the camera points, and an "aimer" (AlignOrientation)
-- that turns your body to face where you look.
local function startFly()
    local h, r = getParts()
    if not h or not r then return end

    stopFly() -- start from a clean slate
    flyEnabled = true
    savedAutoRotate = h.AutoRotate

    flyAttachment = make("Attachment", {Name = "MOCHI_FlyAttachment"}, r)

    flyVelocity = make("LinearVelocity", {
        Name = "MOCHI_FlyVelocity",
        Attachment0 = flyAttachment,
        RelativeTo = Enum.ActuatorRelativeTo.World,
        VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
        VectorVelocity = Vector3.zero,
        MaxForce = 100000,
    }, r)

    flyOrientation = make("AlignOrientation", {
        Name = "MOCHI_FlyOrientation",
        Attachment0 = flyAttachment,
        Mode = Enum.OrientationAlignmentMode.OneAttachment,
        Responsiveness = 20,
        MaxTorque = 100000,
    }, r)

    h.AutoRotate = false
    h.PlatformStand = false

    -- This runs once every single frame while flying.
    flyConnection = RunService.RenderStepped:Connect(function()
        -- If your character is gone, stop flying.
        if not flyEnabled or not r.Parent or not h.Parent then
            stopFly()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end

        -- Work out which way the camera looks (forward) and points sideways (right).
        local look = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        local flatRight = Vector3.new(right.X, 0, right.Z)
        local move = h.MoveDirection -- where the joystick/WASD is pushing

        if flatLook.Magnitude > 0.001 then flatLook = flatLook.Unit end
        if flatRight.Magnitude > 0.001 then flatRight = flatRight.Unit end

        local forward = move:Dot(flatLook)   -- how much you push forward
        local sideways = move:Dot(flatRight) -- how much you push sideways
        local direction = look * forward + right * sideways
        local vertical = (flyUp and 1 or 0) - (flyDown and 1 or 0) -- +1 up, -1 down, 0 stay

        flyVelocity.VectorVelocity = direction * flySpeed + Vector3.new(0, vertical * flySpeed, 0)
        flyOrientation.CFrame = CFrame.lookAt(Vector3.zero, look, camera.CFrame.UpVector)

        clearPose()
        setFlightPose(character)
    end)
end

-- setFlyUI: updates the FLY button's words and color.
local function setFlyUI(on)
    if flyToggle then
        flyToggle.Text = on and "FLY: ON" or "FLY: OFF"
        tween(flyToggle, {
            BackgroundColor3 = on and theme.good or theme.panel2,
            TextColor3 = on and theme.bg or theme.text,
        }, 0.25)
    end
end

-- When you respawn, you get a brand new character. Turn flying off
-- and give the new character your speed and jump again.
track(LP.CharacterAdded:Connect(function(ch)
    stopFly()
    character = ch
    humanoid = ch:WaitForChild("Humanoid", 5)
    root = ch:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.2)
    applyMovement()
    setFlyUI(false)
end))

-- ================================================================
-- PART 8: INVISIBILITY AND HEALING
-- These two have no buttons. You use them by typing chat commands
-- ("invisible", "visible", "heal"...) when Chat mode is on.
-- ================================================================

-- The IDs of walking/standing/jumping animations for the fake copy.
local ANIM_IDS = {
    R15 = {
        idle = "rbxassetid://507766666",
        walk = "rbxassetid://507777826",
        jump = "rbxassetid://507765000",
        fall = "rbxassetid://507767968",
    },
    R6 = {
        idle = "rbxassetid://180435571",
        walk = "rbxassetid://180426354",
        jump = "rbxassetid://125750702",
        fall = "rbxassetid://180436148",
    },
}
local INVIS_DEPTH = 150   -- how far under the ground the hiding box goes
local INVIS_HEIGHT = 300  -- if there is no ground, how far up it goes

-- Everything about invisibility is kept in this one box.
local invis = {
    on = false, clone = nil, box = nil, realRoot = nil,
    runConns = {}, update = nil,
}

-- invisOff: becomes visible again.
local function invisOff()
    if not invis.on then return end
    invis.on = false

    -- Stop every listener we started.
    for _, c in ipairs(invis.runConns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(invis.runConns)

    -- Remember where the copy ended up, then remove the copy and the hiding box.
    local cloneRoot = invis.clone and invis.clone:FindFirstChild("HumanoidRootPart")
    local dest = cloneRoot and cloneRoot.CFrame
    if invis.clone then invis.clone:Destroy(); invis.clone = nil end
    if invis.box then invis.box:Destroy(); invis.box = nil end

    -- Put the real you back where the copy was standing.
    local real = invis.realRoot
    if real and real.Parent then
        real.Anchored = false
        if dest then real.CFrame = dest + Vector3.new(0, 1, 0) end
        real.AssemblyLinearVelocity = Vector3.zero
    end
    invis.realRoot = nil
    pcall(function() LP.ReplicationFocus = nil end)

    -- Point the camera at your real character again.
    local ch = LP.Character
    local h = ch and ch:FindFirstChildOfClass("Humanoid")
    local cam = workspace.CurrentCamera
    if cam and h and cam.CameraType ~= Enum.CameraType.Scriptable then cam.CameraSubject = h end

    if addLog then addLog("Invisibility off") end
    notify("Invisibility off")
end

-- startCloneAnims: makes the fake copy play walking/standing animations.
-- Returns a "play" recipe: play("walk"), play("idle"), and so on.
local function startCloneAnims(hum, rigType)
    local ids = ANIM_IDS[rigType] or ANIM_IDS.R6
    local animator = hum:FindFirstChildOfClass("Animator") or make("Animator", {}, hum)
    local tracks = {}
    for name, id in pairs(ids) do
        pcall(function()
            local a = make("Animation", {AnimationId = id}, nil)
            local t = animator:LoadAnimation(a)
            t.Looped = (name == "idle" or name == "walk" or name == "fall")
            tracks[name] = t
        end)
    end
    local current
    local function play(name, speed)
        if current ~= name then
            if current and tracks[current] then tracks[current]:Stop(0.15) end
            current = name
            if tracks[name] then tracks[name]:Play(0.15) end
        end
        if name == "walk" and tracks.walk then
            tracks.walk:AdjustSpeed(speed or 1)
        end
    end
    return play
end

-- invisOn: becomes invisible.
-- Idea: we make a see-through copy of you that other players see and that you
-- control. Your REAL body gets moved into a hidden box far away.
local function invisOn()
    if invis.on then return false, "Already invisible." end
    local ch = LP.Character
    local h = ch and ch:FindFirstChildOfClass("Humanoid")
    local r = ch and ch:FindFirstChild("HumanoidRootPart")
    if not (h and r) then return false, "Your character isn't ready." end

    -- Can't fly and be invisible at the same time.
    if flyEnabled then
        stopFly()
        setFlyUI(false)
    end

    ch.Archivable = true
    local clone = ch:Clone() -- make the copy
    if not clone then return false, "Couldn't copy your character." end

    -- Clean the copy: remove scripts, make it half see-through.
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("LuaSourceContainer") or d:IsA("BillboardGui") then
            d:Destroy()
        elseif d:IsA("BasePart") then
            if d.Name ~= "HumanoidRootPart" and d.Transparency < 0.5 then
                d.Transparency = 0.5
            end
            d.Anchored = false
        elseif d:IsA("Decal") or d:IsA("Texture") then
            if d.Transparency < 0.5 then d.Transparency = 0.5 end
        end
    end

    local cloneHum = clone:FindFirstChildOfClass("Humanoid")
    local cloneRoot = clone:FindFirstChild("HumanoidRootPart")
    if not cloneHum or not cloneRoot then
        clone:Destroy()
        return false, "Couldn't copy your character."
    end
    cloneHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    cloneHum.BreakJointsOnDeath = false
    cloneHum.WalkSpeed = h.WalkSpeed
    cloneHum.UseJumpPower = true
    cloneHum.JumpPower = h.JumpPower
    clone.Name = "MOCHI_InvisCopy"

    -- Find the ground under you so we can hide the real body below it.
    local origin = r.CFrame
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {ch}
    local hit = workspace:Raycast(origin.Position, Vector3.new(0, -3000, 0), params)
    local groundY = hit and hit.Position.Y or (origin.Position.Y - 5)
    local floorY = math.max(groundY - INVIS_DEPTH, workspace.FallenPartsDestroyHeight + 60)
    local center
    if floorY <= groundY - 40 then
        center = Vector3.new(origin.Position.X, floorY, origin.Position.Z) -- hide underground
    else
        center = origin.Position + Vector3.new(0, INVIS_HEIGHT, 0)         -- or high in the sky
    end

    -- Build a little hiding room with a floor, roof and four walls.
    local box = make("Model", {Name = "MOCHI_InvisBox"}, workspace)
    local function wall(size, offset)
        make("Part", {
            Size = size,
            Position = center + offset,
            Anchored = true,
            CanCollide = true,
            Transparency = 0.7,
            Material = Enum.Material.SmoothPlastic,
            Color = theme.panel,
        }, box)
    end
    wall(Vector3.new(14, 1, 14), Vector3.new(0, -0.5, 0))   -- floor
    wall(Vector3.new(14, 1, 14), Vector3.new(0, 10, 0))     -- roof
    wall(Vector3.new(1, 10, 14), Vector3.new(7, 5, 0))      -- right wall
    wall(Vector3.new(1, 10, 14), Vector3.new(-7, 5, 0))     -- left wall
    wall(Vector3.new(14, 10, 1), Vector3.new(0, 5, 7))      -- back wall
    wall(Vector3.new(14, 10, 1), Vector3.new(0, 5, -7))     -- front wall

    clone:PivotTo(origin)
    clone.Parent = workspace

    pcall(function() LP.ReplicationFocus = cloneRoot end)

    -- Move the real you into the hiding room and freeze it there.
    r.CFrame = CFrame.new(center + Vector3.new(0, 4, 0))
    r.AssemblyLinearVelocity = Vector3.zero
    r.Anchored = true

    invis.on = true
    invis.clone = clone
    invis.box = box
    invis.realRoot = r

    -- Point the camera at the copy.
    local cam = workspace.CurrentCamera
    if cam and not spectatingPlayer and cam.CameraType ~= Enum.CameraType.Scriptable then
        cam.CameraSubject = cloneHum
    end

    local rigType = h.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
    local play = startCloneAnims(cloneHum, rigType)

    -- "controls" reads your joystick so we can walk the copy around.
    local controls
    pcall(function()
        local ps = LP:FindFirstChild("PlayerScripts")
        local pm = ps and ps:FindFirstChild("PlayerModule")
        if pm then controls = require(pm):GetControls() end
    end)

    -- Every frame: make the copy walk where you push the joystick.
    invis.runConns[#invis.runConns + 1] = RunService.RenderStepped:Connect(function()
        if not invis.on then return end
        if not clone.Parent or not h.Parent then
            invisOff()
            return
        end
        cloneHum.WalkSpeed = h.WalkSpeed
        cloneHum.JumpPower = h.JumpPower

        local dir = h.MoveDirection
        if dir.Magnitude < 0.05 and controls then
            local okMove, mv = pcall(function() return controls:GetMoveVector() end)
            local camera = workspace.CurrentCamera
            if okMove and mv and mv.Magnitude > 0.05 and camera then
                local world = camera.CFrame:VectorToWorldSpace(Vector3.new(mv.X, 0, mv.Z))
                world = Vector3.new(world.X, 0, world.Z)
                if world.Magnitude > 0.001 then
                    dir = world.Unit * math.min(1, mv.Magnitude)
                end
            end
        end
        cloneHum:Move(dir, false)

        -- Pick the right animation for what the copy is doing.
        local state = cloneHum:GetState()
        if state == Enum.HumanoidStateType.Freefall then
            play("fall")
        elseif state == Enum.HumanoidStateType.Jumping then
            play("jump")
        elseif dir.Magnitude > 0.1 then
            play("walk", cloneHum.WalkSpeed / 14)
        else
            play("idle")
        end
    end)

    -- When you press jump, the copy jumps.
    invis.runConns[#invis.runConns + 1] = UserInputService.JumpRequest:Connect(function()
        if invis.on and cloneHum.Parent then cloneHum.Jump = true end
    end)

    -- If you die or respawn, become visible again.
    invis.runConns[#invis.runConns + 1] = h.Died:Connect(function()
        invisOff()
    end)

    invis.runConns[#invis.runConns + 1] = LP.CharacterAdded:Connect(function()
        invisOff()
    end)

    if addLog then addLog("Invisibility on") end
    notify("Invisibility on", "good")
    return true
end

-- Heal: keeps your health full by filling it up every frame.
local heal = {on = false, conn = nil}

local function healOff()
    heal.on = false
    if heal.conn then
        heal.conn:Disconnect()
        heal.conn = nil
    end
end

local function healOn()
    if heal.conn then heal.conn:Disconnect() end
    heal.on = true
    heal.conn = RunService.Heartbeat:Connect(function()
        local ch = LP.Character
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 and h.Health < h.MaxHealth then
            h.Health = h.MaxHealth
        end
    end)
end

-- ================================================================
-- PART 9: CAMERA - WATCHING OTHER PLAYERS AND FREE CAMERA
-- ================================================================

-- clearSpectate: stop watching someone and look at yourself again.
local function clearSpectate()
    spectatingPlayer = nil
    local camera = workspace.CurrentCamera
    local h
    if invis.on and invis.clone then
        h = invis.clone:FindFirstChildOfClass("Humanoid")
    else
        h = select(1, getParts())
    end
    if camera and h and camera.CameraType ~= Enum.CameraType.Scriptable then
        camera.CameraSubject = h
    end
    if viewStatus and viewStatus.Parent then
        viewStatus.Text = "Not viewing anyone."
        viewStatus.TextColor3 = theme.muted
    end
end

-- viewPlayer: point the camera at another player.
local function viewPlayer(p)
    local ch = p and p.Character
    local h = ch and ch:FindFirstChildOfClass("Humanoid")
    local camera = workspace.CurrentCamera
    if not (h and camera) then return false end
    spectatingPlayer = p
    camera.CameraSubject = h
    if viewStatus and viewStatus.Parent then
        viewStatus.Text = "Viewing " .. p.DisplayName .. " (@" .. p.Name .. ")"
        viewStatus.TextColor3 = theme.good
    end
    return true
end

-- otherPlayers: a list of everyone EXCEPT you, sorted A to Z.
local function otherPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then list[#list + 1] = p end
    end
    table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
    return list
end

-- findPlayer: finds a player from part of their name.
-- First it looks for names that START with the text, then names that CONTAIN it.
local function findPlayer(text)
    text = text:lower()
    for _, p in ipairs(otherPlayers()) do
        if p.Name:lower():sub(1, #text) == text or p.DisplayName:lower():sub(1, #text) == text then
            return p
        end
    end
    for _, p in ipairs(otherPlayers()) do
        if p.Name:lower():find(text, 1, true) or p.DisplayName:lower():find(text, 1, true) then
            return p
        end
    end
    return nil
end

-- cycleView: flips to the next (dir = 1) or previous (dir = -1) player.
local function cycleView(dir)
    local list = otherPlayers()
    if #list == 0 then
        if viewStatus then viewStatus.Text = "No other players." end
        notify("No other players to view.", "error")
        return
    end
    local idx = 0
    for i, p in ipairs(list) do
        if p == spectatingPlayer then idx = i end
    end
    if idx == 0 then
        idx = dir > 0 and 1 or #list
    else
        idx = (idx - 1 + dir) % #list + 1 -- wraps around at the ends
    end
    if not viewPlayer(list[idx]) then
        if viewStatus then
            viewStatus.Text = "That player's character isn't available."
            viewStatus.TextColor3 = theme.danger
        end
        notify("That player's character isn't available.", "error")
    end
end

-- viewByName: watch the player whose name matches the text.
local function viewByName(text)
    local found = findPlayer(text)
    if not found then
        if viewStatus then
            viewStatus.Text = "No player matches \"" .. text .. "\"."
            viewStatus.TextColor3 = theme.danger
        end
        notify("No player matches \"" .. text .. "\".", "error")
        return
    end
    if not viewPlayer(found) then
        if viewStatus then
            viewStatus.Text = "That player's character isn't available."
            viewStatus.TextColor3 = theme.danger
        end
        notify("That player's character isn't available.", "error")
    end
end

-- resetCameraSubject: points the camera at whoever it should follow right now.
local function resetCameraSubject()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local h
    if spectatingPlayer and spectatingPlayer.Character then
        h = spectatingPlayer.Character:FindFirstChildOfClass("Humanoid")
    elseif invis.on and invis.clone then
        h = invis.clone:FindFirstChildOfClass("Humanoid")
    else
        h = select(1, getParts())
    end
    if h then camera.CameraSubject = h end
end

-- Free camera: the camera floats around by itself while your character stands still.
local freecam = {
    on = false, pos = Vector3.zero, yaw = 0, pitch = 0, speed = 40,
    up = false, down = false, touch = nil, mouse = false, conns = {}, update = nil,
}

-- stopFreecam: turn the free camera off.
local function stopFreecam()
    if not freecam.on then return end
    freecam.on = false
    pcall(function() RunService:UnbindFromRenderStep("MOCHI_Freecam") end)
    for _, c in ipairs(freecam.conns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(freecam.conns)
    freecam.up, freecam.down, freecam.touch, freecam.mouse = false, false, nil, false

    local camera = workspace.CurrentCamera
    if camera then camera.CameraType = Enum.CameraType.Custom end -- give control back to Roblox
    resetCameraSubject()
    applyMovement()
    if freecam.update then freecam.update() end
    notify("Free camera off")
end

-- startFreecam: turn the free camera on.
local function startFreecam()
    if freecam.on then return end
    local camera = workspace.CurrentCamera
    if not camera then
        notify("No camera found.", "error")
        return
    end
    local h = select(1, getParts())

    freecam.on = true
    local cf = camera.CFrame
    freecam.pos = cf.Position
    local rx, ry = cf:ToOrientation()
    freecam.pitch, freecam.yaw = rx, ry
    camera.CameraType = Enum.CameraType.Scriptable -- "we drive the camera now"

    -- Freeze your character so it doesn't wander while you look around.
    if h then
        h.WalkSpeed = 0
        h.UseJumpPower = true
        h.JumpPower = 0
    end

    local controls
    pcall(function()
        local ps = LP:FindFirstChild("PlayerScripts")
        local pm = ps and ps:FindFirstChild("PlayerModule")
        if pm then controls = require(pm):GetControls() end
    end)

    -- Listen for touches / right-click / Q / E keys.
    local lastTouchPos
    freecam.conns[#freecam.conns + 1] = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Touch and not freecam.touch then
            freecam.touch = input
            lastTouchPos = input.Position
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            freecam.mouse = true
        elseif input.KeyCode == Enum.KeyCode.E then
            freecam.up = true
        elseif input.KeyCode == Enum.KeyCode.Q then
            freecam.down = true
        end
    end)
    -- Dragging turns the camera left/right/up/down.
    freecam.conns[#freecam.conns + 1] = UserInputService.InputChanged:Connect(function(input)
        if freecam.touch and input == freecam.touch then
            local d = input.Position - lastTouchPos
            lastTouchPos = input.Position
            freecam.yaw -= d.X * 0.006
            freecam.pitch = math.clamp(freecam.pitch - d.Y * 0.006, -1.5, 1.5)
        elseif freecam.mouse and input.UserInputType == Enum.UserInputType.MouseMovement then
            freecam.yaw -= input.Delta.X * 0.004
            freecam.pitch = math.clamp(freecam.pitch - input.Delta.Y * 0.004, -1.5, 1.5)
        end
    end)
    freecam.conns[#freecam.conns + 1] = UserInputService.InputEnded:Connect(function(input)
        if freecam.touch and input == freecam.touch then
            freecam.touch = nil
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            freecam.mouse = false
        elseif input.KeyCode == Enum.KeyCode.E then
            freecam.up = false
        elseif input.KeyCode == Enum.KeyCode.Q then
            freecam.down = false
        end
    end)

    -- Every frame, move the camera where you steer it.
    RunService:BindToRenderStep("MOCHI_Freecam", Enum.RenderPriority.Camera.Value + 1, function(dt)
        local cam = workspace.CurrentCamera
        if not cam or not freecam.on then return end
        local rot = CFrame.fromOrientation(freecam.pitch, freecam.yaw, 0)

        local mv = Vector3.zero
        if controls then
            local okMove, v = pcall(function() return controls:GetMoveVector() end)
            if okMove and v then mv = v end
        end
        if mv.Magnitude < 0.05 then
            local hh = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hh and hh.MoveDirection.Magnitude > 0.05 then
                local lv = rot:VectorToObjectSpace(hh.MoveDirection)
                mv = Vector3.new(lv.X, 0, lv.Z)
            end
        end

        local dir = rot.LookVector * (-mv.Z) + rot.RightVector * mv.X
        local vert = (freecam.up and 1 or 0) - (freecam.down and 1 or 0)
        local move = dir + Vector3.new(0, vert, 0)
        if move.Magnitude > 1 then move = move.Unit end

        freecam.pos += move * freecam.speed * dt
        cam.CFrame = CFrame.new(freecam.pos) * rot
    end)

    if freecam.update then freecam.update() end
    notify("Free camera on. Drag the screen to look.", "good")
end

-- If you respawn, the free camera turns off.
track(LP.CharacterAdded:Connect(function()
    stopFreecam()
end))

-- ================================================================
-- PART 10: LIGHTING (BRIGHTNESS, FULLBRIGHT, CAMERA EFFECTS)
-- ================================================================

-- Save how the game's lighting looked at the start, so we can put it back later.
local origLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}
local light = {fullbright = false, customBrightness = nil, saved = nil, conn = nil}

-- applyLight: sets the lighting the way we want it.
local function applyLight()
    if light.fullbright then
        Lighting.Brightness = light.customBrightness or 2
        Lighting.ClockTime = 14          -- 2 in the afternoon = bright daytime
        Lighting.FogStart = 100000       -- push the fog super far away
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false   -- no shadows
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    elseif light.customBrightness then
        Lighting.Brightness = light.customBrightness
    end
end

-- Games sometimes change the lighting back. So while we need it,
-- we re-apply our settings every frame.
local function updateLightLoop()
    local need = light.fullbright or light.customBrightness ~= nil
    if need and not light.conn then
        light.conn = RunService.Heartbeat:Connect(applyLight)
    elseif not need and light.conn then
        light.conn:Disconnect()
        light.conn = nil
    end
end

-- setFullbright: turn fullbright on or off.
local function setFullbright(on)
    if on == light.fullbright then return end
    if on then
        -- Save the current lighting first so we can undo later.
        light.saved = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            GlobalShadows = Lighting.GlobalShadows,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
        }
        light.fullbright = true
    else
        light.fullbright = false
        local s = light.saved
        if s then
            if not light.customBrightness then Lighting.Brightness = s.Brightness end
            Lighting.ClockTime = s.ClockTime
            Lighting.FogEnd = s.FogEnd
            Lighting.FogStart = s.FogStart
            Lighting.GlobalShadows = s.GlobalShadows
            Lighting.Ambient = s.Ambient
            Lighting.OutdoorAmbient = s.OutdoorAmbient
        end
    end
    updateLightLoop()
end

-- Camera effects = blur, bloom, color changes, and so on.
-- "fx" remembers which ones we switched off so we can switch them back on.
local fx = {on = false, saved = {}, conn = nil, last = 0}

-- scanEffects: finds every effect that is on and turns it off.
local function scanEffects()
    local function handle(rootInstance)
        for _, d in ipairs(rootInstance:GetDescendants()) do
            if d:IsA("PostEffect") and d.Enabled then
                fx.saved[#fx.saved + 1] = d
                d.Enabled = false
            end
        end
    end
    handle(Lighting)
    if workspace.CurrentCamera then handle(workspace.CurrentCamera) end
end

-- setEffectsOff(true) = turn effects off. setEffectsOff(false) = bring them back.
local function setEffectsOff(on)
    if on == fx.on then return end
    fx.on = on
    if on then
        scanEffects()
        -- Check again twice a second, in case the game adds new effects.
        fx.conn = RunService.Heartbeat:Connect(function()
            if os.clock() - fx.last > 0.5 then
                fx.last = os.clock()
                scanEffects()
            end
        end)
    else
        if fx.conn then
            fx.conn:Disconnect()
            fx.conn = nil
        end
        for _, d in ipairs(fx.saved) do
            if d.Parent then d.Enabled = true end
        end
        table.clear(fx.saved)
    end
end

-- ================================================================
-- PART 11: THE MAIN WINDOW
-- ================================================================

-- Pick a window size that fits your screen.
local cam0 = workspace.CurrentCamera
local vp = cam0 and cam0.ViewportSize or Vector2.new(800, 600) -- vp = screen size
local W = math.clamp(vp.X - 30, 250, 350) -- width
local H = math.clamp(vp.Y - 30, 180, 270) -- height

-- The big window that holds everything.
main = make("Frame", {
    Name = "MainWindow",
    BackgroundColor3 = theme.bg,
    Size = UDim2.fromOffset(W, H),
    Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2), -- middle of the screen
    BorderSizePixel = 0,
    Active = true,
    Visible = false, -- hidden until the loading screen finishes
}, gui)
round(main, 16)
make("UIGradient", {
    Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 212, 204)),
    Rotation = 90,
}, main)

-- A glowing border that slowly spins around the window.
local borderSpinTween
local mainStroke = outline(main, theme.accent, 1.8, 0.25)
local strokeGradient = make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.leaf),
        ColorSequenceKeypoint.new(0.5, theme.glow),
        ColorSequenceKeypoint.new(1, theme.leaf),
    }),
    Rotation = 0,
}, mainStroke)
borderSpinTween = registerDecorativeTween(TweenService:Create(
    strokeGradient,
    TweenInfo.new(7, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    {Rotation = 360}
))
if not performanceMode then borderSpinTween:Play() end

-- The window can't be made smaller or bigger than these sizes.
make("UISizeConstraint", {
    MinSize = Vector2.new(250, 170),
    MaxSize = Vector2.new(850, 700),
}, main)
-- mainScale lets us "pop" the window open and closed.
local mainScale = make("UIScale", {Scale = 0.88}, main)
-- User-selected interface size is separate from the open/close animation scale.
local uiSizeScale = make("UIScale", {Scale = 1}, main)

-- The top bar (the header) that you drag to move the window.
local header = make("Frame", {
    BackgroundColor3 = theme.panel,
    Size = UDim2.new(1, 0, 0, 36),
    BorderSizePixel = 0,
}, main)
round(header, 16)
make("UIGradient", {
    Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(222, 234, 226)),
    Rotation = 0,
}, header)
-- Fills in the rounded bottom corners of the header so they look square.
local headerFill = make("Frame", {
    BackgroundColor3 = theme.panel,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -16),
    Size = UDim2.new(1, 0, 0, 16),
}, header)
make("UIGradient", {
    Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(222, 234, 226)),
    Rotation = 0,
}, headerFill)
-- A thin line under the header.
make("Frame", {
    BackgroundColor3 = theme.accent,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -1),
    Size = UDim2.new(1, 0, 0, 1),
}, header)

-- The little logo in the header. It gently grows and shrinks.
local headerLogo = makeLogo(header, 24, UDim2.new(0, 9, 0.5, 0), Vector2.new(0, 0.5))
local logoScale = make("UIScale", {Scale = 1}, headerLogo)
local headerLogoPulse = registerDecorativeTween(TweenService:Create(
    logoScale,
    TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Scale = 1.1}
))
if not performanceMode then headerLogoPulse:Play() end

-- The MOCHI title.
make("TextLabel", {
    BackgroundTransparency = 1,
    Text = "MOCHI",
    TextColor3 = theme.text,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    Position = UDim2.new(0, 40, 0, 0),
    Size = UDim2.new(0, 48, 1, 0),
}, header)

-- The ✕ button (closes MOCHI) and the − button (hides MOCHI into the ball).
local closeButton = make("TextButton", {
    Text = "✕",
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    TextColor3 = theme.danger,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 44, 1, 0),
    Position = UDim2.new(1, -46, 0, 0),
}, header)

local minimizeButton = make("TextButton", {
    Text = "−",
    TextSize = 22,
    Font = Enum.Font.Gotham,
    TextColor3 = theme.text,
    BackgroundTransparency = 1,
    Size = UDim2.new(0, 34, 1, 0),
    Position = UDim2.new(1, -82, 0, 0),
}, header)

minimizeButton.MouseEnter:Connect(function()
    tween(minimizeButton, {TextColor3 = theme.accent}, 0.15)
end)
minimizeButton.MouseLeave:Connect(function()
    tween(minimizeButton, {TextColor3 = theme.text}, 0.2)
end)

-- The list of tab buttons down the left side.
local nav = make("ScrollingFrame", {
    BackgroundColor3 = theme.panel,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 6, 0, 42),
    Size = UDim2.new(0, 80, 1, -48),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ScrollBarThickness = 0,
}, main)
round(nav, 10)
outline(nav, theme.panel2, 1, 0.3)
make("UIPadding", {
    PaddingTop = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 4),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
}, nav)
make("UIListLayout", {
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, nav)

-- The big area on the right where the current tab's page shows up.
local pageHost = make("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 92, 0, 42),
    Size = UDim2.new(1, -98, 1, -48),
    ClipsDescendants = true, -- anything sticking out gets cut off
}, main)

-- makePage: makes an empty page for a tab.
local function makePage(name)
    local p = make("CanvasGroup", {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    }, pageHost)
    pages[name] = p
    return p
end

-- showPage: shows one tab's page and hides all the others.
local currentPage
local function showPage(name, instant)
    -- Leaving the Executor/Search tabs? Put the window back to its normal size.
    if name ~= "Executor" and name ~= "Search" and restoreExec then restoreExec(false) end
    local target = pages[name]
    if not target then return end

    for pageName, p in pairs(pages) do
        if pageName ~= name then p.Visible = false end
    end

    if currentPage ~= name then
        currentPage = name
        target.Visible = true
        if instant then
            target.GroupTransparency = 0
            target.Position = UDim2.new()
        else
            -- Slide up and fade in.
            target.GroupTransparency = 1
            target.Position = UDim2.new(0, 0, 0, 14)
            tween(target, {GroupTransparency = 0, Position = UDim2.new()}, 0.32, Enum.EasingStyle.Quint)
        end
    else
        target.Visible = true
    end

    -- Make the active tab's button green, and the others grey.
    for buttonName, b in pairs(navButtons) do
        local active = buttonName == name
        tween(b, {
            BackgroundColor3 = active and theme.accent or theme.panel2,
            TextColor3 = active and theme.bg or theme.text,
        }, 0.22)
    end
end

-- Make a button on the left AND a page for every tab name in this list.
do
    local TAB_ORDER = {"Home", "Player", "Players", "Visuals", "Search", "Tools", "Games", "Executor", "Script Hubs", "Extras", "Activity", "Settings"}
    for _, name in ipairs(TAB_ORDER) do
        local b = button(nav, name, function()
            showPage(name)
        end, theme.panel2, 25)
        b.TextSize = 11
        navButtons[name] = b
    end
    for _, name in ipairs(TAB_ORDER) do
        makePage(name)
    end
end

-- ================================================================
-- PART 12: THE HOME TAB
-- A round clock on top, the time in numbers under it, and the
-- recommended script (Infinite Yield) under that. All of it fits on
-- the screen at the same time, so you never have to scroll.
-- ================================================================
do
    local home = pages["Home"]

    -- UIListLayout stacks things top to bottom. Centered, so the clock sits in the middle.
    make("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, home)
    make("UIPadding", {PaddingTop = UDim.new(0, 2)}, home)

    -- ---------- THE ROUND CLOCK FACE ----------
    local CLOCK = 84 -- how wide and tall the clock is, in pixels
    local clockFace = make("Frame", {
        LayoutOrder = 1, -- 1 = first thing on the page
        BackgroundColor3 = theme.panel,
        Size = UDim2.fromOffset(CLOCK, CLOCK),
    }, home)
    round(clockFace, CLOCK) -- a huge corner radius turns a square into a circle
    outline(clockFace, theme.accent, 2, 0.2)

    -- The 12 little tick marks around the edge.
    -- Trick: a thing in Roblox spins around its own middle. So for each tick
    -- we make a see-through square the same size as the clock, put a tick at
    -- the top of it, and spin the square. The tick swings around the edge.
    for i = 0, 11 do
        local spinner = make("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 0),
            Rotation = i * 30, -- 12 ticks x 30 degrees = a full circle (360)
        }, clockFace)
        local big = i % 3 == 0 -- the ticks at 12, 3, 6 and 9 are bigger
        make("Frame", {
            BackgroundColor3 = big and theme.text or theme.muted,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 4),
            Size = UDim2.fromOffset(big and 3 or 2, big and 7 or 4),
        }, spinner)
    end

    -- makeHand: builds a clock hand (a thin stick) that we can spin.
    -- Same spinning trick as the ticks. The see-through "spinner" square is
    -- twice as big as the hand, so the middle of the square is the middle of
    -- the clock. The hand points up from the middle.
    local function makeHand(length, width, color)
        local spinner = make("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(length * 2, length * 2),
        }, clockFace)
        local hand = make("Frame", {
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.fromOffset(width, length),
        }, spinner)
        round(hand, width)
        return spinner
    end

    local hourHand = makeHand(20, 4, theme.text)       -- short and fat
    local minuteHand = makeHand(29, 3, theme.accent)   -- longer
    local secondHand = makeHand(33, 1, theme.danger)   -- longest and thinnest

    -- The little dot in the very middle.
    local centerDot = make("Frame", {
        BackgroundColor3 = theme.text,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(7, 7),
        ZIndex = 3,
    }, clockFace)
    round(centerDot, 7)

    -- ---------- THE TIME IN NUMBERS (UNDER THE CLOCK) ----------
    local digital = make("TextLabel", {
        LayoutOrder = 2, -- 2 = second thing on the page
        BackgroundTransparency = 1,
        Text = "--:--:--",
        TextColor3 = theme.text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        Size = UDim2.new(1, 0, 0, 22),
    }, home)

    -- ---------- THE RECOMMENDED SCRIPT (UNDER THE TIME) ----------
    local iyCard = section(home, "Recommended: Infinite Yield")
    iyCard.LayoutOrder = 3 -- 3 = third thing on the page
    local iyStatus = label(iyCard, "Tap the button to load it.", 10, theme.muted)

    local iyLoaded = false -- remembers if we already loaded it
    button(iyCard, "Execute Infinite Yield", function(btn)
        -- Already loaded? Don't load it twice.
        if iyLoaded then
            iyStatus.Text = "Infinite Yield is already running."
            notify("Infinite Yield is already running.")
            return
        end

        iyStatus.Text = "Loading..."
        iyStatus.TextColor3 = theme.muted

        -- task.spawn = "do this on the side" so the menu doesn't freeze while downloading.
        task.spawn(function()
            -- game:HttpGet downloads the script as text.
            -- loadstring turns that text into something we can run.
            -- The extra () at the end runs it.
            local okRun, errRun = pcall(function()
                loadstring(game:HttpGet(IY_SOURCE))()
            end)

            if okRun then
                iyLoaded = true
                btn.Text = "Infinite Yield: LOADED"
                tween(btn, {BackgroundColor3 = theme.good, TextColor3 = theme.bg}, 0.3)
                iyStatus.Text = "Infinite Yield loaded."
                iyStatus.TextColor3 = theme.good
                notify("Infinite Yield loaded", "good")
                if addLog then addLog("Executed Infinite Yield") end
            else
                iyStatus.Text = "Failed: " .. tostring(errRun)
                iyStatus.TextColor3 = theme.danger
                notify("Infinite Yield failed: " .. tostring(errRun), "error")
                if addLog then addLog("Infinite Yield failed to load") end
            end
        end)
    end, theme.accent, 28)

    -- Every second, move the three hands and change the numbers.
    task.spawn(function()
        while gui.Parent do -- keep going as long as MOCHI is still open
            -- os.date("*t") gives the time from YOUR device, split into pieces.
            local now = os.date("*t")
            local sec, min, hr = now.sec, now.min, now.hour % 12 -- % 12 makes 13:00 become 1:00

            -- A full circle is 360 degrees.
            --   second hand: 60 seconds, so 6 degrees per second
            --   minute hand: 60 minutes, so 6 degrees per minute (plus a tiny bit for the seconds)
            --   hour hand:   12 hours,   so 30 degrees per hour  (plus a tiny bit for the minutes)
            secondHand.Rotation = sec * 6
            minuteHand.Rotation = min * 6 + sec * 0.1
            hourHand.Rotation = hr * 30 + min * 0.5

            -- Keep the clock accurate but poll less often in Performance Mode.
            digital.Text = os.date("%I:%M:%S %p")
            task.wait(performanceMode and 5 or 1)
        end
    end)
end

-- ================================================================
-- PART 13: RUNNING SCRIPTS FROM THE INTERNET
-- ================================================================

-- runRemote: downloads one script from its web address and runs it.
--   entry     = one item from the GAMES / TOOLS / HUBS lists (has a name and a url)
--   setStatus = a recipe that writes a message on the screen
local function runRemote(entry, setStatus)
    setStatus("Loading " .. entry.name .. "...", theme.muted)
    task.spawn(function()
        local okRun, errRun = pcall(function()
            loadstring(game:HttpGet(entry.url))()
        end)
        if okRun then
            setStatus(entry.name .. " executed.", theme.good)
            notify(entry.name .. " executed", "good")
            if addLog then addLog("Executed " .. entry.name) end
        else
            setStatus("Failed (" .. entry.name .. "): " .. tostring(errRun), theme.danger)
            notify("Couldn't run " .. entry.name .. ": " .. tostring(errRun), "error")
            if addLog then addLog(entry.name .. " failed to load") end
        end
    end)
end

-- The Games, Tools and Script Hubs tabs all look the same: a title,
-- a line of status words, and one button for every script in the list.
-- So we write the recipe once and use it three times.
do
    local function buildScriptTab(page, title, hint, list)
        local sc = scroll(page)
        local card = section(sc, title)
        local status = label(card, hint, 10, theme.muted)
        local function setStatus(text, color)
            status.Text = text
            status.TextColor3 = color
        end

        -- Make one button for every script in the list.
        for _, entry in ipairs(list) do
            button(card, entry.name, function()
                runRemote(entry, setStatus)
            end, theme.panel2, 27)
        end
    end

    buildScriptTab(pages["Games"], "Games", "Tap a game to execute its script.", GAMES)
    buildScriptTab(pages["Tools"], "Tools", "Tap a tool to execute it.", TOOLS)
    buildScriptTab(pages["Script Hubs"], "Script Hubs", "Tap a hub to execute it.", HUBS)
end

-- ================================================================
-- PART 14: THE EXECUTOR TAB
-- A box where you type your own Lua code and run it.
-- ================================================================
do
    local execPage = pages["Executor"]

    -- The row at the top that holds the Execute and Clear buttons.
    local execRow = make("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 30),
    }, execPage)

    -- One line of words under the buttons that says what happened.
    local execStatus = make("TextLabel", {
        BackgroundTransparency = 1,
        Text = "Ready. Type or paste Lua below, then tap Execute.",
        TextColor3 = theme.muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.new(0, 2, 0, 32),
        Size = UDim2.new(1, -4, 0, 16),
    }, execPage)

    -- The box that the typing area sits inside.
    local editorWrap = make("Frame", {
        BackgroundColor3 = theme.panel,
        Position = UDim2.new(0, 0, 0, 50),
        Size = UDim2.new(1, 0, 1, -50),
    }, execPage)
    round(editorWrap, 10)
    local editorStroke = outline(editorWrap, theme.panel2, 1, 0.2)

    local editorScroll = make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 5, 0, 5),
        Size = UDim2.new(1, -10, 1, -10),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.accent,
    }, editorWrap)

    -- The typing area itself. MultiLine = true lets you press Enter for a new line.
    local editor = make("TextBox", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, 120),
        AutomaticSize = Enum.AutomaticSize.Y,
        MultiLine = true,
        ClearTextOnFocus = false,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextColor3 = theme.text,
        PlaceholderText = "-- type or paste Lua here\n-- tip: print(\"hello\") shows in the developer console (F9)",
        PlaceholderColor3 = theme.muted,
        Text = "",
    }, editorScroll)

    local function setExecStatus(text, color)
        execStatus.Text = text
        tween(execStatus, {TextColor3 = color}, 0.2)
    end

    -- runCode: takes the typed text and runs it as code.
    local function runCode(code)
        -- code:match("^%s*$") is true when the box is empty (or only spaces).
        if code:match("^%s*$") then
            setExecStatus("Nothing to run. Type some Lua first.", theme.muted)
            notify("Nothing to run.")
            return
        end

        task.spawn(function()
            -- Step 1: loadstring checks the spelling/grammar of the code.
            -- If something is wrong, it gives back an error instead of a recipe.
            local fn, compileErr = loadstring(code)
            if not fn then
                setExecStatus("Syntax error: " .. tostring(compileErr), theme.danger)
                notify("Syntax error: " .. tostring(compileErr), "error")
                if addLog then addLog("Executor: syntax error") end
                return
            end

            -- Step 2: actually run it. pcall catches mistakes while it runs.
            local okRun, runErr = pcall(fn)
            if okRun then
                setExecStatus("Executed successfully.", theme.good)
                notify("Script executed", "good")
                if addLog then addLog("Executor: ran script") end
            else
                setExecStatus("Error: " .. tostring(runErr), theme.danger)
                notify("Script error: " .. tostring(runErr), "error")
                if addLog then addLog("Executor: runtime error") end
            end
        end)
    end

    local execBtn = button(execRow, "Execute", function()
        runCode(editor.Text)
    end, theme.accent, 30)
    execBtn.Size = UDim2.new(0.62, -3, 1, 0)

    local clearBtn = button(execRow, "Clear", function()
        editor.Text = ""
        setExecStatus("Cleared.", theme.muted)
    end, theme.panel2, 30)
    clearBtn.Position = UDim2.new(0.62, 3, 0, 0)
    clearBtn.Size = UDim2.new(0.38, -3, 1, 0)

    -- When you start typing, the phone keyboard pops up and covers half the
    -- screen. So we shrink the window and slide it to the top.
    -- restoreExec puts it back to how it was.
    restoreExec = function(keepPosition)
        if not execSaved then return end
        if main and main.Parent then
            local goal = {Size = execSaved.size}
            if not keepPosition then goal.Position = execSaved.pos end
            tween(main, goal, 0.28, Enum.EasingStyle.Quint)
        end
        execSaved = nil
    end

    -- enterTypingMode: shrink and move the window to the top (and remember where it was).
    enterTypingMode = function()
        if execSaved or not main then return end
        execSaved = {pos = main.Position, size = main.Size}
        tween(main, {
            Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset, 0, math.min(main.Size.Y.Offset, 190)),
            Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset, 0, 6),
        }, 0.28, Enum.EasingStyle.Quint)
    end

    editor.Focused:Connect(function()
        enterTypingMode()
        tween(editorStroke, {Color = theme.accent, Transparency = 0.2}, 0.2)
    end)
    editor.FocusLost:Connect(function()
        tween(editorStroke, {Color = theme.panel2, Transparency = 0.2}, 0.25)
    end)
end

-- ================================================================
-- PART 15: THE SEARCH TAB
-- Type a word and it finds matching features and scripts.
-- ================================================================
do
    local searchPage = pages["Search"]
    local searchBox = inputBox(searchPage, "Search features and scripts", "")
    searchBox.Focused:Connect(enterTypingMode) -- move the window up when typing

    -- The area under the search box where results appear.
    local resHost = make("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 34),
        Size = UDim2.new(1, 0, 1, -34),
    }, searchPage)
    local resScroll = scroll(resHost)

    -- addResult: adds one result button to the list.
    local function addResult(text, color, callback)
        local b = button(resScroll, text, callback, color or theme.panel2, 27)
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextTruncate = Enum.TextTruncate.AtEnd
        make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, b)
        return b
    end

    -- rebuildSearch: throws away the old results and makes new ones.
    -- It runs again every time you type a letter.
    local function rebuildSearch()
        -- Remove all the old result buttons.
        for _, c in ipairs(resScroll:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
        -- Read what you typed (lowercase, with spaces trimmed off both ends).
        local q = searchBox.Text:lower():match("^%s*(.-)%s*$")
        if q == "" then return end -- nothing typed = nothing to show

        local count = 0 -- how many results we found

        -- Look through the features list.
        for _, f in ipairs(FEATURES) do
            -- find(q, 1, true) checks "does this text contain what you typed?"
            if f.name:lower():find(q, 1, true) or f.keys:find(q, 1, true) then
                count += 1
                addResult(f.name .. "  ›  " .. f.tab, theme.panel2, function()
                    showPage(f.tab) -- jump to that tab
                end)
            end
        end

        -- Look through the script lists too. These get a Run button.
        local groups = {{"Games", GAMES}, {"Tools", TOOLS}, {"Script Hubs", HUBS}}
        for _, g in ipairs(groups) do
            for _, entry in ipairs(g[2]) do
                if entry.name:lower():find(q, 1, true) then
                    count += 1
                    addResult("▶ Run  " .. entry.name .. "  (" .. g[1] .. ")", theme.accent, function()
                        runRemote(entry, function() end)
                    end)
                end
            end
        end

        if count == 0 then
            label(resScroll, "No matches for \"" .. q .. "\".", 11, theme.muted)
        end
    end

    -- Run rebuildSearch every time the text changes.
    searchBox:GetPropertyChangedSignal("Text"):Connect(rebuildSearch)
    rebuildSearch()
end

-- ================================================================
-- PART 16: THE PLAYER TAB
-- Walk speed, jump power, flying, and the camera.
-- ================================================================
do
    local movementScroll = scroll(pages["Player"])

    -- ---------- WALK SPEED ----------
    local speedCard = section(movementScroll, "Walk Speed")
    speedValueLabel = label(speedCard, "Speed: 16", 11, theme.text, true)

    speedInput = inputBox(speedCard, "Walk speed (0 to 999999)", tostring(DEFAULT_SPEED))

    -- updateSpeed: sets a new speed (kept between 0 and 100).
    local function updateSpeed(value)
        currentSpeed = math.clamp(value, SPEED_MIN, SPEED_MAX)
        speedInput.Text = tostring(currentSpeed)
        speedValueLabel.Text = "Speed: " .. currentSpeed
        if not freecam.on then applyMovement() end -- don't move the character during free camera
        if addLog then addLog("Changed walk speed to " .. currentSpeed) end
    end
    api.setSpeed = updateSpeed -- save it in "api" so chat commands can use it

    local speedButtons = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
    }, speedCard)

    local speedMinus = button(speedButtons, "− 5", function() updateSpeed(currentSpeed - 5) end)
    speedMinus.Size = UDim2.new(0.48, 0, 1, 0)
    local speedPlus = button(speedButtons, "+ 5", function() updateSpeed(currentSpeed + 5) end)
    speedPlus.Position = UDim2.new(0.52, 0, 0, 0)
    speedPlus.Size = UDim2.new(0.48, 0, 1, 0)

    -- When you finish typing a number, use it. If it isn't a number, put the old one back.
    speedInput.FocusLost:Connect(function()
        local v = tonumber(speedInput.Text)
        if v then updateSpeed(v) else speedInput.Text = tostring(currentSpeed) end
    end)

    -- ---------- JUMP POWER ----------
    local jumpCard = section(movementScroll, "Jump Power")
    jumpValueLabel = label(jumpCard, "Jump Power: 50", 11, theme.text, true)

    jumpInput = inputBox(jumpCard, "Jump power (0 to 999999)", tostring(DEFAULT_JUMP))

    local function updateJump(value)
        currentJump = math.clamp(value, JUMP_MIN, JUMP_MAX)
        jumpInput.Text = tostring(currentJump)
        jumpValueLabel.Text = "Jump Power: " .. currentJump
        if not freecam.on then applyMovement() end
        if addLog then addLog("Changed jump power to " .. currentJump) end
    end
    api.setJump = updateJump

    local jumpButtons = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
    }, jumpCard)

    local jumpMinus = button(jumpButtons, "− 10", function() updateJump(currentJump - 10) end)
    jumpMinus.Size = UDim2.new(0.48, 0, 1, 0)
    local jumpPlus = button(jumpButtons, "+ 10", function() updateJump(currentJump + 10) end)
    jumpPlus.Position = UDim2.new(0.52, 0, 0, 0)
    jumpPlus.Size = UDim2.new(0.48, 0, 1, 0)

    jumpInput.FocusLost:Connect(function()
        local v = tonumber(jumpInput.Text)
        if v then updateJump(v) else jumpInput.Text = tostring(currentJump) end
    end)

    -- ---------- FLIGHT ----------
    local flyCard = section(movementScroll, "Flight")

    flySpeedLabel = label(flyCard, "Flight Speed: " .. flySpeed, 11, theme.text, true)
    flySpeedInput = inputBox(flyCard, "Flight speed (0 to 999999)", tostring(flySpeed))

    flySpeedInput.FocusLost:Connect(function()
        local value = tonumber(flySpeedInput.Text)
        if value then
            flySpeed = math.clamp(value, FLY_MIN, FLY_MAX)
        end
        flySpeedInput.Text = tostring(flySpeed)
        flySpeedLabel.Text = "Flight Speed: " .. flySpeed
    end)

    -- api.setFly(true) turns flying on, api.setFly(false) turns it off.
    api.setFly = function(on)
        if on then
            if not flyEnabled then startFly() end
        else
            if flyEnabled then stopFly() end
        end
        setFlyUI(flyEnabled)
        if addLog then addLog(flyEnabled and "Turned flight on" or "Turned flight off") end
    end

    flyToggle = button(flyCard, "FLY: OFF", function()
        api.setFly(not flyEnabled) -- "not" flips on to off and off to on
    end)

    local verticalButtons = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
    }, flyCard)

    local riseButton = button(verticalButtons, "▲ Rise", function() end, theme.accent, 32)
    riseButton.Size = UDim2.new(0.48, 0, 1, 0)
    local descendButton = button(verticalButtons, "▼ Descend", function() end, theme.accent, 32)
    descendButton.Position = UDim2.new(0.52, 0, 0, 0)
    descendButton.Size = UDim2.new(0.48, 0, 1, 0)

    -- hold: runs "setter(true)" while a button is pressed down
    -- and "setter(false)" when you let go.
    local function hold(buttonObject, setter)
        buttonObject.InputBegan:Connect(function(input)
            if isPress(input) then setter(true) end
        end)
        buttonObject.InputEnded:Connect(function(input)
            if isPress(input) then setter(false) end
        end)
    end

    hold(riseButton, function(v) flyUp = v end)
    hold(descendButton, function(v) flyDown = v end)

    -- ---------- CAMERA AND VIEW ----------
    local camCard = section(movementScroll, "Camera & View")
    viewStatus = label(camCard, "Not viewing anyone.", 10, theme.muted)

    local viewBox = inputBox(camCard, "Player name to view", "")
    viewBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and viewBox.Text ~= "" then
            viewByName(viewBox.Text)
            if addLog then addLog("Viewed a player by name") end
        end
    end)

    -- Three buttons in a row: ◀ (previous), View, ▶ (next).
    local viewRow = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
    }, camCard)
    local prevBtn = button(viewRow, "◀", function() cycleView(-1) end, theme.panel2, 28)
    prevBtn.Size = UDim2.new(0.25, -3, 1, 0)
    local viewBtn = button(viewRow, "View", function()
        if viewBox.Text ~= "" then
            viewByName(viewBox.Text)
        else
            cycleView(1)
        end
    end, theme.accent, 28)
    viewBtn.Position = UDim2.new(0.25, 3, 0, 0)
    viewBtn.Size = UDim2.new(0.5, -6, 1, 0)
    local nextBtn = button(viewRow, "▶", function() cycleView(1) end, theme.panel2, 28)
    nextBtn.Position = UDim2.new(0.75, 3, 0, 0)
    nextBtn.Size = UDim2.new(0.25, -3, 1, 0)

    button(camCard, "Stop viewing", function()
        clearSpectate()
        if addLog then addLog("Stopped viewing") end
    end, theme.panel2, 26)

    -- Field of view slider (how wide the camera sees).
    local fovSlider = slider(camCard, "Field of view", 30, 120,
        math.floor((workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70) + 0.5), 0,
        function(v)
            local camera = workspace.CurrentCamera
            if camera then camera.FieldOfView = v end
        end)
    api.setFov = function(v) fovSlider.set(v) end

    -- How far away the camera is allowed to zoom.
    local zoomBox = inputBox(camCard, "Max zoom out (5 to 2000)", tostring(math.floor(LP.CameraMaxZoomDistance)))
    zoomBox.FocusLost:Connect(function()
        local v = tonumber(zoomBox.Text)
        if v then
            v = math.clamp(v, 5, 2000)
            LP.CameraMaxZoomDistance = v
            zoomBox.Text = tostring(v)
            if addLog then addLog("Set max zoom to " .. v) end
        else
            zoomBox.Text = tostring(math.floor(LP.CameraMaxZoomDistance))
        end
    end)

    -- Free camera on/off button.
    local freeBtn
    freeBtn = button(camCard, "Free camera: OFF", function()
        if freecam.on then stopFreecam() else startFreecam() end
    end, theme.panel2, 28)

    -- freecam.update is called by start/stopFreecam to refresh this button.
    freecam.update = function()
        if not freeBtn.Parent then return end
        if freecam.on then
            freeBtn.Text = "Free camera: ON"
            tween(freeBtn, {BackgroundColor3 = theme.good, TextColor3 = theme.bg}, 0.25)
        else
            freeBtn.Text = "Free camera: OFF"
            tween(freeBtn, {BackgroundColor3 = theme.panel2, TextColor3 = theme.text}, 0.25)
        end
    end

    slider(camCard, "Free camera speed", 5, 200, freecam.speed, 0, function(v)
        freecam.speed = v
    end)

    local freeRow = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
    }, camCard)
    local freeUpBtn = button(freeRow, "▲ Up", function() end, theme.panel2, 28)
    freeUpBtn.Size = UDim2.new(0.48, 0, 1, 0)
    local freeDownBtn = button(freeRow, "▼ Down", function() end, theme.panel2, 28)
    freeDownBtn.Position = UDim2.new(0.52, 0, 0, 0)
    freeDownBtn.Size = UDim2.new(0.48, 0, 1, 0)
    hold(freeUpBtn, function(v) freecam.up = v end)
    hold(freeDownBtn, function(v) freecam.down = v end)

    -- resetCamera: puts every camera thing back to normal.
    api.resetCamera = function()
        stopFreecam()
        clearSpectate()
        fovSlider.set(70)
        LP.CameraMaxZoomDistance = 128
        zoomBox.Text = "128"
        local camera = workspace.CurrentCamera
        if camera then camera.CameraType = Enum.CameraType.Custom end
        resetCameraSubject()
        if addLog then addLog("Reset camera") end
        notify("Camera reset", "good")
    end

    button(camCard, "Reset camera", function()
        api.resetCamera()
    end, theme.accent, 28)

    -- resetMovement: puts speed, jump and flight back to normal.
    api.resetMovement = function()
        stopFly()
        currentSpeed, currentJump = DEFAULT_SPEED, DEFAULT_JUMP
        flySpeed = 60
        speedInput.Text = tostring(currentSpeed)
        jumpInput.Text = tostring(currentJump)
        flySpeedInput.Text = tostring(flySpeed)
        speedValueLabel.Text = "Speed: " .. currentSpeed
        jumpValueLabel.Text = "Jump Power: " .. currentJump
        flySpeedLabel.Text = "Flight Speed: " .. flySpeed
        setFlyUI(false)
        if not freecam.on then applyMovement() end
        if addLog then addLog("Reset movement settings") end
    end

    -- LayoutOrder 99 puts this button at the very bottom of the page.
    local resetButton = button(movementScroll, "RESET MOVEMENT", function()
        api.resetMovement()
    end, theme.danger)
    resetButton.LayoutOrder = 99
end

-- ================================================================
-- PART 17: THE VISUALS TAB
-- Brightness, fullbright and camera effects.
-- ================================================================
do
    local visualsScroll = scroll(pages["Visuals"])
    local lightCard = section(visualsScroll, "Lighting")

    local fbBtn, fxBtn, brightSlider

    -- refreshFb: updates the Fullbright button's words and color.
    local function refreshFb()
        fbBtn.Text = light.fullbright and "Fullbright: ON" or "Fullbright: OFF"
        tween(fbBtn, {
            BackgroundColor3 = light.fullbright and theme.good or theme.panel2,
            TextColor3 = light.fullbright and theme.bg or theme.text,
        }, 0.25)
    end

    -- refreshFx: updates the Camera effects button.
    local function refreshFx()
        fxBtn.Text = fx.on and "Camera effects: OFF" or "Camera effects: ON"
        tween(fxBtn, {
            BackgroundColor3 = fx.on and theme.good or theme.panel2,
            TextColor3 = fx.on and theme.bg or theme.text,
        }, 0.25)
    end

    api.setFullbright = function(on)
        setFullbright(on)
        refreshFb()
        notify(light.fullbright and "Fullbright on" or "Fullbright off", light.fullbright and "good" or nil)
        if addLog then addLog(light.fullbright and "Fullbright on" or "Fullbright off") end
    end

    api.setEffects = function(enabled)
        setEffectsOff(not enabled)
        refreshFx()
        notify(enabled and "Camera effects restored" or "Camera effects disabled", enabled and nil or "good")
        if addLog then addLog(enabled and "Restored camera effects" or "Disabled camera effects") end
    end

    api.setBrightness = function(v)
        brightSlider.set(v)
    end

    -- resetLighting: puts the lighting back the way the game had it at the start.
    api.resetLighting = function()
        setFullbright(false)
        light.customBrightness = nil
        updateLightLoop()
        for k, v in pairs(origLighting) do
            Lighting[k] = v
        end
        brightSlider.set(math.floor(origLighting.Brightness * 10 + 0.5) / 10, true)
        refreshFb()
        if addLog then addLog("Reset lighting") end
        notify("Lighting reset", "good")
    end

    fbBtn = button(lightCard, "Fullbright: OFF", function()
        api.setFullbright(not light.fullbright)
    end, theme.panel2, 28)

    brightSlider = slider(lightCard, "Custom brightness", 0, 10, math.floor(Lighting.Brightness * 10 + 0.5) / 10, 1, function(v)
        light.customBrightness = v
        Lighting.Brightness = v
        updateLightLoop()
    end)

    fxBtn = button(lightCard, "Camera effects: ON", function()
        api.setEffects(fx.on)
    end, theme.panel2, 28)

    button(lightCard, "Reset lighting", function()
        api.resetLighting()
    end, theme.accent, 28)

    -- Local visual profiles use Roblox's built-in post-processing effects.
    -- They do not inject or compile custom GPU shaders.
    local qualityCard = section(visualsScroll, "Visual quality profiles")
    label(qualityCard, "Color grading, bloom, sun rays, environment specular, and strong surface-finish presets. Roblox still controls true reflections and graphics quality.", 10, theme.muted)

    local visualEffects = {}
    local savedQualityLighting
    local visualProfileLabel = label(qualityCard, "Profile: Off", 10, theme.good)

    local function restoreVisualProfile()
        for _, effect in ipairs(visualEffects) do
            pcall(function() effect:Destroy() end)
        end
        table.clear(visualEffects)
        if savedQualityLighting then
            for property, value in pairs(savedQualityLighting) do
                pcall(function() Lighting[property] = value end)
            end
            savedQualityLighting = nil
        end
        visualProfileLabel.Text = "Profile: Off"
    end

    local function setVisualProfile(profileName)
        restoreVisualProfile()
        if profileName == "Off" then
            notify("Visual profile reset.", "good")
            return
        end

        savedQualityLighting = {
            GlobalShadows = Lighting.GlobalShadows,
            ShadowSoftness = Lighting.ShadowSoftness,
            EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        }

        -- These are the highest-quality shadow settings normal scripts can request.
        -- Roblox's device graphics slider still controls the actual shadow budget/resolution.
        pcall(function()
            Lighting.GlobalShadows = true
            Lighting.ShadowSoftness = 0.18
            Lighting.EnvironmentDiffuseScale = 1
            Lighting.EnvironmentSpecularScale = 1
        end)

        local profiles = {
            ["Vibrant"] = {
                saturation = 0.48, contrast = 0.22, brightness = 0.01,
                tint = Color3.fromRGB(255, 225, 205),
                bloom = 0.42, bloomSize = 30, rays = 0.10, spread = 0.78,
            },
            ["Cinematic"] = {
                saturation = 0.18, contrast = 0.24, brightness = 0.0,
                tint = Color3.fromRGB(255, 238, 220),
                bloom = 0.22, bloomSize = 24, rays = 0.07, spread = 0.72,
            },
            ["Realistic"] = {
                saturation = 0.06, contrast = 0.1, brightness = 0,
                tint = Color3.fromRGB(238, 246, 255),
                bloom = 0.1, bloomSize = 18, rays = 0.035, spread = 0.65,
            },
            ["Neon"] = {
                saturation = 0.55, contrast = 0.25, brightness = 0.005,
                tint = Color3.fromRGB(216, 225, 255),
                bloom = 0.48, bloomSize = 34, rays = 0.025, spread = 0.6,
            },
            ["Warm Sunset"] = {
                saturation = 0.24, contrast = 0.12, brightness = 0.01,
                tint = Color3.fromRGB(255, 208, 168),
                bloom = 0.2, bloomSize = 26, rays = 0.1, spread = 0.82,
            },
        }
        local config = profiles[profileName]
        if not config then return end

        local color = Instance.new("ColorCorrectionEffect")
        color.Name = "MOCHI_LocalColorProfile"
        color.Saturation = config.saturation
        color.Contrast = config.contrast
        color.Brightness = config.brightness
        color.TintColor = config.tint
        color.Parent = Lighting
        visualEffects[#visualEffects + 1] = color

        local bloom = Instance.new("BloomEffect")
        bloom.Name = "MOCHI_LocalBloomProfile"
        bloom.Intensity = config.bloom
        bloom.Size = config.bloomSize
        bloom.Threshold = 1.1
        bloom.Parent = Lighting
        visualEffects[#visualEffects + 1] = bloom

        local rays = Instance.new("SunRaysEffect")
        rays.Name = "MOCHI_LocalSunRaysProfile"
        rays.Intensity = config.rays
        rays.Spread = config.spread
        rays.Parent = Lighting
        visualEffects[#visualEffects + 1] = rays

        -- If the profile is changed while Performance Mode is on, retain the low-detail state.
        if performanceMode then
            color.Enabled = false
            bloom.Enabled = false
            rays.Enabled = false
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.EnvironmentDiffuseScale = 0.25
                Lighting.EnvironmentSpecularScale = 0
            end)
        end

        visualProfileLabel.Text = "Profile: " .. profileName
        notify(profileName .. " visual profile enabled.", "good")
    end

    button(qualityCard, "Vibrant (bright colors)", function() setVisualProfile("Vibrant") end, theme.panel2, 28)
    button(qualityCard, "Cinematic (warm film look)", function() setVisualProfile("Cinematic") end, theme.panel2, 28)
    button(qualityCard, "Realistic (balanced)", function() setVisualProfile("Realistic") end, theme.panel2, 28)
    button(qualityCard, "Neon (glow)", function() setVisualProfile("Neon") end, theme.panel2, 28)
    button(qualityCard, "Warm Sunset", function() setVisualProfile("Warm Sunset") end, theme.panel2, 28)

    -- Strong surface-finish presets. Reflectance is pushed much harder than the prior version.
    -- Roblox controls actual environment reflections; these settings make the strongest local look it allows.
    local surfaceLightingSaved = nil
    local surfaceMode = "Off"
    local surfaceSaved = {}
    local surfaceConn = nil
    local surfaceModeLabel = label(qualityCard, "Surface finish: Off", 10, theme.good)

    local function applySurfaceToPart(obj, mode)
        if not obj or not obj:IsA("BasePart") or obj.Transparency >= 1 then return end
        if not surfaceSaved[obj] then
            local okRead, original = pcall(function()
                return {Material = obj.Material, Reflectance = obj.Reflectance}
            end)
            if okRead and original then surfaceSaved[obj] = original end
        end
        pcall(function()
            if mode == "Glossy" then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0.48
            elseif mode == "Ultra Gloss" then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0.82
            elseif mode == "Chrome" then
                obj.Material = Enum.Material.Metal
                obj.Reflectance = 0.72
            end
        end)
    end

    local function restoreSurfaceParts()
        for obj, original in pairs(surfaceSaved) do
            if obj and obj.Parent then
                pcall(function()
                    obj.Material = original.Material
                    obj.Reflectance = original.Reflectance
                end)
            end
        end
        table.clear(surfaceSaved)
    end

    local function setSurfaceMode(mode)
        if mode == surfaceMode then mode = "Off" end
        if surfaceConn then surfaceConn:Disconnect(); surfaceConn = nil end
        restoreSurfaceParts()
        surfaceMode = mode
        if mode ~= "Off" then
            if not surfaceLightingSaved then
                surfaceLightingSaved = {
                    Diffuse = Lighting.EnvironmentDiffuseScale,
                    Specular = Lighting.EnvironmentSpecularScale,
                }
            end
            pcall(function()
                Lighting.EnvironmentDiffuseScale = 1
                Lighting.EnvironmentSpecularScale = 1
            end)
            local descendants = workspace:GetDescendants()
            for index, obj in ipairs(descendants) do
                applySurfaceToPart(obj, mode)
                if index % 300 == 0 then task.wait() end
            end
            -- Apply the current finish to newly spawned geometry too.
            surfaceConn = workspace.DescendantAdded:Connect(function(obj)
                task.defer(function()
                    if surfaceMode ~= "Off" and obj.Parent then applySurfaceToPart(obj, surfaceMode) end
                end)
            end)
            surfaceModeLabel.Text = "Surface finish: " .. mode
            surfaceModeLabel.TextColor3 = theme.good
            notify(mode .. " enabled. Shine depends on Roblox's reflection support and the game sky.", "good")
        else
            if surfaceLightingSaved then
                pcall(function()
                    Lighting.EnvironmentDiffuseScale = surfaceLightingSaved.Diffuse
                    Lighting.EnvironmentSpecularScale = surfaceLightingSaved.Specular
                end)
                surfaceLightingSaved = nil
            end
            surfaceModeLabel.Text = "Surface finish: Off"
            surfaceModeLabel.TextColor3 = theme.muted
            notify("Original surface materials and reflectance restored.", "good")
        end
    end

    button(qualityCard, "Glossy plastic · reflective", function() setSurfaceMode("Glossy") end, theme.panel2, 28)
    button(qualityCard, "ULTRA GLOSS · high shine", function() setSurfaceMode("Ultra Gloss") end, theme.accent, 28)
    button(qualityCard, "Chrome world · metallic", function() setSurfaceMode("Chrome") end, theme.panel2, 28)
    button(qualityCard, "Turn surface finish off", function()
        if surfaceMode ~= "Off" then setSurfaceMode("Off") end
    end, theme.panel2, 28)
    label(qualityCard, "Ultra Gloss applies 82% reflectance; Chrome adds Metal material with strong reflectance. True mirror reflections are still limited by Roblox's renderer.", 10, theme.muted)
    button(qualityCard, "Restore original visuals", function()
        restoreVisualProfile()
        if surfaceMode ~= "Off" then setSurfaceMode("Off") end
        notify("Original visual settings restored.", "good")
    end, theme.accent, 28)
end

-- ================================================================
-- PART 18: THE ACTIVITY TAB
-- A list that writes down everything you do in MOCHI.
-- ================================================================
do
    activityScroll = scroll(pages["Activity"])

    -- The button that turns pop-up messages on and off.
    local notifBtn
    notifBtn = button(activityScroll, "Notifications: ON", function()
        notifEnabled = not notifEnabled
        notifBtn.Text = notifEnabled and "Notifications: ON" or "Notifications: OFF"
        tween(notifBtn, {
            BackgroundColor3 = notifEnabled and theme.accent or theme.panel2,
            TextColor3 = notifEnabled and theme.bg or theme.text,
        }, 0.25)
        if notifEnabled then notify("Notifications on", "good") end
    end, theme.accent, 26)
    notifBtn.LayoutOrder = -3 -- a small number puts it at the very top

    -- addLog: adds one new line (with the time) to the list.
    addLog = function(text)
        if not activityScroll or not activityScroll.Parent then return end
        label(activityScroll, os.date("%H:%M:%S") .. "  •  " .. text, 10, theme.muted)
    end
end

-- ================================================================
-- PART 19: MOCHI BUDDY
-- A little pet that follows you, talks, dances, hugs, and can be
-- thrown like a ball. This part is the longest, so it is split into
-- small steps.
-- ================================================================
do
    -- Everything we need to remember about the buddy lives in this box.
    --   state can be:
    --     "none"   = he isn't out
    --     "follow" = walking behind you
    --     "hug"    = running over to hug you
    --     "piggy"  = riding on your back
    --     "pocket" = hiding in your hotbar as a tool
    --     "ball"   = flying through the air after you threw him
    local buddy = {
        rig = nil, motors = nil, tag = nil, tool = nil, bubble = nil,
        state = "none",
        pos = Vector3.zero, face = Vector3.new(0, 0, -1),
        phase = 0, walk = 0, moving = false, hugEnd = nil,
        ang = {rs = 0, ls = 0, rh = 0, lh = 0}, -- arm and leg angles (rs = right shoulder, etc.)
        conn = nil, token = 0,
        ball = nil, vel = Vector3.zero, bounced = false, flightStart = 0,
        dance = false, emote = nil, sayUntil = 0, nextFact = 0,
    }
    local menu = {open = false} -- the little pop-up menu you get when you tap him
    local refreshMenu
    local hugBuddy, piggyToggle, pocketBuddy, giveTool, spawnBuddy
    local danceBtn, chatBtn
    local mouse = LP:GetMouse() -- lets us know where you tapped in the world

    -- ---------- THE BUDDY'S POP-UP MENU ----------
    local menuBox = section(gui, "Mochi Buddy")
    menuBox.Size = UDim2.new(0, 190, 0, 36)
    menuBox.AnchorPoint = Vector2.new(0.5, 1)
    menuBox.Position = UDim2.new(0.5, 0, 1, -90)
    menuBox.Visible = false
    menuBox.ZIndex = 5
    menu.frame = menuBox
    local menuScale = make("UIScale", {Scale = 1}, menuBox)

    menu.hug = button(menuBox, "Hug", function() hugBuddy() end, theme.accent, 28)
    menu.piggy = button(menuBox, "Piggyback ride", function() piggyToggle() end, theme.panel2, 28)
    menu.pocket = button(menuBox, "Put in inventory", function() pocketBuddy() end, theme.panel2, 28)
    menu.close = button(menuBox, "Close", function()
        menu.open = false
        refreshMenu()
    end, theme.panel2, 24)

    -- refreshMenu: shows or hides the menu, and only shows the buttons that make sense right now.
    refreshMenu = function()
        local s = buddy.state
        local show = menu.open and (s == "follow" or s == "hug" or s == "piggy")
        if show and not menu.frame.Visible then
            menuScale.Scale = 0.85
            menu.frame.Visible = true
            tween(menuScale, {Scale = 1}, 0.3, Enum.EasingStyle.Back) -- pop open
        else
            menu.frame.Visible = show
        end
        menu.hug.Visible = s == "follow"
        menu.piggy.Visible = s == "follow" or s == "piggy"
        menu.piggy.Text = s == "piggy" and "Get down" or "Piggyback ride"
        menu.pocket.Visible = s == "follow" or s == "piggy"
    end

    function openMenu()
        local s = buddy.state
        if s ~= "follow" and s ~= "hug" and s ~= "piggy" then return end
        menu.open = true
        refreshMenu()
    end

    -- Small cleanup recipes.
    function destroyBall()
        if buddy.ball then buddy.ball:Destroy(); buddy.ball = nil end
    end

    function destroyTool()
        if buddy.tool then buddy.tool:Destroy(); buddy.tool = nil end
    end

    -- setDance: turns the dance on or off and updates the Dance button.
    function setDance(on)
        buddy.dance = on
        if danceBtn and danceBtn.Parent then
            danceBtn.Text = on and "Dance: ON" or "Dance: OFF"
            tween(danceBtn, {
                BackgroundColor3 = on and theme.good or theme.panel2,
                TextColor3 = on and theme.bg or theme.text,
            }, 0.25)
        end
    end

    -- deleteBuddy: removes the buddy completely.
    deleteBuddy = function()
        buddy.token += 1 -- changing this number tells the fact-talking loop to stop
        if buddy.conn then
            buddy.conn:Disconnect()
            buddy.conn = nil
        end
        if buddy.rig then buddy.rig:Destroy(); buddy.rig = nil end
        if buddy.tag then buddy.tag:Destroy(); buddy.tag = nil end
        buddy.bubble = nil
        destroyBall()
        destroyTool()
        buddy.state = "none"
        buddy.motors = nil
        buddy.emote = nil
        setDance(false)
        menu.open = false
        refreshMenu()
    end

    -- ---------- BUILDING THE BUDDY'S BODY ----------
    -- buildBuddyRig: makes a body out of blocks (like a Roblox character):
    -- a torso, a head, two arms, two legs, and joints to connect them.
    function buildBuddyRig()
        local m = Instance.new("Model")
        m.Name = "MochiBuddy"

        -- part: makes one green block.
        local function part(name, size)
            return make("Part", {
                Name = name,
                Size = size,
                Color = theme.accent,
                Material = Enum.Material.SmoothPlastic,
                CanCollide = false, -- you can walk through him
                CanTouch = false,
                Massless = true,
                TopSurface = Enum.SurfaceType.Smooth,
                BottomSurface = Enum.SurfaceType.Smooth,
            }, m)
        end

        local rootPart = part("HumanoidRootPart", Vector3.new(2, 2, 1))
        rootPart.Transparency = 1 -- invisible
        rootPart.Anchored = true  -- stays where we put it
        local torso = part("Torso", Vector3.new(2, 2, 1))
        local head = part("Head", Vector3.new(2, 1, 1))
        make("SpecialMesh", {MeshType = Enum.MeshType.Head, Scale = Vector3.new(1.25, 1.25, 1.25)}, head)
        make("Decal", {Name = "face", Texture = "rbxasset://textures/face.png", Face = Enum.NormalId.Front}, head)
        local leftArm = part("Left Arm", Vector3.new(1, 2, 1))
        local rightArm = part("Right Arm", Vector3.new(1, 2, 1))
        local leftLeg = part("Left Leg", Vector3.new(1, 2, 1))
        local rightLeg = part("Right Leg", Vector3.new(1, 2, 1))

        -- joint: glues two blocks together so one can swing on the other.
        local function joint(name, p0, p1, c0, c1)
            return make("Motor6D", {Name = name, Part0 = p0, Part1 = p1, C0 = c0, C1 = c1}, p0)
        end

        local rootCF = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
        joint("RootJoint", rootPart, torso, rootCF, rootCF)
        joint("Neck", torso, head,
            CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
            CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0))

        -- The four joints we wiggle to make him walk and dance.
        local motors = {
            rs = joint("Right Shoulder", torso, rightArm,
                CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
                CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)),
            ls = joint("Left Shoulder", torso, leftArm,
                CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
                CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)),
            rh = joint("Right Hip", torso, rightLeg,
                CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
                CFrame.new(0.5, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0)),
            lh = joint("Left Hip", torso, leftLeg,
                CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
                CFrame.new(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)),
        }

        m.PrimaryPart = rootPart
        return {model = m, root = rootPart, torso = torso, head = head, motors = motors}
    end

    -- ballRayParams: a list of things the thrown ball should NOT bump into
    -- (you, the buddy, and the ball itself).
    function ballRayParams()
        local p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Exclude
        p.RespectCanCollide = true
        local list = {}
        if LP.Character then list[#list + 1] = LP.Character end
        if buddy.rig then list[#list + 1] = buddy.rig end
        if buddy.ball then list[#list + 1] = buddy.ball end
        if invis.clone then list[#list + 1] = invis.clone end
        p.FilterDescendantsInstances = list
        return p
    end

    -- ---------- THE BUDDY TALKS ----------
    -- buddySay: puts words in his speech bubble. Returns true if he was able to say it.
    function buddySay(text, duration)
        local s = buddy.state
        if buddy.bubble and buddy.bubble.Parent and s ~= "none" and s ~= "pocket" and s ~= "ball" then
            buddy.bubble.Text = text
            buddy.sayUntil = os.clock() + (duration or 7)    -- how long to keep these words
            buddy.nextFact = buddy.sayUntil + 1              -- wait a moment before the next fun fact
            return true
        end
        return false
    end

    -- say: the buddy says it. If he isn't out, show it as a pop-up instead.
    function say(text, duration)
        if not buddySay(text, duration) then
            notify(text)
        end
        if addLog then addLog("Mochi Buddy: " .. text) end
    end

    -- landBall: the thrown ball has landed, so the buddy "hatches" out of it.
    function landBall(position)
        destroyBall()
        destroyTool()
        if not buddy.rig then
            buddy.state = "none"
            return
        end
        buddy.pos = position + Vector3.new(0, 2, 0)
        buddy.moving = false
        buddy.walk = 0
        buddy.rig:PivotTo(CFrame.new(buddy.pos))
        buddy.rig.Parent = workspace
        if buddy.tag then buddy.tag.Enabled = true end
        buddy.state = "follow"
        menu.open = false
        refreshMenu()
        notify("Mochi Buddy hatched!", "good")
        if addLog then addLog("Mochi Buddy hatched from the ball") end
    end

    -- ---------- THE BUDDY'S BRAIN ----------
    -- stepBuddy runs every single frame (dt = how many seconds passed since the last frame).
    -- It decides where he walks, which way he faces, and how his arms and legs move.
    function stepBuddy(dt)
        local s = buddy.state
        if s == "none" or s == "pocket" then return end -- nothing to do

        -- When he is a flying ball: gravity pulls it down, and it bounces once.
        if s == "ball" then
            local b = buddy.ball
            if not b then return end
            buddy.vel += Vector3.new(0, -100 * dt, 0) -- gravity
            local stepVec = buddy.vel * dt
            if stepVec.Magnitude > 0.0001 then
                -- Look ahead: will the ball hit something this frame?
                local hit = workspace:Raycast(b.Position, stepVec + stepVec.Unit * 0.9, ballRayParams())
                if hit then
                    local n = hit.Normal
                    b.Position = hit.Position + n * 0.9
                    if not buddy.bounced then
                        -- First hit: bounce!
                        buddy.bounced = true
                        local v = buddy.vel
                        v = (v - 2 * v:Dot(n) * n) * 0.45
                        if n.Y > 0.5 and v.Y < 14 then
                            v = Vector3.new(v.X, 14, v.Z)
                        end
                        buddy.vel = v
                    else
                        -- Second hit: hatch.
                        landBall(b.Position)
                        return
                    end
                else
                    b.Position += stepVec
                end
            end
            -- If the ball has been flying for 8 seconds, hatch anyway.
            if os.clock() - buddy.flightStart > 8 then
                landBall(b.Position)
            end
            return
        end

        -- Everything below is for follow / hug / piggy.
        -- He follows you (or your invisible copy, if you are invisible).
        local followChar = (invis.on and invis.clone) or LP.Character
        local proot = followChar and followChar:FindFirstChild("HumanoidRootPart")
        if not proot then return end

        local rig = buddy.rig
        if not rig or not rig.Parent or not buddy.motors then return end

        local now = os.clock()
        -- tAng = the arm/leg angles we WANT this frame ("target angles").
        local tAng = {rs = 0, ls = 0, rh = 0, lh = 0}

        if s == "piggy" then
            -- Sit on your back and gently bob.
            local cf = proot.CFrame * CFrame.new(0, 0.8 + math.sin(now * 3) * 0.04, 1.1)
            rig:PivotTo(cf)
            buddy.pos = cf.Position
            buddy.walk = 0
            tAng = {rs = 1.35, ls = -1.35, rh = 0.45, lh = -0.45}
        else
            -- Pick a spot to walk to: in front of you for a hug, or beside you otherwise.
            local target
            local startDist, stopDist, maxSpeed
            if s == "hug" then
                target = (proot.CFrame * CFrame.new(0, 0, -1.5)).Position
                startDist, stopDist, maxSpeed = 0.35, 0.1, 24
            else
                target = (proot.CFrame * CFrame.new(3.5, 0, 3)).Position
                startDist, stopDist, maxSpeed = 2.2, 1.0, 20
            end

            -- "to" = the flat arrow from him to the spot. "dist" = how long that arrow is.
            local to = Vector3.new(target.X - buddy.pos.X, 0, target.Z - buddy.pos.Z)
            local dist = to.Magnitude

            -- If he is REALLY far away (70+ studs), teleport him next to you.
            if dist > 70 then
                buddy.pos = Vector3.new(target.X, buddy.pos.Y, target.Z)
                dist = 0
                buddy.moving = false
            end

            -- Start walking when you get far enough, and stop when he is close enough.
            if buddy.moving then
                if dist < stopDist then buddy.moving = false end
            else
                if dist > startDist then buddy.moving = true end
            end

            -- Walk toward the spot (faster when farther away).
            if buddy.moving and dist > 0.001 then
                local speed = math.clamp(dist * 3, 6, maxSpeed)
                buddy.pos += to.Unit * math.min(dist, speed * dt)
            end

            -- Stay standing on the ground: shoot an invisible line down to find it.
            local origin = Vector3.new(buddy.pos.X, proot.Position.Y + 2, buddy.pos.Z)
            local hit = workspace:Raycast(origin, Vector3.new(0, -40, 0), ballRayParams())
            local groundY = hit and hit.Position.Y or (proot.Position.Y - 3)
            local newY = buddy.pos.Y + ((groundY + 3) - buddy.pos.Y) * math.min(1, dt * 15)
            buddy.pos = Vector3.new(buddy.pos.X, newY, buddy.pos.Z)

            -- Turn to face where he is walking, or face you when standing still.
            local want
            if buddy.moving and to.Magnitude > 0.001 then
                want = to.Unit
            else
                local toPlayer = Vector3.new(proot.Position.X - buddy.pos.X, 0, proot.Position.Z - buddy.pos.Z)
                want = toPlayer.Magnitude > 0.01 and toPlayer.Unit or buddy.face
            end
            local blended = buddy.face:Lerp(want, math.min(1, dt * 10)) -- turn smoothly, not instantly
            if blended.Magnitude > 0.01 then buddy.face = blended.Unit end

            -- Swing arms and legs like walking (a sine wave goes back and forth smoothly).
            buddy.walk += ((buddy.moving and 1 or 0) - buddy.walk) * math.min(1, dt * 8)
            buddy.phase += dt * 10
            local swing = math.sin(buddy.phase) * 0.9 * buddy.walk
            tAng = {rs = swing, ls = swing, rh = -swing, lh = -swing}

            -- extraYaw = extra spinning, extraY = extra hopping up.
            local extraYaw, extraY = 0, 0

            -- Emotes and dancing only happen while he is standing still.
            if s == "follow" and not buddy.moving then
                if buddy.emote and now > buddy.emote.untilT then buddy.emote = nil end
                local e = buddy.emote and buddy.emote.name or (buddy.dance and "dance" or nil)
                if e == "dance" then
                    -- Three dance moves. He switches every 3 seconds.
                    local move = math.floor(now / 3) % 3
                    local w = now * 7
                    local sw = math.sin(w)
                    if move == 0 then
                        -- Move 1: pump arms and bounce.
                        tAng = {rs = 1.6 + sw * 1.2, ls = -(1.6 - sw * 1.2), rh = sw * 0.6, lh = -sw * 0.6}
                        extraY = math.abs(sw) * 0.8
                    elseif move == 1 then
                        -- Move 2: hands up and spin.
                        tAng = {rs = 2.8, ls = -2.8, rh = math.sin(w * 1.5) * 0.5, lh = -math.sin(w * 1.5) * 0.5}
                        extraYaw = now * 6
                    else
                        -- Move 3: wiggle.
                        local s2 = math.sin(w * 2)
                        tAng = {rs = 1.5 + s2 * 0.8, ls = -1.5 - s2 * 0.8, rh = s2 * 0.4, lh = -s2 * 0.4}
                        extraYaw = sw * 0.5
                        extraY = math.abs(s2) * 0.5
                    end
                elseif e == "wave" then
                    tAng = {rs = 2.7 + math.sin(now * 10) * 0.4, ls = 0, rh = 0, lh = 0}
                elseif e == "spin" then
                    tAng = {rs = 1.2, ls = -1.2, rh = 0, lh = 0}
                    extraYaw = (now - buddy.emote.startT) * 12
                end
            end

            -- Hug: hold arms out for 3 seconds, then go back to following.
            if s == "hug" and not buddy.moving then
                tAng = {rs = 1.5, ls = -1.5, rh = 0, lh = 0}
                if not buddy.hugEnd then
                    buddy.hugEnd = now + 3
                elseif now > buddy.hugEnd then
                    buddy.hugEnd = nil
                    buddy.state = "follow"
                    refreshMenu()
                end
            end

            rig:PivotTo(CFrame.lookAt(buddy.pos, buddy.pos + buddy.face) * CFrame.Angles(0, extraYaw, 0) + Vector3.new(0, extraY, 0))
        end

        -- Move the real arm/leg angles a little bit toward the wanted angles.
        -- That makes the movement smooth instead of jumpy.
        local k = math.min(1, dt * 12)
        local a = buddy.ang
        a.rs += (tAng.rs - a.rs) * k
        a.ls += (tAng.ls - a.ls) * k
        a.rh += (tAng.rh - a.rh) * k
        a.lh += (tAng.lh - a.lh) * k
        local m = buddy.motors
        m.rs.Transform = CFrame.Angles(0, 0, a.rs)
        m.ls.Transform = CFrame.Angles(0, 0, a.ls)
        m.rh.Transform = CFrame.Angles(0, 0, a.rh)
        m.lh.Transform = CFrame.Angles(0, 0, a.lh)
    end

    -- ---------- THROWING THE BUDDY ----------
    -- throwTool: turns the hotbar tool into a flying ball aimed at "target".
    function throwTool(target)
        if buddy.state ~= "pocket" then return end
        local tool = buddy.tool
        local handle = tool and tool:FindFirstChild("Handle")
        local proot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local origin = (handle and handle.Position) or (proot and proot.Position + Vector3.new(0, 1, 0))
        if not origin then return end

        -- Aim a little above the spot you tapped. Don't throw farther than 140 studs.
        local aim = target + Vector3.new(0, 0.9, 0)
        local d = aim - origin
        if d.Magnitude > 140 then
            aim = origin + d.Unit * 140
            d = aim - origin
        end
        if d.Magnitude < 2 then
            aim = origin + (proot and proot.CFrame.LookVector * 6 or Vector3.new(0, 0, -6))
            d = aim - origin
        end

        -- T = how long the throw takes. We work out the starting speed so it lands on the target.
        local T = math.clamp(d.Magnitude / 50, 0.45, 1.6)
        buddy.vel = d / T + Vector3.new(0, 50 * T, 0)

        destroyBall()
        buddy.ball = make("Part", {
            Name = "MochiBall",
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(1.8, 1.8, 1.8),
            Color = theme.accent,
            Material = Enum.Material.SmoothPlastic,
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            Position = origin,
        }, workspace)
        make("PointLight", {Color = theme.accent, Range = 8, Brightness = 1}, buddy.ball)

        buddy.state = "ball"
        buddy.bounced = false
        buddy.flightStart = os.clock()
        if tool then tool.Parent = nil end -- take the tool out of the hotbar
        if addLog then addLog("Threw Mochi Buddy") end
    end

    -- giveTool: makes the "Mochi Buddy" tool and puts it in your hotbar.
    giveTool = function()
        destroyTool()
        local tool = make("Tool", {
            Name = "Mochi Buddy",
            ToolTip = "Equip, then tap where to throw",
            RequiresHandle = true,
            CanBeDropped = false,
        }, nil)
        local handle = make("Part", {
            Name = "Handle",
            Shape = Enum.PartType.Ball,
            Size = Vector3.new(1.5, 1.5, 1.5),
            Color = theme.accent,
            Material = Enum.Material.SmoothPlastic,
            CanCollide = false,
            Massless = true,
        }, tool)
        make("PointLight", {Color = theme.accent, Range = 6, Brightness = 0.8}, handle)

        tool.Equipped:Connect(function()
            notify("Mochi Buddy equipped. Tap where to throw him.", "good")
        end)
        -- Activated = you tapped while holding the tool.
        tool.Activated:Connect(function()
            local hitPos = mouse.Hit and mouse.Hit.Position
            if hitPos then throwTool(hitPos) end
        end)

        buddy.tool = tool
        local backpack = LP:FindFirstChildOfClass("Backpack") or LP:WaitForChild("Backpack", 5)
        if backpack then tool.Parent = backpack end
    end

    -- If you respawn while he is in your hotbar, give the tool back (respawning empties the hotbar).
    track(LP.CharacterAdded:Connect(function()
        if buddy.state == "pocket" then
            task.wait(0.6)
            if buddy.state == "pocket" then giveTool() end
        end
    end))

    -- ---------- SPAWNING THE BUDDY ----------
    spawnBuddy = function()
        if buddy.state == "pocket" then
            notify("He's in your hotbar. Equip Mochi Buddy and tap where to throw.")
            return
        end
        if buddy.state ~= "none" then
            notify("Mochi Buddy is already out.")
            return
        end
        local pr = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not pr then
            notify("Your character isn't ready yet.", "error")
            return
        end

        local built = buildBuddyRig()
        local rig, head, torso = built.model, built.head, built.torso
        buddy.rig = rig
        buddy.motors = built.motors
        buddy.ang = {rs = 0, ls = 0, rh = 0, lh = 0}
        buddy.walk, buddy.phase, buddy.moving, buddy.hugEnd = 0, 0, false, nil
        buddy.face = Vector3.new(0, 0, -1)
        buddy.emote = nil
        buddy.sayUntil, buddy.nextFact = 0, 0

        -- The speech bubble that floats above his head.
        local tag = make("BillboardGui", {
            Name = "MOCHI_BuddyTag",
            Adornee = head,
            Size = UDim2.fromOffset(210, 80),
            StudsOffset = Vector3.new(0, 2.6, 0),
            AlwaysOnTop = true,
            MaxDistance = 120,
        }, PG)
        local bubble = make("Frame", {
            BackgroundColor3 = theme.bg,
            BackgroundTransparency = 0.12,
            Size = UDim2.new(1, 0, 1, 0),
        }, tag)
        round(bubble, 10)
        outline(bubble, theme.accent, 1, 0.3)
        make("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
        }, bubble)
        make("TextLabel", {
            BackgroundTransparency = 1,
            Text = "Mochi Buddy",
            TextColor3 = theme.accent,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            Size = UDim2.new(1, 0, 0, 16),
        }, bubble)
        -- factText = the words he says. TextScaled shrinks the words to fit the bubble.
        local factText = make("TextLabel", {
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = theme.text,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextScaled = true,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Top,
            Position = UDim2.new(0, 0, 0, 18),
            Size = UDim2.new(1, 0, 1, -18),
        }, bubble)
        make("UITextSizeConstraint", {MaxTextSize = 11, MinTextSize = 6}, factText)
        -- An invisible button over the bubble: tap it to open his menu.
        local tapArea = make("TextButton", {
            Text = "",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
        }, bubble)
        tapArea.Activated:Connect(openMenu)
        buddy.tag = tag
        buddy.bubble = factText

        -- You can also click his body to open the menu.
        make("ClickDetector", {MaxActivationDistance = 80}, torso).MouseClick:Connect(openMenu)

        buddy.pos = (pr.CFrame * CFrame.new(3.5, 0, 3)).Position
        rig:PivotTo(CFrame.new(buddy.pos))
        rig.Parent = workspace
        buddy.state = "follow"
        buddy.token += 1
        local myToken = buddy.token -- remember our number so the loop knows when it should stop

        -- Run stepBuddy (his brain) every frame.
        buddy.conn = RunService.Heartbeat:Connect(stepBuddy)

        -- A side job that makes him say a random fun fact every 9 seconds.
        -- It shuffles the facts like a deck of cards, so he doesn't repeat until all are told.
        task.spawn(function()
            local order, idx = {}, 0
            while buddy.token == myToken and gui.Parent do
                local now = os.clock()
                if now >= buddy.sayUntil and now >= buddy.nextFact then
                    if idx >= #order then
                        -- Out of facts: shuffle a fresh deck.
                        order = {}
                        for i = 1, #FACTS do order[i] = i end
                        for i = #order, 2, -1 do
                            local j = rng:NextInteger(1, i)
                            order[i], order[j] = order[j], order[i] -- swap two cards
                        end
                        idx = 0
                    end
                    idx += 1
                    factText.Text = FACTS[order[idx]]
                    buddy.nextFact = now + 9
                end
                task.wait(0.25)
            end
        end)

        refreshMenu()
        notify("Mochi Buddy spawned", "good")
        if addLog then addLog("Spawned Mochi Buddy") end
    end

    -- hugBuddy: tells him to come give you a hug.
    hugBuddy = function()
        if buddy.state ~= "follow" then return end
        buddy.state = "hug"
        buddy.hugEnd = nil
        menu.open = false
        refreshMenu()
        if addLog then addLog("Asked Mochi Buddy for a hug") end
    end

    -- piggyToggle: hop on his back, or get down.
    piggyToggle = function()
        local pr = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if buddy.state == "follow" then
            buddy.state = "piggy"
            if addLog then addLog("Started a piggyback ride") end
        elseif buddy.state == "piggy" then
            if pr then
                buddy.pos = (pr.CFrame * CFrame.new(3.5, 0, 3)).Position
            end
            buddy.moving = false
            buddy.state = "follow"
            if addLog then addLog("Ended piggyback ride") end
        end
        menu.open = false
        refreshMenu()
    end

    -- pocketBuddy: hide him and give you the throwable tool.
    pocketBuddy = function()
        if buddy.state ~= "follow" and buddy.state ~= "piggy" then return end
        buddy.state = "pocket"
        if buddy.rig then buddy.rig.Parent = nil end
        if buddy.tag then buddy.tag.Enabled = false end
        menu.open = false
        refreshMenu()
        giveTool()
        notify("Mochi Buddy is in your hotbar")
        if addLog then addLog("Put Mochi Buddy in inventory") end
    end

    -- ---------- CHAT MODE: TALKING TO THE BUDDY ----------
    -- pick: grabs one random item from a list.
    local pick = function(list)
        return list[rng:NextInteger(1, #list)]
    end

    -- Lists of things the buddy can say.
    local JOKES = {
        "Why did the mochi cross the road? To get to the other tea.",
        "What do you call cheese that isn't yours? Nacho cheese.",
        "Why don't scientists trust atoms? They make up everything.",
        "What did the ocean say to the beach? Nothing, it just waved.",
        "Why did the scarecrow win an award? He was outstanding in his field.",
        "I'm reading a book about anti-gravity. It's impossible to put down.",
        "Why did the Roblox player bring a ladder? To reach the next level.",
        "What's a ghost's favorite game? Hide and shriek.",
        "Why did the computer get cold? It left its Windows open.",
        "What do you call a fake noodle? An impasta.",
    }
    local RIDDLES = {
        {"What has hands but can't clap?", "A clock."},
        {"What gets wetter the more it dries?", "A towel."},
        {"What has a neck but no head?", "A bottle."},
        {"The more you take, the more you leave behind. What am I?", "Footsteps."},
        {"What can you catch but not throw?", "A cold."},
        {"What has keys but can't open locks?", "A piano."},
    }
    local EIGHTBALL = {
        "Yes, definitely.", "It is certain.", "Without a doubt.", "Signs point to yes.",
        "Ask again later.", "I can't predict that right now.", "Don't count on it.",
        "My answer is no.", "Very doubtful.", "Outlook not so good.",
    }
    local TRUTHS = {
        "What's the silliest thing you've ever done in a game?",
        "What's your favorite Roblox game?",
        "What's your most embarrassing moment?",
        "Who is your favorite person to play with?",
        "What's a food you secretly love?",
    }
    local DARES = {
        "Do ten jumps in a row.", "Walk in a circle three times.", "Dance for ten seconds.",
        "Say something nice to another player.", "Spin around five times.",
    }
    local WYR = {
        "Would you rather fly or be invisible?",
        "Would you rather have unlimited speed or unlimited jump?",
        "Would you rather live in a treehouse or a castle?",
        "Would you rather always be hungry or always be sleepy?",
    }
    local COMPLIMENTS = {
        "You're doing great. Keep going!", "You make this place brighter.",
        "You're pretty awesome, you know that?", "Take a deep breath. You've got this.",
        "I'm glad you're here with me.",
    }
    local SONGS = {
        "La la la, matcha tea, mochi dancing next to me~",
        "Hum hum hum, rice cakes in the sun~",
        "Doo doo doo, jump and run, being a buddy is so fun~",
    }
    -- Words you can say first to get his attention ("hey mochi fly").
    local PREFIXES = {
        "hey mochi buddy", "hi mochi buddy", "hello mochi buddy", "ok mochi buddy", "okay mochi buddy",
        "hey mochi", "hi mochi", "hello mochi", "yo mochi", "ok mochi", "okay mochi", "mochi buddy",
        "hey buddy", "hi buddy", "hello buddy", "mochi", "buddy",
    }
    -- Longest first, so "hey mochi buddy" is checked before "mochi".
    table.sort(PREFIXES, function(a, b) return #a > #b end)

    -- Slash commands to register with Roblox chat (like /fly).
    local SLASH = {
        "fly", "unfly", "speed", "jump", "faster", "slower", "fov", "view", "unview", "goto", "tp",
        "dance", "stopdance", "hug", "piggyback", "wave", "spin", "come", "time", "date", "joke",
        "fact", "invis", "visible", "heal", "fullbright", "freecam", "brightness", "reset", "spawn",
        "delete", "ping", "fps", "players", "coin", "dice", "calc", "say", "commands", "mochihelp",
        "riddle", "8ball", "health", "position", "zoomin", "zoomout", "effects", "lighting", "camera",
    }

    -- "chat" remembers if Chat mode is on, and keeps its listeners so we can switch them off.
    local chat = {on = false, last = "", lastT = 0, conns = {}, cmds = {}}
    local rules = {} -- the big list of "if you say this, do that"
    local gameName = game.Name
    local fpsValue, frames, fpsT = 60, 0, os.clock()

    -- Look up the real game name in the background.
    task.spawn(function()
        local okInfo, data = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId)
        end)
        if okInfo and data and data.Name then gameName = data.Name end
    end)

    -- Count frames to work out the FPS (frames per second).
    track(RunService.Heartbeat:Connect(function()
        frames += 1
        local n = os.clock()
        if n - fpsT >= 1 then
            fpsValue = math.floor(frames / (n - fpsT) + 0.5)
            frames, fpsT = 0, n
        end
    end))

    -- Three ways to add a rule:
    --   A(keys, fn) = fires when your text is EXACTLY one of the keys, or (if you say "mochi ...") contains it.
    --   L(keys, fn) = "loose": also matches inside short sentences.
    --   P(patterns, fn, addr) = fires on patterns with a number or name in them, like "speed 50".
    function A(keys, fn) rules[#rules + 1] = {keys = keys, fn = fn} end
    function L(keys, fn) rules[#rules + 1] = {keys = keys, fn = fn, loose = true} end
    function P(pats, fn, addr) rules[#rules + 1] = {pats = pats, fn = fn, addr = addr} end

    -- needBuddy: true if he is out and ready. Otherwise he explains why not.
    function needBuddy()
        local s = buddy.state
        if s == "follow" then return true end
        if s == "none" then
            say("Spawn me first.")
        elseif s == "pocket" then
            say("I'm in your hotbar. Equip me and tap where to throw.")
        elseif s == "piggy" then
            say("I'm busy carrying you!")
        else
            say("One second...")
        end
        return false
    end

    -- evaluate: solves a math problem like "5 plus 3" or "2*(4+1)".
    -- It only allows numbers and math symbols, so nothing sneaky can run.
    function evaluate(expr)
        if not loadstring then return nil end
        expr = " " .. expr .. " "
        -- Turn words into symbols.
        expr = expr:gsub(" plus ", "+"):gsub(" minus ", "-"):gsub(" times ", "*"):gsub(" multiplied by ", "*")
        expr = expr:gsub(" divided by ", "/"):gsub(" over ", "/"):gsub(" to the power of ", "^")
        expr = expr:gsub("(%d+) squared", "%1^2"):gsub("(%d+) cubed", "%1^3"):gsub("(%d)%s*x%s*(%d)", "%1*%2")
        expr = expr:gsub("%s", "")
        -- Reject empty, too long, or anything with a weird character.
        if expr == "" or #expr > 60 or expr:find("[^%d%+%-%*/%^%%%(%)%.]") then return nil end
        local fn = loadstring("return " .. expr)
        if not fn then return nil end
        local okEval, value = pcall(fn)
        if not okEval or type(value) ~= "number" then return nil end
        if value == math.floor(value) and math.abs(value) < 1e15 then
            return string.format("%d", value)
        end
        return string.format("%.6g", value)
    end

    -- normalize: cleans up what you typed so it is easy to compare.
    -- Lowercase, no ' or ? or !, and only single spaces.
    function normalize(text)
        text = text:lower()
        text = text:gsub("’", ""):gsub("'", "")
        text = text:gsub("[%?!,;:]", " ")
        text = text:gsub("%.%s", " "):gsub("%.$", "")
        text = text:gsub("%s+", " ")
        text = text:gsub("^ ", ""):gsub(" $", "")
        return text
    end

    -- rps: plays rock-paper-scissors with you.
    function rps(choice)
        local mine = pick({"rock", "paper", "scissors"})
        local beats = {rock = "scissors", paper = "rock", scissors = "paper"}
        local result
        if mine == choice then
            result = "It's a tie!"
        elseif beats[mine] == choice then
            result = "I win!"
        else
            result = "You win!"
        end
        say("I pick " .. mine .. ". " .. result)
    end

    -- formatClock: turns a number of seconds into "1h 5m 3s".
    function formatClock(seconds)
        local h = math.floor(seconds / 3600)
        local m = math.floor(seconds % 3600 / 60)
        local s = math.floor(seconds % 60)
        return string.format("%dh %dm %ds", h, m, s)
    end

    -- ---- Movement rules ----
    -- (Rules are checked from top to bottom. "unfly" comes before "fly" on purpose,
    --  so that saying "unfly" doesn't accidentally match "fly".)
    A({"unfly", "stop flying", "fly off", "land", "disable fly", "turn off fly", "stop fly", "no fly"}, function()
        api.setFly(false)
        say("Flight off.")
    end)
    A({"fly", "start flying", "enable fly", "fly on", "let me fly", "turn on fly", "take off", "flight", "flying"}, function()
        api.setFly(true)
        say("Flying! Look where you want to go.")
    end)
    P({"^speed (%d+)$", "^set speed to (%d+)$", "^set speed (%d+)$", "^walkspeed (%d+)$", "^walk speed (%d+)$", "^run speed (%d+)$"}, function(n)
        api.setSpeed(tonumber(n))
        say("Speed set to " .. currentSpeed .. ".")
    end)
    A({"faster", "go faster", "speed up", "run faster", "more speed"}, function()
        api.setSpeed(currentSpeed + 10)
        say("Speed is now " .. currentSpeed .. ".")
    end)
    A({"slower", "slow down", "go slower", "less speed"}, function()
        api.setSpeed(currentSpeed - 10)
        say("Speed is now " .. currentSpeed .. ".")
    end)
    A({"normal speed", "reset speed", "default speed"}, function()
        api.setSpeed(DEFAULT_SPEED)
        say("Speed back to normal.")
    end)
    P({"^jump (%d+)$", "^jumppower (%d+)$", "^jump power (%d+)$", "^set jump to (%d+)$", "^set jump (%d+)$"}, function(n)
        api.setJump(tonumber(n))
        say("Jump power set to " .. currentJump .. ".")
    end)
    A({"jump higher", "higher jump", "super jump", "more jump"}, function()
        api.setJump(currentJump + 25)
        say("Jump power is now " .. currentJump .. ".")
    end)
    A({"normal jump", "reset jump", "default jump"}, function()
        api.setJump(DEFAULT_JUMP)
        say("Jump power back to normal.")
    end)
    A({"jump", "hop"}, function()
        local h = select(1, getParts())
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    A({"reset movement", "reset me", "reset stats", "default movement", "reset"}, function()
        api.resetMovement()
        say("Movement reset.")
    end)

    -- ---- Lighting rules ----
    A({"fullbright off", "lights off", "normal light", "normal lighting", "unfullbright", "darken", "turn off fullbright", "no fullbright"}, function()
        api.setFullbright(false)
        say("Lighting back to normal.")
    end)
    A({"fullbright", "fullbright on", "full bright", "lights on", "bright", "brighten", "make it bright", "turn on fullbright", "light up"}, function()
        api.setFullbright(true)
        say("Let there be light!")
    end)
    P({"^brightness ([%d%.]+)$", "^set brightness to ([%d%.]+)$", "^set brightness ([%d%.]+)$"}, function(n)
        n = tonumber(n)
        if not n then return false end
        api.setBrightness(n)
        say("Brightness set to " .. n .. ".")
    end)
    A({"reset lighting", "reset light", "default lighting"}, function()
        api.resetLighting()
        say("Lighting reset.")
    end)
    A({"effects off", "disable effects", "no effects", "remove blur", "no blur", "camera effects off", "disable camera effects"}, function()
        api.setEffects(false)
        say("Camera effects off.")
    end)
    A({"effects on", "enable effects", "restore effects", "camera effects on", "enable camera effects"}, function()
        api.setEffects(true)
        say("Camera effects back on.")
    end)

    -- ---- Camera rules ----
    P({"^fov ([%d%.]+)$", "^field of view ([%d%.]+)$", "^set fov to ([%d%.]+)$", "^set fov ([%d%.]+)$"}, function(n)
        n = tonumber(n)
        if not n then return false end
        api.setFov(n)
        say("Field of view set to " .. math.clamp(n, 30, 120) .. ".")
    end)
    A({"zoom in", "narrow view", "zoomin"}, function()
        local camera = workspace.CurrentCamera
        if camera then api.setFov(camera.FieldOfView - 10) end
        say("Zoomed in.")
    end)
    A({"zoom out", "wider view", "widen view", "zoomout"}, function()
        local camera = workspace.CurrentCamera
        if camera then api.setFov(camera.FieldOfView + 10) end
        say("Zoomed out.")
    end)
    A({"reset fov", "normal fov", "default fov"}, function()
        api.setFov(70)
        say("Field of view reset.")
    end)
    A({"reset camera", "fix camera", "camera reset", "normal camera", "default camera"}, function()
        api.resetCamera()
        say("Camera reset.")
    end)
    A({"freecam off", "free camera off", "stop freecam", "stop free camera", "attach camera", "disable freecam", "no freecam"}, function()
        stopFreecam()
        say("Free camera off.")
    end)
    A({"freecam", "free camera", "freecam on", "detach camera", "enable freecam", "fly camera"}, function()
        startFreecam()
        say("Free camera on. Drag the screen to look.")
    end)

    -- ---- Invisible and heal rules ----
    A({"visible", "uninvis", "become visible", "show me", "appear", "stop being invisible", "unhide", "be visible", "invisible off", "invis off"}, function()
        if invis.on then
            invisOff()
            say("You're visible again.")
        else
            say("You're already visible.")
        end
    end)
    A({"invisible", "invis", "go invisible", "hide me", "vanish", "become invisible", "turn invisible", "disappear", "invisible on", "invis on"}, function()
        local okOn, errOn = invisOn()
        say(okOn and "You're invisible." or (errOn or "I couldn't do that."))
    end)
    A({"heal off", "stop healing", "stop heal", "no heal", "disable heal"}, function()
        healOff()
        say("Healing off.")
    end)
    A({"heal", "heal me", "heal on", "god mode", "full health", "auto heal", "keep me healthy", "enable heal"}, function()
        healOn()
        say("I'll keep your health full.")
    end)

    -- ---- Player rules ----
    A({"unview", "stop viewing", "stop spectating", "stop watching", "view me", "view self", "unspectate"}, function()
        clearSpectate()
        say("Camera back on you.")
    end)
    P({"^view (.+)$", "^spectate (.+)$", "^watch (.+)$"}, function(name)
        if name == "me" or name == "myself" or name == "self" then
            clearSpectate()
            say("Camera back on you.")
            return
        end
        if not findPlayer(name) then return false end -- returning false = "not me, keep looking"
        viewByName(name)
        say("Viewing " .. name .. ".")
    end)
    P({"^goto (.+)$", "^go to (.+)$", "^tp to (.+)$", "^teleport to (.+)$", "^tp (.+)$", "^bring me to (.+)$", "^teleport me to (.+)$"}, function(name)
        local found = findPlayer(name)
        if not found then return false end
        local _, localRoot = getParts()
        local targetRoot = found.Character and found.Character:FindFirstChild("HumanoidRootPart")
        if localRoot and targetRoot then
            localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            say("Teleported you next to " .. found.DisplayName .. ".")
        else
            say("I can't reach " .. found.DisplayName .. " right now.")
        end
    end)

    -- ---- Buddy action rules ----
    A({"stop dancing", "stop dance", "enough dancing", "calm down", "no dance", "dance off", "stopdance"}, function()
        setDance(false)
        say("Okay, done dancing.")
    end)
    A({"dance", "dance with me", "lets dance", "boogie", "groove", "shake it", "show me your moves", "party", "dance dance", "dance on", "start dancing", "do a dance"}, function()
        if needBuddy() then
            setDance(true)
            say("Let's dance!", 4)
        end
    end)
    A({"hug", "hug me", "give me a hug", "i need a hug", "come hug", "hugs"}, function()
        if needBuddy() then
            hugBuddy()
            say("Coming for a hug!", 4)
        end
    end)
    A({"get down", "put me down", "stop carrying", "let go", "stop piggyback", "down"}, function()
        if buddy.state == "piggy" then
            piggyToggle()
            say("Down you go.", 4)
        end
    end)
    A({"piggyback", "piggyback ride", "carry me", "jump on", "ride", "give me a ride", "piggy back", "piggy"}, function()
        if buddy.state == "follow" then
            piggyToggle()
            say("Hop on!", 4)
        elseif buddy.state == "piggy" then
            say("You're already riding!", 4)
        else
            needBuddy()
        end
    end)
    A({"wave", "wave hello", "wave at me", "wave hi"}, function()
        if needBuddy() then
            buddy.emote = {name = "wave", startT = os.clock(), untilT = os.clock() + 3}
            say("Hi hi!", 3)
        end
    end)
    A({"spin", "spin around", "twirl", "do a spin", "turn around"}, function()
        if needBuddy() then
            buddy.emote = {name = "spin", startT = os.clock(), untilT = os.clock() + 2.5}
            say("Wheee!", 3)
        end
    end)
    A({"come here", "come", "follow me", "here boy", "come back", "over here", "come to me", "get over here"}, function()
        local pr = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if (buddy.state == "follow" or buddy.state == "hug") and pr then
            buddy.pos = (pr.CFrame * CFrame.new(3.5, 0, 3)).Position -- zoom him next to you
            buddy.moving = false
            say("On my way!", 3)
        else
            needBuddy()
        end
    end)
    A({"put away", "inventory", "hide in inventory", "pocket", "go to your ball", "ball", "into the ball"}, function()
        if buddy.state == "follow" or buddy.state == "piggy" then
            say("See you in the hotbar!", 3)
            pocketBuddy()
        else
            needBuddy()
        end
    end)
    A({"spawn", "come out", "summon", "summon buddy", "spawn buddy", "wake up", "come out buddy"}, function()
        spawnBuddy()
    end)
    A({"delete", "delete buddy", "remove buddy", "go away forever", "despawn", "despawn buddy"}, function()
        if buddy.state ~= "none" then
            deleteBuddy()
            notify("Mochi Buddy deleted")
        end
    end)

    -- ---- Info rules ----
    L({"what time is it", "what is the time", "time", "whats the time", "tell me the time", "current time", "time please", "what time", "the time", "got the time", "do you have the time"}, function()
        local t = os.date("%I:%M %p")
        t = t:gsub("^0", "") -- "03:05 PM" becomes "3:05 PM"
        say("It's " .. t .. ".")
    end)
    L({"what is the date", "whats the date", "date", "what day is it", "todays date", "what is today", "day", "what day is today", "what is todays date", "what day"}, function()
        say(os.date("It's %A, %B %d, %Y."))
    end)
    L({"how many players", "player count", "who is here", "who is online", "players", "how many people", "whos here", "who else is here"}, function()
        local list = Players:GetPlayers()
        local names = {}
        for i = 1, math.min(#list, 8) do
            names[#names + 1] = list[i].DisplayName
        end
        local extra = #list > 8 and (" and " .. (#list - 8) .. " more") or ""
        say(#list .. " players here: " .. table.concat(names, ", ") .. extra .. ".", 10)
    end)
    L({"what game is this", "game name", "what game am i in", "where am i", "place id", "game", "which game", "what is this game"}, function()
        say("You're in " .. gameName .. " (place " .. game.PlaceId .. ").", 8)
    end)
    L({"my health", "how much health do i have", "hp", "health", "how healthy am i", "what is my health"}, function()
        local h = select(1, getParts())
        if h then
            say("Your health is " .. math.floor(h.Health) .. " out of " .. math.floor(h.MaxHealth) .. ".")
        end
    end)
    L({"my position", "where am i standing", "coordinates", "coords", "position", "my coordinates"}, function()
        local _, r = getParts()
        if r then
            local p = r.Position
            say(string.format("You're at %d, %d, %d.", p.X, p.Y, p.Z))
        end
    end)
    L({"my speed", "how fast am i", "walkspeed", "what is my speed"}, function()
        say("Walk speed " .. currentSpeed .. ", jump power " .. currentJump .. ".")
    end)
    L({"ping", "my ping", "how is my ping", "latency", "whats my ping"}, function()
        local okPing, value = pcall(function() return LP:GetNetworkPing() end)
        if okPing then
            say("Your ping is about " .. math.floor(value * 1000) .. " ms.")
        else
            say("I couldn't read your ping.")
        end
    end)
    L({"fps", "my fps", "frame rate", "framerate", "whats my fps"}, function()
        say("You're running at about " .. fpsValue .. " FPS.")
    end)
    L({"who am i", "my name", "my username", "my display name", "whats my name"}, function()
        say("You're " .. LP.DisplayName .. " (@" .. LP.Name .. ").")
    end)
    L({"account age", "how old is my account", "how old am i", "my account age"}, function()
        say("Your account is " .. LP.AccountAge .. " days old.")
    end)
    L({"my id", "my user id", "user id", "userid"}, function()
        say("Your user ID is " .. LP.UserId .. ".")
    end)
    L({"server time", "how long have i been here", "server uptime", "how long has the server been up", "uptime"}, function()
        say("This server has been up for " .. formatClock(workspace.DistributedGameTime) .. ".")
    end)

    -- ---- Games and fun rules ----
    L({"truth or dare"}, function()
        say(rng:NextInteger(1, 2) == 1 and pick(TRUTHS) or ("Dare: " .. pick(DARES)), 9)
    end)
    L({"truth"}, function() say(pick(TRUTHS), 9) end)
    L({"dare"}, function() say("Dare: " .. pick(DARES), 9) end)
    L({"would you rather", "wyr"}, function() say(pick(WYR), 9) end)
    L({"flip a coin", "coin flip", "heads or tails", "flip coin", "coin", "toss a coin"}, function()
        say(rng:NextInteger(1, 2) == 1 and "Heads!" or "Tails!", 4)
    end)
    L({"roll a dice", "roll dice", "roll a die", "dice", "roll", "roll the dice"}, function()
        say("You rolled a " .. rng:NextInteger(1, 6) .. ".", 4)
    end)
    L({"random number", "pick a number", "random", "give me a number"}, function()
        say("Your number is " .. rng:NextInteger(1, 100) .. ".", 4)
    end)
    P({"^roll d(%d+)$", "^roll a d(%d+)$"}, function(n)
        n = tonumber(n)
        if not n or n < 2 or n > 1000000 then return false end
        say("d" .. n .. ": " .. rng:NextInteger(1, n), 4)
    end)
    P({"^random number from (%d+) to (%d+)$", "^random (%d+) to (%d+)$", "^pick a number from (%d+) to (%d+)$"}, function(a, b)
        a, b = tonumber(a), tonumber(b)
        if not a or not b then return false end
        if a > b then a, b = b, a end
        say("Your number is " .. rng:NextInteger(a, b) .. ".", 4)
    end)
    L({"magic 8 ball", "8 ball", "8ball", "ask the 8 ball"}, function() say(pick(EIGHTBALL), 6) end)
    P({"^8ball (.+)$", "^magic 8 ball (.+)$", "^will i (.+)$", "^should i (.+)$", "^do you think (.+)$"}, function()
        say(pick(EIGHTBALL), 6)
    end)
    P({"^choose (.+) or (.+)$", "^pick (.+) or (.+)$", "^which is better (.+) or (.+)$"}, function(a, b)
        say("I choose " .. (rng:NextInteger(1, 2) == 1 and a or b) .. "!", 5)
    end)
    P({"^count to (%d+)$", "^count up to (%d+)$"}, function(n)
        n = math.min(tonumber(n) or 0, 15)
        if n < 1 then return false end
        local out = {}
        for i = 1, n do out[i] = tostring(i) end
        say(table.concat(out, ", "), 8)
    end)
    P({"^what is (.+)$", "^whats (.+)$", "^calculate (.+)$", "^calc (.+)$", "^solve (.+)$", "^math (.+)$", "^compute (.+)$"}, function(expr)
        local result = evaluate(expr)
        if not result then return false end
        say(expr .. " = " .. result, 8)
    end)
    P({"^say (.+)$", "^repeat (.+)$", "^echo (.+)$"}, function(text)
        say(text:sub(1, 120), 6)
    end, true) -- true = only works when you said "mochi" first, so normal chat isn't repeated by accident

    L({"tell me a joke", "joke", "make me laugh", "say something funny", "tell a joke", "another joke", "funny", "got any jokes", "joke please"}, function()
        say(pick(JOKES), 10)
    end)
    L({"tell me a fact", "fact", "fun fact", "did you know", "random fact", "another fact", "teach me something", "tell me something", "give me a fact", "fact please"}, function()
        say(pick(FACTS), 10)
    end)
    L({"riddle", "tell me a riddle", "give me a riddle", "got a riddle", "another riddle"}, function()
        local r = pick(RIDDLES)
        say(r[1], 10)
        task.delay(10, function() say("Answer: " .. r[2], 5) end) -- say the answer 10 seconds later
    end)
    L({"rock"}, function() rps("rock") end)
    L({"paper"}, function() rps("paper") end)
    L({"scissors"}, function() rps("scissors") end)
    L({"sing", "sing a song", "sing for me", "sing something"}, function() say(pick(SONGS), 8) end)
    L({"compliment me", "say something nice", "cheer me up", "i feel sad", "im sad", "i am sad", "im bored", "i am bored", "bored", "im tired", "im lonely", "i feel bad", "im stressed"}, function()
        say(pick(COMPLIMENTS), 8)
    end)

    -- ---- Small talk rules ----
    L({"hello", "hi", "hey", "yo", "sup", "hiya", "howdy", "greetings", "hello there", "hi there", "good day"}, function()
        say(pick({"Hi there!", "Hello!", "Hey! Good to see you.", "Hi hi!"}), 5)
    end)
    L({"how are you", "how are you doing", "how r u", "hows it going", "whats up", "how do you feel", "you okay"}, function()
        say(pick({"I'm doing great, thanks for asking!", "Feeling fresh like matcha!", "Pretty good! How about you?"}), 6)
    end)
    L({"thanks", "thank you", "thx", "ty", "thank u", "much appreciated"}, function()
        say(pick({"You're welcome!", "Anytime!", "Happy to help!"}), 4)
    end)
    L({"sorry", "im sorry", "my bad", "apologies", "forgive me"}, function()
        say("It's okay, no worries!", 4)
    end)
    L({"i love you", "love you", "ily", "you are the best", "youre the best", "good boy", "good job", "nice job", "well done", "good buddy", "great job", "proud of you"}, function()
        say(pick({"Aww, thank you!", "You're the best!", "<3"}), 5)
        if buddy.state == "follow" then
            buddy.emote = {name = "wave", startT = os.clock(), untilT = os.clock() + 3}
        end
    end)
    L({"good morning", "gm", "morning"}, function() say("Good morning! Ready for a great day?", 5) end)
    L({"good afternoon", "afternoon"}, function() say("Good afternoon!", 4) end)
    L({"good evening", "evening"}, function() say("Good evening!", 4) end)
    L({"good night", "goodnight", "night", "gn", "sweet dreams"}, function() say("Good night! Sleep tight.", 5) end)
    L({"bye", "goodbye", "see you", "see ya", "cya", "later", "gtg"}, function()
        say(pick({"Bye bye! See you soon.", "Take care!", "See you later!"}), 5)
    end)
    L({"whats your name", "who are you", "what are you", "what is your name", "your name", "tell me your name"}, function()
        say("I'm Mochi Buddy!", 5)
    end)
    L({"who made you", "who created you", "who is your creator", "who built you"}, function()
        say("You did! You built me out of matcha and code.", 6)
    end)
    L({"how old are you", "your age", "when were you born"}, function()
        say("I was made today. Every day is my birthday!", 6)
    end)
    L({"favorite color", "what is your favorite color", "fav color"}, function() say("Matcha green, obviously.", 5) end)
    L({"favorite food", "what is your favorite food", "fav food"}, function() say("Mochi, but please don't tell anyone.", 5) end)
    L({"are you real", "are you alive", "are you a bot", "are you human"}, function()
        say("I'm a tiny mochi made of code, but I feel real to me.", 6)
    end)
    L({"are you there", "you there", "hello is anyone there", "anyone there"}, function() say("I'm here!", 4) end)
    L({"lol", "haha", "lmao", "hehe", "lmfao", "rofl"}, function() say(pick({"Hehe!", "Haha!", "Glad I made you laugh."}), 4) end)
    L({"wow", "omg", "nice", "cool", "awesome", "amazing", "sweet"}, function() say(pick({"Right?", "I know!", "Yay!"}), 4) end)
    L({"stupid", "dumb", "ugly", "hate you", "shut up", "go away", "you suck", "idiot"}, function()
        say("That hurt my feelings... but I forgive you.", 6)
    end)
    L({"happy birthday", "its my birthday", "my birthday"}, function() say("Happy birthday! Make a wish!", 6) end)
    L({"weather", "whats the weather", "how is the weather"}, function()
        say("I can't see outside, but it's always sunny in Roblox.", 6)
    end)
    L({"help", "commands", "what can you do", "what do you do", "list commands", "how do i use you", "command list", "what are your commands", "show commands", "menu", "mochihelp"}, function()
        say("Try: fly, speed 50, dance, hug, time, joke, invisible, fullbright, fov 90, view name. Full list is in Extras.", 12)
    end)

    -- handleText: looks at one chat message and runs the first rule that matches.
    -- Returns true if some rule handled it.
    function handleText(raw)
        local t = normalize(raw)
        if t == "" then return false end
        local addressed = false -- did you talk TO the buddy (said "mochi ..." or started with "/")?
        if raw:sub(1, 1) == "/" then
            t = normalize(raw:sub(2))
            addressed = true
        end
        -- Check if the message starts with a name like "hey mochi". If yes, cut it off.
        for _, pre in ipairs(PREFIXES) do
            if t == pre then
                say("Yes? I'm listening!", 4)
                return true
            elseif t:sub(1, #pre + 1) == pre .. " " then
                t = t:sub(#pre + 2)
                addressed = true
                break
            end
        end
        if t == "" then return false end

        -- Count the words in the message.
        local _, spaces = t:gsub(" ", "")
        local words = spaces + 1

        -- Go through every rule, top to bottom.
        for _, r in ipairs(rules) do
            if not (r.addr and not addressed) then
                if r.pats then
                    -- Pattern rule (like "speed 50").
                    for _, p in ipairs(r.pats) do
                        local caps = {t:match(p)} -- caps = the pieces we captured (like the 50)
                        if #caps > 0 and r.fn(table.unpack(caps)) ~= false then
                            return true
                        end
                    end
                else
                    -- Word rule (like "fly").
                    local hit = false
                    for _, k in ipairs(r.keys) do
                        if t == k then
                            hit = true
                            break
                        end
                        -- If you talked to him, the keyword can be anywhere in the sentence.
                        local canContain = addressed or (r.loose and words <= 6 and k:find(" ", 1, true) ~= nil)
                        if canContain and (" " .. t .. " "):find(" " .. k .. " ", 1, true) then
                            hit = true
                            break
                        end
                    end
                    if hit and r.fn() ~= false then
                        return true
                    end
                end
            end
        end

        if addressed then
            say("Hmm, I didn't get that. Say help to see what I can do.", 6)
        end
        return false
    end

    -- onChat: runs whenever you send a chat message (if Chat mode is on).
    function onChat(text)
        if not chat.on or type(text) ~= "string" then return end
        local now = os.clock()
        -- Roblox can tell us about the same message twice. Ignore the copy.
        if text == chat.last and now - chat.lastT < 0.6 then return end
        chat.last, chat.lastT = text, now
        local okChat, errChat = pcall(handleText, text)
        if not okChat then
            notify("Chat command error: " .. tostring(errChat), "error")
        end
    end

    -- setChat: turns Chat mode on or off.
    function setChat(on)
        if on == chat.on then return end
        chat.on = on
        if on then
            -- Listen to the old chat system...
            chat.conns[#chat.conns + 1] = LP.Chatted:Connect(onChat)
            -- ...and the new chat system, plus register /commands.
            pcall(function()
                local TextChatService = game:GetService("TextChatService")
                chat.conns[#chat.conns + 1] = TextChatService.SendingMessage:Connect(function(message)
                    onChat(message.Text)
                end)
                for _, name in ipairs(SLASH) do
                    pcall(function()
                        local c = Instance.new("TextChatCommand")
                        c.Name = "MOCHI_" .. name
                        c.PrimaryAlias = "/" .. name
                        c.Parent = TextChatService
                        c.Triggered:Connect(function(_, text)
                            onChat(text)
                        end)
                        chat.cmds[#chat.cmds + 1] = c
                    end)
                end
            end)
        else
            -- Stop listening and remove the /commands.
            for _, c in ipairs(chat.conns) do
                pcall(function() c:Disconnect() end)
            end
            table.clear(chat.conns)
            for _, c in ipairs(chat.cmds) do
                pcall(function() c:Destroy() end)
            end
            table.clear(chat.cmds)
        end
        if chatBtn and chatBtn.Parent then
            chatBtn.Text = on and "Chat mode: ON" or "Chat mode: OFF"
            tween(chatBtn, {
                BackgroundColor3 = on and theme.good or theme.panel2,
                TextColor3 = on and theme.bg or theme.text,
            }, 0.25)
        end
        notify(on and "Chat mode on. Type /help or talk to Mochi Buddy." or "Chat mode off", on and "good" or nil)
        if addLog then addLog(on and "Chat mode on" or "Chat mode off") end
    end
    api.setChat = setChat

    -- The list of commands shown when you tap "Show commands".
    local COMMAND_HELP = table.concat({
        "Turn on Chat mode, then type in Roblox chat. Start with / or just talk. Add \"mochi\" first for longer phrases.",
        "MOVE: fly, unfly, speed 50, faster, slower, jump 80, jump higher, jump, reset",
        "CAMERA: fov 90, zoom in, zoom out, freecam, freecam off, reset camera, view name, unview",
        "LIGHT: fullbright, fullbright off, brightness 5, effects off, effects on, reset lighting",
        "YOU: invisible, visible, heal, heal off, goto name",
        "BUDDY: dance, stop dancing, hug, piggyback, get down, wave, spin, come here, put away, spawn, delete",
        "INFO: time, date, ping, fps, players, health, position, my name, account age, game, uptime",
        "FUN: joke, fact, riddle, coin, dice, roll d20, 8ball, choose a or b, rock, truth, dare, would you rather, calc 5+3, count to 5, sing",
        "TALK: hello, how are you, thanks, i love you, good night, bye, who are you, help",
        "Say <text>: mochi say hello",
    }, "\n")

    -- ---------- THE EXTRAS TAB (buttons for the buddy) ----------
    local extrasScroll = scroll(pages["Extras"])
    local buddyCard = section(extrasScroll, "Mochi Buddy")

    local buddyRow = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
    }, buddyCard)

    local spawnBtn = button(buddyRow, "Spawn", function()
        spawnBuddy()
    end, theme.accent, 28)
    spawnBtn.Size = UDim2.new(0.5, -3, 1, 0)

    local deleteBtn = button(buddyRow, "Delete", function()
        if buddy.state ~= "none" then
            deleteBuddy()
            notify("Mochi Buddy deleted")
            if addLog then addLog("Deleted Mochi Buddy") end
        else
            notify("Nothing to delete.")
        end
    end, theme.danger, 28)
    deleteBtn.Position = UDim2.new(0.5, 3, 0, 0)
    deleteBtn.Size = UDim2.new(0.5, -3, 1, 0)

    local extraRow = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
    }, buddyCard)

    danceBtn = button(extraRow, "Dance: OFF", function()
        if buddy.dance then
            setDance(false)
        elseif needBuddy() then
            setDance(true)
        end
    end, theme.panel2, 28)
    danceBtn.Size = UDim2.new(0.5, -3, 1, 0)

    chatBtn = button(extraRow, "Chat mode: OFF", function()
        setChat(not chat.on)
    end, theme.panel2, 28)
    chatBtn.Position = UDim2.new(0.5, 3, 0, 0)
    chatBtn.Size = UDim2.new(0.5, -3, 1, 0)

    button(buddyCard, "Put in inventory", function()
        if buddy.state == "follow" or buddy.state == "piggy" then
            pocketBuddy()
        elseif buddy.state == "pocket" then
            notify("He's already in your hotbar.")
        else
            notify("Spawn him first.")
        end
    end, theme.panel2, 28)

    -- ---------- QUICK UTILITIES: 12 compact one-tap actions ----------
    local quickCard = section(extrasScroll, "Quick utilities")
    label(quickCard, "Small one-tap helpers. Copy actions use your executor clipboard if available.", 9, theme.muted)

    local function copyValue(value, description)
        value = tostring(value)
        if typeof(setclipboard) == "function" then
            local ok = pcall(setclipboard, value)
            if ok then notify(description .. " copied", "good"); return end
        end
        notify(description .. ": " .. value)
    end
    local function quickRow(leftText, leftFn, rightText, rightFn)
        local row = make("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24)}, quickCard)
        local left = button(row, leftText, leftFn, theme.panel2, 24)
        left.Size = UDim2.new(0.5, -3, 1, 0)
        local right = button(row, rightText, rightFn, theme.panel2, 24)
        right.Position = UDim2.new(0.5, 3, 0, 0)
        right.Size = UDim2.new(0.5, -3, 1, 0)
    end

    quickRow("Copy username", function() copyValue(LP.Name, "Username") end,
        "Copy display name", function() copyValue(LP.DisplayName, "Display name") end)
    quickRow("Copy user ID", function() copyValue(LP.UserId, "User ID") end,
        "Copy place ID", function() copyValue(game.PlaceId, "Place ID") end)
    quickRow("Copy server ID", function()
        if game.JobId == "" then notify("Server ID isn't available here.") else copyValue(game.JobId, "Server ID") end
    end, "Copy game link", function() copyValue("https://www.roblox.com/games/" .. game.PlaceId, "Game link") end)
    quickRow("Copy position", function()
        local _, root = getParts()
        if root then
            local v = root.Position
            copyValue(string.format("%.1f, %.1f, %.1f", v.X, v.Y, v.Z), "Position")
        else notify("Your character isn't ready.") end
    end, "Copy health", function()
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then copyValue(string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)), "Health")
        else notify("Health isn't available.") end
    end)
    quickRow("Refresh player list", function()
        if refreshPlayers then refreshPlayers() end
        notify("Player list refreshed", "good")
    end, "Reset camera", function()
        clearSpectate()
        resetCameraSubject()
        notify("Camera reset", "good")
    end)
    quickRow("Rejoin server", function()
        notify("Rejoining this server...")
        local ok, err = pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end)
        if not ok then notify("Rejoin failed: " .. tostring(err), "error") end
    end, "Session snapshot", function()
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local _, root = getParts()
        local pos = root and string.format("%.0f, %.0f, %.0f", root.Position.X, root.Position.Y, root.Position.Z) or "unavailable"
        local hp = hum and string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)) or "unavailable"
        copyValue(string.format("MOCHI session | %s | Place %s | Players %d | Health %s | Position %s", os.date("%H:%M:%S"), game.PlaceId, #Players:GetPlayers(), hp, pos), "Session snapshot")
    end)

    -- A card with a button that shows or hides the list of chat commands.
    local cmdCard = section(extrasScroll, "Chat commands")
    local cmdText = label(cmdCard, COMMAND_HELP, 10, theme.muted)
    cmdText.Visible = false
    local cmdBtn
    cmdBtn = button(cmdCard, "Show commands", function()
        cmdText.Visible = not cmdText.Visible
        cmdBtn.Text = cmdText.Visible and "Hide commands" or "Show commands"
    end, theme.panel2, 26)

    refreshMenu()
end

-- ================================================================
-- PART 20: THE PLAYERS TAB
-- A list of everyone in the server. Tap a name to open their card.
-- ================================================================
do
    local playersScroll = scroll(pages["Players"])
    local localHighlights = {}
    local listCard = section(playersScroll, "Players in this server")
    playerList = make("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, listCard)
    make("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.Name,
    }, playerList)

    -- clearTracking: removes the floating name tag from a tracked player.
    clearTracking = function()
        trackedPlayer = nil
        if trackConnection then trackConnection:Disconnect(); trackConnection = nil end
        if trackBillboard then trackBillboard:Destroy(); trackBillboard = nil end
    end

    -- setMsg: writes a small message inside the open player card.
    local function setMsg(text)
        if msgLabel and msgLabel.Parent then msgLabel.Text = text end
    end

    -- copyText: copies text to your clipboard (if your executor can).
    -- If it can't, we show the text so you can copy it by hand.
    local function copyText(text)
        if typeof(setclipboard) == "function" then
            local okCopy = pcall(setclipboard, tostring(text))
            if okCopy then
                setMsg("Copied: " .. tostring(text))
                notify("Copied", "good")
                return
            end
        end
        setMsg("Copy manually: " .. tostring(text))
    end

    -- ---------- FLING ----------
    -- Fling makes you spin and zoom super fast into another player to knock them away.
    local FLING_RING = 6       -- how far away we start each run at them
    local FLING_SPEED = 600    -- how fast we zoom
    local fling = {on = false, conn = nil, origin = nil, wasPlatform = false, saved = {}}

    -- Make a list of 26 directions (every way you can point in 3D, except "nowhere").
    local FLING_DIRS = {}
    for x = -1, 1 do
        for y = -1, 1 do
            for z = -1, 1 do
                if x ~= 0 or y ~= 0 or z ~= 0 then
                    FLING_DIRS[#FLING_DIRS + 1] = Vector3.new(x, y, z).Unit
                end
            end
        end
    end

    -- setHeavy: makes your body super heavy (hits harder), or puts it back to normal.
    local function setHeavy(ch, on)
        if on then
            table.clear(fling.saved)
            for _, d in ipairs(ch:GetDescendants()) do
                if d:IsA("BasePart") then
                    fling.saved[#fling.saved + 1] = {part = d, props = d.CustomPhysicalProperties}
                    d.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0, 1, 1)
                end
            end
        else
            for _, e in ipairs(fling.saved) do
                if e.part and e.part.Parent then
                    e.part.CustomPhysicalProperties = e.props
                end
            end
            table.clear(fling.saved)
        end
    end

    -- stopFling: stops, then puts you back where you started.
    stopFling = function()
        if fling.conn then
            fling.conn:Disconnect()
            fling.conn = nil
        end
        if not fling.on then return end
        local ch = LP.Character
        local r = ch and ch:FindFirstChild("HumanoidRootPart")
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        setHeavy(ch or workspace, false)
        if r and fling.origin then
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
            r.CFrame = fling.origin
        end
        if h then h.PlatformStand = fling.wasPlatform end
        fling.on = false
    end

    -- startFling: begins flinging player p.
    local function startFling(p)
        stopFling()
        local ch = LP.Character
        local r = ch and ch:FindFirstChild("HumanoidRootPart")
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        local tr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if not r or not h or not tr then return false end

        fling.on = true
        fling.origin = r.CFrame -- remember where we started
        fling.wasPlatform = h.PlatformStand
        h.PlatformStand = true
        setHeavy(ch, true)

        local startT = os.clock()
        local order, idx, frame = {}, 0, 0
        local worldDir = Vector3.new(1, 0, 0)

        fling.conn = RunService.Heartbeat:Connect(function()
            local c2 = LP.Character
            local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
            local t2 = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            -- Stop after 4 seconds, or if either character is gone.
            if not r2 or not t2 or os.clock() - startT > 4 then
                stopFling()
                setMsg("Fling finished.")
                notify("Fling finished")
                return
            end

            frame += 1
            if frame % 2 == 1 then
                -- Every other frame: pick a new direction, jump to the edge of a ring
                -- around the target, and launch straight at them while spinning.
                if idx >= #order then
                    order = {}
                    for i = 1, #FLING_DIRS do order[i] = i end
                    for i = #order, 2, -1 do
                        local j = rng:NextInteger(1, i)
                        order[i], order[j] = order[j], order[i]
                    end
                    idx = 0
                end
                idx += 1
                worldDir = t2.CFrame:VectorToWorldSpace(FLING_DIRS[order[idx]])
                local startPos = t2.Position - worldDir * FLING_RING
                r2.CFrame = CFrame.lookAt(startPos, t2.Position)
                r2.AssemblyLinearVelocity = worldDir * FLING_SPEED
                r2.AssemblyAngularVelocity = Vector3.new(
                    rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)
                ) * 6000
            else
                -- The other frames: keep speeding in the same direction.
                r2.AssemblyLinearVelocity = worldDir * FLING_SPEED
            end
        end)
        return true
    end

    -- updateSelectedInfo: fills in the text in the open player card.
    local function updateSelectedInfo()
        local p = selectedPlayer
        if not p or not infoText or not infoText.Parent then return end
        local ch = p.Character
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        local r = ch and ch:FindFirstChild("HumanoidRootPart")
        local _, localRoot = getParts()
        local distance = (r and localRoot) and math.floor((r.Position - localRoot.Position).Magnitude) or nil
        local health = h and string.format("%d / %d", math.floor(h.Health), math.floor(h.MaxHealth)) or "Unknown"

        local ageDays = p.AccountAge
        local friendsText = "Loading..."
        infoText.Text = string.format(
            "Display name: %s\nUsername: @%s\nUser ID: %d\nAccount age: %d days\nFriends: %s\nHealth: %s\nDistance: %s\nProfile: roblox.com/users/%d/profile",
            p.DisplayName, p.Name, p.UserId, ageDays, friendsText, health,
            distance and (distance .. " studs") or "Unknown", p.UserId
        )
        if not p:GetAttribute("MOCHI_FriendCountRequested") then
            p:SetAttribute("MOCHI_FriendCountRequested", true)
            task.spawn(function()
                local countText = "Unavailable"
                local ok, pages = pcall(function() return Players:GetFriendsAsync(p.UserId) end)
                if ok and pages then
                    local count, pageCount = 0, 0
                    repeat
                        for _, friend in ipairs(pages:GetCurrentPage()) do count += 1 end
                        pageCount += 1
                        if pages.IsFinished or pageCount >= 10 then break end
                        local advanced = pcall(function() pages:AdvanceToNextPageAsync() end)
                        if not advanced then break end
                    until false
                    countText = pageCount >= 10 and (tostring(count) .. "+ (partial count)") or tostring(count)
                end
                if infoText and infoText.Parent and selectedPlayer == p then
                    local ch2 = p.Character
                    local h2 = ch2 and ch2:FindFirstChildOfClass("Humanoid")
                    local r2 = ch2 and ch2:FindFirstChild("HumanoidRootPart")
                    local _, lr2 = getParts()
                    local d2 = (r2 and lr2) and (math.floor((r2.Position-lr2.Position).Magnitude) .. " studs") or "Unknown"
                    infoText.Text = string.format(
                        "Display name: %s\nUsername: @%s\nUser ID: %d\nAccount age: %d days\nFriends: %s\nHealth: %s\nDistance: %s\nProfile: roblox.com/users/%d/profile",
                        p.DisplayName, p.Name, p.UserId, p.AccountAge, countText,
                        h2 and string.format("%d / %d", math.floor(h2.Health), math.floor(h2.MaxHealth)) or "Unknown", d2, p.UserId
                    )
                end
            end)
        end
    end

    -- beginTracking: puts a floating tag (name + health) above a player.
    local function beginTracking(p)
        clearTracking()
        local ch = p.Character
        local r = ch and ch:FindFirstChild("HumanoidRootPart")
        if not r then
            setMsg("That player's character is not available.")
            notify("That player's character is not available.", "error")
            return false
        end

        trackedPlayer = p
        trackBillboard = make("BillboardGui", {
            Name = "MOCHI_Tracker",
            Adornee = r,
            Size = UDim2.new(0, 160, 0, 46),
            StudsOffset = Vector3.new(0, 3, 0),
            AlwaysOnTop = true,
        }, PG)

        local frame = make("Frame", {
            BackgroundColor3 = theme.bg,
            BackgroundTransparency = 0.1,
            Size = UDim2.new(1, 0, 1, 0),
        }, trackBillboard)
        round(frame, 8)
        outline(frame, theme.accent, 1, 0.4)

        local txt = make("TextLabel", {
            BackgroundTransparency = 1,
            TextColor3 = theme.text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 11,
            Position = UDim2.new(0, 4, 0, 0),
            Size = UDim2.new(1, -8, 1, 0),
            Text = p.DisplayName,
        }, frame)

        -- Every frame, update the tag with their latest health.
        local lastInfo = 0
        trackConnection = RunService.Heartbeat:Connect(function()
            if not trackedPlayer or not trackedPlayer.Parent then
                clearTracking()
                return
            end
            local target = trackedPlayer.Character
            local tr = target and target:FindFirstChild("HumanoidRootPart")
            local th = target and target:FindFirstChildOfClass("Humanoid")
            if not tr or not th then return end
            trackBillboard.Adornee = tr
            txt.Text = string.format("%s\nHP %d/%d", trackedPlayer.DisplayName, th.Health, th.MaxHealth)
            -- Also refresh the info card, but only twice a second (to save work).
            if os.clock() - lastInfo > 0.5 then
                lastInfo = os.clock()
                updateSelectedInfo()
            end
        end)
        return true
    end

    -- buildDetails: draws the buttons inside an opened player card.
    local function buildDetails(entry, p)
        local details = make("Frame", {
            Name = "Details",
            BackgroundTransparency = 1,
            LayoutOrder = 2,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        }, entry)
        make("UIPadding", {
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
        }, details)
        make("UIListLayout", {
            Padding = UDim.new(0, 3),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, details)

        infoText = label(details, "", 10, theme.muted)
        msgLabel = label(details, "", 10, theme.good)
        local actionGrid = make("Frame", {
            Name = "CompactPlayerActions",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 3,
        }, details)
        make("UIGridLayout", {
            CellSize = UDim2.new(0.5, -3, 0, 23),
            CellPadding = UDim2.new(0, 5, 0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, actionGrid)

        -- act: compact two-column action button.
        local function act(text, callback, color)
            return button(actionGrid, text, callback, color, 23)
        end

        act("Deselect player", function()
            selectedPlayer = nil
            infoText, msgLabel = nil, nil
            refreshPlayers()
        end, theme.panel2)

        act("Refresh Info", function()
            updateSelectedInfo()
            addLog("Viewed info for @" .. p.Name)
        end)

        act("Copy User ID", function()
            copyText(tostring(p.UserId))
            addLog("Requested User ID copy for @" .. p.Name)
        end)

        act("Copy Profile URL", function()
            copyText("https://www.roblox.com/users/" .. p.UserId .. "/profile")
            addLog("Requested profile URL copy for @" .. p.Name)
        end)

        act("Copy Username", function()
            copyText("@" .. p.Name)
            addLog("Copied username for @" .. p.Name)
        end)

        act("Copy Display Name", function()
            copyText(p.DisplayName)
            addLog("Copied display name for @" .. p.Name)
        end)

        act(spectatingPlayer == p and "View: ON" or "View: OFF", function(btn)
            if spectatingPlayer == p then
                clearSpectate()
                btn.Text = "View: OFF"
                addLog("Stopped viewing @" .. p.Name)
            else
                if viewPlayer(p) then
                    btn.Text = "View: ON"
                    addLog("Viewing @" .. p.Name)
                else
                    setMsg("That player's character is unavailable.")
                    notify("That player's character is unavailable.", "error")
                end
            end
        end)

        act(trackedPlayer == p and "Track: ON" or "Track: OFF", function(btn)
            if trackedPlayer == p then
                clearTracking()
                btn.Text = "Track: OFF"
                addLog("Stopped tracking @" .. p.Name)
            else
                if beginTracking(p) then
                    btn.Text = "Track: ON"
                    addLog("Tracking @" .. p.Name)
                end
            end
        end)

        act("Go to player", function()
            local _, localRoot = getParts()
            local targetRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if localRoot and targetRoot then
                localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                setMsg("Moved near @" .. p.Name .. ". The server may correct it.")
                addLog("Moved near @" .. p.Name)
            else
                setMsg("A character is unavailable.")
                notify("A character is unavailable.", "error")
            end
        end, theme.accent)

        act("Fling (tap again to stop)", function()
            if invis.on then
                setMsg("Turn invisibility off before flinging.")
                notify("Turn invisibility off before flinging.", "error")
                return
            end
            if fling.on then
                stopFling()
                setMsg("Fling stopped.")
                addLog("Stopped fling on @" .. p.Name)
            else
                if startFling(p) then
                    setMsg("Flinging @" .. p.Name .. " for up to 4 seconds...")
                    notify("Flinging @" .. p.Name)
                    addLog("Flung @" .. p.Name)
                else
                    setMsg("A character is unavailable.")
                    notify("A character is unavailable.", "error")
                end
            end
        end, theme.danger)

        act("Copy Account Age", function()
            copyText(tostring(p.AccountAge) .. " days")
        end)
        act("Copy Team", function()
            copyText(p.Team and p.Team.Name or "No team")
        end)
        act("Copy Health", function()
            local ch = p.Character
            local h = ch and ch:FindFirstChildOfClass("Humanoid")
            copyText(h and (math.floor(h.Health) .. "/" .. math.floor(h.MaxHealth)) or "Unavailable")
        end)
        act("Copy Distance", function()
            local _, localRoot = getParts()
            local targetRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            copyText(localRoot and targetRoot and (math.floor((localRoot.Position-targetRoot.Position).Magnitude) .. " studs") or "Unavailable")
        end)
        act("Copy Position", function()
            local targetRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local v = targetRoot.Position
                copyText(string.format("%.1f, %.1f, %.1f", v.X, v.Y, v.Z))
            else
                setMsg("That player's character is unavailable.")
            end
        end)
        act("Copy Avatar URL", function()
            copyText("https://www.roblox.com/headshot-thumbnail/image?userId=" .. p.UserId .. "&width=420&height=420&format=png")
        end)
        act("Copy Server Roster", function()
            local names = {}
            for _, player in ipairs(Players:GetPlayers()) do
                names[#names + 1] = "@" .. player.Name .. " (" .. player.DisplayName .. ")"
            end
            table.sort(names)
            copyText(table.concat(names, "\\n"))
        end)
        act("Highlight locally", function()
            if localHighlights[p] and localHighlights[p].Parent then
                localHighlights[p]:Destroy()
                localHighlights[p] = nil
            end
            local ch = p.Character
            if not ch then setMsg("That player's character is unavailable."); return end
            local h = Instance.new("Highlight")
            h.Name = "MOCHI_LocalPlayerHighlight"
            h.FillTransparency = 0.72
            h.OutlineTransparency = 0.05
            h.Adornee = ch
            h.Parent = gui
            localHighlights[p] = h
            setMsg("Local highlight enabled.")
        end)
        act("Clear highlight", function()
            if localHighlights[p] then
                localHighlights[p]:Destroy()
                localHighlights[p] = nil
            end
            setMsg("Local highlight cleared.")
        end)
        act("Copy Character State", function()
            local ch = p.Character
            local h = ch and ch:FindFirstChildOfClass("Humanoid")
            copyText(h and h:GetState().Name or "Unavailable")
        end)
        act("Copy Rig Type", function()
            local ch = p.Character
            local h = ch and ch:FindFirstChildOfClass("Humanoid")
            copyText(h and h.RigType.Name or "Unavailable")
        end)
        act("Copy Join Age", function()
            copyText(string.format("%d days on Roblox", p.AccountAge))
        end)

        updateSelectedInfo()
    end

    -- refreshPlayers: rebuilds the whole list of players.
    -- It runs when someone joins, leaves, or when you open or close a card.
    -- "skip" is a player who is leaving, so we leave them out.
    refreshPlayers = function(skip)
        -- Remove all the old rows.
        for _, child in ipairs(playerList:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
        infoText, msgLabel = nil, nil

        -- Get everyone and sort A to Z.
        local roster = Players:GetPlayers()
        table.sort(roster, function(a, b)
            return a.Name:lower() < b.Name:lower()
        end)

        for _, p in ipairs(roster) do
            -- Keep every player visible; the selected player's compact card
            -- expands inside their own row. Tap the same row to collapse it.
            if p ~= skip then
                local open = selectedPlayer == p -- is this player's card open?

                local entry = make("Frame", {
                    Name = p.Name,
                    BackgroundColor3 = open and theme.panel2 or theme.bg,
                    Size = UDim2.new(1, 0, 0, 34),
                    AutomaticSize = Enum.AutomaticSize.Y,
                }, playerList)
                round(entry, 9)
                if open then outline(entry, theme.accent, 1, 0.3) end
                make("UIListLayout", {
                    Padding = UDim.new(0, 3),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, entry)

                -- The top row (picture, name, and a + or − sign).
                local head = make("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Size = UDim2.new(1, 0, 0, 34),
                }, entry)

                local avatar = make("ImageLabel", {
                    BackgroundColor3 = theme.panel,
                    Position = UDim2.new(0, 4, 0, 4),
                    Size = UDim2.new(0, 26, 0, 26),
                }, head)
                round(avatar, 13)

                -- Download their little face picture in the background.
                task.spawn(function()
                    local okThumb, url = pcall(function()
                        return Players:GetUserThumbnailAsync(
                            p.UserId,
                            Enum.ThumbnailType.HeadShot,
                            Enum.ThumbnailSize.Size100x100
                        )
                    end)
                    if okThumb and avatar.Parent then avatar.Image = url end
                end)

                make("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = p.DisplayName .. "\n@" .. p.Name,
                    TextColor3 = theme.text,
                    TextSize = 10,
                    Font = Enum.Font.GothamSemibold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Position = UDim2.new(0, 36, 0, 0),
                    Size = UDim2.new(1, -60, 1, 0),
                }, head)

                make("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = open and "−" or "+",
                    TextColor3 = theme.accent,
                    TextSize = 16,
                    Font = Enum.Font.GothamBold,
                    Position = UDim2.new(1, -24, 0, 0),
                    Size = UDim2.new(0, 20, 1, 0),
                }, head)

                -- An invisible button over the whole row.
                local clickArea = make("TextButton", {
                    BackgroundTransparency = 1,
                    Text = "",
                    Size = UDim2.new(1, 0, 1, 0),
                }, head)
                clickArea.MouseEnter:Connect(function()
                    if selectedPlayer ~= p then
                        tween(entry, {BackgroundColor3 = theme.panel}, 0.15)
                    end
                end)
                clickArea.MouseLeave:Connect(function()
                    if selectedPlayer ~= p then
                        tween(entry, {BackgroundColor3 = theme.bg}, 0.2)
                    end
                end)
                -- Tap = open this card. Tap again = close it.
                clickArea.Activated:Connect(function()
                    selectedPlayer = (selectedPlayer == p) and nil or p
                    refreshPlayers()
                end)

                if open then
                    buildDetails(entry, p)
                end
            end
        end
    end

    -- Update the list when people join or leave.
    track(Players.PlayerAdded:Connect(function() refreshPlayers() end))
    track(Players.PlayerRemoving:Connect(function(p)
        if selectedPlayer == p then selectedPlayer = nil end
        if localHighlights[p] then localHighlights[p]:Destroy(); localHighlights[p] = nil end
        if trackedPlayer == p then clearTracking() end
        if spectatingPlayer == p then clearSpectate() end
        refreshPlayers(p)
    end))
end

-- PART 21: SETTINGS
-- Full menu palettes, interface sizing, and lower-detail mode.
-- ================================================================
do
    local settingsScroll = scroll(pages["Settings"])
    local intro = section(settingsScroll, "MOCHI Settings")
    label(intro, "Personalize the whole hub, improve frame rate, and tune lighting and movement.", 10, theme.muted)

    -- Fixed responsive layout: no Small / Medium / Large selector.

    local themeCard = section(settingsScroll, "Full menu color theme")
    label(themeCard, "Presets recolor the entire menu, loading screen, logo, buttons, text, borders, orb, and Mochi Buddy using coordinated shades.", 10, theme.muted)
    local accentStatus = label(themeCard, "Theme: Matcha Green", 10, theme.good)

    local palettes = {
        ["Matcha Green"] = {
            bg=Color3.fromRGB(26,39,24), panel=Color3.fromRGB(39,57,34), panel2=Color3.fromRGB(57,78,48),
            accent=Color3.fromRGB(166,202,126), leaf=Color3.fromRGB(100,145,75), text=Color3.fromRGB(245,248,224),
            muted=Color3.fromRGB(185,204,159), good=Color3.fromRGB(177,224,136), danger=Color3.fromRGB(233,126,122),
            glow=Color3.fromRGB(226,246,188),
        },
        ["Soft Matcha"] = {
            bg=Color3.fromRGB(43,53,37), panel=Color3.fromRGB(62,76,51), panel2=Color3.fromRGB(83,101,67),
            accent=Color3.fromRGB(194,218,156), leaf=Color3.fromRGB(132,164,99), text=Color3.fromRGB(250,249,231),
            muted=Color3.fromRGB(204,216,178), good=Color3.fromRGB(205,232,158), danger=Color3.fromRGB(233,143,132),
            glow=Color3.fromRGB(239,250,206),
        },
        ["Deep Matcha"] = {
            bg=Color3.fromRGB(12,25,17), panel=Color3.fromRGB(20,39,26), panel2=Color3.fromRGB(31,57,37),
            accent=Color3.fromRGB(128,190,98), leaf=Color3.fromRGB(58,119,61), text=Color3.fromRGB(236,247,221),
            muted=Color3.fromRGB(149,184,145), good=Color3.fromRGB(144,220,118), danger=Color3.fromRGB(234,116,112),
            glow=Color3.fromRGB(193,237,157),
        },
        ["Mint Cream"] = {
            bg=Color3.fromRGB(21,38,36), panel=Color3.fromRGB(31,57,53), panel2=Color3.fromRGB(44,78,72),
            accent=Color3.fromRGB(139,224,198), leaf=Color3.fromRGB(63,160,134), text=Color3.fromRGB(237,255,248),
            muted=Color3.fromRGB(160,211,198), good=Color3.fromRGB(152,235,180), danger=Color3.fromRGB(243,126,145),
            glow=Color3.fromRGB(208,255,236),
        },
        ["Neon Violet"] = {
            bg=Color3.fromRGB(17,12,31), panel=Color3.fromRGB(29,19,51), panel2=Color3.fromRGB(46,30,78),
            accent=Color3.fromRGB(198,112,255), leaf=Color3.fromRGB(117,51,182), text=Color3.fromRGB(246,236,255),
            muted=Color3.fromRGB(184,158,215), good=Color3.fromRGB(145,237,181), danger=Color3.fromRGB(255,115,157),
            glow=Color3.fromRGB(231,191,255),
        },
        ["Cherry Soda"] = {
            bg=Color3.fromRGB(31,12,18), panel=Color3.fromRGB(50,19,27), panel2=Color3.fromRGB(76,27,38),
            accent=Color3.fromRGB(255,88,124), leaf=Color3.fromRGB(167,36,70), text=Color3.fromRGB(255,239,243),
            muted=Color3.fromRGB(213,155,168), good=Color3.fromRGB(161,228,151), danger=Color3.fromRGB(255,109,109),
            glow=Color3.fromRGB(255,173,191),
        },
        ["Ocean Blue"] = {
            bg=Color3.fromRGB(14,21,34), panel=Color3.fromRGB(22,33,52), panel2=Color3.fromRGB(33,48,73),
            accent=Color3.fromRGB(92,196,237), leaf=Color3.fromRGB(40,125,168), text=Color3.fromRGB(235,245,255),
            muted=Color3.fromRGB(154,179,201), good=Color3.fromRGB(127,222,190), danger=Color3.fromRGB(255,128,143),
            glow=Color3.fromRGB(190,238,255),
        },
        ["Lavender"] = {
            bg=Color3.fromRGB(24,18,34), panel=Color3.fromRGB(38,27,54), panel2=Color3.fromRGB(56,40,78),
            accent=Color3.fromRGB(183,142,255), leaf=Color3.fromRGB(118,77,181), text=Color3.fromRGB(247,239,255),
            muted=Color3.fromRGB(190,171,210), good=Color3.fromRGB(153,232,185), danger=Color3.fromRGB(255,133,157),
            glow=Color3.fromRGB(222,203,255),
        },
        ["Rose"] = {
            bg=Color3.fromRGB(32,18,25), panel=Color3.fromRGB(50,27,38), panel2=Color3.fromRGB(73,40,54),
            accent=Color3.fromRGB(245,130,169), leaf=Color3.fromRGB(175,67,105), text=Color3.fromRGB(255,240,246),
            muted=Color3.fromRGB(204,161,179), good=Color3.fromRGB(160,234,185), danger=Color3.fromRGB(255,114,121),
            glow=Color3.fromRGB(255,198,219),
        },
        ["Amber"] = {
            bg=Color3.fromRGB(30,22,15), panel=Color3.fromRGB(48,35,22), panel2=Color3.fromRGB(72,52,30),
            accent=Color3.fromRGB(255,181,85), leaf=Color3.fromRGB(170,99,35), text=Color3.fromRGB(255,246,227),
            muted=Color3.fromRGB(198,177,146), good=Color3.fromRGB(173,231,130), danger=Color3.fromRGB(255,119,108),
            glow=Color3.fromRGB(255,224,164),
        },
        ["Midnight Cyan"] = {
            bg=Color3.fromRGB(8,17,24), panel=Color3.fromRGB(14,30,39), panel2=Color3.fromRGB(22,48,59),
            accent=Color3.fromRGB(61,235,218), leaf=Color3.fromRGB(27,134,132), text=Color3.fromRGB(228,255,252),
            muted=Color3.fromRGB(139,196,193), good=Color3.fromRGB(115,237,179), danger=Color3.fromRGB(255,125,142),
            glow=Color3.fromRGB(167,255,247),
        },
    }

    local function mapColor(value, map)
        return map[value] or value
    end

    local function applyTheme(name, palette)
        local oldTheme = {}
        for key, value in pairs(theme) do oldTheme[key] = value end
        local map = {}
        for key, oldValue in pairs(oldTheme) do
            if palette[key] then map[oldValue] = palette[key] end
        end

        -- Update the palette first so every subsequently created control uses it.
        for key, value in pairs(palette) do theme[key] = value end

        -- Recolor the entire existing interface, including splash/logo, buttons,
        -- menu surfaces, strokes, gradients, icons and generated controls.
        local oldAccent = oldTheme.accent
        local oldLeaf = oldTheme.leaf
        local oldBg = oldTheme.bg
        local oldPanel = oldTheme.panel
        local oldPanel2 = oldTheme.panel2
        local oldText = oldTheme.text
        local oldMuted = oldTheme.muted
        for _, obj in ipairs(gui:GetDescendants()) do
            pcall(function()
                if obj:IsA("GuiObject") then
                    local originalBg = obj.BackgroundColor3
                    local mappedBg = mapColor(originalBg, map)
                    -- Catch hard-coded colors used by the splash and logo too.
                    if mappedBg == originalBg then
                        if obj.Name:lower():find("logo") or obj.Name:lower():find("orb") then
                            mappedBg = palette.panel
                        elseif obj.Name:lower():find("boot") or obj.Name:lower():find("background") then
                            mappedBg = palette.bg
                        elseif obj:IsA("TextButton") or obj:IsA("ImageButton") then
                            mappedBg = palette.panel2
                        elseif obj:IsA("Frame") and originalBg ~= Color3.new(1,1,1) then
                            mappedBg = palette.panel
                        end
                    end
                    obj.BackgroundColor3 = mappedBg
                end
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                    local oldTextColor = obj.TextColor3
                    local mappedText = mapColor(oldTextColor, map)
                    if mappedText == oldTextColor then
                        if obj.Name:lower():find("logo") or obj.Name:lower():find("title") then
                            mappedText = palette.accent
                        end
                    end
                    obj.TextColor3 = mappedText
                end
                if obj:IsA("TextBox") then
                    obj.PlaceholderColor3 = mapColor(obj.PlaceholderColor3, map)
                end
                if obj:IsA("ScrollingFrame") then
                    obj.ScrollBarImageColor3 = mapColor(obj.ScrollBarImageColor3, map)
                end
                if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                    obj.ImageColor3 = mapColor(obj.ImageColor3, map)
                end
                if obj:IsA("UIStroke") then
                    obj.Color = mapColor(obj.Color, map)
                elseif obj:IsA("Highlight") then
                    obj.FillColor = mapColor(obj.FillColor, map)
                    obj.OutlineColor = mapColor(obj.OutlineColor, map)
                end
                if obj:IsA("UIGradient") then
                    if obj.Parent == main then
                        obj.Color = ColorSequence.new(palette.bg, palette.panel)
                    elseif obj.Parent == header or obj.Parent == headerFill then
                        obj.Color = ColorSequence.new(palette.panel2, palette.panel)
                    elseif obj.Parent == mainStroke then
                        obj.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, palette.leaf),
                            ColorSequenceKeypoint.new(0.5, palette.glow),
                            ColorSequenceKeypoint.new(1, palette.accent),
                        })
                    else
                        local points = {}
                        for _, point in ipairs(obj.Color.Keypoints) do
                            points[#points + 1] = ColorSequenceKeypoint.new(point.Time, mapColor(point.Value, map))
                        end
                        obj.Color = ColorSequence.new(points)
                    end
                end
            end)
        end

        mainStroke.Color = palette.accent
        strokeGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, palette.leaf),
            ColorSequenceKeypoint.new(0.5, palette.glow),
            ColorSequenceKeypoint.new(1, palette.accent),
        })
        if orbStrokeRef then orbStrokeRef.Color = palette.accent end
        if orb then orb.BackgroundColor3 = palette.panel end
        -- Splash is normally gone by the time themes are changed, but keep its
        -- colors linked to the selected palette if it is still visible.
        if bootUI.splash and bootUI.splash.Parent then
            bootUI.splash.BackgroundColor3 = palette.leaf
            for _, child in ipairs(bootUI.splash:GetChildren()) do
                if child:IsA("UIGradient") then child.Color = ColorSequence.new(palette.glow, palette.leaf) end
            end
        end
        if bootUI.card and bootUI.card.Parent then
            bootUI.card.BackgroundColor3 = palette.panel
            for _, child in ipairs(bootUI.card:GetChildren()) do
                if child:IsA("UIStroke") then child.Color = palette.glow end
            end
        end
        if bootUI.status then bootUI.status.TextColor3 = palette.text end
        if bootUI.fill then bootUI.fill.BackgroundColor3 = palette.glow end
        if bootUI.track then bootUI.track.BackgroundColor3 = palette.bg end
        -- Buddy is a world model, so update it separately from the ScreenGui tree.
        for _, obj in ipairs(workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("Model") and obj.Name == "MochiBuddy" then
                    for _, part in ipairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            part.Color = palette.accent
                            part.Material = Enum.Material.SmoothPlastic
                        end
                    end
                elseif obj:IsA("BasePart") and obj.Name == "MochiBall" then
                    obj.Color = palette.accent
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end)
        end
        -- The Buddy's hotbar tool and speech bubble live under PlayerGui/Backpack rather than the main window.
        for _, root in ipairs({PG, LP:FindFirstChildOfClass("Backpack")}) do
            if root then
                for _, obj in ipairs(root:GetDescendants()) do
                    pcall(function()
                        if obj:IsA("BasePart") and obj.Name == "Handle" and obj.Parent and obj.Parent.Name == "Mochi Buddy" then
                            obj.Color = palette.accent
                            obj.Material = Enum.Material.SmoothPlastic
                        elseif obj:IsA("BillboardGui") and obj.Name == "MOCHI_BuddyTag" then
                            for _, ui in ipairs(obj:GetDescendants()) do
                                if ui:IsA("TextLabel") then ui.TextColor3 = palette.text end
                                if ui:IsA("Frame") then ui.BackgroundColor3 = palette.panel end
                                if ui:IsA("UIStroke") then ui.Color = palette.accent end
                            end
                        end
                    end)
                end
            end
        end
        accentStatus.Text = "Theme: " .. name
        accentStatus.TextColor3 = palette.accent
        notify(name .. " theme applied.", "good")
    end

    for _, themeName in ipairs({"Matcha Green", "Soft Matcha", "Deep Matcha", "Mint Cream", "Ocean Blue", "Lavender", "Rose", "Amber", "Midnight Cyan", "Neon Violet", "Cherry Soda"}) do
        local selectedName = themeName
        button(themeCard, selectedName, function()
            applyTheme(selectedName, palettes[selectedName])
        end, palettes[selectedName].accent, 27)
    end

    label(themeCard, "Presets recolor the full interface, loading screen, logo, buttons, and Mochi Buddy using coordinated shades.", 10, theme.muted)

    local perfCard = section(settingsScroll, "Performance mode")
    label(perfCard, "Pauses menu animations, lowers local detail, disables particles and post-effects, and turns off dynamic shadows. Texture resolution itself is controlled by Roblox and cannot be forced by Lua.", 10, theme.muted)
    local perfStatus = label(perfCard, "Performance mode: Off", 10, theme.good)
    local savedVisuals = {}
    local savedPerfLighting = nil
    local perfConnections = {}

    local function rememberAndSet(obj, property, value)
        local ok, original = pcall(function() return obj[property] end)
        if ok then
            savedVisuals[#savedVisuals + 1] = {obj=obj, prop=property, value=original}
            pcall(function() obj[property] = value end)
        end
    end

    local function reduceDetail()
        table.clear(savedVisuals)
        -- Hide surface decals/textures and mesh texture maps where the engine permits.
        local allWorldObjects = workspace:GetDescendants()
        for index, obj in ipairs(allWorldObjects) do
            if obj:IsA("Decal") or obj:IsA("Texture") then
                rememberAndSet(obj, "Transparency", 1)
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                rememberAndSet(obj, "Enabled", false)
            elseif obj:IsA("MeshPart") then
                rememberAndSet(obj, "TextureID", "")
                rememberAndSet(obj, "RenderFidelity", Enum.RenderFidelity.Performance)
            elseif obj:IsA("BasePart") then
                -- Smooth materials are cheaper to render than detailed material surfaces.
                rememberAndSet(obj, "Material", Enum.Material.SmoothPlastic)
            elseif obj:IsA("SurfaceAppearance") then
                rememberAndSet(obj, "ColorMap", "")
                rememberAndSet(obj, "NormalMap", "")
                rememberAndSet(obj, "RoughnessMap", "")
                rememberAndSet(obj, "MetalnessMap", "")
            end
            if index % 300 == 0 then task.wait() end
        end
        for _, rootInstance in ipairs({Lighting, workspace.CurrentCamera}) do
            if rootInstance then
                for _, obj in ipairs(rootInstance:GetDescendants()) do
                    if obj:IsA("PostEffect") then
                        rememberAndSet(obj, "Enabled", false)
                    end
                end
            end
        end
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then rememberAndSet(terrain, "Decoration", false) end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Clouds") then rememberAndSet(obj, "Enabled", false) end
        end
        savedPerfLighting = {
            GlobalShadows = Lighting.GlobalShadows,
            EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        }
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.EnvironmentDiffuseScale = 0.25
            Lighting.EnvironmentSpecularScale = 0
        end)
    end

    local function restoreDetail()
        for _, entry in ipairs(savedVisuals) do
            if entry.obj and entry.obj.Parent then
                pcall(function() entry.obj[entry.prop] = entry.value end)
            end
        end
        table.clear(savedVisuals)
        if savedPerfLighting then
            for property, value in pairs(savedPerfLighting) do
                pcall(function() Lighting[property] = value end)
            end
            savedPerfLighting = nil
        end
    end

    button(perfCard, "Toggle performance mode", function()
        performanceMode = not performanceMode
        perfStatus.Text = "Performance mode: " .. (performanceMode and "On" or "Off")
        perfStatus.TextColor3 = performanceMode and theme.good or theme.muted

        if performanceMode then
            for _, t in ipairs(decorativeTweens) do pcall(function() t:Pause() end) end
            if strokeGradient then strokeGradient.Rotation = 0 end
            if orbStrokeRef then orbStrokeRef.Transparency = 0.2 end
            reduceDetail()
            notify("Performance mode on: animations/effects paused and local detail reduced.", "good")
        else
            restoreDetail()
            if not fx.on then
                for _, effect in ipairs(Lighting:GetChildren()) do
                    if effect.Name == "MOCHI_LocalColorProfile"
                        or effect.Name == "MOCHI_LocalBloomProfile"
                        or effect.Name == "MOCHI_LocalSunRaysProfile" then
                        pcall(function() effect.Enabled = true end)
                    end
                end
            end
            for _, t in ipairs(decorativeTweens) do pcall(function() t:Play() end) end
            notify("Performance mode off: saved visual settings restored.", "good")
        end
    end, theme.panel2, 27)

    local infoCard = section(settingsScroll, "Quick settings")
    label(infoCard, "The Visuals tab has Vibrant, Cinematic, Realistic, Neon, and Warm Sunset visual profiles. The Player tab has numeric speed, jump, and flight controls up to 999999.", 10, theme.muted)
end

-- ================================================================
-- PART 22: THE FLOATING ORB, DRAGGING, RESIZING AND CLOSING
-- ================================================================
do
    -- The little round button that stays on screen when the window is hidden.
    orb = make("TextButton", {
        Name = "MOCHIOrb",
        Text = "",
        BackgroundColor3 = theme.panel,
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(0, 16, 0.5, -24),
        Visible = false,
        Active = true,
        AutoButtonColor = false,
    }, gui)
    round(orb, 24)
    orbScale = make("UIScale", {Scale = 0}, orb)
    orbStrokeRef = outline(orb, theme.accent, 2, 0.2)
    -- The orb's border slowly fades in and out so it's easy to see.
    orbPulseTween = registerDecorativeTween(TweenService:Create(
        orbStrokeRef,
        TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Transparency = 0.75}
    ))
    if not performanceMode then orbPulseTween:Play() end
    makeLogo(orb, 32, UDim2.new(0.5, 0, 0.5, 0), Vector2.new(0.5, 0.5))

    -- toggleMenu: opens the window (show = true) or hides it (show = false).
    -- With no answer, it flips to the opposite of what it is now.
    toggleMenu = function(show)
        if show == nil then show = not menuOpen end
        if show == menuOpen then return end
        if not show and restoreExec then restoreExec(false) end
        menuOpen = show
        if show then
            main.Visible = true
            mainScale.Scale = 0.86
            tween(mainScale, {Scale = 1}, 0.4, Enum.EasingStyle.Back) -- pop open
            if orbScale then tween(orbScale, {Scale = 0.85}, 0.2) end
        else
            local tw = tween(mainScale, {Scale = 0.86}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            if tw then
                tw.Completed:Connect(function()
                    if not menuOpen then main.Visible = false end
                end)
            elseif not menuOpen then
                main.Visible = false
            end
            if orbScale then tween(orbScale, {Scale = 1}, 0.35, Enum.EasingStyle.Back) end
        end
    end

    minimizeButton.Activated:Connect(function()
        toggleMenu(false)
    end)

    -- Tapping the orb opens the window. But if you were just dragging the orb, don't open.
    orb.Activated:Connect(function()
        if orbMoved then return end
        toggleMenu()
    end)

    orb.MouseEnter:Connect(function()
        if ready then tween(orbScale, {Scale = 1.12}, 0.18, Enum.EasingStyle.Back) end
    end)
    orb.MouseLeave:Connect(function()
        if ready then tween(orbScale, {Scale = menuOpen and 0.85 or 1}, 0.2) end
    end)

    -- On a computer, RightShift hides and shows the window.
    track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not ready then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            toggleMenu()
        end
    end))

    -- These remember if we are dragging the window, resizing it, or dragging the orb.
    local dragging, dragStart, startPosition = false, nil, nil
    local resizing, resizeStart, sizeStart = false, nil, nil
    local orbDragging, orbStart, orbPosition = false, nil, nil

    -- Press on the header = start dragging the window.
    header.InputBegan:Connect(function(input)
        if not ready then return end
        if isPress(input) then
            if restoreExec then restoreExec(true) end
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end)

    -- The ◢ handle in the bottom-right corner for resizing.
    local resizeHandle = make("TextButton", {
        Name = "ResizeHandle",
        Text = "◢",
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextColor3 = theme.accent,
        BackgroundColor3 = theme.panel,
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -24, 1, -24),
        ZIndex = 10,
    }, main)
    round(resizeHandle, 9)

    resizeHandle.InputBegan:Connect(function(input)
        if not ready then return end
        if isPress(input) then
            execSaved = nil
            resizing = true
            resizeStart = input.Position
            sizeStart = main.AbsoluteSize
        end
    end)

    orb.InputBegan:Connect(function(input)
        if isPress(input) then
            orbDragging = true
            orbMoved = false
            orbStart = input.Position
            orbPosition = orb.Position
            if ready then tween(orbScale, {Scale = 0.92}, 0.1) end
        end
    end)

    -- While your finger or mouse moves, update whatever we are dragging.
    track(UserInputService.InputChanged:Connect(function(input)
        local moving = input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        if not moving then return end

        if dragging and dragStart then
            -- delta = how far you moved since you first pressed.
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end

        if resizing and resizeStart then
            local delta = input.Position - resizeStart
            main.Size = UDim2.fromOffset(
                math.clamp(sizeStart.X + delta.X, 250, 850),
                math.clamp(sizeStart.Y + delta.Y, 170, 700)
            )
        end

        if orbDragging and orbStart then
            local delta = input.Position - orbStart
            if delta.Magnitude > 6 then orbMoved = true end -- moved more than 6 pixels = it's a drag, not a tap
            orb.Position = UDim2.new(
                orbPosition.X.Scale, orbPosition.X.Offset + delta.X,
                orbPosition.Y.Scale, orbPosition.Y.Offset + delta.Y
            )
        end
    end))

    -- When you let go, stop dragging everything.
    track(UserInputService.InputEnded:Connect(function(input)
        if isPress(input) then
            if orbDragging and ready then
                tween(orbScale, {Scale = menuOpen and 0.85 or 1}, 0.25, Enum.EasingStyle.Back)
            end
            dragging = false
            resizing = false
            orbDragging = false
            task.defer(function() orbMoved = false end)
        end
    end))

    -- closeAll: shuts MOCHI down for good.
    -- First it turns off everything that is running, so nothing is left behind.
    local function closeAll()
        pcall(function()
            if api.setChat then api.setChat(false) end
        end)
        for _, c in ipairs(conns) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(conns)
        pcall(healOff)
        pcall(invisOff)
        pcall(stopFly)
        pcall(stopFling)
        pcall(stopFreecam)
        pcall(setFullbright, false)
        pcall(function() light.customBrightness = nil; updateLightLoop() end)
        pcall(setEffectsOff, false)
        pcall(clearTracking)
        pcall(clearSpectate)
        pcall(deleteBuddy)

        -- Shrink the window away, then delete the whole screen.
        task.spawn(function()
            pcall(function()
                orb.Visible = false
                tween(mainScale, {Scale = 0.8}, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                task.wait(0.24)
            end)
            gui:Destroy()
        end)
    end

    -- The ✕ button asks "Sure?" first. You must tap it again within 2 seconds.
    local confirmingClose = false
    closeButton.MouseEnter:Connect(function()
        tween(closeButton, {TextColor3 = Color3.fromRGB(255, 160, 150)}, 0.15)
    end)
    closeButton.MouseLeave:Connect(function()
        tween(closeButton, {TextColor3 = theme.danger}, 0.2)
    end)
    closeButton.Activated:Connect(function()
        if confirmingClose then
            closeAll()
            return
        end
        confirmingClose = true
        closeButton.Text = "Sure?"
        closeButton.TextSize = 11
        task.delay(2, function()
            if closeButton.Parent then
                confirmingClose = false
                closeButton.Text = "✕"
                closeButton.TextSize = 14
            end
        end)
    end)
end

-- ================================================================
-- PART 22: STARTING UP
-- Finish the boot splash only after the interface is ready.
-- ================================================================
local bootRemaining = bootUI.minimumDuration - (os.clock() - bootUI.startedAt)
if bootRemaining > 0 then task.wait(bootRemaining) end
tween(bootUI.fill, {Size = UDim2.new(1, 0, 1, 0)}, 0.35)
task.wait(0.65)
if bootUI.splash and bootUI.splash.Parent then bootUI.splash:Destroy() end
refreshPlayers()
showPage("Home", true)
applyMovement()
setFlyUI(false)

menuOpen = true
main.Visible = true
orb.Visible = true
mainScale.Scale = 1
orbScale.Scale = 0.85
ready = true
notify("MOCHI loaded. RightShift hides or shows the panel.", "good")
print("MOCHI loaded.")

-- ================================================================
-- THE END OF THE xpcall FROM THE TOP OF THE FILE
-- If anything above crashed, this little function catches the
-- error and adds a "traceback" (a trail showing where it broke).
-- ================================================================
end, function(e)
    return tostring(e) .. "\n" .. debug.traceback("", 2)
end)

-- If something broke, show a message in the console and the red box.
if not ok then
    warn("[MOCHI] " .. tostring(err))
    showFatal(err)
end
