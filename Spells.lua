ME_Spells = {
        Casting = false,
        Channeling = false,
        ChannelSpell = "",
        Spell = "",
        ChanDuration = nil,
        Swimming = false,
}

--Split the spell and rank, incase the player includes the rank of the spell in /castx
function ME_SpellSplitRank( spell )
        local found,_,f_spell,rank = string.find(spell,"([%a%s]+)%s*(%b())")
        if found then
                rank = strtrim(string.sub(rank,2,-2))
                rank = string.gsub(rank,"(%a)(.*)", function (a,b) return string.upper(a)..b end)
                spell = strtrim(f_spell)
        end
        return spell,rank
end

function ME_GetSpellTable( spell, rankOnly)
        rankOnly = rankOnly or false
        local f_spell,f_rank = ME_SpellSplitRank(string.lower(spell))
        if ME_Spells[f_spell] then
                if f_rank and rankOnly then
                        if ME_Spells[f_spell][f_rank] then
                                return ME_Spells[f_spell][f_rank]
                        end
                else
                        return ME_Spells[f_spell]
                end
        end
        return nil
end

function ME_GetSpellID(spell, rank)
        spell = string.lower(spell)
        if not ME_Spells[spell] then
                return nil
        end
        
        if (not rank) or type(rank) == "number" then
                rank = rank or ME_Spells[spell].maxRanks
                if ME_Spells[spell].maxRanks >= rank then
                        rank = ME_Spells[spell].maxRanks
                end
                
                return ME_Spells[spell]["Rank "..rank].id        
        else
                rank = rank or ("Rank "..ME_Spells[spell].maxRanks)      
                if ME_Spells[spell][rank] then
                        return ME_Spells[spell][rank].id
                end
        end
        
        return nil
end

function ME_GetSpellEfficencay( spell )
        local spellTable = ME_GetSpellTable(spell)
        local found = false
        
        if spellTable then
                if string.find(string.lower(spell),"life tap")  then
                        if Select(2,UnitClass("player")) == "WARLOCK" and UnitManaPct("player") < 100 then
                                local scale = 563
                                local mult = 1.2
                                local rank_mult = {0.38,0.68,0.8,0.8,0.8,0.8}
                                local base_damage = {30,75,140,220,310,424}
                                
                                for i=spellTable.maxRanks,1,-1 do
                                        local rankTable = spellTable['Rank '..i]
                                        if rankTable then
                                                local formula = (base_damage[i] + rank_mult[i] * scale)
                                                if ((UnitHealth("player") >= formula) and ((UnitManaMax("player") - UnitMana("player")) >= (formula * mult))) then
                                                        return "Life Tap(Rank "..i..")", true
                                                end
                                        end
                                end
                        else
                                return nil,found
                        end
                else
                        for i=spellTable.maxRanks,1,-1 do
                                local rankTable = spellTable['Rank '..i]
                                if rankTable then
                                        local mana_cost = rankTable.spellCost
                                        if found == false and (UnitMana("player") > (mana_cost*(1-rankTable.rank/100))) then
                                                spell=spell.."(Rank "..i..")"
                                                found = true
                                                break
                                        end 
                                end
                        end
                end
        end
        
        return spell,found
end

function ME_UpdateSpellBook( ... )
        WipeTable(ME_Spells)
        
        if not ME_Spells then
                ME_Spells = {}
        end
        
        ME_SpellTooltip:SetOwner(UIParent,"ANCHOR_NONE")
        
        for i = 1, MAX_SKILLLINE_TABS do
                local name, texture, offset, numSpells = GetSpellTabInfo(i)
                local spellCost = 0
                if not name then
                        break
                end
                
                for s = offset + 1, offset + numSpells do
                        local spellName, rankName = GetSpellName(s, BOOKTYPE_SPELL)
                        local spellTexture = GetSpellTexture(s, BOOKTYPE_SPELL)
                        spellTexture = Select(3,string.find(spellTexture,"([%w%_]+)$"))
                        
                        
                        ME_SpellTooltip:ClearLines()
                        ME_SpellTooltip:SetSpell(s,BOOKTYPE_SPELL)
                        
                        local tooltipText3 = ME_SpellTooltipTextLeft3:GetText()
                        local isChanneled = (ME_SpellTooltip:NumLines()>=3 and ME_SpellTooltipTextLeft3:IsShown() and ME_SpellTooltipTextLeft3:GetText() == "Channeled") 
                        
                        if ME_SpellTooltipTextLeft2:IsShown() then
                                local found,_,manaCost,manaType = string.find(ME_SpellTooltipTextLeft2:GetText(),"(%d+)(.*)")
                                if found then
                                        spellCost = tonumber(manaCost)
                                        if manaType ~= nil or manaType ~= "" then
                                                manaType = strtrim(manaType)
                                        end
                                end
                        end
                        
                        if ME_SpellTooltipTextLeft4:IsShown() then
                        end
                        
                        rank = tonumber(Select(3,string.find(rankName, "(%d+)$")))                 
                        local l_spell = string.lower(spellName)
                        
                        if not rank then
                                rank = 1
                                rankName = "Rank 1"
                        end
                        
                        if not ME_Spells[l_spell] then
                                ME_Spells[l_spell] = {  maxRanks = rank, isChanneled = isChanneled }
                        else
                                local oldMaxRank = ME_Spells[l_spell].maxRanks
                                if (not oldMaxRank or (rank > oldMaxRank)) then
                                        ME_Spells[l_spell].maxRanks = rank
                                end
                        end
                        
                        if not ME_Spells[l_spell][rankName] then
                                ME_Spells[l_spell][rankName] = {
                                        id = tonumber(s),
                                        found = true, 
                                        spellName = spellName,
                                        spellCost = spellCost, 
                                        rank = rank, 
                                        spellTexture = spellTexture,
                                }
                        end
                end
        end
end