[group_by(.district_code)[] |
    {"data": {
            "language": .[0].language,
            "district_code": .[0]["district_code"],
            "district": .[0].district,
            "details": [.[] | {
                                "assembly": .constituency_name,
                                "name": .name,
                                "party": .party,
                                "party_color": .party_color,
                                "gender": .gender
                              }
                            ]
                    }
            }
]
