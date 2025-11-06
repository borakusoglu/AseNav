--[[
Rock Solid Live Exporter (15 FPS)
This script exports the active sprite as flattened PNG frames to a temp folder.
Fixes fully transparent exports by drawing the correct active frame index.
Runs on a timer at 15 FPS instead of change listeners for predictable cadence.
--]]

if not app.activeSprite then
  return app.alert("Please open a sprite first.")
end

-- Stop any previous instance of this exporter if it's running
if _G.__live_exporter_listeners then
  for _, listener in ipairs(_G.__live_exporter_listeners) do
    pcall(function() app.activeSprite.events:off(listener) end)
  end
  _G.__live_exporter_listeners = nil
end

local tempDir = os.getenv("TMP") or os.getenv("TEMP") or "/tmp"
local FRAMES_DIR = tempDir .. "/aseprite_navigator_frames"

if not app.fs.isDirectory(FRAMES_DIR) then
  app.fs.makeDirectory(FRAMES_DIR)
end

print("Live exporter running. Output folder: " .. FRAMES_DIR)
print("Open AseNav to see the frames.")
print("AseNav Version 1.0.0")

local frameCounter = 1
local timer = nil

local function exportFrame()
  -- Validate active sprite and dimensions
  local sprite = app.activeSprite
  if not sprite or not sprite.width or sprite.width <= 0 or not sprite.height or sprite.height <= 0 then
    return
  end

  -- Use the correct active frame index (fixes fully transparent output)
  local frameNumber = 1
  if app.activeFrame and app.activeFrame.frameNumber then
    frameNumber = app.activeFrame.frameNumber
  end

  -- Create an explicit RGBA image and draw the flattened frame for reliable compositing
  local img = Image(sprite.width, sprite.height, ColorMode.RGBA)
  img:clear() -- ensure transparent background cleared
  img:drawSprite(sprite, frameNumber)

  -- Save as sequential PNG file
  local framePath = string.format("%s/frame_%06d.png", FRAMES_DIR, frameCounter)
  img:saveAs(framePath)
  frameCounter = frameCounter + 1
end

-- Use change listener for continuous updates (more reliable than Timer in Aseprite)
local changeListener = app.activeSprite.events:on("change", function()
  local ok, err = pcall(exportFrame)
  if not ok then
    print("Export error: " .. tostring(err))
  end
end)

-- Store listeners globally for cleanup
_G.__live_exporter_listeners = { changeListener }

-- Export an initial frame immediately
exportFrame()
