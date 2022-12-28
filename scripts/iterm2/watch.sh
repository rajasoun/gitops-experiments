#!/usr/bin/osascript

tell application "iTerm"
    activate
    select first window
    
    # # Create new tab
    # tell current window
    #     create tab with default profile
    # end tell
    
    # Split pane
    tell current session of current window
        # split vertically with default profile
        split horizontally with default profile
        # split horizontally with default profile
    end tell
    
    # Exec commands
    tell first session of current tab of current window
        write text "watch flux get kustomizations"
    end tell
    tell second session of current tab of current window
        write text "flux logs --all-namespaces --follow --tail=10"
    end tell
    # tell third session of current tab of current window
    #     write text "watch flux get all --all-namespaces"
    # end tell
end tell






