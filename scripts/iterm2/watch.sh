#!/usr/bin/osascript

tell application "iTerm"
    set isopen to false
    activate

    # Check if window is open else create it
    if not isopen then
        create window with default profile
    end if

    # Open window in full screen
    # tell application "System Events"
    #     keystroke "f" using {control down, command down}
    # end tell

    # Select first tab
    select first window
    
    # Split pane
    tell current session of current window
        # split vertically with default profile
        split horizontally with default profile
        split horizontally with default profile
    end tell
    
    # Exec commands
    tell first session of current tab of current window
        write text "watch flux get kustomizations"
    end tell
    tell second session of current tab of current window
        write text "watch flux get helmreleases --all-namespaces"
    end tell
    tell third session of current tab of current window
        write text "flux logs --all-namespaces --follow --tail=10"
    end tell

    # create tab with current window
    tell current window
        create tab with default profile
    end tell

    tell current session of current tab of current window
        write text "k9s"
    end tell

end tell






