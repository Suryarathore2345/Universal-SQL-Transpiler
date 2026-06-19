"""
IANA → Windows time zone ID mapping.

T-SQL's AT TIME ZONE (SQL Server / Synapse / Fabric DW) requires Windows time
zone IDs (e.g. "India Standard Time"), while Redshift/Snowflake CONVERT_TIMEZONE
takes IANA names (e.g. "Asia/Kolkata") or abbreviations (e.g. "UTC"). This table
is a curated subset of the authoritative Unicode CLDR windowsZones.xml mapping
(https://github.com/unicode-org/cldr/blob/main/common/supplemental/windowsZones.xml),
restricted to entries we are highly confident about.

Deliberately NOT exhaustive: an unmapped zone must NOT be guessed at — callers
should leave the original function call untouched and raise a manual-review
warning instead of emitting a plausible-looking but wrong conversion.
"""
from __future__ import annotations

IANA_TO_WINDOWS_TZ: dict[str, str] = {
    "UTC": "UTC",
    "ETC/UTC": "UTC",
    "GMT": "UTC",

    # Americas
    "AMERICA/NEW_YORK": "Eastern Standard Time",
    "AMERICA/TORONTO": "Eastern Standard Time",
    "AMERICA/CHICAGO": "Central Standard Time",
    "AMERICA/DENVER": "Mountain Standard Time",
    "AMERICA/PHOENIX": "US Mountain Standard Time",
    "AMERICA/LOS_ANGELES": "Pacific Standard Time",
    "AMERICA/VANCOUVER": "Pacific Standard Time",
    "AMERICA/ANCHORAGE": "Alaskan Standard Time",
    "AMERICA/HALIFAX": "Atlantic Standard Time",
    "AMERICA/SAO_PAULO": "E. South America Standard Time",
    "AMERICA/MEXICO_CITY": "Central Standard Time (Mexico)",
    "AMERICA/BOGOTA": "SA Pacific Standard Time",
    "AMERICA/LIMA": "SA Pacific Standard Time",
    "AMERICA/SANTIAGO": "Pacific SA Standard Time",
    "AMERICA/ARGENTINA/BUENOS_AIRES": "Argentina Standard Time",

    # Europe
    "EUROPE/LONDON": "GMT Standard Time",
    "EUROPE/DUBLIN": "GMT Standard Time",
    "EUROPE/LISBON": "GMT Standard Time",
    "EUROPE/PARIS": "Romance Standard Time",
    "EUROPE/MADRID": "Romance Standard Time",
    "EUROPE/BERLIN": "W. Europe Standard Time",
    "EUROPE/ROME": "W. Europe Standard Time",
    "EUROPE/AMSTERDAM": "W. Europe Standard Time",
    "EUROPE/ZURICH": "W. Europe Standard Time",
    "EUROPE/WARSAW": "Central European Standard Time",
    "EUROPE/ATHENS": "GTB Standard Time",
    "EUROPE/HELSINKI": "FLE Standard Time",
    "EUROPE/MOSCOW": "Russian Standard Time",
    "EUROPE/ISTANBUL": "Turkey Standard Time",

    # Africa / Middle East
    "AFRICA/CAIRO": "Egypt Standard Time",
    "AFRICA/JOHANNESBURG": "South Africa Standard Time",
    "AFRICA/LAGOS": "W. Central Africa Standard Time",
    "AFRICA/NAIROBI": "E. Africa Standard Time",
    "ASIA/DUBAI": "Arabian Standard Time",
    "ASIA/RIYADH": "Arab Standard Time",
    "ASIA/JERUSALEM": "Israel Standard Time",
    "ASIA/TEHRAN": "Iran Standard Time",

    # Asia / Pacific
    "ASIA/KARACHI": "Pakistan Standard Time",
    "ASIA/KOLKATA": "India Standard Time",
    "ASIA/CALCUTTA": "India Standard Time",
    "ASIA/DHAKA": "Bangladesh Standard Time",
    "ASIA/BANGKOK": "SE Asia Standard Time",
    "ASIA/JAKARTA": "SE Asia Standard Time",
    "ASIA/SINGAPORE": "Singapore Standard Time",
    "ASIA/SHANGHAI": "China Standard Time",
    "ASIA/TOKYO": "Tokyo Standard Time",
    "ASIA/SEOUL": "Korea Standard Time",
    "AUSTRALIA/SYDNEY": "AUS Eastern Standard Time",
    "AUSTRALIA/MELBOURNE": "AUS Eastern Standard Time",
    "AUSTRALIA/BRISBANE": "E. Australia Standard Time",
    "AUSTRALIA/PERTH": "W. Australia Standard Time",
    "AUSTRALIA/ADELAIDE": "Cen. Australia Standard Time",
    "PACIFIC/AUCKLAND": "New Zealand Standard Time",
}


def iana_to_windows(tz_name: str) -> str | None:
    """
    Look up the Windows time zone ID for an IANA zone name or common
    abbreviation (case-insensitive). Returns None when there is no
    high-confidence mapping — callers must not guess in that case.
    """
    return IANA_TO_WINDOWS_TZ.get(tz_name.strip().upper())
