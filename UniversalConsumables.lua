--- STEAMODDED HEADER
--- MOD_NAME: Universal Consumables
--- MOD_ID: UniversalConsumables
--- MOD_AUTHOR: [UniversalConsumables]
--- MOD_DESCRIPTION: Allows tarot and spectral cards to be used on jokers and consumables.
--- DEPENDENCIES: [Steamodded>=0.9.8]
--- VERSION: 1.0.1

UC = {}

UC.force_hand = false

function UC.is_random_target_card(card)
    local random_keys = {
        immolate=true,
        hex=true, ankh=true, ectoplasm=true,
        wraith=true,
    }
    if not card or not card.config or not card.config.center then return false end
    local key = card.config.center.key or ""
    key = key:gsub("^c_","")
    return random_keys[key] == true
end

function UC.sel()
    local t = {}
    if G.hand and G.hand.highlighted then
        for _,c in ipairs(G.hand.highlighted) do t[#t+1]=c end
    end
    if G.jokers then
        for _,c in ipairs(G.jokers.cards) do
            if c.highlighted then t[#t+1]=c end
        end
    end
    if G.consumeables then
        for _,c in ipairs(G.consumeables.cards) do
            if c.highlighted then t[#t+1]=c end
        end
    end
    return t
end

function UC.non_hand_highlighted()
    if G.jokers then
        for _,c in ipairs(G.jokers.cards) do
            if c.highlighted then return true end
        end
    end
    if G.consumeables then
        for _,c in ipairs(G.consumeables.cards) do
            if c.highlighted then return true end
        end
    end
    return false
end

function UC.has_any(exclude)
    if G.hand and #G.hand.cards > 0 then return true end
    if G.jokers and #G.jokers.cards > 0 then return true end
    if G.consumeables then
        for _,c in ipairs(G.consumeables.cards) do
            if c ~= exclude then return true end
        end
    end
    return false
end

function UC.copy_extras(src, dst)
    if src.edition then
        dst:set_edition(src.edition, true)
    else
        dst:set_edition(nil, true)
    end
    if src.seal then
        dst:set_seal(src.seal, true, true)
    elseif dst.seal then
        dst:set_seal(nil, true, true)
    end
end

function UC.apply_edition(card, key)
    if card then card:set_edition({[key]=true}, true) end
end

local JOKER_FOR_ENHANCE = {
    m_lucky  = "j_lucky_cat",
    m_wild   = "j_smeared",
    m_steel  = "j_steel_joker",
    m_glass  = "j_glass",
    m_gold   = "j_golden",
    m_stone  = "j_stone",
    m_mult   = "j_jolly",
    m_bonus  = "j_zany",
}

local JOKER_FOR_SUIT_COMMON = {
    Diamonds = "j_greedy_joker",
    Clubs    = "j_gluttonous_joker",
    Hearts   = "j_lusty_joker",
    Spades   = "j_wrathful_joker",
}
local JOKER_FOR_SUIT_RARE = {
    Diamonds = "j_rough_gem",
    Clubs    = "j_onyx_agate",
    Hearts   = "j_bloodstone",
    Spades   = "j_arrowhead",
}

local function swap_to_joker(t, joker_key)
    local center = G.P_CENTERS[joker_key]
    if center then
        t:set_ability(center)
        card_eval_status_text(t,"extra",nil,nil,nil,{message=localize("k_upgrade_ex"),colour=G.C.PURPLE})
    end
end

local function make_enhance1(key, center_key, msg_key, colour_key)
    SMODS.Consumable:take_ownership(key, {
        can_use = function(self, card) return UC.has_any(card) end,
        use = function(self, card, area, copier)
            local s = UC.sel()
            local target = nil
            for _,c in ipairs(s) do
                if c.area ~= G.hand then target = c; break end
            end
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
                func=function()
                    local t = target or (G.hand.highlighted and G.hand.highlighted[1])
                    if t then
                        if t.area ~= G.hand and JOKER_FOR_ENHANCE[center_key] then
                            swap_to_joker(t, JOKER_FOR_ENHANCE[center_key])
                        else
                            t:set_ability(G.P_CENTERS[center_key])
                            card_eval_status_text(t,"extra",nil,nil,nil,{message=localize(msg_key),colour=G.C[colour_key]})
                        end
                    end
                    return true
                end
            }))
        end,
    }, true)
end

local function make_enhance2(key, center_key, msg_key, colour_key)
    SMODS.Consumable:take_ownership(key, {
        can_use = function(self, card) return UC.has_any(card) end,
        use = function(self, card, area, copier)
            local s = UC.sel()
            local targets = {}
            for _,c in ipairs(s) do
                if c.area ~= G.hand then targets[#targets+1]=c end
            end
            if #targets == 0 and G.hand.highlighted then
                for _,c in ipairs(G.hand.highlighted) do targets[#targets+1]=c end
            end
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
                func=function()
                    for _,t in ipairs(targets) do
                        if t.area ~= G.hand and JOKER_FOR_ENHANCE[center_key] then
                            swap_to_joker(t, JOKER_FOR_ENHANCE[center_key])
                        else
                            t:set_ability(G.P_CENTERS[center_key])
                            card_eval_status_text(t,"extra",nil,nil,nil,{message=localize(msg_key),colour=G.C[colour_key]})
                        end
                    end
                    return true
                end
            }))
        end,
    }, true)
end

local function make_suit(key, suit)
    SMODS.Consumable:take_ownership(key, {
        can_use = function(self, card) return UC.has_any(card) end,
        use = function(self, card, area, copier)
            local s = UC.sel()
            local targets = {}
            for _,c in ipairs(s) do
                if c.area ~= G.hand then targets[#targets+1]=c end
            end
            if #targets == 0 and G.hand.highlighted then
                for _,c in ipairs(G.hand.highlighted) do targets[#targets+1]=c end
            end
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
                func=function()
                    for _,t in ipairs(targets) do
                        if t.area == G.hand then
                            t:change_suit(suit)
                            card_eval_status_text(t,"extra",nil,nil,nil,{
                                message=localize(suit,"suits_plural"),
                                colour=G.C.SUITS[suit]
                            })
                        else
                            local rarity = t.config and t.config.center and t.config.center.rarity or 1
                            if type(rarity) == "string" then
                                rarity = ({Common=1,Uncommon=2,Rare=3,Legendary=4})[rarity] or 1
                            end
                            local joker_key = (rarity >= 2) and JOKER_FOR_SUIT_RARE[suit] or JOKER_FOR_SUIT_COMMON[suit]
                            if joker_key then swap_to_joker(t, joker_key) end
                        end
                    end
                    return true
                end
            }))
        end,
    }, true)
end

local function make_seal(key, seal, msg_key, colour_key)
    SMODS.Consumable:take_ownership(key, {
        can_use = function(self, card) return UC.has_any(card) end,
        use = function(self, card, area, copier)
            local s = UC.sel()
            local target = nil
            for _,c in ipairs(s) do
                if c.area ~= G.hand then target=c; break end
            end
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
                func=function()
                    local t = target or (G.hand.highlighted and G.hand.highlighted[1])
                    if t then
                        t:set_seal(seal, true, true)
                        card_eval_status_text(t,"extra",nil,nil,nil,{message=localize(msg_key),colour=G.C[colour_key]})
                    end
                    return true
                end
            }))
        end,
    }, true)
end

make_enhance1("magician",  "m_lucky",  "k_lucky_ex",   "MULT")
make_enhance1("lovers",    "m_wild",   "k_wild_ex",    "GREEN")
make_enhance1("chariot",   "m_steel",  "k_steel_ex",   "BLUE")
make_enhance1("justice",   "m_glass",  "k_glass_ex",   "BLUE")
make_enhance1("devil",     "m_gold",   "k_gold_ex",    "MONEY")
make_enhance1("tower",     "m_stone",  "k_stone_ex",   "CHIPS")
make_enhance2("empress",   "m_mult",   "k_mult_ex",    "MULT")
make_enhance2("emperor",   "m_bonus",  "k_bonus_ex",   "CHIPS")
make_suit("star",  "Diamonds")
make_suit("moon",  "Clubs")
make_suit("sun",   "Hearts")
make_suit("world", "Spades")
make_seal("talisman", "Gold",   "k_gold_seal",   "MONEY")
make_seal("deja_vu",  "Red",    "k_red_seal",    "RED")
make_seal("trance",   "Blue",   "k_blue_seal",   "BLUE")
make_seal("medium",   "Purple", "k_purple_seal", "PURPLE")

SMODS.Consumable:take_ownership("strength", {
    can_use = function(self, card) return UC.has_any(card) end,
    use = function(self, card, area, copier)
        local s = UC.sel()
        local targets = {}
        for _,c in ipairs(s) do
            if c.area ~= G.hand then targets[#targets+1]=c end
        end
        if #targets == 0 and G.hand.highlighted then
            for _,c in ipairs(G.hand.highlighted) do targets[#targets+1]=c end
        end
        G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
            func=function()
                for _,t in ipairs(targets) do
                    if t.area == G.hand then

                        local ranks = {"2","3","4","5","6","7","8","9","10","Jack","Queen","King","Ace"}
                        for i,r in ipairs(ranks) do
                            if r == t.base.value then
                                if i < #ranks then
                                    t:set_base(G.P_CARDS[t.base.suit.."_"..ranks[i+1]])
                                end
                                break
                            end
                        end
                    else
                        local rarity_order = {1, 2, 3, 4}
                        local rarity_jokers = {
                            [1] = "j_joker",
                            [2] = "j_jolly",
                            [3] = "j_lusty_joker",
                            [4] = "j_cavendish",
                        }
                        local cur = t.config.center.rarity or 1
                        if type(cur) == "string" then
                            cur = ({Common=1,Uncommon=2,Rare=3,Legendary=4})[cur] or 1
                        end
                        local next_rarity = math.min(cur + 1, 4)
                        if next_rarity > cur then
                            local pool = G.P_CENTER_POOLS["Joker"] or {}
                            local eligible = {}
                            for _,j in ipairs(pool) do
                                local r = j.rarity
                                if type(r) == "string" then
                                    r = ({Common=1,Uncommon=2,Rare=3,Legendary=4})[r] or 1
                                end
                                if r == next_rarity then eligible[#eligible+1] = j end
                            end
                            if #eligible > 0 then
                                local chosen = eligible[math.random(#eligible)]
                                t:set_ability(chosen)
                            end
                        end
                    end
                    card_eval_status_text(t,"extra",nil,nil,nil,{message=localize("k_upgrade_ex"),colour=G.C.CHIPS})
                end
                return true
            end
        }))
    end,
}, true)

SMODS.Consumable:take_ownership("hanged_man", {
    can_use = function(self, card) return UC.has_any(card) end,
    use = function(self, card, area, copier)
        local s = UC.sel()
        local targets = {}
        for _,c in ipairs(s) do
            if c.area ~= G.hand then targets[#targets+1]=c end
        end
        if #targets == 0 and G.hand.highlighted then
            for _,c in ipairs(G.hand.highlighted) do targets[#targets+1]=c end
        end
        G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
            func=function()
                for _,t in ipairs(targets) do
                    if t.area == G.hand then
                        G.hand:remove_card(t)
                    end
                    t:start_dissolve(nil, true)
                end
                return true
            end
        }))
    end,
}, true)

SMODS.Consumable:take_ownership("death", {
    can_use = function(self, card)

        if G.jokers and #G.jokers.cards >= 2 then return true end
        if G.hand and #G.hand.cards >= 2 then return true end
        return false
    end,
    use = function(self, card, area, copier)

        local src = nil
        local src_idx = nil
        if G.jokers then
            for i,c in ipairs(G.jokers.cards) do
                if c.highlighted then src=c; src_idx=i; break end
            end
        end

        if src and src_idx then

            local neighbor_idx = src_idx < #G.jokers.cards and src_idx+1 or src_idx-1
            local dst = G.jokers.cards[neighbor_idx]
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
                func=function()
                    dst:set_ability(src.config.center)
                    UC.copy_extras(src, dst)
                    card_eval_status_text(dst,"extra",nil,nil,nil,{message=localize("k_copied_ex"),colour=G.C.PURPLE})
                    return true
                end
            }))
        else

            local sel = {}
            if G.hand.highlighted then
                for _,c in ipairs(G.hand.highlighted) do sel[#sel+1]=c end
            end
            if #sel < 2 then return end
            table.sort(sel, function(a,b)
                local ai,bi = 999,999
                for i,c in ipairs(G.hand.cards) do
                    if c==a then ai=i end
                    if c==b then bi=i end
                end
                return ai < bi
            end)
            local left, right = sel[1], sel[2]
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
                func=function()
                    right:set_base(left.base)
                    right:set_ability(left.config.center)
                    UC.copy_extras(left, right)
                    card_eval_status_text(right,"extra",nil,nil,nil,{message=localize("k_copied_ex"),colour=G.C.PURPLE})
                    return true
                end
            }))
        end
    end,
}, true)

SMODS.Consumable:take_ownership("wheel_of_fortune", {
    can_use = function(self, card)
        if G.jokers then
            for _,c in ipairs(G.jokers.cards) do
                if not (c.edition and c.edition.polychrome) then return true end
            end
        end
        return false
    end,
    use = function(self, card, area, copier)
        local target = nil
        if G.jokers then
            for _,c in ipairs(G.jokers.cards) do
                if c.highlighted then target=c; break end
            end
        end
        G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
            func=function()
                local function roll_edition()
                    local r = pseudorandom("wheel_of_fortune")
                    if r < 0.5 then return "foil"
                    elseif r < 0.85 then return "holo"
                    else return "polychrome" end
                end
                if target then
                    UC.apply_edition(target, roll_edition())
                    card_eval_status_text(target,"extra",nil,nil,nil,{message=localize("k_upgrade_ex"),colour=G.C.PURPLE})
                else
                    if pseudorandom("wheel_of_fortune") < 0.25 then
                        local eligible = {}
                        for _,c in ipairs(G.jokers.cards) do
                            if not c.edition then eligible[#eligible+1]=c end
                        end
                        if #eligible > 0 then
                            local chosen = eligible[math.random(#eligible)]
                            UC.apply_edition(chosen, roll_edition())
                            card_eval_status_text(chosen,"extra",nil,nil,nil,{message=localize("k_upgrade_ex"),colour=G.C.PURPLE})
                        end
                    else
                        card_eval_status_text(card,"extra",nil,nil,nil,{message=localize("k_no_effect_ex"),colour=G.C.RED})
                    end
                end
                return true
            end
        }))
    end,
}, true)

SMODS.Consumable:take_ownership("aura", {
    can_use = function(self, card) return UC.has_any(card) end,
    use = function(self, card, area, copier)
        local s = UC.sel()
        local target = s[1] or (G.hand.highlighted and G.hand.highlighted[1])
        if not target then return end
        G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
            func=function()
                local r = pseudorandom("aura")
                local ed = r < 0.5 and "foil" or (r < 0.85 and "holo" or "polychrome")
                UC.apply_edition(target, ed)
                card_eval_status_text(target,"extra",nil,nil,nil,{message=localize("k_upgrade_ex"),colour=G.C.PURPLE})
                return true
            end
        }))
    end,
}, true)

SMODS.Consumable:take_ownership("cryptid", {
    can_use = function(self, card)

        if G.hand and #G.hand.cards > 0 then return true end
        if G.jokers then
            local lim = (G.jokers.config and G.jokers.config.card_limit) or 5
            if #G.jokers.cards > 0 and #G.jokers.cards + 2 <= lim then return true end
        end
        return false
    end,
    use = function(self, card, area, copier)
        local s = UC.sel()
        local target = nil
        for _,c in ipairs(s) do
            if c.area ~= G.hand then target=c; break end
        end
        G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
            func=function()
                if target then
                    for i=1,2 do
                        local copy = copy_card(target, nil, nil, target.area)
                        if target.edition then copy:set_edition(target.edition, true) end
                        if target.seal then copy:set_seal(target.seal, true, true) end
                        copy:add_to_deck()
                        target.area:emplace(copy)
                        copy:juice_up(0.3, 0)
                        card_eval_status_text(copy,"extra",nil,nil,nil,{message=localize("k_copied_ex"),colour=G.C.PURPLE})
                    end
                else
                    local src = G.hand.highlighted and G.hand.highlighted[1]
                    if src then
                        for i=1,2 do
                            local copy = copy_card(src, nil, nil, G.deck)
                            G.deck.config.card_limit = G.deck.config.card_limit + 1
                            copy:add_to_deck()
                            G.deck:emplace(copy)
                        end
                        card_eval_status_text(src,"extra",nil,nil,nil,{message=localize("k_copied_ex"),colour=G.C.PURPLE})
                    end
                end
                return true
            end
        }))
    end,
}, true)

SMODS.Consumable:take_ownership("immolate", {
    can_use = function(self, card)
        if UC.force_hand then
            return G.hand and #G.hand.cards > 1
        else
            return G.jokers and #G.jokers.cards > 0
        end
    end,
    use = function(self, card, area, copier)
        local hand_mode = UC.force_hand
        UC.force_hand = false
        G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
            func=function()
                if hand_mode then
                    local pool = {}
                    for _,c in ipairs(G.hand.cards) do pool[#pool+1]=c end
                    for i=1,math.min(5,#pool) do
                        local idx = math.random(#pool)
                        local v = table.remove(pool, idx)
                        G.hand:remove_card(v)
                        v:start_dissolve(nil, true)
                    end
                else
                    local pool = {}
                    for _,c in ipairs(G.jokers.cards) do
                        if not (c.ability and c.ability.eternal) then pool[#pool+1]=c end
                    end
                    for i=1,math.min(5,#pool) do
                        local idx = math.random(#pool)
                        local v = table.remove(pool, idx)
                        v:start_dissolve(nil, true)
                    end
                end
                ease_dollars(20)
                card_eval_status_text(card,"extra",nil,nil,nil,{message="$20",colour=G.C.MONEY})
                return true
            end
        }))
    end,
}, true)

SMODS.Consumable:take_ownership("hex", {
    can_use = function(self, card)
        if UC.force_hand then
            return G.hand and #G.hand.cards > 1
        else
            if G.jokers then
                for _,c in ipairs(G.jokers.cards) do
                    if not (c.edition and c.edition.polychrome) then return true end
                end
            end
            return false
        end
    end,
    use = function(self, card, area, copier)
        local hand_mode = UC.force_hand
        UC.force_hand = false
        if hand_mode then
            local eligible = {}
            for _,c in ipairs(G.hand.cards) do
                if not (c.edition and c.edition.polychrome) then eligible[#eligible+1]=c end
            end
            if #eligible == 0 then return end
            local chosen = eligible[math.random(#eligible)]
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
                func=function()
                    chosen:set_edition({polychrome=true}, true)
                    card_eval_status_text(chosen,"extra",nil,nil,nil,{message=localize("k_upgrade_ex"),colour=G.C.PURPLE})
                    local destroy = {}
                    for _,c in ipairs(G.hand.cards) do
                        if c ~= chosen then destroy[#destroy+1]=c end
                    end
                    for _,c in ipairs(destroy) do
                        G.hand:remove_card(c)
                        c:start_dissolve(nil, true)
                    end
                    return true
                end
            }))
        else
            local eligible = {}
            if G.jokers then
                for _,c in ipairs(G.jokers.cards) do
                    if not (c.edition and c.edition.polychrome) then eligible[#eligible+1]=c end
                end
            end
            if #eligible == 0 then return end
            local chosen = eligible[math.random(#eligible)]
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
                func=function()
                    UC.apply_edition(chosen, "polychrome")
                    card_eval_status_text(chosen,"extra",nil,nil,nil,{message=localize("k_upgrade_ex"),colour=G.C.PURPLE})
                    local destroy = {}
                    for _,c in ipairs(G.jokers.cards) do
                        if c ~= chosen and not (c.ability and c.ability.eternal) then
                            destroy[#destroy+1]=c
                        end
                    end
                    for _,c in ipairs(destroy) do c:start_dissolve(nil,true) end
                    return true
                end
            }))
        end
    end,
}, true)

SMODS.Consumable:take_ownership("ankh", {
    can_use = function(self, card)
        return G.jokers and #G.jokers.cards >= 1
    end,
    use = function(self, card, area, copier)
        local chosen = nil
        if G.jokers then
            for _,c in ipairs(G.jokers.cards) do
                if c.highlighted then chosen=c; break end
            end
            if not chosen and #G.jokers.cards > 0 then
                chosen = G.jokers.cards[math.random(#G.jokers.cards)]
            end
        end
        if not chosen then return end
        G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
            func=function()
                local destroy = {}
                for _,c in ipairs(G.jokers.cards) do
                    if c ~= chosen and not (c.ability and c.ability.eternal) then
                        destroy[#destroy+1]=c
                    end
                end
                for _,c in ipairs(destroy) do c:start_dissolve(nil,true) end
                return true
            end
        }))
        G.E_MANAGER:add_event(Event({ trigger="after", delay=0.4,
            func=function()
                local copy = copy_card(chosen, nil, nil, G.jokers)
                if chosen.edition and not chosen.edition.negative then
                    copy:set_edition(chosen.edition, true)
                else
                    copy:set_edition(nil, true)
                end
                if chosen.seal then copy:set_seal(chosen.seal, true, true) end
                copy:add_to_deck()
                G.jokers:emplace(copy)
                copy:juice_up(0.3, 0)
                card_eval_status_text(copy,"extra",nil,nil,nil,{message=localize("k_copied_ex"),colour=G.C.PURPLE})
                return true
            end
        }))
    end,
}, true)

SMODS.Consumable:take_ownership("ectoplasm", {
    can_use = function(self, card)
        if UC.force_hand then
            return G.hand and #G.hand.cards > 0
        else
            if not G.jokers or #G.jokers.cards == 0 then return false end
            for _,c in ipairs(G.jokers.cards) do
                if not (c.edition and c.edition.negative) then return true end
            end
            return false
        end
    end,
    use = function(self, card, area, copier)
        local hand_mode = UC.force_hand
        UC.force_hand = false
        local chosen = nil
        if hand_mode then
            local eligible = {}
            for _,c in ipairs(G.hand.cards) do
                if not (c.edition and c.edition.negative) then eligible[#eligible+1]=c end
            end
            if #eligible > 0 then chosen = eligible[math.random(#eligible)] end
        else
            if G.jokers then
                local eligible = {}
                for _,c in ipairs(G.jokers.cards) do
                    if not (c.edition and c.edition.negative) then eligible[#eligible+1]=c end
                end
                if #eligible > 0 then chosen = eligible[math.random(#eligible)] end
            end
        end
        G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
            func=function()
                if chosen then
                    chosen:set_edition({negative=true}, true)
                    card_eval_status_text(chosen,"extra",nil,nil,nil,{message=localize("k_upgrade_ex"),colour=G.C.PURPLE})
                end
                G.GAME.ectoplasm_count = (G.GAME.ectoplasm_count or 0) + 1
                G.hand:change_size(-G.GAME.ectoplasm_count)
                card_eval_status_text(card,"extra",nil,nil,nil,{
                    message=localize{type="variable",key="a_handsize",vars={-G.GAME.ectoplasm_count}},
                    colour=G.C.RED
                })
                return true
            end
        }))
    end,
}, true)

SMODS.Consumable:take_ownership("sigil", {
    can_use = function(self, card)
        if G.hand and #G.hand.cards > 1 then return true end
        if not UC.force_hand and G.jokers and #G.jokers.cards > 0 then return true end
        return false
    end,
    use = function(self, card, area, copier)
        local suits = {"Spades","Hearts","Clubs","Diamonds"}
        local suit = suits[math.random(#suits)]
        local targets = {}
        if not UC.force_hand and G.jokers then
            for _,c in ipairs(G.jokers.cards) do
                if c.highlighted then targets[#targets+1]=c end
            end
        end
        UC.force_hand = false
        G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
            func=function()
                if #targets > 0 then
                    for _,t in ipairs(targets) do
                        t.ability.forced_suit = suit
                        card_eval_status_text(t,"extra",nil,nil,nil,{message=localize(suit,"suits_plural"),colour=G.C.SUITS[suit]})
                    end
                else
                    for _,c in ipairs(G.hand.cards) do
                        c:change_suit(suit)
                        card_eval_status_text(c,"extra",nil,nil,nil,{message=localize(suit,"suits_plural"),colour=G.C.SUITS[suit]})
                    end
                end
                return true
            end
        }))
    end,
}, true)

SMODS.Consumable:take_ownership("ouija", {
    can_use = function(self, card)
        if G.hand and #G.hand.cards > 1 then return true end
        if not UC.force_hand and G.jokers and #G.jokers.cards > 0 then return true end
        return false
    end,
    use = function(self, card, area, copier)
        local ranks = {"2","3","4","5","6","7","8","9","10","Jack","Queen","King","Ace"}
        local rank = ranks[math.random(#ranks)]
        local targets = {}
        if not UC.force_hand and G.jokers then
            for _,c in ipairs(G.jokers.cards) do
                if c.highlighted then targets[#targets+1]=c end
            end
        end
        UC.force_hand = false
        G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
            func=function()
                if #targets > 0 then
                    for _,t in ipairs(targets) do
                        t.ability.forced_rank = rank
                        card_eval_status_text(t,"extra",nil,nil,nil,{message=rank,colour=G.C.CHIPS})
                    end
                else
                    for _,c in ipairs(G.hand.cards) do
                        c:set_base(G.P_CARDS[c.base.suit.."_"..rank])
                        card_eval_status_text(c,"extra",nil,nil,nil,{message=rank,colour=G.C.CHIPS})
                    end
                end
                G.hand:change_size(-1)
                card_eval_status_text(card,"extra",nil,nil,nil,{
                    message=localize{type="variable",key="a_handsize",vars={-1}},
                    colour=G.C.RED
                })
                return true
            end
        }))
    end,
}, true)

local function make_destroy_add(key, count, rank_pool, add_count)
    SMODS.Consumable:take_ownership(key, {
        can_use = function(self, card)
            if G.hand and #G.hand.cards > 1 then return true end
            if not UC.force_hand and G.jokers and #G.jokers.cards > 0 then return true end
            if not UC.force_hand and G.consumeables then
                for _,c in ipairs(G.consumeables.cards) do
                    if c ~= card then return true end
                end
            end
            return false
        end,
        use = function(self, card, area, copier)
            local victim = nil
            if not UC.force_hand then
                if G.jokers then
                    for _,c in ipairs(G.jokers.cards) do
                        if c.highlighted then victim=c; break end
                    end
                end
                if not victim and G.consumeables then
                    for _,c in ipairs(G.consumeables.cards) do
                        if c.highlighted and c ~= card then victim=c; break end
                    end
                end
            end
            UC.force_hand = false
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
                func=function()
                    if victim then
                        victim:start_dissolve(nil, true)
                    else
                        local pool = {}
                        for _,c in ipairs(G.hand.cards) do pool[#pool+1]=c end
                        if #pool > 0 then
                            local v = table.remove(pool, math.random(#pool))
                            G.hand:remove_card(v)
                            v:start_dissolve(nil, true)
                        end
                    end
                    local suits = {"Spades","Hearts","Clubs","Diamonds"}
                    local enhs = {"m_bonus","m_mult","m_wild","m_glass","m_steel","m_stone","m_gold","m_lucky"}
                    for i=1,add_count do
                        local r = rank_pool[math.random(#rank_pool)]
                        local s = suits[math.random(#suits)]
                        local e = enhs[math.random(#enhs)]
                        local nc = Card(
                            G.deck.T.x + G.deck.T.w/2, G.deck.T.y,
                            G.CARD_W, G.CARD_H,
                            G.P_CARDS[s.."_"..r], G.P_CENTERS[e]
                        )
                        nc:add_to_deck()
                        G.deck:emplace(nc)
                        card_eval_status_text(nc,"extra",nil,nil,nil,{message=localize("k_added_ex"),colour=G.C.GREEN})
                    end
                    return true
                end
            }))
        end,
    }, true)
end

make_destroy_add("familiar",    1, {"Jack","Queen","King"}, 3)
make_destroy_add("grim",        1, {"Ace"},                 2)
make_destroy_add("incantation", 1, {"2","3","4","5","6","7","8","9","10"}, 4)


G.FUNCS.uc_alt_use_card = function(e)
    UC.force_hand = true
    G.FUNCS.use_card(e)
end

local UC_orig_eval_card = eval_card
eval_card = function(card, context)
    local ret, post = UC_orig_eval_card(card, context)

    if card and card.seal and card.area and G.jokers and card.area == G.jokers then

        if card.seal == "Red" and context.joker_main and next(ret or {}) then
            if not ret.retriggers then ret.retriggers = {} end
            ret.retriggers[#ret.retriggers+1] = {message=localize("k_again_ex"), colour=G.C.RED}
        end

        if card.seal == "Gold" and context.joker_main and next(ret or {}) then
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
                func=function()
                    ease_dollars(3)
                    card_eval_status_text(card,"extra",nil,nil,nil,{message=localize("$").."3",colour=G.C.MONEY})
                    return true
                end
            }))
        end

        if card.seal == "Blue" and context.end_of_round and not context.blueprint then
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.2,
                func=function()
                    if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                        local planet = create_card("Planet", G.consumeables, nil, nil, nil, nil, nil, "uc_blue_seal")
                        planet:add_to_deck()
                        G.consumeables:emplace(planet)
                        planet:start_materialize()
                        card_eval_status_text(card,"extra",nil,nil,nil,{message=localize("k_planet_ex"),colour=G.C.SECONDARY_SET.Planet})
                    end
                    return true
                end
            }))
        end

    end

    return ret, post
end

local UC_orig_sell = Card.sell_card
function Card:sell_card(selling)
    if self.seal == "Purple" and self.ability and self.ability.set == "Joker" then
        G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
            func=function()
                if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                    local tarot = create_card("Tarot", G.consumeables, nil, nil, nil, nil, nil, "uc_purple_seal")
                    tarot:add_to_deck()
                    G.consumeables:emplace(tarot)
                    tarot:start_materialize()
                    card_eval_status_text(self,"extra",nil,nil,nil,{message=localize("k_tarot_ex"),colour=G.C.SECONDARY_SET.Tarot})
                end
                return true
            end
        }))
    end
    return UC_orig_sell(self, selling)
end

local UC_orig_keypressed = love.keypressed
love.keypressed = function(key, ...)
    if key == 'tab' and G.consumeables then
        local has_random = false
        for _, c in ipairs(G.consumeables.cards) do
            if UC.is_random_target_card(c) then has_random = true; break end
        end
        if has_random then
            UC.force_hand = not UC.force_hand
            play_sound('card1', 0.9, 0.4)
            local target_card = nil
            for _, c in ipairs(G.consumeables.cards) do
                if UC.is_random_target_card(c) then target_card = c; break end
            end
            attention_text({
                text = UC.force_hand and "HAND MODE" or "JOKER MODE",
                scale = 0.9, hold = 1.5, align = 'cm',
                offset = {x = 0, y = 0},
                major = target_card or G.consumeables
            })
            return
        end
    end
    if UC_orig_keypressed then UC_orig_keypressed(key, ...) end
end

local UC_orig_can_use = G.FUNCS.can_use_consumeable
G.FUNCS.can_use_consumeable = function(e)
    UC_orig_can_use(e)
    local card = e.config.ref_table
    if card and UC.is_random_target_card(card) and card.area == G.consumeables then
        if e.config.button then
            e.config.colour = UC.force_hand and G.C.BLUE or G.C.RED
        end
    end
end

SMODS.Consumable:take_ownership("wraith", {
    can_use = function(self, card)
        if UC.force_hand then
            return G.hand and #G.hand.cards >= 0
        end
        local lim = G.jokers.config and G.jokers.config.card_limit or 5
        return #G.jokers.cards < lim
    end,
    use = function(self, card, area, copier)
        local hand_mode = UC.force_hand
        UC.force_hand = false
        if hand_mode then
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
                func=function()
                    local suit_keys = {"S","H","C","D"}
                    local rank_keys = {"2","3","4","5","6","7","8","9","10","J","Q","K","A"}
                    local enhancements = {"m_bonus","m_mult","m_wild","m_glass","m_steel","m_stone","m_gold","m_lucky"}
                    local editions = {"foil","holo","polychrome","negative"}
                    local seals = {"Gold","Red","Blue","Purple"}

                    local _s = suit_keys[math.random(#suit_keys)]
                    local _r = rank_keys[math.random(#rank_keys)]
                    local _e = enhancements[math.random(#enhancements)]

                    local front = G.P_CARDS[_s.."_".._r]
                    if not front then return true end

                    local r = pseudorandom("wraith_hand")
                    local center = (r < 0.7) and (G.P_CENTERS[_e] or G.P_CENTERS.c_base) or G.P_CENTERS.c_base

                    G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                    local nc = Card(
                        G.deck.T.x + G.deck.T.w/2, G.deck.T.y,
                        G.CARD_W, G.CARD_H,
                        front, center,
                        {playing_card = G.playing_card}
                    )
                    table.insert(G.playing_cards, nc)

                    if pseudorandom("wraith_ed") < 0.5 then
                        nc:set_edition({[editions[math.random(#editions)]] = true}, true)
                    end

                    if pseudorandom("wraith_seal") < 0.5 then
                        nc:set_seal(seals[math.random(#seals)], true, true)
                    end

                    nc:add_to_deck()
                    G.hand:emplace(nc)
                    G.hand.config.card_limit = G.hand.config.card_limit + 1
                    card_eval_status_text(card,"extra",nil,nil,nil,{message=localize("k_added_ex"),colour=G.C.GREEN})
                    return true
                end
            }))
        else
            G.E_MANAGER:add_event(Event({ trigger="after", delay=0.1,
                func=function()
                    if #G.jokers.cards < (G.jokers.config and G.jokers.config.card_limit or 5) then
                        local new_joker = create_card("Joker", G.jokers, nil, 3, nil, nil, nil, "wraith")
                        new_joker:add_to_deck()
                        G.jokers:emplace(new_joker)
                        new_joker:start_materialize()
                        card_eval_status_text(card,"extra",nil,nil,nil,{message=localize("k_joker_ex"),colour=G.C.PURPLE})
                    end
                    ease_dollars(-G.GAME.dollars)
                    card_eval_status_text(card,"extra",nil,nil,nil,{message="$0",colour=G.C.MONEY})
                    return true
                end
            }))
        end
    end,
}, true)
