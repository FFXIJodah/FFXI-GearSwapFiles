-------------------------------------------------------------------------------------------------------------------
-- Setup functions for this job.  Generally should not be modified.
-------------------------------------------------------------------------------------------------------------------
include('organizer-lib.lua')
-- Also, you'll need the Shortcuts addon to handle the auto-targetting of the custom pact commands.

--[[
    Custom commands:
    
    gs c petweather
        Automatically casts the storm appropriate for the current avatar, if possible.
    
    gs c siphon
        Automatically run the process to: dismiss the current avatar; cast appropriate
        weather; summon the appropriate spirit; Elemental Siphon; release the spirit;
        and re-summon the avatar.
        
        Will not cast weather you do not have access to.
        Will not re-summon the avatar if one was not out in the first place.
        Will not release the spirit if it was out before the command was issued.
        
    gs c pact [PactType]
        Attempts to use the indicated pact type for the current avatar.
        PactType can be one of:
            cure
            curaga
            buffOffense
            buffDefense
            buffSpecial
            debuff1
            debuff2
            sleep
            nuke2
            nuke4
            bp70
            bp75 (merits and lvl 75-80 pacts)
            astralflow
--]]


-- Initialization function for this job file.
function get_sets()
    mote_include_version = 2

    -- Load and initialize the include file.
    include('Mote-Include.lua')
	include('Modes.lua')
	
end

-- Setup vars that are user-independent.  state.Buff vars initialized here will automatically be tracked.
function job_setup()
    state.Buff["Avatar's Favor"] = buffactive["Avatar's Favor"] or false
    state.Buff["Astral Conduit"] = buffactive["Astral Conduit"] or false
	
	state.NoTP = true or false

    spirits = S{"LightSpirit", "DarkSpirit", "FireSpirit", "EarthSpirit", "WaterSpirit", "AirSpirit", "IceSpirit", "ThunderSpirit"}
    avatars = S{"Carbuncle", "Fenrir", "Diabolos", "Ifrit", "Titan", "Leviathan", "Garuda", "Shiva", "Ramuh", "Odin", "Alexander", "Cait Sith"}

    magicalRagePacts = S{
        'Inferno','Earthen Fury','Tidal Wave','Aerial Blast','Diamond Dust','Judgment Bolt','Searing Light','Howling Moon','Ruinous Omen',
        'Fire II','Stone II','Water II','Aero II','Blizzard II','Thunder II',
        'Fire IV','Stone IV','Water IV','Aero IV','Blizzard IV','Thunder IV',
        'Thunderspark','Burning Strike','Meteorite','Nether Blast',
        'Meteor Strike','Heavenly Strike','Wind Blade','Geocrush','Grand Fall','Thunderstorm',
        'Holy Mist','Lunar Bay','Night Terror','Level ? Holy','Conflag Strike','Impact'}


    pacts = {}
    pacts.cure = {['Carbuncle']='Healing Ruby'}
    pacts.curaga = {['Carbuncle']='Healing Ruby II', ['Garuda']='Whispering Wind', ['Leviathan']='Spring Water'}
    pacts.buffoffense = {['Carbuncle']='Glittering Ruby', ['Ifrit']='Crimson Howl', ['Garuda']='Hastega II', ['Ramuh']='Rolling Thunder',
        ['Fenrir']='Ecliptic Growl'}
    pacts.buffdefense = {['Carbuncle']='Shining Ruby', ['Shiva']='Frost Armor', ['Garuda']='Aerial Armor', ['Titan']='Earthen Ward',
        ['Ramuh']='Lightning Armor', ['Fenrir']='Ecliptic Howl', ['Diabolos']='Noctoshield', ['Cait Sith']='Reraise II'}
    pacts.buffspecial = {['Ifrit']='Inferno Howl', ['Garuda']='Fleet Wind', ['Titan']='Earthen Armor', ['Diabolos']='Dream Shroud',
        ['Carbuncle']='Soothing Ruby', ['Fenrir']='Heavenward Howl', ['Cait Sith']='Raise II',
		['Shiva']='Crystal Blessing', ['Leviathan']='Soothing Current'}
    pacts.debuff1 = {['Shiva']='Diamond Storm', ['Ramuh']='Shock Squall', ['Leviathan']='Tidal Roar', ['Fenrir']='Lunar Cry',
        ['Diabolos']='Pavor Nocturnus', ['Cait Sith']='Eerie Eye'}
    pacts.debuff2 = {['Shiva']='Sleepga', ['Leviathan']='Slowga', ['Fenrir']='Lunar Roar', ['Diabolos']='Somnolence'}
    pacts.sleep = {['Shiva']='Sleepga', ['Diabolos']='Nightmare', ['Cait Sith']='Mewing Lullaby'}
    pacts.nuke2 = {['Ifrit']='Fire II', ['Shiva']='Blizzard II', ['Garuda']='Aero II', ['Titan']='Stone II',
        ['Ramuh']='Thunder II', ['Leviathan']='Water II'}
    pacts.nuke4 = {['Ifrit']='Fire IV', ['Shiva']='Blizzard IV', ['Garuda']='Aero IV', ['Titan']='Stone IV',
        ['Ramuh']='Thunder IV', ['Leviathan']='Water IV'}
    pacts.bp70 = {['Ifrit']='Flaming Crush', ['Shiva']='Rush', ['Garuda']='Predator Claws', ['Titan']='Mountain Buster',
        ['Ramuh']='Chaotic Strike', ['Leviathan']='Spinning Dive', ['Carbuncle']='Meteorite', ['Fenrir']='Eclipse Bite',
        ['Diabolos']='Nether Blast',['Cait Sith']='Regal Scratch'}
    pacts.bp75 = {['Ifrit']='Meteor Strike', ['Shiva']='Heavenly Strike', ['Garuda']='Wind Blade', ['Titan']='Geocrush',
        ['Ramuh']='Thunderstorm', ['Leviathan']='Grand Fall', ['Carbuncle']='Holy Mist', ['Fenrir']='Lunar Bay',
        ['Diabolos']='Night Terror', ['Cait Sith']='Level ? Holy'}
    pacts.astralflow = {['Ifrit']='Inferno', ['Shiva']='Diamond Dust', ['Garuda']='Aerial Blast', ['Titan']='Earthen Fury',
        ['Ramuh']='Judgment Bolt', ['Leviathan']='Tidal Wave', ['Carbuncle']='Searing Light', ['Fenrir']='Howling Moon',
        ['Diabolos']='Ruinous Omen', ['Cait Sith']="Altana's Favor"}

    -- Wards table for creating custom timers   
    wards = {}
    -- Base duration for ward pacts.
    wards.durations = {
        ['Crimson Howl'] = 60, ['Earthen Armor'] = 60, ['Inferno Howl'] = 60, ['Heavenward Howl'] = 60,
        ['Rolling Thunder'] = 120, ['Fleet Wind'] = 120,
        ['Shining Ruby'] = 180, ['Frost Armor'] = 180, ['Lightning Armor'] = 180, ['Ecliptic Growl'] = 180,
        ['Glittering Ruby'] = 180, ['Hastega II'] = 180, ['Noctoshield'] = 180, ['Ecliptic Howl'] = 180,
        ['Dream Shroud'] = 180,
        ['Reraise II'] = 3600
    }
    -- Icons to use when creating the custom timer.
    wards.icons = {
        ['Earthen Armor']   = 'spells/00299.png', -- 00299 for Titan
        ['Shining Ruby']    = 'spells/00043.png', -- 00043 for Protect
        ['Dream Shroud']    = 'spells/00304.png', -- 00304 for Diabolos
        ['Noctoshield']     = 'spells/00106.png', -- 00106 for Phalanx
        ['Inferno Howl']    = 'spells/00298.png', -- 00298 for Ifrit
        ['Hastega']         = 'spells/00358.png', -- 00358 for Hastega
        ['Rolling Thunder'] = 'spells/00104.png', -- 00358 for Enthunder
        ['Frost Armor']     = 'spells/00250.png', -- 00250 for Ice Spikes
        ['Lightning Armor'] = 'spells/00251.png', -- 00251 for Shock Spikes
        ['Reraise II']      = 'spells/00135.png', -- 00135 for Reraise
        ['Fleet Wind']      = 'abilities/00074.png', -- 
    }
    -- Flags for code to get around the issue of slow skill updates.
    wards.flag = false
    wards.spell = ''
    
end

-------------------------------------------------------------------------------------------------------------------
-- User setup functions for this job.  Recommend that these be overridden in a sidecar file.
-------------------------------------------------------------------------------------------------------------------

-- Setup vars that are user-dependent.  Can override this function in a sidecar file.
function user_setup()
    state.OffenseMode:options('None', 'Normal', 'Acc', 'Att', 'Mix')
    state.CastingMode:options('Normal', 'Resistant')
    state.IdleMode:options('Normal', 'PDT', 'Att','AFK','NoTP')
	
	--Lock top line to keep tp
	send_command('gs disable Main')
	send_command('gs disable Sub')
	send_command('gs disable Range')
	state.NoTP = false
	
	--Set gear to given Variables to make it easier to change them
	gear.Pet_BPDelay_Back = { name="Conveyance Cape", augments={'Summoning magic skill +4','Pet: Enmity+15','Blood Pact Dmg.+2','Blood Pact ab. del. II -2',}} -- BP II -2
	gear.Pet_BPDmg_Back = {  name="Conveyance Cape", augments={'Summoning magic skill +3','Pet: Enmity+6','Blood Pact Dmg.+3',}} --BP Dmg 3 Base SmnMagic 8 + 3Aug
	gear.CapPoints_Back = {name="Mecisto. Mantle", augments={'Cap. Point+48%','HP+11','"Mag.Atk.Bns."+2','DEF+1',}}
	gear.WakeUp_Neck = "Sacrifice Torque"
	--Perp Set
    gear.Perp_Staff = "Nirvana" -- -8 Perp
	gear.Perp_Sub = "Oneiros Grip" -- Latent Refresh 1 MP<75%
	gear.Perp_Head = "Glyphic Horn +1" -- -4 Perp
	gear.Perp_Body = "Hagondes Coat +1" -- -2 Perp
	--gear.Perp_Hands = --Ultima 99 hands -1 in storage
	gear.Perp_HandsWeather = "Beckoner's Bracers +1"
	gear.Perp_Legs = "Assiduity Pants +1" -- -3 Perp
	gear.Perp_Feet = "Beckoner's Pigaches" -- -4 Perp
	gear.Perp_Neck = "Caller's Pendant" -- -1 During Any Weather
	
	--Refresh Set
	gear.Refresh_Club = "Bolelabunga" -- +1 Refresh +1 Regen
	gear.Refresh_Shield = "Genbu's Shield" -- 
	gear.Refresh_Staff = "Nirvana" -- Perp -8
	gear.Refresh_Grip = "Oneiros Grip" -- +1 Regen Latent 1 Refresh @ <75% Base MP
	gear.Refresh_Head = "Beckoner's Horn +1" -- +2 Refresh
	gear.Refresh_Body = "Hagondes Coat +1" -- +2 Refresh
	gear.Refresh_Hands ="Serpentes Cuffs" -- Nighttime +1 Refresh
	gear.Refresh_Legs = "Assiduity Pants +1" -- +1~2 Depending on Unity Rank
	gear.Refresh_Feet = "Serpentes Sabots" -- Daytime +1 Refresh
	gear.Refresh_Neck = "Wiglen Gorget"
	gear.Refresh_RingToAU = "Balrahn's Ring" --1 Refresh in Assualts/Salvage
	gear.Refresh_RingLegion = "Maquette Ring" --1 Refresh in Legion
	
	--Pet Magic Accuracy Set
	gear.Pet_MAcc_Sub = "Vox Grip" -- +3 Smn. Magic
	gear.Pet_MAcc_Head = "Convoker's Horn +1" -- Smn Magic +15
	gear.Pet_MAcc_Body = "Beckoner's Doublet +1" -- Smn Magic +12
	gear.Pet_MAcc_Hands = "Glyphic Bracers +1" --Smn Magic +19
    gear.Pet_MAcc_Legs = { name="Helios Spats", augments={'Pet: Mag. Acc.+30','Pet: Crit.hit rate +3','Summoning magic skill +6',}} -- Base MAcc +15/ BP Dmg +6
	gear.Pet_MAcc_Feet = "Beckoner's Pigaches" --MAcc +27
	gear.Pet_MAcc_Neck = "Caller's Pendant" -- Smn. Magic +9
	gear.Pet_MAcc_Ear1 = "Andoaa Earring" -- +5Smn Magic
	gear.Pet_MAcc_Ear2 = "Smn. Earring" -- +3Smn Magic
	gear.Pet_MAcc_Ring1 = "Evoker's Ring" -- +10Smn Magic
	gear.Pet_MAcc_Ring2 = "Fevor Ring" -- +4Smn Magic
	gear.Pet_MAcc_Back = { name="Conveyance Cape", augments={'Summoning magic skill +4','Pet: Enmity+15','Blood Pact Dmg.+2','Blood Pact ab. del. II -2',}} -- Base +8Smn Magic
	gear.Pet_MAcc_Waist = "Cimmerian Sash" -- +5Smn. Magic
	
	--Pet Physical Accuracy Set
	gear.Pet_PAcc_Sub = "Vox Grip" -- +3Smn Magic
	gear.Pet_PAcc_Head = "Convoker's Horn +1" -- Smn Magic +15
	gear.Pet_PAcc_Body = "Anhur Robe" -- Smn Magic +12
	gear.Pet_PAcc_Hands = "Glyphic Bracers +1" -- +28 Acc / Smn. Magic +19 
	gear.Pet_PAcc_Legs = { name="Helios Spats", augments={'Pet: Accuracy+30 Pet: Rng. Acc.+30','Pet: Crit.hit rate +3','Blood Pact Dmg.+7',}}
	gear.Pet_PAcc_Feet = { name="Helios Boots", augments={'Pet: Accuracy+28 Pet: Rng. Acc.+28','"Avatar perpetuation cost" -2','Pet: Haste+4',}}
	gear.Pet_PAcc_Neck = "Caller's Pendant" -- Smn. Magic +9
	gear.Pet_PAcc_Ear1 = "Andoaa Earring" -- +5Smn Magic
	gear.Pet_PAcc_Ear2 = "Smn. Earring" -- +3Smn Magic
	gear.Pet_PAcc_Ring1 = "Evoker's Ring" -- +10Smn Magic
	gear.Pet_PAcc_Ring2 = "Fevor Ring" -- +4Smn Magic
	gear.Pet_PAcc_Back = { name="Conveyance Cape", augments={'Summoning magic skill +4','Pet: Enmity+15','Blood Pact Dmg.+2','Blood Pact ab. del. II -2',}} -- Base +8Smn Magic
	gear.Pet_PAcc_Waist = "Cimmerian Sash" -- +5Smn. Magic
	
	--Pet Regen Set
	gear.Pet_Regen_Head = "Selenian Cap" -- -DT -10% Regen +1
    gear.Pet_Regen_Body = { name="Telchine Chas.", augments={'Pet: Accuracy+18 Pet: Rng. Acc.+18','Pet: "Regen"+3','Pet: Damage taken -2%',}}
	gear.Pet_Regen_Hands ={ name="Telchine Gloves", augments={'Pet: Attack+14 Pet: Rng.Atk.+14','Pet: "Regen"+3','Pet: Damage taken -3%',}}
	gear.Pet_Regen_Legs = { name="Telchine Braconi", augments={'Pet: Accuracy+14 Pet: Rng. Acc.+14','Pet: "Regen"+3',}}
	gear.Pet_Regen_Feet = "Beckoner's Pigaches" -- Perp -4
	gear.Pet_Regen_Waist = "Isa Belt" --Eva +10 Regen +1 DT -3%
	
	--Elemental Siphon Set
	gear.Pet_Siphon_Head = "Convoker's Horn +1"
	gear.Pet_Siphon_Body ={ name="Telchine Chas.", augments={'Pet: Attack+6 Pet: Rng.Atk.+6','"Elemental Siphon"+35','Pet: Damage taken -4%',}}
	gear.Pet_Siphon_Hands = "Glyphic Bracers +1"
	gear.Pet_Siphon_Legs ="Beckoner's Spats +1"
	gear.Pet_Siphon_Feet = "Beckoner's Pigaches"
	--gear.Pet_Siphon_Neck = "Caller's Pendant"
	--gear.Pet_Siphon_Ear1 = {}
	--gear.Pet_Siphon_Ear2 = {}
	--gear.Pet_Siphon_Ring1 = {}
	--gear.Pet_Siphon_Ring2 = {}
	--gear.Pet_Siphon_Waist = {}
	
	--Pet Magic Attack Bonus Set
	gear.Pet_MAtb_Head ={ name="Helios Band", augments={'Pet: "Mag.Atk.Bns."+29','Pet: Crit.hit rate +4','Blood Pact Dmg.+7',}}
	gear.Pet_MAtb_Body = "Convoker's Doublet +1" -- BP Dmg +12
	gear.Pet_MAtb_Hands = { name="Helios Gloves", augments={'Pet: "Mag.Atk.Bns."+21','"Blood Boon"+5','Blood Pact Dmg.+2',}}
	gear.Pet_MAtb_Legs = { name="Helios Spats", augments={'Pet: Mag. Acc.+30','Pet: Crit.hit rate +3','Summoning magic skill +6',}}
	gear.Pet_MAtb_Feet = { name="Hagondes Sabots", augments={'Phys. dmg. taken -3%','Pet: Mag. Acc.+20',}} -- Base +25 MAtb
	gear.Pet_MAtb_Neck = "Caller's Pendant" -- Smn. Magic +9
	gear.Pet_MAtb_Ear1 = "Andoaa Earring" -- Smn. Magic +5
	gear.Pet_MAtb_Ear2 = "Esper Earring" -- BPDmg +3%
	gear.Pet_MAtb_Ring1 = "Evoker's Ring" -- +10Smn Magic
	gear.Pet_MAtb_Ring2 = "Fevor Ring" -- +4Smn Magic
	gear.Pet_MAtb_Back = gear.Pet_BPDmg_Back
	gear.Pet_MAtb_Waist = "Caller's Sash" -- +52MATB	
	--Pet Physical Attack Set
	gear.Pet_PAtt_Head ={ name="Helios Band", augments={'Pet: "Mag.Atk.Bns."+29','Pet: Crit.hit rate +4','Blood Pact Dmg.+7',}} --BP Dmg +4 Crit Hit 4
	gear.Pet_PAtt_Body = "Convoker's Doublet +1" -- BP Dmg +12
	gear.Pet_PAtt_Hands = "Auspex Gages" --BPDmg +4% Att +9
	gear.Pet_PAtt_Legs = { name="Helios Spats", augments={'Pet: Attack+28 Pet: Rng.Atk.+28','Pet: "Dbl. Atk."+5','Blood Pact Dmg.+5',}} --Base BP Dmg +6
	gear.Pet_PAtt_Feet = "Convoker's Pigaches +1" --BP Dmg +6
	gear.Pet_PAtt_Neck = "Sacrifice Torque" -- Att +3
	gear.Pet_PAtt_Ear1 = "Esper Earring" -- BPDmg +3%
	gear.Pet_PAtt_Ear2 = "Domes. Earring" -- DA +3%
	gear.Pet_PAtt_Ring1 = "Evoker's Ring" -- +10Smn Magic
	gear.Pet_PAtt_Ring2 = "Fevor Ring" -- +4Smn Magic
	gear.Pet_PAtt_Back = gear.Pet_BPDmg_Back
	gear.Pet_PAtt_Waist = "Mujin Obi" -- +10 Att
	
	--Summon Magic Set
	gear.Pet_SmnMagic_Main = {}
	gear.Pet_SmnMagic_Sub = "Vox Grip" -- +3Smn Magic
	gear.Pet_SmnMagic_Head = "Convoker's Horn +1" -- +15Smn Magic
	gear.Pet_SmnMagic_Body = "Beckoner's Doublet +1" -- +12 Smn Magic
	gear.Pet_SmnMagic_Hands = "Glyphic Bracers +1" -- +19 Smn Magic
	gear.Pet_SmnMagic_Legs = "Beckoner's Spats +1" -- +10 Smn Magic
	gear.Pet_SmnMagic_Feet = "Mdk. Crackows +1" -- +11 Smn Magic
	gear.Pet_SmnMagic_Back = { name="Conveyance Cape", augments={'Summoning magic skill +4','Pet: Enmity+15','Blood Pact Dmg.+2','Blood Pact ab. del. II -2',}} -- +12 Smn Magic
	gear.Pet_SmnMagic_Neck = "Caller's Pendant" -- +9Smn Magic
	gear.Pet_SmnMagic_Waist = "Cimmerian Sash" -- +5Smn. Magic
	gear.Pet_SmnMagic_Ear1 = "Andoaa Earring" -- +5Smn Magic
	gear.Pet_SmnMagic_Ear2 = "Smn. Earring" -- +3Smn Magic
	gear.Pet_SmnMagic_Ring1 = "Evoker's Ring" -- +10Smn Magic
	gear.Pet_SmnMagic_Ring2 = "Fevor Ring" -- +4Smn Magic
	
	--BloodPact Reduction set 100Merit BP II -5 
	gear.Pet_BPDelay_Ammo = "Seraphicaller" -- BP II -5
	gear.Pet_BPDelay_Head = "Glyphic Horn +1" -- BP I -8
	gear.Pet_BPDelay_Body = "Glyphic Doublet +1"-- BP II -2
	gear.Pet_BPDelay_Hands = "Glyphic Bracers +1"-- BP I -6
	gear.Pet_BPDelay_Legs = "Glyphic Spats +1"-- BP I -6
	gear.Pet_BPDelay_Feet = "Glyph. Pigaches +1"-- BP II -1
	gear.Pet_BPDelay_Back = {  name="Conveyance Cape", augments={'Summoning magic skill +4','Pet: Enmity+15','Blood Pact Dmg.+2','Blood Pact ab. del. II -2',}} -- BP II -3
	gear.Pet_BPDelay_Ear1 = "Gifted Earring" --Making sure Esper Earring is not on
	gear.Pet_BPDelay_Ear2 = "Loquacious Earring" --Making sure Esper Earring is not on
	
	--Fast Cast Set Max FC 40% / Max Spell Reduc 40%
	gear.FastCast_Head ="Nahtirah Hat" -- +10% Fast Cast
	gear.FastCast_Body = "Anhur Robe" -- +10% Fast Cast
	gear.FastCast_Hands = { name="Otomi Gloves", augments={'Phys. dmg. taken -2%','Magic dmg. taken -2%','"Fast Cast"+3',}} -- 3% Fast Cast
	gear.FastCast_Legs = "Artsieq Hose" -- 5% Fast Cast
	gear.FastCast_Feet = { name="Uk'uxkaj Boots", augments={'Phys. dmg. taken -2%','Magic dmg. taken -2%','"Fast Cast"+3',}} -- 3% Fast Cast
	gear.FastCast_Neck = "Caller's Pendant" -- +9Smn Magic
	gear.FastCast_Back = "Swith Cape" -- 3% Fast Cast
	gear.FastCast_Waist = "Witful Belt" -- 3% Fast Cast 3% Insta Cast
	gear.FastCast_Ear1 = "Andoaa Earring" -- +5Smn Magic
	gear.FastCast_Ear2 = "Loquacious Earring" -- +2% Fast Cast
	gear.FastCast_Ring1 = "Evoker's Ring" -- +10Smn Magic
	gear.FastCast_Ring2 = "Fevor Ring" -- +4Smn Magic
	
	--Magic Attack Bonus Set (GarlandOfBliss MND/STR + MAB)
	gear.MAB_Head = "Buremte Hat" --MagDmg +35 / Base MND 24 / STR 20 Aug 8 MND
	gear.MAB_Body = "Artsieq Jubbah" --Base +10MAB / Aug + 15MAB 19MND/STR18
	gear.MAB_Hands = "Yaoyotl Gloves" -- MAB 15 33MND / 6STR
	gear.MAB_Legs = "Hagondes Pants +1" --MAB 25 22MND / 23STR
	gear.MAB_Feet = "Umbani Boots" --MAB 20 MDmg 10 19MND / 10STR
	gear.MAB_Neck = "Eddy Necklace" --MAB11
	gear.MAB_Ear1 = "Hecate's Earring" --MAB 6
	gear.MAB_Ear2 = "Novio Earring" --MAB 7
	gear.MAB_Ring1 = "Rajas Ring" -- STR 5
	gear.MAB_Ring2 = "Shiva Ring" -- INT 8
	gear.MAB_Back = "Pahtli Cape" -- MND 8
	gear.MAB_Waist = "Sekhmet Corset" -- MDmg 15
	

	select_default_macro_book()
	 
end


-- Define sets and vars used by this job file.
function init_gear_sets()
    --------------------------------------
    -- Precast Sets
    --------------------------------------
    
    -- Precast sets to enhance JAs
    sets.precast.JA['Astral Flow'] = {head="Glyphic Horn +1"}
    
	
    sets.precast.JA['Elemental Siphon'] = {main="Nirvana", sub=gear.Pet_SmnMagic_Sub,
        head=gear.Pet_Siphon_Head, neck=gear.Pet_SmnMagic_Neck, ear1=gear.Pet_SmnMagic_Ear1, ear2=gear.Pet_SmnMagic_Ear2,
        body=gear.Pet_Siphon_Body, hands=gear.Pet_Spihon_Hands, ring1=gear.Pet_SmnMagic_Ring1, ring2=gear.Pet_SmnMagic_Ring2,
        back=gear.Pet_SmnMagic_Back, waist=gear.Pet_SmnMagic_Waist, legs=gear.Pet_Siphon_Legs, feet=gear.Pet_Siphon_Feet}

    sets.precast.JA['Mana Cede'] = {hands="Beckoner's Bracers +1"}

    -- Pact delay reduction gear
    sets.precast.BloodPactWard = {main="Nirvana", sub="Oneiros Grip",ammo=gear.Pet_BPDelay_Ammo,
		head=gear.Pet_BPDelay_Head, ear1=gear.Pet_BPDelay_Ear1,ear2=gear.Pet_BPDelay_Ear2,
		body=gear.Pet_BPDelay_Body, hands=gear.Pet_BPDelay_Hands,
		legs=gear.Pet_BPDelay_Legs, feet=gear.Pet_BPDelay_Feet,back=gear.Pet_BPDelay_Back}

    sets.precast.BloodPactRage = sets.precast.BloodPactWard

    -- Fast cast sets for spells
    
    sets.precast.FC = {
        head=gear.FastCast_Head, neck=gear.FastCast_Neck, ear1=gear.FastCast_Ear1, ear2=gear.FastCast_Ear2,
        body=gear.FastCast_Body, hands=gear.FastCast_Hands, ring1=gear.FastCast_Ring1, ring2=gear.FastCast_Ring2,
        back=gear.FastCast_Back, waist=gear.FastCast_Waist, legs=gear.FastCast_Legs, feet=gear.FastCast_Feet}

    sets.precast.FC['Enhancing Magic'] = set_combine(sets.precast.FC, {waist="Siegel Sash"})
	
	sets.precast.FC.Stoneskin = set_combine(sets.precast.FC, {head="Umuthi Hat",waist="Siegel Sash"})
	
	sets.precast.FC.Cure = set_combine(sets.precast.FC, {body="Heka's Kalasiris",back="Pahtli Cape",legs="Nabu's Shalwar"})

       
    -- Weaponskill sets
    -- Default set for any weaponskill that isn't any more specifically defined
    sets.precast.WS = {
        head="Buremte Hat",neck="Fotia Gorget",ear1="Bladeborn Earring",ear2="Steelflash Earring",
        body="Helios Jacket",hands="Glyphic Bracers +1",ring1="Rajas Ring",ring2="K'ayres Ring",
        back="Pahtli Cape",waist="Fotia Belt",legs="Telchine Braconi",feet="Con. Pigaches +1"}

    -- Specific weaponskill sets.  Uses the base set if an appropriate WSMod version isn't found.
    sets.precast.WS['Myrkr'] = {
        head="Nahtirah Hat", neck="Fotia Gorget", ear1="Gifted Earring",ear2="Loquacious Earring",
        body="Convoker's Doublet +1",hands="Glyphic Bracers +1",ring1="Evoker's Ring",ring2="Sangoma Ring",
        back="Pahtli Cape",waist="Fotia Belt",legs="Glypic Spats +1",feet="Glyphic Pigaches +1"}

    sets.precast.WS['Garland of Bliss'] = {
		head=gear.MAB_Head, neck="Fotia Gorget", ear1=gear.MAB_Ear1, ear2=gear.MAB_Ear2,
		body=gear.MAB_Body, hands=gear.MAB_Hands, ring1=gear.MAB_Ring1, ring2=gear.MAB_Ring2,
		back=gear.MAB_Back, waist="Fotia Belt", legs=gear.MAB_Legs, feet=gear.MAB_Feet}
    --------------------------------------
    -- Midcast sets
    --------------------------------------

    sets.midcast.FastRecast = {
        head=gear.FastCast_Head, neck=gear.FastCast_Neck, ear1=gear.FastCast_Ear1, ear2=gear.FastCast_Ear2,
        body=gear.FastCast_Body, hands=gear.FastCast_Hands,ring1=gear.FastCast_Ring1, ring2=gear.FastCast_Ring2,
        back=gear.FastCast_Back, waist=gear.FastCast_Waist, legs=gear.FastCast_Legs, feet=gear.FastCast_Feet}

    sets.midcast.Cure = { main="Tamaxchi", sub ="Genbu's Shield",
        head="Buremte Hat",ear1="Gifted Earring",ear2="Loquacious Earring",
        body="Heka's Kalasiris",hands="Bokwus Gloves",ring1="Ephedra Ring",ring2="Ephedra Ring",
        back="Pahtli Cape",waist="Cascade Belt",legs="Assiduity pants +1",feet="Glyph. Pigaches +1"}
	
	sets.midcast['Enhancing Magic'] = { main="Kirin's Pole", sub="Fulcio Grip",
		head="Umuthi Hat", neck="Colossus's Torque",
		body=gear.Pet_Regen_Body, hands="Ayao's Gages",
		waist="Cascade Belt", legs = "Shedir Seraweels"}

    sets.midcast.Stoneskin =  set_combine(sets.midcast['Enhancing Magic'], {neck="Stone Gorget",waist="Siegel Sash"})
	
	sets.midcast.Cursna = set_combine(sets.midcast.Cure, {legs="Nabu's Shalwar"})

    sets.midcast['Elemental Magic'] = {main="Nirvana",sub="Oneiros Grip",
        head=gear.MAB_Head, neck=gear.MAB_Neck, ear1=gear.MAB_Ear1, ear2=gear.MAB_Ear2,
        body=gear.MAB_Body, hands=gear.MAB_Hands, ring1=gear.MAB_Ring1, ring2=gear.MAB_Ring2,
        back=gear.MAB_Back, waist=gear.MAB_Waist, legs=gear.MAB_Legs, feet=gear.MAB_Feet}

    sets.midcast['Dark Magic'] = {main="Nirvana",sub="Oneiros Grip",
        head="Nahtirah Hat",neck="Aesir Torque",ear1="Lifestorm Earring",ear2="Psystorm Earring",
        body="Artsieq Jubbah",hands="Yaoyotl Gloves",ring1="Maquette Ring",ring2="Balrahn's Ring",
        waist="Fuchi-no-Obi",legs="Bokwus Slops",feet="Umbani Boots"}


    -- Avatar pact sets.  All pacts are Ability type.
    --General Pact Sets
    sets.midcast.Pet.BloodPactWard = {main="Nirvana", sub="Vox Grip", ammo="Seraphicaller",
        head=gear.Pet_SmnMagic_Head, neck=gear.Pet_SmnMagic_Neck, ear1=gear.Pet_SmnMagic_Ear1, ear2=gear.Pet_SmnMagic_Ear2,
        body=gear.Pet_SmnMagic_Body, hands=gear.Pet_SmnMagic_Hands, ring1=gear.Pet_SmnMagic_Ring1,ring2=gear.Pet_SmnMagic_Ring2,
        back=gear.Pet_SmnMagic_Back, waist=gear.Pet_SmnMagic_Waist, legs=gear.Pet_SmnMagic_Legs, feet=gear.Pet_SmnMagic_Feet}

    sets.midcast.Pet.DebuffBloodPactWard = {main="Nirvana", sub="Vox Grip", ammo="Seraphicaller",
        head=gear.Pet_MAcc_Head, neck=gear.Pet_MAcc_Neck, ear1=gear.Pet_MAcc_Ear1, ear2=gear.Pet_MAcc_Ear2,
        body=gear.Pet_MAcc_Body, hands=gear.Pet_MAcc_Hands, ring1=gear.Pet_MAcc_Ring1, ring2=gear.Pet_MAcc_Ring2,
        back=gear.Pet_MAcc_Back, waist=gear.Pet_MAcc_Waist, legs=gear.Pet_MAcc_Legs, feet=gear.Pet_MAcc_Feet}
    
    sets.midcast.Pet.PhysicalBloodPactRage = {main="Nirvana", sub="Vox Grip", ammo="Seraphicaller",
        head=gear.Pet_PAtt_Head, neck=gear.Pet_PAtt_Neck, ear1=gear.Pet_PAtt_Ear1, ear2=gear.Pet_PAtt_Ear2,
        body=gear.Pet_PAtt_Body, hands=gear.Pet_PAtt_Hands, ring1=gear.Pet_PAtt_Ring1, ring2=gear.Pet_PAtt_Ring2,
        back=gear.Pet_PAtt_Back, waist=gear.Pet_PAtt_Waist, legs=gear.Pet_PAtt_Legs, feet=gear.Pet_PAtt_Feet}
		
	sets.midcast.Pet.PhysicalBloodPactRage.Mix = {
	
	
	}

    sets.midcast.Pet.PhysicalBloodPactRage.Acc = {main="Nirvana", sub="Vox Grip", ammo="Seraphicaller",
        head=gear.Pet_PAcc_Head, neck=gear.Pet_PAcc_Neck, ear1=gear.Pet_PAcc_Ear1, ear2=gear.Pet_PAcc_Ear2,
        body=gear.Pet_PAcc_Body, hands=gear.Pet_PAcc_Hands, ring1=gear.Pet_PAcc_Ring1, ring2=gear.Pet_PAcc_Ring2,
        back=gear.Pet_PAcc_Back, waist=gear.Pet_PAcc_Waist, legs=gear.Pet_PAcc_Legs, feet=gear.Pet_PAcc_Feet}

    sets.midcast.Pet.MagicalBloodPactRage = {main="Nirvana", sub="Vox Grip", ammo="Seraphicaller",
        head=gear.Pet_MAtb_Head, neck=gear.Pet_MAtb_Neck, ear1=gear.Pet_MAtb_Ear1, ear2=gear.Pet_MAtb_Ear2,
        body=gear.Pet_MAtb_Body, hands=gear.Pet_MAtb_Hands, ring1=gear.Pet_MAtb_Ring1, ring2=gear.Pet_MAtb_Ring2,
        back=gear.Pet_MAtb_Back, waist=gear.Pet_MAtb_Waist, legs=gear.Pet_MAtb_Legs, feet=gear.Pet_MAtb_Feet}

    sets.midcast.Pet.MagicalBloodPactRage.Acc = sets.midcast.Pet.DebuffBloodPactWard
	
	--Singular Pacts Special Sets
	
	--Flaming Crush Set
	sets.midcast.Pet['Flaming Crush']= {main="Nirvana", sub="Vox Grip", ammo="Seraphicaller",
        head=gear.Pet_MAtb_Head, neck=gear.Pet_PAtt_Neck, ear1=gear.Pet_PAtt_Ear1,ear2=gear.Pet_PAtt_Ear2,
        body=gear.Pet_MAtb_Body, hands=gear.Pet_MAtb_Hands, ring1=gear.Pet_MAtb_Ring1, ring2=gear.Pet_MAtb_Ring2,
        back=gear.Pet_MAtb_Back, waist=gear.Pet_MAtb_Waist, legs=gear.Pet_PAtt_Legs, feet="Hag. Sabots +1"}
	--For Atomos, uses MAcc set	
	sets.midcast.Pet['Deconstruction'] = sets.midcast.Pet.DebuffBloodPactWard


    -- Spirits cast magic spells, which can be identified in standard ways.
    
    sets.midcast.Pet.WhiteMagic = {legs="Glyphic Spats +1"}
    
    sets.midcast.Pet['Elemental Magic'] = set_combine(sets.midcast.Pet.MagicalBloodPactRage, {legs=gear.Pet_MAtb_Legs})

    sets.midcast.Pet['Elemental Magic'].Resistant = set_combine(sets.midcast.Pet.MagicalBloodPactRage.Acc, {legs=gear.Pet_MAcc_Legs})

    

    --------------------------------------
    -- Idle/resting/defense/etc sets
    --------------------------------------
    
    -- Resting sets
    sets.resting = {main=gear.Refresh_Club, sub=gear.Refresh_Shield, ammo="Seraphicaller",
        head=gear.Refresh_Head, neck=gear.Refresh_Neck, ear1=gear.Refresh_Ear1, ear2=gear.Refresh_Ear2,
        body=gear.Refresh_Body, hands=gear.Refresh_Hands, ring1=gear.Refresh_Ring1, ring2=gear.Refresh_Ring2,
        back=gear.Refresh_Back, waist=gear.Refresh_Waist, legs=gear.Refresh_Legs, feet=gear.Refresh_Feet}
    
    -- Idle sets
    sets.idle = {main="Nirvana",sub="Oneiros Grip",ammo="Seraphicaller",
        head=gear.Refresh_Head, neck=gear.Refresh_Neck, ear1=gear.Refresh_Ear1, ear2=gear.Refresh_Ear2,
        body=gear.Refresh_Body, hands=gear.Refresh_Hands, ring1=gear.Refresh_Ring1, ring2=gear.Refresh_Ring2,
        back=gear.Refresh_Back, waist=gear.Refresh_Waist, legs=gear.Refresh_Legs, feet=gear.Refresh_Feet}

    sets.idle.PDT = {main="Nirvana",sub="Oneiros Grip",ammo="Seraphicaller",
        head="Convoker's Horn +1",neck="Wiglen Gorget",ear1="Gifted Earring",ear2="Loquacious Earring",
        body="Hagondes Coat +1",hands="Serpentes Cuffs",ring1="Sheltered Ring",ring2="Defending Ring",
        back="Kumbira Cape",waist="Fucho-no-Obi",legs="Assid. Pants +1",feet=gear.Perp_Feet}
		
	sets.idle.AFK = {main="Nirvana", sub="Oneiros Grip",ammo="Seraphicaller",
        head="Convoker's Horn +1",neck="Wiglen Gorget",ear1="Gifted Earring",ear2="Loquacious Earring",
        body="Hagondes Coat +1",hands="Serpentes Cuffs",ring1="Paguroidea Ring",ring2="Defending Ring",
        back="Kumbira Cape",waist="Fucho-no-Obi",legs="Assid. Pants +1",feet=gear.Perp_Feet}
		
	sets.idle.NoTP = sets.resting

    -- perp costs:
    -- spirits: 7
    -- carby: 11 (5 with mitts)
    -- fenrir: 13
    -- others: 15
    
    -- Max useful -perp gear is 1 less than the perp cost (can't be reduced below 1)
    -- Aim for -14 perp, and refresh in other slots.
    
    -- -perp gear:
    -- Gridarvor: -5
    -- Glyphic Horn: -4
    -- Caller's Doublet +2/Glyphic Doublet: -4
    -- Evoker's Ring: -1
    -- Convoker's Pigaches: -4
    -- total: -18
    
    -- Can make due without either the head or the body, and use +refresh items in those slots.
    
    sets.idle.Avatar = {main="Nirvana",sub="Oneiros Grip",ammo="Seraphicaller",
        head="Convoker's Horn +1", neck="Caller's Pendant", ear1="Gifted Earring", ear2="Loquacious Earring",
        body="Hagondes Coat +1", hands=gear.Refresh_Hands, ring1="Evoker's Ring", ring2="Sheltered Ring",
        back="Kumbira Cape", waist="Fucho-no-Obi", legs="Assid. Pants +1", feet=gear.Perp_Feet}

    sets.idle.PDT.Avatar = {main="Nirvana",sub="Oeniros Grip",ammo="Seraphicaller",
        head="Convoker's Horn +1",neck="Caller's Pendant",ear1="Gifted Earring",ear2="Loquacious Earring",
        body="Hagondes Coat +1",hands="Artsieq Cuffs",ring1="Evoker's Ring",ring2="Defending Ring",
        back="Kumbira Cape",waist="Fucho-no-Obi",legs="Assid. Pants +1",feet=gear.Perp_Feet}

    sets.idle.Spirit = {main="Nirvana",sub="Oneiros Grip",ammo="Seraphicaller",
        head="Convoker's Horn +1",neck="Caller's Pendant",ear1="Anodaa Earring",ear2="Smn. Earring",
        body="Beckoner's Doublet +1",hands="Glyphic Bracers +1",ring1="Evoker's Ring",ring2="Fevor Ring",
        back="Conveyance Cape",waist="Cimmerian Sash",legs="Glyphic Spats +1",feet="Mdk. Crackows +1"}
		
	sets.idle.PDT.Spirit = {main="Nirvana",sub="Oneiros Grip",ammo="Seraphicaller",
        head="Convoker's Horn +1",neck="Caller's Pendant",ear1="Anodaa Earring",ear2="Smn. Earring",
        body="Anhur Robe",hands="Glyphic Bracers +1",ring1="Evoker's Ring",ring2="Fevor Ring",
        back="Conveyance Cape",waist="Cimmerian Sash",legs="Glyphic Spats +1",feet="Mdk. Crackows +1"}

    sets.idle.Town = {main="Nirvana",sub="Oneiros Grip",ammo="Seraphicaller",
        head="Beckoner's Horn +1",neck="Fotia Gorget",ear1="Esper Earring",ear2="Domes. Earring",
        body="Hagondes Coat +1",hands="Beckoner's Bracers +1",ring1="Sheltered Ring",ring2="Sangoma Ring",
        back="Kumbira Cape",waist="Fucho-no-Obi",legs="Tatsu. Sitagoromo",feet="Beckoner's Pigaches"}

    -- Favor uses Caller's Horn instead of Convoker's Horn for refresh
    sets.idle.Avatar.Favor = {head="Beckoner's Horn +1"}
	--Sets to be used while only Avatar is engaged
	sets.idle.Avatar.Melee = { main="Nirvana",sub="Oneiros Grip",ammo="Seraphicaller",
		head="Con. Horn +1", neck="Caller's Pendant",ear1="Handler's Earring",ear2="Domes. Earring",
		body="Glyphic Doublet +1",hands="Artsieq Cuffs",ring1="Evoker's Ring",
		back="Conveyance Cape",waist="Moepapa Stone",legs="Con. Spats +1", feet=gear.Perp_Feet}
	
	sets.idle.PDT.Avatar.Melee = {
		head=gear.Pet_Regen_Head, neck="Caller's Pendant",ear1="Handler's Earring",ear2="Domes. Earring",
		body=gear.Pet_Regen_Body,hands=gear.Pet_Regen_Hands,ring1="Evoker's Ring",
		back="Conveyance Cape",waist="Isa Belt",legs=gear.Pet_Regen_Legs, feet=gear.Perp_Feet}
	
        
    sets.perp = {}
    -- Caller's Bracer's halve the perp cost after other costs are accounted for.
    -- Using -10 (Gridavor, ring, Conv.feet), standard avatars would then cost 5, halved to 2.
    -- We can then use Hagondes Coat and end up with the same net MP cost, but significantly better defense.
    -- Weather is the same, but we can also use the latent on the pendant to negate the last point lost.
    sets.perp.Day = {hands="Beckoner's Bracers +1"}
    sets.perp.Weather = {hands="Beckoner's Bracers +1"}
    -- Carby: Mitts+Conv.feet = 1/tick perp.  Everything else should be +refresh
    sets.perp.Carbuncle = {main="Nirvana", sub="Oneiros Grip",
        head="Convoker's Horn +1",
		body="Hagondes Coat +1",hands="Serpentes Cuffs",
		legs="Assid. Pants",feet="Serpentes Sabots"}
    -- Diabolos's Rope doesn't gain us anything at this time
    --sets.perp.Diabolos = {waist="Diabolos's Rope"}
    sets.perp.Alexander = set_combine(sets.midcast.Pet.BloodPactWard, {legs='Ngen Seraweels', feet='Mdk. Crackows +1'})

    --sets.perp.staff_and_grip = {main=gear.perp_staff,sub="Achaq Grip"}
    
    -- Defense sets
    sets.defense.PDT = {
        head="Hagondes Hat +1",neck="Wiglen Gorget",ear1="Gifted Earring",ear2="Loquacious Earring",
        body="Hagondes Coat +1",hands="Otomi Gloves",ring1="Defending Ring",ring2="Dark Ring",
        back="Umbra Cape",waist="Fucho-no-Obi",legs="Hagondes Pants +1",feet="Hagondes Sabots +1"}

    sets.defense.MDT = {
        head="Hagondes Hat +1",neck="Twilight Torque",ear1="Gifted Earring",ear2="Loquacious Earring",
        body="Con. Doublet +1",hands="Otomi Gloves",ring1="Defending Ring",ring2="Dark Ring",
        back="Umbra Cape",waist="Fucho-no-Obi",legs="Hagondes Pants +1",feet="Hagondes Sabots +1"}

    sets.Kiting = {legs="Tatsu. Sitagoromo"}
    
    sets.latent_refresh = {waist="Fucho-no-obi"}
    

    --------------------------------------
    -- Engaged sets
    --------------------------------------
    
    -- Normal melee group
    sets.engaged = {main="Nirvana", sub="Oneiros Grip",ammo="Seraphicaller",
        head="Con. Horn +1",neck="Caller's Pendant",ear1="Moonshade Earring",ear2="Domes. Earring",
        body="Hagondes Coat +1",hands="Con. Bracers +1",ring1="Rajas Ring",ring2="Defending Ring",
        back="Kumbira Cape",waist="Kuku Stone",legs=gear.Pet_Regen_Legs,feet="Con. Pigaches +1"}
end

-------------------------------------------------------------------------------------------------------------------
-- Job-specific hooks for standard casting events.
-------------------------------------------------------------------------------------------------------------------

-- Set eventArgs.handled to true if we don't want any automatic gear equipping to be done.
-- Set eventArgs.useMidcastGear to true if we want midcast gear equipped on precast.
function job_precast(spell, action, spellMap, eventArgs)

	--Allow equipment that will cause tp lose to be changed
	--For Nirvana people that want to be able to switch into full mage mode when need, Use IdleMode NoTP
	--if state.IdleMode.current == 'NoTP' and state.NoTP == false then 
		
		--send_command('gs enable Main')
		--send_command('gs enable Sub')
		--send_command('gs enable Range')
		
	--	state.NoTP = true
	
	--elseif state.IdleMode.current ~= 'NoTP' and state.NoTP == true then
	
		--send_command('gs disable Main')
	--	send_command('gs disable Sub')
		--send_command('gs disable Range')
		
	--	state.NoTP = false
		
	--end
	
    if state.Buff['Astral Conduit'] then
        eventArgs.useMidcastGear = true
    end
	
	if state.IdleMode.current == 'AFK' and spell.type == 'BloodPactRage' and windower.ffxi.get_ability_recasts()[spell.recast_id] < 10 then

		cast_delay(windower.ffxi.get_ability_recasts()[spell.recast_id])
		
	end
	
end

function job_midcast(spell, action, spellMap, eventArgs)

    if state.Buff['Astral Conduit'] and pet_midaction() then
        eventArgs.handled = true
    end
	
	
end

-- Runs when pet completes an action.
function job_pet_aftercast(spell, action, spellMap, eventArgs)

    if not spell.interrupted and spell.type == 'BloodPactWard' and spellMap ~= 'DebuffBloodPactWard' then
        wards.flag = true
        wards.spell = spell.english
        send_command('wait 4; gs c reset_ward_flag')
    end
	
	if state.Buff['Astral Conduit'] then
        eventArgs.handled = true
    end
	
end

-------------------------------------------------------------------------------------------------------------------
-- Job-specific hooks for non-casting events.
-------------------------------------------------------------------------------------------------------------------

-- Called when a player gains or loses a buff.
-- buff == buff gained or lost
-- gain == true if the buff was gained, false if it was lost.
function job_buff_change(buff, gain)
    --Set Avatar's favor into command
	local command = ''
	command = command..'wait 1.1;input /ja "'.."Avatar's Favor"..'" <me>'
	
    if state.Buff[buff] ~= nil then
        handle_equipping_gear(player.status)
    elseif storms:contains(buff) then
        handle_equipping_gear(player.status)
    end
	
	--This will attempt to keep you alive while AFK, Mainly used with Garuda
	if state.IdleMode.current == 'AFK' then
		
		if not buffactive['Commitment'] and player.inventory['Capacity Ring'] and pet.status ~= 'Engaged' then
			
			--send_command('input /equip ring1 "Capacity Ring";wait 7; input /item "Capacity Ring" <me>')
		
		end
		
		
		if pet.name == 'Garuda' then
			if pet.hpp < 70 then
				
				send_command('wait 2; gs c pact curaga')
			end
			
			if not buffactive['Haste'] then
				send_command('wait 2;gs c pact buffoffense')
				
			end
			
			if not buffactive['Blink'] then
				send_command('wait 2;gs c pact buffdefense')
				
				if pet.status == 'Engaged' then
				
					send_command('wait 4;gs c pact bp70')
				
				end
				
			end
			--if not buffactive['Stoneskin'] then
			--	send_command('wait 6;input /ma "Stoneskin" <me>')
			--end
			
		end
		
		if pet.name == 'Ifrit' then
			
			if not buffactive['Enfire'] then
				send_command('wait 2;input /pet "Inferno Howl" <me>')
			end
			
			if not buffactive['Aquaveil'] then
				send_command('input /ma "Aquaveil" <me>')
			end
			
			if not buffactive['Blink'] then
				send_command('input /ma "Blink" <me>')
			end
			
			if not buffactive['Stoneskin'] then
				send_command('wait 6;input /ma "Stoneskin" <me>')
			end
			send_command('wait 7;input /pet "Flaming Crush" <bt>')
		
		end
		
		if not buffactive['Protect'] then
			send_command('input /ma "Protect III" <me>')
			send_command('wait 5;input /ma "Shell II" <me>')
		end
		
	end
	
	--Activates Avatar's Favor if not active or times out
		if not buffactive["Avatar's Favor"] then
			send_command(command)
		end

end


-- Called when the player's pet's status changes.
-- This is also called after pet_change after a pet is released.  Check for pet validity.
function job_pet_status_change(newStatus, oldStatus, eventArgs)
	--send_command('input /echo oldStatus '..oldStatus..' newStatus '..newStatus)
    if pet.isvalid and not midaction() and not pet_midaction() and (newStatus == 'Engaged' or oldStatus == 'Engaged') then
        handle_equipping_gear(player.status, newStatus)
    end
	--This will attempt to keep you alive while AFK, Mainly Used with Garuda
	if state.IdleMode.current == 'AFK' then
		--if not buffactive['Stoneskin'] then
		--	send_command('/ma "Stoneskin" <me>')
		--end
		
		if pet.name == 'Garuda' then
			if pet.status == 'Engaged' then
					send_command('wait 4;input /ja "Apogee" <me>;wait 3;gs c pact bp70;wait 5;')
					--send_command('wait 5;gs c pact bp70')
				
				if not buffactive['Blink'] then
					send_command('wait 1;gs c pact buffdefense')
				end
			
				--send_command('wait 1;input /ja "Apogee" <me>')
				if pet.hpp < 80 or player.hpp < 80 then
					send_command('wait 3;input /pet "Whispering Wind" <me>')
				end
			
			else 
			
				if pet.hpp < 80 or player.hpp < 80 then
					send_command('wait 3;input /pet "Whispering Wind" <me>')
				end
				
			end
	
		end
		
		if pet.name == 'Ifrit' then
		
			if pet.status == 'Engaged' then
				if not buffactive['Warcry'] then
					send_command('wait 1;input /pet "Crimson Howl" <me>')
				end
				send_command('wait 8;input /pet "Flaming Crush" <bt>')
			end
			
		end
		
		if not pet.isvalid then
			send_command('wait 4;input /ma "Ifrit" <me>')
		end
		
		--send_command('wait 4;input /ma "Cure" <me>')
		
	end
end


-- Called when a player gains or loses a pet.
-- pet == pet structure
-- gain == true if the pet was gained, false if it was lost.
function job_pet_change(petparam, gain)
    classes.CustomIdleGroups:clear()
    if gain then
        if avatars:contains(pet.name) then
            classes.CustomIdleGroups:append('Avatar')
        elseif spirits:contains(pet.name) then
            classes.CustomIdleGroups:append('Spirit')
        end
    else
        --select_default_macro_book('reset')
    end
	
end

-------------------------------------------------------------------------------------------------------------------
-- User code that supplements standard library decisions.
-------------------------------------------------------------------------------------------------------------------

-- Custom spell mapping.
function job_get_spell_map(spell)
    if spell.type == 'BloodPactRage' then
        if magicalRagePacts:contains(spell.english) then
            return 'MagicalBloodPactRage'
        else
            return 'PhysicalBloodPactRage'
        end
    elseif spell.type == 'BloodPactWard' and spell.target.type == 'MONSTER' then
        return 'DebuffBloodPactWard'
    end
end

-- Modify the default idle set after it was constructed.
function customize_idle_set(idleSet)
    if pet.isvalid then
        if pet.element == world.day_element then
            idleSet = set_combine(idleSet, sets.perp.Day)
        end
        if pet.element == world.weather_element then
            idleSet = set_combine(idleSet, sets.perp.Weather)
        end
        --if sets.perp[pet.name] then
           -- idleSet = set_combine(idleSet, sets.perp[pet.name])
        --end
        --gear.perp_staff.name = elements.perpetuance_staff_of[pet.element]
        --if gear.perp_staff.name and (player.inventory[gear.perp_staff.name] or player.wardrobe[gear.perp_staff.name]) then
          --  idleSet = set_combine(idleSet, sets.perp.staff_and_grip)
        --end

		
		--Equip's Caller's Horn +2 if Favor is up and Idling 
        if state.Buff["Avatar's Favor"] and avatars:contains(pet.name) then
            idleSet = set_combine(idleSet, sets.idle.Avatar.Favor)
        end
		
		--Changes Idle set when only Avatar is Attacking and Idle Set is set to appropriate setting
        if pet.status == 'Engaged' then
		
			if state.IdleMode.current == 'PDT' then
				idleSet = sets.idle.PDT.Avatar.Melee
				
			elseif state.IdleMode.current == 'Att' then
					
				idleSet = sets.idle.Avatar.Melee
				
			end
			
		end
		--Regen Pet Belt if pet is out
		
		if state.IdleMode.current == 'AFK'  then
			
			if pet.status == 'Engaged' then
				idleSet = set_combine(idleSet, {waist="Moepapa Stone", hands=gear.Pet_Regen_Hands, legs=gear.Pet_PAtt_Legs})
			else  
				idleSet = set_combine(idleSet, {waist=gear.Pet_Regen_Waist, hands=gear.Pet_Regen_Hands})
			end
		end
		
		
    end
	
	
    --Latent Refresh Belt
    if player.mpp < 51 and pet.status ~= 'Engaged' then
	
        idleSet = set_combine(idleSet, sets.latent_refresh)
	
	end
	
    
	if buffactive["Quickening"] then
			send_command("/equip legs 'Tatsu. Sitagoromo'")
	end
	
	
    return idleSet
	
end

-- Called by the 'update' self-command, for common needs.
-- Set eventArgs.handled to true if we don't want automatic equipping of gear.
function job_update(cmdParams, eventArgs)
    classes.CustomIdleGroups:clear()
    if pet.isvalid then
        if avatars:contains(pet.name) then
            classes.CustomIdleGroups:append('Avatar')
        elseif spirits:contains(pet.name) then
            classes.CustomIdleGroups:append('Spirit')
        end
    end
end

-- Set eventArgs.handled to true if we don't want the automatic display to be run.
function display_current_job_state(eventArgs)

end

function status_change(newStatus, oldStatus) 
	
	send_command('input /echo oldStatus '..oldStatus..' newStatus '..newStatus)

end
-------------------------------------------------------------------------------------------------------------------
-- User self-commands.
-------------------------------------------------------------------------------------------------------------------

-- Called for custom player commands.
function job_self_command(cmdParams, eventArgs)
    if cmdParams[1]:lower() == 'petweather' then
        handle_petweather()
        eventArgs.handled = true
    elseif cmdParams[1]:lower() == 'siphon' then
        handle_siphoning()
        eventArgs.handled = true
    elseif cmdParams[1]:lower() == 'pact' then
        handle_pacts(cmdParams)
        eventArgs.handled = true
    elseif cmdParams[1] == 'reset_ward_flag' then
        wards.flag = false
        wards.spell = ''
        eventArgs.handled = true
    end
end


-------------------------------------------------------------------------------------------------------------------
-- Utility functions specific to this job.
-------------------------------------------------------------------------------------------------------------------

-- Cast the appopriate storm for the currently summoned avatar, if possible.
function handle_petweather()
    if player.sub_job ~= 'SCH' then
        add_to_chat(122, "You can not cast storm spells")
        return
    end
        
    if not pet.isvalid then
        add_to_chat(122, "You do not have an active avatar.")
        return
    end
    
    local element = pet.element
    if element == 'Thunder' then
        element = 'Lightning'
    end
    
    if S{'Light','Dark','Lightning'}:contains(element) then
        add_to_chat(122, 'You do not have access to '..elements.storm_of[element]..'.')
        return
    end 
    
    local storm = elements.storm_of[element]
    
    if storm then
        send_command('@input /ma "'..elements.storm_of[element]..'" <me>')
    else
        add_to_chat(123, 'Error: Unknown element ('..tostring(element)..')')
    end
end


-- Custom uber-handling of Elemental Siphon
function handle_siphoning()
    if areas.Cities:contains(world.area) then
        add_to_chat(122, 'Cannot use Elemental Siphon in a city area.')
        return
    end

    local siphonElement
    local stormElementToUse
    local releasedAvatar
    local dontRelease
    
    -- If we already have a spirit out, just use that.
    if pet.isvalid and spirits:contains(pet.name) then
        siphonElement = pet.element
        dontRelease = true
        -- If current weather doesn't match the spirit, but the spirit matches the day, try to cast the storm.
        if player.sub_job == 'SCH' and pet.element == world.day_element and pet.element ~= world.weather_element then
            if not S{'Light','Dark','Lightning'}:contains(pet.element) then
                stormElementToUse = pet.element
            end
        end
    -- If we're subbing /sch, there are some conditions where we want to make sure specific weather is up.
    -- If current (single) weather is opposed by the current day, we want to change the weather to match
    -- the current day, if possible.
    elseif player.sub_job == 'SCH' and world.weather_element ~= 'None' then
        -- We can override single-intensity weather; leave double weather alone, since even if
        -- it's partially countered by the day, it's not worth changing.
        if get_weather_intensity() == 1 then
            -- If current weather is weak to the current day, it cancels the benefits for
            -- siphon.  Change it to the day's weather if possible (+0 to +20%), or any non-weak
            -- weather if not.
            -- If the current weather matches the current avatar's element (being used to reduce
            -- perpetuation), don't change it; just accept the penalty on Siphon.
            if world.weather_element == elements.weak_to[world.day_element] and
                (not pet.isvalid or world.weather_element ~= pet.element) then
                -- We can't cast lightning/dark/light weather, so use a neutral element
                if S{'Light','Dark','Lightning'}:contains(world.day_element) then
                    stormElementToUse = 'Wind'
                else
                    stormElementToUse = world.day_element
                end
            end
        end
    end
    
    -- If we decided to use a storm, set that as the spirit element to cast.
    if stormElementToUse then
        siphonElement = stormElementToUse
    elseif world.weather_element ~= 'None' and (get_weather_intensity() == 2 or world.weather_element ~= elements.weak_to[world.day_element]) then
        siphonElement = world.weather_element
    else
        siphonElement = world.day_element
    end
    
    local command = ''
    local releaseWait = 0
    
    if pet.isvalid and avatars:contains(pet.name) then
        command = command..'input /pet "Release" <me>;wait 1.1;'
        releasedAvatar = pet.name
        releaseWait = 10
    end
    
    if stormElementToUse then
        command = command..'input /ma "'..elements.storm_of[stormElementToUse]..'" <me>;wait 4;'
        releaseWait = releaseWait - 4
    end
    
    if not (pet.isvalid and spirits:contains(pet.name)) then
        command = command..'input /ma "'..elements.spirit_of[siphonElement]..'" <me>;wait 4;'
        releaseWait = releaseWait - 4
    end
    
    command = command..'input /ja "Elemental Siphon" <me>;'
    releaseWait = releaseWait - 1
    releaseWait = releaseWait + 0.1
    
    if not dontRelease then
        if releaseWait > 0 then
            command = command..'wait '..tostring(releaseWait)..';'
        else
            command = command..'wait 1.1;'
        end
        
        command = command..'input /pet "Release" <me>;'
    end
    
    if releasedAvatar then
        command = command..'wait 1.1;input /ma "'..releasedAvatar..'" <me>'
    end
    
    send_command(command)
end


-- Handles executing blood pacts in a generic, avatar-agnostic way.
-- cmdParams is the split of the self-command.
-- gs c [pact] [pacttype]
function handle_pacts(cmdParams)
	--local battleTarget = windower.ffxi.get_mob_by_target('bt')
    if areas.Cities:contains(world.area) then
        add_to_chat(122, 'You cannot use pacts in town.')
        return
    end

    if not pet.isvalid then
        add_to_chat(122,'No avatar currently available.')
        --select_default_macro_book('reset')
        return
    end

    if spirits:contains(pet.name) then
        add_to_chat(122,'Cannot use pacts with spirits.')
        return
    end

    if not cmdParams[2] then
        add_to_chat(123,'No pact type given.')
        return
    end
    
    local pact = cmdParams[2]:lower()
    
    if not pacts[pact] then
        add_to_chat(123,'Unknown pact type: '..tostring(pact))
        return
    end
    
    if pacts[pact][pet.name] then
        if pact == 'astralflow' and not buffactive['astral flow'] then
            add_to_chat(122,'Cannot use Astral Flow pacts at this time.')
            return
        end
		
		if state.IdleMode.current == 'AFK'and pact == 'bp70' then
			send_command('@input /pet "'..pacts[pact][pet.name]..'" <bt>')
        else
			-- Leave out target; let Shortcuts auto-determine it.
			send_command('@input /pet "'..pacts[pact][pet.name]..'"')
		end
    else
        add_to_chat(122,pet.name..' does not have a pact of type ['..pact..'].')
    end
end


-- Event handler for updates to player skill, since we can't rely on skill being
-- correct at pet_aftercast for the creation of custom timers.
windower.raw_register_event('incoming chunk',
    function (id)
        if id == 0x62 then
            if wards.flag then
                create_pact_timer(wards.spell)
                wards.flag = false
                wards.spell = ''
            end
        end
    end)

-- Function to create custom timers using the Timers addon.  Calculates ward duration
-- based on player skill and base pact duration (defined in job_setup).
function create_pact_timer(spell_name)
    -- Create custom timers for ward pacts.
    if wards.durations[spell_name] then
        local ward_duration = wards.durations[spell_name]
        if ward_duration < 181 then
            local skill = player.skills.summoning_magic
            if skill > 300 then
                skill = skill - 300
                if skill > 200 then skill = 200 end
                ward_duration = ward_duration + skill
            end
        end
        
        local timer_cmd = 'timers c "'..spell_name..'" '..tostring(ward_duration)..' down'
        
        if wards.icons[spell_name] then
            timer_cmd = timer_cmd..' '..wards.icons[spell_name]
        end

        send_command(timer_cmd)
    end
end


-- Select default macro book on initial load or subjob change.
function select_default_macro_book(reset)
    if reset == 'reset' then
        -- lost pet, or tried to use pact when pet is gone
    end
    
    -- Default macro set/book
    set_macro_page(2, 16)
end