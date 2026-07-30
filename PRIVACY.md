# Privacy & Data Safety — working notes

**Status: draft for review. Not yet published.**

Google Play's Data Safety form and the iOS privacy manifest must *agree with each
other and with the code* — mismatches get apps suspended. This file records what
the build actually does today, so the forms can be filled in from evidence rather
than from memory. **Re-check it whenever a dependency or service is added.**

Last verified against the code on the commit that introduced this file.

---

## What the app collects today

| Data | Collected? | Where it goes |
|---|---|---|
| Game progress (day, coins, gems, inventory, stars, friendships) | Yes | **Device only**, via `shared_preferences`. Never transmitted. |
| Account / email / name | No | No accounts, no login, no sign-in SDK. |
| Location, contacts, photos, files | No | Not requested. |
| Analytics / usage events | **Not transmitted** | `AnalyticsService` defaults to `NoopAnalytics`, which discards every event. Nothing leaves the device. |
| Purchases | **Not processed** | `IapService` defaults to `UnavailableIap`, which refuses all purchases. No billing SDK is wired. |
| Advertising ID | **See caveat below** | Ads are disabled (`Features.ads = false`) and `AdService.init()` is not called, but the AdMob SDK is still compiled into the binary. |
| Notifications | Local only | `flutter_local_notifications`. Off by default; scheduled only if the player enables the reminder. No push server, no tokens. |

There is **no backend**: the app has no server, no user identifiers, and no
network API of its own.

---

## Caveats that must be resolved before submitting

### 1. Google Fonts is fetched at runtime

`google_fonts` is a dependency but **no font files are bundled** (there is no
`fonts:` section in `pubspec.yaml` and no `assets/fonts/`). The package therefore
downloads Playfair Display and Nunito from `fonts.gstatic.com` on first use.

Consequences: the app contacts a Google server, the device IP is exposed to that
request, first launch needs connectivity, and text may fall back to a system font
offline.

**Recommended fix:** bundle the two font families as assets and stop the runtime
fetch. That removes a third-party network call, makes the app fully offline, and
simplifies this disclosure. Until then, the network access must be disclosed.

### 2. The AdMob SDK ships even though ads are off

Disabling ads in Dart does not remove `google_mobile_ads` from the binary. The
SDK can access the advertising identifier, and Play expects that declared.

**Two clean options — pick one before submitting:**
- **Shipping without ads:** remove the `google_mobile_ads` dependency and
  `lib/services/ad_service.dart` entirely, then declare no ad data.
- **Shipping with ads later:** keep it, put real unit IDs in `ad_service.dart`,
  set `Features.ads = true`, and declare advertising ID + any ad-partner data
  sharing.

Leaving it as-is (SDK present, ads off, nothing declared) is the one combination
to avoid.

### 3. Selling gems changes this document

The moment a real billing plugin is wired, purchase data is processed by the
store and the disclosure changes. Server-side receipt validation is required
anyway — without it clients can mint free gems.

### 4. Children / age rating

The game is cosy and broadly appealing, so it may attract under-13 players. If
the age rating targets children, ads and any analytics must be COPPA/GDPR-K
compliant, which is a further argument for shipping ad-free.

---

## Draft privacy policy text

> **Bloom & Deliver — Privacy Policy**
>
> Bloom & Deliver does not collect, transmit, or sell personal information.
>
> **Game progress.** Your shop — day, coins, gems, flowers, stars and customer
> friendships — is saved locally on your device so you can pick up where you left
> off. It never leaves your device, and we cannot see it. Deleting the app
> deletes it.
>
> **No account.** There is no sign-up, login, or profile. We do not collect your
> name, email address, contacts, photos, or location.
>
> **Notifications.** Optional. If you turn on the daily reminder, it is scheduled
> on your device by your device — no messages are sent from us, and no token or
> identifier is shared. Turn it off any time with the bell icon.
>
> **Fonts.** The app downloads its typefaces from Google Fonts the first time it
> runs, which involves a request to Google's servers. *(Remove this paragraph
> once fonts are bundled.)*
>
> **Purchases.** Gems are optional and never required to finish the game. When
> you buy gems the transaction is handled entirely by Google Play or the App
> Store; we never see your payment details. *(Add once purchases are live.)*
>
> **Children.** We do not knowingly collect information from anyone, including
> children.
>
> **Changes.** Material changes will be reflected here with an updated date.
>
> **Contact:** <add a contact email — Play requires a reachable address>

---

## Before you publish

- [ ] Decide: ship with ads or remove the SDK (see caveat 2)
- [ ] Bundle fonts, or disclose the Google Fonts request (caveat 1)
- [ ] Add a real contact email
- [ ] Host the policy at a public URL and link it in both stores
- [ ] Fill the Play Data Safety form to match this file
- [ ] Add the iOS privacy manifest (`PrivacyInfo.xcprivacy`) to match
- [ ] Re-verify after wiring analytics or billing — both change the answers
