import urllib.parse

# ---------------------------------------------------------
# MEDIA & APP CONTROLS (Using Android Deep Links)
# ---------------------------------------------------------

def play_youtube(page, search_query):
    """Opens the YouTube app and searches for a specific video or song."""
    try:
        # Format the text for a URL (e.g., "Iron Man" -> "Iron+Man")
        query_formatted = urllib.parse.quote_plus(search_query)
        url = f"https://www.youtube.com/results?search_query={query_formatted}"
        
        # Flet's launch_url tells Android to open this in the native YouTube app
        page.launch_url(url)
        return f"Opening YouTube for: {search_query}"
    except Exception as e:
        return f"⚠️ Failed to open YouTube: {str(e)}"


def play_spotify(page, search_query):
    """Opens Spotify and searches for a track."""
    try:
        query_formatted = urllib.parse.quote(search_query)
        # The 'spotify:' prefix forces Android to open the Spotify app, not the browser
        url = f"spotify:search:{query_formatted}"
        page.launch_url(url)
        return f"Searching Spotify for: {search_query}"
    except Exception as e:
        return f"⚠️ Failed to open Spotify: {str(e)}"


def open_whatsapp(page, phone_number=""):
    """Opens WhatsApp. Can jump straight to a specific chat if a number is provided."""
    try:
        if phone_number:
            # Ensure number has country code, e.g., +91
            url = f"whatsapp://send?phone={phone_number}"
        else:
            url = "whatsapp://app"
        page.launch_url(url)
        return "Opening WhatsApp."
    except Exception as e:
        return f"⚠️ Failed to open WhatsApp: {str(e)}"

# ---------------------------------------------------------
# PHONE & CALLING CONTROLS
# ---------------------------------------------------------

def call_contact(page, phone_number):
    """Opens the native Android dialer with the number pre-filled."""
    try:
        # The 'tel:' prefix triggers the Android phone dialer
        url = f"tel:{phone_number}"
        page.launch_url(url)
        return f"Dialing {phone_number}..."
    except Exception as e:
        return f"⚠️ Failed to initiate call: {str(e)}"

# ---------------------------------------------------------
# HARDWARE TOGGLES (Torch, WiFi)
# ---------------------------------------------------------
# Note: On Android 15, direct background toggling of hardware via Python 
# requires complex Pyjnius Java wrapping. For V1.0, we route to settings.

def open_wifi_settings(page):
    """Opens the Android WiFi settings panel."""
    try:
        # Intent to open settings
        page.launch_url("intent:#Intent;action=android.settings.WIFI_SETTINGS;end")
        return "Opening WiFi Settings."
    except Exception:
        return "⚠️ Could not access hardware settings."
      
