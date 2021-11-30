-- Main
import XMonad
import System.IO
import System.Exit
import qualified XMonad.StackSet as W

-- Actions
import XMonad.Actions.GridSelect
import XMonad.Actions.CycleWS (Direction1D(..), moveTo, shiftTo, WSType(..), nextScreen, prevScreen, emptyWS, nextWS, shiftToNext, shiftToPrev)
import XMonad.Actions.SpawnOn
import XMonad.Actions.MouseResize
import XMonad.Actions.WithAll (sinkAll, killAll)
import XMonad.Actions.CopyWindow (kill1)

-- Data
import Data.Semigroup
import Data.Monoid
import Data.Maybe (fromJust)
import Data.Maybe (isJust)
import qualified Data.Map        as M

-- Hooks
import XMonad.Hooks.DynamicProperty
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks (avoidStruts, docksEventHook, manageDocks, ToggleStruts(..))
import XMonad.Hooks.SetWMName
import XMonad.Hooks.ManageHelpers (isFullscreen, doFullFloat, isDialog, doCenterFloat, doRectFloat)

-- Layouts
import XMonad.Layout.Accordion
import XMonad.Layout.GridVariants (Grid(Grid))
import XMonad.Layout.SimplestFloat
import XMonad.Layout.Spiral
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import Data.List
import XMonad.Layout.IndependentScreens

--Layouts modifers
import XMonad.Layout.LayoutModifier
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiToggle (mkToggle, single, EOT(EOT), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed
import XMonad.Layout.Simplest
import XMonad.Layout.Spacing
import XMonad.Layout.SubLayouts
import XMonad.Layout.WindowNavigation
import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))
import qualified XMonad.Layout.MultiToggle as MT (Toggle(..))
import XMonad.Layout.IndependentScreens
import XMonad.Layout.Gaps
    ( Direction2D(D, L, R, U),
      gaps,
      setGaps,
      GapMessage(DecGap, ToggleGaps, IncGap) )

-- Utilities
import XMonad.Util.Dmenu
import XMonad.Util.EZConfig(additionalKeysP)
import XMonad.Util.NamedScratchpad
import XMonad.Util.Scratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce
import Graphics.X11.ExtraTypes.XF86

import XMonad.Hooks.StatusBar.PP

import qualified Graphics.X11
import qualified Graphics.X11.Xinerama
import Data.List (intercalate)


------------------------------------------------------------------------
-- Main strings
------------------------------------------------------------------------
myFont :: String
myFont = "xft:SauceCodePro Nerd Font Mono:regular:size=9:antialias=true:hinting=true"

myTerminal :: String
myTerminal = "alacritty"        -- Default terminal

myModMask :: KeyMask
myModMask = mod4Mask            -- Super Key (--mod4Mask= super key --mod1Mask= alt key --controlMask= ctrl key --shiftMask= shift key)

myBrowser :: String
myBrowser = "firefox"           -- Default browser

myBorderWidth :: Dimension
myBorderWidth   = 0             -- Window border

myNormColor :: String
myNormColor   = "#282c34"       -- Border colors for windows

myFocusColor :: String
myFocusColor  = "#73d0ff"       -- Border colors of focused windows

------------------------------------------------------------------------
-- Colors for tabs
------------------------------------------------------------------------
myTabTheme = def { fontName          = myFont
               , activeColor         = "#73d0ff"
               , inactiveColor       = "#191e2a"
               , activeBorderColor   = "#73d0ff"
               , inactiveBorderColor = "#191e2a"
               , activeTextColor     = "#191e2a"
               , inactiveTextColor   = "#c7c7c7"
               }


------------------------------------------------------------------------
-- Space between Tiling Windows
------------------------------------------------------------------------
mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border 40 10 10 10) True (Border 10 10 10 10) True


------------------------------------------------------------------------
-- Layout Hook
------------------------------------------------------------------------
myLayoutHook = avoidStruts $ mouseResize $ windowArrange $ T.toggleLayouts full
               $ mkToggle (NBFULL ?? NOBORDERS ?? MIRROR ?? EOT) myDefaultLayout
             where
               myDefaultLayout =      withBorder myBorderWidth tall
                                  ||| grid
                                  ||| full
                                  ||| mirror


------------------------------------------------------------------------
-- Tiling Layouts
------------------------------------------------------------------------
tall     = renamed [Replace " <fc=#95e6cb><fn=2> \61449 </fn>Tall</fc>"]
           $ smartBorders
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 8
           $ mySpacing 5
           $ ResizableTall 1 (3/100) (1/2) []
grid     = renamed [Replace " <fc=#95e6cb><fn=2> \61449 </fn>Grid</fc>"]
           $ smartBorders
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 12
           $ mySpacing 5
           $ mkToggle (single MIRROR)
           $ Grid (16/10)   
mirror     = renamed [Replace " <fc=#95e6cb><fn=2> \61449 </fn>Mirror</fc>"]
           $ smartBorders
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (smartBorders Simplest)
           $ limitWindows 6
           $ mySpacing 5
           $ Mirror  
           $ ResizableTall 1 (3/100) (1/2) []            
full     = renamed [Replace " <fc=#95e6cb><fn=2> \61449 </fn>Full</fc>"]
           $ Full              


------------------------------------------------------------------------
-- Workspaces
------------------------------------------------------------------------
xmobarEscape :: String -> String
xmobarEscape = concatMap doubleLts
  where
    doubleLts 'a' = "<<"
    doubleLts x = [x]



myWorkspaces :: [String]
myWorkspaces = clickable . (map xmobarEscape)
   $ [" <fn=5>\61713</fn> ", " <fn=5>\61713</fn> ", " <fn=5>\61713</fn> ", " <fn=5>\61713</fn> ", " <fn=5>\61713</fn> "]
 where
   clickable l = ["<action=xdotool key super+" ++ show (i) ++ "> " ++ ws ++ "</action>" | (i, ws) <- zip [1 .. 5] l]
-- myWorkspaces = withScreens 2 [" <fn=5>\61713</fn> ", " <fn=5>\61713</fn> ", " <fn=5>\61713</fn> ", " <fn=5>\61713</fn> ", " <fn=5>\61713</fn> "]


windowCount :: X (Maybe String)
windowCount = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset


------------------------------------------------------------------------
-- Scratch Pads
------------------------------------------------------------------------
zoomDimensions = (customFloating (W.RationalRect (3/4) (1/12) (1/4) (1/3)))

myScratchPads :: [NamedScratchpad]
myScratchPads =
  [
      NS "discord"              "discord"              (appName =? "discord")                   (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
    , NS "spotify"              "spotify"              (appName =? "spotify")                   (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
    , NS "nautilus"             "nautilus"             (className =? "Org.gnome.Nautilus")      (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
    , NS "ncmpcpp"              launchMocp             (title =? "ncmpcpp")                     (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
    , NS "whatsapp-for-linux"   "whatsapp-for-linux"   (appName =? "whatsapp-for-linux")        (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
    , NS "terminal"             launchTerminal         (title =? "scratchpad")                  (customFloating $ W.RationalRect 0.15 0.15 0.7 0.7)
    , NS "zoom" "zoom" (fmap ("Zoom Meeting ID" `isInfixOf`) title) zoomDimensions
  ]
  where
    launchMocp     = myTerminal ++ " -t ncmpcpp -e ncmpcpp"
    launchTerminal = myTerminal ++ " -t scratchpad"


-- Key bindings. Add, modify or remove key bindings here.

rofi_launcher = spawn "rofi -no-lazy-grab -show drun -modi drun -theme kde-runner"



myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $

    -- launch a terminal
    [ ((modm,               xK_Return     ), spawn myTerminal)

    -- lock screen
    , ((modm,               xK_Escape     ), spawn "betterlockscreen -l dim -- --time-str='%H:%M'")

    -- launch rofi
    , ((modm,               xK_s     ), rofi_launcher)

    -- close focused window
    , ((modm,               xK_q     ), kill)

     -- Rotate through the available layout algorithms
    , ((modm,               xK_space ), sendMessage NextLayout)

    --  Reset the layouts on the current workspace to default
    , ((modm .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf)

    -- Resize viewed windows to the correct size
    , ((modm,               xK_n     ), refresh)


    -- Move focus to the next window
    , ((modm,               xK_j     ), windows W.focusDown)

    -- Move focus to the previous window
    , ((modm,               xK_k     ), windows W.focusUp  )

    -- Move focus to the master window
    , ((modm,               xK_m     ), windows W.focusMaster  )

    -- Swap the focused window and the master window
    , ((modm,               xK_Left  ), windows W.swapMaster)

    -- Swap the focused window with the next window
    , ((modm .|. shiftMask, xK_Down     ), windows W.swapDown  )

    -- Swap the focused window with the previous window
    , ((modm .|. shiftMask, xK_Up     ), windows W.swapUp    )

    -- Shrink the master area
    , ((mod1Mask,              xK_Left     ), sendMessage Shrink)

    -- Expand the master area
    , ((mod1Mask,               xK_Right     ), sendMessage Expand)

    -- Push window back into tiling
    , ((modm,               xK_t     ), withFocused $ windows . W.sink)

    -- Increment the number of windows in the master area
    , ((modm              , xK_comma ), sendMessage (IncMasterN 1))

    -- Deincrement the number of windows in the master area
    , ((modm              , xK_period), sendMessage (IncMasterN (-1)))

    -- Quit xmonad
    , ((modm .|. shiftMask, xK_q     ), spawn "~/bin/powermenu.sh")
    ]
    ++

    --
    -- mod-[1..9], Switch to workspace N
    -- mod-shift-[1..9], Move client to workspace N
    --
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++

    --
    -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
    --
    [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [1, 0]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

------------------------------------------------------------------------
-- Moving between WS
------------------------------------------------------------------------
      where nonNSP          = WSIs (return (\ws -> W.tag ws /= "NSP"))
            nonEmptyNonNSP  = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "NSP"))


------------------------------------------------------------------------
-- Floats
------------------------------------------------------------------------

myManageHook :: XMonad.Query (Data.Monoid.Endo WindowSet)
myManageHook = composeAll
     [ className =? "confirm"                           --> doFloat
     , className =? "file_progress"                     --> doFloat
     , resource  =? "desktop_window"                    --> doIgnore
     , className =? "MEGAsync"                          --> doFloat
     , className =? "mpv"                               --> doCenterFloat
     , className =? "Gthumb"                            --> doCenterFloat
     , className =? "Ristretto"                         --> doCenterFloat
     , className =? "feh"                               --> doCenterFloat
     , className =? "Galculator"                        --> doCenterFloat
     , className =? "Gcolor3"                           --> doFloat
     , className =? "dialog"                            --> doFloat
     , className =? "Downloads"                         --> doFloat
     , className =? "Save As..."                        --> doFloat
     , className =? "Xfce4-appfinder"                   --> doFloat
     , className =? "Org.gnome.NautilusPreviewer"       --> doRectFloat (W.RationalRect 0.15 0.15 0.7 0.7)
     , className =? "Thunar"                            --> doRectFloat (W.RationalRect 0.15 0.15 0.7 0.7)
     , className =? "Sublime_merge"                     --> doRectFloat (W.RationalRect 0.15 0.15 0.7 0.7)
     , isFullscreen -->  doFullFloat
     , isDialog --> doCenterFloat
     , className =? "zoom"                              --> zoomDimensions
     ] <+> namedScratchpadManageHook myScratchPads
     

myHandleEventHook :: Event -> X All
myHandleEventHook = dynamicPropertyChange "WM_NAME" (title =? "Spotify" --> floating)
        where floating = doRectFloat (W.RationalRect 0.15 0.15 0.7 0.7)


------------------------------------------------------------------------
-- Startup Hooks
------------------------------------------------------------------------
myStartupHook = do
    spawnOnce "$HOME/.xmonad/scripts/autostart.sh" 
    spawnOnce "picom --experimental-backend &"
--  spawnOnce "mpd &"
    spawnOnce "echo 0 | sudo tee -a /sys/module/hid_apple/parameters/fnmode &"
--  spawnOnce "sleep 5 && conky -c $HOME/.config/conky/conky.conkyrc &"
    spawnOnce "xrandr --output DP-2 --primary --mode 3840x2160 --right-of HDMI-0 --output HDMI-0 --mode 3840x2160"
--  setWMName "LG3D"
    spawnOnce "feh --bg-scale ~/Pictures/arch-4k.png"
    spawnOnce "trayer --edge top --align right --SetDockType true --transparent true --padding 5 --monitor primary --SetPartialStrut true --expand true --widthtype request --iconspacing 10 --alpha 0 --tint 0x212733 --height 20 --distance 5 --margin 10"
    spawnOnce "~/.local/bin/scripts/launch_polybar"

------------------------------------------------------------------------
-- Main Do
------------------------------------------------------------------------
main :: IO ()
main = do
--        xmproc <- spawnPipe "~/.local/bin/xmobar ~/.xmobarrc"
        xmonad $ ewmh def
                { manageHook = myManageHook <+> manageDocks
                , modMask            = myModMask
                , keys               = myKeys
                , layoutHook         = myLayoutHook
                , workspaces         = myWorkspaces
                , normalBorderColor  = myNormColor
                , focusedBorderColor = myFocusColor
                , terminal           = myTerminal
                , borderWidth        = myBorderWidth
                , startupHook        = myStartupHook
                , handleEventHook    = myHandleEventHook
                }

-- Find app class name
-- xprop | grep WM_CLASS
-- https://xmobar.org/#diskio-disks-args-refreshrate
