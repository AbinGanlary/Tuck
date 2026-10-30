import Foundation

/// Popular apps the Installed tab checks for. iOS doesn't list installed apps, so Tuck asks about
/// each of these by bundle ID. A wrong or missing ID just never matches.
enum KnownApps {
    static let bundleIds: [String] = [
        // messaging and social
        "net.whatsapp.WhatsApp", "net.whatsapp.WhatsAppSMB", "ph.telegra.Telegraph", "org.whispersystems.signal",
        "com.facebook.Messenger", "com.facebook.Facebook", "com.burbn.instagram", "com.burbn.barcelona",
        "com.atebits.Tweetie2", "com.toyopagroup.picaboo", "com.linkedin.LinkedIn", "com.reddit.Reddit",
        "pinterest", "com.hammerandchisel.discord", "com.zhiliaoapp.musically", "com.truecaller",
        "jp.naver.line", "com.skype.skype", "com.viber",
        // Google
        "com.google.ios.youtube", "com.google.ios.youtubemusic", "com.google.ios.youtubekids", "com.google.Gmail",
        "com.google.GoogleMobile", "com.google.chrome.ios", "com.google.Maps", "com.google.Drive",
        "com.google.photos", "com.google.meetings", "com.google.calendar", "com.google.Keep",
        "com.google.Translate", "com.google.Docs", "com.google.Sheets", "com.google.paisa", "com.google.gemini",
        "com.google.GoogleAuthenticator",
        // Microsoft and work
        "com.microsoft.Office.Outlook", "com.microsoft.skype.teams", "com.microsoft.Office.Word",
        "com.microsoft.Office.Excel", "com.microsoft.Office.Powerpoint", "com.microsoft.skydrive",
        "com.microsoft.azureauthenticator", "com.microsoft.copilot", "com.microsoft.msedge",
        "us.zoom.videomeetings", "com.tinyspeck.chatlyio", "notion.id", "com.getdropbox.Dropbox",
        "com.readdle.smartemail", "com.github.stormbreaker.prod", "com.trello.trello", "com.evernote.iPhone.Evernote",
        "com.adobe.Adobe-Reader",
        // AI
        "com.openai.chat", "com.anthropic.claude", "ai.perplexity.app", "com.deepseek.chat",
        // media
        "com.spotify.client", "com.netflix.Netflix", "com.amazon.aiv.AIVApp", "in.startv.hotstar",
        "com.jio.media.ondemand", "com.disney.disneyplus", "com.shazam.Shazam", "com.soundcloud.TouchApp",
        "com.audible.iphone", "tv.twitch", "com.vimeo", "com.mxtech.mxplayer", "com.gaana.gaana",
        "com.saavn.JioSaavn", "com.amazon.mp3.AmazonMP3",
        // shopping, food, travel, payments (India and global)
        "com.amazon.Amazon", "com.amazon.AmazonIN", "com.flipkart.app", "com.myntra.Myntra",
        "com.grofers.consumer", "com.zomato.zomato", "com.bundl.swiggy", "com.bigbasket.mobileapp",
        "com.zeptonow.consumer", "com.meesho.supply", "com.ajio.ajio", "com.nykaa.app",
        "com.one97.paytm", "com.phonepe.PhonePeApp", "com.dreamplug.cred", "com.mobikwik",
        "com.ubercab.UberClient", "olacabs.com", "com.rapido.passenger", "com.makemytrip.iphone",
        "com.goibibo.goibibo", "com.booking.BookingApp", "com.airbnb.app", "in.redbus.redbusiphone",
        "com.ixigo.train", "com.irctc.rail",
        // tools and other
        "com.duolingo.DuolingoMobile", "com.lastpass.ilastpass", "com.agilebits.onepassword",
        "com.bitwarden.desktop", "com.brave.ios.browser", "org.mozilla.ios.Firefox", "com.opera.OperaTouch",
        "com.yahoo.weather", "com.weather.TWC", "com.strava.stravaride", "com.fitbit.FitbitMobile",
        "com.canva.canvaeditor", "com.burbn.layout", "com.vsco.vscocam", "com.cardify.tinder",
        "com.bumble.app", "com.mojang.minecraftpe",
    ]
}
