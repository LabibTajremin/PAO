"""Source of the PAO service icon library (P22). Run: python3 design/icons/icons.py

Every icon is drawn on a 24 x 24 grid with a 2 px safe margin, one colour
(currentColor), 1.75 px stroke, round caps and joins. The apps tint them with
the accent colour, so nothing here may carry its own fill colour.
"""
import pathlib

ICONS = {
    # Pipe with a tap and a falling drop: the PAO plumbing mark (not a wrench).
    "plumbing": '<path d="M3 8h8a3 3 0 0 1 3 3v1"/><path d="M3 5v6"/><path d="M11 5h4"/><path d="M13 5v3"/><path d="M14 16.5c0 1.4-1 2.5-2 2.5s-2-1.1-2-2.5c0-1.2 2-3.5 2-3.5s2 2.3 2 3.5z"/>',
    "electrician": '<path d="M13 2 5 13h6l-1 9 8-11h-6l1-9z"/>',
    "ac": '<rect x="3" y="4" width="18" height="8" rx="2"/><path d="M7 9h10"/><path d="M8 15v2"/><path d="M12 15v4"/><path d="M16 15v2"/>',
    "appliance": '<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M5 7h14"/><circle cx="12" cy="14" r="4"/><path d="M8 5h.01"/><path d="M11 5h.01"/>',
    "cleaning": '<path d="M14 3 9 11"/><path d="M6 11h7l3 3-1 7H6l-1-7z"/><path d="M9 17v4"/><path d="M12 17v4"/>',
    "deep-clean": '<path d="M9 3h4v4H9z"/><path d="M11 7v2"/><path d="M8 9h6l1 12H7z"/><path d="M17 4l2-1"/><path d="M17 7h3"/><path d="M17 10l2 1"/>',
    "pest-control": '<ellipse cx="12" cy="13" rx="4" ry="6"/><path d="M12 7V5"/><path d="M10 4l2 1 2-1"/><path d="M8 11H4"/><path d="M8 15l-3 2"/><path d="M16 11h4"/><path d="M16 15l3 2"/><path d="M3 21 21 3"/>',
    "painting": '<rect x="4" y="3" width="14" height="6" rx="1.5"/><path d="M18 6h2v5h-8v3"/><rect x="10" y="14" width="4" height="7" rx="1"/>',
    "carpentry": '<path d="M12.5 11.5 4 20"/><path d="M9.5 8.5 14 4l6 6-4.5 4.5z"/><path d="M14 4l-2-1.5"/>',
    "gas-stove": '<rect x="3" y="12" width="18" height="9" rx="2"/><path d="M7 16h.01"/><path d="M17 16h.01"/><path d="M12 3c2 2 3 3.5 3 5a3 3 0 0 1-6 0c0-1.5 1-3 3-5z"/>',
    "water-filter": '<rect x="7" y="3" width="10" height="14" rx="2"/><path d="M7 7h10"/><path d="M12 17v2"/><path d="M9 21h6"/><path d="M12 10c1 1.2 1.5 2 1.5 2.7a1.5 1.5 0 0 1-3 0c0-.7.5-1.5 1.5-2.7z"/>',
    "salon": '<circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><path d="M8.5 7.5 20 18"/><path d="M8.5 16.5 20 6"/>',
    "spa": '<path d="M12 21c-4-1-8-4-8-9 3 0 6 1.5 8 4 2-2.5 5-4 8-4 0 5-4 8-8 9z"/><path d="M12 16c-1.5-2-2-4-2-6 0-2 1-4 2-6 1 2 2 4 2 6 0 2-.5 4-2 6z"/>',
    "grooming": '<path d="M5 4h14"/><path d="M6 4v3h12V4"/><path d="M12 7v14"/><path d="M10.5 12h3"/><path d="M10.5 16h3"/>',
    "driver": '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="2"/><path d="M3.5 10h6.5"/><path d="M14 10h6.5"/><path d="M12 14v7"/>',
    "car-wash": '<path d="M4 17v-4l2-5h12l2 5v4z"/><path d="M4 13h16"/><path d="M7 17v2"/><path d="M17 17v2"/><path d="M8 3v2"/><path d="M12 2v3"/><path d="M16 3v2"/>',
    "moving": '<path d="M2 6h11v10H2z"/><path d="M13 9h4l3 3v4h-7"/><circle cx="6" cy="18" r="2"/><circle cx="17" cy="18" r="2"/>',
    "laundry": '<rect x="4" y="3" width="16" height="18" rx="2"/><path d="M4 7h16"/><circle cx="12" cy="14" r="4"/><path d="M10 14.5c1-1 3 0 4-1"/>',
    "tailoring": '<path d="M5 20 19 6"/><circle cx="19.5" cy="4.5" r="1.5"/><path d="M5 20c-2-2 1-5 4-5s5 2 4 4-4 1-5-1"/>',
    "babysitting": '<circle cx="12" cy="7" r="4"/><path d="M10 6.5h.01"/><path d="M14 6.5h.01"/><path d="M10.5 9c1 .7 2 .7 3 0"/><path d="M6 21c0-4 2.5-7 6-7s6 3 6 7"/>',
    "elderly-care": '<circle cx="10" cy="5" r="2.5"/><path d="M10 9v6l-3 6"/><path d="M10 15l2 6"/><path d="M7 11l3-2 3 2"/><path d="M17 11v10"/><path d="M17 11a2 2 0 0 0-2 2"/>',
    "nursing": '<rect x="3" y="3" width="18" height="18" rx="4"/><path d="M12 8v8"/><path d="M8 12h8"/>',
    "tutoring": '<path d="M2 8l10-5 10 5-10 5z"/><path d="M6 10v5c0 1.5 3 3 6 3s6-1.5 6-3v-5"/><path d="M22 8v6"/>',
    # Stacked tiffin carrier with its handle.
    "homemade-food": '<path d="M9 3h6"/><path d="M12 3v2"/><rect x="6" y="5" width="12" height="5" rx="1.5"/><rect x="6" y="10" width="12" height="5" rx="1.5"/><rect x="6" y="15" width="12" height="5" rx="1.5"/>',
    # Handi: a wide-bellied pot with a lid and a narrow neck.
    "catering": '<path d="M7 9h10"/><path d="M9 6h6"/><path d="M12 4v2"/><path d="M8 9c-3 1-4 4-4 6a5 5 0 0 0 5 5h6a5 5 0 0 0 5-5c0-2-1-5-4-6"/><path d="M4 13H2"/><path d="M20 13h2"/>',
    # Jute bag for the monthly bazar.
    "bazar": '<path d="M5 8h14l-1 13H6z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/><path d="M8 12h8"/><path d="M8 16h8"/>',
    "grocery": '<path d="M3 4h2l2.5 11h11L21 7H6"/><circle cx="9" cy="19" r="1.5"/><circle cx="17" cy="19" r="1.5"/>',
    "chef": '<path d="M7 14a4 4 0 0 1-1-7.9A5 5 0 0 1 15.5 5 4 4 0 0 1 17 14z"/><path d="M7 14v6h10v-6"/><path d="M7 17h10"/>',
    "gardening": '<path d="M12 21v-9"/><path d="M12 12c-4 0-6-3-6-7 4 0 6 3 6 7z"/><path d="M12 15c3 0 5-2 5-5-3 0-5 2-5 5z"/><path d="M6 21h12"/>',
    "cctv": '<path d="M3 6l13 4-2 5-11-4z"/><path d="M15 12l4 1"/><path d="M6 11v5"/><path d="M3 16h6"/><path d="M19 10v6"/>',
    "wifi": '<path d="M2 9a15 15 0 0 1 20 0"/><path d="M5.5 12.5a10 10 0 0 1 13 0"/><path d="M9 16a5 5 0 0 1 6 0"/><path d="M12 19.5h.01"/>',
    "mobile-repair": '<rect x="6" y="2" width="12" height="20" rx="2.5"/><path d="M11 18h2"/><path d="m10 8 4 4"/><path d="m14 8-4 4"/>',
    "computer-repair": '<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8"/><path d="M12 16v4"/><path d="m10 8-2 2 2 2"/><path d="m14 8 2 2-2 2"/>',
    "photography": '<path d="M4 8h3l2-3h6l2 3h3a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13.5" r="3.5"/>',
    "decoration": '<path d="M2 5c3 3 7 4 10 4s7-1 10-4"/><path d="M6 7.5V11"/><path d="M12 9v5"/><path d="M18 7.5V11"/><circle cx="6" cy="13" r="2"/><circle cx="12" cy="16" r="2"/><circle cx="18" cy="13" r="2"/>',
    "security": '<path d="M12 2 4 5v6c0 5 3.5 9 8 11 4.5-2 8-6 8-11V5z"/><path d="m9 12 2 2 4-4"/>',
    "courier": '<path d="M3 7.5 12 3l9 4.5v9L12 21l-9-4.5z"/><path d="M3 7.5 12 12l9-4.5"/><path d="M12 12v9"/><path d="m7.5 5.2 9 4.6"/>',
    "tools": '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94z"/>',
    # Category marks.
    "beauty": '<path d="M12 3v4"/><path d="M12 17v4"/><path d="M3 12h4"/><path d="M17 12h4"/><path d="M12 7c0 3 2 5 5 5-3 0-5 2-5 5 0-3-2-5-5-5 3 0 5-2 5-5z"/>',
    "food": '<path d="M7 3v8"/><path d="M5 3v5a2 2 0 0 0 4 0V3"/><path d="M7 11v10"/><path d="M17 21V3c-2 1-3 4-3 8h3"/>',
}

HEAD = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round">')

if __name__ == "__main__":
    root = pathlib.Path(__file__).resolve().parents[2]
    for out in (root / "design/icons", root / "Frontend/packages/pao_ui/assets/icons"):
        for key, body in ICONS.items():
            (out / f"{key}.svg").write_text(f"{HEAD}{body}</svg>\n")
    print(f"{len(ICONS)} icons")
