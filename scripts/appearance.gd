class_name StaffAppearance
extends RefCounted
const SKIN = [Color("d7b8a0"), Color("b78c6b"), Color("8b6550"), Color("e0c9b5"), Color("694e43"), Color("c69c83")]
const HAIR = [Color("302d2b"), Color("6b4937"), Color("aca394"), Color("c0a172"), Color("824a38"), Color("504d4c")]
const SHIRTS = [Color("718d9d"), Color("a67d73"), Color("89976f"), Color("9583a2"), Color("c1a271")]
static func of(person: Dictionary) -> Dictionary:
	var value = int(person.get("appearance", absi((person.name + person.role).hash())))
	return {"skin": SKIN[value % SKIN.size()], "hair": HAIR[(value / 7) % HAIR.size()], "style": (value / 43) % 5, "glasses": (value / 211) % 3 == 0, "beard": (value / 641) % 4 == 0, "shirt": SHIRTS[(value / 2573) % SHIRTS.size()], "wide": (value / 12907) % 2 == 0}
