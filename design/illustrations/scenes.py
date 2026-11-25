"""The scene for every artwork slot, composed from the motifs in draw.py."""
from draw import (A, G, INK, P, S, W, banana, boat, bubble, building, cat, cloud, garland, ground, jute_bag,
                  kantha, person, plant, rickshaw, sangsad, svg, tea, tiffin)

SKIN, HAIR = "#E9C9A8", INK


def skyline(w, base, line, fill, scale=1.0):
    """Rooftops of Dhaka with Sangsad Bhaban in the middle."""
    k = scale
    return (building(w * .02, base, 120 * k, 300 * k, line, fill, tank=True)
            + building(w * .02 + 135 * k, base, 100 * k, 220 * k, line, fill, rows=2)
            + sangsad(w * .5 - 170 * k, base, 340 * k, line, fill)
            + building(w * .98 - 260 * k, base, 110 * k, 260 * k, line, fill, tank=True)
            + building(w * .98 - 130 * k, base, 130 * k, 340 * k, line, fill, rows=3))


def hero(w, h, people, services):
    """Navy hero: ivory line art, white service bubbles floating over the city."""
    base = h * .78
    # The top-left stays clear: the app sets the wordmark and tagline there.
    body = [cloud(w * .64, h * .08, 260, G), skyline(w, base, G, P)]
    body.append(f'<rect x="0" y="{base}" width="{w}" height="{h - base}" fill="{INK}"/>')
    body.append(kantha(0, base + 30, w, G))
    spots = [(.56, .3), (.8, .2), (.8, .44), (.18, .46), (.36, .36), (.62, .5)]
    for (fx, fy), key in zip(spots, services):
        body.append(bubble(w * fx, h * fy, 62, key, G, W))
    body.append(people(base))
    return svg(w, h, "".join(body), P)


def customer_people(w):
    def draw(base):
        return (person(w * .36, base + 60, 380, G, SKIN, S, HAIR, phone=True, long_hair=True)
                + rickshaw(w * .58, base + 60, 300, G, P, A) + plant(w * .12, base + 50, 120, G, S))
    return draw


def partner_people(w):
    def draw(base):
        return (person(w * .4, base + 60, 390, G, SKIN, S, HAIR, cap=True, toolbag=True)
                + person(w * .62, base + 60, 330, G, SKIN, W, HAIR, phone=True) + banana(w * .86, base + 60, 260, G, S))
    return draw


def scene(w, h, body):
    """A transparent scene standing on a soft ground, outlined in Primary."""
    return svg(w, h, ground(w, h, h * .82, G, P) + body)


def onboarding(slot):
    w, h = 1170, 1080
    floor = h * .84
    parts = {
        "customer.onboarding.1": person(w * .5, floor, 560, P, SKIN, S, HAIR, phone=True, long_hair=True)
        + bubble(w * .2, h * .3, 80, "cleaning", P, W) + bubble(w * .8, h * .26, 80, "plumbing", P, W)
        + bubble(w * .78, h * .55, 70, "salon", P, W) + bubble(w * .22, h * .6, 70, "electrician", P, W),
        "customer.onboarding.2": building(w * .1, floor, 300, 560, P, W, tank=True)
        + person(w * .62, floor, 520, P, SKIN, S, HAIR, cap=True, toolbag=True) + plant(w * .88, floor, 160, P, S)
        + bubble(w * .82, h * .22, 70, "tools", P, W),
        "customer.onboarding.3": rickshaw(w * .08, floor, 520, P, S, A) + tiffin(w * .66, floor, 220, P, W)
        + jute_bag(w * .8, floor, 180, P, S) + bubble(w * .5, h * .2, 80, "homemade-food", P, W),
        "partner.onboarding.1": person(w * .45, floor, 560, P, SKIN, S, HAIR, cap=True, toolbag=True)
        + bubble(w * .78, h * .25, 80, "ac", P, W) + bubble(w * .82, h * .52, 70, "plumbing", P, W)
        + bubble(w * .16, h * .3, 70, "painting", P, W),
        "partner.onboarding.2": building(w * .04, floor, 220, 420, P, W, rows=2) + building(w * .74, floor, 240, 520, P, W, tank=True)
        + rickshaw(w * .28, floor, 500, P, S, A) + cloud(w * .3, h * .14, 240, P),
        "partner.onboarding.3": person(w * .4, floor, 540, P, SKIN, W, HAIR, phone=True) + tea(w * .68, floor, 160, P, S)
        + garland(w * .76, h * .34, 150, P, S, A),
    }
    return scene(w, h, parts[slot])


def small(slot):
    w, h = 720, 540
    floor = h * .86
    parts = {
        "empty.bookings": jute_bag(w * .32, floor, 220, P, S) + cat(w * .62, floor, 90, P, W),
        "empty.search": f'<circle cx="{w * .45}" cy="{h * .45}" r="120" fill="{W}" stroke="{P}" stroke-width="14"/>'
        f'<path d="M{w * .45 + 85} {h * .45 + 85}l90 90" stroke="{P}" stroke-width="26" stroke-linecap="round"/>'
        + plant(w * .16, floor, 140, P, S),
        "empty.notifications": tea(w * .3, floor, 170, P, S) + cat(w * .54, floor, 90, P, W) + cloud(w * .55, h * .12, 160, P),
        "empty.jobs": tiffin(w * .26, floor, 200, P, S) + tea(w * .55, floor, 150, P, W) + cloud(w * .3, h * .1, 180, P),
        "offline": boat(w * .34, floor - 20, 240, P, S) + cloud(w * .1, h * .12, 180, P) + cloud(w * .6, h * .2, 150, P),
    }
    return scene(w, h, parts[slot])


def success(slot):
    w = h = 720
    key = "tools" if slot == "success.job" else "cleaning"
    return svg(w, h, garland(w / 2, h * .45, 210, P, S, A) + bubble(w * .82, h * .16, 60, key, P, W)
               + kantha(w * .15, h * .9, w * .7, P))


def admin_hero():
    w, h = 1600, 1200
    base = h * .78
    body = [cloud(w * .7, h * .1, 300, G), skyline(w, base, G, P, 1.3),
            f'<rect x="0" y="{base}" width="{w}" height="{h - base}" fill="{INK}"/>', kantha(0, base + 36, w, G)]
    for i, key in enumerate(["cleaning", "plumbing", "electrician", "salon", "homemade-food", "bazar", "ac", "tutoring"]):
        body.append(bubble(w * (.12 + i * .108), h * (.36 if i % 2 else .48), 58, key, G, W))
    return svg(w, h, "".join(body), P)


def all_scenes():
    width = 1170
    yield "customer.signin.hero", hero(width, 1200, customer_people(width), ["cleaning", "plumbing", "salon", "electrician", "homemade-food", "bazar"])
    yield "partner.signin.hero", hero(width, 1200, partner_people(width), ["ac", "tools", "painting", "carpentry", "plumbing", "moving"])
    for app in ("customer", "partner"):
        for i in (1, 2, 3):
            yield f"{app}.onboarding.{i}", onboarding(f"{app}.onboarding.{i}")
    for slot in ("empty.bookings", "empty.search", "empty.notifications", "empty.jobs", "offline"):
        yield slot, small(slot)
    for slot in ("success.booking", "success.job"):
        yield slot, success(slot)
    yield "admin.login.hero", admin_hero()
