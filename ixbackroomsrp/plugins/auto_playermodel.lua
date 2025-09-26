PLUGIN.name = "T-Pose Fix for Helix"
PLUGIN.description = "Fixes any and all playermodel T-Posing"
PLUGIN.author = "Giygas"
PLUGIN.readme = [[
T-Pose Fix for Helix
---
Installation:
- Place auto_playermodel.Lua file into your Schema's Plugin directory.

Just message @iamgiygas on Discord if you need help.
]]
PLUGIN.license = [[
The MIT License (MIT)
Copyright (c) 2024 Giygas
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-- Function to iterate through each player model and perform a function on it
local function processPlayerModels(class)
    if !isstring(class) then return end
        local models = player_manager.AllValidModels()
    
        for _, model in pairs(models) do
            ix.anim.SetModelClass(model, class)
            print("Set model class for", model, "to", class)
        end
    end
    
    -- Call the function to process player models
    processPlayerModels("player")