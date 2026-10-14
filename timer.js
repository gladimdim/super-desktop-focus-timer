.pragma library

// Saved values (sd.values):
//   current: {label, minutes, startedAt, endsAt} while a timer runs, else absent.
//            Set by the start popup, cleared by the top-bar item when it ends.
//   alert:   {label, minutes, finishedAt} from the moment a timer ends until
//            the user clicks the flashing button. Owned by the top-bar item.
//   history: [{id, label, minutes, finishedAt}], newest last. The top-bar item
//            appends, the history popup removes.

// A plain JS copy of a saved object (or null).
function obj(v) {
    if (!v || typeof v !== "object") return null
    return Object.assign({}, v)
}

// A JS array copy of a saved list. (Before SUPER DESKTOP 1.6 a saved list came
// back as a Qt list, not a JS array.)
function list(v) {
    if (!v || typeof v.length !== "number") return []
    var out = []
    for (var i = 0; i < v.length; i++) out.push(Object.assign({}, v[i]))
    return out
}

function history(values) { return list(values && values.history) }

function newId() {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 7)
}

function pad(n) { return String(n).padStart(2, "0") }

// Seconds → "4:59", "1:02:03".
function clock(secs) {
    secs = Math.max(0, Math.ceil(secs))
    var h = Math.floor(secs / 3600), m = Math.floor(secs / 60) % 60, s = secs % 60
    return h > 0 ? h + ":" + pad(m) + ":" + pad(s) : m + ":" + pad(s)
}

// Minutes → "25 min", "1 h 30 min", "90 s".
function lengthText(minutes) {
    var secs = Math.round(minutes * 60)
    if (secs < 60) return secs + " s"
    if (secs < 3600) return (secs % 60 ? (secs / 60).toFixed(1) : secs / 60) + " min"
    var mins = Math.round(secs / 60)
    var h = Math.floor(mins / 60), m = mins % 60
    return h + " h" + (m ? " " + m + " min" : "")
}

// Parses the custom-length field: minutes, e.g. "40", "7.5", "1:30" (h:mm).
// Returns minutes or NaN.
function parseMinutes(text) {
    var s = String(text).trim().replace(",", ".")
    var hm = /^(\d{1,2}):(\d{2})$/.exec(s)
    var m = hm ? (+hm[1]) * 60 + (+hm[2]) : (/^\d+(\.\d+)?$/.test(s) ? parseFloat(s) : NaN)
    if (isNaN(m) || m <= 0 || m > 24 * 60) return NaN
    return m
}

function timeText(d) { return pad(d.getHours()) + ":" + pad(d.getMinutes()) }

// "Today 14:30", "Yesterday 09:00", "Mon 09:00", "2026-10-02 09:00".
function whenText(at) {
    var d = new Date(at)
    var now = new Date()
    var today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    var day = new Date(d.getFullYear(), d.getMonth(), d.getDate())
    var diff = Math.round((today - day) / 86400000)
    if (diff === 0) return "Today " + timeText(d)
    if (diff === 1) return "Yesterday " + timeText(d)
    if (diff > 1 && diff < 7)
        return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][d.getDay()] + " " + timeText(d)
    return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) + " " + timeText(d)
}

// ── Colors that stay readable in every Omarchy theme ──────────────────────

function rgb(color) {
    var s = String(color)
    if (s.length === 9) s = "#" + s.slice(3)   // #aarrggbb
    var m = /^#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i.exec(s)
    return m ? [parseInt(m[1], 16), parseInt(m[2], 16), parseInt(m[3], 16)] : [128, 128, 128]
}

function luminance(color) {
    var c = rgb(color).map(function(v) {
        v /= 255
        return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
    })
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
}

function contrast(a, b) {
    var la = luminance(a), lb = luminance(b)
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05)
}

function mix(a, b, t) {
    var x = rgb(a), y = rgb(b)
    return "#" + [0, 1, 2].map(function(i) {
        return Math.round(x[i] + (y[i] - x[i]) * t).toString(16).padStart(2, "0")
    }).join("")
}

// Secondary text: foreground faded toward background, never below 4.5:1.
function soft(theme, t) {
    for (var f = t; f > 0; f -= 0.05) {
        var c = mix(theme.foreground, theme.background, f)
        if (contrast(c, theme.background) >= 4.5) return c
    }
    return theme.foreground
}

// The first theme color in `names` that reads on the background, else foreground.
function readable(theme, names, min) {
    for (var i = 0; i < names.length; i++) {
        var c = theme[names[i]]
        if (c && contrast(c, theme.background) >= min) return c
    }
    return theme.foreground
}

// Black or white text, whichever reads better on `bg`.
function onColor(theme, bg) {
    return contrast(theme.background, bg) >= contrast(theme.foreground, bg) ? theme.background : theme.foreground
}
