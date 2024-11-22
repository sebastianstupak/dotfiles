#!/bin/bash

declare -A COUNTRY_INFO=(
    # Torrent-friendly countries
    ["CH"]="Switzerland (Torrent Friendly, Strong Privacy Laws, No Logs)"
    ["RO"]="Romania (Torrent Friendly, No Data Retention Laws)"
    ["NL"]="Netherlands (Torrent Friendly, Good Privacy Legislation)"
    ["IS"]="Iceland (Torrent Friendly, Strong Privacy Protection)"
    ["SE"]="Sweden (Torrent Friendly, Fast Speeds)"
    ["CZ"]="Czech Republic (Torrent Friendly, No Data Retention)"
    ["ES"]="Spain (Torrent Friendly, Privacy Oriented)"
    ["BG"]="Bulgaria (Torrent Friendly, EU Member)"
    ["PL"]="Poland (Generally Privacy Friendly)"
    ["LV"]="Latvia (Privacy Friendly, EU Member)"
    ["NO"]="Norway (Strong Privacy Laws)"
    ["FI"]="Finland (Privacy Focused)"
    # Countries with some restrictions
    ["DE"]="Germany (Good Speeds, Some Logging Required)"
    ["FR"]="France (Fast Speeds, Data Retention Laws)"
    ["IT"]="Italy (Some Data Retention)"
    ["AT"]="Austria (EU Data Retention)"
    ["UK"]="United Kingdom (Extensive Logging, Five Eyes)"
    ["IE"]="Ireland (EU Member, Some Logging)"
    ["PT"]="Portugal (EU Data Laws Apply)"
    # Five Eyes and high surveillance
    ["US"]="United States (14 Eyes, Extensive Surveillance)"
    ["CA"]="Canada (14 Eyes, Data Retention)"
    ["AU"]="Australia (Five Eyes, Data Laws)"
    ["NZ"]="New Zealand (Five Eyes)"
)
