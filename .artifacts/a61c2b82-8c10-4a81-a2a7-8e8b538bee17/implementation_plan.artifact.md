# Implementation Plan: Pinpoint Weather & Layout Refinements

This plan implements high-accuracy geolocation for weather and fixes small UI inconsistencies in the Cloudy theme and Mobile layout.

## Proposed Changes

### 🌍 Pinpoint Accurate Weather

#### [MODIFY] [post_feed.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/widgets/post_feed.dart)
- **Geolocator Integration**: Use the browser's `Geolocator` (via `geolocator` package) to get the user's exact `latitude` and `longitude` during the login process.
- **Enhanced API Call**: Pass `lat` and `lon` to the `api.updateOwnerLocation(lat: ..., lon: ...)` method.

#### [MODIFY] [api_service.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/services/api_service.dart)
- Update `updateOwnerLocation` to accept optional `lat` and `lon` parameters and send them as JSON to the backend.

#### [MODIFY] [portfolio.py](file:///C:/Users/Kshitij/Desktop/portfolio_website/backend/routes/portfolio.py)
- **Endpoint Update**: Modify `update_location` to accept a JSON body with `lat` and `lon`.
- **Reverse Geocoding**: Use OpenWeather's Geocoding API to find the closest city name for those coordinates.
- **Persistence**: Store `lat`, `lon`, and `city` in the `basics` section.

#### [MODIFY] [weather.py](file:///C:/Users/Kshitij/Desktop/portfolio_website/backend/routes/weather.py)
- **Live Weather Update**: Update `get_weather` to query OpenWeather using `lat` and `lon` coordinates for pinpoint accuracy.

### 🎨 Cloudy Visibility Fixes

#### [MODIFY] [portfolio_content.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/widgets/portfolio_content.dart)
- **Darkened Cloud Aura**: Change the cloud aura color to a darker grey (`0xFF78909C`) so it's clearly visible against the light grey background.
- **Metadata Contrast**: Ensure Year, CGPA, and Tech tags use **Bold** and **Extra Bold** weights with a high-contrast accent color in the Cloudy theme.
- **Hover Impact**: Increase hover opacity and shadow depth for a more premium "card lift" feel.

### 📱 Mobile Layout Optimization

#### [MODIFY] [portfolio_content.dart](file:///C:/Users/Kshitij/Desktop/portfolio_website/frontend/lib/widgets/portfolio_content.dart)
- **Bottom Padding**: Increase bottom padding of the main scroll view to `120px` to ensure no content is ever hidden behind the floating TabBar.

---

## Verification Plan

### Manual Verification
1. **Login Flow**: Log in as owner. Verify the browser asks for Location Permission.
2. **Accuracy**: Confirm the Hero section shows your exact suburb or city based on coordinates, not just a coarse IP-based guess.
3. **Cloud Visibility**: Cycle to Cloudy theme. Verify the aura around the profile pic is clearly defined and all metadata (years/tags) is easily readable.
4. **Mobile Scroll**: Switch to mobile view and scroll to the bottom of the feed. Verify the last post is fully visible.
