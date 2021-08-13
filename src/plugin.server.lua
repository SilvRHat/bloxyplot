-- Bloxy Plot Plugin
-- A 3D Plotting tool extension for Roblox Development
-- Version 1.0.3 (STAGE: In development)

-- Dev // SilvRHat
-- Documentation // https://github.com/SilvRHat/bloxyplot/docs
-- GitHub // https://github.com/SilvRHat/bloxyplot


-- DEPENDENCIES //
local selection = game:GetService('Selection')


-- CONST
local VIS_BUTTON_UID = "BLOXYPLOT_VIS_BUTTON"
local VIS_WIDGET_UID = "BLOXYPLOT_MAIN_UI"


-- UI //
-- Main Button
local toolbar = plugin:CreateToolbar('BloxyPlot')
local vis_toggle = toolbar:CreateButton(
    VIS_BUTTON_UID,
    "Easily visualize bloxyplot lines and subplots",
    "",
    "Legend"
)

-- Main Window
local widgetPreset = DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Left,
    false,      -- Initial state
    false,      -- Override previous state
    500, 500,   -- Default width, height
    100, 100    -- Minimum width, height
)

local main = plugin:CreateDockWidgetPluginGui(VIS_WIDGET_UID, widgetPreset)
main.Title = 'BloxyPlot'

local pluginDir = script.Parent
local premadeMainUI = pluginDir:WaitForChild('bloxyplot_ui')
premadeMainUI.Parent = main


-- Connect
vis_toggle.Click:Connect(function ()
    main.Enabled = not main.Enabled
end)