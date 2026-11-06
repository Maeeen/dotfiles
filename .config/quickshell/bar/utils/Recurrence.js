.pragma library

// Makes the occurrences of Thunderbird calendar events in a date range.
// The rows come from the Thunderbird calendar cache (cache.sqlite): times are µs since the epoch (UTC).
// A "floating" time (all-day events) is the local wall time, kept as if it were UTC.
// Rules: FREQ DAILY, WEEKLY (BYDAY, WKST), MONTHLY and YEARLY (same day of the month), INTERVAL, UNTIL, COUNT,
// and EXDATE, RDATE. Other rule parts (for example MONTHLY;BYDAY=2TU) are not used.

const DAY = 86400000;
const weekdays = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"];

function dayKey(d) {
    return d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate();
}

function midnight(d) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function addDays(d, n) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);
}

function toDate(us, tz) {
    const d = new Date(us / 1000);
    if (tz !== "floating")
        return d;
    return new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), d.getUTCHours(), d.getUTCMinutes());
}

// "20261027", "20261027T100000" (local time) or "20261027T100000Z" (UTC)
function parseIcal(s) {
    const m = /^(\d{4})(\d\d)(\d\d)(?:T(\d\d)(\d\d)(\d\d)(Z)?)?/.exec(s);
    if (!m)
        return null;
    const y = +m[1], mo = +m[2] - 1, d = +m[3], h = +(m[4] || 0), mi = +(m[5] || 0), se = +(m[6] || 0);
    return m[7] ? new Date(Date.UTC(y, mo, d, h, mi, se)) : new Date(y, mo, d, h, mi, se);
}

// Lines like "RRULE:FREQ=WEEKLY;BYDAY=TU", "EXDATE;TZID=Europe/Zurich:20261027T100000"
function parseRules(lines) {
    const r = {
        rrules: [],
        exdates: {},
        rdates: []
    };
    for (const line of lines) {
        const colon = line.indexOf(":");
        const name = line.slice(0, colon).split(";")[0].trim();
        const value = line.slice(colon + 1).trim();
        if (name === "RRULE") {
            const rule = {};
            for (const part of value.split(";")) {
                const kv = part.split("=");
                rule[kv[0]] = kv[1];
            }
            if (rule.UNTIL) {
                rule.until = parseIcal(rule.UNTIL);
                // A date only: the full day is included
                if (rule.UNTIL.indexOf("T") < 0)
                    rule.until = addDays(rule.until, 1);
            }
            r.rrules.push(rule);
        } else if (name === "EXDATE" || name === "RDATE") {
            for (const v of value.split(",")) {
                const d = parseIcal(v);
                if (!d)
                    continue;
                if (name === "EXDATE")
                    r.exdates[dayKey(d)] = true;
                else
                    r.rdates.push(d);
            }
        }
    }
    return r;
}

// True when the rule gives an occurrence on `day` (local midnight). `s` is the midnight of the first occurrence.
function matches(rule, s, day) {
    const interval = +(rule.INTERVAL || 1);
    const days = Math.round((day - s) / DAY);
    if (days < 0)
        return false;
    switch (rule.FREQ) {
    case "DAILY":
        return days % interval === 0;
    case "WEEKLY":
        {
            const byday = rule.BYDAY ? rule.BYDAY.split(",") : [weekdays[s.getDay()]];
            if (byday.indexOf(weekdays[day.getDay()]) < 0)
                return false;
            const wkst = weekdays.indexOf(rule.WKST || "MO");
            // Days from s to the start of the week of day, and of s
            const weekStart = (n, d) => n - (d.getDay() - wkst + 7) % 7;
            return Math.round((weekStart(days, day) - weekStart(0, s)) / 7) % interval === 0;
        }
    case "MONTHLY":
        return day.getDate() === s.getDate() && ((day.getFullYear() - s.getFullYear()) * 12 + day.getMonth() - s.getMonth()) % interval === 0;
    case "YEARLY":
        return day.getDate() === s.getDate() && day.getMonth() === s.getMonth() && (day.getFullYear() - s.getFullYear()) % interval === 0;
    }
    return false;
}

// events: rows [calId, id, title, start, end, startTz, flags, recurrenceId, recurrenceIdTz, status]
// rules: rows [calId, itemId, icalString]
// Returns the events with their rules, ready for occurrences()
function prepare(events, rules) {
    const lines = {};
    for (const row of rules) {
        const key = row[0] + " " + row[1];
        (lines[key] = lines[key] || []).push(row[2]);
    }
    const items = [];
    // Days of the occurrences that an exception (an occurrence changed in Thunderbird) replaces
    const moved = {};
    for (const e of events) {
        const key = e[0] + " " + e[1];
        if (e[7] !== null)
            (moved[key] = moved[key] || {})[dayKey(toDate(e[7], e[8]))] = true;
        if (e[9] === "CANCELLED")
            continue;
        const start = toDate(e[3], e[5]);
        items.push({
            key: key,
            cal: e[0],
            title: e[2] || "",
            start: start,
            end: e[4] !== null ? toDate(e[4], e[5]) : start,
            allDay: (e[6] & 8) !== 0,
            rules: e[7] === null && (e[6] & 16) ? parseRules(lines[key] || []) : null
        });
    }
    for (const it of items)
        if (it.rules)
            it.moved = moved[it.key] || {};
    return items;
}

// Occurrences that touch [from, to), all-day first, then by start: {cal, title, start, end, allDay}
function occurrences(items, from, to) {
    const out = [];
    const push = (it, start) => {
        const end = new Date(+start + (it.end - it.start));
        // An event with no length still shows on its day
        if (start < to && (end > from || start >= from))
            out.push({
                cal: it.cal,
                title: it.title,
                start: start,
                end: end,
                allDay: it.allDay
            });
    };
    const at = (day, time) => new Date(day.getFullYear(), day.getMonth(), day.getDate(), time.getHours(), time.getMinutes());

    for (const it of items) {
        if (!it.rules) {
            push(it, it.start);
            continue;
        }
        const r = it.rules;
        const s = midnight(it.start);
        const skip = day => r.exdates[dayKey(day)] || it.moved[dayKey(day)];
        const counted = r.rrules.some(rule => rule.COUNT);
        // COUNT needs all the occurrences from the start. Else, start just before the range:
        // an occurrence from an earlier day can last into it.
        let day = counted ? s : new Date(Math.max(+s, +midnight(new Date(+from - (it.end - it.start))) - DAY));
        day = midnight(day);
        const counts = r.rrules.map(() => 0);
        for (; day < to; day = addDays(day, 1)) {
            let hit = +day === +s;
            r.rrules.forEach((rule, i) => {
                if (!matches(rule, s, day))
                    return;
                if (rule.until && at(day, it.start) > rule.until)
                    return;
                if (rule.COUNT && ++counts[i] > +rule.COUNT)
                    return;
                hit = true;
            });
            if (hit && !skip(day))
                push(it, at(day, it.start));
        }
        for (const d of r.rdates)
            if (!skip(d))
                push(it, d);
    }
    return out.sort((a, b) => (b.allDay - a.allDay) || (a.start - b.start));
}
