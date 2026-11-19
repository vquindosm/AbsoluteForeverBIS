-- Original class and route data retained; no talent builds are asserted.
local D = FWC.Data
D.source = "https://wowtbc.gg/warcraftforever/bis-list/"
D.classes = {
  DRUID = {"Balance","Feral Tank","Feral DPS","Restoration"},
  HUNTER = {"Beast Mastery","Marksmanship","Survival"},
  MAGE = {"Arcane","Fire","Frost"},
  PALADIN = {"Holy","Protection","Retribution","Shockadin"},
  PRIEST = {"Discipline","Holy","Shadow"},
  ROGUE = {"Assassination","Combat","Subtlety"},
  SHAMAN = {"Elemental","Enhancement","Restoration"},
  WARLOCK = {"Affliction","Demonology","Destruction"},
  WARRIOR = {"Arms","Fury","Protection"},
 }
D.routes = {
  {zone="Felwood",name="Timbermaw reputation and vendor",detail="Farm furbolgs and check Meilosh rewards; verify standing."},
  {zone="Stranglethorn Vale",name="Pix Xizzix vendor",detail="Check Arcanoweave Cloak availability and currency."},
  {zone="Blackrock Mountain",name="Upper Blackrock Spire",detail="Target General Drakkisath and Lord Valthalak (may require encounter unlock)."},
  {zone="Blackrock Mountain",name="Blackrock Depths",detail="Target Golem Lord Argelmach for Omnicast Boots."},
  {zone="Eastern Plaguelands",name="Stratholme",detail="Look for Skul (rare) for wand."},
  {zone="Western Plaguelands",name="Scholomance",detail="Target Vectus for necklace."},
  {zone="Feralas",name="Dire Maul East",detail="Target Pusillin for Obsidian Bauble."},
  {zone="Moonwell",name="Mooncloth cooldown",detail="Bring 2 Felcloth; craft at a Moonwell and record cooldown manually."},
 }
D.classOrder = {"DRUID","HUNTER","MAGE","PALADIN","PRIEST","ROGUE","SHAMAN","WARLOCK","WARRIOR"}
D.professionChoices = {"Any profession","Tailoring","Enchanting","Alchemy","Blacksmithing","Engineering","Leatherworking","Herbalism","Mining","Skinning"}
D.slots = {
 {key="Head",label="Head",legacy="Head",inventory=1},
 {key="Neck",label="Neck",legacy="Neck",inventory=2},
 {key="Shoulders",label="Shoulders",legacy="Shoulders",inventory=3},
 {key="Back",label="Back",legacy="Back",inventory=15},
 {key="Chest",label="Chest",legacy="Chest",inventory=5},
 {key="Wrists",label="Wrists",legacy="Wrists",inventory=9},
 {key="Hands",label="Hands",legacy="Hands",inventory=10},
 {key="Waist",label="Waist",legacy="Waist",inventory=6},
 {key="Legs",label="Legs",legacy="Legs",inventory=7},
 {key="Feet",label="Feet",legacy="Feet",inventory=8},
 {key="Ring1",label="Ring 1",legacy="Ring 1",inventory=11},
 {key="Ring2",label="Ring 2",legacy="Ring 2",inventory=12},
 {key="Trinket1",label="Trinket 1",legacy="Trinket 1",inventory=13},
 {key="Trinket2",label="Trinket 2",legacy="Trinket 2",inventory=14},
 {key="MainHand",label="Main Hand",legacy="Main Hand",inventory=16},
 {key="OffHand",label="Off Hand",legacy="Off Hand",inventory=17},
 {key="Ranged",label="Ranged / Relic / Wand",legacy="Wand",inventory=18},
}
D.slotByKey = {}; for _, slot in ipairs(D.slots) do D.slotByKey[slot.key] = slot end
D.provenance = {
 imported_unranked="Imported / unranked", verified="Verified in client",
 calculated="Calculated (method required)", pending_recipe="Recipe pending review",
 imported_recipe="Imported recipe / confirm in game", legacy_unverified="Legacy recipe / unverified",
}
