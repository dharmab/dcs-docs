-- =============================================================================
-- UNIT TEMPLATES
-- Defines unit compositions for all difficulty levels
-- =============================================================================

UnitTemplates = {}

-- =============================================================================
-- ISAF PLATOON (Immortal/Invisible - for firefight visuals)
-- =============================================================================

UnitTemplates.ISAFPlatoon = {
    {type = "M-1 Abrams", count = 2},
    {type = "M-2 Bradley", count = 2},
    {type = "Vulcan", count = 1},
    {type = "CHAP_M1083", count = 1},
}

-- =============================================================================
-- ERUSEA PLATOONS BY DIFFICULTY
-- =============================================================================

UnitTemplates.EruseaPlatoon = {
    VeryEasy = {
        {type = "Leclerc", count = 2},
        {type = "Marder", count = 2},
    },
    Easy = {
        {type = "Leclerc", count = 2},
        {type = "Marder", count = 2},
        {type = "ZSU-23-4 Shilka", count = 1},
    },
    Normal = {
        {type = "Leclerc", count = 2},
        {type = "Marder", count = 2},
        {type = "Gepard", count = 1},
    },
    Hard = {
        {type = "Leclerc", count = 2},
        {type = "Marder", count = 2},
        {type = "Gepard", count = 1},
    },
}

-- =============================================================================
-- SHORAD UNITS BY DIFFICULTY
-- =============================================================================

UnitTemplates.SHORAD = {
    VeryEasy = {},
    Easy = {
        {type = "Ural-375 ZU-23", count = 1},
        {type = "Strela-1 9P31", count = 1},
    },
    Normal = {
        {type = "Ural-375 ZU-23", count = 1},
        {type = "Strela-10M3", count = 1},
        {type = "ZSU-23-4 Shilka", count = 1},
    },
    Hard = {
        {type = "Gepard", count = 1},
        {type = "Strela-10M3", count = 1},
        {type = "2S6 Tunguska", count = 1},
    },
}

-- =============================================================================
-- SAM SITE COMPOSITIONS BY DIFFICULTY
-- =============================================================================

UnitTemplates.SAMSites = {
    Easy = {
        SA2Incomplete = {
            {type = "SNR_75V", count = 1},
            {type = "S_75M_Volhov", count = 3},
        },
        SA9 = {
            {type = "Strela-1 9P31", count = 2},
        },
        SA13 = {
            {type = "Strela-10M3", count = 2},
        },
    },
    Normal = {
        SA2 = {
            {type = "p-19 s-125 sr", count = 1},
            {type = "SNR_75V", count = 1},
            {type = "S_75M_Volhov", count = 6},
        },
        SA3 = {
            {type = "p-19 s-125 sr", count = 1},
            {type = "snr s-125 tr", count = 1},
            {type = "5p73 s-125 ln", count = 4},
        },
        SA6 = {
            {type = "Kub 1S91 str", count = 1},
            {type = "Kub 2P25 ln", count = 4},
        },
        SA8 = {
            {type = "Osa 9A33 ln", count = 2},
        },
        EWR = {
            {type = "1L13 EWR", count = 1},
        },
    },
    Hard = {
        SA10 = {
            {type = "S-300PS 40B6MD sr", count = 1},
            {type = "S-300PS 64H6E sr", count = 1},
            {type = "S-300PS 40B6M tr", count = 1},
            {type = "S-300PS 5P85C ln", count = 4},
            {type = "S-300PS 5P85D ln", count = 2},
            {type = "S-300PS 54K6 cp", count = 1},
        },
        SA11 = {
            {type = "SA-11 Buk SR 9S18M1", count = 1},
            {type = "SA-11 Buk CC 9S470M1", count = 1},
            {type = "SA-11 Buk LN 9A310M1", count = 4},
        },
        SA6 = {
            {type = "Kub 1S91 str", count = 1},
            {type = "Kub 2P25 ln", count = 4},
        },
        SA15 = {
            {type = "Tor 9A331", count = 2},
        },
        EWR = {
            {type = "1L13 EWR", count = 1},
            {type = "55G6 EWR", count = 1},
        },
    },
}

-- =============================================================================
-- AIRBASE SHORAD BY DIFFICULTY
-- Short-range air defense units positioned near enemy airbases
-- to defend against low-level OCA strikes
-- =============================================================================

UnitTemplates.AirbaseSHORAD = {
    VeryEasy = {},
    Easy = {
        {type = "Ural-375 ZU-23", count = 2},
        {type = "Strela-1 9P31", count = 1},
    },
    Normal = {
        {type = "ZSU-23-4 Shilka", count = 2},
        {type = "Strela-10M3", count = 2},
    },
    Hard = {
        {type = "Gepard", count = 2},
        {type = "Strela-10M3", count = 2},
    },
}

-- =============================================================================
-- AAA BY DIFFICULTY
-- =============================================================================

UnitTemplates.AAA = {
    VeryEasy = {},
    Easy = {
        {type = "Ural-375 ZU-23", count = 2},
        {type = "ZSU-23-4 Shilka", count = 1},
    },
    Normal = {
        {type = "Ural-375 ZU-23", count = 3},
        {type = "ZSU-23-4 Shilka", count = 2},
        {type = "Gepard", count = 1},
    },
    Hard = {
        {type = "Ural-375 ZU-23", count = 4},
        {type = "ZSU-23-4 Shilka", count = 2},
        {type = "Gepard", count = 2},
    },
}

-- =============================================================================
-- FIGHTER CONFIGURATIONS BY DIFFICULTY
-- =============================================================================

UnitTemplates.Fighters = {
    VeryEasy = {
        types = {},
        maxAirborne = 0,
    },
    Easy = {
        types = {"MiG-21Bis", "F-5E", "F-5E-3"},
        skills = {"Average", "Good", "High"},
        maxAirborne = 2,
        payloads = {
            ["MiG-21Bis"] = {
                pylons = {
                    [1] = {CLSID = "{R-60M}"},
                    [2] = {CLSID = "{PTB_490C_MIG21}"},
                    [3] = {CLSID = "{PTB_490C_MIG21}"},
                    [4] = {CLSID = "{R-60M}"},
                },
                fuel = 2280,
                flare = 0,
                chaff = 0,
                gun = 100,
            },
            ["F-5E"] = {
                pylons = {
                    [1] = {CLSID = "{AIM-9P5}"},
                    [3] = {CLSID = "{0395076D-2F77-4420-9D33-087A4571B44B}"},
                    [5] = {CLSID = "{AIM-9P5}"},
                },
                fuel = 2046,
                flare = 15,
                chaff = 15,
                gun = 100,
            },
            ["F-5E-3"] = {
                pylons = {
                    [1] = {CLSID = "{AIM-9P5}"},
                    [3] = {CLSID = "{0395076D-2F77-4420-9D33-087A4571B44B}"},
                    [5] = {CLSID = "{AIM-9P5}"},
                },
                fuel = 2046,
                flare = 15,
                chaff = 15,
                gun = 100,
            },
        },
    },
    Normal = {
        types = {"MiG-29A", "MiG-29S", "Mirage 2000-5", "F-16A"},
        skills = {"Good", "High", "Excellent"},
        maxAirborne = 4,
        payloads = {
            ["MiG-29A"] = {
                pylons = {
                    [1] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"},
                    [2] = {CLSID = "{9B25D316-0434-4954-868F-D51DB1A38DF0}"},
                    [3] = {CLSID = "{2BEC576B-CDF5-4B7F-961F-B0FA4312B841}"},
                    [4] = {CLSID = "{2BEC576B-CDF5-4B7F-961F-B0FA4312B841}"},
                    [5] = {CLSID = "{9B25D316-0434-4954-868F-D51DB1A38DF0}"},
                    [6] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"},
                },
                fuel = 3376,
                flare = 30,
                chaff = 30,
                gun = 100,
            },
            ["MiG-29S"] = {
                pylons = {
                    [1] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"},
                    [2] = {CLSID = "{9B25D316-0434-4954-868F-D51DB1A38DF0}"},
                    [3] = {CLSID = "{2BEC576B-CDF5-4B7F-961F-B0FA4312B841}"},
                    [4] = {CLSID = "{2BEC576B-CDF5-4B7F-961F-B0FA4312B841}"},
                    [5] = {CLSID = "{9B25D316-0434-4954-868F-D51DB1A38DF0}"},
                    [6] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"},
                },
                fuel = 3376,
                flare = 30,
                chaff = 30,
                gun = 100,
            },
            ["Mirage 2000-5"] = {
                pylons = {
                    [1] = {CLSID = "{Matra_Magic_II}"},
                    [2] = {CLSID = "{Matra_Super_530D}"},
                    [5] = {CLSID = "{M2000_RPL_522}"},
                    [8] = {CLSID = "{Matra_Super_530D}"},
                    [9] = {CLSID = "{Matra_Magic_II}"},
                },
                fuel = 3165,
                flare = 112,
                chaff = 112,
                gun = 100,
            },
            ["F-16A"] = {
                pylons = {
                    [1] = {CLSID = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}"},
                    [2] = {CLSID = "{AIM-9L}"},
                    [4] = {CLSID = "{F376DBEE-4CAE-41BA-ADD9-B2910AC95DEC}"},
                    [6] = {CLSID = "{F376DBEE-4CAE-41BA-ADD9-B2910AC95DEC}"},
                    [8] = {CLSID = "{AIM-9L}"},
                    [9] = {CLSID = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}"},
                },
                fuel = 3104,
                flare = 60,
                chaff = 60,
                gun = 100,
            },
        },
    },
    Hard = {
        types = {"F-15C", "Su-27", "F-16C_50", "FA-18C_hornet", "J-11A"},
        skills = {"High", "Excellent"},
        maxAirborne = 6,
        payloads = {
            ["F-15C"] = {
                pylons = {
                    [1] = {CLSID = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}"},
                    [2] = {CLSID = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"},
                    [3] = {CLSID = "{E1F29B21-F291-4589-9FD8-3272EEC69506}"},
                    [5] = {CLSID = "{E1F29B21-F291-4589-9FD8-3272EEC69506}"},
                    [7] = {CLSID = "{E1F29B21-F291-4589-9FD8-3272EEC69506}"},
                    [9] = {CLSID = "{E1F29B21-F291-4589-9FD8-3272EEC69506}"},
                    [10] = {CLSID = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"},
                    [11] = {CLSID = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}"},
                },
                fuel = 6103,
                flare = 60,
                chaff = 120,
                gun = 100,
            },
            ["Su-27"] = {
                pylons = {
                    [1] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"},
                    [2] = {CLSID = "{B4C01D60-A8A3-4237-BD72-CA7655BC0FE9}"},
                    [3] = {CLSID = "{B4C01D60-A8A3-4237-BD72-CA7655BC0FE9}"},
                    [4] = {CLSID = "{88DAC840-9F75-4531-8689-B46A5C613D43}"},
                    [5] = {CLSID = "{B79C379A-9E87-4E50-A1EE-7F7E29C2E87A}"},
                    [6] = {CLSID = "{B79C379A-9E87-4E50-A1EE-7F7E29C2E87A}"},
                    [7] = {CLSID = "{88DAC840-9F75-4531-8689-B46A5C613D43}"},
                    [8] = {CLSID = "{B4C01D60-A8A3-4237-BD72-CA7655BC0FE9}"},
                    [9] = {CLSID = "{B4C01D60-A8A3-4237-BD72-CA7655BC0FE9}"},
                    [10] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"},
                },
                fuel = 9400,
                flare = 96,
                chaff = 96,
                gun = 100,
            },
            ["F-16C_50"] = {
                pylons = {
                    [1] = {CLSID = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"},
                    [2] = {CLSID = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"},
                    [3] = {CLSID = "{5CE2FF2A-645A-4197-B48D-8720A31E718B}"},
                    [4] = {CLSID = "{F376DBEE-4CAE-41BA-ADD9-B2910AC95DEC}"},
                    [6] = {CLSID = "{F376DBEE-4CAE-41BA-ADD9-B2910AC95DEC}"},
                    [7] = {CLSID = "{5CE2FF2A-645A-4197-B48D-8720A31E718B}"},
                    [8] = {CLSID = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"},
                    [9] = {CLSID = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"},
                },
                fuel = 3249,
                flare = 60,
                chaff = 60,
                gun = 100,
            },
            ["FA-18C_hornet"] = {
                pylons = {
                    [1] = {CLSID = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"},
                    [2] = {CLSID = "{5CE2FF2A-645A-4197-B48D-8720A31E718B}"},
                    [3] = {CLSID = "{FPU_8A_FUEL_TANK}"},
                    [5] = {CLSID = "{FPU_8A_FUEL_TANK}"},
                    [7] = {CLSID = "{FPU_8A_FUEL_TANK}"},
                    [8] = {CLSID = "{5CE2FF2A-645A-4197-B48D-8720A31E718B}"},
                    [9] = {CLSID = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}"},
                },
                fuel = 4900,
                flare = 60,
                chaff = 60,
                gun = 100,
            },
            ["J-11A"] = {
                pylons = {
                    [1] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"},
                    [2] = {CLSID = "{B4C01D60-A8A3-4237-BD72-CA7655BC0FE9}"},
                    [3] = {CLSID = "{B4C01D60-A8A3-4237-BD72-CA7655BC0FE9}"},
                    [4] = {CLSID = "{88DAC840-9F75-4531-8689-B46A5C613D43}"},
                    [5] = {CLSID = "{B79C379A-9E87-4E50-A1EE-7F7E29C2E87A}"},
                    [6] = {CLSID = "{B79C379A-9E87-4E50-A1EE-7F7E29C2E87A}"},
                    [7] = {CLSID = "{88DAC840-9F75-4531-8689-B46A5C613D43}"},
                    [8] = {CLSID = "{B4C01D60-A8A3-4237-BD72-CA7655BC0FE9}"},
                    [9] = {CLSID = "{B4C01D60-A8A3-4237-BD72-CA7655BC0FE9}"},
                    [10] = {CLSID = "{FBC29BFE-3D24-4C64-B81D-941239D12249}"},
                },
                fuel = 9400,
                flare = 96,
                chaff = 96,
                gun = 100,
            },
        },
    },
}

-- =============================================================================
-- HELICOPTER CONFIGURATIONS BY DIFFICULTY
-- =============================================================================

UnitTemplates.Helicopters = {
    Easy = {
        types = {"Mi-24P", "Mi-24V", "Ka-50"},
    },
    Normal = {
        types = {"Mi-24P", "Ka-50", "AH-64A"},
    },
    Hard = {
        types = {"Ka-50", "AH-64D"},
    },
}

-- =============================================================================
-- LOGISTICS CONVOY
-- =============================================================================

UnitTemplates.LogisticsConvoy = {
    {type = "Ural-375", count = 4},
    {type = "BRDM-2", count = 1},
    {type = "Ural-375 ZU-23", count = 1},
}

-- =============================================================================
-- ARTILLERY BATTERY
-- =============================================================================

UnitTemplates.ArtilleryBattery = {
    {type = "SAU Akatsia", count = 4},
    {type = "Ural-375", count = 1},
    {type = "BRDM-2", count = 1},
}

-- =============================================================================
-- UNIT SUBSTITUTIONS
-- =============================================================================

-- Equivalent unit types that can be swapped for variety
UnitTemplates.Substitutions = {
    -- Main Battle Tanks
    ["Leclerc"] = {"Leclerc", "Leopard-2", "Challenger2"},
    ["Leopard-2"] = {"Leopard-2", "Leclerc", "Challenger2"},
    ["Challenger2"] = {"Challenger2", "Leclerc", "Leopard-2"},
    ["M-1 Abrams"] = {"M-1 Abrams"},

    -- IFVs
    ["Marder"] = {"Marder", "BMP-3", "Warrior"},
    ["BMP-3"] = {"BMP-3", "Marder", "Warrior"},
    ["M-2 Bradley"] = {"M-2 Bradley"},

    -- SHORAD/AAA
    ["Gepard"] = {"Gepard", "ZSU-23-4 Shilka"},
    ["ZSU-23-4 Shilka"] = {"ZSU-23-4 Shilka", "Gepard"},
    ["Vulcan"] = {"Vulcan"},
    ["2S6 Tunguska"] = {"2S6 Tunguska"},
    ["Strela-10M3"] = {"Strela-10M3", "Strela-1 9P31"},
    ["Strela-1 9P31"] = {"Strela-1 9P31", "Strela-10M3"},
    ["Ural-375 ZU-23"] = {"Ural-375 ZU-23"},

    -- Trucks/Logistics
    ["Ural-375"] = {"Ural-375", "GAZ-66"},
    ["GAZ-66"] = {"GAZ-66", "Ural-375"},
    ["BRDM-2"] = {"BRDM-2"},

    -- Artillery
    ["SAU Akatsia"] = {"SAU Akatsia", "SAU Msta", "SAU Gvozdika"},
    ["SAU Msta"] = {"SAU Msta", "SAU Akatsia"},
    ["SAU Gvozdika"] = {"SAU Gvozdika", "SAU Akatsia"},

    -- Supply
    ["CHAP_M1083"] = {"CHAP_M1083"},
}

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Get a substitute unit type (or original if no substitution)
function UnitTemplates:getSubstitute(unitType, chance)
    chance = chance or 0.3

    -- Only substitute with given probability
    if math.random() > chance then
        return unitType
    end

    local alternatives = self.Substitutions[unitType]
    if alternatives and #alternatives > 1 then
        return alternatives[math.random(#alternatives)]
    end

    return unitType
end

function UnitTemplates:getRandomSkill(difficulty)
    local config = self.Fighters[difficulty]
    if not config or not config.skills then
        return "Average"
    end
    return config.skills[math.random(#config.skills)]
end

function UnitTemplates:getRandomFighterType(difficulty)
    local config = self.Fighters[difficulty]
    if not config or not config.types or #config.types == 0 then
        return nil
    end
    return config.types[math.random(#config.types)]
end

function UnitTemplates:getPayload(difficulty, aircraftType)
    local config = self.Fighters[difficulty]
    if not config or not config.payloads then
        return nil
    end
    return config.payloads[aircraftType]
end

env.info("[UnitTemplates] Loaded successfully")
