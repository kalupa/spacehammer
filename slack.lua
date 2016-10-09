-- Improving Slack
-- as "Apps" modal lets you switch to Slack, and shows "Jump to" dialog box

-- Slack doesn't allow scrolling thread by using only keyboard -
--  this module introduces C-j, C-k bindings for scrolling
--  C-g - takes you to the end of thread

modalA:bind("", "s", function()
              hs.application.launchOrFocus("Slack")
              local app = hs.application.find("Slack")
              if app then
                app:activate()
                hs.timer.doAfter(0.2, highlighActiveWin)
                hs.eventtap.keyStroke({"cmd"}, "k")
                app:unhide()
              end

              exitModals()
end)

-- to correctly scroll the window, mouse pointer should be within the frame (otherwise it would scroll other windows that do not belong to Slack)
function setMouseCursorOnSlack()
  local sf = hs.application.find("Slack"):findWindow("Slack"):frame()
  local desired_point = hs.geometry.point(sf._x + sf._w - (sf._w * 0.10), sf._y + sf._h - (sf._h * 0.10)) 
  hs.mouse.setAbsolutePosition(desired_point)
end

hs.window.filter.new('Slack')
  :subscribe(hs.window.filter.windowFocused,function()
               -- Slack on focus
               hs.fnutils.each(slackLocalKeys, function(k) k:enable() end)
               slackJumpToEnd = hs.hotkey.bind({"ctrl"}, "g",
                 function()
                   setMouseCursorOnSlack()
                   hs.eventtap.scrollWheel({0, -5000}, {}) -- from my experience this number is big enough to take you to the end of thread
                 end, nil, nil)

               slackInsertEmoji = hs.hotkey.bind({"cmd"}, "i",
                 function()
                   hs.eventtap.keyStroke({"cmd", "shift"}, "\\")
                 end, nil, nil)
            end)
:subscribe(hs.window.filter.windowUnfocused,function()
             -- Slack lost focus
             hs.fnutils.each(slackLocalKeys, function(k) k:disable() end)
             slackJumpToEnd:disable()
             slackInsertEmoji:disable()
          end)

slackLocalKeys = {}
slackJumpToEnd = {}

-- when Slack is active ...
hs.fnutils.each({{key = "j", dir = -3}, {key = "k", dir = 3}}, function(k)
    function scrollFn()
      setMouseCursorOnSlack()
      hs.eventtap.scrollWheel({0, k.dir}, {})
    end
    -- pressing C-j, C-k should force to scroll discussion thread window up and down
    slackLocalKeys[{key = k, mod = "ctrl"}] = hs.hotkey.new({"ctrl"}, k.key, scrollFn, nil, scrollFn)

    function jumpItem()
      setMouseCursorOnSlack()
      if k.key == "j" then
        hs.eventtap.keyStroke({"alt"}, "down")
      elseif k.key == "k" then
        hs.eventtap.keyStroke({"alt"}, "up")
      end
    end

    -- pressing M-j, M-k for "previous/next item in the list"
    slackLocalKeys[{key = k, mod = "alt"}] = hs.hotkey.new({"alt"}, k.key, jumpItem, nil, jumpItem)
end)