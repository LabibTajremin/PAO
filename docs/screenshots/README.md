# Screenshots

Every main screen of the three apps in light and dark mode, in English and Bangla (P28). They
are written by the screen tours, which also run in every `./pao test dart` and fail on any
layout error (overflow, clipped text) in any of the four looks:

| App | Tour | Screen size |
|---|---|---|
| PAO (customer) | `Frontend/apps/customer/test/tour/customer_tour_test.dart` | 393 × 852 |
| PAO Partner | `Frontend/apps/partner/test/tour/partner_tour_test.dart` | 393 × 852 |
| PAO Admin | `Frontend/apps/admin/test/tour/admin_tour_test.dart` | 1280 × 800 |

Files are named `<screen>_<light|dark>_<en|bn>.png`. To refresh them after a design change:

```bash
cd Frontend/apps/customer && flutter test --update-goldens test/tour
```

Run the same in `apps/partner` and `apps/admin`. The data comes from the tests' fixtures, so
names and amounts are examples. Store screenshots for Play and the App Store are taken from
these at the stores' sizes.
